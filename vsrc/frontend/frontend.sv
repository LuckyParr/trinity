`include "defines.sv"
module frontend (
    input wire clock,
    input wire reset_n,

    //redirect
    input wire             redirect_valid,
    input wire [`PC_RANGE] redirect_target,

    input wire pc_index_ready,    // Signal indicating DDR operation is complete
    input wire pc_operation_done, // Signal indicating PC operation is done

    // Inputs for instruction buffer
    input wire [511:0] pc_read_inst,      // 512-bit input data for instructions
    input wire         fifo_read_en,      // External read enable signal for FIFO
    input wire         clear_ibuffer_ext, // External clear signal for ibuffer

    // Outputs from ibuffer
    output wire [31:0] fifo_data_out,  // 32-bit output data from the FIFO
    output wire        fifo_empty,     // Signal indicating if the FIFO is empty

    // Outputs from pc_ctrl
    output wire [18:0] pc_index  // Selected bits [21:3] of the PC for DDR index

);

    ifu_top u_ifu_top (
        .clock            (clock),
        .reset_n          (reset_n),
        .boot_addr        (48'h80000000),
        .interrupt_valid  ('b0),
        .interrupt_addr   ('b0),
        .redirect_valid   (redirect_valid),
        .redirect_target  (redirect_target),
        .pc_index_ready   (pc_index_ready),
        .pc_operation_done(pc_operation_done),
        .pc_read_inst     (pc_read_inst),
        .fifo_read_en     (fifo_read_en),
        .clear_ibuffer_ext(clear_ibuffer_ext),
        .fifo_data_out    (fifo_data_out),
        .fifo_empty       (fifo_empty),
        .pc_index         (pc_index)
    );

endmodule
