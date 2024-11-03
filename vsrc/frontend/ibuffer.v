module ibuffer (
    input wire clock,
    input wire reset_n,
    input wire pc_index_ready,                  // Signal indicating readiness from `pc_index`
    input wire [511:0] pc_read_inst,        // 512-bit input data from arbiter (16 instructions, 32 bits each)
    input wire fifo_read_en,                    // External read enable signal for FIFO
    input wire clear_ibuffer,                   // Clear signal for ibuffer
    input wire can_fetch_inst,
    input wire [47:0] pc,

    output wire [31:0]  ibuffer_inst_out,
    output wire [47:0]  ibuffer_pc_out,
    output reg fetch_inst,                      // Output pulse when FIFO count decreases from 4 to 3
    output wire fifo_empty                      // Signal indicating if the FIFO is empty
);
    wire [(32+48-1):0] fifo_inst_addr_out;           // 32-bit output data from the FIFO
    assign ibuffer_inst_out = fifo_inst_addr_out[(32+48-1):48];
    assign ibuffer_pc_out = fifo_inst_addr_out[47:0];

    // Internal signals
    reg [(32+48-1):0] inst_buffer [0:15];              // Buffer to store 16 instructions (32-bit each)
    reg pc_index_ready_prev;                    // To detect rising edge of pc_index_ready
    reg write_enable;                           // Enable writing to FIFO
    wire fifo_full;                             // Full signal from FIFO
    wire [4:0] fifo_count;                      // Count of entries in the FIFO
    reg [4:0] fifo_count_prev;                  // Previous FIFO count to detect transition from 4 to 3

    // Instantiate the 32x24 FIFO with clear functionality
    fifo_depth24 fifo_inst (
        .clock(clock),
        .reset_n(reset_n),
        .data_in(inst_buffer[write_index]),     // 32-bit input to FIFO
        .write_en(write_enable),
        .read_en(fifo_read_en),
        .clear_ibuffer(clear_ibuffer),          // Pass clear signal to FIFO
        .data_out(fifo_inst_addr_out),
        .empty(fifo_empty),
        .full(fifo_full),
        .count(fifo_count)
    );

    reg [3:0] write_index;                      // Index for loading instructions into FIFO

    // Detect rising edge of pc_index_ready
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            pc_index_ready_prev <= 1'b0;
        end else begin
            pc_index_ready_prev <= pc_index_ready;
        end
    end

    // Store 16 instructions into inst_buffer when pc_index_ready rises from 0 to 1
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n || clear_ibuffer) begin
            write_index <= 4'b0;
            write_enable <= 1'b0;
            fetch_inst <= 1'b0;
            fifo_count_prev <= 5'b0;
        end else begin
            // Detect rising edge of pc_index_ready
            if (pc_index_ready && !pc_index_ready_prev) begin
                // Split pc_read_inst into 16 instructions and load them into inst_buffer
                inst_buffer[0]  <= {pc_read_inst[31:0]    , (pc+48'd0)};
                inst_buffer[1]  <= {pc_read_inst[63:32]   , (pc+48'd4)};
                inst_buffer[2]  <= {pc_read_inst[95:64]   , (pc+48'd8)};
                inst_buffer[3]  <= {pc_read_inst[127:96]  , (pc+48'd12)};
                inst_buffer[4]  <= {pc_read_inst[159:128] , (pc+48'd16)};
                inst_buffer[5]  <= {pc_read_inst[191:160] , (pc+48'd20)};
                inst_buffer[6]  <= {pc_read_inst[223:192] , (pc+48'd24)};
                inst_buffer[7]  <= {pc_read_inst[255:224] , (pc+48'd28)};
                inst_buffer[8]  <= {pc_read_inst[287:256] , (pc+48'd32)};
                inst_buffer[9]  <= {pc_read_inst[319:288] , (pc+48'd36)};
                inst_buffer[10] <= {pc_read_inst[351:320] , (pc+48'd40)};
                inst_buffer[11] <= {pc_read_inst[383:352] , (pc+48'd44)};
                inst_buffer[12] <= {pc_read_inst[415:384] , (pc+48'd48)};
                inst_buffer[13] <= {pc_read_inst[447:416] , (pc+48'd52)};
                inst_buffer[14] <= {pc_read_inst[479:448] , (pc+48'd56)};
                inst_buffer[15] <= {pc_read_inst[511:480] , (pc+48'd60)};

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
            if(can_fetch_inst)begin
                fetch_inst <= ((fifo_count_prev == 5'd4 && fifo_count == 5'd3)||fifo_empty) ? 1'b1 : 1'b0;
            end
        end
    end

endmodule
