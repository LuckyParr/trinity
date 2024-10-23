module tb_top (
    input wire [3:0] a,
    output wire [3:0] b,
    output wire [31:0] opt,

    input wire clk,
    input wire rst_n
);
    assign b[3:0] = a+4'b1;
    initial begin
        $display("heell");
        // $finish;
    end
    
    top u_top(
        .clk   (clk   ),
        .rst_n (rst_n ),
        .opt (opt)
    );
    
    
endmodule
