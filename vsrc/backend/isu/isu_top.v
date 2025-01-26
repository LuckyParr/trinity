module isu_top (
    //---------------------------------------------------------------------------
    // Global signals
    //---------------------------------------------------------------------------
    input  wire clock,
    input  wire reset_n,

    //---------------------------------------------------------------------------
    // Inputs from rename stage (instr0)
    //---------------------------------------------------------------------------
    input  wire               pipe2isu_instr0_valid,
    output wire               isu2pipe_instr0_ready, // from Dispatch
    input  wire [  `PC_RANGE] instr0_pc,
    input  wire [31:0]        instr0,
    input  wire [`LREG_RANGE] instr0_lrs1,
    input  wire [`LREG_RANGE] instr0_lrs2,
    input  wire [`LREG_RANGE] instr0_lrd,
    input  wire [`PREG_RANGE] instr0_prd,
    input  wire [`PREG_RANGE] instr0_old_prd,
    input  wire               instr0_need_to_wb,

    // Additional signals from rename for instr0
    input wire [`PREG_RANGE]        instr0_prs1,
    input wire [`PREG_RANGE]        instr0_prs2,
    input wire                      instr0_src1_is_reg,
    input wire                      instr0_src2_is_reg,
    input wire [63:0]               instr0_imm,
    input wire [`CX_TYPE_RANGE]     instr0_cx_type,
    input wire                      instr0_is_unsigned,
    input wire [`ALU_TYPE_RANGE]    instr0_alu_type,
    input wire [`MULDIV_TYPE_RANGE] instr0_muldiv_type,
    input wire                      instr0_is_word,
    input wire                      instr0_is_imm,
    input wire                      instr0_is_load,
    input wire                      instr0_is_store,
    input wire [3:0]                instr0_ls_size,

    //---------------------------------------------------------------------------
    // Inputs from rename stage (instr1)
    //---------------------------------------------------------------------------
    input  wire               pipe2isu_instr1_valid,
    output wire               isu2pipe_instr1_ready, // from Dispatch
    input  wire [  `PC_RANGE] instr1_pc,
    input  wire [31:0]        instr1,
    input  wire [`LREG_RANGE] instr1_lrs1,
    input  wire [`LREG_RANGE] instr1_lrs2,
    input  wire [`LREG_RANGE] instr1_lrd,
    input  wire [`PREG_RANGE] instr1_prd,
    input  wire [`PREG_RANGE] instr1_old_prd,
    input  wire               instr1_need_to_wb,

    // Additional signals from rename for instr1
    input wire [`PREG_RANGE]        instr1_prs1,
    input wire [`PREG_RANGE]        instr1_prs2,
    input wire                      instr1_src1_is_reg,
    input wire                      instr1_src2_is_reg,
    input wire [63:0]               instr1_imm,
    input wire [`CX_TYPE_RANGE]     instr1_cx_type,
    input wire                      instr1_is_unsigned,
    input wire [`ALU_TYPE_RANGE]    instr1_alu_type,
    input wire [`MULDIV_TYPE_RANGE] instr1_muldiv_type,
    input wire                      instr1_is_word,
    input wire                      instr1_is_imm,
    input wire                      instr1_is_load,
    input wire                      instr1_is_store,
    input wire [3:0]                instr1_ls_size,

    //---------------------------------------------------------------------------
    // Inputs from ROB to Dispatch
    //---------------------------------------------------------------------------
    input  wire [`INSTR_ID_WIDTH-1:0] rob2disp_instr_cnt, // 7 bits
    input  wire [`INSTR_ID_WIDTH-1:0] rob2disp_instr_id,  // 7 bits



    //---------------------------------------------------------------------------
    // Dispatch <-> Busy Vector signals
    //---------------------------------------------------------------------------
    // Busy vector read ports (4 read ports)
    output wire [5:0] disp2bt_instr0rs1_rdaddr,
    input  wire       bt2disp_instr0rs1_busy,

    output wire [5:0] disp2bt_instr0rs2_rdaddr,
    input  wire       bt2disp_instr0rs2_busy,

    output wire [5:0] disp2bt_instr1rs1_rdaddr,
    input  wire       bt2disp_instr1rs1_busy,

    output wire [5:0] disp2bt_instr1rs2_rdaddr,
    input  wire       bt2disp_instr1rs2_busy,

    // Busy vector write ports (allocate)
    output wire       disp2bt_alloc_instr0rd_en,
    output wire [5:0] disp2bt_alloc_instr0rd_addr,
    output wire       disp2bt_alloc_instr1rd_en,
    output wire [5:0] disp2bt_alloc_instr1rd_addr,

    // Freed bits (2 free writes) from commit or elsewhere
    input  wire       intwb2bt_free_instr0rd_en,
    input  wire [5:0] intwb2bt_free_instr0rd_addr,
    input  wire       memwb2bt_free_instr0rd_en,
    input  wire [5:0] memwb2bt_free_instr0rd_addr,

    //---------------------------------------------------------------------------
    // Dispatch -> Issue Queue signals
    //---------------------------------------------------------------------------
    output wire              disp2isq_instr0_wren,
    output wire [230:0]      disp2isq_instr0_entrydata,

    //---------------------------------------------------------------------------
    // Issue Queue <-> PRF signals
    //---------------------------------------------------------------------------
    output wire               isq2prf_prs1_rden,
    output wire [`PREG_RANGE] isq2prf_prs1_rdaddr,
    input  wire [63:0]        prf2isq_prs1_rddata,

    output wire               isq2prf_prs2_rden,
    output wire [`PREG_RANGE] isq2prf_prs2_rdaddr,
    input  wire [63:0]        prf2isq_prs2_rddata,

    //---------------------------------------------------------------------------
    // Issue Queue -> FU signals
    //---------------------------------------------------------------------------
    // We assume a single instruction out for example.
    output wire               instr0_valid,  // queue side says valid
    input  wire               instr0_ready,  // FU side ready/back-pressure

    output wire [63:0]        instr0_src1,
    output wire [63:0]        instr0_src2,
    output wire [`INSTR_ID_WIDTH-1:0] instr0_id,
    output wire [`PC_RANGE]   instr0_pc_out,
    output wire [`PREG_RANGE] instr0_prd_out,
    output wire [63:0]        instr0_imm_out,
    output wire               instr0_need_to_wb_out,
    output wire [`CX_TYPE_RANGE]     instr0_cx_type_out,
    output wire               instr0_is_unsigned_out,
    output wire [`ALU_TYPE_RANGE]    instr0_alu_type_out,
    output wire [`MULDIV_TYPE_RANGE] instr0_muldiv_type_out,
    output wire               instr0_is_word_out,
    output wire               instr0_is_imm_out,
    output wire               instr0_is_load_out,
    output wire               instr0_is_store_out,
    output wire [3:0]         instr0_ls_size_out,
    output wire [31:0]        instr0_debug_out,

    //---------------------------------------------------------------------------
    // ROB <-> Completion signals
    //---------------------------------------------------------------------------
    input  wire                       complete_wren0,
    input  wire [`INSTR_ID_WIDTH-1:0] complete_wraddr0,
    input  wire [0:0]                 complete_wrdata0, // e.g. bit=1 => complete

    input  wire                       complete_wren1,
    input  wire [`INSTR_ID_WIDTH-1:0] complete_wraddr1,
    input  wire [0:0]                 complete_wrdata1,

    //---------------------------------------------------------------------------
    // ROB -> Freed Physical Register Indication
    //---------------------------------------------------------------------------
    output wire               rob2fl_commit_valid0,
    output wire [5:0]         rob2fl_commit_old_prd,
    output wire               rob2specrat_commit0_valid,
    output wire               rob2specrat_commit0_need_to_wb,
    output wire [`LREG_RANGE] rob2specrat_commit0_lrd,
    output wire [`PREG_RANGE] rob2specrat_commit0_prd,
    output wire               rob2specrat_commit1_valid,
    output wire               rob2specrat_commit1_need_to_wb,
    output wire [`LREG_RANGE] rob2specrat_commit1_lrd,
    output wire [`PREG_RANGE] rob2specrat_commit1_prd,

    //---------------------------------------------------------------------------
    // Flush & Walk signals
    //---------------------------------------------------------------------------
    input  wire                       flush_valid,
    input  wire [63:0]               flush_target,
    input  wire [`INSTR_ID_WIDTH-1:0] flush_id,

    output wire is_idle,
    output wire is_rollingback,
    output wire is_walking,
    output wire walking_valid0,
    output wire walking_valid1,
    output wire [5:0] walking_prd0,
    output wire [5:0] walking_prd1,
    output wire walking_complete0,
    output wire walking_complete1,
    output wire [4:0] walking_lrd0,
    output wire [4:0] walking_lrd1,
    output wire [5:0] walking_old_prd0,
    output wire [5:0] walking_old_prd1,

    //---------------------------------------------------------------------------
    // Physical Register File: 2R2W
    //---------------------------------------------------------------------------
    input  wire         pregfile_wren0,
    input  wire [5:0]   pregfile_waddr0,
    input  wire [63:0]  pregfile_wdata0,

    input  wire         pregfile_wren1,
    input  wire [5:0]   pregfile_waddr1,
    input  wire [63:0]  pregfile_wdata1,

    // PRF debug signals
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


assign isu2pipe_instr0_ready  = disp_instr0_ready;
assign disp_instr0_valid = pipe2isu_instr0_valid;



// Outputs from Dispatch to ROB
    wire                      disp2rob_instr0_valid    ;
    wire [123:0]              disp2rob_instr0_entrydata;
    wire                      disp2rob_instr1_valid    ;
    wire [123:0]              disp2rob_instr1_entrydata;


// --------------------------------------------------------------------------
// 1) Dispatch
// --------------------------------------------------------------------------
dispatch dispatch_inst (
    .clock(clock),
    .reset_n(reset_n),

    // from rename for instr0
    .disp_instr0_valid(pipe2isu_instr0_valid),//i
    .disp_instr0_ready(isu2pipe_instr0_ready),//output
    .instr0_pc        (instr0_pc            ),//i
    .instr0           (instr0               ),//i
    .instr0_lrs1      (instr0_lrs1          ),//i
    .instr0_lrs2      (instr0_lrs2          ),//i
    .instr0_lrd       (instr0_lrd           ),//i
    .instr0_prd       (instr0_prd           ),//i
    .instr0_old_prd   (instr0_old_prd       ),//i
    .instr0_need_to_wb(instr0_need_to_wb    ),//i

    .instr0_prs1       (instr0_prs1       ),
    .instr0_prs2       (instr0_prs2       ),
    .instr0_src1_is_reg(instr0_src1_is_reg),
    .instr0_src2_is_reg(instr0_src2_is_reg),
    .instr0_imm        (instr0_imm        ),
    .instr0_cx_type    (instr0_cx_type    ),
    .instr0_is_unsigned(instr0_is_unsigned),
    .instr0_alu_type   (instr0_alu_type   ),
    .instr0_muldiv_type(instr0_muldiv_type),
    .instr0_is_word    (instr0_is_word    ),
    .instr0_is_imm     (instr0_is_imm     ),
    .instr0_is_load    (instr0_is_load    ),
    .instr0_is_store   (instr0_is_store   ),
    .instr0_ls_size    (instr0_ls_size    ),

    // from rename for instr1
    .disp_instr1_valid(),
    .disp_instr1_ready(),
    .instr1_pc        (),
    .instr1           (),
    .instr1_lrs1      (),
    .instr1_lrs2      (),
    .instr1_lrd       (),
    .instr1_prd       (),
    .instr1_old_prd   (),
    .instr1_need_to_wb(),

    .instr1_prs1       (),
    .instr1_prs2       (),
    .instr1_src1_is_reg(),
    .instr1_src2_is_reg(),
    .instr1_imm        (),
    .instr1_cx_type    (),
    .instr1_is_unsigned(),
    .instr1_alu_type   (),
    .instr1_muldiv_type(),
    .instr1_is_word    (),
    .instr1_is_imm     (),
    .instr1_is_load    (),
    .instr1_is_store   (),
    .instr1_ls_size    (),

    // from ROB
    .rob2disp_instr_cnt(rob2disp_instr_cnt),//i
    .rob2disp_instr_id(rob2disp_instr_id  ),//i

    // disp write robentry to ROB
    .disp2rob_instr0_valid    (disp2rob_instr0_valid    ),
    .disp2rob_instr0_entrydata(disp2rob_instr0_entrydata),
    .disp2rob_instr1_valid    (),
    .disp2rob_instr1_entrydata(),

    // to busy_vector
    .disp2bt_instr0rs1_rdaddr(disp2bt_instr0rs1_rdaddr),
    .bt2disp_instr0rs1_busy  (bt2disp_instr0rs1_busy  ),
    .disp2bt_instr0rs2_rdaddr(disp2bt_instr0rs2_rdaddr),
    .bt2disp_instr0rs2_busy  (bt2disp_instr0rs2_busy  ),
    .disp2bt_instr1rs1_rdaddr(disp2bt_instr1rs1_rdaddr),
    .bt2disp_instr1rs1_busy  (bt2disp_instr1rs1_busy  ),
    .disp2bt_instr1rs2_rdaddr(disp2bt_instr1rs2_rdaddr),
    .bt2disp_instr1rs2_busy  (bt2disp_instr1rs2_busy  ),

    .disp2bt_alloc_instr0rd_en(disp2bt_alloc_instr0rd_en),
    .disp2bt_alloc_instr0rd_addr(disp2bt_alloc_instr0rd_addr),
    .disp2bt_alloc_instr1rd_en(disp2bt_alloc_instr1rd_en),
    .disp2bt_alloc_instr1rd_addr(disp2bt_alloc_instr1rd_addr),

    // to Issue Queue
    .disp2isq_instr0_wren(disp2isq_instr0_wren),
    .disp2isq_instr0_entrydata(disp2isq_instr0_entrydata)
);

//
// --------------------------------------------------------------------------
// 2) Busy Table
// --------------------------------------------------------------------------
busy_table busy_table_inst (
    .clk(clock),
    .reset_n(reset_n),

    // read ports
    .disp2bt_instr0rs1_rdaddr(disp2bt_instr0rs1_rdaddr),
    .bt2disp_instr0rs1_busy(bt2disp_instr0rs1_busy),
    .disp2bt_instr0rs2_rdaddr(disp2bt_instr0rs2_rdaddr),
    .bt2disp_instr0rs2_busy(bt2disp_instr0rs2_busy),
    .disp2bt_instr1rs1_rdaddr(disp2bt_instr1rs1_rdaddr),
    .bt2disp_instr1rs1_busy(bt2disp_instr1rs1_busy),
    .disp2bt_instr1rs2_rdaddr(disp2bt_instr1rs2_rdaddr),
    .bt2disp_instr1rs2_busy(bt2disp_instr1rs2_busy),

    // allocate
    .disp2bt_alloc_instr0rd_en(disp2bt_alloc_instr0rd_en),
    .disp2bt_alloc_instr0rd_addr(disp2bt_alloc_instr0rd_addr),
    .disp2bt_alloc_instr1rd_en(disp2bt_alloc_instr1rd_en),
    .disp2bt_alloc_instr1rd_addr(disp2bt_alloc_instr1rd_addr),

    // free
    .intwb2bt_free_instr0rd_en  (intwb2bt_free_instr0rd_en  ),
    .intwb2bt_free_instr0rd_addr(intwb2bt_free_instr0rd_addr),
    .memwb2bt_free_instr0rd_en  (memwb2bt_free_instr0rd_en  ),
    .memwb2bt_free_instr0rd_addr(memwb2bt_free_instr0rd_addr),

    // flush & walk logic from ROB
    .flush_valid(flush_valid),
    .flush_id(flush_id),
    .is_idle(is_idle),
    .is_rollingback(is_rollingback),
    .is_walking(is_walking),
    .walking_valid0(walking_valid0),
    .walking_valid1(walking_valid1),
    .walking_prd0(walking_prd0),
    .walking_prd1(walking_prd1),
    .walking_complete0(walking_complete0),
    .walking_complete1(walking_complete1)
);

//
// --------------------------------------------------------------------------
// 3) Issue Queue (with new interface)
// --------------------------------------------------------------------------
issue_queue #(
    .ISSUE_QUEUE_DEPTH     (8),
    .ISSUE_QUEUE_DEPTH_LOG (3),
    .DATA_WIDTH            (248)
) issue_queue_inst (
    .clock           (clock),
    .reset_n         (reset_n),

    // Write interface (from Dispatch)
    .wr_data         (disp2isq_instr0_entrydata), // 248-bit instruction package
    .wr_rs1_sleepbit (1'b0),             // or from your dispatch logic
    .wr_rs2_sleepbit (1'b0),             // or from your dispatch logic
    .wr_valid        (disp2isq_instr0_wren),   // rename -> dispatch -> issueq handshake
    .wr_ready        (/* unconnected or wire out if needed */),
    .queue_full      (/* unconnected or wire out if needed */),

    // Wake-up interface (for RS1, RS2) from completion or broadcast
    .wake_rs1_index  ({ISSUE_QUEUE_DEPTH_LOG{1'b0}}), // example
    .wake_rs1_enable (1'b0),
    .wake_rs2_index  ({ISSUE_QUEUE_DEPTH_LOG{1'b0}}), // example
    .wake_rs2_enable (1'b0),

    // Read interface
    .rd_valid        (/* internally used to drive instr0_valid; see below */),
    .rd_ready        (intblock_ready & memblock_ready),  // !!! The FU signals 'ready' to accept next
    .rd_data         (/* internally used, or can be exposed if you prefer */),

    // PRF read
    .isq2prf_prs1_rden   (isq2prf_prs1_rden),
    .isq2prf_prs1_rdaddr (isq2prf_prs1_rdaddr),
    .prf2isq_prs1_rddata (prf2isq_prs1_rddata),

    .isq2prf_prs2_rden   (isq2prf_prs2_rden),
    .isq2prf_prs2_rdaddr (isq2prf_prs2_rdaddr),
    .prf2isq_prs2_rddata (prf2isq_prs2_rddata),

    // Info to the FU
    .instr0_valid        (instr0_valid),   // from queue out
    .instr0_ready        (instr0_ready),   // handshake from FU
    .instr0_src1         (instr0_src1),
    .instr0_src2         (instr0_src2),
    .instr0_id           (instr0_id),
    .instr0_pc           (instr0_pc_out),
    .instr0_prd          (instr0_prd_out),
    .instr0_imm          (instr0_imm_out),
    .instr0_need_to_wb   (instr0_need_to_wb_out),
    .instr0_cx_type      (instr0_cx_type_out),
    .instr0_is_unsigned  (instr0_is_unsigned_out),
    .instr0_alu_type     (instr0_alu_type_out),
    .instr0_muldiv_type  (instr0_muldiv_type_out),
    .instr0_is_word      (instr0_is_word_out),
    .instr0_is_imm       (instr0_is_imm_out),
    .instr0_is_load      (instr0_is_load_out),
    .instr0_is_store     (instr0_is_store_out),
    .instr0_ls_size      (instr0_ls_size_out),
    .instr0              (instr0_debug_out),

    // flush & walk logic
    .flush_valid         (flush_valid),
    .flush_id            (flush_id),
    .is_idle             (is_idle),
    .is_rollingback      (is_rollingback),
    .is_walking          (is_walking),
    .walking_valid0      (walking_valid0),
    .walking_valid1      (walking_valid1)
);

//
// --------------------------------------------------------------------------
// 4) Physical Register File (2R2W, 64 entries, 64-bit each)
// --------------------------------------------------------------------------
pregfile_64x64_2r2w pregfile_inst (
    .clk        (clock),
    .reset_n    (reset_n),

    // Write port 0
    .wren0      (pregfile_wren0),
    .waddr0     (pregfile_waddr0),
    .wdata0     (pregfile_wdata0),

    // Write port 1
    .wren1      (pregfile_wren1),
    .waddr1     (pregfile_waddr1),
    .wdata1     (pregfile_wdata1),

    // Read port 0
    .rden0      (isq2prf_prs1_rden),
    .raddr0     (isq2prf_prs1_rdaddr),
    .rdata0     (prf2isq_prs1_rddata),

    // Read port 1
    .rden1      (isq2prf_prs2_rden),
    .raddr1     (isq2prf_prs2_rdaddr),
    .rdata1     (prf2isq_prs2_rddata),

    // debug signals
    .debug_preg0 (debug_preg0),
    .debug_preg1 (debug_preg1),
    .debug_preg2 (debug_preg2),
    .debug_preg3 (debug_preg3),
    .debug_preg4 (debug_preg4),
    .debug_preg5 (debug_preg5),
    .debug_preg6 (debug_preg6),
    .debug_preg7 (debug_preg7),
    .debug_preg8 (debug_preg8),
    .debug_preg9 (debug_preg9),
    .debug_preg10(debug_preg10),
    .debug_preg11(debug_preg11),
    .debug_preg12(debug_preg12),
    .debug_preg13(debug_preg13),
    .debug_preg14(debug_preg14),
    .debug_preg15(debug_preg15),
    .debug_preg16(debug_preg16),
    .debug_preg17(debug_preg17),
    .debug_preg18(debug_preg18),
    .debug_preg19(debug_preg19),
    .debug_preg20(debug_preg20),
    .debug_preg21(debug_preg21),
    .debug_preg22(debug_preg22),
    .debug_preg23(debug_preg23),
    .debug_preg24(debug_preg24),
    .debug_preg25(debug_preg25),
    .debug_preg26(debug_preg26),
    .debug_preg27(debug_preg27),
    .debug_preg28(debug_preg28),
    .debug_preg29(debug_preg29),
    .debug_preg30(debug_preg30),
    .debug_preg31(debug_preg31)
);

//
// --------------------------------------------------------------------------
// 5) Reorder Buffer (ROB)
// --------------------------------------------------------------------------
rob #(
    .DATA_WIDTH    (124),
    .DEPTH         (64),
    .STATUS_WIDTH  (1),
    .DEPTH_LOG     (6),
    .ADDR_WIDTH    ($clog2(64)),
    .INDEX_WIDTH   ($clog2(64) + 1)
) rob_inst (
    .clock                  (clock),
    .reset_n                (reset_n),

    // Write Port 0
    .disp2rob_instr0_valid                   (disp2rob_instr0_valid    ),
    .disp2rob_instr0_entrydata               (disp2rob_instr0_entrydata),
    // Write Port 1
    .disp2rob_instr1_valid                   (),
    .disp2rob_instr1_entrydata               (),

    // Status writes (from FU completion)
    .complete_wren0         (complete_wren0),
    .complete_wraddr0       (complete_wraddr0),
    .complete_wrdata0       (complete_wrdata0),
    .complete_wren1         (complete_wren1),
    .complete_wraddr1       (complete_wraddr1),
    .complete_wrdata1       (complete_wrdata1),

    // Commit port
    .rob2fl_commit_valid0   (rob2fl_commit_valid0),
    .rob2fl_commit_old_prd  (rob2fl_commit_old_prd),

    .rob2specrat_commit0_valid     (rob2specrat_commit0_valid),
    .rob2specrat_commit0_need_to_wb(rob2specrat_commit0_need_to_wb),
    .rob2specrat_commit0_lrd       (rob2specrat_commit0_lrd),
    .rob2specrat_commit0_prd       (rob2specrat_commit0_prd),

    .rob2specrat_commit1_valid     (rob2specrat_commit1_valid),
    .rob2specrat_commit1_need_to_wb(rob2specrat_commit1_need_to_wb),
    .rob2specrat_commit1_lrd       (rob2specrat_commit1_lrd),
    .rob2specrat_commit1_prd       (rob2specrat_commit1_prd),

    // For Dispatch
    .rob2disp_instr_cnt      (rob2disp_instr_cnt),
    .rob2disp_instr_id       (rob2disp_instr_id),

    // flush
    .flush_valid             (flush_valid),
    .flush_target            (flush_target),
    .flush_id                (flush_id),

    // walk
    .is_idle                 (is_idle),
    .is_rollingback          (is_rollingback),
    .is_walking              (is_walking),
    .walking_valid0          (walking_valid0),
    .walking_valid1          (walking_valid1),
    .walking_prd0            (walking_prd0),
    .walking_prd1            (walking_prd1),
    .walking_complete0       (walking_complete0),
    .walking_complete1       (walking_complete1),
    .walking_lrd0            (walking_lrd0),
    .walking_lrd1            (walking_lrd1),
    .walking_old_prd0        (walking_old_prd0),
    .walking_old_prd1        (walking_old_prd1)
);

endmodule
`endif
