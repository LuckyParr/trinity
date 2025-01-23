`include "defines.sv"
module pipereg_intwb (
    input  wire                          clock,
    input  wire                          reset_n,
    input  wire                          intblock_out_instr_valid,
    input  wire                          intblock_out_need_to_wb,
    input  wire [`PREG_LENGTH-1:0]       intblock_out_prd,
    input  wire [63:0]                   intblock_out_result,
    input  wire                          intblock_out_redirect_valid,
    input  wire [63:0]                   intblock_out_redirect_target,
    input  wire [`INSTR_ID_WIDTH:0]      intblock_out_id,
    input  wire                           bjusb_bht_write_enable,
    input  wire [`BHTBTB_INDEX_WIDTH-1:0] bjusb_bht_write_index,
    input  wire [1:0]                     bjusb_bht_write_counter_select,
    input  wire                           bjusb_bht_write_inc,
    input  wire                           bjusb_bht_write_dec,
    input  wire                           bjusb_bht_valid_in,
    input  wire                           bjusb_btb_ce,
    input  wire                           bjusb_btb_we,
    input  wire [128:0]                   bjusb_btb_wmask,
    input  wire [8:0]                     bjusb_btb_write_index,
    input  wire [128:0]                   bjusb_btb_din,
    output reg                          intwb_instr_valid,
    output reg                          intwb_need_to_wb,
    output reg [`PREG_LENGTH-1:0]       intwb_prd,
    output reg [63:0]                   intwb_result,
    output reg                          intwb_redirect_valid,// rename to flush_valid
    output reg [63:0]                   intwb_redirect_target,// rename to flush_target
    output reg [`INSTR_ID_WIDTH-1:0]    intwb_id, // rename to flush_id
    output reg                          intwb_bjusb_bht_write_enable,
    output reg [`BHTBTB_INDEX_WIDTH-1:0]intwb_bjusb_bht_write_index,
    output reg [1:0]                    intwb_bjusb_bht_write_counter_select,
    output reg                          intwb_bjusb_bht_write_inc,
    output reg                          intwb_bjusb_bht_write_dec,
    output reg                          intwb_bjusb_bht_valid_in,
    output reg                          intwb_bjusb_btb_ce,
    output reg                          intwb_bjusb_btb_we,
    output reg [128:0]                  intwb_bjusb_btb_wmask,
    output reg [8:0]                    intwb_bjusb_btb_write_index,
    output reg [128:0]                  intwb_bjusb_btb_din
);

    `MACRO_DFF_NONEN(intwb_instr_valid, intblock_out_instr_valid, 1)
    `MACRO_DFF_NONEN(intwb_need_to_wb, intblock_out_need_to_wb, 1)
    `MACRO_DFF_NONEN(intwb_prd, intblock_out_prd, `PREG_LENGTH)
    `MACRO_DFF_NONEN(intwb_result, intblock_out_result, 64)
    `MACRO_DFF_NONEN(intwb_redirect_valid, intblock_out_redirect_valid, 1)
    `MACRO_DFF_NONEN(intwb_redirect_target, intblock_out_redirect_target, 64)
    `MACRO_DFF_NONEN(intwb_id, intblock_out_id,`INSTR_ID_WIDTH)

    `MACRO_DFF_NONEN(intwb_bjusb_bht_write_enable        , bjusb_bht_write_enable, 1)
    `MACRO_DFF_NONEN(intwb_bjusb_bht_write_index         , bjusb_bht_write_index, `BHTBTB_INDEX_WIDTH)
    `MACRO_DFF_NONEN(intwb_bjusb_bht_write_counter_select, bjusb_bht_write_counter_select, 2)
    `MACRO_DFF_NONEN(intwb_bjusb_bht_write_inc           , bjusb_bht_write_inc, 1)
    `MACRO_DFF_NONEN(intwb_bjusb_bht_write_dec           , bjusb_bht_write_dec, 1)
    `MACRO_DFF_NONEN(intwb_bjusb_bht_valid_in            , bjusb_bht_valid_in, 1)

    `MACRO_DFF_NONEN(intwb_bjusb_btb_ce         , bjusb_btb_ce, 1)
    `MACRO_DFF_NONEN(intwb_bjusb_btb_we         , bjusb_btb_we, 1)
    `MACRO_DFF_NONEN(intwb_bjusb_btb_wmask      , bjusb_btb_wmask, 129)
    `MACRO_DFF_NONEN(intwb_bjusb_btb_write_index, bjusb_btb_write_index, 9)
    `MACRO_DFF_NONEN(intwb_bjusb_btb_din        , bjusb_btb_din, 129)

endmodule
