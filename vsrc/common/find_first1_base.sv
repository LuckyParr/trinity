module find_first1_base #(
    parameter WIDTH = 8
)(
    input  [WIDTH-1:0] data_in,
    input  [WIDTH-1:0] base,
    output reg [WIDTH-1:0] data_out
);

    integer i;
    always @(*) begin
        data_out = 0; // 默认值，表示未找到
        for (i = base; i < WIDTH; i = i + 1) begin
            if (data_in[i]) begin
                data_out = i;
                break;
            end
        end
    end

endmodule