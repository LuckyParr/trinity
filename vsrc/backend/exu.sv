`include "defines.sv"
module exu #(
        parameter BHTBTB_INDEX_WIDTH = 9           // Width of the set index (for SETS=512, BHTBTB_INDEX_WIDTH=9)
)(
    input wire                      clock,
    input wire                      reset_n,
    input wire [       `LREG_RANGE] rs1,
    input wire [       `LREG_RANGE] rs2,
    input wire [       `LREG_RANGE] rd,
    input wire [        `SRC_RANGE] src1,
    input wire [        `SRC_RANGE] src2,
    input wire [        `SRC_RANGE] imm,
    input wire                      src1_is_reg,
    input wire                      src2_is_reg,
    input wire                      need_to_wb,
    input wire [    `CX_TYPE_RANGE] cx_type,
    input wire                      is_unsigned,
    input wire [   `ALU_TYPE_RANGE] alu_type,
    input wire                      is_word,
    input wire                      is_load,
    input wire                      is_imm,
    input wire                      is_store,
    input wire [               3:0] ls_size,
    input wire [`MULDIV_TYPE_RANGE] muldiv_type,
    input wire                      instr_valid,
    input  wire                  predict_taken,
    input  wire [31:0]           predict_target,  
    input wire [         `PC_RANGE] pc,
    input wire [      `INSTR_RANGE] instr,
    // output valid, pc, inst
    output wire                      instr_valid_out,
    output wire [         `PC_RANGE] pc_out,
    output wire [      `INSTR_RANGE] instr_out,
    //exu result
    output wire [`RESULT_RANGE] alu_result,
    output wire [`RESULT_RANGE] bju_result,
    output wire [`RESULT_RANGE] muldiv_result,
    //output wire [`RESULT_RANGE] ls_address,
    //redirect
    output wire             redirect_valid,
    output wire [`PC_RANGE] redirect_target,
    //bypass exu result to end of dec module
    //output wire [  `LREG_RANGE] ex_byp_rd,
    //output wire                 ex_byp_need_to_wb,
    output wire [`RESULT_RANGE] ex_byp_result,
    //BHT Write Interface
    output wire bjusb_bht_write_enable,                         // Write enable signal
    output wire [BHTBTB_INDEX_WIDTH-1:0] bjusb_bht_write_index,        // Set index for write operation
    output wire [1:0] bjusb_bht_write_counter_select,           // Counter select (0 to 3) within the set
    output wire bjusb_bht_write_inc,                            // Increment signal for the counter
    output wire bjusb_bht_write_dec,                            // Decrement signal for the counter
    output wire bjusb_bht_valid_in,                             // Valid signal for the write operation

    //BTB Write Interface
    output wire bjusb_btb_ce,                    // Chip enable
    output wire bjusb_btb_we,                    // Write enable
    output wire [128:0] bjusb_btb_wmask,
    output wire [8:0]   bjusb_btb_write_index,           // Write address (9 bits for 512 sets)
    output wire [128:0] bjusb_btb_din           // Data input (1 valid bit + 4 targets * 32 bits)
);


    assign instr_valid_out =         instr_valid;
    assign pc_out =      pc;
    assign instr_out =   instr;

    //mem load to use bypass
    wire [`SRC_RANGE] src1_muxed;
    wire [`SRC_RANGE] src2_muxed;
    assign src1_muxed = src1;
    assign src2_muxed = src2;
    

    //exu logic
    wire alu_valid = (|alu_type) & instr_valid;
    wire agu_valid = (is_load | is_store) & instr_valid;
    wire bju_valid = (|cx_type) & instr_valid;
    wire muldiv_valid = (|muldiv_type) & instr_valid;

    assign instr_valid_out = instr_valid;
    assign pc_out = pc;
    assign instr_out = instr;

    //agu u_agu (
    //    .src1      (src1_muxed),
    //    .imm       (imm),
    //    .is_load   (is_load),
    //    .is_store  (is_store),
    //    .ls_address(ls_address)
    //);

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
        .clock (clock),
        .reset_n (reset_n),
        .src1           (src1_muxed),
        .src2           (src2_muxed),
        .imm            (imm),
        .predict_taken      (predict_taken), 
        .predict_target     (predict_target), 
        .pc             (pc),
        .cx_type        (cx_type),
        .valid          (bju_valid),
        .is_unsigned    (is_unsigned),
        .dest           (bju_result),
        .redirect_valid (redirect_valid),
        .redirect_target(redirect_target),
        .bjusb_bht_write_enable (bjusb_bht_write_enable),                 
        .bjusb_bht_write_index (bjusb_bht_write_index),
        .bjusb_bht_write_counter_select (bjusb_bht_write_counter_select),   
        .bjusb_bht_write_inc (bjusb_bht_write_inc),                    
        .bjusb_bht_write_dec (bjusb_bht_write_dec),                    
        .bjusb_bht_valid_in (bjusb_bht_valid_in),  
        .bjusb_btb_ce (bjusb_btb_ce),           
        .bjusb_btb_we (bjusb_btb_we),           
        .bjusb_btb_wmask (bjusb_btb_wmask),
        .bjusb_btb_write_index (bjusb_btb_write_index),
        .bjusb_btb_din (bjusb_btb_din)             
    );

    muldiv u_muldiv (
        .src1       (src1_muxed),
        .src2       (src2_muxed),
        .valid      (muldiv_valid),
        .muldiv_type(muldiv_type),
        .result     (muldiv_result)
    );

    //forwarding logic
    //assign ex_byp_rd         = rd;
    //assign ex_byp_need_to_wb = need_to_wb & instr_valid & (alu_valid | muldiv_valid | bju_valid);
    assign ex_byp_result     = alu_valid ? alu_result : muldiv_valid ? muldiv_result : bju_valid ? bju_result : 64'hDEADBEEF;

    //mem load to use bypass logic
    //wire              src1_need_forward;
    //wire              src2_need_forward;
    //assign src1_need_forward = (rs1 == mem_byp_rd) & mem_byp_need_to_wb;
    //assign src2_need_forward = (rs2 == mem_byp_rd) & mem_byp_need_to_wb;
//
    //wire [`RESULT_RANGE] src1_forward_result;
    //wire [`RESULT_RANGE] src2_forward_result;
//
    //assign src1_forward_result = (rs1 == mem_byp_rd) & mem_byp_need_to_wb ? mem_byp_result : 64'hDEADBEEF;
    //assign src2_forward_result = (rs2 == mem_byp_rd) & mem_byp_need_to_wb ? mem_byp_result : 64'hDEADBEEF;
//
    //assign src1_muxed = src1_need_forward ? src1_forward_result : src1;
    //assign src2_muxed = src2_need_forward ? src2_forward_result : src2;
//
    //assign final_src1 = src1_muxed;
    //assign final_src2 = src2_muxed;
endmodule
