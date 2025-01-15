////////////////////////////////////////////////////////////////////////////////
// Module Name: BTB with PMU (Branch Target Buffer with Performance Monitoring Unit)
// Description:
//   - 512 sets
//   - 1 valid bit per set
//   - 4 predict target addresses per set (32 bits each)
//   - Utilizes a single SRAM module with DATA_WIDTH=129 to store all information
//   - Supports read and write operations without write bypassing
//   - Includes a read miss counter that increments when a read miss occurs
////////////////////////////////////////////////////////////////////////////////

module btb (
    // Clock and Reset
    input wire clock,                     // Clock signal
    input wire reset_n,                   // Active low asynchronous reset

    // Chip Enable and Write Enable
    input wire ce,                        // Chip enable
    input wire we,                        // Write enable

    // Write Interface
    input wire [8:0] waddr,               // Write address (9 bits for 512 sets)
    input wire write_valid_in,            // Valid bit for write operation
    input wire [127:0] write_targets,     // 4 target addresses (4 * 32 bits)

    // Read Interface
    input wire [8:0] raddr,               // Read address (9 bits for 512 sets)
    output wire read_valid_out,           // Valid bit from read operation
    output wire [127:0] read_targets,     // 4 target addresses from read operation

    // PMU Interface
    output wire [31:0] read_miss_count_out // Read miss counter output
);

    // Define DATA_WIDTH as 129 bits: 1 valid bit + 4 * 32-bit target addresses
    localparam DATA_WIDTH_BTB = 129;

    // Instantiate the SRAM module
    wire [DATA_WIDTH_BTB-1:0] sram_dout;

    sram #(
        .DATA_WIDTH(DATA_WIDTH_BTB),
        .ADDR_WIDTH(9)  // 9 bits to address 512 sets
    ) sram_btb (
        .clock(clock),
        .reset_n(reset_n),
        .ce(ce),
        .we(we),
        .waddr(waddr),
        .raddr(raddr),
        .din({write_valid_in, write_targets}),    // Concatenate valid bit and target addresses
        .wmask({DATA_WIDTH_BTB{we}}),            // Write mask: all bits writable when 'we' is high
        .dout(sram_dout)
    );

    // Assign outputs by unpacking the read data
    assign read_valid_out = sram_dout[128];
    assign read_targets = sram_dout[127:0];

    // PMU Logic: Read Miss Counter
    reg [31:0] read_miss_count; // 32-bit read miss counter

    // Assign the read miss count to output
    assign read_miss_count_out = read_miss_count;

    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            read_miss_count <= 32'd0;
        end else begin
            // Check if a read operation is active: ce=1 and we=0
            // and if a read miss occurs: read_valid_out=0
            if (ce && !we) begin
                if (!read_valid_out) begin
                    read_miss_count <= read_miss_count + 1;
                end
            end
        end
    end

endmodule
