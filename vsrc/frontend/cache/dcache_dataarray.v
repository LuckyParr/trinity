
// 2-Way, 8-Bank Cache Module
module dcache_dataarray 
#(parameter DATA_WIDTH = 64,  // Width of data
  parameter ADDR_WIDTH = 9   // Width of address bus
) (
    input wire clock,                                  // Clock signal
    input wire reset_n,                              // Active low reset
    input wire [7:0] we_way0, 
    input wire [7:0] ce_way0,                        // Write enables for each bank in way 0
    input wire [7:0] we_way1, 
    input wire [7:0] ce_way1,                        // Write enables for each bank in way 1
    input wire [ADDR_WIDTH-1:0] writewayaddr_way0 ,    // Write addresses for each bank in way 0
    input wire [ADDR_WIDTH-1:0] writewayaddr_way1 ,    // Write addresses for each bank in way 1
    input wire [ADDR_WIDTH-1:0] readwayaddr_way0 ,    // Read addresses for each bank in way 0
    input wire [ADDR_WIDTH-1:0] readwayaddr_way1 ,    // Read addresses for each bank in way 1
    input wire [DATA_WIDTH-1:0] din_way0 [7:0],      // Data inputs for each bank in way 0
    input wire [DATA_WIDTH-1:0] din_way1 [7:0],      // Data inputs for each bank in way 1
    input wire [DATA_WIDTH-1:0] wmask_way0 [7:0],    // Write masks for each bank in way 0
    input wire [DATA_WIDTH-1:0] wmask_way1 [7:0],    // Write masks for each bank in way 1
    output wire [DATA_WIDTH-1:0] dout_way0 [7:0],    // Data outputs for each bank in way 0
    output wire [DATA_WIDTH-1:0] dout_way1 [7:0]     // Data outputs for each bank in way 1
);

    // Instantiate 8 SRAM banks for each way
    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : Way0_8Bank
            sram #(
                .DATA_WIDTH(DATA_WIDTH),
                .ADDR_WIDTH(ADDR_WIDTH)
            ) sram_inst_way0 (
                .clock(clock),
                .reset_n(reset_n),
                .we(we_way0[i]),
                .waddr(writewayaddr_way0),
                .raddr(readwayaddr_way0),
                .din(din_way0[i]),
                .wmask(wmask_way0[i]),
                .dout(dout_way0[i])
            );
        end

        for (i = 0; i < 8; i = i + 1) begin : Way1_8Bank
            sram #(
                .DATA_WIDTH(DATA_WIDTH),
                .ADDR_WIDTH(ADDR_WIDTH)
            ) sram_inst_way1 (
                .clock(clock),
                .reset_n(reset_n),
                .we(we_way1[i]),
                .waddr(writewayaddr_way1),
                .raddr(readwayaddr_way1),
                .din(din_way1[i]),
                .wmask(wmask_way1[i]),
                .dout(dout_way1[i])
            );
        end
    endgenerate

endmodule