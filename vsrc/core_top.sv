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
    input  wire         ddr_ready                // Indicates if DDR is ready for new operation
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
    wire                      wb_valid;
    wire [     `RESULT_RANGE] wb_data;

    //redirect
    wire                      redirect_valid;
    wire [         `PC_RANGE] redirect_target;
    //mem stall
    wire                      mem_stall;



    // PC Channel Inputs and Outputs
    wire                      pc_index_valid;  // Valid signal for pc_index
    wire [              18:0] pc_index;  // 19-bit input for pc_index (Channel 1)
    reg                       pc_index_ready;  // Ready signal for pc channel
    reg  [             511:0] pc_read_inst;  // Output burst read data for pc channel
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

    backend u_backend (
        .clock                 (clock),
        .reset_n               (reset_n),
        .rs1                   (rs1),
        .rs2                   (rs2),
        .rd                    (rd),
        .src1                  (src1),
        .src2                  (src2),
        .imm                   (imm),
        .src1_is_reg           (src1_is_reg),
        .src2_is_reg           (src2_is_reg),
        .need_to_wb            (need_to_wb),
        .cx_type               (cx_type),
        .is_unsigned           (is_unsigned),
        .alu_type              (alu_type),
        .is_word               (is_word),
        .is_load               (is_load),
        .is_imm                (is_imm),
        .is_store              (is_store),
        .ls_size               (ls_size),
        .muldiv_type           (muldiv_type),
        .pc                    (pc),
        .instr                 (instr),
        .wb_valid              (wb_valid),
        .wb_data               (wb_data),
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
        .opload_operation_done (opload_operation_done)
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
