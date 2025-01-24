`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////
// Description: 
//
// A busy vector module with a 64-bit vector, supporting 4 read ports and 4 write ports.
// Read ports output the busy status based on provided addresses, incorporating bypass logic.
// Write ports can set or clear specific bits based on enable signals.

////////////////////////////////////////////////////////////////////////////////

module busy_vector (
    input wire clk,                         // Clock signal
    input wire reset_n,                     // Active-low reset signal

    // Read Port 0
    input wire [5:0] disp2bt_instr0rs1_rdaddr, // Address for disp2bt_instr0rs1_rddata
    output wire bt2disp_instr0rs1_busy,      // Data output for disp2bt_instr0rs1_rddata

    // Read Port 1
    input wire [5:0] disp2bt_instr0rs2_rdaddr, // Address for disp2bt_instr0rs2_rddata
    output wire bt2disp_instr0rs2_busy,      // Data output for disp2bt_instr0rs2_rddata

    // Read Port 2
    input wire [5:0] disp2bt_instr1rs1_rdaddr, // Address for disp2bt_instr1rs1_rddata
    output wire bt2disp_instr1rs1_busy,      // Data output for disp2bt_instr1rs1_rddata

    // Read Port 3
    input wire [5:0] disp2bt_instr1rs2_rdaddr, // Address for disp2bt_instr1rs2_rddata
    output wire bt2disp_instr1rs2_busy,      // Data output for disp2bt_instr1rs2_rddata

    // Write Port 0 - Allocate Instruction 0
    input wire alloc_instr0rd_en0,             // Enable for alloc_instr0rd_addr0
    input wire [5:0] alloc_instr0rd_addr0,     // Address for alloc_instr0rd_addr0

    // Write Port 1 - Allocate Instruction 1
    input wire alloc_instr1rd_en1,             // Enable for alloc_instr1rd_addr1
    input wire [5:0] alloc_instr1rd_addr1,     // Address for alloc_instr1rd_addr1

    // Write Port 2 - Free Instruction 0
    input wire free_instr0rd_en0,              // Enable for free_instr0rd_addr0
    input wire [5:0] free_instr0rd_addr0,      // Address for free_instr0rd_addr0

    // Write Port 3 - Free Instruction 1
    input wire free_instr1rd_en1,              // Enable for free_instr1rd_addr1
    input wire [5:0] free_instr1rd_addr1,       // Address for free_instr1rd_addr1

/* ------------------------------- walk logic ------------------------------- */
    input flush_valid,
    input [`INSTR_ID_WIDTH-1:0] flush_id,
    input wire is_idle,
    input wire is_rollingback,
    input wire is_walking,
    input wire walking_valid0,
    input wire walking_valid1,
    input wire [5:0] walking_prd0,
    input wire [5:0] walking_prd1,
    input wire walking_complete0,
    input wire walking_complete1

);

    // Internal 64-bit busy vector register
    reg [63:0] busy_vector;

    // Synchronous write operations with active-low reset
    always @(posedge clk) begin
        if (!reset_n | is_rollingback) begin
            busy_vector <= 64'b0;
        end else begin
            // Allocation Ports - Set Bit to 1
            if (alloc_instr0rd_en0)begin
                busy_vector[alloc_instr0rd_addr0] <= 1'b1;                
            end

            if (alloc_instr1rd_en1)begin
                busy_vector[alloc_instr1rd_addr1] <= 1'b1;                
            end

            // Free Ports - Set Bit to 0
            if (free_instr0rd_en0)begin
                busy_vector[free_instr0rd_addr0] <= 1'b0;                
            end

            if (free_instr1rd_en1)begin
                busy_vector[free_instr1rd_addr1] <= 1'b0;                
            end

            if (walking_valid0 && ~walking_complete0)begin
                busy_vector[walking_prd0] = 1'b1;
            end

            if (walking_valid1 && ~walking_complete1)begin
                busy_vector[walking_prd1] = 1'b1;
            end
            
        end
    end

    // Bypass Logic for Read Port 0
    wire bypass_instr0rs1;
    assign bypass_instr0rs1 = 
           (alloc_instr0rd_en0 && (alloc_instr0rd_addr0 == disp2bt_instr0rs1_rdaddr)) ? 1'b1 :
           (alloc_instr1rd_en1 && (alloc_instr1rd_addr1 == disp2bt_instr0rs1_rdaddr)) ? 1'b1 :
           (free_instr0rd_en0 && (free_instr0rd_addr0 == disp2bt_instr0rs1_rdaddr)) ? 1'b0 :
           (free_instr1rd_en1 && (free_instr1rd_addr1 == disp2bt_instr0rs1_rdaddr)) ? 1'b0 :
           busy_vector[disp2bt_instr0rs1_rdaddr];

    // Bypass Logic for Read Port 1
    wire bypass_instr0rs2;
    assign bypass_instr0rs2 = 
           (alloc_instr0rd_en0 && (alloc_instr0rd_addr0 == disp2bt_instr0rs2_rdaddr)) ? 1'b1 :
           (alloc_instr1rd_en1 && (alloc_instr1rd_addr1 == disp2bt_instr0rs2_rdaddr)) ? 1'b1 :
           (free_instr0rd_en0 && (free_instr0rd_addr0 == disp2bt_instr0rs2_rdaddr)) ? 1'b0 :
           (free_instr1rd_en1 && (free_instr1rd_addr1 == disp2bt_instr0rs2_rdaddr)) ? 1'b0 :
           busy_vector[disp2bt_instr0rs2_rdaddr];

    // Bypass Logic for Read Port 2
    wire bypass_instr1rs1;
    assign bypass_instr1rs1 = 
           (alloc_instr0rd_en0 && (alloc_instr0rd_addr0 == disp2bt_instr1rs1_rdaddr)) ? 1'b1 :
           (alloc_instr1rd_en1 && (alloc_instr1rd_addr1 == disp2bt_instr1rs1_rdaddr)) ? 1'b1 :
           (free_instr0rd_en0 && (free_instr0rd_addr0 == disp2bt_instr1rs1_rdaddr)) ? 1'b0 :
           (free_instr1rd_en1 && (free_instr1rd_addr1 == disp2bt_instr1rs1_rdaddr)) ? 1'b0 :
           busy_vector[disp2bt_instr1rs1_rdaddr];

    // Bypass Logic for Read Port 3
    wire bypass_instr1rs2;
    assign bypass_instr1rs2 = 
           (alloc_instr0rd_en0 && (alloc_instr0rd_addr0 == disp2bt_instr1rs2_rdaddr)) ? 1'b1 :
           (alloc_instr1rd_en1 && (alloc_instr1rd_addr1 == disp2bt_instr1rs2_rdaddr)) ? 1'b1 :
           (free_instr0rd_en0 && (free_instr0rd_addr0 == disp2bt_instr1rs2_rdaddr)) ? 1'b0 :
           (free_instr1rd_en1 && (free_instr1rd_addr1 == disp2bt_instr1rs2_rdaddr)) ? 1'b0 :
           busy_vector[disp2bt_instr1rs2_rdaddr];

    // Assigning read data with bypass logic
    assign bt2disp_instr0rs1_busy = bypass_instr0rs1;
    assign bt2disp_instr0rs2_busy = bypass_instr0rs2;
    assign bt2disp_instr1rs1_busy = bypass_instr1rs1;
    assign bt2disp_instr1rs2_busy = bypass_instr1rs2;

endmodule
