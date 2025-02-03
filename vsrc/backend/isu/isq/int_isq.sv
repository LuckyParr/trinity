module int_isq (
    input  wire clock,
    input  wire reset_n,
    //ready sigs,cause dispathc only can dispatch when rob,IQ,SQ both have avail entry
    output wire iq_can_alloc0,
    input  wire sq_can_alloc,
    input  wire all_iq_ready,

    input wire               enq_instr0_valid,
    input wire [`LREG_RANGE] enq_instr0_lrs1,
    input wire [`LREG_RANGE] enq_instr0_lrs2,
    input wire [`LREG_RANGE] enq_instr0_lrd,
    input wire [  `PC_RANGE] enq_instr0_pc,
    input wire [       31:0] enq_instr0,

    input wire [              63:0] enq_instr0_imm,
    input wire                      enq_instr0_src1_is_reg,
    input wire                      enq_instr0_src2_is_reg,
    input wire                      enq_instr0_need_to_wb,
    input wire [    `CX_TYPE_RANGE] enq_instr0_cx_type,
    input wire                      enq_instr0_is_unsigned,
    input wire [   `ALU_TYPE_RANGE] enq_instr0_alu_type,
    input wire [`MULDIV_TYPE_RANGE] enq_instr0_muldiv_type,
    input wire                      enq_instr0_is_word,
    input wire                      enq_instr0_is_imm,
    input wire                      enq_instr0_is_load,
    input wire                      enq_instr0_is_store,
    input wire [               3:0] enq_instr0_ls_size,

    input wire [`PREG_RANGE] enq_instr0_prs1,
    input wire [`PREG_RANGE] enq_instr0_prs2,
    input wire [`PREG_RANGE] enq_instr0_prd,
    input wire [`PREG_RANGE] enq_instr0_old_prd,

    input wire                     enq_instr0_robidx_flag,
    input wire [`ROB_SIZE_LOG-1:0] enq_instr0_robidx,

    input wire                       enq_instr0_sqidx_flag,
    input wire [`STOREQUEUE_LOG-1:0] enq_instr0_sqidx,
    /* -------------------------------- src state ------------------------------- */
    input wire                       enq_instr0_src1_state,
    input wire                       enq_instr0_src2_state,

    /* ------------------------------- output to execute block ------------------------------- */
    output wire               issue0_valid,
    //temp sig
    input  wire               issue0_ready,
    output reg  [`PREG_RANGE] issue0_prs1,
    output reg  [`PREG_RANGE] issue0_prs2,
    output reg                issue0_src1_is_reg,
    output reg                issue0_src2_is_reg,

    output reg [`PREG_RANGE] issue0_prd,
    output reg [`PREG_RANGE] issue0_old_prd,

    output reg [`SRC_RANGE] issue0_pc,
    // output reg [`INSTR_RANGE] issue0,
    output reg [`SRC_RANGE] issue0_imm,

    output reg                      issue0_need_to_wb,
    output reg [    `CX_TYPE_RANGE] issue0_cx_type,
    output reg                      issue0_is_unsigned,
    output reg [   `ALU_TYPE_RANGE] issue0_alu_type,
    output reg [`MULDIV_TYPE_RANGE] issue0_muldiv_type,
    output reg                      issue0_is_word,
    output reg                      issue0_is_imm,
    output reg                      issue0_is_load,
    output reg                      issue0_is_store,
    output reg [               3:0] issue0_ls_size,

    output reg                       issue0_robidx_flag,
    output reg [  `ROB_SIZE_LOG-1:0] issue0_robidx,
    output reg                       issue0_sqidx_flag,
    output reg [`STOREQUEUE_LOG-1:0] issue0_sqidx,



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


    /* -------------------------------------------------------------------------- */
    /*                                   enq dec                                  */
    /* -------------------------------------------------------------------------- */

    reg  [`ISSUE_QUEUE_DEPTH-1:0] iq_entries_enq_valid_dec;
    reg  [             `PC_RANGE] iq_entries_enq_pc_dec          [`ISSUE_QUEUE_DEPTH-1:0];
    reg  [           `PREG_RANGE] iq_entries_enq_prs1_dec        [`ISSUE_QUEUE_DEPTH-1:0];
    reg  [           `PREG_RANGE] iq_entries_enq_prs2_dec        [`ISSUE_QUEUE_DEPTH-1:0];
    reg  [`ISSUE_QUEUE_DEPTH-1:0] iq_entries_enq_src1_is_reg_dec;
    reg  [`ISSUE_QUEUE_DEPTH-1:0] iq_entries_enq_src2_is_reg_dec;
    reg  [`ISSUE_QUEUE_DEPTH-1:0] iq_entries_enq_src1_state_dec;
    reg  [`ISSUE_QUEUE_DEPTH-1:0] iq_entries_enq_src2_state_dec;
    reg  [           `PREG_RANGE] iq_entries_enq_prd_dec         [`ISSUE_QUEUE_DEPTH-1:0];
    reg  [           `PREG_RANGE] iq_entries_enq_old_prd_dec     [`ISSUE_QUEUE_DEPTH-1:0];
    reg  [                  31:0] iq_entries_enq_instr_dec       [`ISSUE_QUEUE_DEPTH-1:0];
    reg  [            `SRC_RANGE] iq_entries_enq_imm_dec         [`ISSUE_QUEUE_DEPTH-1:0];
    reg                           iq_entries_enq_need_to_wb_dec  [`ISSUE_QUEUE_DEPTH-1:0];
    reg  [        `CX_TYPE_RANGE] iq_entries_enq_cx_type_dec     [`ISSUE_QUEUE_DEPTH-1:0];
    reg                           iq_entries_enq_is_unsigned_dec [`ISSUE_QUEUE_DEPTH-1:0];
    reg  [       `ALU_TYPE_RANGE] iq_entries_enq_alu_type_dec    [`ISSUE_QUEUE_DEPTH-1:0];
    reg  [    `MULDIV_TYPE_RANGE] iq_entries_enq_muldiv_type_dec [`ISSUE_QUEUE_DEPTH-1:0];
    reg  [`ISSUE_QUEUE_DEPTH-1:0] iq_entries_enq_is_word_dec;
    reg  [`ISSUE_QUEUE_DEPTH-1:0] iq_entries_enq_is_imm_dec;
    reg  [`ISSUE_QUEUE_DEPTH-1:0] iq_entries_enq_is_load_dec;
    reg  [`ISSUE_QUEUE_DEPTH-1:0] iq_entries_enq_is_store_dec;
    reg  [                   3:0] iq_entries_enq_ls_size_dec     [`ISSUE_QUEUE_DEPTH-1:0];
    reg  [`ISSUE_QUEUE_DEPTH-1:0] iq_entries_enq_robidx_flag_dec;
    reg  [     `ROB_SIZE_LOG-1:0] iq_entries_enq_robidx_dec      [`ISSUE_QUEUE_DEPTH-1:0];
    reg  [`ISSUE_QUEUE_DEPTH-1:0] iq_entries_enq_sqidx_flag_dec;
    reg  [   `STOREQUEUE_LOG-1:0] iq_entries_enq_sqidx_dec       [`ISSUE_QUEUE_DEPTH-1:0];
    /* -------------------------------------------------------------------------- */
    /*                                   deq dec                                  */
    /* -------------------------------------------------------------------------- */
    wire [           `PREG_RANGE] iq_entries_deq_prs1_dec        [`ISSUE_QUEUE_DEPTH-1:0];
    wire [           `PREG_RANGE] iq_entries_deq_prs2_dec        [`ISSUE_QUEUE_DEPTH-1:0];
    wire [`ISSUE_QUEUE_DEPTH-1:0] iq_entries_deq_src1_is_reg_dec;
    wire [`ISSUE_QUEUE_DEPTH-1:0] iq_entries_deq_src2_is_reg_dec;
    wire [           `PREG_RANGE] iq_entries_deq_prd_dec         [`ISSUE_QUEUE_DEPTH-1:0];
    wire [           `PREG_RANGE] iq_entries_deq_old_prd_dec     [`ISSUE_QUEUE_DEPTH-1:0];
    wire [             `PC_RANGE] iq_entries_deq_pc_dec          [`ISSUE_QUEUE_DEPTH-1:0];
    wire [                  31:0] iq_entries_deq_instr_dec       [`ISSUE_QUEUE_DEPTH-1:0];
    wire [            `SRC_RANGE] iq_entries_deq_imm_dec         [`ISSUE_QUEUE_DEPTH-1:0];
    wire                          iq_entries_deq_need_to_wb_dec  [`ISSUE_QUEUE_DEPTH-1:0];
    wire [        `CX_TYPE_RANGE] iq_entries_deq_cx_type_dec     [`ISSUE_QUEUE_DEPTH-1:0];
    wire                          iq_entries_deq_is_unsigned_dec [`ISSUE_QUEUE_DEPTH-1:0];
    wire [       `ALU_TYPE_RANGE] iq_entries_deq_alu_type_dec    [`ISSUE_QUEUE_DEPTH-1:0];
    wire [    `MULDIV_TYPE_RANGE] iq_entries_deq_muldiv_type_dec [`ISSUE_QUEUE_DEPTH-1:0];
    wire [`ISSUE_QUEUE_DEPTH-1:0] iq_entries_deq_is_word_dec;
    wire [`ISSUE_QUEUE_DEPTH-1:0] iq_entries_deq_is_imm_dec;
    wire [`ISSUE_QUEUE_DEPTH-1:0] iq_entries_deq_is_load_dec;
    wire [`ISSUE_QUEUE_DEPTH-1:0] iq_entries_deq_is_store_dec;
    wire [                   3:0] iq_entries_deq_ls_size_dec     [`ISSUE_QUEUE_DEPTH-1:0];
    wire [`ISSUE_QUEUE_DEPTH-1:0] iq_entries_deq_robidx_flag_dec;
    wire [     `ROB_SIZE_LOG-1:0] iq_entries_deq_robidx_dec      [`ISSUE_QUEUE_DEPTH-1:0];
    wire [`ISSUE_QUEUE_DEPTH-1:0] iq_entries_deq_sqidx_flag_dec;
    wire [   `STOREQUEUE_LOG-1:0] iq_entries_deq_sqidx_dec       [`ISSUE_QUEUE_DEPTH-1:0];

    wire [`ISSUE_QUEUE_DEPTH-1:0] iq_entries_ready_to_go_dec;
    wire [`ISSUE_QUEUE_DEPTH-1:0] iq_entries_valid_dec;



    reg  [`ISSUE_QUEUE_DEPTH -1 : 0] enq_ptr_oh;
    reg  [`ISSUE_QUEUE_DEPTH -1 : 0] enq_ptr_oh_next;
    reg  [`ISSUE_QUEUE_DEPTH -1 : 0] deq_ptr_oh;
    reg  [`ISSUE_QUEUE_DEPTH -1 : 0] deq_ptr_oh_next;

    wire                             enq_has_avail_entry;
    wire                             enq_fire;
    assign enq_has_avail_entry = |(enq_ptr_oh & ~iq_entries_valid_dec);
    assign enq_fire            = enq_has_avail_entry & enq_instr0_valid & sq_can_alloc;
    always @(posedge clock or negedge reset_n) begin
        if (~reset_n) begin
            enq_ptr_oh <= 'b1;
        end else begin
            enq_ptr_oh <= enq_ptr_oh_next;
        end
    end







    //check if age buffer have available entry
    assign intisq_can_enq = enq_ready;




    /* -------------------------------------------------------------------------- */
    /*                                 deq age policy                             */
    /* -------------------------------------------------------------------------- */
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
