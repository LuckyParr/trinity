module index_ctrl (
    input wire clk,                          // Clock signal
    input wire rst_n,                        // Active-low reset signal
    input wire [18:0] pc_index,              // 19-bit input for pc_index (Channel 1)
    input wire [18:0] sw_index,              // 19-bit input for sw_index (Channel 2)
    input wire [18:0] lw_index,              // 19-bit input for lw_index (Channel 3)
    input wire pc_index_valid,               // Valid signal for pc_index
    input wire sw_index_valid,               // Valid signal for sw_index
    input wire lw_index_valid,               // Valid signal for lw_index
    input wire ddr_ready,                    // Indicates if DDR is ready for new operation

    output reg [18:0] ddr_index,             // 19-bit selected index to be sent to DDR
    output reg burst_mode,                   // Burst mode signal, 1 when pc_index is selected
    output reg pc_index_done,                // Done signal for pc_index
    output reg sw_index_done,                // Done signal for sw_index
    output reg lw_index_done                 // Done signal for lw_index
);

    // Internal busy signals to track ongoing operations
    reg pc_index_busy;
    reg sw_index_busy;
    reg lw_index_busy;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset all signals on negative edge of rst_n
            pc_index_busy <= 1'b0;
            sw_index_busy <= 1'b0;
            lw_index_busy <= 1'b0;
            pc_index_done <= 1'b0;
            sw_index_done <= 1'b0;
            lw_index_done <= 1'b0;
            ddr_index <= 19'b0;
            burst_mode <= 1'b0;
        end else begin
            // Default done signals to 0, will set them when the operation is completed
            pc_index_done <= 1'b0;
            sw_index_done <= 1'b0;
            lw_index_done <= 1'b0;

            // Check if DDR is ready and an operation is in progress
            if (ddr_ready) begin
                // Finish the current busy operation
                if (pc_index_busy) begin
                    pc_index_busy <= 1'b0;
                    pc_index_done <= 1'b1;
                end else if (sw_index_busy) begin
                    sw_index_busy <= 1'b0;
                    sw_index_done <= 1'b1;
                end else if (lw_index_busy) begin
                    lw_index_busy <= 1'b0;
                    lw_index_done <= 1'b1;
                end
            end

            // Select index to send to DDR based on priority and validity
            if (!sw_index_busy && sw_index_valid) begin
                ddr_index <= sw_index;
                sw_index_busy <= 1'b1;
                burst_mode <= 1'b0;
            end else if (!lw_index_busy && lw_index_valid) begin
                ddr_index <= lw_index;
                lw_index_busy <= 1'b1;
                burst_mode <= 1'b0;
            end else if (!pc_index_busy && pc_index_valid) begin
                ddr_index <= pc_index;
                pc_index_busy <= 1'b1;
                burst_mode <= 1'b1;
            end
        end
    end

endmodule
