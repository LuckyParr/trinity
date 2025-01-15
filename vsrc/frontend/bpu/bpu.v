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
    input wire btb_write_enable,                 // Write enable for BTB
    input wire [8:0] btb_write_index,            // Set index for BTB write operation
    input wire btb_write_valid_in,               // Valid bit for BTB write operation
    input wire [127:0] btb_write_targets,        // Four 32-bit target addresses for BTB write operation

    // Outputs from BHT
    output wire [1:0] bht_prediction,            // 2-bit branch prediction
    output wire bht_valid,                       // BHT valid bit
    output wire [31:0] bht_read_miss_count,      // BHT read miss count

    // Outputs from BTB
    output wire [127:0] btb_targets,             // Four 32-bit branch target addresses
    output wire btb_valid,                       // BTB valid bit
    output wire [31:0] btb_read_miss_count       // BTB read miss count
);

    // Extract set address from PC [12:4]
    wire [8:0] set_addr = pc[12:4];

    // Define Counter Select for BHT Read (assuming you want to read a specific counter)
    // Here, we choose to read the first counter (0). Modify as needed.
    wire [1:0] bht_read_counter_select = 2'd0;

    // Instantiate BHT
    bht #(
        .SETS(512),
        .INDEX_WIDTH(9),
        .COUNTER_WIDTH(2)
    ) bht_inst (
        .clock(clock),
        .reset_n(reset_n),

        // Write Interface
        .write_enable(bht_write_enable),
        .write_index(bht_write_index),
        .write_counter_select(bht_write_counter_select),
        .write_inc(bht_write_inc),
        .write_dec(bht_write_dec),
        .valid_in(bht_valid_in),

        // Read Interface
        .read_enable(1'b1),                    // Always enable read
        .read_index(set_addr),
        .read_counter_select(bht_read_counter_select),
        .read_data(bht_prediction),
        .valid_out(bht_valid)
    );

    // Instantiate BTB
    btb btb_inst (
        .clock(clock),
        .reset_n(reset_n),

        // Write Interface
        .ce(btb_write_enable),                // Chip enable during write
        .we(btb_write_enable),                // Write enable during write
        .waddr(btb_write_index),
        .write_valid_in(btb_write_valid_in),
        .write_targets(btb_write_targets),

        // Read Interface
        .raddr(set_addr),
        .read_valid_out(btb_valid),
        .read_targets(btb_targets),

        // PMU Interface
        .read_miss_count_out(btb_read_miss_count)
    );


endmodule
