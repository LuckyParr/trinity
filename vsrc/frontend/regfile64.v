module regfile64 (
    input wire clock,
    input wire reset_n,
    input wire [4:0] rs1,               // Read register 1 address
    input wire [4:0] rs2,               // Read register 2 address
    input wire [4:0] rd,                // Write register address
    input wire [63:0] rd_data,          // Data to be written to rd
    input wire reg_write,               // Write enable signal for rd
    output reg [63:0] rs1_regdata,      // Data from rs1 register
    output reg [63:0] rs2_regdata       // Data from rs2 register
);

    reg [63:0] registers [31:0];        // 32 registers, 64 bits each

    // Reset all registers to 0 (optional)
    integer i;
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            for (i = 0; i < 32; i = i + 1) begin
                registers[i] <= 64'b0;
            end
        end else if (reg_write && rd != 5'b0) begin
            // Write to rd only if rd is not zero (x0 is always 0 in RISC-V)
            registers[rd] <= rd_data;
        end
    end

    // Combinational read logic with forwarding
    always @(*) begin
        // Forward rd_data if reg_write is active and addresses match
        if (reg_write && rd == rs1 && rd != 5'b0) begin
            rs1_regdata = rd_data;
        end else begin
            rs1_regdata = registers[rs1];
        end

        if (reg_write && rd == rs2 && rd != 5'b0) begin
            rs2_regdata = rd_data;
        end else begin
            rs2_regdata = registers[rs2];
        end
    end
endmodule
