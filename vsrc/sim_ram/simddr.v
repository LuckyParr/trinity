
module simddr (
    input wire clock,                         // Clock signal
    input wire reset_n,                       // reset_n signal
    input wire ddr_chip_enable,                 // Chip enable signal (1 to enable operations)
    input wire [18:0] ddr_index,              // Address input (19 bits to address 524,288 entries)
    input wire ddr_write_enable,                // Write enable signal (1 for write, 0 for read)
    input wire ddr_burst_mode,                  // Burst mode control (1 for 512-bit, 0 for 64-bit)
    input wire [63:0] ddr_opstore_write_mask,    // Write Mask
    input wire [63:0] ddr_opstore_write_data,    // 64-bit data input for single access write
    //input wire redirect_valid,
    output reg [63:0] ddr_opload_read_data,     // 64-bit data output for single access read
    output reg [511:0] ddr_pc_read_inst, // 512-bit data output for burst read operations
    input wire [511:0] ddr_l2_write_data, // 512-bit data input for burst write operations
    output wire ddr_operation_done,
    output reg ddr_ready                        // Ready signal, high when data is available (read) or written (write)
);

import "DPI-C" function longint difftest_ram_read(input longint rIdx);

import "DPI-C" function void difftest_ram_write
(
  input  longint index,
  input  longint data,
  input  longint mask
);

    //reg redirect_valid_dly;
    //always @(posedge clock or negedge reset_n) begin
    //    if(~reset_n)begin
    //        redirect_valid_dly <= 1'b0;
    //    end else begin
    //        redirect_valid_dly <= redirect_valid;
    //    end
    //end

    reg ddr_burst_mode_latch;
    always @(posedge clock or negedge reset_n ) begin
        if(!reset_n) begin
            ddr_burst_mode_latch <= 1'b0;
        end
        //else if(ddr_chip_enable  & ~operation_in_progress) begin
        else if(ddr_chip_enable ) begin
            ddr_burst_mode_latch <= ddr_burst_mode;
        end
    end

    // reg [63:0] memory [0:524287];           // 64-bit DDR memory array (524,288 entries, each 64-bit)

    reg [7:0] cycle_counter;                // 8-bit counter for counting up to 80 cycles for burst or 64 cycles for single access
    reg operation_in_progress;              // Flag to indicate if a read or write operation is in progress

    // Initialize the memory with some test values (optional, can be replaced with actual data)
    // integer i;
    // initial begin
    //     for (i = 0; i < 524288; i = i + 1) begin
    //         memory[i] = 64'hA0A0_B0B0_C0C0_D0D0 + i;
    //     end
    // end
    reg ddr_ready_dly;
    always @(posedge clock or negedge reset_n) begin
        if (~reset_n) begin 
            ddr_ready_dly <= 1'b1;
        end else begin
            ddr_ready_dly <= ddr_ready;
        end
    end
    assign ddr_operation_done = ddr_ready & (!ddr_ready_dly);
    // State machine to handle both burst and single access read/write operations
    //wire [63:0] concat_address = {45'b0, ddr_index};
    reg [63:0] concat_address;
    always @(posedge clock or negedge reset_n) begin
        if(~reset_n)begin
            concat_address <= 64'd0;
        end else if (ddr_chip_enable) begin
            concat_address <= {45'b0, ddr_index};
        end
    end
    always @(posedge clock or negedge reset_n) begin
        if (~reset_n) begin
            cycle_counter <= 8'b0;
            ddr_ready <= 1'b1;
            operation_in_progress <= 1'b0;
            ddr_pc_read_inst <= 512'b0;
            ddr_opload_read_data <= 64'b0;
        end else begin
            //if (ddr_chip_enable && operation_in_progress) begin  // Operations only proceed when ddr_chip_enable is high
            if (operation_in_progress) begin  // Operations only proceed when ddr_chip_enable is high
                //if (ddr_burst_mode && cycle_counter == 8'd79) begin  // After 80 cycles in burst mode
                if (ddr_burst_mode_latch && cycle_counter == 8'd79) begin  // After 80 cycles in burst mode
                    cycle_counter <= 8'b0;        // reset_n cycle counter
                    ddr_ready <= 1'b1;                // Signal that the operation is complete
                    operation_in_progress <= 1'b0;  // End the operation
                    
                    if (!ddr_write_enable) begin
                        // Read 512 bits (8 x 64-bit entries) from memory in one cycle for burst mode
                        ddr_pc_read_inst[63:0] <= difftest_ram_read(concat_address);
                        ddr_pc_read_inst[127:64] <= difftest_ram_read(concat_address  +64'd1);
                        ddr_pc_read_inst[191:128] <= difftest_ram_read(concat_address +64'd2);
                        ddr_pc_read_inst[255:192] <= difftest_ram_read(concat_address +64'd3);
                        ddr_pc_read_inst[319:256] <= difftest_ram_read(concat_address +64'd4);
                        ddr_pc_read_inst[383:320] <= difftest_ram_read(concat_address +64'd5);
                        ddr_pc_read_inst[447:384] <= difftest_ram_read(concat_address +64'd6);
                        ddr_pc_read_inst[511:448] <= difftest_ram_read(concat_address +64'd7);
                        // ddr_pc_read_inst[63:0]   <= memory[ddr_index];
                        // ddr_pc_read_inst[127:64] <= memory[ddr_index + 1];
                        // ddr_pc_read_inst[191:128] <= memory[ddr_index + 2];
                        // ddr_pc_read_inst[255:192] <= memory[ddr_index + 3];
                        // ddr_pc_read_inst[319:256] <= memory[ddr_index + 4];
                        // ddr_pc_read_inst[383:320] <= memory[ddr_index + 5];
                        // ddr_pc_read_inst[447:384] <= memory[ddr_index + 6];
                        // ddr_pc_read_inst[511:448] <= memory[ddr_index + 7];
                    end else if (ddr_write_enable) begin
                        // Write 512 bits (8 x 64-bit entries) to memory in one cycle for burst mode
                        // memory[ddr_index]     <= ddr_l2_write_data[63:0];
                        // memory[ddr_index + 1] <= ddr_l2_write_data[127:64];
                        // memory[ddr_index + 2] <= ddr_l2_write_data[191:128];
                        // memory[ddr_index + 3] <= ddr_l2_write_data[255:192];
                        // memory[ddr_index + 4] <= ddr_l2_write_data[319:256];
                        // memory[ddr_index + 5] <= ddr_l2_write_data[383:320];
                        // memory[ddr_index + 6] <= ddr_l2_write_data[447:384];
                        // memory[ddr_index + 7] <= ddr_l2_write_data[511:448];
                    end
                //end else if (!ddr_burst_mode && cycle_counter == 8'd63) begin  // After 64 cycles for single access
                end else if (!ddr_burst_mode_latch && cycle_counter == 8'd63) begin  // After 64 cycles for single access
                    cycle_counter <= 8'b0;        // reset_n cycle counter
                    ddr_ready <= 1'b1;                // Signal that the operation is complete
                    operation_in_progress <= 1'b0;  // End the operation
                    
                    if (!ddr_write_enable) begin
                        // Single 64-bit read from memory for single access mode
                        // ddr_opload_read_data <= memory[ddr_index];
                        ddr_opload_read_data[63:0] <= difftest_ram_read(concat_address);

                    end else if (ddr_write_enable) begin
                        // Single 64-bit write to memory for single access mode
                        // memory[ddr_index] <= ddr_opstore_write_data;
                        difftest_ram_write(concat_address,ddr_opstore_write_data ,ddr_opstore_write_mask);
                    end
                end else begin
                    cycle_counter <= cycle_counter + 1;  // Increment cycle counter for both modes
                    ddr_ready <= 1'b0;                       // Data not ddr_ready during the wait
                end
            end else if (ddr_chip_enable && !operation_in_progress && (!ddr_write_enable || ddr_write_enable)) begin
                // Start a new read or write operation if ddr_chip_enable is 1
                cycle_counter <= 8'b0;            // reset_n cycle counter
                operation_in_progress <= 1'b1;    // Mark operation as in progress
                ddr_ready <= 1'b0;                    // reset_n ddr_ready signal
            end
        end
    end

endmodule
