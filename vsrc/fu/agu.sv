module agu (
    input wire [`SRC_RANGE] src1,
    input wire [`SRC_RANGE] offset,
    output wire [`RESULT_RANGE] ls_address
);
    wire [`RESULT_RANGE] sum = src + offset;
    assign ls_address[`RESULT_RANGE] = {3'b0, sum[`RESULT_WIDTH: 3]};
endmodule