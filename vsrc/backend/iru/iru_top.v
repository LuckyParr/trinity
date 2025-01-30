`timescale 1ns / 1ps

module iru_top
#()
(
    input wire               clock,
    input wire               reset_n,
    input wire                       instr0_valid ,
    output wire                      instr0_ready                             ,                   
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

    input wire                       instr1_valid ,
    output wire                      instr1_ready                             ,                   
    input wire [ 31:0             ]  instr1                                   ,                         
    input wire [ 4 :0             ]  instr1_lrs1                              ,                    
    input wire [ 4 :0             ]  instr1_lrs2                              ,                    
    input wire [ 4 :0             ]  instr1_lrd                               ,                     
    input wire [ 63:0             ]  instr1_pc                                ,                      
    input wire [ 63:0             ]  instr1_imm                               ,                     
    input wire                       instr1_src1_is_reg                       ,             
    input wire                       instr1_src2_is_reg                       ,             
    input wire                       instr1_need_to_wb                        ,              
    input wire [    `CX_TYPE_RANGE]  instr1_cx_type                           ,                 
    input wire                       instr1_is_unsigned                       ,             
    input wire [   `ALU_TYPE_RANGE]  instr1_alu_type                          ,                
    input wire [`MULDIV_TYPE_RANGE]  instr1_muldiv_type                       ,             
    input wire                       instr1_is_word                           ,                 
    input wire                       instr1_is_imm                            ,                  
    input wire                       instr1_is_load                           ,                 
    input wire                       instr1_is_store                          ,                
    input wire [ 3:0              ]  instr1_ls_size  

    // Inputs from ROB to Speculative RAT
    input wire               rob2specrat_commit1_valid,
    input wire               rob2specrat_commit1_need_to_wb,
    input wire [`LREG_RANGE-1:0] rob2specrat_commit1_lrd,
    input wire [`PREG_RANGE-1:0] rob2specrat_commit1_prd,

    // Inputs from ROB to Free List
    input wire [`PREG_RANGE-1:0] rob2fl_commit_old_prd,
    input wire                   rob2fl_commit_valid0,

    // Additional control signals
    input wire [1:0]         rob_state,
    input wire               flush_valid,
    input wire               walking_valid0,
    input wire               walking_valid1,
    input wire [`PREG_RANGE-1:0] walking_old_prd0,
    input wire [`PREG_RANGE-1:0] walking_old_prd1,
    input wire               commit0_valid,
    input wire               commit0_need_to_wb,
    input wire [`LREG_RANGE-1:0] commit0_lrd,
    input wire [`PREG_RANGE-1:0] commit0_prd,

    //iru 2 pipe port
    output wire                      rn2pipe_instr0_valid,
    input wire                       pipe2rn_instr0_ready,
    output wire [ `LREG_RANGE      ] rn2pipe_instr0_lrs1,
    output wire [ `LREG_RANGE      ] rn2pipe_instr0_lrs2,
    output wire [ `LREG_RANGE      ] rn2pipe_instr0_lrd,
    output wire [   `PC_RANGE      ] rn2pipe_instr0_pc,
    output wire [`INSTR_RANGE      ] rn2pipe_instr0,
    output wire [              63:0] rn2pipe_instr0_imm,
    output wire                      rn2pipe_instr0_src1_is_reg,
    output wire                      rn2pipe_instr0_src2_is_reg,
    output wire                      rn2pipe_instr0_need_to_wb,
    output wire [    `CX_TYPE_RANGE] rn2pipe_instr0_cx_type,
    output wire                      rn2pipe_instr0_is_unsigned,
    output wire [   `ALU_TYPE_RANGE] rn2pipe_instr0_alu_type,
    output wire [`MULDIV_TYPE_RANGE] rn2pipe_instr0_muldiv_type,
    output wire                      rn2pipe_instr0_is_word,
    output wire                      rn2pipe_instr0_is_imm,
    output wire                      rn2pipe_instr0_is_load,
    output wire                      rn2pipe_instr0_is_store,
    output wire [               3:0] rn2pipe_instr0_ls_size,
    output wire [`PREG_RANGE       ] rn2pipe_instr0_old_prd,
    //other info of instr1
    output wire                      rn2pipe_instr1_valid,
    input wire                       pipe2rn_instr1_ready,
    output wire [ `LREG_RANGE      ] rn2pipe_instr1_lrs1,
    output wire [ `LREG_RANGE      ] rn2pipe_instr1_lrs2,
    output wire [ `LREG_RANGE      ] rn2pipe_instr1_lrd,
    output wire [   `PC_RANGE      ] rn2pipe_instr1_pc,
    output wire [`INSTR_RANGE      ] rn2pipe_instr1,
    output wire [              63:0] rn2pipe_instr1_imm,
    output wire                      rn2pipe_instr1_src1_is_reg,
    output wire                      rn2pipe_instr1_src2_is_reg,
    output wire                      rn2pipe_instr1_need_to_wb,
    output wire [    `CX_TYPE_RANGE] rn2pipe_instr1_cx_type,
    output wire                      rn2pipe_instr1_is_unsigned,
    output wire [   `ALU_TYPE_RANGE] rn2pipe_instr1_alu_type,
    output wire [`MULDIV_TYPE_RANGE] rn2pipe_instr1_muldiv_type,
    output wire                      rn2pipe_instr1_is_word,
    output wire                      rn2pipe_instr1_is_imm,
    output wire                      rn2pipe_instr1_is_load,
    output wire                      rn2pipe_instr1_is_store,
    output wire [               3:0] rn2pipe_instr1_ls_size,
    output wire [`PREG_RANGE       ] rn2pipe_instr1_old_prd,
    //arch_rat : 32 arch regfile content
    output wire [`PREG_RANGE] debug_preg0,
    output wire [`PREG_RANGE] debug_preg1,
    output wire [`PREG_RANGE] debug_preg2,
    output wire [`PREG_RANGE] debug_preg3,
    output wire [`PREG_RANGE] debug_preg4,
    output wire [`PREG_RANGE] debug_preg5,
    output wire [`PREG_RANGE] debug_preg6,
    output wire [`PREG_RANGE] debug_preg7,
    output wire [`PREG_RANGE] debug_preg8,
    output wire [`PREG_RANGE] debug_preg9,
    output wire [`PREG_RANGE] debug_preg10,
    output wire [`PREG_RANGE] debug_preg11,
    output wire [`PREG_RANGE] debug_preg12,
    output wire [`PREG_RANGE] debug_preg13,
    output wire [`PREG_RANGE] debug_preg14,
    output wire [`PREG_RANGE] debug_preg15,
    output wire [`PREG_RANGE] debug_preg16,
    output wire [`PREG_RANGE] debug_preg17,
    output wire [`PREG_RANGE] debug_preg18,
    output wire [`PREG_RANGE] debug_preg19,
    output wire [`PREG_RANGE] debug_preg20,
    output wire [`PREG_RANGE] debug_preg21,
    output wire [`PREG_RANGE] debug_preg22,
    output wire [`PREG_RANGE] debug_preg23,
    output wire [`PREG_RANGE] debug_preg24,
    output wire [`PREG_RANGE] debug_preg25,
    output wire [`PREG_RANGE] debug_preg26,
    output wire [`PREG_RANGE] debug_preg27,
    output wire [`PREG_RANGE] debug_preg28,
    output wire [`PREG_RANGE] debug_preg29,
    output wire [`PREG_RANGE] debug_preg30,
    output wire [`PREG_RANGE] debug_preg31
        
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
    .wr_en0           (rob2fl_commit_valid0),//o //commits0_valid & commits0_need_to_wb
    .wr_data0         (rob2fl_commit_old_prd),
    .wr_en1           (1'b0),
    .wr_data1         ('b0),
    .rd_en0           (rn2fl_instr0_lrd_valid),//i //instr0_freelist_req
    .rd_data0         (fl2rn_instr0prd),//i //instr0_freelist_resp
    .rd_en1           (1'b0),
    .rd_data1         (),
    .rob_state        (rob_state),
    .walking_valid0   (walking_valid0),
    .walking_valid1   (walking_valid1)
);

rename u_rename(
    .instr0_valid                 (instr0_valid                 ),
    .instr0_ready                 (instr0_ready                 ),//output
    .instr0                       (instr0                       ),
    .instr0_lrs1                  (instr0_lrs1                  ),
    .instr0_lrs2                  (instr0_lrs2                  ),
    .instr0_lrd                   (instr0_lrd                   ),
    .instr0_pc                    (instr0_pc                    ),
    .instr0_imm                   (instr0_imm                   ),
    .instr0_src1_is_reg           (instr0_src1_is_reg           ),
    .instr0_src2_is_reg           (instr0_src2_is_reg           ),
    .instr0_need_to_wb            (instr0_need_to_wb            ),
    .instr0_cx_type               (instr0_cx_type               ),
    .instr0_is_unsigned           (instr0_is_unsigned           ),
    .instr0_alu_type              (instr0_alu_type              ),
    .instr0_muldiv_type           (instr0_muldiv_type           ),
    .instr0_is_word               (instr0_is_word               ),
    .instr0_is_imm                (instr0_is_imm                ),
    .instr0_is_load               (instr0_is_load               ),
    .instr0_is_store              (instr0_is_store              ),
    .instr0_ls_size               (instr0_ls_size               ),
    .instr1_valid                 (),
    .instr1_ready                 (),
    .instr1                       (),
    .instr1_lrs1                  (),
    .instr1_lrs2                  (),
    .instr1_lrd                   (),
    .instr1_pc                    (),
    .instr1_imm                   (),
    .instr1_src1_is_reg           (),
    .instr1_src2_is_reg           (),
    .instr1_need_to_wb            (),
    .instr1_cx_type               (),
    .instr1_is_unsigned           (),
    .instr1_alu_type              (),
    .instr1_muldiv_type           (),
    .instr1_is_word               (),
    .instr1_is_imm                (),
    .instr1_is_load               (),
    .instr1_is_store              (),
    .instr1_ls_size               (),

    .rn2specrat_instr0_lrs1_rden  (rn2specrat_instr0_lrs1_rden  ),
    .rn2specrat_instr0_lrs1       (rn2specrat_instr0_lrs1       ),
    .rn2specrat_instr0_lrs2_rden  (rn2specrat_instr0_lrs2_rden  ),
    .rn2specrat_instr0_lrs2       (rn2specrat_instr0_lrs2       ),
    .rn2specrat_instr0_lrd_rden   (rn2specrat_instr0_lrd_rden   ),
    .rn2specrat_instr0_lrd        (rn2specrat_instr0_lrd        ),
    .rn2specrat_instr1_lrs1_rden  (),
    .rn2specrat_instr1_lrs1       (),
    .rn2specrat_instr1_lrs2_rden  (),
    .rn2specrat_instr1_lrs2       (),
    .rn2specrat_instr1_lrd_rden   (),
    .rn2specrat_instr1_lrd        (),
    .specrat2rn_instr0prs1        (specrat2rn_instr0prs1        ),
    .specrat2rn_instr0prs2        (specrat2rn_instr0prs2        ),
    .specrat2rn_instr0prd         (specrat2rn_instr0prd         ),
    .specrat2rn_instr1prs1        (),
    .specrat2rn_instr1prs2        (),
    .specrat2rn_instr1prd         (),
    .rn2fl_instr0_lrd_valid       (rn2fl_instr0_lrd_valid       ),
    .fl2rn_instr0prd              (fl2rn_instr0prd              ),
    .rn2fl_instr1_lrd_valid       (),
    .fl2rn_instr1prd              (),
    .flush_valid                  (flush_valid                  ),

    .rn2specrat_instr0_lrd_wren   (rn2specrat_instr0_lrd_wren   ),//output
    .rn2specrat_instr0_lrd_wraddr (rn2specrat_instr0_lrd_wraddr ),//output
    .rn2specrat_instr0_lrd_wrdata (rn2specrat_instr0_lrd_wrdata ),//output
    .rn2specrat_instr1_lrd_wren   (),//output
    .rn2specrat_instr1_lrd_wraddr (),//output
    .rn2specrat_instr1_lrd_wrdata (),//output

    .rn2pipe_instr0_valid         (rn2pipe_instr0_valid         ),//output
    .pipe2rn_instr0_ready          (pipe2rn_instr0_ready          ),//i
    .rn2pipe_instr0_lrs1          (rn2pipe_instr0_lrs1          ),//output
    .rn2pipe_instr0_lrs2          (rn2pipe_instr0_lrs2          ),//output
    .rn2pipe_instr0_lrd           (rn2pipe_instr0_lrd           ),//output
    .rn2pipe_instr0_pc            (rn2pipe_instr0_pc            ),//output
    .rn2pipe_instr0               (rn2pipe_instr0               ),//output
    .rn2pipe_instr0_imm           (rn2pipe_instr0_imm           ),//output
    .rn2pipe_instr0_src1_is_reg   (rn2pipe_instr0_src1_is_reg   ),//output
    .rn2pipe_instr0_src2_is_reg   (rn2pipe_instr0_src2_is_reg   ),//output
    .rn2pipe_instr0_need_to_wb    (rn2pipe_instr0_need_to_wb    ),//output
    .rn2pipe_instr0_cx_type       (rn2pipe_instr0_cx_type       ),//output
    .rn2pipe_instr0_is_unsigned   (rn2pipe_instr0_is_unsigned   ),//output
    .rn2pipe_instr0_alu_type      (rn2pipe_instr0_alu_type      ),//output
    .rn2pipe_instr0_muldiv_type   (rn2pipe_instr0_muldiv_type   ),//output
    .rn2pipe_instr0_is_word       (rn2pipe_instr0_is_word       ),//output
    .rn2pipe_instr0_is_imm        (rn2pipe_instr0_is_imm        ),//output
    .rn2pipe_instr0_is_load       (rn2pipe_instr0_is_load       ),//output
    .rn2pipe_instr0_is_store      (rn2pipe_instr0_is_store      ),//output
    .rn2pipe_instr0_ls_size       (rn2pipe_instr0_ls_size       ),//output
    .rn2pipe_instr0_old_prd       (rn2pipe_instr0_old_prd       ),//output
    .rn2pipe_instr0_prs1          (rn2pipe_instr0_prs1          ),//output
    .rn2pipe_instr0_prs2          (rn2pipe_instr0_prs2          ),//output
    .rn2pipe_instr0_prd           (rn2pipe_instr0_prd           ),//output

    .rn2pipe_instr1_valid         (),//output
    .pipe2rn_instr1_ready         (),//i
    .rn2pipe_instr1_lrs1          (),//output
    .rn2pipe_instr1_lrs2          (),//output
    .rn2pipe_instr1_lrd           (),//output
    .rn2pipe_instr1_pc            (),//output
    .rn2pipe_instr1               (),//output
    .rn2pipe_instr1_imm           (),//output
    .rn2pipe_instr1_src1_is_reg   (),//output
    .rn2pipe_instr1_src2_is_reg   (),//output
    .rn2pipe_instr1_need_to_wb    (),//output
    .rn2pipe_instr1_cx_type       (),//output
    .rn2pipe_instr1_is_unsigned   (),//output
    .rn2pipe_instr1_alu_type      (),//output
    .rn2pipe_instr1_muldiv_type   (),//output
    .rn2pipe_instr1_is_word       (),//output
    .rn2pipe_instr1_is_imm        (),//output
    .rn2pipe_instr1_is_load       (),//output
    .rn2pipe_instr1_is_store      (),//output
    .rn2pipe_instr1_ls_size       (),//output
    .rn2pipe_instr1_old_prd       (),//output
    .rn2pipe_instr1_prs1          (),//output
    .rn2pipe_instr1_prs2          (),//output
    .rn2pipe_instr1_prd           ()//output

);

spec_rat u_spec_rat(
    .clock                        (clock                        ),
    .reset_n                      (reset_n                      ),
    .rn2specrat_instr0_lrd_wren   (rn2specrat_instr0_lrd_wren   ),
    .rn2specrat_instr0_lrd_wraddr (rn2specrat_instr0_lrd_wraddr ),
    .rn2specrat_instr0_lrd_wrdata (rn2specrat_instr0_lrd_wrdata ),
    .rn2specrat_instr1_lrd_wren   (),
    .rn2specrat_instr1_lrd_wraddr (),
    .rn2specrat_instr1_lrd_wrdata (),
    .rn2specrat_instr0_lrs1_rden  (rn2specrat_instr0_lrs1_rden  ),
    .rn2specrat_instr0_lrs2_rden  (rn2specrat_instr0_lrs2_rden  ),
    .rn2specrat_instr0_lrd_rden   (rn2specrat_instr0_lrd_rden   ),
    .rn2specrat_instr1_lrs1_rden  (),
    .rn2specrat_instr1_lrs2_rden  (),
    .rn2specrat_instr1_lrd_rden   (),
    .rn2specrat_instr0_lrs1       (rn2specrat_instr0_lrs1       ),
    .rn2specrat_instr0_lrs2       (rn2specrat_instr0_lrs2       ),
    .rn2specrat_instr0_lrd        (rn2specrat_instr0_lrd        ),
    .rn2specrat_instr1_lrs1       (),
    .rn2specrat_instr1_lrs2       (),
    .rn2specrat_instr1_lrd        (),
    .specrat2rn_instr0prs1        (specrat2rn_instr0prs1        ),
    .specrat2rn_instr0prs2        (specrat2rn_instr0prs2        ),
    .specrat2rn_instr0prd         (specrat2rn_instr0prd         ),
    .specrat2rn_instr1prs1        (),
    .specrat2rn_instr1prs2        (),
    .specrat2rn_instr1prd         (),
    .commit0_valid                (commit0_valid                ),
    .commit0_need_to_wb           (commit0_need_to_wb           ),
    .commit0_lrd                  (commit0_lrd                  ),
    .commit0_prd                  (commit0_prd                  ),
    .commit1_valid                (),
    .commit1_need_to_wb           (),
    .commit1_lrd                  (),
    .commit1_prd                  (),
    .rob_state                    (rob_state),
    .walking_valid0               (walking_valid0               ),
    .walking_valid1               (walking_valid1               ),
    .walking_prd0                 (walking_prd0                 ),
    .walking_prd1                 (walking_prd1                 ),
    .walking_lrd0                 (walking_lrd0                 ),
    .walking_lrd1                 (walking_lrd1                 ),
    // 32 arch reg 
    .debug_preg0                   (debug_preg0),
    .debug_preg1                   (debug_preg1),
    .debug_preg2                   (debug_preg2),
    .debug_preg3                   (debug_preg3),
    .debug_preg4                   (debug_preg4),
    .debug_preg5                   (debug_preg5),
    .debug_preg6                   (debug_preg6),
    .debug_preg7                   (debug_preg7),
    .debug_preg8                   (debug_preg8),
    .debug_preg9                   (debug_preg9),
    .debug_preg10                  (debug_preg10),
    .debug_preg11                  (debug_preg11),
    .debug_preg12                  (debug_preg12),
    .debug_preg13                  (debug_preg13),
    .debug_preg14                  (debug_preg14),
    .debug_preg15                  (debug_preg15),
    .debug_preg16                  (debug_preg16),
    .debug_preg17                  (debug_preg17),
    .debug_preg18                  (debug_preg18),
    .debug_preg19                  (debug_preg19),
    .debug_preg20                  (debug_preg20),
    .debug_preg21                  (debug_preg21),
    .debug_preg22                  (debug_preg22),
    .debug_preg23                  (debug_preg23),
    .debug_preg24                  (debug_preg24),
    .debug_preg25                  (debug_preg25),
    .debug_preg26                  (debug_preg26),
    .debug_preg27                  (debug_preg27),
    .debug_preg28                  (debug_preg28),
    .debug_preg29                  (debug_preg29),
    .debug_preg30                  (debug_preg30),
    .debug_preg31                  (debug_preg31)
);


endmodule
