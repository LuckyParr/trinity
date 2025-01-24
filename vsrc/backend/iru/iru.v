`timescale 1ns / 1ps

module iru
#()
(
    input wire               clock,
    input wire               reset_n,
    //
    input wire                       instr0_ready                             ,                   
    input wire [ 31:0             ]  instr0                                   ,                         
    input wire [ 4 :0             ]  instr0_lrs1                              ,                    
    input wire [ 4 :0             ]  instr0_lrs2                              ,                    
    input wire [ 4 :0             ]  instr0_lrd                               ,                     
    input wire [ 63:0             ]  instr0_pc                                ,                      
    input wire [ 63:0             ]  instr0_imm                               ,                     
    input wire                       instr0_src1_is_reg                       ,             
    input wire                       instr0_src2_is_reg                       ,             
    input wire                       instr0_need_to_wb                        ,              
    input wire [    `CX_TYPE_RANGE]  instr0_cx_type                           ,                 
    input wire                       instr0_is_unsigned                       ,             
    input wire [   `ALU_TYPE_RANGE]  instr0_alu_type                          ,                
    input wire [`MULDIV_TYPE_RANGE]  instr0_muldiv_type                       ,             
    input wire                       instr0_is_word                           ,                 
    input wire                       instr0_is_imm                            ,                  
    input wire                       instr0_is_load                           ,                 
    input wire                       instr0_is_store                          ,                
    input wire [ 3:0              ]  instr0_ls_size                           ,                 

    // Inputs from ROB to Speculative RAT
    input wire               rob2specrat_commit1_valid,
    input wire               rob2specrat_commit1_need_to_wb,
    input wire [`LREG_RANGE-1:0] rob2specrat_commit1_lrd,
    input wire [`PREG_RANGE-1:0] rob2specrat_commit1_prd,

    // Inputs from ROB to Free List
    input wire [`PREG_RANGE-1:0] rob2fl_commit_old_prd,
    input wire               rob2fl_commit_valid0,

    // Additional control signals
    input wire               flush_valid,
    input wire               is_idle,
    input wire               is_rollingback,
    input wire               is_walking,
    input wire               walking_valid0,
    input wire               walking_valid1,
    input wire [`PREG_RANGE-1:0] walking_old_prd0,
    input wire [`PREG_RANGE-1:0] walking_old_prd1,
    input wire               commit0_valid,
    input wire               commit0_need_to_wb,
    input wire [`LREG_RANGE-1:0] commit0_lrd,
    input wire [`PREG_RANGE-1:0] commit0_prd
);


     wire                  rn2fl_instr0_lrd_valid,
     wire [`PREG_RANGE-1:0] fl2rn_instr0prd,

     wire                  rn2specrat_instr0_lrs1_rden,
     wire                  rn2specrat_instr0_lrs2_rden,
     wire                  rn2specrat_instr0_lrd_rden,
     wire [`LREG_RANGE-1:0] rn2specrat_instr0_lrs1,
     wire [`LREG_RANGE-1:0] rn2specrat_instr0_lrs2,
     wire [`LREG_RANGE-1:0] rn2specrat_instr0_lrd,

     wire [`PREG_RANGE-1:0] specrat2rn_instr0prs1,
     wire [`PREG_RANGE-1:0] specrat2rn_instr0prs2,
     wire [`PREG_RANGE-1:0] specrat2rn_instr0prd,

// Instantiate the Free List
freelist u_freelist(
    .clock            (clock),
    .reset_n          (reset_n),
    .wr_en0           (rob2fl_commit_valid0),
    .wr_data0         (rob2fl_commit_old_prd),
    .wr_en1           (1'b0),
    .wr_data1         ('b0),
    .rd_en0           (rn2fl_instr0_lrd_valid),
    .rd_data0         (fl2rn_instr0prd),
    .rd_en1           (1'b0),
    .rd_data1         (),
    .is_idle          (is_idle),
    .is_rollingback   (is_rollingback),
    .is_walking       (is_walking),
    .walking_valid0   (walking_valid0),
    .walking_valid1   (walking_valid1),
    .walking_old_prd0 (walking_old_prd0),
    .walking_old_prd1 (walking_old_prd1)
);

// Instantiate the Rename Unit
rename u_rename(
    .instr0_valid                    (1'b0),
    .instr0_ready                    (),
    .instr0                          (),
    .instr0_lrs1                     (),
    .instr0_lrs2                     (),
    .instr0_lrd                      (),
    .instr0_pc                       (),
    .instr0_imm                      (),
    .instr0_src1_is_reg              (),
    .instr0_src2_is_reg              (),
    .instr0_need_to_wb               (),
    .instr0_cx_type                  (),
    .instr0_is_unsigned              (),
    .instr0_alu_type                 (),
    .instr0_muldiv_type              (),
    .instr0_is_word                  (),
    .instr0_is_imm                   (),
    .instr0_is_load                  (),
    .instr0_is_store                 (),
    .instr0_ls_size                  (),
    .instr1_valid                    (1'b0),
    .flush_valid                     (flush_valid),
    .rn2fl_instr0_lrd_valid          (rn2fl_instr0_lrd_valid),
    .fl2rn_instr0prd                 (fl2rn_instr0prd),
    .rn2specrat_instr0_lrs1_rden     (rn2specrat_instr0_lrs1_rden),
    .rn2specrat_instr0_lrs2_rden     (rn2specrat_instr0_lrs2_rden),
    .rn2specrat_instr0_lrd_rden      (rn2specrat_instr0_lrd_rden),
    .rn2specrat_instr0_lrs1          (rn2specrat_instr0_lrs1),
    .rn2specrat_instr0_lrs2          (rn2specrat_instr0_lrs2),
    .rn2specrat_instr0_lrd           (rn2specrat_instr0_lrd),
    .specrat2rn_instr0prs1           (specrat2rn_instr0prs1),
    .specrat2rn_instr0prs2           (specrat2rn_instr0prs2),
    .specrat2rn_instr0prd            (specrat2rn_instr0prd)
);

// Instantiate the Speculative Register Alias Table
spec_rat u_spec_rat(
    .clock                        (clock),
    .reset_n                      (reset_n),
    .rn2specrat_instr0_lrd_wren   (rn2specrat_instr0_lrd_rden),
    .rn2specrat_instr0_lrd_wraddr (rn2specrat_instr0_lrd),
    .rn2specrat_instr0_lrd_wrdata (specrat2rn_instr0prd),
    .rn2specrat_instr0_lrs1_rden  (rn2specrat_instr0_lrs1_rden),
    .rn2specrat_instr0_lrs2_rden  (rn2specrat_instr0_lrs2_rden),
    .rn2specrat_instr0_lrs1       (rn2specrat_instr0_lrs1),
    .rn2specrat_instr0_lrs2       (rn2specrat_instr0_lrs2),
    .rn2specrat_instr0_lrd        (rn2specrat_instr0_lrd),
    .specrat2rn_instr0prs1        (specrat2rn_instr0prs1),
    .specrat2rn_instr0prs2        (specrat2rn_instr0prs2),
    .specrat2rn_instr0prd         (specrat2rn_instr0prd),
    .commit0_valid                (commit0_valid),
    .commit0_need_to_wb           (commit0_need_to_wb),
    .commit0_lrd                  (commit0_lrd),
    .commit0_prd                  (commit0_prd),
    .commit1_valid                (rob2specrat_commit1_valid),
    .commit1_need_to_wb           (rob2specrat_commit1_need_to_wb),
    .commit1_lrd                  (rob2specrat_commit1_lrd),
    .commit1_prd                  (rob2specrat_commit1_prd),
    .is_idle                      (is_idle),
    .is_rollingback               (is_rollingback),
    .is_walking                   (is_walking),
    .walking_valid0               (walking_valid0),
    .walking_valid1               (walking_valid1),
    .walking_prd0                 (walking_old_prd0),
    .walking_prd1                 (walking_old_prd1),
    .walking_lrd0                 (),
    .walking_lrd1                 ()
);

endmodule
