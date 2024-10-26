module channel_arb (
    input wire ddr_operation_done,
    output wire arb_operation_done,
    // PC Channel Inputs and Outputs
    input wire [18:0] pc_index,                // 19-bit input for pc_index (Channel 1)
    input wire pc_index_valid,                 // Valid signal for pc_index
    input wire [511:0] fetch_burst_read_inst,  // 512-bit data output for pc channel burst read
    output reg [511:0] arb2ib_read_inst, // Output burst read data for pc channel
    output reg pc_index_ready,                       // Ready signal for pc channel

    // SW Channel Inputs and Outputs
    input wire [18:0] sw_index,                // 19-bit input for sw_index (Channel 2)
    input wire sw_index_valid,                 // Valid signal for sw_index
    input wire [63:0] sw2arb_write_mask,       // Write Mask for sw channel
    input wire [63:0] sw2ddr_write_data,       // 64-bit data input for sw channel write
    output reg [63:0] sw_write_mask,           // Output write mask for sw channel
    output reg [63:0] sw_write_data,           // Output write data for sw channel
    output reg sw_index_ready,                       // Ready signal for sw channel

    // LW Channel Inputs and Outputs
    input wire [18:0] lw_index,                // 19-bit input for lw_index (Channel 3)
    input wire lw_index_valid,                 // Valid signal for lw_index
    input wire [63:0] lw_read_data,            // 64-bit data output for lw channel read
    output reg [63:0] arb2lw_read_data,        // Output read data for lw channel
    output reg lw_index_ready,                       // Ready signal for lw channel

    // DDR Control Inputs and Outputs
    input wire ddr_ready,                      // Indicates if DDR is ready for new operation
    output reg [18:0] ddr_index,               // 19-bit selected index to be sent to DDR
    output reg burst_mode,                     // Burst mode signal, 1 when pc_index is selected
    output reg chip_enable,                    // Enables chip for one cycle when a channel is selected
    output reg write_enable                    // Write enable signal (1 for write, 0 for read)
);
    assign arb_operation_done = ddr_operation_done;

    always @(*) begin
        // Default output values
        chip_enable = 1'b0;
        burst_mode = 1'b0;
        write_enable = 1'b0;
        ddr_index = 19'b0;

        sw_write_mask = 64'b0;
        sw_write_data = 64'b0;
        arb2lw_read_data = 64'b0;
        arb2ib_read_inst = 512'b0;

        // Default ready signals
        pc_index_ready = 1'b0;
        sw_index_ready = 1'b0;
        lw_index_ready = 1'b0;

        if (ddr_ready) begin
            // Priority selection logic
            if (sw_index_valid) begin
                // SW channel selected for write
                ddr_index = sw_index;
                chip_enable = 1'b1;
                write_enable = 1'b1;             // Write operation
                sw_write_mask = sw2arb_write_mask;
                sw_write_data = sw2ddr_write_data;
                burst_mode = 1'b0;
                sw_index_ready = 1'b1;                 // Indicate SW channel is ready
            end else if (lw_index_valid) begin
                // LW channel selected for read
                ddr_index = lw_index;
                chip_enable = 1'b1;
                write_enable = 1'b0;             // Read operation
                //arb2lw_read_data = lw_read_data;
                burst_mode = 1'b0;
                lw_index_ready = 1'b1;                 // Indicate LW channel is ready
            end else if (pc_index_valid) begin
                // PC channel selected for burst read
                ddr_index = pc_index;
                chip_enable = 1'b1;
                write_enable = 1'b0;             // Read operation for burst mode
                //arb2ib_read_inst = fetch_burst_read_inst;
                burst_mode = 1'b1;
                pc_index_ready = 1'b1;                 // Indicate PC channel is ready
            end
        end
    end
endmodule
