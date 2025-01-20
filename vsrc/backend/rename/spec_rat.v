`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////
// Description:
//      Speculative Register Alias Table (Spec_RAT) with 6 read ports and 2 write ports.
//      Maps logical registers to physical registers for two instructions simultaneously.
//      Supports 64 physical registers.
//      Includes valid signals to indicate the necessity of each read port output.
//      Implements bypass logic to forward write data to read ports when necessary.
//      Write port signals have been renamed for clarity and consistency.
////////////////////////////////////////////////////////////////////////////////

module spec_rat (
    input wire clk,
    input wire reset,
    
    // Instruction 0 Control Signals
    input wire instr0_src1_is_reg,
    input wire instr0_src2_is_reg,
    input wire instr0_need_to_wb,
    
    // Instruction 1 Control Signals
    input wire instr1_src1_is_reg,
    input wire instr1_src2_is_reg,
    input wire instr1_need_to_wb,
    
    // Read Ports for Instruction 0
    input wire [4:0] instr0_lrs1,
    input wire [4:0] instr0_lrs2,
    input wire [4:0] instr0_lrd,
    
    // Read Ports for Instruction 1
    input wire [4:0] instr1_lrs1,
    input wire [4:0] instr1_lrs2,
    input wire [4:0] instr1_lrd,
    
    // Write Port 0 (Renamed)
    input wire rename2rat_instr0rd_pnum_wren,
    input wire [4:0] rename2rat_instr0rd_pnum_wraddr,
    input wire [5:0] rename2rat_instr0rd_pnum_wrdata,
    
    // Write Port 1 (Renamed)
    input wire rename2rat_instr1rd_pnum_wren,
    input wire [4:0] rename2rat_instr1rd_pnum_wraddr,
    input wire [5:0] rename2rat_instr1rd_pnum_wrdata,
    
    // Read Data Outputs for Instruction 0
    output wire [5:0] rat2rename_instr0_prs1,
    output wire        rat2rename_instr0_prs1_valid,
    output wire [5:0] rat2rename_instr0_prs2,
    output wire        rat2rename_instr0_prs2_valid,
    output wire [5:0] rat2rename_instr0_prd,
    output wire        rat2rename_instr0_prd_valid,
    
    // Read Data Outputs for Instruction 1
    output wire [5:0] rat2rename_instr1_prs1,
    output wire        rat2rename_instr1_prs1_valid,
    output wire [5:0] rat2rename_instr1_prs2,
    output wire        rat2rename_instr1_prs2_valid,
    output wire [5:0] rat2rename_instr1_prd,
    output wire        rat2rename_instr1_prd_valid
);

    // Parameters
    localparam LOGICAL_REG_WIDTH    = 5;
    localparam PHYSICAL_REG_WIDTH   = 6;
    localparam NUM_LOGICAL_REGS     = 32;
    localparam NUM_PHYSICAL_REGS    = 64;
    
    // Speculative RAT Register Array: Maps Logical Registers to Physical Registers
    reg [PHYSICAL_REG_WIDTH-1:0] spec_rat [0:NUM_LOGICAL_REGS-1];
    
    // Initialize Speculative RAT
    integer i;
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            for (i = 0; i < NUM_LOGICAL_REGS; i = i + 1) begin
                spec_rat[i] <= i; // Initial mapping: Logical Reg i maps to Physical Reg i
            end
        end
        else begin
            // Write Port 0
            if (rename2rat_instr0rd_pnum_wren) begin
                spec_rat[rename2rat_instr0rd_pnum_wraddr] <= rename2rat_instr0rd_pnum_wrdata;
            end
            // Write Port 1
            if (rename2rat_instr1rd_pnum_wren) begin
                spec_rat[rename2rat_instr1rd_pnum_wraddr] <= rename2rat_instr1rd_pnum_wrdata;
            end
        end
    end
    
    // Bypass Logic
    // For each read port, check if the read address matches any write address.
    // If a match is found and the write enable is active, bypass the write data.
    // Priority: Write Port 1 has higher priority than Write Port 0.
    
    // Instruction 0 Source 1 (prs1)
    wire [5:0] bypass_instr0_prs1;
    wire bypass_instr0_prs1_sel_wr1;
    wire bypass_instr0_prs1_sel_wr0;
    
    assign bypass_instr0_prs1_sel_wr1 = rename2rat_instr1rd_pnum_wren && 
                                        (instr0_lrs1 == rename2rat_instr1rd_pnum_wraddr);
                                        
    assign bypass_instr0_prs1_sel_wr0 = rename2rat_instr0rd_pnum_wren && 
                                        (instr0_lrs1 == rename2rat_instr0rd_pnum_wraddr) &&
                                        !bypass_instr0_prs1_sel_wr1;
    
    assign bypass_instr0_prs1 = bypass_instr0_prs1_sel_wr1 ? rename2rat_instr1rd_pnum_wrdata :
                                  (bypass_instr0_prs1_sel_wr0 ? rename2rat_instr0rd_pnum_wrdata :
                                  spec_rat[instr0_lrs1]);
    
    // Instruction 0 Source 2 (prs2)
    wire [5:0] bypass_instr0_prs2;
    wire bypass_instr0_prs2_sel_wr1;
    wire bypass_instr0_prs2_sel_wr0;
    
    assign bypass_instr0_prs2_sel_wr1 = rename2rat_instr1rd_pnum_wren && 
                                        (instr0_lrs2 == rename2rat_instr1rd_pnum_wraddr);
                                        
    assign bypass_instr0_prs2_sel_wr0 = rename2rat_instr0rd_pnum_wren && 
                                        (instr0_lrs2 == rename2rat_instr0rd_pnum_wraddr) &&
                                        !bypass_instr0_prs2_sel_wr1;
    
    assign bypass_instr0_prs2 = bypass_instr0_prs2_sel_wr1 ? rename2rat_instr1rd_pnum_wrdata :
                                  (bypass_instr0_prs2_sel_wr0 ? rename2rat_instr0rd_pnum_wrdata :
                                  spec_rat[instr0_lrs2]);
    
    // Instruction 0 Destination (prd)
    wire [5:0] bypass_instr0_prd;
    wire bypass_instr0_prd_sel_wr1;
    wire bypass_instr0_prd_sel_wr0;
    
    assign bypass_instr0_prd_sel_wr1 = rename2rat_instr1rd_pnum_wren && 
                                       (instr0_lrd == rename2rat_instr1rd_pnum_wraddr);
                                        
    assign bypass_instr0_prd_sel_wr0 = rename2rat_instr0rd_pnum_wren && 
                                       (instr0_lrd == rename2rat_instr0rd_pnum_wraddr) &&
                                       !bypass_instr0_prd_sel_wr1;
    
    assign bypass_instr0_prd = bypass_instr0_prd_sel_wr1 ? rename2rat_instr1rd_pnum_wrdata :
                                 (bypass_instr0_prd_sel_wr0 ? rename2rat_instr0rd_pnum_wrdata :
                                 spec_rat[instr0_lrd]);
    
    // Instruction 1 Source 1 (prs1)
    wire [5:0] bypass_instr1_prs1;
    wire bypass_instr1_prs1_sel_wr1;
    wire bypass_instr1_prs1_sel_wr0;
    
    assign bypass_instr1_prs1_sel_wr1 = rename2rat_instr1rd_pnum_wren && 
                                        (instr1_lrs1 == rename2rat_instr1rd_pnum_wraddr);
                                        
    assign bypass_instr1_prs1_sel_wr0 = rename2rat_instr0rd_pnum_wren && 
                                        (instr1_lrs1 == rename2rat_instr0rd_pnum_wraddr) &&
                                        !bypass_instr1_prs1_sel_wr1;
    
    assign bypass_instr1_prs1 = bypass_instr1_prs1_sel_wr1 ? rename2rat_instr1rd_pnum_wrdata :
                                  (bypass_instr1_prs1_sel_wr0 ? rename2rat_instr0rd_pnum_wrdata :
                                  spec_rat[instr1_lrs1]);
    
    // Instruction 1 Source 2 (prs2)
    wire [5:0] bypass_instr1_prs2;
    wire bypass_instr1_prs2_sel_wr1;
    wire bypass_instr1_prs2_sel_wr0;
    
    assign bypass_instr1_prs2_sel_wr1 = rename2rat_instr1rd_pnum_wren && 
                                        (instr1_lrs2 == rename2rat_instr1rd_pnum_wraddr);
                                        
    assign bypass_instr1_prs2_sel_wr0 = rename2rat_instr0rd_pnum_wren && 
                                        (instr1_lrs2 == rename2rat_instr0rd_pnum_wraddr) &&
                                        !bypass_instr1_prs2_sel_wr1;
    
    assign bypass_instr1_prs2 = bypass_instr1_prs2_sel_wr1 ? rename2rat_instr1rd_pnum_wrdata :
                                  (bypass_instr1_prs2_sel_wr0 ? rename2rat_instr0rd_pnum_wrdata :
                                  spec_rat[instr1_lrs2]);
    
    // Instruction 1 Destination (prd)
    wire [5:0] bypass_instr1_prd;
    wire bypass_instr1_prd_sel_wr1;
    wire bypass_instr1_prd_sel_wr0;
    
    assign bypass_instr1_prd_sel_wr1 = rename2rat_instr1rd_pnum_wren && 
                                       (instr1_lrd == rename2rat_instr1rd_pnum_wraddr);
                                        
    assign bypass_instr1_prd_sel_wr0 = rename2rat_instr0rd_pnum_wren && 
                                       (instr1_lrd == rename2rat_instr0rd_pnum_wraddr) &&
                                       !bypass_instr1_prd_sel_wr1;
    
    assign bypass_instr1_prd = bypass_instr1_prd_sel_wr1 ? rename2rat_instr1rd_pnum_wrdata :
                                 (bypass_instr1_prd_sel_wr0 ? rename2rat_instr0rd_pnum_wrdata :
                                 spec_rat[instr1_lrd]);
    
    // Read Ports - Combinational Outputs with Valid Signals and Bypass Logic
    // Instruction 0 Source 1
    assign rat2rename_instr0_prs1 = instr0_src1_is_reg ? bypass_instr0_prs1 : 6'd0;
    assign rat2rename_instr0_prs1_valid = instr0_src1_is_reg;
    
    // Instruction 0 Source 2
    assign rat2rename_instr0_prs2 = instr0_src2_is_reg ? bypass_instr0_prs2 : 6'd0;
    assign rat2rename_instr0_prs2_valid = instr0_src2_is_reg;
    
    // Instruction 0 Destination
    assign rat2rename_instr0_prd  = instr0_need_to_wb    ? bypass_instr0_prd  : 6'd0;
    assign rat2rename_instr0_prd_valid = instr0_need_to_wb;
    
    // Instruction 1 Source 1
    assign rat2rename_instr1_prs1 = instr1_src1_is_reg ? bypass_instr1_prs1 : 6'd0;
    assign rat2rename_instr1_prs1_valid = instr1_src1_is_reg;
    
    // Instruction 1 Source 2
    assign rat2rename_instr1_prs2 = instr1_src2_is_reg ? bypass_instr1_prs2 : 6'd0;
    assign rat2rename_instr1_prs2_valid = instr1_src2_is_reg;
    
    // Instruction 1 Destination
    assign rat2rename_instr1_prd  = instr1_need_to_wb    ? bypass_instr1_prd  : 6'd0;
    assign rat2rename_instr1_prd_valid = instr1_need_to_wb;

endmodule
