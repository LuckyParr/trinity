module SimTop (
    input  wire       reset,
    input  wire       clock,
    input  wire       difftest_logCtrl_begin,
    input  wire       difftest_logCtrl_end,
    output wire       difftest_uart_out_valid,
    output wire [7:0] difftest_uart_out_ch,
    input  wire       difftest_uart_in_valid,
    input  wire [7:0] difftest_uart_in_ch,

    input wire difftest_perfCtrl_clean,
    input wire difftest_perfCtrl_dump,

    output wire difftest_exit,
    output wire difftest_step

);
    assign difftest_step           = 1'b1;
    assign difftest_exit           = 1'b0;
    assign difftest_uart_out_ch    = 8'b0;
    assign difftest_uart_out_valid = 1'b0;



    // DDR Control Inputs and Outputs
    wire         ddr_chip_enable;  // Enables chip for one cycle when a channel is selected
    wire [ 63:0] ddr_index;  // 19-bit selected index to be sent to DDR
    wire         ddr_write_enable;  // Write enable signal (1 for write; 0 for read)
    wire         ddr_burst_mode;  // Burst mode signal; 1 when pc_index is selected
    wire [ 511:0] ddr_write_data;  // Output write data for opstore channel
    wire [ 511:0] ddr_read_data;  // 64-bit data output for lw channel read
    wire         ddr_operation_done;
    wire         ddr_ready;  // Indicates if DDR is ready for new operation

    core_top u_core_top (
        .clock                 (clock),
        .reset_n               (~reset),
        .ddr_chip_enable       (ddr_chip_enable),
        .ddr_index             (ddr_index),
        .ddr_write_enable      (ddr_write_enable),
        .ddr_burst_mode        (ddr_burst_mode),
        .ddr_write_data(ddr_write_data),
        .ddr_read_data  (ddr_read_data),
        .ddr_operation_done    (ddr_operation_done),
        .ddr_ready             (ddr_ready)
    );




    simddr u_simddr (
        .clock             (clock),
        .reset_n           (~reset),
        .ddr_chip_enable   (ddr_chip_enable),
        .ddr_index         (ddr_index),
        .ddr_write_enable  (ddr_write_enable),
        .ddr_burst_mode    (ddr_burst_mode),
        .ddr_write_data    (ddr_write_data),
        .ddr_read_data     (ddr_read_data),
        .ddr_operation_done(ddr_operation_done),
        .ddr_ready         (ddr_ready)
    );


 


endmodule
