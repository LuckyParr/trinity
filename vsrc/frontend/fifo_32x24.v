module fifo_32x24 (
    input wire clk,
    input wire rst_n,
    input wire [31:0] data_in,      // 32-bit data input
    input wire write_en,            // Write enable
    input wire read_en,             // Read enable
    input wire clear_ibuffer,       // Clear signal for ibuffer

    output reg [31:0] data_out,     // 32-bit data output
    output reg empty,               // FIFO empty flag
    output reg full,                // FIFO full flag
    output reg [4:0] count          // FIFO count
);

    reg [31:0] fifo [23:0];         // FIFO storage (32x24)
    reg [4:0] read_ptr;             // Read pointer
    reg [4:0] write_ptr;            // Write pointer

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n || clear_ibuffer) begin
            // Reset or clear the FIFO
            read_ptr <= 5'b0;
            write_ptr <= 5'b0;
            count <= 5'b0;
            data_out <= 32'b0;
            empty <= 1'b1;
            full <= 1'b0;
        end else begin
            // Write operation
            if (write_en && !full) begin
                fifo[write_ptr] <= data_in;
                write_ptr <= (write_ptr + 1) % 24;
                count <= count + 1;
            end

            // Read operation
            if (read_en && !empty) begin
                data_out <= fifo[read_ptr];
                read_ptr <= (read_ptr + 1) % 24;
                count <= count - 1;
            end

            // Update empty and full flags based on count
            empty <= (count == 0);
            full <= (count == 24);
        end
    end
endmodule
