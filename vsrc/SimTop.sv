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
    top u_top (
        .clk  (clock),
        .rst_n(~reset),
        .opt  ()
    );
    reg [63:0] cnt;
    always @(posedge clock) begin
        if (reset) begin
            cnt <= 'b0;
        end else begin
            cnt <= cnt + 1'b1;
        end
    end
    DifftestTrapEvent u_DifftestTrapEvent (
        .clock      (clock),
        .enable     (1'b1),
        .io_hasTrap (1'b0),
        .io_cycleCnt(cnt),
        .io_instrCnt('b0),
        .io_hasWFI  ('b0),
        .io_code    ('b0),
        .io_pc      ('b0),
        .io_coreid  ('b0)
    );

endmodule
