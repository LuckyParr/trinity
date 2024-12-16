
// 2-Way, 8-Bank Cache Module
module dcache_dataarray 
#(parameter DATA_WIDTH = 64,  // Width of data
  parameter ADDR_WIDTH = 9   // Width of address bus
) (
    input wire clock,                                  // Clock signal
    input wire reset_n,                              // Active low reset
    input wire [1:0] ce_way,                               //Way enable,to select Way
    input wire  we, 
    input wire [7:0] ce_bank,                        // Write enables for each bank in way 0
    input wire [ADDR_WIDTH-1:0] writesetaddr ,    // Write addresses for each bank in way 0
    input wire [ADDR_WIDTH-1:0] readsetaddr ,    // Read addresses for each bank in way 1
    input wire [DATA_WIDTH-1:0] din_bank [7:0],      // Data inputs for each bank in bank 0
    input wire [DATA_WIDTH-1:0] wmask_bank [7:0],    // Write masks for each bank in bank 0
    output wire [DATA_WIDTH-1:0] dout_bank [7:0]    // Data outputs for each bank in bank 0
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
                .ce(ce_bank[i] & ce_way[0]),
                .we(we),
                .waddr(writesetaddr),
                .raddr(readsetaddr),
                .din(din_bank[i]),
                .wmask(wmask_bank[i]),
                .dout(dout_bank[i])
            );
        end

        for (i = 0; i < 8; i = i + 1) begin : Way1_8Bank
            sram #(
                .DATA_WIDTH(DATA_WIDTH),
                .ADDR_WIDTH(ADDR_WIDTH)
            ) sram_inst_way1 (
                .clock(clock),
                .reset_n(reset_n),
                .ce(ce_bank[i] & ce_way[1]),
                .we(we),
                .waddr(writesetaddr),
                .raddr(readsetaddr),
                .din(din_bank[i]),
                .wmask(wmask_bank[i]),
                .dout(dout_bank[i])
            );
        end
    endgenerate

endmodule