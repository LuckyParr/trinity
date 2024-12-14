module channel_arb (
    input wire clock,   // Clock signal
    input wire reset_n, // Active-low reset signal

    // PC Channel Inputs and Outputs
    input  wire         pc_index_valid,    // Valid signal for pc_index
    input  wire [ 18:0] pc_index,          // 19-bit input for pc_index (Channel 1)
    output reg          pc_index_ready,    // Ready signal for pc channel
    output reg  [511:0] pc_read_inst,      // Output burst read data for pc channel
    output wire         pc_operation_done,

    //trinity bus channel
    input reg                  tbus_index_valid,
    output  wire                 tbus_index_ready,
    input reg  [`RESULT_RANGE] tbus_index,
    input reg  [   `SRC_RANGE] tbus_write_data,
    input reg  [         63:0] tbus_write_mask,

    output  wire [ `RESULT_RANGE] tbus_read_data,
    output  wire                 tbus_operation_done,
    input wire [  `TBUS_RANGE] tbus_operation_type,
    

    // DDR Control Inputs and Outputs
    output reg          ddr_chip_enable,         // Enables chip for one cycle when a channel is selected
    output reg  [ 18:0] ddr_index,               // 19-bit selected index to be sent to DDR
    output reg          ddr_write_enable,        // Write enable signal (1 for write, 0 for read)
    output reg          ddr_burst_mode,          // Burst mode signal, 1 when pc_index is selected
    output reg  [ 63:0] ddr_opstore_write_mask,  // Output write mask for opstore channel
    output reg  [ 63:0] ddr_opstore_write_data,  // Output write data for opstore channel
    input  wire [ 63:0] ddr_opload_read_data,    // 64-bit data output for lw channel read
    input  wire [511:0] ddr_pc_read_inst,        // 512-bit data output for pc channel burst read
    input  wire         ddr_operation_done,
    input  wire         ddr_ready,               // Indicates if DDR is ready for new operation

    //add redirect wire
    input wire redirect_valid

);
    reg redirect_valid_dly;
    reg redirect_valid_dly_2;

    reg pc_latch, opstore_latch, opload_latch;
    always @(posedge clock or negedge reset_n) begin
        if (~reset_n) begin
            opstore_latch <= 1'b0;
            opload_latch  <= 1'b0;
            pc_latch      <= 1'b0;
        end else if (pc_index_valid && pc_index_ready) begin
            opstore_latch <= 1'b0;
            opload_latch  <= 1'b0;
            pc_latch      <= 1'b1;
        end else if (tbus_index_valid & (tbus_operation_type == `TBUS_READ) && tbus_index_ready) begin
            opstore_latch <= 1'b0;
            opload_latch  <= 1'b1;
            pc_latch      <= 1'b0;
        end else if (tbus_index_valid & (tbus_operation_type == `TBUS_WRITE) && tbus_index_ready) begin
            opstore_latch <= 1'b1;
            opload_latch  <= 1'b0;
            pc_latch      <= 1'b0;
        end
    end

    wire opstore_operation_done = opstore_latch ? ddr_operation_done : 1'b0;
    wire opload_operation_done  = opload_latch ? ddr_operation_done : 1'b0;

    assign tbus_operation_done = opstore_operation_done | opload_operation_done;
    assign pc_operation_done      = pc_latch ? ddr_operation_done : 1'b0;

    wire anyop_fire;
    assign anyop_fire = (tbus_index_valid & (tbus_operation_type == `TBUS_READ) & tbus_index_ready | tbus_index_valid & (tbus_operation_type == `TBUS_WRITE) & tbus_index_ready | pc_index_valid & pc_index_ready);

    always @(posedge clock or negedge reset_n) begin
        if (~reset_n) begin
            // default output values to simddr.v
            ddr_chip_enable        <= 1'b0;
            ddr_burst_mode         <= 1'b0;
            ddr_write_enable       <= 1'b0;
            ddr_index              <= 19'b0;
            ddr_opstore_write_mask <= 64'b0;
            ddr_opstore_write_data <= 64'b0;
            // default output ready signals to pc_ctrl.v and mem.v
            pc_index_ready         <= 1'b0;
            tbus_index_ready <= 1'b0;
        end else begin
            //when ddr is idle , process req by priority
            // if (ddr_ready) begin
            if (anyop_fire) begin
                ddr_chip_enable     <= 1'b0;
                pc_index_ready      <= 1'b0;
                tbus_index_ready <= 1'b0;
            end else if (ddr_ready) begin
                if (tbus_index_valid & (tbus_operation_type == `TBUS_WRITE)) begin
                    // opstore channel selected for write
                    ddr_index              <= tbus_index;
                    ddr_chip_enable        <= 1'b1;
                    ddr_write_enable       <= 1'b1;  // Write operation
                    ddr_opstore_write_mask <= tbus_write_mask;
                    ddr_opstore_write_data <= tbus_write_data;
                    ddr_burst_mode         <= 1'b0;
                    tbus_index_ready <= 1'b1;  // Indicate SW channel is ready
                end else if (tbus_index_valid & (tbus_operation_type == `TBUS_READ)) begin
                    // opload channel selected for read
                    ddr_index          <= tbus_index;
                    ddr_chip_enable    <= 1'b1;
                    ddr_write_enable   <= 1'b0;  // Read operation
                    ddr_burst_mode     <= 1'b0;
                    tbus_index_ready <= 1'b1;  // Indicate LW channel is ready
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
        tbus_read_data = 64'b0;
        pc_read_inst     = 512'b0;
        if (ddr_ready) begin
            if (pc_operation_done) begin
                pc_read_inst = ddr_pc_read_inst;
            end
            if (opload_operation_done) begin
                tbus_read_data = ddr_opload_read_data;
            end  // Priority selection logic

        end
    end
endmodule
