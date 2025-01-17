//////////////////////////////////////////////////////////////////////////////
// Module Name: Parameterizable BHT (Branch History Table) with Separate Counters
// Description:
//   - Parameterizable number of sets (default 512)
//   - Four separate arrays for saturating counters (2-bit each)
//   - Each set has one valid bit
//   - Supports simultaneous read and write with write bypassing read
//   - Includes a read miss counter
//////////////////////////////////////////////////////////////////////////////

module bht #(
    parameter SETS = 512,                     // Number of sets in the BHT
    parameter BHTBTB_INDEX_WIDTH = 9,         // Width of the set index (for SETS=512, BHTBTB_INDEX_WIDTH=9)
    parameter COUNTER_WIDTH = 2               // Width of each saturating counter (default 2 bits)
)(
    input wire clock,                           // Clock signal
    input wire reset_n,                         // Active-low asynchronous reset

    // BHT Write Interface
    input wire bht_write_enable,                         // Write enable signal
    input wire [BHTBTB_INDEX_WIDTH-1:0] bht_write_index, // Set index for write operation
    input wire [1:0] bht_write_counter_select,           // Counter select (0 to 3) within the set
    input wire bht_write_inc,                            // Increment signal for the counter
    input wire bht_write_dec,                            // Decrement signal for the counter
    input wire bht_valid_in,                             // Valid signal for the write operation

    // BHT Read Interface
    input wire bht_read_enable,                          // Read enable signal
    input wire [BHTBTB_INDEX_WIDTH-1:0] bht_read_index,  // Set index for read operation
    output reg [COUNTER_WIDTH*4-1:0] bht_read_data,      // Data read from all 4 counters (8 bits)
    output reg bht_valid,                                // Valid signal from the read operation
    output reg [31:0] bht_read_miss_count                // Read miss counter output
);

    // Internal Storage
    reg [COUNTER_WIDTH-1:0] bht_counter0 [0:SETS-1]; // Counter 0 for each set
    reg [COUNTER_WIDTH-1:0] bht_counter1 [0:SETS-1]; // Counter 1 for each set
    reg [COUNTER_WIDTH-1:0] bht_counter2 [0:SETS-1]; // Counter 2 for each set
    reg [COUNTER_WIDTH-1:0] bht_counter3 [0:SETS-1]; // Counter 3 for each set
    reg bht_valid_bits [0:SETS-1];                  // Valid bit per set

    integer i; // Iterator for reset

    // Write and Read Logic with Write Bypass
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            // Asynchronous Reset: Reset all counters and valid bits
            for (i = 0; i < SETS; i = i + 1) begin
                bht_valid_bits[i] <= 1'b0;
                bht_counter0[i] <= {COUNTER_WIDTH{1'b0}};
                bht_counter1[i] <= {COUNTER_WIDTH{1'b0}};
                bht_counter2[i] <= {COUNTER_WIDTH{1'b0}};
                bht_counter3[i] <= {COUNTER_WIDTH{1'b0}};
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

                // Update the selected saturating counter
                case(bht_write_counter_select)
                    2'd0: begin
                        if (bht_write_inc && !bht_write_dec) begin
                            if (bht_counter0[bht_write_index] < 2'b11)
                                bht_counter0[bht_write_index] <= bht_counter0[bht_write_index] + 2'b01;
                            // Else, saturate at 2'b11
                        end
                        else if (bht_write_dec && !bht_write_inc) begin
                            if (bht_counter0[bht_write_index] > 2'b00)
                                bht_counter0[bht_write_index] <= bht_counter0[bht_write_index] - 2'b01;
                            // Else, saturate at 2'b00
                        end
                        // If both inc and dec are asserted, no change
                    end
                    2'd1: begin
                        if (bht_write_inc && !bht_write_dec) begin
                            if (bht_counter1[bht_write_index] < 2'b11)
                                bht_counter1[bht_write_index] <= bht_counter1[bht_write_index] + 2'b01;
                        end
                        else if (bht_write_dec && !bht_write_inc) begin
                            if (bht_counter1[bht_write_index] > 2'b00)
                                bht_counter1[bht_write_index] <= bht_counter1[bht_write_index] - 2'b01;
                        end
                    end
                    2'd2: begin
                        if (bht_write_inc && !bht_write_dec) begin
                            if (bht_counter2[bht_write_index] < 2'b11)
                                bht_counter2[bht_write_index] <= bht_counter2[bht_write_index] + 2'b01;
                        end
                        else if (bht_write_dec && !bht_write_inc) begin
                            if (bht_counter2[bht_write_index] > 2'b00)
                                bht_counter2[bht_write_index] <= bht_counter2[bht_write_index] - 2'b01;
                        end
                    end
                    2'd3: begin
                        if (bht_write_inc && !bht_write_dec) begin
                            if (bht_counter3[bht_write_index] < 2'b11)
                                bht_counter3[bht_write_index] <= bht_counter3[bht_write_index] + 2'b01;
                        end
                        else if (bht_write_dec && !bht_write_inc) begin
                            if (bht_counter3[bht_write_index] > 2'b00)
                                bht_counter3[bht_write_index] <= bht_counter3[bht_write_index] - 2'b01;
                        end
                    end
                    default: begin
                        // Do nothing for invalid select
                    end
                endcase
            end

            // Read Operation with Write Bypass
            if (bht_read_enable) begin
                // Check if read and write are accessing the same set
                if (bht_write_enable && (bht_write_index == bht_read_index)) begin
                    // Determine which counter is being written and bypass its updated value
                    case(bht_write_counter_select)
                        2'd0: begin
                            // Bypass counter0
                            reg [COUNTER_WIDTH-1:0] bypass_counter0;
                            if (bht_write_inc && !bht_write_dec) begin
                                bypass_counter0 = (bht_counter0[bht_read_index] < 2'b11) ? 
                                                  (bht_counter0[bht_read_index] + 2'b01) : 
                                                  bht_counter0[bht_read_index];
                            end
                            else if (bht_write_dec && !bht_write_inc) begin
                                bypass_counter0 = (bht_counter0[bht_read_index] > 2'b00) ? 
                                                  (bht_counter0[bht_read_index] - 2'b01) : 
                                                  bht_counter0[bht_read_index];
                            end
                            else begin
                                bypass_counter0 = bht_counter0[bht_read_index];
                            end
                            bht_read_data <= {bht_counter3[bht_read_index],
                                              bht_counter2[bht_read_index],
                                              bht_counter1[bht_read_index],
                                              bypass_counter0};
                        end
                        2'd1: begin
                            // Bypass counter1
                            reg [COUNTER_WIDTH-1:0] bypass_counter1;
                            if (bht_write_inc && !bht_write_dec) begin
                                bypass_counter1 = (bht_counter1[bht_read_index] < 2'b11) ? 
                                                  (bht_counter1[bht_read_index] + 2'b01) : 
                                                  bht_counter1[bht_read_index];
                            end
                            else if (bht_write_dec && !bht_write_inc) begin
                                bypass_counter1 = (bht_counter1[bht_read_index] > 2'b00) ? 
                                                  (bht_counter1[bht_read_index] - 2'b01) : 
                                                  bht_counter1[bht_read_index];
                            end
                            else begin
                                bypass_counter1 = bht_counter1[bht_read_index];
                            end
                            bht_read_data <= {bht_counter3[bht_read_index],
                                              bht_counter2[bht_read_index],
                                              bypass_counter1,
                                              bht_counter0[bht_read_index]};
                        end
                        2'd2: begin
                            // Bypass counter2
                            reg [COUNTER_WIDTH-1:0] bypass_counter2;
                            if (bht_write_inc && !bht_write_dec) begin
                                bypass_counter2 = (bht_counter2[bht_read_index] < 2'b11) ? 
                                                  (bht_counter2[bht_read_index] + 2'b01) : 
                                                  bht_counter2[bht_read_index];
                            end
                            else if (bht_write_dec && !bht_write_inc) begin
                                bypass_counter2 = (bht_counter2[bht_read_index] > 2'b00) ? 
                                                  (bht_counter2[bht_read_index] - 2'b01) : 
                                                  bht_counter2[bht_read_index];
                            end
                            else begin
                                bypass_counter2 = bht_counter2[bht_read_index];
                            end
                            bht_read_data <= {bht_counter3[bht_read_index],
                                              bypass_counter2,
                                              bht_counter1[bht_read_index],
                                              bht_counter0[bht_read_index]};
                        end
                        2'd3: begin
                            // Bypass counter3
                            reg [COUNTER_WIDTH-1:0] bypass_counter3;
                            if (bht_write_inc && !bht_write_dec) begin
                                bypass_counter3 = (bht_counter3[bht_read_index] < 2'b11) ? 
                                                  (bht_counter3[bht_read_index] + 2'b01) : 
                                                  bht_counter3[bht_read_index];
                            end
                            else if (bht_write_dec && !bht_write_inc) begin
                                bypass_counter3 = (bht_counter3[bht_read_index] > 2'b00) ? 
                                                  (bht_counter3[bht_read_index] - 2'b01) : 
                                                  bht_counter3[bht_read_index];
                            end
                            else begin
                                bypass_counter3 = bht_counter3[bht_read_index];
                            end
                            bht_read_data <= {bypass_counter3,
                                              bht_counter2[bht_read_index],
                                              bht_counter1[bht_read_index],
                                              bht_counter0[bht_read_index]};
                        end
                        default: begin
                            // For invalid select, just read normally
                            bht_read_data <= {bht_counter3[bht_read_index],
                                              bht_counter2[bht_read_index],
                                              bht_counter1[bht_read_index],
                                              bht_counter0[bht_read_index]};
                        end
                    endcase
                end
                else begin
                    // Normal read (without hazard): Concatenate all 4 counters
                    bht_read_data <= {bht_counter3[bht_read_index],
                                      bht_counter2[bht_read_index],
                                      bht_counter1[bht_read_index],
                                      bht_counter0[bht_read_index]};
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
