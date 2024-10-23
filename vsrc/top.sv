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

  MemRWHelper mem (
      .r_enable(r_enable),  //input 1
      .r_index (r_index),   //input 64
      .r_data  (r_data),    //output 64

      .w_enable(w_enable),  //input 1
      .w_index(w_index),  //input 64
      .w_data(w_data),  //input 64
      .w_mask(w_mask),  //input 64
      .enable(1'b1),  //input 1
      .clock(clk)  //input 1
  );


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
endmodule
