module regfile64 (
    input wire clk,
    input wire rst_n,
    input wire [4:0] rs1,               // Read register 1 address
    input wire [4:0] rs2,               // Read register 2 address
    input wire [4:0] rd,                // Write register address
    input wire [63:0] rd_data,          // Data to be written to rd
    input wire reg_write,               // Write enable signal for rd
    output reg [63:0] rs1_data,         // Data from rs1 register
    output reg [63:0] rs2_data          // Data from rs2 register
);

    reg [63:0] registers [31:0];        // 32 registers, 64 bits each

    // Reset all registers to 0 (optional)
    integer i;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < 32; i = i + 1) begin
                registers[i] <= 64'b0;
            end
        end else if (reg_write && rd != 5'b0) begin
            // Write to rd only if rd is not zero (x0 is always 0 in RISC-V)
            registers[rd] <= rd_data;
        end
    end

    // Combinational read logic
    always @(*) begin
        rs1_data = registers[rs1];
        rs2_data = registers[rs2];
    end
endmodule
