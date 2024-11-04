`include "defines.sv"
module core_top #(
) (
    input wire clock,
    input wire reset_n,

    // DDR Control Inputs and Outputs
    output wire         ddr_chip_enable,         // Enables chip for one cycle when a channel is selected
    output wire [ 18:0] ddr_index,               // 19-bit selected index to be sent to DDR
    output wire         ddr_write_enable,        // Write enable signal (1 for write, 0 for read)
    output wire         ddr_burst_mode,          // Burst mode signal, 1 when pc_index is selected
    output wire [ 63:0] ddr_opstore_write_mask,  // Output write mask for opstore channel
    output wire [ 63:0] ddr_opstore_write_data,  // Output write data for opstore channel
    input  wire [ 63:0] ddr_opload_read_data,    // 64-bit data output for lw channel read
    input  wire [511:0] ddr_pc_read_inst,        // 512-bit data output for pc channel burst read
    input  wire         ddr_operation_done,
    input  wire         ddr_ready  ,              // Indicates if DDR is ready for new operation
    output reg          flop_commit_valid
);


    wire                      chip_enable = 1'b1;



    wire [       `LREG_RANGE] rs1;
    wire [       `LREG_RANGE] rs2;
    wire [       `LREG_RANGE] rd;
    wire [        `SRC_RANGE] src1;
    wire [        `SRC_RANGE] src2;
    wire [        `SRC_RANGE] imm;
    wire                      src1_is_reg;
    wire                      src2_is_reg;
    wire                      need_to_wb;
    wire [    `CX_TYPE_RANGE] cx_type;
    wire                      is_unsigned;
    wire [   `ALU_TYPE_RANGE] alu_type;
    wire                      is_word;
    wire                      is_load;
    wire                      is_imm;
    wire                      is_store;
    wire [               3:0] ls_size;
    wire [`MULDIV_TYPE_RANGE] muldiv_type;
    wire [         `PC_RANGE] pc;
    wire [      `INSTR_RANGE] instr;

    wire                      regfile_write_valid;
    wire [     `RESULT_RANGE] regfile_write_data;
    wire [               4:0] regfile_write_rd;
    wire                      decoder_inst_valid;
    wire [              47:0] decoder_pc_out;
    wire [              47:0] decoder_inst_out;

    //redirect
    wire                      redirect_valid;
    wire [         `PC_RANGE] redirect_target;
    //mem stall
    wire                      mem_stall;



    // PC Channel Inputs and Outputs
    wire                      pc_index_valid;  // Valid signal for pc_index
    wire [              18:0] pc_index;  // 19-bit input for pc_index (Channel 1)
    wire                      pc_index_ready;  // Ready signal for pc channel
    wire [             511:0] pc_read_inst;  // Output burst read data for pc channel
    wire                      pc_operation_done;

    // LSU store Channel Inputs and Outputs
    wire                      opstore_index_valid;  // Valid signal for opstore_index
    wire [              18:0] opstore_index;  // 19-bit input for opstore_index (Channel 2)
    wire                      opstore_index_ready;  // Ready signal for opstore channel
    wire [              63:0] opstore_write_mask;  // Write Mask for opstore channel
    wire [              63:0] opstore_write_data;  // 64-bit data input for opstore channel write
    wire                      opstore_operation_done;

    // LSU load Channel Inputs and Outputs
    wire                      opload_index_valid;  // Valid signal for opload_index
    wire [              18:0] opload_index;  // 19-bit input for opload_index (Channel 3)
    wire                      opload_index_ready;  // Ready signal for lw channel
    wire [              63:0] opload_read_data;  // Output read data for lw channel
    wire                      opload_operation_done;



    frontend u_frontend (
        .clock             (clock),
        .reset_n           (reset_n),
        .redirect_valid    (redirect_valid),
        .redirect_target   (redirect_target),
        .pc_index_valid    (pc_index_valid),
        .pc_index_ready    (pc_index_ready),
        .pc_operation_done (pc_operation_done),
        .pc_read_inst      (pc_read_inst),
        .pc_index          (pc_index),
        .fifo_read_en      (1'b1),
        .clear_ibuffer_ext (redirect_valid),
        .rs1               (rs1),
        .rs2               (rs2),
        .rd                (rd),
        .src1              (src1),
        .src2              (src2),
        .imm               (imm),
        .src1_is_reg       (src1_is_reg),
        .src2_is_reg       (src2_is_reg),
        .need_to_wb        (need_to_wb),
        .cx_type           (cx_type),
        .is_unsigned       (is_unsigned),
        .alu_type          (alu_type),
        .is_word           (is_word),
        .is_imm            (is_imm),
        .is_load           (is_load),
        .is_store          (is_store),
        .ls_size           (ls_size),
        .muldiv_type       (muldiv_type),
        .decoder_inst_valid(decoder_inst_valid),
        .decoder_pc_out    (decoder_pc_out),
        .decoder_inst_out  (decoder_inst_out),
        //write back enable
        .writeback_valid   (regfile_write_valid),
        .writeback_rd      (regfile_write_rd),
        .writeback_data    (regfile_write_data)

    );
    wire                      out_valid;
    wire [       `LREG_RANGE] out_rs1;
    wire [       `LREG_RANGE] out_rs2;
    wire [       `LREG_RANGE] out_rd;
    wire [        `SRC_RANGE] out_src1;
    wire [        `SRC_RANGE] out_src2;
    wire [        `SRC_RANGE] out_imm;
    wire                      out_src1_is_reg;
    wire                      out_src2_is_reg;
    wire                      out_need_to_wb;
    wire [    `CX_TYPE_RANGE] out_cx_type;
    wire                      out_is_unsigned;
    wire [   `ALU_TYPE_RANGE] out_alu_type;
    wire                      out_is_word;
    wire                      out_is_load;
    wire                      out_is_imm;
    wire                      out_is_store;
    wire [               3:0] out_ls_size;
    wire [`MULDIV_TYPE_RANGE] out_muldiv_type;
    wire [         `PC_RANGE] out_pc;
    wire [      `INSTR_RANGE] out_instr;
    pipe_reg u_pipe_reg_dec2exu (
        .clock                  (clock),
        .reset_n                (reset_n),
        .stall                  ('b0),
        .valid                  (decoder_inst_valid),
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
        .pc                     (decoder_pc_out),
        .instr                  (decoder_inst_out),
        .ls_address             ('b0),
        .alu_result             ('b0),
        .bju_result             ('b0),
        .muldiv_result          ('b0),
        .opload_read_data_wb    ('b0),
        .out_valid              (out_valid),
        .out_rs1                (out_rs1),
        .out_rs2                (out_rs2),
        .out_rd                 (out_rd),
        .out_src1               (out_src1),
        .out_src2               (out_src2),
        .out_imm                (out_imm),
        .out_src1_is_reg        (out_src1_is_reg),
        .out_src2_is_reg        (out_src2_is_reg),
        .out_need_to_wb         (out_need_to_wb),
        .out_cx_type            (out_cx_type),
        .out_is_unsigned        (out_is_unsigned),
        .out_alu_type           (out_alu_type),
        .out_is_word            (out_is_word),
        .out_is_load            (out_is_load),
        .out_is_imm             (out_is_imm),
        .out_is_store           (out_is_store),
        .out_ls_size            (out_ls_size),
        .out_muldiv_type        (out_muldiv_type),
        .out_pc                 (out_pc),
        .out_instr              (out_instr),
        .out_ls_address         (),
        .out_alu_result         (),
        .out_bju_result         (),
        .out_muldiv_result      (),
        .out_opload_read_data_wb()
    );


    backend u_backend (
        .clock                 (clock),
        .reset_n               (reset_n),
        .pipeval                 (out_valid),
        .rs1                   (out_rs1),
        .rs2                   (out_rs2),
        .rd                    (out_rd),
        .src1                  (out_src1),
        .src2                  (out_src2),
        .imm                   (out_imm),
        .src1_is_reg           (out_src1_is_reg),
        .src2_is_reg           (out_src2_is_reg),
        .need_to_wb            (out_need_to_wb),
        .cx_type               (out_cx_type),
        .is_unsigned           (out_is_unsigned),
        .alu_type              (out_alu_type),
        .is_word               (out_is_word),
        .is_load               (out_is_load),
        .is_imm                (out_is_imm),
        .is_store              (out_is_store),
        .ls_size               (out_ls_size),
        .muldiv_type           (out_muldiv_type),
        .pc                    (out_pc),
        .instr                 (out_instr),
        .regfile_write_valid   (regfile_write_valid),
        .regfile_write_rd      (regfile_write_rd),
        .regfile_write_data    (regfile_write_data),
        .redirect_valid        (redirect_valid),
        .redirect_target       (redirect_target),
        .mem_stall             (mem_stall),
        .opstore_index_valid   (opstore_index_valid),
        .opstore_index         (opstore_index),
        .opstore_index_ready   (opstore_index_ready),
        .opstore_write_mask    (opstore_write_mask),
        .opstore_write_data    (opstore_write_data),
        .opstore_operation_done(opstore_operation_done),
        .opload_index_valid    (opload_index_valid),
        .opload_index          (opload_index),
        .opload_index_ready    (opload_index_ready),
        .opload_read_data      (opload_read_data),
        .opload_operation_done (opload_operation_done),
        .flop_commit_valid     (flop_commit_valid)
    );


    channel_arb u_channel_arb (
        .pc_index_valid        (pc_index_valid),
        .pc_index              (pc_index),
        .pc_index_ready        (pc_index_ready),
        .pc_read_inst          (pc_read_inst),
        .pc_operation_done     (pc_operation_done),
        .opstore_index_valid   (opstore_index_valid),
        .opstore_index         (opstore_index),
        .opstore_index_ready   (opstore_index_ready),
        .opstore_write_mask    (opstore_write_mask),
        .opstore_write_data    (opstore_write_data),
        .opstore_operation_done(opstore_operation_done),
        .opload_index_valid    (opload_index_valid),
        .opload_index          (opload_index),
        .opload_index_ready    (opload_index_ready),
        .opload_read_data      (opload_read_data),
        .opload_operation_done (opload_operation_done),
        .ddr_chip_enable       (ddr_chip_enable),
        .ddr_index             (ddr_index),
        .ddr_write_enable      (ddr_write_enable),
        .ddr_burst_mode        (ddr_burst_mode),
        .ddr_opstore_write_mask(ddr_opstore_write_mask),
        .ddr_opstore_write_data(ddr_opstore_write_data),
        .ddr_opload_read_data  (ddr_opload_read_data),
        .ddr_pc_read_inst      (ddr_pc_read_inst),
        .ddr_operation_done    (ddr_operation_done),
        .ddr_ready             (ddr_ready)
    );

endmodule
