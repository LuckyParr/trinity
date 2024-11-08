module channel_arb (
    input wire clock,   // Clock signal
    input wire reset_n, // Active-low reset signal

    // PC Channel Inputs and Outputs
    input  wire         pc_index_valid,    // Valid signal for pc_index
    input  wire [ 18:0] pc_index,          // 19-bit input for pc_index (Channel 1)
    output reg          pc_index_ready,    // Ready signal for pc channel
    output reg  [511:0] pc_read_inst,      // Output burst read data for pc channel
    output wire         pc_operation_done,


    // LSU store Channel Inputs and Outputs
    input  wire        opstore_index_valid,    // Valid signal for opstore_index
    input  wire [18:0] opstore_index,          // 19-bit input for opstore_index (Channel 2)
    output reg         opstore_index_ready,    // Ready signal for opstore channel
    input  wire [63:0] opstore_write_mask,     // Write Mask for opstore channel
    input  wire [63:0] opstore_write_data,     // 64-bit data input for opstore channel write
    output wire        opstore_operation_done,

    // LSU load Channel Inputs and Outputs
    input  wire        opload_index_valid,    // Valid signal for opload_index
    input  wire [18:0] opload_index,          // 19-bit input for opload_index (Channel 3)
    output reg         opload_index_ready,    // Ready signal for lw channel
    output reg  [63:0] opload_read_data,      // Output read data for lw channel
    output wire        opload_operation_done,

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
    input  wire         ddr_ready,                // Indicates if DDR is ready for new operation
    
    //add redirect wire
    input wire redirect_valid

);
    reg redirect_valid_dly;
    reg redirect_valid_dly_2;
    assign pc_operation_done      = ddr_operation_done;
    assign opstore_operation_done = ddr_operation_done;
    assign opload_operation_done  = ddr_operation_done;

    always @(*) begin
        // Default output values
        ddr_chip_enable        = 1'b0;
        ddr_burst_mode         = 1'b0;
        ddr_write_enable       = 1'b0;
        ddr_index              = 19'b0;

        ddr_opstore_write_mask = 64'b0;
        ddr_opstore_write_data = 64'b0;


        // Default ready signals
        pc_index_ready         = 1'b0;
        opstore_index_ready    = 1'b0;
        opload_index_ready     = 1'b0;
        if(ddr_ready) begin
        if (opstore_index_valid) begin
            // opstore channel selected for write
            ddr_index              = opstore_index;
            ddr_chip_enable        = 1'b1;
            ddr_write_enable       = 1'b1;  // Write operation
            ddr_opstore_write_mask = opstore_write_mask;
            ddr_opstore_write_data = opstore_write_data;
            ddr_burst_mode         = 1'b0;
            opstore_index_ready    = 1'b1;  // Indicate SW channel is ready
        end else if (opload_index_valid) begin
            // opload channel selected for read
            ddr_index          = opload_index;
            ddr_chip_enable    = 1'b1;
            ddr_write_enable   = 1'b0;  // Read operation
            ddr_burst_mode     = 1'b0;
            opload_index_ready = 1'b1;  // Indicate LW channel is ready
        end else if (pc_index_valid) begin
            // PC channel selected for burst read
            ddr_index        = pc_index;
            ddr_chip_enable  = 1'b1;
            ddr_write_enable = 1'b0;  // Read operation for burst mode
            ddr_burst_mode   = 1'b1;
            pc_index_ready   = 1'b1;  // Indicate PC channel is ready
        end
        end
        //force handshake when redirect_valid = 1
        else if(~ddr_ready && ~redirect_valid_dly && redirect_valid_dly_2)begin
            // PC channel selected for burst read
            ddr_index        = pc_index;
            ddr_chip_enable  = 1'b1;
            ddr_write_enable = 1'b0;  // Read operation for burst mode
            ddr_burst_mode   = 1'b1;
            pc_index_ready   = 1'b1;  // Indicate PC channel is ready
        end
    end

    always @(posedge clock or negedge reset_n) begin
        if(~reset_n)begin
            redirect_valid_dly <= 1'b0;
            redirect_valid_dly_2 <= 1'b0;
        end else begin
            redirect_valid_dly <= redirect_valid;
            redirect_valid_dly_2 <= redirect_valid_dly;
        end
    end

    always @(*) begin
        // Default output values
        opload_read_data = 64'b0;
        pc_read_inst     = 512'b0;
        if (ddr_ready) begin
            if (pc_operation_done) begin
                pc_read_inst = ddr_pc_read_inst;
            end 
            if (opload_operation_done) begin
                opload_read_data = ddr_opload_read_data;
            end  // Priority selection logic

        end
    end
endmodule
