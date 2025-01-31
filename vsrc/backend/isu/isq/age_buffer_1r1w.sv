module age_buffer_1r1w #(
    parameter DATA_WIDTH      = 248,
    parameter CONDITION_WIDTH = 2,
    parameter INDEX_WIDTH     = 4,
    parameter DEPTH     = 8
)(
    input  logic                         clock,
    input  logic                         reset_n,

    //-----------------------------------------------------
    // Enqueue interface
    //-----------------------------------------------------
    input  logic [DATA_WIDTH-1:0]       enq_data,
    input  logic [CONDITION_WIDTH-1:0]  enq_condition,
    //input  logic [INDEX_WIDTH-1:0]      enq_index,
    input  logic                         enq_valid,  // Request to enqueue
    output logic                         enq_ready,  // Indicate we can accept data

    //-----------------------------------------------------
    // Dequeue interface
    //-----------------------------------------------------
    output logic [DATA_WIDTH-1:0]       deq_data,
    output logic [CONDITION_WIDTH-1:0]  deq_condition,
    output logic [INDEX_WIDTH-1:0]      deq_index,
    output logic                         deq_valid,  // We have a valid oldest ready
    input  logic                         deq_ready,  // Consumer is ready to take it

    //-----------------------------------------------------
    // Broadcast condition updates
    //-----------------------------------------------------
    input  logic                        update_condition_valid,
    input  logic [`ROB_SIZE_LOG:0]      update_condition_robid,
    input  logic [CONDITION_WIDTH-1:0]  update_condition_mask,
    input  logic [CONDITION_WIDTH-1:0]  update_condition_in,
    // Flush interface
    input  logic                      flush_valid,
    input  logic [`ROB_SIZE_LOG:0]    flush_robid,
    //output array
    output logic [DEPTH-1:0][DATA_WIDTH-1:0]      data_out_array,
    output logic [DEPTH-1:0][CONDITION_WIDTH-1:0] condition_out_array,
    output logic [DEPTH-1:0][INDEX_WIDTH-1:0]     index_out_array,
    output logic [DEPTH-1:0]                      valid_out_array
);

    // ----------------------------------------------------------
    // Sub-entry outputs and control signals
    // ----------------------------------------------------------
    logic [DEPTH-1:0]                      wr_en;
    logic [DEPTH-1:0]                      clear_entry;
    logic [DEPTH-1:0]                      rdy2dq_out_array;



    // age_matrix[i][j] = 1 => "entry i" is older than "entry j"
    logic [DEPTH-1:0][DEPTH-1:0] age_matrix;
    logic [DEPTH-1:0] needflush_array;

/* ----------------- writeback to update condition bit logic ---------------- */
    //lets assume robid lie in [247:241] for now
    // Decode update_condition_robid -> one-hot
    integer j;
    always_comb begin
        for (j = 0; j < DEPTH; j++) begin
            update_condition_valid_array[j] = (update_condition_robid == data_out[j][247:241]) && update_condition_valid;
        end
    end

    //dont need enq_index in age_buffer
    assign enq_index = 'b0;
    // ----------------------------------------------------------
    // Generate sub-entries
    // ----------------------------------------------------------
    genvar g;
    generate
        for (g = 0; g < DEPTH; g++) begin : GEN_ENTRIES
            abentry #(
                .DATA_WIDTH     (DATA_WIDTH),
                .CONDITION_WIDTH(CONDITION_WIDTH),
                .INDEX_WIDTH    (INDEX_WIDTH)
            ) abentry_g (
                .clock                  (clock),
                .reset_n                (reset_n),

                // Control
                .wr_en                  (wr_en[g]),
                .clear_entry            (clear_entry[g]),

                // Data in (only used when wr_en[g] == 1)
                .data_in                (enq_data),
                .condition_in           (enq_condition),
                .index_in               (enq_index),
                .valid_in               (1'b1),

                // Condition updates
                .update_condition_valid (update_condition_valid_array[g]),
                .update_condition_mask  (update_condition_mask),
                .update_condition_in    (update_condition_in),

                // Outputs
                .data_out               (data_out_array[g]),
                .condition_out          (condition_out_array[g]),
                .index_out              (index_out_array[g]),
                .valid_out              (valid_out_array[g]),
                .ready_to_dequeue_out   (rdy2dq_out_array[g])
            );
        end
    endgenerate

    // ----------------------------------------------------------
    // Combinational logic: find the first free index (for enqueue)
    // ----------------------------------------------------------
    integer free_idx_for_enq;
    always_comb begin
        free_idx_for_enq = -1;
        for (int i = 0; i < DEPTH; i++) begin
            if (valid_out_array[i] == 1'b0) begin
                free_idx_for_enq = i;
                break;
            end
        end
    end

    // ----------------------------------------------------------
    // Combinational logic: find the oldest ready entry (for dequeue)
    // ----------------------------------------------------------
    integer oldest_idx_for_deq;
    logic   oldest_found;
    always_comb begin
        oldest_idx_for_deq = -1;
        oldest_found       = 1'b0;

        for (int i = 0; i < DEPTH; i++) begin
            if (rdy2dq_out_array[i]) begin
                // Check if there's any j that is older than i
                logic any_j_older = 1'b0;
                for (int j = 0; j < DEPTH; j++) begin
                    if (j != i && valid_out_array[j] && age_matrix[j][i]) begin
                        any_j_older = 1'b1;
                        break;
                    end
                end

                // If no j is older and we haven't chosen an oldest yet
                if (!any_j_older && !oldest_found) begin
                    oldest_idx_for_deq = i;
                    oldest_found       = 1'btrue;
                end
            end
        end
    end

    // ----------------------------------------------------------
    // Provide enq_ready & deq_valid based on the combinational searches
    // ----------------------------------------------------------
    assign enq_ready = (free_idx_for_enq != -1);
    assign deq_valid = oldest_found;

    // For output data (dequeue path)
    assign deq_data      = (oldest_found) ? data_out_array[oldest_idx_for_deq]      : '0;
    assign deq_condition = (oldest_found) ? condition_out_array[oldest_idx_for_deq] : '0;
    assign deq_index     = (oldest_found) ? index_out_array[oldest_idx_for_deq]     : '0;

    // ----------------------------------------------------------
    // Main sequential block
    //   - Drive wr_en, clear_entry
    //   - Update age_matrix
    // ----------------------------------------------------------
    always_ff @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            // Reset everything
            for (int i = 0; i < DEPTH; i++) begin
                wr_en[i]       <= 1'b0;
                clear_entry[i] <= 1'b0;
                for (int j = 0; j < DEPTH; j++) begin
                    age_matrix[i][j] <= 1'b0;
                end
            end
        end
        else begin
            if(flush_valid)begin
                clear_entry <= needflush_array;
            end
            // ================================
            // Enqueue if enq_valid & enq_ready
            // ================================
            if (enq_valid && (free_idx_for_enq != -1)) begin
                wr_en[free_idx_for_enq] <= 1'b1;

                // Update age_matrix for the new entry free_idx_for_enq
                // The new entry is "younger" than all existing valid entries
                for (int j = 0; j < DEPTH; j++) begin
                    if (j != free_idx_for_enq) begin
                        if (valid_out_array[j]) begin
                            // j is older than free_idx_for_enq
                            age_matrix[j][free_idx_for_enq] <= 1'b1;
                            age_matrix[free_idx_for_enq][j] <= 1'b0;
                        end
                        else begin
                            age_matrix[j][free_idx_for_enq] <= 1'b0;
                            age_matrix[free_idx_for_enq][j] <= 1'b0;
                        end
                    end
                end
            end

            // ================================
            // Dequeue if we found an oldest ready entry & deq_ready
            // ================================
            if (oldest_found && deq_ready) begin
                clear_entry[oldest_idx_for_deq] <= 1'b1;

                // Clear row & column in the age_matrix
                for (int j = 0; j < DEPTH; j++) begin
                    age_matrix[oldest_idx_for_deq][j] <= 1'b0;
                    age_matrix[j][oldest_idx_for_deq] <= 1'b0;
                end
            end
        end
    end


/* ------------------------------- flush logic ------------------------------ */
//lets assume robid lie in [247:241] for now
//find req younger than flush_robid
    always @(*) begin
        integer i;
        needflush_array = 'b0;
        for (i = 0; i < DEPTH; i = i + 1) begin
            if (rob_state == `ROB_STATE_ROLLILNGBACK) begin
                    needflush_array[i] = flush_robid[`ROB_SIZE_LOG] ^ data_out[i][247] ^ (flush_robid[`ROB_SIZE_LOG-1:0] < data_out[i][246:241]);
                end
            end
        end



// disp2isq_wrdata0 = {
// rob2disp_instr_id ,//7   //[247 : 241]
// instr0_pc         ,//64  //[240 : 177]         
// instr0            ,//32  //[176 : 145]         
// instr0_lrs1       ,//5   //[144 : 140]         
// instr0_lrs2       ,//5   //[139 : 135]         
// instr0_lrd        ,//5   //[134 : 130]         
// instr0_prd        ,//6   //[129 : 124]         
// instr0_old_prd    ,//6   //[123 : 118]         
// instr0_need_to_wb ,//1   //[117 : 117]         
// instr0_prs1       ,//6   //[116 : 111]         
// instr0_prs2       ,//6   //[110 : 105]         
// instr0_src1_is_reg,//1   //[104 : 104]         
// instr0_src2_is_reg,//1   //[103 : 103]         
// instr0_imm        ,//64  //[102 : 39 ]         
// instr0_cx_type    ,//6   //[38  : 33 ]         
// instr0_is_unsigned,//1   //[32  : 32 ]         
// instr0_alu_type   ,//11  //[31  : 21 ]         
// instr0_muldiv_type,//13  //[20  : 8  ]         
// instr0_is_word    ,//1   //[7   : 7  ]         
// instr0_is_imm     ,//1   //[6   : 6  ]         
// instr0_is_load    ,//1   //[5   : 5  ]         
// instr0_is_store   ,//1   //[4   : 4  ]         
// instr0_ls_size     //4   //[3   : 0  ]         
// };

endmodule
