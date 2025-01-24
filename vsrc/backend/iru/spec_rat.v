`timescale 1ns / 1ps
module spec_rat #(
    parameter DATA_WIDTH = 124;
)
(
    input wire clock,
    input wire reset_n,
    // Write Port 0 
    input wire rn2specrat_instr0_lrd_wren,
    input wire [4:0] rn2specrat_instr0_lrd_wraddr,
    input wire [5:0] rn2specrat_instr0_lrd_wrdata,
    
    // Write Port 1 
    input wire rn2specrat_instr1_lrd_wren,
    input wire [4:0] rn2specrat_instr1_lrd_wraddr,
    input wire [5:0] rn2specrat_instr1_lrd_wrdata,

    // Read Ports for Instruction     
    input wire rn2specrat_instr0_lrs1_rden,
    input wire rn2specrat_instr0_lrs2_rden,
    input wire rn2specrat_instr0_lrd_rden,
    input wire rn2specrat_instr1_lrs1_rden,
    input wire rn2specrat_instr1_lrs2_rden,
    input wire rn2specrat_instr1_lrd_rden,
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

/* ------------------------------- commit port ------------------------------ */
    input wire                  commit0_valid     ,
    input wire                  commit0_need_to_wb,
    input wire [4:0]            commit0_lrd       ,
    input wire [5:0]            commit0_prd       ,
    input wire                  commit1_valid     ,
    input wire                  commit1_need_to_wb,
    input wire [4:0]            commit1_lrd       ,
    input wire [5:0]            commit1_prd       ,

/* ------------------------------- walk_logic ------------------------------- */
    input wire is_idle,
    input wire is_rollingback,
    input wire is_walking,
    input wire walking_valid0,
    input wire walking_valid1,
    input wire [5:0] walking_prd0,
    input wire [5:0] walking_prd1,
    input wire [4:0] walking_lrd0,
    input wire [4:0] walking_lrd1

);

    //hit situation
    wire rename_lrd_hit;
    wire walk_lrd_hit;
    assign rename_lrd_hit = rn2specrat_instr0_lrd_wren && rn2specrat_instr1_lrd_wren && (rn2specrat_instr0_lrd_wraddr == rn2specrat_instr1_lrd_wraddr);
    assign walk_lrd_hit = walking_valid0 && walking_valid1 && (walking_lrd0 == walking_lrd1);

    // Parameters
    localparam LOGICAL_REG_WIDTH    = 5;
    localparam PHYSICAL_REG_WIDTH   = 6;
    localparam NUM_LOGICAL_REGS     = 32;
    localparam NUM_PHYSICAL_REGS    = 64;
    
    // Speculative RAT Register Array: Maps Logical Registers to Physical Registers
    reg [PHYSICAL_REG_WIDTH-1:0] spec_rat [0:NUM_LOGICAL_REGS-1];  // [5:0] reg [31:0]
    
    // Initialize Speculative RAT
    integer i;
    always @(posedge clock or negedge reset_n) begin
        if (~reset_n) begin
            for (i = 0; i < NUM_LOGICAL_REGS; i = i + 1) begin
                spec_rat[i] <= i; // Initial mapping: Logical Reg i maps to Physical Reg i
            end
        end
        else begin
            if(is_rollingback)begin
                    spec_rat <= arch_rat_content;
            end else if (is_walking)begin
                if(walking_valid0 && ~walk_lrd_hit)begin
                    spec_rat[walking_lrd0] <= walking_prd0;//prd is new physical reg number fetched from freelist, use it to upate arch_rat 
                end
                if(walking_valid1)begin
                    spec_rat[walking_lrd1] <= walking_prd1;
                end
            end else begin // (is_idle)
            // Write Port 0
            if (rn2specrat_instr0_lrd_wren && ~rename_lrd_hit) begin
                spec_rat[rn2specrat_instr0_lrd_wraddr] <= rn2specrat_instr0_lrd_wrdata;
            end
            // Write Port 1
            if (rn2specrat_instr1_lrd_wren) begin
                spec_rat[rn2specrat_instr1_lrd_wraddr] <= rn2specrat_instr1_lrd_wrdata;
            end
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
    assign specrat2rn_instr0prs1 = rn2specrat_instr0_lrs1_rden   ? bypass_instr0_prs1 : 6'd0;
    assign specrat2rn_instr0prs2 = rn2specrat_instr0_lrs2_rden   ? bypass_instr0_prs2 : 6'd0;
    assign specrat2rn_instr0prd  = rn2specrat_instr1_lrd_rden    ? bypass_instr0_prd  : 6'd0;
    assign specrat2rn_instr1prs1 = rn2specrat_instr1_lrs1_rden   ? bypass_instr1_prs1 : 6'd0;
    assign specrat2rn_instr1prs2 = rn2specrat_instr1_lrs2_rden   ? bypass_instr1_prs2 : 6'd0;
    assign specrat2rn_instr1prd  = rn2specrat_instr0_lrd_rden    ? bypass_instr1_prd  : 6'd0;

/* ------------------------------ commit logic ------------------------------ */
//decode meterial
//   disp2rob_wrdata0 =   
//   { 
//   instr0_pc           ,//[123:60]
//   instr0              ,//[59:28]
//   instr0_lrs1         ,//[27:23]
//   instr0_lrs2         ,//[22:18]
//   instr0_lrd          ,//[17:13]
//   instr0_prd          ,//[12:7]
//   instr0_old_prd      ,//[6:1]
//   instr0_need_to_wb    //[0]
//   };


arch_rat u_arch_rat(
    .clock              (clock              ),
    .reset_n            (reset_n            ),
    .commit0_valid      (rob2specrat_commit0_valid     ),
    .commit0_need_to_wb (rob2specrat_commit0_need_to_wb),
    .commit0_lrd        (rob2specrat_commit0_lrd       ),
    .commit0_prd        (rob2specrat_commit0_prd       ),
    .commit1_valid      (),
    .commit1_need_to_wb (),
    .commit1_lrd        (),
    .commit1_prd        (),
    .debug_preg0        (debug_preg0        ),
    .debug_preg1        (debug_preg1        ),
    .debug_preg2        (debug_preg2        ),
    .debug_preg3        (debug_preg3        ),
    .debug_preg4        (debug_preg4        ),
    .debug_preg5        (debug_preg5        ),
    .debug_preg6        (debug_preg6        ),
    .debug_preg7        (debug_preg7        ),
    .debug_preg8        (debug_preg8        ),
    .debug_preg9        (debug_preg9        ),
    .debug_preg10       (debug_preg10       ),
    .debug_preg11       (debug_preg11       ),
    .debug_preg12       (debug_preg12       ),
    .debug_preg13       (debug_preg13       ),
    .debug_preg14       (debug_preg14       ),
    .debug_preg15       (debug_preg15       ),
    .debug_preg16       (debug_preg16       ),
    .debug_preg17       (debug_preg17       ),
    .debug_preg18       (debug_preg18       ),
    .debug_preg19       (debug_preg19       ),
    .debug_preg20       (debug_preg20       ),
    .debug_preg21       (debug_preg21       ),
    .debug_preg22       (debug_preg22       ),
    .debug_preg23       (debug_preg23       ),
    .debug_preg24       (debug_preg24       ),
    .debug_preg25       (debug_preg25       ),
    .debug_preg26       (debug_preg26       ),
    .debug_preg27       (debug_preg27       ),
    .debug_preg28       (debug_preg28       ),
    .debug_preg29       (debug_preg29       ),
    .debug_preg30       (debug_preg30       ),
    .debug_preg31       (debug_preg31       )
);


    wire [`PREG_RANGE] arch_rat_content[31:0];
    assign arch_rat_content = {
        debug_preg31,
        debug_preg30,
        debug_preg29,
        debug_preg28,
        debug_preg27,
        debug_preg26,
        debug_preg25,
        debug_preg24,
        debug_preg23,
        debug_preg22,
        debug_preg21,
        debug_preg20,
        debug_preg19,
        debug_preg18,
        debug_preg17,
        debug_preg16,
        debug_preg15,
        debug_preg14,
        debug_preg13,
        debug_preg12,
        debug_preg11,
        debug_preg10,
        debug_preg9,
        debug_preg8,
        debug_preg7,
        debug_preg6,
        debug_preg5,
        debug_preg4,
        debug_preg3,
        debug_preg2,
        debug_preg1,
        debug_preg0
    };



endmodule
