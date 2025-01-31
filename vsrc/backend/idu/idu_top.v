module idu_top(
    input  wire                      clock,
    input  wire                      reset_n,

    // ports with ibuffer
    input  wire                      fifo_empty,
    input  wire                      ibuffer_instr_valid,
    input  wire                      ibuffer_predicttaken_out,
    input  wire [31:0]               ibuffer_predicttarget_out,
    input  wire [31:0]               ibuffer_inst_out,
    input  wire [47:0]               ibuffer_pc_out,
    output wire                      ibuffer_read_en,

    // flush signals from intwb
    input  wire                      flush_valid,

    // ports with iru
    input  wire                      isu_instr_ready,
    output wire                      idu_instr_valid,
    output wire [`INSTR_RANGE]       idu_instr,
    output wire [`PC_RANGE]          idu_pc,
    output wire [`LREG_RANGE]        idu_lrs1,
    output wire [`LREG_RANGE]        idu_lrs2,
    output wire [`LREG_RANGE]        idu_lrd,
    output wire [`SRC_RANGE]         idu_imm,
    output wire                      idu_src1_is_reg,
    output wire                      idu_src2_is_reg,
    output wire                      idu_need_to_wb,

    output wire [`CX_TYPE_RANGE]     idu_cx_type,
    output wire                      idu_is_unsigned,
    output wire [`ALU_TYPE_RANGE]    idu_alu_type,
    output wire                      idu_is_word,
    output wire                      idu_is_load,
    output wire                      idu_is_imm,
    output wire                      idu_is_store,
    output wire [3:0]                idu_ls_size,
    output wire [`MULDIV_TYPE_RANGE] idu_muldiv_type,

    output wire [`PREG_RANGE]        idu_prs1,
    output wire [`PREG_RANGE]        idu_prs2,
    output wire [`PREG_RANGE]        idu_prd,
    output wire [`PREG_RANGE]        idu_old_prd
);

    //----------------------------------
    // Internal signals: decoder -> pipereg_autostall
    //----------------------------------
    wire [4:0]                dec_rs1;
    wire [4:0]                dec_rs2;
    wire [4:0]                dec_rd;
    wire [63:0]               dec_imm;
    wire                      dec_src1_is_reg;
    wire                      dec_src2_is_reg;
    wire                      dec_need_to_wb;
    wire [`CX_TYPE_RANGE]     dec_cx_type;
    wire                      dec_is_unsigned;
    wire [`ALU_TYPE_RANGE]    dec_alu_type;
    wire                      dec_is_word;
    wire                      dec_is_imm;
    wire                      dec_is_load;
    wire                      dec_is_store;
    wire [3:0]                dec_ls_size;
    wire [`MULDIV_TYPE_RANGE] dec_muldiv_type;

    // Decoder output signals (instruction valid, PC, instruction, etc.)
    wire                      dec_instr_valid;
    wire [47:0]              dec_pc_out;
    wire [31:0]              dec_instr_out;
    wire                      dec_predicttaken_out;
    wire [31:0]              dec_predicttarget_out;

    //----------------------------------
    // Instantiate decoder module
    //----------------------------------
    decoder u_decoder (
        .clock                      (clock),
        .reset_n                    (reset_n),

        // Inputs from ibuffer
        .fifo_empty                 (fifo_empty),
        .ibuffer_instr_valid        (ibuffer_instr_valid),
        .ibuffer_predicttaken_out   (ibuffer_predicttaken_out),
        .ibuffer_predicttarget_out  (ibuffer_predicttarget_out),
        .ibuffer_inst_out           (ibuffer_inst_out),
        .ibuffer_pc_out             (ibuffer_pc_out),

        // Decoding outputs (registers, control signals, etc.)
        .rs1                        (dec_rs1),
        .rs2                        (dec_rs2),
        .rd                         (dec_rd),
        .imm                        (dec_imm),
        .src1_is_reg                (dec_src1_is_reg),
        .src2_is_reg                (dec_src2_is_reg),
        .need_to_wb                 (dec_need_to_wb),
        .cx_type                    (dec_cx_type),
        .is_unsigned                (dec_is_unsigned),
        .alu_type                   (dec_alu_type),
        .is_word                    (dec_is_word),
        .is_imm                     (dec_is_imm),
        .is_load                    (dec_is_load),
        .is_store                   (dec_is_store),
        .ls_size                    (dec_ls_size),
        .muldiv_type                (dec_muldiv_type),

        // Feedthrough signals
        .decoder_instr_valid        (dec_instr_valid),
        .decoder_pc_out             (dec_pc_out),
        .decoder_instr_out          (dec_instr_out),
        .decoder_predicttaken_out   (dec_predicttaken_out),
        .decoder_predicttarget_out  (dec_predicttarget_out)
    );

    //----------------------------------
    // Instantiate pipereg_autostall
    //----------------------------------
    pipereg_autostall u_idu_pipereg_autostall (
        .clock                      (clock),
        .reset_n                    (reset_n),

        // Inputs from decoder -> pipeline register
        .instr_valid_from_upper     (dec_instr_valid),
        .instr_ready_to_upper       (ibuffer_read_en),//output

        .instr                      (dec_instr_out),
        .pc                         (dec_pc_out),
        .lrs1                       (dec_rs1),
        .lrs2                       (dec_rs2),
        .lrd                        (dec_rd),
        .imm                        (dec_imm),
        .src1_is_reg                (dec_src1_is_reg),
        .src2_is_reg                (dec_src2_is_reg),
        .need_to_wb                 (dec_need_to_wb),

        .cx_type                    (dec_cx_type),
        .is_unsigned                (dec_is_unsigned),
        .alu_type                   (dec_alu_type),
        .is_word                    (dec_is_word),
        .is_load                    (dec_is_load),
        .is_imm                     (dec_is_imm),
        .is_store                   (dec_is_store),
        .ls_size                    (dec_ls_size),
        .muldiv_type                (dec_muldiv_type),

        // Optional: If physical register renaming information is needed, map them here
        .prs1                       (),
        .prs2                       (),
        .prd                        (),
        .old_prd                    (),

        // Results from EXU for write-back or bypassing
        .ls_address                 (),
        .alu_result                 (),
        .bju_result                 (),
        .muldiv_result              (),
        .opload_read_data_wb        (),

        // Outputs to next pipeline stage
        .instr_valid_to_lower       (idu_instr_valid),
        .instr_ready_from_lower     (isu_instr_ready),//input feedthrough

        .idu_instr                  (idu_instr),
        .idu_pc                     (idu_pc),
        .idu_lrs1                   (idu_lrs1),
        .idu_lrs2                   (idu_lrs2),
        .idu_lrd                    (idu_lrd),
        .idu_imm                    (idu_imm),
        .idu_src1_is_reg            (idu_src1_is_reg),
        .idu_src2_is_reg            (idu_src2_is_reg),
        .idu_need_to_wb             (idu_need_to_wb),

        .idu_cx_type                (idu_cx_type),
        .idu_is_unsigned            (idu_is_unsigned),
        .idu_alu_type               (idu_alu_type),
        .idu_is_word                (idu_is_word),
        .idu_is_load                (idu_is_load),
        .idu_is_imm                 (idu_is_imm),
        .idu_is_store               (idu_is_store),
        .idu_ls_size                (idu_ls_size),
        .idu_muldiv_type            (idu_muldiv_type),

        .idu_prs1                   (),
        .idu_prs2                   (),
        .idu_prd                    (),
        .idu_old_prd                (),

        .idu_ls_address             (),
        .idu_alu_result             (),
        .idu_bju_result             (),
        .idu_muldiv_result          (),
        .idu_opload_read_data_wb    (),

        // Flush signal
        .flush_valid                (flush_valid)
    );

endmodule
