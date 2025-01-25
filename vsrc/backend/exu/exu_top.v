/*************************************************************
 * exu.v
 *
 * A top-level wrapper module for the two sub-blocks:
 *   1) intblock
 *   2) memblock
 *
 *************************************************************/

`include "defines.v"  
module exu_top #(
    parameter BHTBTB_INDEX_WIDTH = 9
)(
    input wire clock,
    input wire reset_n,

    //----------------------------------------------------------
    // Interface to INTBLOCK
    //----------------------------------------------------------
    input  wire                      int_instr_valid,
    output wire                      int_instr_ready,
    input  wire [      `INSTR_RANGE] int_instr,  // for debug
    input  wire [         `PC_RANGE] int_pc,
    input  wire [`INSTR_ID_WIDTH-1:0] int_id,

    input  wire [        `SRC_RANGE] int_src1,
    input  wire [        `SRC_RANGE] int_src2,
    input  wire [       `PREG_RANGE] int_prd,
    input  wire [        `SRC_RANGE] int_imm,
    input  wire                      int_need_to_wb,
    input  wire [    `CX_TYPE_RANGE] int_cx_type,
    input  wire                      int_is_unsigned,
    input  wire [   `ALU_TYPE_RANGE] int_alu_type,
    input  wire [`MULDIV_TYPE_RANGE] int_muldiv_type,
    input  wire                      int_is_imm,
    input  wire                      int_is_word,

    // BHT/BTB prediction
    input  wire                      int_predict_taken,
    input  wire [31:0]              int_predict_target,

    // Outputs from intblock
    output wire                      int_out_instr_valid,
    output wire [      `INSTR_RANGE] int_out_instr,   // debug
    output wire [         `PC_RANGE] int_out_pc,      // debug
    output wire [`INSTR_ID_WIDTH-1:0] int_out_id,

    output wire [`RESULT_RANGE]      int_out_result,
    output wire                      int_out_need_to_wb,
    output wire [       `PREG_RANGE] int_out_prd,

    output wire                      int_redirect_valid,
    output wire [       `PC_RANGE]   int_redirect_target,

    output wire [`RESULT_RANGE]      int_ex_byp_result,

    // BHT/BTB Update
    output wire                      bjusb_bht_write_enable,           
    output wire [BHTBTB_INDEX_WIDTH-1:0] bjusb_bht_write_index,       
    output wire [1:0]               bjusb_bht_write_counter_select,
    output wire                      bjusb_bht_write_inc,
    output wire                      bjusb_bht_write_dec,
    output wire                      bjusb_bht_valid_in,

    output wire                      bjusb_btb_ce,
    output wire                      bjusb_btb_we,
    output wire [128:0]             bjusb_btb_wmask,
    output wire [8:0]               bjusb_btb_write_index,
    output wire [128:0]             bjusb_btb_din,

    //----------------------------------------------------------
    // Interface to MEMBLOCK
    //----------------------------------------------------------
    input  wire                      mem_instr_valid,
    output wire                      mem_instr_ready,
    input  wire [  `INSTR_RANGE]     mem_instr,  // for debug
    input  wire [     `PC_RANGE]     mem_pc,     // for debug
    input  wire [`INSTR_ID_WIDTH-1:0] mem_id,

    // Calculation material for memory ops
    input  wire [  `SRC_RANGE]       mem_src1,
    input  wire [  `SRC_RANGE]       mem_src2,
    input  wire [`PREG_RANGE]        mem_prd,
    input  wire [  `SRC_RANGE]       mem_imm,
    input  wire                      mem_is_load,
    input  wire                      mem_is_store,
    input  wire                      mem_is_unsigned,
    input  wire [`LS_SIZE_RANGE]     mem_ls_size,

    // Trinity bus channel
    output wire                      tbus_index_valid,
    input  wire                      tbus_index_ready,
    output wire [`RESULT_RANGE]      tbus_index,
    output wire [   `SRC_RANGE]      tbus_write_data,
    output wire [            63:0]   tbus_write_mask,

    input  wire [ `RESULT_RANGE]     tbus_read_data,
    input  wire                      tbus_operation_done,
    output wire [`TBUS_OPTYPE_RANGE] tbus_operation_type,

    // MEMBLOCK outputs
    output wire                      mem_out_instr_valid,
    output wire [`INSTR_ID_WIDTH-1:0] mem_out_id,
    output wire [       `PREG_RANGE] mem_out_prd,
    output wire                      mem_out_need_to_wb,
    output wire                      mem_out_mmio_valid,
    output wire [`RESULT_RANGE]      mem_out_opload_rddata,

    //----------------------------------------------------------
    // Shared flush signals
    //----------------------------------------------------------
    input  wire                      flush_valid,
    input  wire [`INSTR_ID_WIDTH-1:0] flush_id,

    // Dcache flush (from memblock)
    output wire                      mem2dcache_flush
);

//============================================================
// 1) Instantiate the INTBLOCK
//============================================================
intblock #(
    .BHTBTB_INDEX_WIDTH (BHTBTB_INDEX_WIDTH)
) u_intblock (
    // Common
    .clock              (clock),
    .reset_n            (reset_n),

    // Handshake
    .instr_valid        (int_instr_valid),
    .instr_ready        (int_instr_ready),

    // Debug info
    .instr              (int_instr),
    .pc                 (int_pc),
    .id                 (int_id),

    // Execution input
    .src1               (int_src1),
    .src2               (int_src2),
    .prd                (int_prd),
    .imm                (int_imm),
    .need_to_wb         (int_need_to_wb),
    .cx_type            (int_cx_type),
    .is_unsigned        (int_is_unsigned),
    .alu_type           (int_alu_type),
    .muldiv_type        (int_muldiv_type),
    .is_imm             (int_is_imm),
    .is_word            (int_is_word),

    // BHT/BTB
    .predict_taken      (int_predict_taken),
    .predict_target     (int_predict_target),

    // Outputs
    .out_instr_valid    (int_out_instr_valid),
    .out_instr          (int_out_instr),
    .out_pc             (int_out_pc),
    .out_id             (int_out_id),
    .out_result         (int_out_result),
    .out_need_to_wb     (int_out_need_to_wb),
    .out_prd            (int_out_prd),

    .redirect_valid     (int_redirect_valid),
    .redirect_target    (int_redirect_target),
    .ex_byp_result      (int_ex_byp_result),

    // BHT/BTB Update
    .bjusb_bht_write_enable       (bjusb_bht_write_enable),
    .bjusb_bht_write_index        (bjusb_bht_write_index),
    .bjusb_bht_write_counter_select(bjusb_bht_write_counter_select),
    .bjusb_bht_write_inc          (bjusb_bht_write_inc),
    .bjusb_bht_write_dec          (bjusb_bht_write_dec),
    .bjusb_bht_valid_in           (bjusb_bht_valid_in),

    .bjusb_btb_ce                 (bjusb_btb_ce),
    .bjusb_btb_we                 (bjusb_btb_we),
    .bjusb_btb_wmask              (bjusb_btb_wmask),
    .bjusb_btb_write_index        (bjusb_btb_write_index),
    .bjusb_btb_din                (bjusb_btb_din),

    // Flush
    .flush_valid        (flush_valid),
    .flush_id           (flush_id)
);

//============================================================
// 2) Instantiate the MEMBLOCK
//============================================================
memblock u_memblock (
    .clock             (clock),
    .reset_n           (reset_n),

    // Handshake
    .instr_valid       (mem_instr_valid),
    .instr_ready       (mem_instr_ready),

    // Debug info
    .instr             (mem_instr),
    .pc                (mem_pc),
    .id                (mem_id),

    // Execution input for load/store
    .src1              (mem_src1),
    .src2              (mem_src2),
    .prd               (mem_prd),
    .imm               (mem_imm),
    .is_load           (mem_is_load),
    .is_store          (mem_is_store),
    .is_unsigned       (mem_is_unsigned),
    .ls_size           (mem_ls_size),

    // Trinity bus
    .tbus_index_valid  (tbus_index_valid),
    .tbus_index_ready  (tbus_index_ready),
    .tbus_index        (tbus_index),
    .tbus_write_data   (tbus_write_data),
    .tbus_write_mask   (tbus_write_mask),

    .tbus_read_data    (tbus_read_data),
    .tbus_operation_done (tbus_operation_done),
    .tbus_operation_type (tbus_operation_type),

    // Outputs
    .out_instr_valid   (mem_out_instr_valid),
    .out_id            (mem_out_id),
    .out_prd           (mem_out_prd),
    .out_need_to_wb    (mem_out_need_to_wb),
    .out_mmio_valid    (mem_out_mmio_valid),
    .out_opload_rddata (mem_out_opload_rddata),

    // Flush
    .flush_valid       (flush_valid),
    .flush_id          (flush_id),
    .mem2dcache_flush  (mem2dcache_flush)
);

endmodule
