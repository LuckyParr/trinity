module fifo_32x24 (
    input wire clk,
    input wire rst_n,
    input wire [31:0] data_in,
    input wire write_en,
    input wire read_en,
    output reg [31:0] data_out,
    output reg empty,
    output reg full
);

    parameter DEPTH = 24;
    reg [31:0] fifo_mem [0:DEPTH-1];
    reg [4:0] write_ptr, read_ptr, count;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            write_ptr <= 0;
            read_ptr <= 0;
            count <= 0;
            empty <= 1;
            full <= 0;
        end else begin
            // Write Operation
            if (write_en && !full) begin
                fifo_mem[write_ptr] <= data_in;
                write_ptr <= (write_ptr + 1) % DEPTH;
                count <= count + 1;
            end

            // Read Operation
            if (read_en && !empty) begin
                data_out <= fifo_mem[read_ptr];
                read_ptr <= (read_ptr + 1) % DEPTH;
                count <= count - 1;
            end

            // Update empty and full flags
            empty <= (count == 0);
            full <= (count == DEPTH);
        end
    end
endmodule
