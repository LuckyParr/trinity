////////////////////////////////////////////////////////////////////////////////
// Module Name: Parameterizable BHT (Branch History Table)
// Description:
//   - Parameterizable number of sets (default 512)
//   - Each set contains 4 saturating counters (2-bit each)
//   - Each set has one valid bit
//   - Supports simultaneous read and write with write bypassing read
////////////////////////////////////////////////////////////////////////////////

module bht #(
    parameter SETS = 512,                // Number of sets in the BHT
    parameter INDEX_WIDTH = 9,           // Width of the set index (for SETS=512, INDEX_WIDTH=9)
    parameter COUNTER_WIDTH = 2          // Width of each saturating counter (default 2 bits)
)(
    input wire clock,                       // Clock signal

    input wire reset_n,                     // Active-low asynchronous reset

    // Write Interface
    input wire write_enable,                         // Write enable signal
    input wire [INDEX_WIDTH-1:0] write_index,        // Set index for write operation
    input wire [1:0] write_counter_select,           // Counter select (0 to 3) within the set
    input wire write_inc,                            // Increment signal for the counter
    input wire write_dec,                            // Decrement signal for the counter
    input wire valid_in,                             // Valid signal for the write operation

    // Read Interface
    input wire read_enable,                          // Read enable signal
    input wire [INDEX_WIDTH-1:0] read_index,         // Set index for read operation
    input wire [1:0] read_counter_select,            // Counter select (0 to 3) within the set
    output reg [COUNTER_WIDTH-1:0] read_data,        // Data read from the counter
    output reg valid_out                             // Valid signal from the read operation
);

    // Internal Storage
    reg [COUNTER_WIDTH-1:0] counters [0:SETS-1][0:3]; // 4 saturating counters per set
    reg valid_bits [0:SETS-1];                        // Valid bit per set

    integer i, j; // Iterators for reset

    // Saturating Counter Increment Function
    function [COUNTER_WIDTH-1:0] saturate_increment;
        input [COUNTER_WIDTH-1:0] count;
        begin
            if (count < {1'b1, {(COUNTER_WIDTH-1){1'b1}}}) // If not at max value
                saturate_increment = count + 1;
            else
                saturate_increment = count; // Saturate at max
        end
    endfunction

    // Saturating Counter Decrement Function
    function [COUNTER_WIDTH-1:0] saturate_decrement;
        input [COUNTER_WIDTH-1:0] count;
        begin
            if (count > 0)
                saturate_decrement = count - 1;
            else
                saturate_decrement = count; // Saturate at 0
        end
    endfunction

    // Write and Read Logic with Write Bypass
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            // Asynchronous Reset: Reset all counters and valid bits
            for (i = 0; i < SETS; i = i + 1) begin
                valid_bits[i] <= 1'b0;
                for (j = 0; j < 4; j = j + 1) begin
                    counters[i][j] <= {COUNTER_WIDTH{1'b0}};
                end
            end
            read_data <= {COUNTER_WIDTH{1'b0}};
            valid_out <= 1'b0;
        end
        else begin
            // Write Operation
            if (write_enable) begin
                // Update Valid Bit
                valid_bits[write_index] <= valid_in;

                // Update the selected saturating counter
                if (write_inc && !write_dec) begin
                    counters[write_index][write_counter_select] <= saturate_increment(counters[write_index][write_counter_select]);
                end
                else if (write_dec && !write_inc) begin
                    counters[write_index][write_counter_select] <= saturate_decrement(counters[write_index][write_counter_select]);
                end
                // If both write_inc and write_dec are asserted, no change occurs
            end

            // Read Operation with Write Bypass
            if (read_enable) begin
                // Check if read and write are accessing the same set and counter
                if (write_enable &&
                    (write_index == read_index) &&
                    (write_counter_select == read_counter_select)) begin
                    // Determine the updated value based on write operation
                    if (write_inc && !write_dec) begin
                        read_data <= saturate_increment(counters[read_index][read_counter_select]);
                    end
                    else if (write_dec && !write_inc) begin
                        read_data <= saturate_decrement(counters[read_index][read_counter_select]);
                    end
                    else begin
                        // If both or neither write_inc/write_dec are asserted, return current value
                        read_data <= counters[read_index][read_counter_select];
                    end
                end
                else begin
                    // Normal read
                    read_data <= counters[read_index][read_counter_select];
                end

                // Read the valid bit
                valid_out <= valid_bits[read_index];
            end
            else begin
                // If not reading, retain previous read_data and valid_out
                read_data <= read_data;
                valid_out <= valid_out;
            end
        end
    end

endmodule
