///////////////////////////////////////////////////////////////////////////////
// Module Name: BPU (Branch Prediction Unit)
// Description:
//   - Instantiates both BHT and BTB modules
//   - Receives a 64-bit PC, extracts [12:4] bits as set address
//   - Reads from both BHT and BTB using the set address
//   - Provides write interfaces to update BHT and BTB
//   - Outputs predictions and target addresses
//   - Exposes read miss counts from both BHT and BTB
///////////////////////////////////////////////////////////////////////////////

module bpu (
    input wire clock,                     // Clock signal
    input wire reset_n,                   // Active low asynchronous reset
    input wire [63:0] pc,                 // 64-bit Program Counter input

    // BHT Write Interface
    input wire bht_write_enable,                 // Write enable for BHT
    input wire [8:0] bht_write_index,            // Set index for BHT write operation
    input wire [1:0] bht_write_counter_select,   // Counter select within the BHT set (0 to 3)
    input wire bht_write_inc,                    // Increment signal for BHT counter
    input wire bht_write_dec,                    // Decrement signal for BHT counter
    input wire bht_valid_in,                     // Valid bit for BHT write operation

    // BTB Write Interface
    input wire btb_ce,                 // Write enable for BTB
    input wire btb_we,
    input wire [128:0] btb_wmask,
    input wire [8:0] btb_write_index,            // Set index for BTB write operation
    input wire [128:0] btb_din,
    // Outputs from BHT
    output wire [7:0] bht_read_data,              // 8-bit data from BHT (4 counters)
    output wire bht_valid,                       // BHT valid bit
    output wire [31:0] bht_read_miss_count,      // BHT read miss count

    // Outputs from BTB
    output wire [127:0] btb_targets,             // Four 32-bit branch target addresses
    output wire btb_valid,                       // BTB valid bit
    output wire [31:0] btb_read_miss_count       // BTB read miss count
);

    // Extract set address from PC [12:4]
    wire [8:0] read_index = pc[12:4];

    // Instantiate BHT
    bht #(
        .SETS(512),
        .BHTBTB_INDEX_WIDTH(9),
        .COUNTER_WIDTH(2)
    ) bht_inst (
        .clock(clock),
        .reset_n(reset_n),

        // Write Interface
        .bht_write_enable(bht_write_enable),
        .bht_write_index(bht_write_index),
        .bht_write_counter_select(bht_write_counter_select),
        .bht_write_inc(bht_write_inc),
        .bht_write_dec(bht_write_dec),
        .bht_valid_in(bht_valid_in),

        // Read Interface
        .bht_read_enable(1'b1),                    // Always enable read
        .bht_read_index(read_index),
        .bht_read_data(bht_read_data),             // 8-bit read data (4 counters)
        .bht_valid(bht_valid),
        .bht_read_miss_count(bht_read_miss_count)  // Read miss count output
    );

    // Instantiate BTB
    btb btb_inst (
        .clock(clock),
        .reset_n(reset_n),

        // Write Interface
        .btb_ce(btb_ce),                // Chip enable during write
        .btb_we(btb_we),                // Write enable during write
        .btb_wmask (btb_wmask),
        .btb_write_index(btb_write_index),
        .btb_din(btb_din),    // Concatenate valid bit and target addresses

        // Read Interface
        .btb_read_index(read_index),
        .btb_read_valid_out(btb_valid),
        .btb_read_targets(btb_targets),

        // PMU Interface
        .btb_read_miss_count_out(btb_read_miss_count)
    );


endmodule
