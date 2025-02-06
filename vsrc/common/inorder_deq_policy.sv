`include "defines.sv"
module inorder_deq_policy #(
    parameter QUEUE_SIZE = 8,
    parameter QUEUE_SIZE_LOG = 3
) (
    input wire clock,
    input wire reset_n,

    input  wire                      deq_fire,
    output reg  [ QUEUE_SIZE -1 : 0] deq_ptr_oh,
    output reg  [QUEUE_SIZE_LOG : 0] deq_ptr
);
    always @(posedge clock or negedge reset_n) begin
        if (~reset_n) begin
            deq_ptr <= 'b0;
        end else if (deq_fire) begin
            deq_ptr <= deq_ptr + 1;
        end
    end

    always @(*) begin
        integer i;
        deq_ptr_oh = 'b0;
        for (i = 0; i < QUEUE_SIZE; i = i + 1) begin
            if (deq_ptr[QUEUE_SIZE_LOG-1:0] == i) begin
                deq_ptr_oh[i] = 'b1;
            end
        end
    end

endmodule
