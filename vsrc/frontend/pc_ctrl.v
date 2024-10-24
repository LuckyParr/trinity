module pc_ctrl (
    input wire clk,                          // Clock signal
    input wire reset,                        // Reset signal
    input wire access_busy,                  // Access busy signal, prevents PC from incrementing when high
    input wire fetch_inst,                   // Fetch instruction signal, PC increments by 8 when high and access_busy is 0
    input wire [47:0] interrupt_addr,        // 48-bit interrupt address
    input wire interrupt_valid,              // 1-bit interrupt valid signal
    output reg [18:0] pc_out                 // Lower 19 bits of the PC
);

    reg [44:0] pc;                           // 45-bit Program Counter
    reg [47:0] boot_addr;                    // Internal 48-bit boot address, default 0

    // Initialize boot_addr to 0 (can be set to other values later if needed)
    initial begin
        boot_addr = 48'b0;                   // Default boot address is 0
    end

    // Select the appropriate address based on interrupt_valid
    wire [47:0] addr_select = interrupt_valid ? interrupt_addr : boot_addr;

    // PC update logic
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            pc <= 45'b0;                     // Reset PC to 0 on reset
        end else if (interrupt_valid) begin
            pc <= interrupt_addr[47:3];      // Set PC to interrupt address if interrupt_valid is 1
        end else if (!access_busy && fetch_inst) begin
            pc <= pc + 8;                    // Increment PC by 8 when !access_busy and fetch_inst are both true
        end
        // If access_busy is 1 or fetch_inst is 0, the PC stays the same
    end

    // Output the lower 19 bits of the PC as pc_out
    always @(pc) begin
        pc_out = pc[18:0];
    end

endmodule
