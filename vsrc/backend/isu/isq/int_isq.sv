module int_isq (
    input logic clock,
    input logic reset_n,

    //-----------------------------------------------------
    // Enqueue interface
    //-----------------------------------------------------
    input  logic [     `ISQ_DATA_WIDTH-1:0] enq_data,
    input  logic [`ISQ_CONDITION_WIDTH-1:0] enq_condition,
    input  logic                            enq_valid,
    output logic                            enq_ready,

    //-----------------------------------------------------
    // Dequeue interface
    //-----------------------------------------------------
    output logic [ `ISQ_DATA_WIDTH-1:0] deq_data,
    output logic                        deq_valid,
    input  logic                        deq_ready,

    //-----------------------------------------------------
    // writeback to set condition to 1
    //-----------------------------------------------------
    input wire               writeback0_valid,
    input wire               writeback0_need_to_wb,
    input wire [`PREG_RANGE] writeback0_prd,

    input wire                      writeback1_valid,
    input wire                      writeback1_need_to_wb,
    input wire  [      `PREG_RANGE] writeback1_prd,
    //-----------------------------------------------------
    // Flush interface
    //-----------------------------------------------------
    input logic [              1:0] rob_state,
    input logic                     flush_valid,
    input logic [`INSTR_ID_WIDTH:0] flush_robid,

    output logic intisq_can_enq
);
    //output dec
    logic [          `ISQ_DEPTH-1:0][     `ISQ_DATA_WIDTH-1:0] data_out_dec;
    logic [          `ISQ_DEPTH-1:0][`ISQ_CONDITION_WIDTH-1:0] condition_out_dec;
    logic [          `ISQ_DEPTH-1:0][    `ISQ_INDEX_WIDTH-1:0] index_out_dec;
    logic [          `ISQ_DEPTH-1:0]                           valid_out_dec;

    //-----------------------------------------------------
    // condition updates for writeback0
    //-----------------------------------------------------
    logic                                                      update_valid;
    logic [       `INSTR_ID_WIDTH:0]                           update_robid;
    logic [`ISQ_CONDITION_WIDTH-1:0]                           update_mask;
    logic [`ISQ_CONDITION_WIDTH-1:0]                           update_in;

    assign update_valid = (writeback0_valid && writeback0_need_to_wb && (writeback0_prd_match_prs1 || writeback0_prd_match_prs2)) | (writeback1_valid && writeback1_need_to_wb && (writeback1_prd_match_prs1 || writeback1_prd_match_prs2));

    reg writeback0_prd_match_prs1;
    reg writeback0_prd_match_prs2;
    reg writeback1_prd_match_prs1;
    reg writeback1_prd_match_prs2;

    always @(*) begin
        integer i;
        update_mask               = 0;
        update_in                 = 0;
        update_robid              = 0;
        writeback0_prd_match_prs1 = 0;
        writeback0_prd_match_prs2 = 0;
        writeback1_prd_match_prs1 = 0;
        writeback1_prd_match_prs2 = 0;
        for (i = 0; i < `ISQ_DEPTH; i = i + 1) begin
            //instr0_prs1
            if ((data_out_dec[i][116 : 111] == writeback0_prd) && valid_out_dec[i]) begin
                update_mask               = 2'b10;
                update_in                 = 2'b10;
                update_robid              = index_out_dec[i];
                writeback0_prd_match_prs1 = 1'b1;
            end
            //instr0_prs2
            if ((data_out_dec[i][110 : 105] == writeback0_prd) && valid_out_dec[i]) begin
                update_mask               = 2'b01;
                update_in                 = 2'b01;
                update_robid              = index_out_dec[i];
                writeback0_prd_match_prs2 = 1'b1;
            end

            //wb1
            if ((data_out_dec[i][116 : 111] == writeback1_prd) && valid_out_dec[i]) begin
                update_mask               = 2'b10;
                update_in                 = 2'b10;
                update_robid              = index_out_dec[i];
                writeback1_prd_match_prs1 = 1'b1;
            end
            //wb1
            if ((data_out_dec[i][110 : 105] == writeback1_prd) && valid_out_dec[i]) begin
                update_mask               = 2'b01;
                update_in                 = 2'b01;
                update_robid              = index_out_dec[i];
                writeback1_prd_match_prs2 = 1'b1;
            end
        end
    end


    //check if age buffer have available entry
    assign intisq_can_enq = enq_ready;

    // --------------------------------------------------------------------
    // Instantiate the age_buffer module
    // --------------------------------------------------------------------
    age_buffer_1r1w u_age_buffer (
        .clock  (clock),
        .reset_n(reset_n),

        // Enqueue
        .enq_data     (enq_data),
        .enq_condition(enq_condition),
        //.enq_index                (enq_index),
        .enq_valid    (enq_valid),
        .enq_ready    (enq_ready),

        // Dequeue
        .deq_data (deq_data),
        .deq_valid(deq_valid),
        .deq_ready(deq_ready),

        // Condition updates
        .update_valid(update_valid),
        .update_robid(update_robid),
        .update_mask (update_mask),
        .update_in   (update_in),

        // Flush interface
        .rob_state  (rob_state),
        .flush_valid(flush_valid),
        .flush_robid(flush_robid),

        //output dec
        .data_out_dec     (data_out_dec),
        .condition_out_dec(condition_out_dec),
        .index_out_dec    (index_out_dec),
        .valid_out_dec    (valid_out_dec)
    );

endmodule
