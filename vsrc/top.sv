module top #(
) (
    input wire clk,
    input wire rst_n,
    output wire [31:0] opt
);
  reg [ 3:0] a;
  reg [31:0] b;
  always @(posedge clk) begin
    if (~rst_n) begin
      a <= 'b0;
    end else if (a[3] != 1'b1) begin
      a <= a + 1'b1;
    end else begin
      a <= a;
    end
  end
//   import "DPI-C" function int dpic_test(int b);

  always @(posedge clk) begin
    if (~rst_n) begin
      b <= 'b0;
    end else if (a[3] == 1'b1) begin
    //   b <= dpic_test(int'(a));
      b <= 'b1;
    end
  end
  assign opt = b;

  reg r_enable;
  reg [63:0] r_index;
  reg [63:0] r_data;

  reg w_enable;
  reg [63:0] w_index;
  reg [63:0] w_data;
  reg [63:0] w_mask;
  reg enable;

  wire [63:0] temp = 64'h1;



  always @(posedge clk) begin
    if (~rst_n) begin
      r_enable <= 'b0;
      r_index  <= 'b0;
      w_enable <= 'b0;
      w_index  <= 'b0;
      w_data   <= 'b0;
      w_mask   <= 'b0;
    end
  end

  wire chip_enable = 1'b1;

simddr u_simddr(
    .clk                   (clk                   ),
    .rst_n                 (rst_n                 ),
    .chip_enable           (chip_enable           ),
    .write_enable          (1'b0          ),
    .burst_mode            (1'b1            ),
    .address               (64'b0               ),
    .access_write_mask     (64'b0     ),
    .l2_burst_write_data   (64'b0   ),
    .access_write_data     (64'b0     ),
    .fetch_burst_read_inst ( ),
    .access_read_data      (      ),
    .ready                 (                 )
);

initial begin
  
end
endmodule
