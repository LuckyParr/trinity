`include "defines.sv"
module exu (
    input wire clock,
    input wire reset_n,
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
    input wire [      `INSTR_RANGE] instr,

    output wire             redirect_valid,
    output wire [`PC_RANGE] redirect_target,

    output wire [`RESULT_RANGE] ls_address,
    output wire [`RESULT_RANGE] alu_result,
    output wire [`RESULT_RANGE] bju_result,
    output wire [`RESULT_RANGE] muldiv_result
    


);
    //forwarding logic
    reg need_to_wb_dly;
    always @(posedge clock or negedge reset_n) begin
        if(~reset_n)begin
            need_to_wb_dly <= 0;
        end else
            need_to_wb_dly <= need_to_wb; 
    end

    reg [`LREG_RANGE] rd_dly;
    reg [`RESULT_RANGE] alu_result_dly;

    always @(posedge clock or negedge reset_n) begin
        if(~reset_n)begin
            rd_dly <= 0;
            alu_result_dly <= 0;
        end else begin
            rd_dly <= rd; 
            alu_result_dly <= alu_result;
        end
    end

     wire [        `SRC_RANGE] src1_muxed;
     wire [        `SRC_RANGE] src2_muxed;
     wire src1_need_forward;
     wire src2_need_forward;
     assign src1_need_forward = (need_to_wb_dly && (rd_dly == rs1));
     assign src2_need_forward = (need_to_wb_dly && (rd_dly == rs2));
     
     assign src1_muxed = src1_need_forward?alu_result_dly:src1;
     assign src2_muxed = src2_need_forward?alu_result_dly:src2;



    //exu logic
    wire alu_valid = |alu_type;
    wire agu_valid = is_load | is_store;
    wire bju_valid = |cx_type;
    wire muldiv_valid = |muldiv_type;


    agu u_agu (
        .src1      (src1_muxed),
        .imm       (imm),
        .is_load   (is_load),
        .is_store  (is_store),
        .ls_address(ls_address)
    );

    alu u_alu (
        .src1       (src1_muxed),
        .src2       (src2_muxed),
        .imm        (imm),
        .pc         (pc),
        .valid      (alu_valid),
        .alu_type   (alu_type),
        .is_word    (is_word),
        .is_unsigned(is_unsigned),
        .is_imm     (is_imm),
        .result     (alu_result)
    );

    bju u_bju (
        .src1           (src1_muxed),
        .src2           (src2_muxed),
        .imm            (imm),
        .pc             (pc),
        .cx_type        (cx_type),
        .valid          (bju_valid),
        .is_unsigned    (is_unsigned),
        .dest           (bju_result),
        .redirect_valid (redirect_valid),
        .redirect_target(redirect_target)
    );

    muldiv u_muldiv (
        .src1       (src1_muxed),
        .src2       (src2_muxed),
        .valid      (muldiv_valid),
        .muldiv_type(muldiv_type),
        .result     (muldiv_result)
    );

endmodule
