module exu_top #(
    parameter BHTBTB_INDEX_WIDTH = 9
)(
    input wire                          clock,
    input wire                          reset_n,

    // Common Inputs
    input wire                          flush_valid,
    input wire  [`INSTR_ID_WIDTH-1:0]   flush_robid,

    // Intblock Inputs
    input wire                          int_instr_valid,
    output wire                         int_instr_ready,
    input wire   [      `INSTR_RANGE  ] int_instr,
    input wire   [         `PC_RANGE  ] int_pc,
    input wire   [`INSTR_ID_WIDTH-1:0 ] int_robid,
    input wire [        `SRC_RANGE]     int_src1,
    input wire [        `SRC_RANGE]     int_src2,
    input wire [       `PREG_RANGE]     int_prd,
    input wire [        `SRC_RANGE]     int_imm,
    input wire                          int_need_to_wb,
    input wire [    `CX_TYPE_RANGE]     int_cx_type,
    input wire                          int_is_unsigned,
    input wire [   `ALU_TYPE_RANGE]     int_alu_type,
    input wire [`MULDIV_TYPE_RANGE]     int_muldiv_type,
    input wire                          int_is_imm,
    input wire                          int_is_word,
    input wire                          int_predict_taken,
    input wire [31:0]                   int_predict_target,

    // Memblock Inputs
    input wire                          mem_instr_valid,
    output wire                         mem_instr_ready,
    input wire [  `INSTR_RANGE]         mem_instr,
    input wire [     `PC_RANGE]         mem_pc,
    input wire [`INSTR_ID_WIDTH-1:0]    mem_robid,
    input wire [    `SRC_RANGE]         mem_src1,
    input wire [    `SRC_RANGE]         mem_src2,
    input wire [      `PREG_RANGE]      mem_prd,
    input wire [    `SRC_RANGE]         mem_imm,
    input wire                          mem_is_load,
    input wire                          mem_is_store,
    input wire                          mem_is_unsigned,
    input wire [`LS_SIZE_RANGE]         mem_ls_size,

    // Trinity Bus Interface
    output wire                         tbus_index_valid,
    input  wire                         tbus_index_ready,
    output wire [`RESULT_RANGE]         tbus_index,
    output wire [   `SRC_RANGE]         tbus_write_data,
    output wire [         63:0]         tbus_write_mask,
    input  wire [ `RESULT_RANGE]        tbus_read_data,
    input  wire                         tbus_operation_done,
    output wire [`TBUS_OPTYPE_RANGE]    tbus_operation_type,

    // Intblock Outputs
    output wire                         intwb_instr_valid,
    output wire                         intwb_need_to_wb,
    output wire [`PREG_RANGE]           intwb_prd,
    output wire [`RESULT_RANGE]         intwb_result,
    output wire                         intwb_redirect_valid,
    output wire [63:0]                  intwb_redirect_target,
    output wire [`INSTR_ID_WIDTH-1:0]   intwb_id,
    output wire [      `INSTR_RANGE ]   intwb_instr,
    output wire [         `PC_RANGE ]   intwb_pc,

    // Memblock Outputs
    output wire                         memwb_out_instr_valid,
    output wire [`INSTR_ID_WIDTH-1:0]   memwb_out_robid,
    output wire [`PREG_RANGE]           memwb_out_prd,
    output wire                         memwb_out_need_to_wb,
    output wire                         memwb_out_mmio_valid,
    output wire [`RESULT_RANGE]         memwb_out_opload_rddata,
    output wire [      `INSTR_RANGE ]   memwb_out_instr,
    output wire [         `PC_RANGE ]   memwb_out_pc,

    // BHT/BTB Update
    output wire                         bjusb_bht_write_enable,
    output wire [BHTBTB_INDEX_WIDTH-1:0] bjusb_bht_write_index,
    output wire [1:0]                   bjusb_bht_write_counter_select,
    output wire                         bjusb_bht_write_inc,
    output wire                         bjusb_bht_write_dec,
    output wire                         bjusb_bht_valid_in,
    output wire                         bjusb_btb_ce,
    output wire                         bjusb_btb_we,
    output wire [128:0]                 bjusb_btb_wmask,
    output wire [8:0]                   bjusb_btb_write_index,
    output wire [128:0]                 bjusb_btb_din,

    // Dcache Flush
    output wire                         mem2dcache_flush
);

    // Intblock internal signals
    wire                        intblock_out_instr_valid;
    wire                        intblock_out_need_to_wb;
    wire [`PREG_RANGE]          intblock_out_prd;
    wire [`RESULT_RANGE]        intblock_out_result;
    wire                        intblock_out_redirect_valid;
    wire [63:0]                 intblock_out_redirect_target;
    wire [`INSTR_ID_WIDTH-1:0]  intblock_out_robid;
    wire [      `INSTR_RANGE ]  intblock_out_instr;
    wire [         `PC_RANGE ]  intblock_out_pc;

    // Memblock internal signals
    wire                        memblock_out_instr_valid;
    wire [`INSTR_ID_WIDTH-1:0]  memblock_out_robid;
    wire [`PREG_RANGE]          memblock_out_prd;
    wire                        memblock_out_need_to_wb;
    wire                        memblock_out_mmio_valid;
    wire [`RESULT_RANGE]        memblock_out_opload_rddata;
    wire [      `INSTR_RANGE ]  memblock_out_instr;
    wire [         `PC_RANGE ]  memblock_out_pc;

    // Instantiate intblock
    intblock #(
        .BHTBTB_INDEX_WIDTH(BHTBTB_INDEX_WIDTH)
    ) intblock_inst (
        .clock(clock),
        .reset_n(reset_n),
        .instr_valid(int_instr_valid),
        .instr_ready(int_instr_ready),
        .instr(int_instr),
        .pc(int_pc),
        .robid(int_robid),
        .src1(int_src1),
        .src2(int_src2),
        .prd(int_prd),
        .imm(int_imm),
        .need_to_wb(int_need_to_wb),
        .cx_type(int_cx_type),
        .is_unsigned(int_is_unsigned),
        .alu_type(int_alu_type),
        .muldiv_type(int_muldiv_type),
        .is_imm(int_is_imm),
        .is_word(int_is_word),
        .predict_taken(int_predict_taken),
        .predict_target(int_predict_target),
        .intblock_out_instr_valid(intblock_out_instr_valid),
        .intblock_out_need_to_wb(intblock_out_need_to_wb),
        .intblock_out_prd(intblock_out_prd),
        .intblock_out_result(intblock_out_result),
        .intblock_out_redirect_valid(intblock_out_redirect_valid),
        .intblock_out_redirect_target(intblock_out_redirect_target),
        .intblock_out_robid(intblock_out_robid),
        .intblock_out_instr(intblock_out_instr),
        .intblock_out_pc(intblock_out_pc),
        .flush_valid(flush_valid),
        .flush_robid(flush_robid),
        .bjusb_bht_write_enable(bjusb_bht_write_enable),
        .bjusb_bht_write_index(bjusb_bht_write_index),
        .bjusb_bht_write_counter_select(bjusb_bht_write_counter_select),
        .bjusb_bht_write_inc(bjusb_bht_write_inc),
        .bjusb_bht_write_dec(bjusb_bht_write_dec),
        .bjusb_bht_valid_in(bjusb_bht_valid_in),
        .bjusb_btb_ce(bjusb_btb_ce),
        .bjusb_btb_we(bjusb_btb_we),
        .bjusb_btb_wmask(bjusb_btb_wmask),
        .bjusb_btb_write_index(bjusb_btb_write_index),
        .bjusb_btb_din(bjusb_btb_din)
    );

    // Instantiate pipereg_intwb
    pipereg_intwb pipereg_intwb_inst (
        .clock(clock),
        .reset_n(reset_n),
        .intblock_out_instr_valid(intblock_out_instr_valid),
        .intblock_out_need_to_wb(intblock_out_need_to_wb),
        .intblock_out_prd(intblock_out_prd),
        .intblock_out_result(intblock_out_result),
        .intblock_out_redirect_valid(intblock_out_redirect_valid),
        .intblock_out_redirect_target(intblock_out_redirect_target),
        .intblock_out_id(intblock_out_robid),
        .intblock_out_instr(intblock_out_instr),
        .intblock_out_pc(intblock_out_pc),
        .bjusb_bht_write_enable(bjusb_bht_write_enable),
        .bjusb_bht_write_index(bjusb_bht_write_index),
        .bjusb_bht_write_counter_select(bjusb_bht_write_counter_select),
        .bjusb_bht_write_inc(bjusb_bht_write_inc),
        .bjusb_bht_write_dec(bjusb_bht_write_dec),
        .bjusb_bht_valid_in(bjusb_bht_valid_in),
        .bjusb_btb_ce(bjusb_btb_ce),
        .bjusb_btb_we(bjusb_btb_we),
        .bjusb_btb_wmask(bjusb_btb_wmask),
        .bjusb_btb_write_index(bjusb_btb_write_index),
        .bjusb_btb_din(bjusb_btb_din),
        .intwb_instr_valid(intwb_instr_valid),
        .intwb_need_to_wb(intwb_need_to_wb),
        .intwb_prd(intwb_prd),
        .intwb_result(intwb_result),
        .intwb_redirect_valid(intwb_redirect_valid),
        .intwb_redirect_target(intwb_redirect_target),
        .intwb_id(intwb_id),
        .intwb_bjusb_bht_write_enable(),
        .intwb_bjusb_bht_write_index(),
        .intwb_bjusb_bht_write_counter_select(),
        .intwb_bjusb_bht_write_inc(),
        .intwb_bjusb_bht_write_dec(),
        .intwb_bjusb_bht_valid_in(),
        .intwb_bjusb_btb_ce(),
        .intwb_bjusb_btb_we(),
        .intwb_bjusb_btb_wmask(),
        .intwb_bjusb_btb_write_index(),
        .intwb_bjusb_btb_din()
    );

    // Instantiate memblock
    memblock memblock_inst (
        .clock(clock),
        .reset_n(reset_n),
        .instr_valid(mem_instr_valid),
        .instr_ready(mem_instr_ready),
        .instr(mem_instr),
        .pc(mem_pc),
        .robid(mem_robid),
        .src1(mem_src1),
        .src2(mem_src2),
        .prd(mem_prd),
        .imm(mem_imm),
        .is_load(mem_is_load),
        .is_store(mem_is_store),
        .is_unsigned(mem_is_unsigned),
        .ls_size(mem_ls_size),
        .tbus_index_valid(tbus_index_valid),
        .tbus_index_ready(tbus_index_ready),
        .tbus_index(tbus_index),
        .tbus_write_data(tbus_write_data),
        .tbus_write_mask(tbus_write_mask),
        .tbus_read_data(tbus_read_data),
        .tbus_operation_done(tbus_operation_done),
        .tbus_operation_type(tbus_operation_type),
        .memblock_out_instr_valid(memblock_out_instr_valid),
        .memblock_out_robid(memblock_out_robid),
        .memblock_out_prd(memblock_out_prd),
        .memblock_out_need_to_wb(memblock_out_need_to_wb),
        .memblock_out_mmio_valid(memblock_out_mmio_valid),
        .memblock_out_opload_rddata(memblock_out_opload_rddata),
        .memblock_out_instr(memblock_out_instr),
        .memblock_out_pc(memblock_out_pc),
        .flush_valid(flush_valid),
        .flush_robid(flush_robid),
        .mem2dcache_flush(mem2dcache_flush)
    );

    // Instantiate pipereg_memwb
    pipereg_memwb pipereg_memwb_inst (
        .clock(clock),
        .reset_n(reset_n),
        .memblock_out_instr_valid(memblock_out_instr_valid),
        .memblock_out_robid(memblock_out_robid),
        .memblock_out_prd(memblock_out_prd),
        .memblock_out_need_to_wb(memblock_out_need_to_wb),
        .memblock_out_mmio_valid(memblock_out_mmio_valid),
        .memblock_out_opload_rddata(memblock_out_opload_rddata),
        .memblock_out_instr(memblock_out_instr),
        .memblock_out_pc(memblock_out_pc),
        .memwb_out_instr_valid(memwb_out_instr_valid),
        .memwb_out_robid(memwb_out_robid),
        .memwb_out_prd(memwb_out_prd),
        .memwb_out_need_to_wb(memwb_out_need_to_wb),
        .memwb_out_mmio_valid(memwb_out_mmio_valid),
        .memwb_out_opload_rddata(memwb_out_opload_rddata)
    );

endmodule