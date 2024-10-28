`include "defines.sv"
module exu (
    input wire [       `LREG_RANGE] rs1,
    input wire [       `LREG_RANGE] rs2,
    input wire [       `LREG_RANGE] rd,
    input wire [        `SRC_RANGE] src1,
    input wire [        `SRC_RANGE] src2,
    input wire [        `SRC_RANGE] imm,
    input wire                      src1_is_reg,
    input wire                      src2_is_reg,
    input wire                      need_to_wb,
    // input wire is_jump,
    // input wire is_br,
    //sig below is control transfer(xfer) type
    input wire [    `CX_TYPE_RANGE] cx_type,
    input wire                      is_unsigned,
    input wire [   `ALU_TYPE_RANGE] alu_type,
    input wire                      is_word,
    input wire                      is_load,
    input wire                      is_imm,
    input wire                      is_store,
    input wire [               3:0] ls_size,
    input wire [`MULDIV_TYPE_RANGE] muldiv_type,
    input wire [         `PC_RANGE] pc,
    input wire [      `INSTR_RANGE] instr

);
    wire alu_valid = |alu_type;
    wire agu_valid = is_load | is_store;
    wire bju_valid = |cx_type;
    wire muldiv_valid = |muldiv_type;



endmodule
