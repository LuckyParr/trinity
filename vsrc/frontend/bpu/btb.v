///////////////////////////////////////////////////////////////////////////////
// Module Name: BTB (Branch Target Buffer)
// Description:
//   - 512 sets
//   - 1 valid bit per set
//   - 4 predict target addresses per set (32 bits each)
//   - Utilizes a single SRAM module with DATA_WIDTH=129 to store valid bit and 4 targets
//   - Includes a read miss counter for performance monitoring
///////////////////////////////////////////////////////////////////////////////

module btb (
    // Clock and Reset
    input wire clock,                     // Clock signal
    input wire reset_n,                   // Active low asynchronous reset

    //BTB Write Interface
    input wire btb_ce,                    // Chip enable
    input wire btb_we,                    // Write enable
    input wire [128:0] btb_wmask,
    input wire [8:0] btb_waddr,           // Write address (9 bits for 512 sets)
    input wire [128:0] btb_din,           // Data input (1 valid bit + 4 targets * 32 bits)

    //BTB Read Interface
    input wire [8:0] btb_raddr,           // Read address (9 bits for 512 sets)
    output wire btb_read_valid_out,       // Valid bit from read operation
    output wire [127:0] btb_read_targets, // 4 target addresses from read operation

    // PMU Interface
    output wire [31:0] btb_read_miss_count_out // Read miss counter output
);

    // Define DATA_WIDTH as 129 bits: 1 valid bit + 4 * 32-bit target addresses
    localparam DATA_WIDTH_BTB = 129;

    // Instantiate the SRAM module
    wire [DATA_WIDTH_BTB-1:0] btb_sram_dout;

    sram #(
        .DATA_WIDTH(DATA_WIDTH_BTB),
        .ADDR_WIDTH(9)  // 9 bits to address 512 sets
    ) sram_btb (
        .clock(clock),
        .reset_n(reset_n),
        .ce(btb_ce),
        .we(btb_we),
        .waddr(btb_waddr),
        .raddr(btb_raddr),
        .din(btb_din),                        // Concatenated valid bit and target addresses
        .wmask(btb_wmask),                    
        .dout(btb_sram_dout)
    );

    // Assign outputs by unpacking the read data
    assign btb_read_valid_out = btb_sram_dout[128];
    assign btb_read_targets = btb_sram_dout[127:0];

    // PMU Logic: Read Miss Counter
    reg [31:0] btb_read_miss_count_reg;
    assign btb_read_miss_count_out = btb_read_miss_count_reg;

    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            btb_read_miss_count_reg <= 32'd0;
        end else begin
            if (btb_ce && !btb_we) begin // Read operation: btb_ce=1, btb_we=0
                if (!btb_read_valid_out) begin
                    btb_read_miss_count_reg <= btb_read_miss_count_reg + 1;
                end
            end
        end
    end

endmodule
