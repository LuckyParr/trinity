module dcache 
#(parameter DATA_WIDTH = 64,  // Width of data
  parameter ADDR_WIDTH = 9   // Width of address bus
) (
    
    input wire clk,        // Clock signal
    input wire reset_n,    // Active low reset

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
    input  wire         ddr_ready               // Indicates if DDR is ready for new operation

);
    
    // Define states using parameters
    localparam IDLE          = 3'b000;
    localparam READ_TAG      = 3'b001;
    localparam READWRITE_DATA = 3'b010;
    localparam WB_DDR        = 3'b011;
    localparam READ_DDR      = 3'b100;
    localparam REFILL        = 3'b101;

    // State register
    reg [2:0] state 
    reg [2:0] next_state;

    // State transition logic
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n)
            state <= IDLE; // Reset to IDLE state
        else
            state <= next_state;
    end

    // Next state logic
    always @(*) begin
        case (state)
            IDLE: begin
                if (opload_index_valid || opstore_index_valid)
                    next_state = READ_TAG;
                    raddr = ({64{opstore_index_valid}} & opstore_index)
                else
                    next_state = IDLE;
            end
            READ_TAG: begin
                // Add condition for transitioning to next state
                next_state = READWRITE_DATA;
            end
            READWRITE_DATA: begin
                // Add condition for transitioning to next state
                next_state = WB_DDR;
            end
            WB_DDR: begin
                // Add condition for transitioning to next state
                next_state = READ_DDR;
            end
            READ_DDR: begin
                // Add condition for transitioning to next state
                next_state = REFILL;
            end
            REFILL: begin
                // Add condition for transitioning to IDLE or another state
                next_state = IDLE;
            end
            default: next_state = IDLE;
        endcase
    end

dcache_tagarray u_dcache_tagarray(
    .clock   (clock   ),
    .reset_n (reset_n ),
    .we      (we      ),
    .ce      (ce      ),
    .waddr   (waddr   ),
    .raddr   (raddr   ),
    .din     (din     ),
    .wmask   (wmask   ),
    .dout    (dout    )
);

dcache_dataarray u_dcache_dataarray(
    .clock             (clock             ),
    .reset_n           (reset_n           ),
    .we_way0           (we_way0           ),
    .ce_way0           (ce_way0           ),
    .we_way1           (we_way1           ),
    .ce_way1           (ce_way1           ),
    .writewayaddr_way0 (writewayaddr_way0 ),
    .writewayaddr_way1 (writewayaddr_way1 ),
    .readwayaddr_way0  (readwayaddr_way0  ),
    .readwayaddr_way1  (readwayaddr_way1  ),
    .din_way0          (din_way0          ),
    .din_way1          (din_way1          ),
    .wmask_way0        (wmask_way0        ),
    .wmask_way1        (wmask_way1        ),
    .dout_way0         (dout_way0         ),
    .dout_way1         (dout_way1         )
);




endmodule


