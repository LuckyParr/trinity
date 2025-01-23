`include "defines.sv"
module intblock #(
        parameter BHTBTB_INDEX_WIDTH = 9           // Width of the set index (for SETS=512, BHTBTB_INDEX_WIDTH=9)
)(
    input wire                      clock,
    input wire                      reset_n,
    input wire                      instr_valid,
    output wire                     instr_ready,
    input wire  [      `INSTR_RANGE]   instr,  //for debug
    input wire  [         `PC_RANGE ]  pc,
    input reg   [`INSTR_ID_WIDTH-1:0]  id,

/* -------------------------- calculation meterial -------------------------- */
    //input wire [       `LREG_RANGE] rs1,
    //input wire [       `LREG_RANGE] rs2,
    //input wire [       `LREG_RANGE] rd,
    //input wire                      src1_is_reg,
    //input wire                      src2_is_reg,
    input wire [        `SRC_RANGE] src1,
    input wire [        `SRC_RANGE] src2,
    input wire [       `PREG_RANGE] prd,
    input wire [        `SRC_RANGE] imm,
    input wire                      need_to_wb,
    input wire [    `CX_TYPE_RANGE] cx_type,
    input wire                      is_unsigned,
    input wire [   `ALU_TYPE_RANGE] alu_type,
    input wire [`MULDIV_TYPE_RANGE] muldiv_type,
    input wire                      is_imm,
    input wire                      is_word,
    //input wire                      is_load,
    //input wire                      is_store,
    //input wire [               3:0] ls_size,
/* ------------------------------ bhtbtb input info ------------------------------ */
    input  wire                      predict_taken,
    input  wire [31:0              ] predict_target,
/* ----------------------- output result to wb pipereg ---------------------- */
    // output valid, pc, inst, id
    output wire                      out_instr_valid,
    output wire [      `INSTR_RANGE] out_instr,//for debug
    output wire [         `PC_RANGE] out_pc, //for debug
    output wire [`INSTR_ID_WIDTH-1:0]                out_id,
    //exu result
    // output wire [`RESULT_RANGE] alu_result,
    // output wire [`RESULT_RANGE] bju_result,
    // output wire [`RESULT_RANGE] muldiv_result,
    output wire [`RESULT_RANGE] out_result,
    output wire                 out_need_to_wb,
    output wire [       `PREG_RANGE] out_prd,
    //output wire [`RESULT_RANGE] ls_address,
    //redirect
    output wire             redirect_valid,
    output wire [`PC_RANGE] redirect_target,
    //bypass exu result to end of dec module
    //output wire [  `LREG_RANGE] ex_byp_rd,
    //output wire                 ex_byp_need_to_wb,
    output wire [`RESULT_RANGE] ex_byp_result,

/* ---------------------- flush signal from wb pipereg ---------------------- */
    input wire                     flush_valid,
    input wire  [`INSTR_ID_WIDTH-1:0]              flush_id,


/* --------------------------- btbbht update port -------------------------- */
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
    wire redirect_valid_internal;

    assign instr_ready = 1'b1;
    //when redirect instr from wb pipereg is older than current instr in exu, flush instr in exu
    wire need_flush;
    assign need_flush = flush_valid && ((flush_id[7]^out_id[7])^(flush_id[6:0] < out_id[6:0]));

    assign out_instr_valid =  need_flush? 0 :  instr_valid;
    assign out_pc          =  pc;    
    assign out_instr       =  instr; //for debug
    assign out_id          =  id;
    assign out_prd         =  prd;
    assign redirect_valid  =  need_flush? 0 :  redirect_valid_internal;

    //exu logic
    wire alu_valid = (|alu_type) & instr_valid;
    wire bju_valid = (|cx_type) & instr_valid;
    wire muldiv_valid = (|muldiv_type) & instr_valid;
    assign out_result = (|alu_type) ? alu_result : (|cx_type) ? bju_result : (|muldiv_type) ? muldiv_result : 64'hDEADBEEF;
    assign out_need_to_wb = need_to_wb;


    alu u_alu (
        .src1       (src1),
        .src2       (src2),
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
        .src1           (src1),
        .src2           (src2),
        .imm            (imm),
        .predict_taken      (predict_taken), 
        .predict_target     (predict_target), 
        .pc             (pc),
        .cx_type        (cx_type),
        .valid          (bju_valid),
        .is_unsigned    (is_unsigned),
        .dest           (bju_result),
        .redirect_valid (redirect_valid_internal),
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
        .src1       (src1),
        .src2       (src2),
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
    //assign src1 = src1_need_forward ? src1_forward_result : src1;
    //assign src2 = src2_need_forward ? src2_forward_result : src2;
//
    //assign final_src1 = src1;
    //assign final_src2 = src2;
endmodule
