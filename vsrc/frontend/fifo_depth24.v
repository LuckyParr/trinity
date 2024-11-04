module fifo_depth24 (
    input wire clock,
    input wire reset_n,
    input wire [(32+48-1):0] data_in,      // (32+48-1)-bit data input
    input wire write_en,            // Write enable
    input wire read_en,             // Read enable
    input wire clear_ibuffer,       // Clear signal for ibuffer

    output reg [(32+48-1):0] data_out,     // (32+48-1)-bit data output
    // output reg empty,               // FIFO empty flag
    // output reg full,                // FIFO full flag
    output wire empty,               // FIFO empty flag
    output wire full,                // FIFO full flag
    output reg [4:0] count          // FIFO count
);

    reg [(32+48-1):0] fifo [23:0];         // FIFO storage ((32+48-1)x24)
    reg [4:0] read_ptr;             // Read pointer
    reg [4:0] write_ptr;            // Write pointer

    assign empty = (count == 5'd0);
    assign full = (count == 5'd24);
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n || clear_ibuffer) begin
            // Reset or clear the FIFO
            read_ptr <= 5'b0;
            write_ptr <= 5'b0;
            count <= 5'b0;
            data_out <= 32'b0;
            //empty <= 1'b1;
            //full <= 1'b0;
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
            //empty <= (count == 0);
            //full <= (count == 24);
        end
    end
endmodule
