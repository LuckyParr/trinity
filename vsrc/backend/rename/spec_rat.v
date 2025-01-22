`timescale 1ns / 1ps
module spec_rat (
    input wire clk,
    input wire reset,
    // Write Port 0 
    input wire rn2specrat_instr0_lrd_wren,
    input wire [4:0] rn2specrat_instr0_lrd_wraddr,
    input wire [5:0] rn2specrat_instr0_lrd_wrdata,
    
    // Write Port 1 
    input wire rn2specrat_instr1_lrd_wren,
    input wire [4:0] rn2specrat_instr1_lrd_wraddr,
    input wire [5:0] rn2specrat_instr1_lrd_wrdata,

    // Read Ports for Instruction     
    input wire rn2specrat_instr0_lrs1_valid,
    input wire rn2specrat_instr0_lrs2_valid,
    input wire rn2specrat_instr1_lrd_valid,
    input wire rn2specrat_instr1_lrs1_valid,
    input wire rn2specrat_instr1_lrs2_valid,
    input wire rn2specrat_instr0_lrd_valid,
    input wire [4:0] rn2specrat_instr0_lrs1,
    input wire [4:0] rn2specrat_instr0_lrs2,
    input wire [4:0] rn2specrat_instr0_lrd,
    input wire [4:0] rn2specrat_instr1_lrs1,
    input wire [4:0] rn2specrat_instr1_lrs2,
    input wire [4:0] rn2specrat_instr1_lrd,
    
    // Read Data Outputs for Instruction
    output wire [5:0] specrat2rn_instr0prs1,
    output wire [5:0] specrat2rn_instr0prs2,
    output wire [5:0] specrat2rn_instr0prd,    
    output wire [5:0] specrat2rn_instr1prs1,
    output wire [5:0] specrat2rn_instr1prs2,
    output wire [5:0] specrat2rn_instr1prd,
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
            if (rn2specrat_instr0_lrd_wren) begin
                spec_rat[rn2specrat_instr0_lrd_wraddr] <= rn2specrat_instr0_lrd_wrdata;
            end
            // Write Port 1
            if (rn2specrat_instr1_lrd_wren) begin
                spec_rat[rn2specrat_instr1_lrd_wraddr] <= rn2specrat_instr1_lrd_wrdata;
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
    
    assign bypass_instr0_prs1_sel_wr1 = rn2specrat_instr1_lrd_wren && 
                                        (rn2specrat_instr0_lrs1 == rn2specrat_instr1_lrd_wraddr);
                                        
    assign bypass_instr0_prs1_sel_wr0 = rn2specrat_instr0_lrd_wren && 
                                        (rn2specrat_instr0_lrs1 == rn2specrat_instr0_lrd_wraddr) &&
                                        !bypass_instr0_prs1_sel_wr1;
    
    assign bypass_instr0_prs1 = bypass_instr0_prs1_sel_wr1 ? rn2specrat_instr1_lrd_wrdata :
                                  (bypass_instr0_prs1_sel_wr0 ? rn2specrat_instr0_lrd_wrdata :
                                  spec_rat[rn2specrat_instr0_lrs1]);
    
    // Instruction 0 Source 2 (prs2)
    wire [5:0] bypass_instr0_prs2;
    wire bypass_instr0_prs2_sel_wr1;
    wire bypass_instr0_prs2_sel_wr0;
    
    assign bypass_instr0_prs2_sel_wr1 = rn2specrat_instr1_lrd_wren && 
                                        (rn2specrat_instr0_lrs2 == rn2specrat_instr1_lrd_wraddr);
                                        
    assign bypass_instr0_prs2_sel_wr0 = rn2specrat_instr0_lrd_wren && 
                                        (rn2specrat_instr0_lrs2 == rn2specrat_instr0_lrd_wraddr) &&
                                        !bypass_instr0_prs2_sel_wr1;
    
    assign bypass_instr0_prs2 = bypass_instr0_prs2_sel_wr1 ? rn2specrat_instr1_lrd_wrdata :
                                  (bypass_instr0_prs2_sel_wr0 ? rn2specrat_instr0_lrd_wrdata :
                                  spec_rat[rn2specrat_instr0_lrs2]);
    
    // Instruction 0 Destination (prd)
    wire [5:0] bypass_instr0_prd;
    wire bypass_instr0_prd_sel_wr1;
    wire bypass_instr0_prd_sel_wr0;
    
    assign bypass_instr0_prd_sel_wr1 = rn2specrat_instr1_lrd_wren && 
                                       (rn2specrat_instr0_lrd == rn2specrat_instr1_lrd_wraddr);
                                        
    assign bypass_instr0_prd_sel_wr0 = rn2specrat_instr0_lrd_wren && 
                                       (rn2specrat_instr0_lrd == rn2specrat_instr0_lrd_wraddr) &&
                                       !bypass_instr0_prd_sel_wr1;
    
    assign bypass_instr0_prd = bypass_instr0_prd_sel_wr1 ? rn2specrat_instr1_lrd_wrdata :
                                 (bypass_instr0_prd_sel_wr0 ? rn2specrat_instr0_lrd_wrdata :
                                 spec_rat[rn2specrat_instr0_lrd]);
    
    // Instruction 1 Source 1 (prs1)
    wire [5:0] bypass_instr1_prs1;
    wire bypass_instr1_prs1_sel_wr1;
    wire bypass_instr1_prs1_sel_wr0;
    
    assign bypass_instr1_prs1_sel_wr1 = rn2specrat_instr1_lrd_wren && 
                                        (rn2specrat_instr1_lrs1 == rn2specrat_instr1_lrd_wraddr);
                                        
    assign bypass_instr1_prs1_sel_wr0 = rn2specrat_instr0_lrd_wren && 
                                        (rn2specrat_instr1_lrs1 == rn2specrat_instr0_lrd_wraddr) &&
                                        !bypass_instr1_prs1_sel_wr1;
    
    assign bypass_instr1_prs1 = bypass_instr1_prs1_sel_wr1 ? rn2specrat_instr1_lrd_wrdata :
                                  (bypass_instr1_prs1_sel_wr0 ? rn2specrat_instr0_lrd_wrdata :
                                  spec_rat[rn2specrat_instr1_lrs1]);
    
    // Instruction 1 Source 2 (prs2)
    wire [5:0] bypass_instr1_prs2;
    wire bypass_instr1_prs2_sel_wr1;
    wire bypass_instr1_prs2_sel_wr0;
    
    assign bypass_instr1_prs2_sel_wr1 = rn2specrat_instr1_lrd_wren && 
                                        (rn2specrat_instr1_lrs2 == rn2specrat_instr1_lrd_wraddr);
                                        
    assign bypass_instr1_prs2_sel_wr0 = rn2specrat_instr0_lrd_wren && 
                                        (rn2specrat_instr1_lrs2 == rn2specrat_instr0_lrd_wraddr) &&
                                        !bypass_instr1_prs2_sel_wr1;
    
    assign bypass_instr1_prs2 = bypass_instr1_prs2_sel_wr1 ? rn2specrat_instr1_lrd_wrdata :
                                  (bypass_instr1_prs2_sel_wr0 ? rn2specrat_instr0_lrd_wrdata :
                                  spec_rat[rn2specrat_instr1_lrs2]);
    
    // Instruction 1 Destination (prd)
    wire [5:0] bypass_instr1_prd;
    wire bypass_instr1_prd_sel_wr1;
    wire bypass_instr1_prd_sel_wr0;
    
    assign bypass_instr1_prd_sel_wr1 = rn2specrat_instr1_lrd_wren && 
                                       (rn2specrat_instr1_lrd == rn2specrat_instr1_lrd_wraddr);
                                        
    assign bypass_instr1_prd_sel_wr0 = rn2specrat_instr0_lrd_wren && 
                                       (rn2specrat_instr1_lrd == rn2specrat_instr0_lrd_wraddr) &&
                                       !bypass_instr1_prd_sel_wr1;
    
    assign bypass_instr1_prd = bypass_instr1_prd_sel_wr1 ? rn2specrat_instr1_lrd_wrdata :
                                 (bypass_instr1_prd_sel_wr0 ? rn2specrat_instr0_lrd_wrdata :
                                 spec_rat[rn2specrat_instr1_lrd]);
    
    // Read Result
    assign specrat2rn_instr0prs1 = rn2specrat_instr0_lrs1_valid   ? bypass_instr0_prs1 : 6'd0;
    assign specrat2rn_instr0prs2 = rn2specrat_instr0_lrs2_valid   ? bypass_instr0_prs2 : 6'd0;
    assign specrat2rn_instr0prd  = rn2specrat_instr1_lrd_valid    ? bypass_instr0_prd  : 6'd0;
    assign specrat2rn_instr1prs1 = rn2specrat_instr1_lrs1_valid   ? bypass_instr1_prs1 : 6'd0;
    assign specrat2rn_instr1prs2 = rn2specrat_instr1_lrs2_valid   ? bypass_instr1_prs2 : 6'd0;
    assign specrat2rn_instr1prd  = rn2specrat_instr0_lrd_valid    ? bypass_instr1_prd  : 6'd0;

endmodule
