`include "defines.sv"
module core_top #(
        parameter BHTBTB_INDEX_WIDTH = 9           // Width of the set index (for SETS=512, BHTBTB_INDEX_WIDTH=9)
) (
    input wire clock,
    input wire reset_n,

    // DDR Control Inputs and Outputs
    output wire         ddr_chip_enable,     // Enables chip for one cycle when a channel is selected
    output wire [ 63:0] ddr_index,           // 19-bit selected index to be sent to DDR
    output wire         ddr_write_enable,    // Write enable signal (1 for write, 0 for read)
    output wire         ddr_burst_mode,      // Burst mode signal, 1 when pc_index is selected
    output wire [511:0] ddr_write_data,      // Output write data for opstore channel
    input  wire [511:0] ddr_read_data,       // 64-bit data output for lw channel read
    input  wire         ddr_operation_done,
    input  wire         ddr_ready,           // Indicates if DDR is ready for new operation
    output reg          flop_commit_valid
);
    //bhtbtb write interface
    //BHT Write Interface
    wire                   wb_bht_write_enable        ;                         // Write enable signal
    wire [BHTBTB_INDEX_WIDTH-1:0] wb_bht_write_index         ;        // Set index for write operation
    wire [1:0]             wb_bht_write_counter_select;           // Counter select (0 to 3) within the set
    wire                   wb_bht_write_inc           ;                            // Increment signal for the counter
    wire                   wb_bht_write_dec           ;                            // Decrement signal for the counter
    wire                   wb_bht_valid_in            ;                             // Valid signal for the write operation
    //BTB Write Interface
    wire         wb_btb_ce   ;                    // Chip enable
    wire         wb_btb_we   ;                    // Write enable
    wire [128:0] wb_btb_wmask;
    wire [8:0]   wb_btb_write_index;           // Write address (9 bits for 512 sets)
    wire [128:0] wb_btb_din  ;        // Data input (1 valid bit + 4 targets * 32 bits)


    wire                      chip_enable = 1'b1;
    wire [       `LREG_RANGE] rs1;
    wire [       `LREG_RANGE] rs2;
    wire [       `LREG_RANGE] rd;
    wire [        `SRC_RANGE] src1;
    wire [        `SRC_RANGE] src2;
    wire [        `SRC_RANGE] imm;
    wire                      src1_is_reg;
    wire                      src2_is_reg;
    wire                      need_to_wb;
    wire [    `CX_TYPE_RANGE] cx_type;
    wire                      is_unsigned;
    wire [   `ALU_TYPE_RANGE] alu_type;
    wire                      is_word;
    wire                      is_load;
    wire                      is_imm;
    wire                      is_store;
    wire [               3:0] ls_size;
    wire [`MULDIV_TYPE_RANGE] muldiv_type;
    wire [         `PC_RANGE] pc;
    wire [      `INSTR_RANGE] instr;

    wire                      regfile_write_valid;
    wire [     `RESULT_RANGE] regfile_write_data;
    wire [               4:0] regfile_write_rd;
    wire                      decoder_instr_valid;
    wire                      decoder_predicttaken_out;
    wire [31:0]               decoder_predicttarget_out;
    wire [              47:0] decoder_pc_out;
    wire [              31:0] decoder_inst_out;

    //redirect
    wire                      redirect_valid;
    wire [         `PC_RANGE] redirect_target;
    //mem stall
    wire                      mem_stall;



    // PC Channel Inputs and Outputs
    wire                      pc_index_valid;  // Valid signal for pc_index
    wire [              63:0] pc_index;  // 64-bit input for pc_index (Channel 1)
    wire                      pc_index_ready;  // Ready signal for pc channel
    wire [`ICACHE_FETCHWIDTH128_RANGE] pc_read_inst;  // Output burst read data for pc channel
    wire                      pc_operation_done;


    //trinity bus channel:lsu to dcache
    wire                      tbus_index_valid;
    wire                      tbus_index_ready;
    wire [     `RESULT_RANGE] tbus_index;
    wire [        `SRC_RANGE] tbus_write_data;
    wire [              63:0] tbus_write_mask;

    wire [     `RESULT_RANGE] tbus_read_data;
    wire                      tbus_operation_done;
    wire [       `TBUS_OPTYPE_RANGE] tbus_operation_type;




    wire [       `LREG_RANGE] exe_byp_rd;
    wire                      exe_byp_need_to_wb;
    wire [     `RESULT_RANGE] exe_byp_result;

    wire [       `LREG_RANGE] mem_byp_rd;
    wire                      mem_byp_need_to_wb;
    wire [     `RESULT_RANGE] mem_byp_result;




    reg                       dcache2arb_dbus_index_valid;
    wire                      dcache2arb_dbus_index_ready;
    reg  [     `RESULT_RANGE] dcache2arb_dbus_index;
    reg  [ `CACHELINE512_RANGE] dcache2arb_dbus_write_data;
    wire [ `CACHELINE512_RANGE] dcache2arb_dbus_read_data;
    wire                      dcache2arb_dbus_operation_done;
    wire [       `TBUS_OPTYPE_RANGE] dcache2arb_dbus_operation_type;
    wire                      dcache2arb_dbus_burst_mode;


    reg                       icache2arb_dbus_index_valid;
    wire                      icache2arb_dbus_index_ready;
    reg  [     `RESULT_RANGE] icache2arb_dbus_index;
    reg  [ `CACHELINE512_RANGE] icache2arb_dbus_write_data;
    reg  [        `SRC_RANGE] icache2arb_dbus_write_mask;
    wire [ `CACHELINE512_RANGE] icache2arb_dbus_read_data;
    wire                      icache2arb_dbus_operation_done;
    wire [       `TBUS_OPTYPE_RANGE] icache2arb_dbus_operation_type;
    wire                      icache2arb_dbus_burst_mode;



    dcache u_dcache (
        .clock                         (clock),
        .reset_n                       (reset_n),
        .flush                         (redirect_valid),
        //tbus channel from backend lsu (mem.v)
        .tbus_index_valid              (tbus_index_valid),
        .tbus_index_ready              (tbus_index_ready),
        .tbus_index                    (tbus_index),
        .tbus_write_data               (tbus_write_data),
        .tbus_write_mask               (tbus_write_mask),
        .tbus_read_data                (tbus_read_data),
        .tbus_operation_done           (tbus_operation_done),
        .tbus_operation_type           (tbus_operation_type),
        // dcache channel for lsu operation
        .dcache2arb_dbus_index_valid   (dcache2arb_dbus_index_valid),
        .dcache2arb_dbus_index_ready   (dcache2arb_dbus_index_ready),
        .dcache2arb_dbus_index         (dcache2arb_dbus_index),
        .dcache2arb_dbus_write_data    (dcache2arb_dbus_write_data),
        .dcache2arb_dbus_read_data     (dcache2arb_dbus_read_data),
        .dcache2arb_dbus_operation_done(dcache2arb_dbus_operation_done),
        .dcache2arb_dbus_operation_type(dcache2arb_dbus_operation_type)
    );

    icache u_icache (
        .clock                         (clock),
        .reset_n                       (reset_n),
        .flush                         (redirect_valid),
        //tbus channel from pc_ctrl
        .tbus_index_valid              (pc_index_valid),
        .tbus_index_ready              (pc_index_ready),
        .tbus_index                    (pc_index),
        .tbus_write_data               ('b0),
        .tbus_write_mask               ('b0),
        .tbus_read_data                (pc_read_inst),
        .tbus_operation_done           (pc_operation_done),
        .tbus_operation_type           (2'b00),     
        //icache channel for reading inst from ddr
        .icache2arb_dbus_index_valid   (icache2arb_dbus_index_valid),
        .icache2arb_dbus_index_ready   (icache2arb_dbus_index_ready),
        .icache2arb_dbus_index         (icache2arb_dbus_index),
        .icache2arb_dbus_write_data    (icache2arb_dbus_write_data),
        .icache2arb_dbus_read_data     (icache2arb_dbus_read_data),
        .icache2arb_dbus_operation_done(icache2arb_dbus_operation_done),
        .icache2arb_dbus_operation_type()
    );

/* ---------------------------- start change here --------------------------- */
ifu u_ifu(
    .clock                     (clock                     ),
    .reset_n                   (reset_n                   ),
    .boot_addr                 (boot_addr                 ),
    .interrupt_valid           (interrupt_valid           ),
    .interrupt_addr            (interrupt_addr            ),
    .redirect_valid            (redirect_valid            ),
    .redirect_target           (redirect_target           ),
    .pc_index_valid            (pc_index_valid            ),
    .pc_index_ready            (pc_index_ready            ),
    .pc_operation_done         (pc_operation_done         ),
    .pc_read_inst              (pc_read_inst              ),
    .fifo_read_en              (idu2ifu_instr_ready             ),//ready from pipereg_autostall, and feedthrough idu
    .ibuffer_instr_valid       (ibuffer_instr_valid       ),
    .ibuffer_predicttaken_out  (ibuffer_predicttaken_out  ),
    .ibuffer_predicttarget_out (ibuffer_predicttarget_out ),
    .ibuffer_inst_out          (ibuffer_inst_out          ),
    .ibuffer_pc_out            (ibuffer_pc_out            ),
    .fifo_empty                (fifo_empty                ),
    .pc_index                  (pc_index                  ),
    .mem_stall                 (~idu2ifu_instr_ready            ),//
    .bht_write_enable          (bht_write_enable          ),//i
    .bht_write_index           (bht_write_index           ),//i
    .bht_write_counter_select  (bht_write_counter_select  ),//i
    .bht_write_inc             (bht_write_inc             ),//i
    .bht_write_dec             (bht_write_dec             ),//i
    .bht_valid_in              (bht_valid_in              ),//i
    .btb_ce                    (btb_ce                    ),//i
    .btb_we                    (btb_we                    ),//i
    .btb_wmask                 (btb_wmask                 ),//i
    .btb_write_index           (btb_write_index           ),//i
    .btb_din                   (btb_din                   ) //i
);

idu_top u_idu_top(
    .clock                     (clock                     ),//i
    .reset_n                   (reset_n                   ),//i
    .fifo_empty                (fifo_empty                ),//i
    .ibuffer_instr_valid       (ibuffer_instr_valid       ),//i
    .ibuffer_predicttaken_out  (ibuffer_predicttaken_out  ),//i
    .ibuffer_predicttarget_out (ibuffer_predicttarget_out ),//i
    .ibuffer_inst_out          (ibuffer_inst_out          ),//i
    .ibuffer_pc_out            (ibuffer_pc_out            ),//i
    .idu2ifu_instr_ready             (idu2ifu_instr_ready),//output
    .pipe2idu_instr_ready            (pipe2idu_instr_ready),//i
    .rs1                       (idu2pipe_rs1                       ),//output
    .rs2                       (idu2pipe_rs2                       ),//output
    .rd                        (idu2pipe_rd                        ),//output
    .imm                       (idu2pipe_imm                       ),//output
    .src1_is_reg               (idu2pipe_src1_is_reg               ),//output
    .src2_is_reg               (idu2pipe_src2_is_reg               ),//output
    .need_to_wb                (idu2pipe_need_to_wb                ),//output
    .cx_type                   (idu2pipe_cx_type                   ),//output
    .is_unsigned               (idu2pipe_is_unsigned               ),//output
    .alu_type                  (idu2pipe_alu_type                  ),//output
    .is_word                   (idu2pipe_is_word                   ),//output
    .is_imm                    (idu2pipe_is_imm                    ),//output
    .is_load                   (idu2pipe_is_load                   ),//output
    .is_store                  (idu2pipe_is_store                  ),//output
    .ls_size                   (idu2pipe_ls_size                   ),//output
    .muldiv_type               (idu2pipe_muldiv_type               ),//output
    .decoder_instr_valid       (idu2pipe_instr_valid               ),//output
    .decoder_pc_out            (idu2pipe_pc_out                    ),//output
    .decoder_inst_out          (idu2pipe_instr_out                  ),//output
    .decoder_predicttaken_out  (idu2pipe_predicttaken_out          ),//output
    .decoder_predicttarget_out (idu2pipe_predicttarget_out         ) //output
);



pipereg_autostall u_pipereg_autostall_idu2iru(
    .clock                     (clock                     ),
    .reset_n                   (reset_n                   ),
    .instr_ready_to_upper      (pipe2idu_instr_ready      ),//output
    .instr_valid_from_upper    (idu2pipe_instr_valid               ),//i
    .instr                     (idu2pipe_instr                     ),//i
    .pc                        (idu2pipe_pc                        ),//i
    .lrs1                      (idu2pipe_lrs1                      ),//i
    .lrs2                      (idu2pipe_lrs2                      ),//i
    .lrd                       (idu2pipe_lrd                       ),//i
    .imm                       (idu2pipe_imm                       ),//i
    .src1_is_reg               (idu2pipe_src1_is_reg               ),//i
    .src2_is_reg               (idu2pipe_src2_is_reg               ),//i
    .need_to_wb                (idu2pipe_need_to_wb                ),//i
    .cx_type                   (idu2pipe_cx_type                   ),//i
    .is_unsigned               (idu2pipe_is_unsigned               ),//i
    .alu_type                  (idu2pipe_alu_type                  ),//i
    .is_word                   (idu2pipe_is_word                   ),//i
    .is_load                   (idu2pipe_is_load                   ),//i
    .is_imm                    (idu2pipe_is_imm                    ),//i
    .is_store                  (idu2pipe_is_store                  ),//i
    .ls_size                   (idu2pipe_ls_size                   ),//i
    .muldiv_type               (idu2pipe_muldiv_type               ),//i
    .prs1                      (),
    .prs2                      (),
    .prd                       (),
    .old_prd                   (),
    .ls_address                (),
    .alu_result                (),
    .bju_result                (),
    .muldiv_result             (),
    .opload_read_data_wb       (),
    .instr_valid_to_lower      (pipe2iru_instr_valid         ),
    .instr_ready_from_lower    (iru2pipe_instr_ready    ),//i
    .lower_lrs1                (pipe2iru_lrs1                ),
    .lower_lrs2                (pipe2iru_lrs2                ),
    .lower_lrd                 (pipe2iru_lrd                 ),
    .lower_imm                 (pipe2iru_imm                 ),
    .lower_src1_is_reg         (pipe2iru_src1_is_reg         ),
    .lower_src2_is_reg         (pipe2iru_src2_is_reg         ),
    .lower_need_to_wb          (pipe2iru_need_to_wb          ),
    .lower_cx_type             (pipe2iru_cx_type             ),
    .lower_is_unsigned         (pipe2iru_is_unsigned         ),
    .lower_alu_type            (pipe2iru_alu_type            ),
    .lower_is_word             (pipe2iru_is_word             ),
    .lower_is_load             (pipe2iru_is_load             ),
    .lower_is_imm              (pipe2iru_is_imm              ),
    .lower_is_store            (pipe2iru_is_store            ),
    .lower_ls_size             (pipe2iru_ls_size             ),
    .lower_muldiv_type         (pipe2iru_muldiv_type         ),
    .lower_pc                  (pipe2iru_pc                  ),
    .lower_instr               (pipe2iru_instr               ),
    .lower_prs1                (),
    .lower_prs2                (),
    .lower_prd                 (),
    .lower_old_prd             (),
    .lower_ls_address          (),
    .lower_alu_result          (),
    .lower_bju_result          (),
    .lower_muldiv_result       (),
    .lower_opload_read_data_wb (),
    .flush_valid               ()

);



iru_top u_iru_top(
    .clock                          (clock                          ),
    .reset_n                        (reset_n                        ),
    .instr0_valid                   (pipe2iru_instr_valid                   ),//i
    .instr0_ready                   (iru2pipe_instr_ready                   ),//output
    .instr0                         (pipe2iru_instr                         ),//i
    .instr0_lrs1                    (pipe2iru_instr_lrs1                    ),//i
    .instr0_lrs2                    (pipe2iru_instr_lrs2                    ),//i
    .instr0_lrd                     (pipe2iru_instr_lrd                     ),//i
    .instr0_pc                      (pipe2iru_instr_pc                      ),//i
    .instr0_imm                     (pipe2iru_instr_imm                     ),//i
    .instr0_src1_is_reg             (pipe2iru_instr_src1_is_reg             ),//i
    .instr0_src2_is_reg             (pipe2iru_instr_src2_is_reg             ),//i
    .instr0_need_to_wb              (pipe2iru_instr_need_to_wb              ),//i
    .instr0_cx_type                 (pipe2iru_instr_cx_type                 ),//i
    .instr0_is_unsigned             (pipe2iru_instr_is_unsigned             ),//i
    .instr0_alu_type                (pipe2iru_instr_alu_type                ),//i
    .instr0_muldiv_type             (pipe2iru_instr_muldiv_type             ),//i
    .instr0_is_word                 (pipe2iru_instr_is_word                 ),//i
    .instr0_is_imm                  (pipe2iru_instr_is_imm                  ),//i
    .instr0_is_load                 (pipe2iru_instr_is_load                 ),//i
    .instr0_is_store                (pipe2iru_instr_is_store                ),//i
    .instr0_ls_size                 (pipe2iru_instr_ls_size                 ),//i
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
    .rob2specrat_commit1_valid      (rob2specrat_commit1_valid      ),
    .rob2specrat_commit1_need_to_wb (rob2specrat_commit1_need_to_wb ),
    .rob2specrat_commit1_lrd        (rob2specrat_commit1_lrd        ),
    .rob2specrat_commit1_prd        (rob2specrat_commit1_prd        ),
    .rob2fl_commit_old_prd          (rob2fl_commit_old_prd          ),
    .rob2fl_commit_valid0           (rob2fl_commit_valid0           ),
    .flush_valid                    (flush_valid                    ),
    .is_idle                        (is_idle                        ),
    .is_rollback                 (is_rollback                 ),
    .is_walk                     (is_walk                     ),
    .walking_valid0                 (walking_valid0                 ),
    .walking_valid1                 (walking_valid1                 ),
    .walking_old_prd0               (walking_old_prd0               ),
    .walking_old_prd1               (walking_old_prd1               ),
    .commit0_valid                  (commit0_valid                  ),
    .commit0_need_to_wb             (commit0_need_to_wb             ),
    .commit0_lrd                    (commit0_lrd                    ),
    .commit0_prd                    (commit0_prd                    )
);


iru_top u_iru_top(
    .clock                          (clock                                  ),
    .reset_n                        (reset_n                                ),
    .instr0_valid                   (pipe2iru_instr_valid                   ),//i
    .instr0_ready                   (iru2pipe_instr_ready                   ),//output
    .instr0                         (pipe2iru_instr                         ),//i
    .instr0_lrs1                    (pipe2iru_instr_lrs1                    ),//i
    .instr0_lrs2                    (pipe2iru_instr_lrs2                    ),//i
    .instr0_lrd                     (pipe2iru_instr_lrd                     ),//i
    .instr0_pc                      (pipe2iru_instr_pc                      ),//i
    .instr0_imm                     (pipe2iru_instr_imm                     ),//i
    .instr0_src1_is_reg             (pipe2iru_instr_src1_is_reg             ),//i
    .instr0_src2_is_reg             (pipe2iru_instr_src2_is_reg             ),//i
    .instr0_need_to_wb              (pipe2iru_instr_need_to_wb              ),//i
    .instr0_cx_type                 (pipe2iru_instr_cx_type                 ),//i
    .instr0_is_unsigned             (pipe2iru_instr_is_unsigned             ),//i
    .instr0_alu_type                (pipe2iru_instr_alu_type                ),//i
    .instr0_muldiv_type             (pipe2iru_instr_muldiv_type             ),//i
    .instr0_is_word                 (pipe2iru_instr_is_word                 ),//i
    .instr0_is_imm                  (pipe2iru_instr_is_imm                  ),//i
    .instr0_is_load                 (pipe2iru_instr_is_load                 ),//i
    .instr0_is_store                (pipe2iru_instr_is_store                ),//i
    .instr0_ls_size                 (pipe2iru_instr_ls_size                 ),//i
    .instr1_valid                   (),
    .instr1_ready                   (),
    .instr1                         (),
    .instr1_lrs1                    (),
    .instr1_lrs2                    (),
    .instr1_lrd                     (),
    .instr1_pc                      (),
    .instr1_imm                     (),
    .instr1_src1_is_reg             (),
    .instr1_src2_is_reg             (),
    .instr1_need_to_wb              (),
    .instr1_cx_type                 (),
    .instr1_is_unsigned             (),
    .instr1_alu_type                (),
    .instr1_muldiv_type             (),
    .instr1_is_word                 (),
    .instr1_is_imm                  (),
    .instr1_is_load                 (),
    .instr1_is_store                (),
    .rob2specrat_commit1_valid      (rob2specrat_commit1_valid      ),
    .rob2specrat_commit1_need_to_wb (rob2specrat_commit1_need_to_wb ),
    .rob2specrat_commit1_lrd        (rob2specrat_commit1_lrd        ),
    .rob2specrat_commit1_prd        (rob2specrat_commit1_prd        ),
    .rob2fl_commit_old_prd          (rob2fl_commit_old_prd          ),
    .rob2fl_commit_valid0           (rob2fl_commit_valid0           ),
    .flush_valid                    (flush_valid                    ),
    .is_idle                        (is_idle                        ),
    .is_rollback                 (is_rollback                 ),
    .is_walk                     (is_walk                     ),
    .walking_valid0                 (walking_valid0                 ),
    .walking_valid1                 (walking_valid1                 ),
    .walking_old_prd0               (walking_old_prd0               ),
    .walking_old_prd1               (walking_old_prd1               ),
    .commit0_valid                  (commit0_valid                  ),
    .commit0_need_to_wb             (commit0_need_to_wb             ),
    .commit0_lrd                    (commit0_lrd                    ),
    .commit0_prd                    (commit0_prd                    ),

    .rn2pipe_instr0_valid           (rn2pipe_instr0_valid           ),//output
    .pipe2rn_instr0_ready           (pipe2rn_instr0_ready           ),//i
    .rn2pipe_instr0_lrs1            (rn2pipe_instr0_lrs1            ),//output
    .rn2pipe_instr0_lrs2            (rn2pipe_instr0_lrs2            ),//output
    .rn2pipe_instr0_lrd             (rn2pipe_instr0_lrd             ),//output
    .rn2pipe_instr0_pc              (rn2pipe_instr0_pc              ),//output
    .rn2pipe_instr0                 (rn2pipe_instr0                 ),//output
    .rn2pipe_instr0_imm             (rn2pipe_instr0_imm             ),//output
    .rn2pipe_instr0_src1_is_reg     (rn2pipe_instr0_src1_is_reg     ),//output
    .rn2pipe_instr0_src2_is_reg     (rn2pipe_instr0_src2_is_reg     ),//output
    .rn2pipe_instr0_need_to_wb      (rn2pipe_instr0_need_to_wb      ),//output
    .rn2pipe_instr0_cx_type         (rn2pipe_instr0_cx_type         ),//output
    .rn2pipe_instr0_is_unsigned     (rn2pipe_instr0_is_unsigned     ),//output
    .rn2pipe_instr0_alu_type        (rn2pipe_instr0_alu_type        ),//output
    .rn2pipe_instr0_muldiv_type     (rn2pipe_instr0_muldiv_type     ),//output
    .rn2pipe_instr0_is_word         (rn2pipe_instr0_is_word         ),//output
    .rn2pipe_instr0_is_imm          (rn2pipe_instr0_is_imm          ),//output
    .rn2pipe_instr0_is_load         (rn2pipe_instr0_is_load         ),//output
    .rn2pipe_instr0_is_store        (rn2pipe_instr0_is_store        ),//output
    .rn2pipe_instr0_ls_size         (rn2pipe_instr0_ls_size         ),//output
    .rn2pipe_instr0_old_prd         (rn2pipe_instr0_old_prd         ),//output
    .rn2pipe_instr1_valid           (),
    .pipe2rn_instr1_ready           (),
    .rn2pipe_instr1_lrs1            (),
    .rn2pipe_instr1_lrs2            (),
    .rn2pipe_instr1_lrd             (),
    .rn2pipe_instr1_pc              (),
    .rn2pipe_instr1                 (),
    .rn2pipe_instr1_imm             (),
    .rn2pipe_instr1_src1_is_reg     (),
    .rn2pipe_instr1_src2_is_reg     (),
    .rn2pipe_instr1_need_to_wb      (),
    .rn2pipe_instr1_cx_type         (),
    .rn2pipe_instr1_is_unsigned     (),
    .rn2pipe_instr1_alu_type        (),
    .rn2pipe_instr1_muldiv_type     (),
    .rn2pipe_instr1_is_word         (),
    .rn2pipe_instr1_is_imm          (),
    .rn2pipe_instr1_is_load         (),
    .rn2pipe_instr1_is_store        (),
    .rn2pipe_instr1_ls_size         (),
    .rn2pipe_instr1_old_prd         (),
    .debug_preg0        (debug_preg0        ),//archrat2pregfile
    .debug_preg1        (debug_preg1        ),//archrat2pregfile
    .debug_preg2        (debug_preg2        ),//archrat2pregfile
    .debug_preg3        (debug_preg3        ),//archrat2pregfile
    .debug_preg4        (debug_preg4        ),//archrat2pregfile
    .debug_preg5        (debug_preg5        ),//archrat2pregfile
    .debug_preg6        (debug_preg6        ),//archrat2pregfile
    .debug_preg7        (debug_preg7        ),//archrat2pregfile
    .debug_preg8        (debug_preg8        ),//archrat2pregfile
    .debug_preg9        (debug_preg9        ),//archrat2pregfile
    .debug_preg10       (debug_preg10       ),//archrat2pregfile
    .debug_preg11       (debug_preg11       ),//archrat2pregfile
    .debug_preg12       (debug_preg12       ),//archrat2pregfile
    .debug_preg13       (debug_preg13       ),//archrat2pregfile
    .debug_preg14       (debug_preg14       ),//archrat2pregfile
    .debug_preg15       (debug_preg15       ),//archrat2pregfile
    .debug_preg16       (debug_preg16       ),//archrat2pregfile
    .debug_preg17       (debug_preg17       ),//archrat2pregfile
    .debug_preg18       (debug_preg18       ),//archrat2pregfile
    .debug_preg19       (debug_preg19       ),//archrat2pregfile
    .debug_preg20       (debug_preg20       ),//archrat2pregfile
    .debug_preg21       (debug_preg21       ),//archrat2pregfile
    .debug_preg22       (debug_preg22       ),//archrat2pregfile
    .debug_preg23       (debug_preg23       ),//archrat2pregfile
    .debug_preg24       (debug_preg24       ),//archrat2pregfile
    .debug_preg25       (debug_preg25       ),//archrat2pregfile
    .debug_preg26       (debug_preg26       ),//archrat2pregfile
    .debug_preg27       (debug_preg27       ),//archrat2pregfile
    .debug_preg28       (debug_preg28       ),//archrat2pregfile
    .debug_preg29       (debug_preg29       ),//archrat2pregfile
    .debug_preg30       (debug_preg30       ),//archrat2pregfile
    .debug_preg31       (debug_preg31       ) //archrat2pregfile
);

pipereg_autostall u_pipereg_autostall_iru2isu(
    .clock                     (clock                     ),
    .reset_n                   (reset_n                   ),
    .instr_valid_from_upper    (rn2pipe_instr0_valid      ),//i
    .instr_ready_to_upper      (pipe2rn_instr0_ready      ),//output
    .instr                     (rn2pipe_instr0_instr                     ),
    .pc                        (rn2pipe_instr0_pc                        ),
    .lrs1                      (rn2pipe_instr0_lrs1                      ),
    .lrs2                      (rn2pipe_instr0_lrs2                      ),
    .lrd                       (rn2pipe_instr0_lrd                       ),
    .imm                       (rn2pipe_instr0_imm                       ),
    .src1_is_reg               (rn2pipe_instr0_src1_is_reg               ),
    .src2_is_reg               (rn2pipe_instr0_src2_is_reg               ),
    .need_to_wb                (rn2pipe_instr0_need_to_wb                ),
    .cx_type                   (rn2pipe_instr0_cx_type                   ),
    .is_unsigned               (rn2pipe_instr0_is_unsigned               ),
    .alu_type                  (rn2pipe_instr0_alu_type                  ),
    .is_word                   (rn2pipe_instr0_is_word                   ),
    .is_load                   (rn2pipe_instr0_is_load                   ),
    .is_imm                    (rn2pipe_instr0_is_imm                    ),
    .is_store                  (rn2pipe_instr0_is_store                  ),
    .ls_size                   (rn2pipe_instr0_ls_size                   ),
    .muldiv_type               (rn2pipe_instr0_muldiv_type               ),
    .prs1                      (rn2pipe_instr0_prs1                      ),
    .prs2                      (rn2pipe_instr0_prs2                      ),
    .prd                       (rn2pipe_instr0_prd                       ),
    .old_prd                   (rn2pipe_instr0_old_prd                   ),
    .ls_address                (),
    .alu_result                (),
    .bju_result                (),
    .muldiv_result             (),
    .opload_read_data_wb       (),
    .instr_valid_to_lower      (pipe2isu_instr_valid      ),//output
    .instr_ready_from_lower    (isu2pipe_instr_ready      ),//i
    .lower_instr               (pipe2isu_instr0_instr               ),//output
    .lower_pc                  (pipe2isu_instr0_pc                  ),//output
    .lower_lrs1                (pipe2isu_instr0_lrs1                ),//output
    .lower_lrs2                (pipe2isu_instr0_lrs2                ),//output
    .lower_lrd                 (pipe2isu_instr0_lrd                 ),//output
    .lower_imm                 (pipe2isu_instr0_imm                 ),//output
    .lower_src1_is_reg         (pipe2isu_instr0_src1_is_reg         ),//output
    .lower_src2_is_reg         (pipe2isu_instr0_src2_is_reg         ),//output
    .lower_need_to_wb          (pipe2isu_instr0_need_to_wb          ),//output
    .lower_cx_type             (pipe2isu_instr0_cx_type             ),//output
    .lower_is_unsigned         (pipe2isu_instr0_is_unsigned         ),//output
    .lower_alu_type            (pipe2isu_instr0_alu_type            ),//output
    .lower_is_word             (pipe2isu_instr0_is_word             ),//output
    .lower_is_load             (pipe2isu_instr0_is_load             ),//output
    .lower_is_imm              (pipe2isu_instr0_is_imm              ),//output
    .lower_is_store            (pipe2isu_instr0_is_store            ),//output
    .lower_ls_size             (pipe2isu_instr0_ls_size             ),//output
    .lower_muldiv_type         (pipe2isu_instr0_muldiv_type         ),//output
    .lower_prs1                (pipe2isu_instr0_prs1                ),//output
    .lower_prs2                (pipe2isu_instr0_prs2                ),//output
    .lower_prd                 (pipe2isu_instr0_prd                 ),//output
    .lower_old_prd             (pipe2isu_instr0_old_prd             ),//output
    .lower_ls_address          (),
    .lower_alu_result          (),
    .lower_bju_result          (),
    .lower_muldiv_result       (),
    .lower_opload_read_data_wb (),
    .flush_valid               (flush_valid               )
);






























    // frontend u_frontend            (
    //     .clock                     (clock                    ),
    //     .reset_n                   (reset_n                  ),
    //     .redirect_valid            (redirect_valid           ),
    //     .redirect_target           (redirect_target          ),
    //     .pc_index_valid            (pc_index_valid           ),
    //     .pc_index_ready            (pc_index_ready           ),
    //     .pc_operation_done         (pc_operation_done        ),
    //     .pc_read_inst              (pc_read_inst             ),
    //     .pc_index                  (pc_index                 ),
    //     .fifo_read_en              (~mem_stall               ),           //when mem stall,ibuf can not to read instr anymore!
    //     //.clear_ibuffer_ext       (redirect_valid           ),
    //     .rs1                       (rs1                      ),
    //     .rs2                       (rs2                      ),
    //     .rd                        (rd                       ),
    //     .src1_muxed                (src1                     ),
    //     .src2_muxed                (src2                     ),
    //     .imm                       (imm                      ),
    //     .src1_is_reg               (src1_is_reg              ),
    //     .src2_is_reg               (src2_is_reg              ),
    //     .need_to_wb                (need_to_wb               ),
    //     .cx_type                   (cx_type                  ),
    //     .is_unsigned               (is_unsigned              ),
    //     .alu_type                  (alu_type                 ),
    //     .is_word                   (is_word                  ),
    //     .is_imm                    (is_imm                   ),
    //     .is_load                   (is_load                  ),
    //     .is_store                  (is_store                 ),
    //     .ls_size                   (ls_size                  ),
    //     .muldiv_type               (muldiv_type              ),
    //     .decoder_instr_valid       (decoder_instr_valid      ),
    //     .decoder_predicttaken_out  (decoder_predicttaken_out ),
    //     .decoder_predicttarget_out (decoder_predicttarget_out),
    //     .decoder_pc_out            (decoder_pc_out           ),
    //     .decoder_inst_out          (decoder_inst_out         ),
    //     //write back enable
    //     .writeback_valid    (regfile_write_valid),
    //     .writeback_rd       (regfile_write_rd   ),
    //     .writeback_data     (regfile_write_data ),

    //     .exe_byp_rd        (exe_byp_rd                        ),
    //     .exe_byp_need_to_wb(exe_byp_need_to_wb                ),
    //     .exe_byp_result    (exe_byp_result                    ),
    //     .mem_stall         (mem_stall                         ),
    //     //bhtbtb
    //     .bht_write_enable         (wb_bht_write_enable        ),                 
    //     .bht_write_index          (wb_bht_write_index         ),
    //     .bht_write_counter_select (wb_bht_write_counter_select),   
    //     .bht_write_inc            (wb_bht_write_inc           ),                    
    //     .bht_write_dec            (wb_bht_write_dec           ),                    
    //     .bht_valid_in             (wb_bht_valid_in            ),  
    //     .btb_ce                   (wb_btb_ce                  ),           
    //     .btb_we                   (wb_btb_we                  ),           
    //     .btb_wmask                (wb_btb_wmask               ),
    //     .btb_write_index          (wb_btb_write_index               ),
    //     .btb_din                  (wb_btb_din                 )        

    // );
    wire                      out_valid;
    wire [       `LREG_RANGE] out_rs1;
    wire [       `LREG_RANGE] out_rs2;
    wire [       `LREG_RANGE] out_rd;
    wire [        `SRC_RANGE] out_src1;
    wire [        `SRC_RANGE] out_src2;
    wire [        `SRC_RANGE] out_imm;
    wire                      out_src1_is_reg;
    wire                      out_src2_is_reg;
    wire                      out_need_to_wb;
    wire [    `CX_TYPE_RANGE] out_cx_type;
    wire                      out_is_unsigned;
    wire [   `ALU_TYPE_RANGE] out_alu_type;
    wire                      out_is_word;
    wire                      out_is_load;
    wire                      out_is_imm;
    wire                      out_is_store;
    wire [               3:0] out_ls_size;
    wire [`MULDIV_TYPE_RANGE] out_muldiv_type;
    wire                      out_instr_valid;
    wire                      out_predict_taken;
    wire [31:0]               out_predict_target;
    wire [         `PC_RANGE] out_pc;
    wire [      `INSTR_RANGE] out_instr;

    pipereg u_pipereg_dec2exu (
        .clock                  (clock),
        .reset_n                (reset_n),
        .stall                  (mem_stall),//mem_stall latch output of this pipereg
        .redirect_flush         (redirect_valid),
        .rs1                    (rs1),
        .rs2                    (rs2),
        .rd                     (rd),
        .src1                   (src1),
        .src2                   (src2),
        .imm                    (imm),
        .src1_is_reg            (src1_is_reg),
        .src2_is_reg            (src2_is_reg),
        .need_to_wb             (need_to_wb),
        .cx_type                (cx_type),
        .is_unsigned            (is_unsigned),
        .alu_type               (alu_type),
        .is_word                (is_word),
        .is_load                (is_load),
        .is_imm                 (is_imm),
        .is_store               (is_store),
        .ls_size                (ls_size),
        .muldiv_type            (muldiv_type),
        .instr_valid            (decoder_instr_valid),
        .predict_taken          (decoder_predicttaken_out),
        .predict_target         (decoder_predicttarget_out),
        .pc                     (decoder_pc_out),
        .instr                  (decoder_inst_out),
        .ls_address             ('b0),
        .alu_result             ('b0),
        .bju_result             ('b0),
        .muldiv_result          ('b0),
        .opload_read_data_wb    ('b0),
        .out_rs1                (out_rs1),
        .out_rs2                (out_rs2),
        .out_rd                 (out_rd),
        .out_src1               (out_src1),
        .out_src2               (out_src2),
        .out_imm                (out_imm),
        .out_src1_is_reg        (out_src1_is_reg),
        .out_src2_is_reg        (out_src2_is_reg),
        .out_need_to_wb         (out_need_to_wb),
        .out_cx_type            (out_cx_type),
        .out_is_unsigned        (out_is_unsigned),
        .out_alu_type           (out_alu_type),
        .out_is_word            (out_is_word),
        .out_is_load            (out_is_load),
        .out_is_imm             (out_is_imm),
        .out_is_store           (out_is_store),
        .out_ls_size            (out_ls_size),
        .out_muldiv_type        (out_muldiv_type),
        .out_instr_valid        (out_instr_valid),
        .out_predict_taken      (out_predict_taken),
        .out_predict_target     (out_predict_target),
        .out_pc                 (out_pc),
        .out_instr              (out_instr),
        .out_ls_address         (),
        .out_alu_result         (),
        .out_bju_result         (),
        .out_muldiv_result      (),
        .out_opload_read_data_wb(),
        //bhtbtb pipe
        .bht_write_enable         ('b0),                 
        .bht_write_index          ('b0),
        .bht_write_counter_select ('b0),   
        .bht_write_inc            ('b0),                    
        .bht_write_dec            ('b0),                    
        .bht_valid_in             ('b0),  
        .btb_ce                   ('b0),           
        .btb_we                   ('b0),           
        .btb_wmask                ('b0),
        .btb_write_index          ('b0),
        .btb_din                  ('b0),
        .out_bht_write_enable         (),                 
        .out_bht_write_index          (),
        .out_bht_write_counter_select (),   
        .out_bht_write_inc            (),                    
        .out_bht_write_dec            (),                    
        .out_bht_valid_in             (),  
        .out_btb_ce                   (),           
        .out_btb_we                   (),           
        .out_btb_wmask                (),
        .out_btb_write_index          (),
        .out_btb_din                  ()       

    );


    backend u_backend (
        .clock              (clock),
        .reset_n            (reset_n),
        .rs1                (out_rs1),
        .rs2                (out_rs2),
        .rd                 (out_rd),
        .src1               (out_src1),
        .src2               (out_src2),
        .imm                (out_imm),
        .src1_is_reg        (out_src1_is_reg),
        .src2_is_reg        (out_src2_is_reg),
        .need_to_wb         (out_need_to_wb),
        .cx_type            (out_cx_type),
        .is_unsigned        (out_is_unsigned),
        .alu_type           (out_alu_type),
        .is_word            (out_is_word),
        .is_load            (out_is_load),
        .is_imm             (out_is_imm),
        .is_store           (out_is_store),
        .ls_size            (out_ls_size),
        .muldiv_type        (out_muldiv_type),
        .instr_valid        (out_instr_valid),
        .predict_taken      (out_predict_taken), 
        .predict_target     (out_predict_target), 
        .pc                 (out_pc),
        .instr              (out_instr),
        .regfile_write_valid(regfile_write_valid),
        .regfile_write_rd   (regfile_write_rd),
        .regfile_write_data (regfile_write_data),
        .redirect_valid     (redirect_valid),//output
        .redirect_target    (redirect_target),
        .mem_stall          (mem_stall),
        //trinity bus channel
        .tbus_index_valid   (tbus_index_valid),
        .tbus_index_ready   (tbus_index_ready),
        .tbus_index         (tbus_index),
        .tbus_write_data    (tbus_write_data),
        .tbus_write_mask    (tbus_write_mask),
        .tbus_read_data     (tbus_read_data),
        .tbus_operation_done(tbus_operation_done),
        .tbus_operation_type(tbus_operation_type),
        .flop_commit_valid  (flop_commit_valid),
        .exe_byp_rd         (exe_byp_rd),
        .exe_byp_need_to_wb (exe_byp_need_to_wb),
        .exe_byp_result     (exe_byp_result),
        .wb_bht_write_enable         (wb_bht_write_enable        ),                 
        .wb_bht_write_index          (wb_bht_write_index         ),
        .wb_bht_write_counter_select (wb_bht_write_counter_select),   
        .wb_bht_write_inc            (wb_bht_write_inc           ),                    
        .wb_bht_write_dec            (wb_bht_write_dec           ),                    
        .wb_bht_valid_in             (wb_bht_valid_in            ),  
        .wb_btb_ce                   (wb_btb_ce                  ),           
        .wb_btb_we                   (wb_btb_we                  ),           
        .wb_btb_wmask                (wb_btb_wmask               ),
        .wb_btb_write_index                (wb_btb_write_index               ),
        .wb_btb_din                  (wb_btb_din                 ) 

    );



    channel_arb u_channel_arb (
        .clock            (clock),
        .reset_n          (reset_n),
        //icache channel
        .icache2arb_dbus_index_valid     (icache2arb_dbus_index_valid   ),
        .icache2arb_dbus_index           (icache2arb_dbus_index         ),
        .icache2arb_dbus_index_ready     (icache2arb_dbus_index_ready   ),
        .icache2arb_dbus_read_data       (icache2arb_dbus_read_data     ),
        .icache2arb_dbus_operation_done  (icache2arb_dbus_operation_done),
        //dcache channel
        .dcache2arb_dbus_index_valid     (dcache2arb_dbus_index_valid    ),
        .dcache2arb_dbus_index_ready     (dcache2arb_dbus_index_ready    ),
        .dcache2arb_dbus_index           (dcache2arb_dbus_index          ),
        .dcache2arb_dbus_write_data      (dcache2arb_dbus_write_data     ),
        //.dcache2arb_dbus_write_mask      (dcache2arb_dbus_write_mask     ),
        .dcache2arb_dbus_read_data       (dcache2arb_dbus_read_data      ),
        .dcache2arb_dbus_operation_done  (dcache2arb_dbus_operation_done ),
        .dcache2arb_dbus_operation_type  (dcache2arb_dbus_operation_type ),
        //ddr channel
        .ddr_chip_enable    (ddr_chip_enable),
        .ddr_index          (ddr_index),
        .ddr_write_enable   (ddr_write_enable),
        .ddr_burst_mode     (ddr_burst_mode),
        .ddr_write_data     (ddr_write_data),
        .ddr_read_data      (ddr_read_data),
        .ddr_operation_done (ddr_operation_done),
        .ddr_ready          (ddr_ready)
        //.redirect_valid     (redirect_valid)
    );



endmodule
