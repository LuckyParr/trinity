module ibuffer (
    input wire clk,
    input wire rst_n,
    input wire pc_index_ready,                  // Signal indicating readiness from `pc_index`
    input wire [511:0] arb2ib_read_inst,        // 512-bit input data from arbiter (16 instructions, 32 bits each)
    input wire fifo_read_en,                    // External read enable signal for FIFO
    input wire clear_ibuffer,                   // Clear signal for ibuffer

    output reg fetch_inst,                      // Output pulse when FIFO count decreases from 4 to 3
    output wire [31:0] fifo_data_out,           // 32-bit output data from the FIFO
    output wire fifo_empty                      // Signal indicating if the FIFO is empty
);

    // Internal signals
    reg [31:0] inst_buffer [0:15];              // Buffer to store 16 instructions (32-bit each)
    reg pc_index_ready_prev;                    // To detect rising edge of pc_index_ready
    reg write_enable;                           // Enable writing to FIFO
    wire fifo_full;                             // Full signal from FIFO
    wire [4:0] fifo_count;                      // Count of entries in the FIFO
    reg [4:0] fifo_count_prev;                  // Previous FIFO count to detect transition from 4 to 3

    // Instantiate the 32x24 FIFO with clear functionality
    fifo_32x24 fifo_inst (
        .clk(clk),
        .rst_n(rst_n),
        .data_in(inst_buffer[write_index]),     // 32-bit input to FIFO
        .write_en(write_enable),
        .read_en(fifo_read_en),
        .clear_ibuffer(clear_ibuffer),          // Pass clear signal to FIFO
        .data_out(fifo_data_out),
        .empty(fifo_empty),
        .full(fifo_full),
        .count(fifo_count)
    );

    reg [3:0] write_index;                      // Index for loading instructions into FIFO

    // Detect rising edge of pc_index_ready
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc_index_ready_prev <= 1'b0;
        end else begin
            pc_index_ready_prev <= pc_index_ready;
        end
    end

    // Store 16 instructions into inst_buffer when pc_index_ready rises from 0 to 1
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n || clear_ibuffer) begin
            write_index <= 4'b0;
            write_enable <= 1'b0;
            fetch_inst <= 1'b0;
            fifo_count_prev <= 5'b0;
        end else begin
            // Detect rising edge of pc_index_ready
            if (pc_index_ready && !pc_index_ready_prev) begin
                // Split arb2ib_read_inst into 16 instructions and load them into inst_buffer
                inst_buffer[0] <= arb2ib_read_inst[31:0];
                inst_buffer[1] <= arb2ib_read_inst[63:32];
                inst_buffer[2] <= arb2ib_read_inst[95:64];
                inst_buffer[3] <= arb2ib_read_inst[127:96];
                inst_buffer[4] <= arb2ib_read_inst[159:128];
                inst_buffer[5] <= arb2ib_read_inst[191:160];
                inst_buffer[6] <= arb2ib_read_inst[223:192];
                inst_buffer[7] <= arb2ib_read_inst[255:224];
                inst_buffer[8] <= arb2ib_read_inst[287:256];
                inst_buffer[9] <= arb2ib_read_inst[319:288];
                inst_buffer[10] <= arb2ib_read_inst[351:320];
                inst_buffer[11] <= arb2ib_read_inst[383:352];
                inst_buffer[12] <= arb2ib_read_inst[415:384];
                inst_buffer[13] <= arb2ib_read_inst[447:416];
                inst_buffer[14] <= arb2ib_read_inst[479:448];
                inst_buffer[15] <= arb2ib_read_inst[511:480];

                write_index <= 4'b0;             // Reset write_index
                write_enable <= 1'b1;            // Start writing to FIFO
            end

            // Write instructions from inst_buffer to FIFO
            if (write_enable && !fifo_full) begin
                write_index <= write_index + 1;
                if (write_index == 4'd15) begin
                    write_enable <= 1'b0;        // Stop writing after 16 instructions
                end
            end

            // Update fifo_count_prev to detect transition from 4 to 3
            fifo_count_prev <= fifo_count;

            // Generate fetch_inst pulse when FIFO count decreases from 4 to 3
            fetch_inst <= (fifo_count_prev == 5'd4 && fifo_count == 5'd3) ? 1'b1 : 1'b0;
        end
    end

endmodule
