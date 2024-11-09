`include "defines.sv"
module backend (
    input wire               clock,
    input wire               reset_n,
    input wire               instr_valid,
    input wire [`LREG_RANGE] rs1,
    input wire [`LREG_RANGE] rs2,
    input wire [`LREG_RANGE] rd,
    input wire [ `SRC_RANGE] src1,
    input wire [ `SRC_RANGE] src2,
    input wire [ `SRC_RANGE] imm,
    input wire               src1_is_reg,
    input wire               src2_is_reg,
    input wire               need_to_wb,

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

    //write back lreg 
    output wire                 regfile_write_valid,
    output wire [`RESULT_RANGE] regfile_write_data,
    output wire [          4:0] regfile_write_rd,

    //redirect
    output wire             redirect_valid,
    output wire [`PC_RANGE] redirect_target,

    //stall pipeline
    output wire mem_stall,

    /*
        TO L1 D$/MEM
    */

    // LSU store Channel Inputs and Outputs
    output wire        opstore_index_valid,    // Valid signal for opstore_index
    output wire [18:0] opstore_index,          // 19-bit output for opstore_index (Channel 2)
    input  reg         opstore_index_ready,    // Ready signal for opstore channel
    output wire [63:0] opstore_write_mask,     // Write Mask for opstore channel
    output wire [63:0] opstore_write_data,     // 64-bit data output for opstore channel write
    input  wire        opstore_operation_done,

    // LSU load Channel outputs and inputs
    output wire        opload_index_valid,     // Valid signal for opload_index
    output wire [18:0] opload_index,           // 19-bit output for opload_index (Channel 3)
    input  reg         opload_index_ready,     // Ready signal for lw channel
    input  reg  [63:0] opload_read_data,       // input read data for lw channel
    input  wire        opload_operation_done,
    // output instrcnt pulse
    output reg         flop_commit_valid,


    output wire [  `LREG_RANGE] ex_byp_rd,
    output wire                 ex_byp_need_to_wb,
    output wire [`RESULT_RANGE] ex_byp_result,

    output wire [  `LREG_RANGE] mem_byp_rd,
    output wire                 mem_byp_need_to_wb,
    output wire [`RESULT_RANGE] mem_byp_result



);

    wire exu_redirect_valid;
    assign redirect_valid = exu_redirect_valid & instr_valid;

    wire    exu_instr_valid_out;
    wire     [         `PC_RANGE]  exu_pc_out;
    wire     [      `INSTR_RANGE]  exu_instr_out;

    exu u_exu (
        .clock            (clock),
        .reset_n          (reset_n),
        .rs1              (rs1),
        .rs2              (rs2),
        .rd               (rd),
        .src1             (src1),
        .src2             (src2),
        .imm              (imm),
        .src1_is_reg      (src1_is_reg),
        .src2_is_reg      (src2_is_reg),
        .need_to_wb       (need_to_wb),
        .cx_type          (cx_type),
        .is_unsigned      (is_unsigned),
        .alu_type         (alu_type),
        .is_word          (is_word),
        .is_load          (is_load),
        .is_imm           (is_imm),
        .is_store         (is_store),
        .ls_size          (ls_size),
        .muldiv_type      (muldiv_type),
        .instr_valid      (instr_valid),
        .pc               (pc),
        .instr            (instr),
        .instr_valid_out  (exu_instr_valid_out),
        .pc_out           (exu_pc_out),
        .instr_out        (exu_instr_out),
        .redirect_valid   (exu_redirect_valid),
        .redirect_target  (redirect_target),
        .ls_address       (ls_address),
        .alu_result       (alu_result),
        .bju_result       (bju_result),
        .muldiv_result    (muldiv_result),
        .ex_byp_rd        (ex_byp_rd),
        .ex_byp_need_to_wb(ex_byp_need_to_wb),
        .ex_byp_result    (ex_byp_result),
        .mem_byp_rd        (mem_byp_rd),
        .mem_byp_need_to_wb(mem_byp_need_to_wb),
        .mem_byp_result    (mem_byp_result)
    );



    wire [     `RESULT_RANGE] ls_address;
    wire [     `RESULT_RANGE] alu_result;
    wire [     `RESULT_RANGE] bju_result;
    wire [     `RESULT_RANGE] muldiv_result;


    wire                      mem_instr_valid;
    wire [       `LREG_RANGE] mem_rs1;
    wire [       `LREG_RANGE] mem_rs2;
    wire [       `LREG_RANGE] mem_rd;
    wire [        `SRC_RANGE] mem_src1;
    wire [        `SRC_RANGE] mem_src2;
    wire [        `SRC_RANGE] mem_imm;
    wire                      mem_src1_is_reg;
    wire                      mem_src2_is_reg;
    wire                      mem_need_to_wb;
    wire [    `CX_TYPE_RANGE] mem_cx_type;
    wire                      mem_is_unsigned;
    wire [   `ALU_TYPE_RANGE] mem_alu_type;
    wire                      mem_is_word;
    wire                      mem_is_load;
    wire                      mem_is_imm;
    wire                      mem_is_store;
    wire [               3:0] mem_ls_size;
    wire [`MULDIV_TYPE_RANGE] mem_muldiv_type;
    wire [         `PC_RANGE] mem_pc;
    wire [      `INSTR_RANGE] mem_instr;
    wire [     `RESULT_RANGE] mem_ls_address;
    wire [     `RESULT_RANGE] mem_alu_result;
    wire [     `RESULT_RANGE] mem_bju_result;
    wire [     `RESULT_RANGE] mem_muldiv_result;
    wire [     `RESULT_RANGE] mem_opload_read_data_wb;

    pipe_reg u_pipe_reg_exu2mem (
        .clock                  (clock),
        .reset_n                (reset_n),
        .stall                  (mem_stall),
        .rs1                    (rs1),
        .rs2                    (rs2),
        .rd                     (rd),
        .src1                   (src1),
        .src2                   (src2),
        .imm                    (imm),
        .src1_is_reg            (src1_is_reg),
        .src2_is_reg            (src2_is_reg),
        .need_to_wb             (need_to_wb),
        .cx_type                (cx_type),
        .is_unsigned            (is_unsigned),
        .alu_type               (alu_type),
        .is_word                (is_word),
        .is_load                (is_load),
        .is_imm                 (is_imm),
        .is_store               (is_store),
        .ls_size                (ls_size),
        .muldiv_type            (muldiv_type),
        .instr_valid            (exu_instr_valid_out),
        .pc                     (exu_pc_out),
        .instr                  (exu_instr_out),
        .ls_address             (ls_address),
        .alu_result             (alu_result),
        .bju_result             (bju_result),
        .muldiv_result          (muldiv_result),
        //note :sig below dont not to fill until mem stage done
        .opload_read_data_wb    ('b0),
        .out_rs1                (mem_rs1),
        .out_rs2                (mem_rs2),
        .out_rd                 (mem_rd),
        .out_src1               (mem_src1),
        .out_src2               (mem_src2),
        .out_imm                (mem_imm),
        .out_src1_is_reg        (mem_src1_is_reg),
        .out_src2_is_reg        (mem_src2_is_reg),
        .out_need_to_wb         (mem_need_to_wb),
        .out_cx_type            (mem_cx_type),
        .out_is_unsigned        (mem_is_unsigned),
        .out_alu_type           (mem_alu_type),
        .out_is_word            (mem_is_word),
        .out_is_load            (mem_is_load),
        .out_is_imm             (mem_is_imm),
        .out_is_store           (mem_is_store),
        .out_ls_size            (mem_ls_size),
        .out_muldiv_type        (mem_muldiv_type),
        .out_instr_valid        (mem_instr_valid),
        .out_pc                 (mem_pc),
        .out_instr              (mem_instr),
        .out_ls_address         (mem_ls_address),
        .out_alu_result         (mem_alu_result),
        .out_bju_result         (mem_bju_result),
        .out_muldiv_result      (mem_muldiv_result),
        .out_opload_read_data_wb(),
        .redirect_flush         (1'b0)
    );

        wire                      mem_instr_valid_out;
        wire [         `PC_RANGE] mem_pc_out;
        wire [      `INSTR_RANGE] mem_instr_out;


    wire [`RESULT_RANGE] opload_read_data_wb;
    mem u_mem (
        .clock                 (clock),
        .reset_n               (reset_n),
        .is_load               (mem_is_load),
        .is_store              (mem_is_store),
        .is_unsigned           (mem_is_unsigned),
        .src2                  (mem_src2),
        .ls_address            (mem_ls_address),
        .ls_size               (mem_ls_size),
        .opload_index_valid    (opload_index_valid),
        .opload_index_ready    (opload_index_ready),
        .opload_index          (opload_index),
        .opload_operation_done (opload_operation_done),
        .opload_read_data      (opload_read_data),
        .opstore_index_valid   (opstore_index_valid),
        .opstore_index_ready   (opstore_index_ready),
        .opstore_index         (opstore_index),
        .opstore_write_data    (opstore_write_data),
        .opstore_write_mask    (opstore_write_mask),
        .opstore_operation_done(opstore_operation_done),
        .instr_valid      (mem_instr_valid),
        .pc               (mem_pc),
        .instr            (mem_instr),
        .instr_valid_out  (mem_instr_valid_out),
        .pc_out           (mem_pc_out),
        .instr_out        (mem_instr_out),
        .opload_read_data_wb   (opload_read_data_wb),
        .mem_stall             (mem_stall)
    );
    wire                      wb_valid;
    wire [       `LREG_RANGE] wb_rs1;
    wire [       `LREG_RANGE] wb_rs2;
    wire [       `LREG_RANGE] wb_rd;
    wire [        `SRC_RANGE] wb_src1;
    wire [        `SRC_RANGE] wb_src2;
    wire [        `SRC_RANGE] wb_imm;
    wire                      wb_src1_is_reg;
    wire                      wb_src2_is_reg;
    wire                      wb_need_to_wb;
    wire [    `CX_TYPE_RANGE] wb_cx_type;
    wire                      wb_is_unsigned;
    wire [   `ALU_TYPE_RANGE] wb_alu_type;
    wire                      wb_is_word;
    wire                      wb_is_load;
    wire                      wb_is_imm;
    wire                      wb_is_store;
    wire [               3:0] wb_ls_size;
    wire [`MULDIV_TYPE_RANGE] wb_muldiv_type;
    wire [         `PC_RANGE] wb_pc;
    wire [      `INSTR_RANGE] wb_instr;
    wire [     `RESULT_RANGE] wb_ls_address;
    wire [     `RESULT_RANGE] wb_alu_result;
    wire [     `RESULT_RANGE] wb_bju_result;
    wire [     `RESULT_RANGE] wb_muldiv_result;
    wire [     `RESULT_RANGE] wb_opload_read_data_wb;

    pipe_reg u_pipe_reg_mem2wb (
        .clock                  (clock),
        .reset_n                (reset_n),
        .stall                  (1'b0),
        .rs1                    (mem_rs1),
        .rs2                    (mem_rs2),
        .rd                     (mem_rd),
        .src1                   (mem_src1),
        .src2                   (mem_src2),
        .imm                    (mem_imm),
        .src1_is_reg            (mem_src1_is_reg),
        .src2_is_reg            (mem_src2_is_reg),
        .need_to_wb             (mem_need_to_wb),
        .cx_type                (mem_cx_type),
        .is_unsigned            (mem_is_unsigned),
        .alu_type               (mem_alu_type),
        .is_word                (mem_is_word),
        .is_load                (mem_is_load),
        .is_imm                 (mem_is_imm),
        .is_store               (mem_is_store),
        .ls_size                (mem_ls_size),
        .muldiv_type            (mem_muldiv_type),
        .instr_valid            (mem_instr_valid_out & ~mem_stall),
        .pc                     (mem_pc_out),
        .instr                  (mem_instr_out),
        .ls_address             (mem_ls_address),
        .alu_result             (mem_alu_result),
        .bju_result             (mem_bju_result),
        .muldiv_result          (mem_muldiv_result),
        //fill the load wb data
        .opload_read_data_wb    (opload_read_data_wb),
        .out_rs1                (wb_rs1),
        .out_rs2                (wb_rs2),
        .out_rd                 (wb_rd),
        .out_src1               (wb_src1),
        .out_src2               (wb_src2),
        .out_imm                (wb_imm),
        .out_src1_is_reg        (wb_src1_is_reg),
        .out_src2_is_reg        (wb_src2_is_reg),
        .out_need_to_wb         (wb_need_to_wb),
        .out_cx_type            (wb_cx_type),
        .out_is_unsigned        (wb_is_unsigned),
        .out_alu_type           (wb_alu_type),
        .out_is_word            (wb_is_word),
        .out_is_load            (wb_is_load),
        .out_is_imm             (wb_is_imm),
        .out_is_store           (wb_is_store),
        .out_ls_size            (wb_ls_size),
        .out_muldiv_type        (wb_muldiv_type),
        .out_instr_valid        (wb_valid),
        .out_pc                 (wb_pc),
        .out_instr              (wb_instr),
        .out_ls_address         (wb_ls_address),
        .out_alu_result         (wb_alu_result),
        .out_bju_result         (wb_bju_result),
        .out_muldiv_result      (wb_muldiv_result),
        .out_opload_read_data_wb(wb_opload_read_data_wb),
        .redirect_flush         (1'b0)

    );

    assign regfile_write_valid = wb_valid & wb_need_to_wb;
    assign regfile_write_data  = (|wb_alu_type) ? wb_alu_result : (|wb_cx_type) ? wb_bju_result : (|wb_muldiv_type) ? wb_muldiv_result : wb_is_load ? wb_opload_read_data_wb : 64'hDEADBEEF;
    assign regfile_write_rd    = wb_rd;

    wire                commit_valid = ((|wb_alu_type) | (|wb_cx_type) | (|wb_muldiv_type) | wb_is_load | wb_is_store) & wb_valid;

    // reg                 flop_commit_valid;
    reg                 flop_wb_need_to_wb;
    reg  [         4:0] flop_wb_rd;
    reg  [   `PC_RANGE] flop_wb_pc;
    reg  [`INSTR_RANGE] flop_wb_instr;
    always @(posedge clock or negedge reset_n) begin
        if (~reset_n) begin
            flop_commit_valid <= 'b0;
        end else begin
            flop_commit_valid <= commit_valid;
        end
    end
    always @(posedge clock or negedge reset_n) begin
        if (~reset_n) begin
            flop_wb_need_to_wb <= 'b0;
        end else begin
            flop_wb_need_to_wb <= wb_need_to_wb;
        end
    end
    always @(posedge clock or negedge reset_n) begin
        if (~reset_n) begin
            flop_wb_rd <= 'b0;
        end else begin
            flop_wb_rd <= wb_rd;
        end
    end
    always @(posedge clock or negedge reset_n) begin
        if (~reset_n) begin
            flop_wb_pc <= 'b0;
        end else begin
            flop_wb_pc <= wb_pc;
        end
    end
    always @(posedge clock or negedge reset_n) begin
        if (~reset_n) begin
            flop_wb_instr <= 'b0;
        end else begin
            flop_wb_instr <= wb_instr;
        end
    end

    wire mmio_valid = (wb_is_load | wb_is_store) & wb_valid & ('h30000000 <= wb_ls_address) & (wb_ls_address <= 'h40700000);
    reg  flop_mmio_valid;

    always @(posedge clock or negedge reset_n) begin
        if (~reset_n) begin
            flop_mmio_valid <= 'b0;
        end else begin
            flop_mmio_valid <= mmio_valid;
        end
    end

    DifftestInstrCommit u_DifftestInstrCommit (
        .clock     (clock),
        .enable    (flop_commit_valid),
        .io_valid  ('b0),                 //unuse!!!!
        .io_skip   (flop_mmio_valid),
        .io_isRVC  (1'b0),
        .io_rfwen  (flop_wb_need_to_wb),
        .io_fpwen  (1'b0),
        .io_vecwen (1'b0),
        .io_wpdest (flop_wb_rd),
        .io_wdest  (flop_wb_rd),
        .io_pc     (flop_wb_pc),
        .io_instr  (flop_wb_instr),
        .io_robIdx ('b0),
        .io_lqIdx  ('b0),
        .io_sqIdx  ('b0),
        .io_isLoad ('b0),
        .io_isStore('b0),
        .io_nFused ('b0),
        .io_special('b0),
        .io_coreid ('b0),
        .io_index  ('b0)
    );



    assign mem_byp_rd         = mem_rd;
    assign mem_byp_need_to_wb = mem_need_to_wb & mem_instr_valid & ((|mem_alu_type) | (|mem_muldiv_type) | (|mem_cx_type) | mem_is_load);
    assign mem_byp_result     = (|mem_alu_type) ? mem_alu_result : (|mem_muldiv_type) ? mem_muldiv_result : (|mem_cx_type) ? mem_bju_result : mem_is_load ? opload_read_data_wb : 64'hDEADBEEF;
endmodule
