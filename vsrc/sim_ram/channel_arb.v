module channel_arb (
    input wire clock,   // Clock signal
    input wire reset_n, // Active-low reset signal

    // PC Channel Inputs and Outputs : from icache
    input  wire         pc_index_valid,    // Valid signal for pc_index
    input  wire [ 63:0] pc_index,          // 64-bit input for pc_index (Channel 1)
    output reg          pc_index_ready,    // Ready signal for pc channel
    output reg  [511:0] pc_read_inst,      // Output burst read data for pc channel
    output wire         pc_operation_done,

    //ddr bus channel : from dcache
    input  reg                  dbus_index_valid,
    output wire                 dbus_index_ready,
    input  reg  [`RESULT_RANGE] dbus_index,
    input  reg  [   511:0] dbus_write_data,
    input  reg  [   511:0] dbus_write_mask,
    output wire [511:0] dbus_read_data,
    output wire                 dbus_operation_done,
    input  wire [  `DBUS_RANGE] dbus_operation_type,


    // DDR Control Inputs and Outputs
    output reg          ddr_chip_enable,     // Enables chip for one cycle when a channel is selected
    output reg  [ 63:0] ddr_index,           // 64-bit selected index to be sent to DDR
    output reg          ddr_write_enable,    // Write enable signal (1 for write, 0 for read)
    output reg          ddr_burst_mode,      // Burst mode signal, 1 when pc_index is selected
    output reg  [511:0] ddr_write_mask,      // Output write mask for opstore channel
    output reg  [511:0] ddr_write_data,      // Output write data for opstore channel
    input  wire [511:0] ddr_read_data,       // 512-bit data output for lw channel read
    input  wire         ddr_operation_done,
    input  wire         ddr_ready,           // Indicates if DDR is ready for new operation

    //add redirect wire
    input wire redirect_valid

);
    reg redirect_valid_dly;
    reg redirect_valid_dly_2;

    reg pc_latch, dbus_write_latch, dbus_read_latch;
    always @(posedge clock or negedge reset_n) begin
        if (~reset_n) begin
            dbus_write_latch <= 1'b0;
            dbus_read_latch  <= 1'b0;
            pc_latch      <= 1'b0;
        end else if (pc_index_valid && pc_index_ready) begin
            dbus_write_latch <= 1'b0;
            dbus_read_latch  <= 1'b0;
            pc_latch      <= 1'b1;
        end else if (dbus_index_valid & (dbus_operation_type == `DBUS_READ) && dbus_index_ready) begin
            dbus_write_latch <= 1'b0;
            dbus_read_latch  <= 1'b1;
            pc_latch      <= 1'b0;
        end else if (dbus_index_valid & (dbus_operation_type == `DBUS_WRITE) && dbus_index_ready) begin
            dbus_write_latch <= 1'b1;
            dbus_read_latch  <= 1'b0;
            pc_latch      <= 1'b0;
        end
    end

    wire dbus_write_operation_done = dbus_write_latch ? ddr_operation_done : 1'b0;
    wire dbus_read_operation_done = dbus_read_latch ? ddr_operation_done : 1'b0;

    assign dbus_operation_done = dbus_write_operation_done | dbus_read_operation_done;
    assign pc_operation_done   = pc_latch ? ddr_operation_done : 1'b0;

    wire anyop_fire;
    assign anyop_fire = (dbus_index_valid & (dbus_operation_type == `DBUS_READ) & dbus_index_ready | dbus_index_valid & (dbus_operation_type == `DBUS_WRITE) & dbus_index_ready | pc_index_valid & pc_index_ready);

    always @(posedge clock or negedge reset_n) begin
        if (~reset_n) begin
            // default output values to simddr.v
            ddr_chip_enable  <= 1'b0;
            ddr_burst_mode   <= 1'b0;
            ddr_write_enable <= 1'b0;
            ddr_index        <= 'b0;
            ddr_write_mask   <= 'b0;
            ddr_write_data   <= 'b0;
            // default output ready signals to pc_ctrl.v and mem.v
            pc_index_ready   <= 1'b0;
            dbus_index_ready <= 1'b0;
        end else begin
            //when ddr is idle , process req by priority
            // if (ddr_ready) begin
            if (anyop_fire) begin
                ddr_chip_enable  <= 1'b0;
                pc_index_ready   <= 1'b0;
                dbus_index_ready <= 1'b0;
            end else if (ddr_ready) begin
                if (dbus_index_valid & (dbus_operation_type == `DBUS_WRITE)) begin
                    // opstore channel selected for write
                    ddr_index        <= dbus_index;
                    ddr_chip_enable  <= 1'b1;
                    ddr_write_enable <= 1'b1;  // Write operation
                    ddr_write_mask   <= dbus_write_mask;
                    ddr_write_data   <= dbus_write_data;
                    ddr_burst_mode   <= 1'b1;
                    dbus_index_ready <= 1'b1;  // Indicate SW channel is ready
                end else if (dbus_index_valid & (dbus_operation_type == `DBUS_READ)) begin
                    // opload channel selected for read
                    ddr_index        <= dbus_index;
                    ddr_chip_enable  <= 1'b1;
                    ddr_write_enable <= 1'b0;  // Read operation
                    ddr_burst_mode   <= 1'b1;
                    dbus_index_ready <= 1'b1;  // Indicate LW channel is ready
                end else if (pc_index_valid) begin
                    // PC channel selected for burst read
                    ddr_index        <= pc_index;
                    ddr_chip_enable  <= 1'b1;
                    ddr_write_enable <= 1'b0;  // Read operation for burst mode
                    ddr_burst_mode   <= 1'b1;
                    pc_index_ready   <= 1'b1;  // Indicate PC channel is ready
                end
            end
        end



    end

    always @(posedge clock or negedge reset_n) begin
        if (~reset_n) begin
            redirect_valid_dly   <= 1'b0;
            redirect_valid_dly_2 <= 1'b0;
        end else begin
            redirect_valid_dly   <= redirect_valid;
            redirect_valid_dly_2 <= redirect_valid_dly;
        end
    end

    always @(*) begin
        // Default output values
        dbus_read_data = 'b0;
        pc_read_inst   = 'b0;
        if (ddr_ready) begin
            if (pc_operation_done) begin
                pc_read_inst = ddr_read_data;
            end
            if (dbus_read_operation_done) begin
                dbus_read_data = ddr_read_data;
            end  // Priority selection logic
        end
    end
endmodule
