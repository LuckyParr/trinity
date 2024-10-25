module pc_ctrl (
    input wire clk,                          // Clock signal
    input wire rst_n,                        // Active-low reset signal
    input wire fetch_inst,                   // Fetch instruction signal, pulse signal for PC increment
    input wire pc_index_done,                // Signal indicating DDR operation is complete
    input wire interrupt_valid,              // Interrupt valid signal
    input wire [47:0] interrupt_addr,        // 48-bit interrupt address
    input wire [47:0] boot_addr,             // 48-bit boot address

    output reg [18:0] pc_index,              // Selected bits [21:3] of the PC for DDR index
    output reg pc_index_valid,               // Valid signal for PC index
    output reg can_fetch_inst                // Indicates if a new instruction can be fetched
);

    reg [47:0] pc;                           // 48-bit Program Counter

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset PC to boot address, and clear other signals on negative edge of rst_n
            pc <= boot_addr;
            pc_index_valid <= 1'b0;
            pc_index <= 19'b0;
            can_fetch_inst <= 1'b0;
        end else begin
            // Output the selected bits [21:3] of the current PC as pc_index
            pc_index <= pc[21:3];

            // Handle interrupt logic
            if (interrupt_valid) begin
                pc <= interrupt_addr;       // Set PC to interrupt address if interrupt_valid is high
                pc_index_valid <= 1'b1;     // Set pc_index_valid to indicate new index is ready
                can_fetch_inst <= 1'b0;     // Clear can_fetch_inst during interrupt processing
            end else if (fetch_inst) begin
                // Normal PC increment on fetch_inst pulse
                pc <= pc + 64;              // Increment PC by 64
                pc_index_valid <= 1'b1;     // Set pc_index_valid to indicate new index is ready
                can_fetch_inst <= 1'b0;     // Clear can_fetch_inst when fetch_inst is asserted
            end

            // Set can_fetch_inst when pc_index_done indicates operation completion
            if (pc_index_done) begin
                pc_index_valid <= 1'b0;     // Clear pc_index_valid on completion
                can_fetch_inst <= 1'b1;     // Set can_fetch_inst to allow new fetch
            end
        end
    end

endmodule
