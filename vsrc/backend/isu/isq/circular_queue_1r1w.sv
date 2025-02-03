module circular_queue_1r1w #(
    parameter DEPTH           = 8,
    parameter DEPTH_LOG       = 3,
    parameter DATA_WIDTH      = 248,
    parameter CONDITION_WIDTH = 2
) (
    input logic clock,
    input logic reset_n,

    // Enqueue interface
    input  logic                       enqueue_valid,
    output logic                       enqueue_ready,
    input  logic [     DATA_WIDTH-1:0] enqueue_data,
    input  logic [CONDITION_WIDTH-1:0] enqueue_condition,

    // Dequeue interface
    output logic                       dequeue_valid,
    input  logic                       dequeue_ready,
    output logic [     DATA_WIDTH-1:0] dequeue_data,
    output logic [CONDITION_WIDTH-1:0] dequeue_condition,
    output logic [  (DEPTH_LOG+1)-1:0] dequeue_selfid,

    // Flush interface
    input logic                     flush_valid,
    input logic [(DEPTH_LOG+1)-1:0] flush_robid,

    // Update condition interface (pointer-based)
    input logic                       update_valid,
    input logic [CONDITION_WIDTH-1:0] update_mask,
    input logic [    `ROB_SIZE_LOG:0] update_robid,
    input logic [CONDITION_WIDTH-1:0] update_data
);


    localparam SELFID_WIDTH = DEPTH_LOG + 1;
    // 'entry_id_dispatcher' increments on enqueue only
    logic   [   SELFID_WIDTH-1:0] entry_id_dispatcher;
    logic   [     DATA_WIDTH-1:0] data_out_dec               [0:DEPTH-1];
    logic   [CONDITION_WIDTH-1:0] condition_out_dec          [0:DEPTH-1];
    logic   [   SELFID_WIDTH-1:0] index_out_dec              [0:DEPTH-1];
    logic                         valid_out_dec              [0:DEPTH-1];
    logic                         rdy2dq_out_dec             [0:DEPTH-1];

    // Write/clear/update signals
    logic   [          0:DEPTH-1] wr_en_dec;
    logic   [          0:DEPTH-1] clear_dec;
    logic   [          0:DEPTH-1] needflush_dec;
    logic   [          0:DEPTH-1] update_valid_dec;

    // Next input signals used when wr_en=1
    logic   [     DATA_WIDTH-1:0] data_in_next;
    logic   [CONDITION_WIDTH-1:0] condition_in_next;
    logic   [   SELFID_WIDTH-1:0] index_in_next;
    logic                         valid_in_next;

    /* ----------------- writeback to update condition bit logic ---------------- */
    //lets assume robid lie in [247:241] for now
    // Decode update_robid -> one-hot
    integer                       j;
    always_comb begin
        for (j = 0; j < DEPTH; j++) begin
            update_valid_dec[j] = (update_robid == data_out[j][247:241]) && update_valid;
        end
    end

    // Generate cqentry dec
    genvar i;
    generate
        for (i = 0; i < DEPTH; i++) begin : gen_cqentries
            cqentry #(
                .DATA_WIDTH     (DATA_WIDTH),
                .CONDITION_WIDTH(CONDITION_WIDTH),
                .INDEX_WIDTH    (SELFID_WIDTH)
            ) cqentry_i (
                .clock  (clock),
                .reset_n(reset_n),

                .wr_en      (wr_en_dec[i]),
                .clear_entry(clear_dec[i]),

                .data_in     (data_in_next),
                .condition_in(condition_in_next),
                .index_in    (index_in_next),
                .valid_in    (valid_in_next),

                // Update condition signals
                .update_valid(update_valid_dec[i]),
                .update_mask (update_mask),
                .update_in   (update_data),

                // Outputs
                .data_out            (data_out_dec[i]),
                .condition_out       (condition_out_dec[i]),
                .index_out           (index_out_dec[i]),
                .valid_out           (valid_out_dec[i]),
                .ready_to_dequeue_out(rdy2dq_out_dec[i])
            );
        end
    endgenerate

    // ----------------------------------------------------
    // 3) Pointers, Count
    // ----------------------------------------------------
    logic [DEPTH_LOG-1:0] enqueue_ptr;
    logic [DEPTH_LOG-1:0] dequeue_ptr;
    logic [  DEPTH_LOG:0] count;  // 0..DEPTH

    wire                  full = (count == DEPTH);
    wire                  empty = (count == 0);

    // Enqueue logic
    assign enqueue_ready = !full;

    always_ff @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            enqueue_ptr         <= '0;
            count               <= '0;
            entry_id_dispatcher <= '0;
        end else begin
            // Highest priority: flush
            if (flush_valid) begin
                enqueue_ptr         <= flush_robid[DEPTH_LOG-1:0];
                entry_id_dispatcher <= flush_robid + 1;
            end  // Next: normal enqueue
            else if (enqueue_valid && enqueue_ready) begin
                enqueue_ptr         <= (enqueue_ptr + 1) % DEPTH;
                count               <= count + 1;
                // No decrement on dequeue
                entry_id_dispatcher <= entry_id_dispatcher + 1;
            end
        end
    end

    // Dequeue logic
    wire front_ready = rdy2dq_out_dec[dequeue_ptr];
    assign dequeue_valid     = (!empty) && front_ready;

    assign dequeue_data      = data_out_dec[dequeue_ptr];
    assign dequeue_condition = condition_out_dec[dequeue_ptr];
    assign dequeue_selfid    = index_out_dec[dequeue_ptr];

    always_ff @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            dequeue_ptr <= '0;
        end else begin
            if (dequeue_valid && dequeue_ready) begin
                dequeue_ptr <= (dequeue_ptr + 1) % DEPTH;
                count       <= count - 1;
            end
        end
    end

    // ----------------------------------------------------
    // 4) Wr_en & Clear signals
    // ----------------------------------------------------
    always_comb begin
        wr_en_dec         = '0;
        clear_dec         = '0;

        data_in_next      = '0;
        condition_in_next = '0;
        index_in_next     = '0;
        valid_in_next     = 1'b0;

        // Enqueue
        if (enqueue_valid && enqueue_ready && !flush_valid) begin
            wr_en_dec[enqueue_ptr] = 1'b1;

            data_in_next           = enqueue_data;
            condition_in_next      = enqueue_condition;
            index_in_next          = entry_id_dispatcher;
            valid_in_next          = 1'b1;
        end

        // Dequeue => clear that slot
        if (dequeue_valid && dequeue_ready) begin
            clear_dec[dequeue_ptr] = 1'b1;
        end
        if (rob_state == `ROB_STATE_ROLLILNGBACK) begin
            clear_dec = needflush_dec;
        end
    end

    /* ------------------------------- flush logic ------------------------------ */
    //lets assume robid lie in [247:241] for now
    //find req younger than flush_robid
    always @(*) begin
        integer i;
        needflush_dec = 'b0;
        for (i = 0; i < DEPTH; i = i + 1) begin
            if (rob_state == `ROB_STATE_ROLLILNGBACK) begin
                needflush_dec[i] = flush_robid[`ROB_SIZE_LOG] ^ data_out[i][247] ^ (flush_robid[`ROB_SIZE_LOG-1:0] < data_out[i][246:241]);
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
