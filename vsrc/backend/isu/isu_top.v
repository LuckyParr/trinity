module isu_top #(
    parameter DATA_WIDTH      = 248,
    parameter CONDITION_WIDTH = 2,
    parameter INDEX_WIDTH     = 4,
)(
    input  wire               clock,
    input  wire               reset_n,

    // Dispatch inputs from rename stage
    input  wire               iru2isu_instr0_valid,
    output wire               isu2iru_instr0_ready,
    input  wire [  `PC_RANGE]  instr0_pc,
    input  wire [       31:0] instr0,
    input  wire [`LREG_RANGE]  instr0_lrs1,
    input  wire [`LREG_RANGE]  instr0_lrs2,
    input  wire [`LREG_RANGE]  instr0_lrd,
    input  wire [`PREG_RANGE]  instr0_prd,
    input  wire [`PREG_RANGE]  instr0_old_prd,
    input  wire                instr0_need_to_wb,
    input  wire [`PREG_RANGE]  instr0_prs1,
    input  wire [`PREG_RANGE]  instr0_prs2,
    input  wire               instr0_src1_is_reg,
    input  wire               instr0_src2_is_reg,
    input  wire [       63:0] instr0_imm,
    input  wire [    `CX_TYPE_RANGE] instr0_cx_type,
    input  wire               instr0_is_unsigned,
    input  wire [   `ALU_TYPE_RANGE] instr0_alu_type,
    input  wire [`MULDIV_TYPE_RANGE] instr0_muldiv_type,
    input  wire               instr0_is_word,
    input  wire               instr0_is_imm,
    input  wire               instr0_is_load,
    input  wire               instr0_is_store,
    input  wire [        3:0] instr0_ls_size,

    input  wire               iru2isu_instr1_valid,
    output wire               isu2iru_instr1_ready,
    input  wire [  `PC_RANGE]  instr1_pc,
    input  wire [       31:0] instr1,
    input  wire [`LREG_RANGE]  instr1_lrs1,
    input  wire [`LREG_RANGE]  instr1_lrs2,
    input  wire [`LREG_RANGE]  instr1_lrd,
    input  wire [`PREG_RANGE]  instr1_prd,
    input  wire [`PREG_RANGE]  instr1_old_prd,
    input  wire               instr1_need_to_wb,
    input  wire [`PREG_RANGE]  instr1_prs1,
    input  wire [`PREG_RANGE]  instr1_prs2,
    input  wire               instr1_src1_is_reg,
    input  wire               instr1_src2_is_reg,
    input  wire [       63:0] instr1_imm,
    input  wire [    `CX_TYPE_RANGE] instr1_cx_type,
    input  wire               instr1_is_unsigned,
    input  wire [   `ALU_TYPE_RANGE] instr1_alu_type,
    input  wire [`MULDIV_TYPE_RANGE] instr1_muldiv_type,
    input  wire               instr1_is_word,
    input  wire               instr1_is_imm,
    input  wire               instr1_is_load,
    input  wire               instr1_is_store,
    input  wire [        3:0] instr1_ls_size,

    // Writeback inputs
    input  wire                     intwb_instr_valid,
    input  wire [`ROB_SIZE_LOG:0]   intwb_robid,
    input  wire [`PREG_RANGE]       intwb_prd,
    input  wire                     intwb_need_to_wb,

    input  wire                     memwb_instr_valid,
    input  wire [`ROB_SIZE_LOG:0]    memwb_robid,
    input  wire [`PREG_RANGE]        memwb_prd,
    input  wire                     memwb_need_to_wb,
    input  wire                     memwb_mmio_valid,

  

    // Flush inputs
    input  wire                     flush_valid,
    input  wire [`ROB_SIZE_LOG:0]    flush_robid,

    // Commit outputs
    output wire                     commit0_valid,
    output wire [        `PC_RANGE] commit0_pc,
    output wire [             31:0] commit0_instr,
    output wire [      `LREG_RANGE] commit0_lrd,
    output wire [      `PREG_RANGE] commit0_prd,
    output wire [      `PREG_RANGE] commit0_old_prd,
    output wire                     commit0_need_to_wb,
    output wire [`ROB_SIZE_LOG:0]   commit0_robid,
    output wire                     commit0_skip,

    output wire                     commit1_valid,
    output wire [        `PC_RANGE] commit1_pc,
    output wire [             31:0] commit1_instr,
    output wire [      `LREG_RANGE] commit1_lrd,
    output wire [      `PREG_RANGE] commit1_prd,
    output wire [      `PREG_RANGE] commit1_old_prd,
    output wire [`ROB_SIZE_LOG:0]   commit1_robid,
    output wire                     commit1_need_to_wb,
    output wire                     commit1_skip,

    // ISQ outputs
    output wire [6:0]  isu2exu_instr0_robid       ,
    output wire [63:0] isu2exu_instr0_pc          ,
    output wire [31:0] isu2exu_instr0             ,
    output wire [4:0]  isu2exu_instr0_lrs1        ,
    output wire [4:0]  isu2exu_instr0_lrs2        ,
    output wire [4:0]  isu2exu_instr0_lrd         ,
    output wire [5:0]  isu2exu_instr0_prd         ,
    output wire [5:0]  isu2exu_instr0_old_prd     ,
    output wire        isu2exu_instr0_need_to_wb  ,
    output wire [5:0]  isu2exu_instr0_prs1        ,
    output wire [5:0]  isu2exu_instr0_prs2        ,
    output wire        isu2exu_instr0_src1_is_reg ,
    output wire        isu2exu_instr0_src2_is_reg ,
    output wire [63:0] isu2exu_instr0_imm         ,
    output wire [5:0]  isu2exu_instr0_cx_type     ,
    output wire        isu2exu_instr0_is_unsigned ,
    output wire [10:0] isu2exu_instr0_alu_type    ,
    output wire [12:0] isu2exu_instr0_muldiv_type ,
    output wire        isu2exu_instr0_is_word     ,
    output wire        isu2exu_instr0_is_imm      ,
    output wire        isu2exu_instr0_is_load     ,
    output wire        isu2exu_instr0_is_store    ,
    output wire [3:0]  isu2exu_instr0_ls_size     ,
    output wire                       deq_valid,
    input  wire                       deq_ready,

    // Debug outputs
    output wire [1:0]               rob_state,
    output wire                     rob_walk0_valid,
    output wire                     rob_walk0_complete,
    output wire [`LREG_RANGE]        rob_walk0_lrd,
    output wire [`PREG_RANGE]        rob_walk0_prd,
    output wire                     rob_walk1_valid,
    output wire [`LREG_RANGE]        rob_walk1_lrd,
    output wire [`PREG_RANGE]        rob_walk1_prd,
    output wire                     rob_walk1_complete,
    // //intisq indicate instr0 is load or store 
    // output wire isu2exu_instr0_is_load,
    // output wire isu2exu_instr0_is_store,
    //preg content from arch_rat
    input wire [`PREG_RANGE] debug_preg0,
    input wire [`PREG_RANGE] debug_preg1,
    input wire [`PREG_RANGE] debug_preg2,
    input wire [`PREG_RANGE] debug_preg3,
    input wire [`PREG_RANGE] debug_preg4,
    input wire [`PREG_RANGE] debug_preg5,
    input wire [`PREG_RANGE] debug_preg6,
    input wire [`PREG_RANGE] debug_preg7,
    input wire [`PREG_RANGE] debug_preg8,
    input wire [`PREG_RANGE] debug_preg9,
    input wire [`PREG_RANGE] debug_preg10,
    input wire [`PREG_RANGE] debug_preg11,
    input wire [`PREG_RANGE] debug_preg12,
    input wire [`PREG_RANGE] debug_preg13,
    input wire [`PREG_RANGE] debug_preg14,
    input wire [`PREG_RANGE] debug_preg15,
    input wire [`PREG_RANGE] debug_preg16,
    input wire [`PREG_RANGE] debug_preg17,
    input wire [`PREG_RANGE] debug_preg18,
    input wire [`PREG_RANGE] debug_preg19,
    input wire [`PREG_RANGE] debug_preg20,
    input wire [`PREG_RANGE] debug_preg21,
    input wire [`PREG_RANGE] debug_preg22,
    input wire [`PREG_RANGE] debug_preg23,
    input wire [`PREG_RANGE] debug_preg24,
    input wire [`PREG_RANGE] debug_preg25,
    input wire [`PREG_RANGE] debug_preg26,
    input wire [`PREG_RANGE] debug_preg27,
    input wire [`PREG_RANGE] debug_preg28,
    input wire [`PREG_RANGE] debug_preg29,
    input wire [`PREG_RANGE] debug_preg30,
    input wire [`PREG_RANGE] debug_preg31
);
    //wb free busy_table
    wire intwb2bt_free_instr0rd_en =   intwb_instr_valid &&  intwb_need_to_wb;         
    wire [5:0] intwb2bt_free_instr0rd_addr =      intwb_prd;
    wire memwb2bt_free_instr0rd_en =   memwb_instr_valid &&  memwb_need_to_wb;          
    wire [5:0] memwb2bt_free_instr0rd_addr =   memwb_prd; 

    // Internal wires
    wire [`ROB_SIZE_LOG:0] rob2disp_instr_robid;
    wire rob_can_enq;
    wire disp2rob_instr0_enq_valid;
    wire [`PC_RANGE] disp2rob_instr0_pc;
    wire [31:0] disp2rob_instr0;
    wire [`LREG_RANGE] disp2rob_instr0_lrd;
    wire [`PREG_RANGE] disp2rob_instr0_prd;
    wire [`PREG_RANGE] disp2rob_instr0_old_prd;
    wire disp2rob_instr0_need_to_wb;

    wire disp2rob_instr1_enq_valid;
    wire [`PC_RANGE] disp2rob_instr1_pc;
    wire [31:0] disp2rob_instr1;
    wire [`LREG_RANGE] disp2rob_instr1_lrd;
    wire [`PREG_RANGE] disp2rob_instr1_prd;
    wire [`PREG_RANGE] disp2rob_instr1_old_prd;
    wire disp2rob_instr1_need_to_wb;

    wire [5:0] disp2bt_instr0rs1_rdaddr;
    wire bt2disp_instr0rs1_busy;
    wire [5:0] disp2bt_instr0rs2_rdaddr;
    wire bt2disp_instr0rs2_busy;
    wire [5:0] disp2bt_instr1rs1_rdaddr;
    wire bt2disp_instr1rs1_busy;
    wire [5:0] disp2bt_instr1rs2_rdaddr;
    wire bt2disp_instr1rs2_busy;

    wire disp2bt_alloc_instr0rd_en;
    wire [5:0] disp2bt_alloc_instr0rd_addr;
    wire disp2bt_alloc_instr1rd_en;
    wire [5:0] disp2bt_alloc_instr1rd_addr;

    wire intisq_can_enq;
    wire disp2intisq_enq_valid;
    wire [DATA_WIDTH-1:0] disp2intisq_instr0_enq_data;
    wire [CONDITION_WIDTH-1:0] disp2intisq_instr0_enq_condition;

    wire [DATA_WIDTH-1:0]      deq_data;
    wire [CONDITION_WIDTH-1:0] deq_condition;
    wire [INDEX_WIDTH-1:0]     deq_index;

    dispatch u_dispatch(
        .clock                            (clock                            ),
        .reset_n                          (reset_n                          ),
        .iru2isu_instr0_valid             (iru2isu_instr0_valid           ),
        .isu2iru_instr0_ready             (isu2iru_instr0_ready           ),
        .instr0_pc                        (instr0_pc                        ),
        .instr0                           (instr0                           ),
        .instr0_lrs1                      (instr0_lrs1                      ),
        .instr0_lrs2                      (instr0_lrs2                      ),
        .instr0_lrd                       (instr0_lrd                       ),
        .instr0_prd                       (instr0_prd                       ),
        .instr0_old_prd                   (instr0_old_prd                   ),
        .instr0_need_to_wb                (instr0_need_to_wb                ),
        .instr0_prs1                      (instr0_prs1                      ),
        .instr0_prs2                      (instr0_prs2                      ),
        .instr0_src1_is_reg               (instr0_src1_is_reg               ),
        .instr0_src2_is_reg               (instr0_src2_is_reg               ),
        .instr0_imm                       (instr0_imm                       ),
        .instr0_cx_type                   (instr0_cx_type                   ),
        .instr0_is_unsigned               (instr0_is_unsigned               ),
        .instr0_alu_type                  (instr0_alu_type                  ),
        .instr0_muldiv_type               (instr0_muldiv_type               ),
        .instr0_is_word                   (instr0_is_word                   ),
        .instr0_is_imm                    (instr0_is_imm                    ),
        .instr0_is_load                   (instr0_is_load                   ),
        .instr0_is_store                  (instr0_is_store                  ),
        .instr0_ls_size                   (instr0_ls_size                   ),
        .iru2isu_instr1_valid           (),
        .isu2iru_instr1_ready             (),
        .instr1_pc                        (),
        .instr1                           (),
        .instr1_lrs1                      (),
        .instr1_lrs2                      (),
        .instr1_lrd                       (),
        .instr1_prd                       (),
        .instr1_old_prd                   (),
        .instr1_need_to_wb                (),
        .instr1_prs1                      (),
        .instr1_prs2                      (),
        .instr1_src1_is_reg               (),
        .instr1_src2_is_reg               (),
        .instr1_imm                       (),
        .instr1_cx_type                   (),
        .instr1_is_unsigned               (),
        .instr1_alu_type                  (),
        .instr1_muldiv_type               (),
        .instr1_is_word                   (),
        .instr1_is_imm                    (),
        .instr1_is_load                   (),
        .instr1_is_store                  (),
        .instr1_ls_size                   (),
        .rob_can_enq                      (rob_can_enq                      ),
        .rob2disp_instr_robid             (rob2disp_instr_robid             ),
        .rob_state                        (rob_state                        ),
        .disp2rob_instr0_enq_valid        (disp2rob_instr0_enq_valid        ),
        .disp2rob_instr0_pc               (disp2rob_instr0_pc               ),
        .disp2rob_instr0                  (disp2rob_instr0                  ),
        .disp2rob_instr0_lrd              (disp2rob_instr0_lrd              ),
        .disp2rob_instr0_prd              (disp2rob_instr0_prd              ),
        .disp2rob_instr0_old_prd          (disp2rob_instr0_old_prd          ),
        .disp2rob_instr0_need_to_wb       (disp2rob_instr0_need_to_wb       ),
        .disp2rob_instr1_enq_valid        (),
        .disp2rob_instr1_pc               (),
        .disp2rob_instr1                  (),
        .disp2rob_instr1_lrd              (),
        .disp2rob_instr1_prd              (),
        .disp2rob_instr1_old_prd          (),
        .disp2rob_instr1_need_to_wb       (),
        .intisq_can_enq                   (intisq_can_enq                   ),
        .disp2intisq_enq_valid            (disp2intisq_enq_valid            ),
        .intisq2disp_enq_ready            (intisq2disp_enq_ready            ),
        .disp2intisq_instr0_enq_data      (disp2intisq_instr0_enq_data      ),
        .disp2intisq_instr0_enq_condition (disp2intisq_instr0_enq_condition ),
        .disp2bt_instr0rs1_rdaddr         (disp2bt_instr0rs1_rdaddr         ),
        .bt2disp_instr0rs1_busy           (bt2disp_instr0rs1_busy           ),
        .disp2bt_instr0rs2_rdaddr         (disp2bt_instr0rs2_rdaddr         ),
        .bt2disp_instr0rs2_busy           (bt2disp_instr0rs2_busy           ),
        .disp2bt_instr1rs1_rdaddr         (),
        .bt2disp_instr1rs1_busy           (),
        .disp2bt_instr1rs2_rdaddr         (),
        .bt2disp_instr1rs2_busy           (),
        .disp2bt_alloc_instr0rd_en        (disp2bt_alloc_instr0rd_en        ),
        .disp2bt_alloc_instr0rd_addr      (disp2bt_alloc_instr0rd_addr      ),
        .disp2bt_alloc_instr1rd_en        (),
        .disp2bt_alloc_instr1rd_addr      (),
        .flush_valid                      (flush_valid                      )
    );
    
    // Instantiate modules
    rob rob_inst (

        .clock               (clock                     ),
        .reset_n             (reset_n                   ),
        .instr0_enq_valid    (disp2rob_instr0_enq_valid ),
        .instr0_pc           (disp2rob_instr0_pc        ),
        .instr0              (disp2rob_instr0           ),
        .instr0_lrd          (disp2rob_instr0_lrd       ),
        .instr0_prd          (disp2rob_instr0_prd       ),
        .instr0_old_prd      (disp2rob_instr0_old_prd   ),
        .instr0_need_to_wb   (disp2rob_instr0_need_to_wb),
        .instr1_enq_valid    (),
        .instr1_pc           (),
        .instr1              (),
        .instr1_lrd          (),
        .instr1_prd          (),
        .instr1_old_prd      (),
        .instr1_need_to_wb   (),
        .rob2disp_instr_robid(rob2disp_instr_robid      ),
        .rob_can_enq         (rob_can_enq               ),
        .intwb_instr_valid   (intwb_instr_valid         ),
        .intwb_robid         (intwb_robid               ),
        .memwb_instr_valid   (memwb_instr_valid         ),
        .memwb_robid         (memwb_robid               ),
        .memwb_mmio_valid    (memwb_mmio_valid                     ), 
        .commit0_valid       (commit0_valid             ),
        .commit0_pc          (commit0_pc                ),
        .commit0_instr       (commit0_instr             ),
        .commit0_lrd         (commit0_lrd               ),
        .commit0_prd         (commit0_prd               ),
        .commit0_old_prd     (commit0_old_prd           ),
        .commit0_need_to_wb  (commit0_need_to_wb        ),
        .commit0_robid       (commit0_robid             ),
        .commit0_skip        (commit0_skip              ),
        .commit1_valid       (),
        .commit1_pc          (),
        .commit1_instr       (),
        .commit1_lrd         (),
        .commit1_prd         (),
        .commit1_old_prd     (),
        .commit1_robid       (),
        .commit1_need_to_wb  (),
        .commit1_skip        (),
        .flush_valid         (flush_valid               ),
        .flush_robid         (flush_robid               ),
        .rob_state           (rob_state                 ),
        .rob_walk0_valid     (rob_walk0_valid           ),
        .rob_walk0_complete  (rob_walk0_complete        ),
        .rob_walk0_lrd       (rob_walk0_lrd             ),
        .rob_walk0_prd       (rob_walk0_prd             ),
        .rob_walk1_valid     (rob_walk1_valid           ),
        .rob_walk1_lrd       (rob_walk1_lrd             ),
        .rob_walk1_prd       (rob_walk1_prd             ),
        .rob_walk1_complete  (rob_walk1_complete        )
);

int_isq 
#(
    .DATA_WIDTH      (DATA_WIDTH      ),
    .CONDITION_WIDTH (CONDITION_WIDTH ),
    .INDEX_WIDTH     (INDEX_WIDTH     ),
    .DEPTH           (DEPTH           )
)
u_int_isq                          (
    .clock                         (clock                        ),
    .reset_n                       (reset_n                      ),
    .enq_data                      (enq_data                     ),
    .enq_condition                 (enq_condition                ),
    .enq_valid                     (enq_valid                    ),
    .enq_ready                     (enq_ready                    ),
    .deq_data                      (deq_data                     ),
    .deq_condition                 (deq_condition                ),
    .deq_index                     (deq_index                    ),
    .deq_valid                     (deq_valid                    ),
    .deq_ready                     (deq_ready                    ),
    .writeback0_valid              (writeback0_valid             ),
    .writeback0_need_to_wb         (writeback0_need_to_wb        ),
    .writeback0_prd                (writeback0_prd               ),
    .writeback1_valid              (writeback1_valid             ),
    .writeback1_need_to_wb         (writeback1_need_to_wb        ),
    .writeback1_prd                (writeback1_prd               ),
    .flush_valid                   (flush_valid                  ),
    .flush_robid                   (flush_robid                  ),
    .intisq_can_enq                (intisq_can_enq               )
);
// Decode each field of deq_data:
    assign isu2exu_instr0_robid        = deq_data[247:241];
    assign isu2exu_instr0_pc           = deq_data[240:177];
    assign isu2exu_instr0              = deq_data[176:145];
    assign isu2exu_instr0_lrs1         = deq_data[144:140];
    assign isu2exu_instr0_lrs2         = deq_data[139:135];
    assign isu2exu_instr0_lrd          = deq_data[134:130];
    assign isu2exu_instr0_prd          = deq_data[129:124];
    assign isu2exu_instr0_old_prd      = deq_data[123:118];
    assign isu2exu_instr0_need_to_wb   = deq_data[117];
    assign isu2exu_instr0_prs1         = deq_data[116:111];
    assign isu2exu_instr0_prs2         = deq_data[110:105];
    assign isu2exu_instr0_src1_is_reg  = deq_data[104];
    assign isu2exu_instr0_src2_is_reg  = deq_data[103];
    assign isu2exu_instr0_imm          = deq_data[102:39];
    assign isu2exu_instr0_cx_type      = deq_data[38:33];
    assign isu2exu_instr0_is_unsigned  = deq_data[32];
    assign isu2exu_instr0_alu_type     = deq_data[31:21];
    assign isu2exu_instr0_muldiv_type  = deq_data[20:8];
    assign isu2exu_instr0_is_word      = deq_data[7];
    assign isu2exu_instr0_is_imm       = deq_data[6];
    assign isu2exu_instr0_is_load      = deq_data[5];
    assign isu2exu_instr0_is_store     = deq_data[4];
    assign isu2exu_instr0_ls_size      = deq_data[3:0];

   // assign isu2exu_instr0_is_load = deq_valid && isu2exu_instr0_is_load;
   // assign isu2exu_instr0_is_store = deq_valid && isu2exu_instr0_is_store;
    wire intisq2prf_instr0_src1_is_reg = deq_valid && isu2exu_instr0_src1_is_reg;
    wire intisq2prf_inst0_prs1         = {6{deq_valid}} & isu2exu_instr0_prs1;
    wire intisq2prf_instr0_src2_is_reg = deq_valid && isu2exu_instr0_src2_is_reg;
    wire intisq2prf_inst0_prs2         = {6{deq_valid}} & isu2exu_instr0_prs2; 


busy_table u_busy_table(
    .clk                         (clk                         ),
    .reset_n                     (reset_n                     ),
    .disp2bt_instr0rs1_rdaddr    (disp2bt_instr0rs1_rdaddr    ),
    .bt2disp_instr0rs1_busy      (bt2disp_instr0rs1_busy      ),
    .disp2bt_instr0rs2_rdaddr    (disp2bt_instr0rs2_rdaddr    ),
    .bt2disp_instr0rs2_busy      (bt2disp_instr0rs2_busy      ),
    .disp2bt_instr1rs1_rdaddr    ( ),
    .bt2disp_instr1rs1_busy      ( ),
    .disp2bt_instr1rs2_rdaddr    ( ),
    .bt2disp_instr1rs2_busy      ( ),
    .disp2bt_alloc_instr0rd_en   (disp2bt_alloc_instr0rd_en   ),
    .disp2bt_alloc_instr0rd_addr (disp2bt_alloc_instr0rd_addr ),
    .disp2bt_alloc_instr1rd_en   (),
    .disp2bt_alloc_instr1rd_addr (),
    .intwb2bt_free_instr0rd_en   (intwb2bt_free_instr0rd_en   ),
    .intwb2bt_free_instr0rd_addr (intwb2bt_free_instr0rd_addr ),
    .memwb2bt_free_instr0rd_en   (memwb2bt_free_instr0rd_en   ),
    .memwb2bt_free_instr0rd_addr (memwb2bt_free_instr0rd_addr ),
    .flush_valid                 (flush_valid                 ),
    .flush_id                    (flush_id                    ),
    .rob_state                   (rob_state                   ),
    .walking_valid0              (walking_valid0              ),
    .walking_valid1              (walking_valid1              ),
    .walking_prd0                (walking_prd0                ),
    .walking_prd1                (walking_prd1                ),
    .walking_complete0           (walking_complete0           ),
    .walking_complete1           (walking_complete1           )
);

pregfile_64x64_2r2w u_pregfile_64x64_2r2w(
    .clk          (clk          ),
    .reset_n      (reset_n      ),
    .wren0        (wren0        ),
    .waddr0       (waddr0       ),
    .wdata0       (wdata0       ),
    .wren1        (wren1        ),
    .waddr1       (waddr1       ),
    .wdata1       (wdata1       ),
    //READ PORT
    .rden0        (intisq2prf_instr0_src1_is_reg        ),
    .raddr0       (intisq2prf_inst0_prs1       ),
    .rdata0       (prf2exu_src1       ),
    .rden1        (intisq2prf_instr0_src2_is_re        ),
    .raddr1       (intisq2prf_inst0_prs2       ),
    .rdata1       (prf2exu_src2       ),
    .debug_preg0  (debug_preg0  ),
    .debug_preg1  (debug_preg1  ),
    .debug_preg2  (debug_preg2  ),
    .debug_preg3  (debug_preg3  ),
    .debug_preg4  (debug_preg4  ),
    .debug_preg5  (debug_preg5  ),
    .debug_preg6  (debug_preg6  ),
    .debug_preg7  (debug_preg7  ),
    .debug_preg8  (debug_preg8  ),
    .debug_preg9  (debug_preg9  ),
    .debug_preg10 (debug_preg10 ),
    .debug_preg11 (debug_preg11 ),
    .debug_preg12 (debug_preg12 ),
    .debug_preg13 (debug_preg13 ),
    .debug_preg14 (debug_preg14 ),
    .debug_preg15 (debug_preg15 ),
    .debug_preg16 (debug_preg16 ),
    .debug_preg17 (debug_preg17 ),
    .debug_preg18 (debug_preg18 ),
    .debug_preg19 (debug_preg19 ),
    .debug_preg20 (debug_preg20 ),
    .debug_preg21 (debug_preg21 ),
    .debug_preg22 (debug_preg22 ),
    .debug_preg23 (debug_preg23 ),
    .debug_preg24 (debug_preg24 ),
    .debug_preg25 (debug_preg25 ),
    .debug_preg26 (debug_preg26 ),
    .debug_preg27 (debug_preg27 ),
    .debug_preg28 (debug_preg28 ),
    .debug_preg29 (debug_preg29 ),
    .debug_preg30 (debug_preg30 ),
    .debug_preg31 (debug_preg31 )
);


endmodule


