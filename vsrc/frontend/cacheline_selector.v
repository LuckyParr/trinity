module cacheline_selector (
    input [511:0] cache_line,       // 512-bit cache line input (16 instructions)
    input pc_bit_2,                 // PC[2] bit
    output reg cut_first_32_bit,
    output reg [511:0] selected_data // Output cache line after processing
);
    always @* begin
        if (pc_bit_2 == 1'b1) begin
            // Shift cache line to discard the lowest 32 bits (shift by 32 bits)
            selected_data = {32'b0,cache_line[511:32] };
            cut_first_32_bit = 1'b1;
        end else begin
            // No shift, keep the cache line as is
            selected_data = cache_line;
            cut_first_32_bit = 1'b0;
        end
    end
endmodule
