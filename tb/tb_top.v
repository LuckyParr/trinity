`include "defines.sv"
module tb_top (
    input wire [3:0] a,
    output wire [3:0] b,

    input wire clock,
    input wire reset_n
);
    assign b[3:0] = a+4'b1;
    initial begin
        $display("heell");
        // $finish;
    end
        /* verilator lint_off PINMISSING */
    /* verilator lint_off UNUSEDSIGNAL */
    /* verilator lint_off UNDRIVEN */
// Ready signals





    // Ready signals
    reg iq_can_alloc0;
    reg iq_can_alloc1;
    reg sq_can_alloc;

    // ROB enqueue logic - instr0
    reg  instr0_enq_valid;
    reg  [`PC_RANGE]   instr0_pc;
    reg  [31:0]        instr0;
    // Removed lrs1/lrs2 from the interface
    reg  [`LREG_RANGE] instr0_lrd;
    reg  [`PREG_RANGE] instr0_prd;
    reg  [`PREG_RANGE] instr0_old_prd;
    reg               instr0_need_to_wb;

    // ROB enqueue logic - instr1
    reg  instr1_enq_valid;
    reg  [`PC_RANGE]   instr1_pc;
    reg  [31:0]        instr1;
    // Removed lrs1/lrs2 from the interface
    reg  [`LREG_RANGE] instr1_lrd;
    reg  [`PREG_RANGE] instr1_prd;
    reg  [`PREG_RANGE] instr1_old_prd;
    reg               instr1_need_to_wb;

    // rob_counter
    wire [`ROB_SIZE_LOG-1:0] rob_counter;

    // instr_robid
    wire [`ROB_SIZE_LOG:0] instr_robid;

    // Writeback ports
    reg                    intb_writeback0_valid;
    reg  [`ROB_SIZE_LOG:0] intb_writeback0_robid;
    // removed writeback0_need_to_wb from interface

    reg                    memb_writeback0_valid;
    reg  [`ROB_SIZE_LOG:0] memb_writeback0_robid;
    reg                    memb_writeback0_mmio;

    reg                    intb_writeback1_valid;
    reg  [`ROB_SIZE_LOG:0] intb_writeback1_robid;

    // Commit ports (outputs)
    wire                     commit0_valid;
    wire [`PC_RANGE]         commit0_pc;
    wire [31:0]              commit0_instr;
    wire [`LREG_RANGE]       commit0_lrd;
    wire [`PREG_RANGE]       commit0_prd;
    wire [`PREG_RANGE]       commit0_old_prd;
    wire                     commit0_need_to_wb;
    wire [`ROB_SIZE_LOG:0]   commit0_robid;
    wire                     commit0_skip;

    wire                     commit1_valid;
    wire [`PC_RANGE]         commit1_pc;
    wire [31:0]              commit1_instr;
    wire [`LREG_RANGE]       commit1_lrd;
    wire [`PREG_RANGE]       commit1_prd;
    wire [`PREG_RANGE]       commit1_old_prd;
    wire [`ROB_SIZE_LOG:0]   commit1_robid;
    wire                     commit1_need_to_wb;
    wire                     commit1_skip;

    // Flush
    reg                    flush_valid;
    reg  [`ROB_SIZE_LOG:0] flush_robid; 
    // (Removed flush_target from interface)

    // Walk logic
    wire [1:0]             rob_state;
    wire                   rob_walk0_valid;
    wire                   rob_walk0_complete;
    wire [`LREG_RANGE]     rob_walk0_lrd;
    wire [`PREG_RANGE]     rob_walk0_prd;
    wire                   rob_walk1_valid;
    wire [`LREG_RANGE]     rob_walk1_lrd;
    wire [`PREG_RANGE]     rob_walk1_prd;
    wire                   rob_walk1_complete;

    // -------------------------------------------------------------------------
    // 2) DUT Instantiation (rob)
    // -------------------------------------------------------------------------
    rob u_rob (
        .clock                  (clock),
        .reset_n                (reset_n),

        // Ready signals
        .iq_can_alloc0          (iq_can_alloc0),
        .iq_can_alloc1          (iq_can_alloc1),
        .sq_can_alloc           (sq_can_alloc),

        // Enqueue instr0
        .instr0_enq_valid       (instr0_enq_valid),
        .instr0_pc              (instr0_pc),
        .instr0                 (instr0),
        .instr0_lrd             (instr0_lrd),
        .instr0_prd             (instr0_prd),
        .instr0_old_prd         (instr0_old_prd),
        .instr0_need_to_wb      (instr0_need_to_wb),

        // Enqueue instr1
        .instr1_enq_valid       (instr1_enq_valid),
        .instr1_pc              (instr1_pc),
        .instr1                 (instr1),
        .instr1_lrd             (instr1_lrd),
        .instr1_prd             (instr1_prd),
        .instr1_old_prd         (instr1_old_prd),
        .instr1_need_to_wb      (instr1_need_to_wb),

        // rob_counter
        .rob_counter            (rob_counter),

        // instr_robid
        .instr_robid            (instr_robid),

        // Writeback ports
        .intb_writeback0_valid  (intb_writeback0_valid),
        .intb_writeback0_robid  (intb_writeback0_robid),
        .memb_writeback0_valid  (memb_writeback0_valid),
        .memb_writeback0_robid  (memb_writeback0_robid),
        .memb_writeback0_mmio   (memb_writeback0_mmio),
        .intb_writeback1_valid  (intb_writeback1_valid),
        .intb_writeback1_robid  (intb_writeback1_robid),

        // Commit ports
        .commit0_valid          (commit0_valid),
        .commit0_pc             (commit0_pc),
        .commit0_instr          (commit0_instr),
        .commit0_lrd            (commit0_lrd),
        .commit0_prd            (commit0_prd),
        .commit0_old_prd        (commit0_old_prd),
        .commit0_need_to_wb     (commit0_need_to_wb),
        .commit0_robid          (commit0_robid),
        .commit0_skip           (commit0_skip),

        .commit1_valid          (commit1_valid),
        .commit1_pc             (commit1_pc),
        .commit1_instr          (commit1_instr),
        .commit1_lrd            (commit1_lrd),
        .commit1_prd            (commit1_prd),
        .commit1_old_prd        (commit1_old_prd),
        .commit1_robid          (commit1_robid),
        .commit1_need_to_wb     (commit1_need_to_wb),
        .commit1_skip           (commit1_skip),

        // Flush
        .flush_valid            (flush_valid),
        .flush_robid            (flush_robid),

        // Walk logic
        .rob_state              (rob_state),
        .rob_walk0_valid        (rob_walk0_valid),
        .rob_walk0_complete     (rob_walk0_complete),
        .rob_walk0_lrd          (rob_walk0_lrd),
        .rob_walk0_prd          (rob_walk0_prd),
        .rob_walk1_valid        (rob_walk1_valid),
        .rob_walk1_lrd          (rob_walk1_lrd),
        .rob_walk1_prd          (rob_walk1_prd),
        .rob_walk1_complete     (rob_walk1_complete)
    );







        /* verilator lint_off PINMISSING */
    /* verilator lint_off UNUSEDSIGNAL */
    /* verilator lint_off UNDRIVEN */
endmodule
