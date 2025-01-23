`include "defines.sv"
module pipereg_memwb #(
) (
    input  wire                          clock,
    input  wire                          reset_n,
    input wire                          memblock_out_instr_valid,
    input wire [`INSTR_ID_WIDTH-1:0]    memblock_out_id,
    input wire [`PREG_RANGE]            memblock_out_prd,
    input wire                          memblock_out_need_to_wb,
    input wire                          memblock_out_mmio_valid,
    input wire [`RESULT_RANGE]          memblock_out_opload_rddata, 
    //output
    output wire                           memwb_out_instr_valid,
    output wire [`INSTR_ID_WIDTH-1:0]     memwb_out_id,
    output wire [`PREG_RANGE]             memwb_out_prd,
    output wire                           memwb_out_need_to_wb,
    output wire                           memwb_out_mmio_valid,
    output wire [`RESULT_RANGE]           memwb_out_opload_rddata, 
);

    `MACRO_DFF_NONEN(memwb_out_instr_valid, memblock_out_instr_valid, 1)
    `MACRO_DFF_NONEN(memwb_out_id, memblock_out_id, `INSTR_ID_WIDTH)
    `MACRO_DFF_NONEN(memwb_out_prd, memblock_out_prd, 6)
    `MACRO_DFF_NONEN(memwb_out_need_to_wb, memblock_out_need_to_wb, 1)
    `MACRO_DFF_NONEN(memwb_out_mmio_valid, memblock_out_mmio_valid, 1)
    `MACRO_DFF_NONEN(memwb_out_opload_rddata, memblock_out_opload_rddata, 64)

endmodule