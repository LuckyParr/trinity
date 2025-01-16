//////////////////////////////////////////////////////////////////////////////
// Module Name: Parameterizable BHT (Branch History Table) with 2D Vector
// Description:
//   - Parameterizable number of sets (default 512)
//   - Each set contains 4 saturating counters (2-bit each) as an 8-bit vector
//   - Each set has one valid bit
//   - Supports simultaneous read and write with write bypassing read
//   - Includes a read miss counter
//////////////////////////////////////////////////////////////////////////////

module bht #(
    parameter SETS = 512,                // Number of sets in the BHT
    parameter BHTBTB_INDEX_WIDTH = 9,           // Width of the set index (for SETS=512, BHTBTB_INDEX_WIDTH=9)
    parameter COUNTER_WIDTH = 2          // Width of each saturating counter (default 2 bits)
)(
    input wire clock,                       // Clock signal

    input wire reset_n,                     // Active-low asynchronous reset

    //BHT Write Interface
    input wire bht_write_enable,                         // Write enable signal
    input wire [BHTBTB_INDEX_WIDTH-1:0] bht_write_index,        // Set index for write operation
    input wire [1:0] bht_write_counter_select,           // Counter select (0 to 3) within the set
    input wire bht_write_inc,                            // Increment signal for the counter
    input wire bht_write_dec,                            // Decrement signal for the counter
    input wire bht_valid_in,                             // Valid signal for the write operation

    //BHT Read Interface
    input wire bht_read_enable,                          // Read enable signal
    input wire [BHTBTB_INDEX_WIDTH-1:0] bht_read_index,         // Set index for read operation
    output reg [COUNTER_WIDTH*4-1:0] bht_read_data,      // Data read from all 4 counters (8 bits)
    output reg bht_valid,                                // Valid signal from the read operation
    output reg [31:0] bht_read_miss_count               // Read miss counter output
);

    // Internal Storage
    reg [COUNTER_WIDTH*4-1:0] bht_counters [0:SETS-1]; // 4 saturating counters per set as 8-bit vector
    reg bht_valid_bits [0:SETS-1];                    // Valid bit per set

    integer i; // Iterator for reset

    // Saturating Counter Increment Function
    function [COUNTER_WIDTH-1:0] bht_saturate_increment;
        input [COUNTER_WIDTH-1:0] count;
        begin
            if (count < 2'b11) // If not at max value
                bht_saturate_increment = count + 2'b01;
            else
                bht_saturate_increment = count; // Saturate at max
        end
    endfunction

    // Saturating Counter Decrement Function
    function [COUNTER_WIDTH-1:0] bht_saturate_decrement;
        input [COUNTER_WIDTH-1:0] count;
        begin
            if (count > 2'b00)
                bht_saturate_decrement = count - 2'b01;
            else
                bht_saturate_decrement = count; // Saturate at 0
        end
    endfunction

    // Write and Read Logic with Write Bypass
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            // Asynchronous Reset: Reset all counters and valid bits
            for (i = 0; i < SETS; i = i + 1) begin
                bht_valid_bits[i] <= 1'b0;
                bht_counters[i] <= {COUNTER_WIDTH*4{1'b0}};
            end
            bht_read_data <= {COUNTER_WIDTH*4{1'b0}};
            bht_valid <= 1'b0;
            bht_read_miss_count <= 32'd0;
        end
        else begin
            // Write Operation
            if (bht_write_enable) begin
                // Update Valid Bit
                bht_valid_bits[bht_write_index] <= bht_valid_in;

                // Update the selected saturating counter using bit slicing
                case(bht_write_counter_select)
                    2'd0: begin
                        if (bht_write_inc && !bht_write_dec)
                            bht_counters[bht_write_index][1:0] <= bht_saturate_increment(bht_counters[bht_write_index][1:0]);
                        else if (bht_write_dec && !bht_write_inc)
                            bht_counters[bht_write_index][1:0] <= bht_saturate_decrement(bht_counters[bht_write_index][1:0]);
                        // If both write_inc and write_dec are asserted, no change occurs
                    end
                    2'd1: begin
                        if (bht_write_inc && !bht_write_dec)
                            bht_counters[bht_write_index][3:2] <= bht_saturate_increment(bht_counters[bht_write_index][3:2]);
                        else if (bht_write_dec && !bht_write_inc)
                            bht_counters[bht_write_index][3:2] <= bht_saturate_decrement(bht_counters[bht_write_index][3:2]);
                    end
                    2'd2: begin
                        if (bht_write_inc && !bht_write_dec)
                            bht_counters[bht_write_index][5:4] <= bht_saturate_increment(bht_counters[bht_write_index][5:4]);
                        else if (bht_write_dec && !bht_write_inc)
                            bht_counters[bht_write_index][5:4] <= bht_saturate_decrement(bht_counters[bht_write_index][5:4]);
                    end
                    2'd3: begin
                        if (bht_write_inc && !bht_write_dec)
                            bht_counters[bht_write_index][7:6] <= bht_saturate_increment(bht_counters[bht_write_index][7:6]);
                        else if (bht_write_dec && !bht_write_inc)
                            bht_counters[bht_write_index][7:6] <= bht_saturate_decrement(bht_counters[bht_write_index][7:6]);
                    end
                    default: begin
                        // Do nothing
                    end
                endcase
            end

            // Read Operation with Write Bypass
            if (bht_read_enable) begin
                // Check if read and write are accessing the same set
                if (bht_write_enable &&
                    (bht_write_index == bht_read_index)) begin
                    // Determine which counter is being written and bypass its updated value
                    case(bht_write_counter_select)
                        2'd0: begin
                            if (bht_write_inc && !bht_write_dec)
                                bht_read_data <= {bht_counters[bht_read_index][7:6], bht_counters[bht_read_index][5:4], 
                                                  bht_counters[bht_read_index][3:2], bht_saturate_increment(bht_counters[bht_read_index][1:0])};
                            else if (bht_write_dec && !bht_write_inc)
                                bht_read_data <= {bht_counters[bht_read_index][7:6], bht_counters[bht_read_index][5:4], 
                                                  bht_counters[bht_read_index][3:2], bht_saturate_decrement(bht_counters[bht_read_index][1:0])};
                            else
                                bht_read_data <= bht_counters[bht_read_index];
                        end
                        2'd1: begin
                            if (bht_write_inc && !bht_write_dec)
                                bht_read_data <= {bht_counters[bht_read_index][7:6], bht_counters[bht_read_index][5:4], 
                                                  bht_saturate_increment(bht_counters[bht_read_index][3:2]), bht_counters[bht_read_index][1:0]};
                            else if (bht_write_dec && !bht_write_inc)
                                bht_read_data <= {bht_counters[bht_read_index][7:6], bht_counters[bht_read_index][5:4], 
                                                  bht_saturate_decrement(bht_counters[bht_read_index][3:2]), bht_counters[bht_read_index][1:0]};
                            else
                                bht_read_data <= bht_counters[bht_read_index];
                        end
                        2'd2: begin
                            if (bht_write_inc && !bht_write_dec)
                                bht_read_data <= {bht_counters[bht_read_index][7:6], bht_saturate_increment(bht_counters[bht_read_index][5:4]), 
                                                  bht_counters[bht_read_index][3:2], bht_counters[bht_read_index][1:0]};
                            else if (bht_write_dec && !bht_write_inc)
                                bht_read_data <= {bht_counters[bht_read_index][7:6], bht_saturate_decrement(bht_counters[bht_read_index][5:4]), 
                                                  bht_counters[bht_read_index][3:2], bht_counters[bht_read_index][1:0]};
                            else
                                bht_read_data <= bht_counters[bht_read_index];
                        end
                        2'd3: begin
                            if (bht_write_inc && !bht_write_dec)
                                bht_read_data <= {bht_saturate_increment(bht_counters[bht_read_index][7:6]), bht_counters[bht_read_index][5:4], 
                                                  bht_counters[bht_read_index][3:2], bht_counters[bht_read_index][1:0]};
                            else if (bht_write_dec && !bht_write_inc)
                                bht_read_data <= {bht_saturate_decrement(bht_counters[bht_read_index][7:6]), bht_counters[bht_read_index][5:4], 
                                                  bht_counters[bht_read_index][3:2], bht_counters[bht_read_index][1:0]};
                            else
                                bht_read_data <= bht_counters[bht_read_index];
                        end
                        default: begin
                            bht_read_data <= bht_counters[bht_read_index];
                        end
                    endcase
                end
                else begin
                    // Normal read(without hazard): Concatenate all 4 counters
                    bht_read_data <= bht_counters[bht_read_index];
                end

                // Read the valid bit
                bht_valid <= bht_valid_bits[bht_read_index];

                // Update Read Miss Count
                if (!bht_valid_bits[bht_read_index]) begin
                    bht_read_miss_count <= bht_read_miss_count + 1;
                end
            end
            else begin
                // If not reading, retain previous read_data and valid_out
                bht_read_data <= bht_read_data;
                bht_valid <= bht_valid;
                bht_read_miss_count <= bht_read_miss_count;
            end
        end
    end

endmodule
