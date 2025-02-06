`include "defines.sv"
module memblock (
    input  wire clock,
    input  wire reset_n,
    input  wire instr_valid,
    output wire instr_ready,

    input wire [     `INSTR_RANGE] instr,  // for debug
    input wire [        `PC_RANGE] pc,     //for debug
    input wire [  `ROB_SIZE_LOG:0] robid,
    input wire [`STOREQUEUE_LOG:0] sqid,

    input wire [    `SRC_RANGE] src1,
    input wire [    `SRC_RANGE] src2,
    input wire [   `PREG_RANGE] prd,
    input wire [    `SRC_RANGE] imm,
    input wire                  is_load,
    input wire                  is_store,
    input wire                  is_unsigned,
    input wire [`LS_SIZE_RANGE] ls_size,

    //trinity bus channel
    output reg                  load2arb_tbus_index_valid,
    input  wire                 load2arb_tbus_index_ready,
    output reg  [`RESULT_RANGE] load2arb_tbus_index,
    output reg  [   `SRC_RANGE] load2arb_tbus_write_data,
    output reg  [         63:0] load2arb_tbus_write_mask,

    input  wire [     `RESULT_RANGE] load2arb_tbus_read_data,
    input  wire                      load2arb_tbus_operation_done,
    output wire [`TBUS_OPTYPE_RANGE] load2arb_tbus_operation_type,

    /* --------------------------- output to writeback -------------------------- */
    output wire                   memblock_out_instr_valid,
    output wire [`ROB_SIZE_LOG:0] memblock_out_robid,
    output wire [    `PREG_RANGE] memblock_out_prd,
    output wire                   memblock_out_need_to_wb,
    output wire                   memblock_out_mmio_valid,
    output wire [  `RESULT_RANGE] memblock_out_load_data,
    output wire [   `INSTR_RANGE] memblock_out_instr,          //for debug
    output wire [      `PC_RANGE] memblock_out_pc,             //for debug
    //other info to store queue
    output wire [     `SRC_RANGE] memblock_out_store_addr,
    output wire [     `SRC_RANGE] memblock_out_store_data,
    output wire [     `SRC_RANGE] memblock_out_store_mask,
    output wire [            3:0] memblock_out_store_ls_size,
    /* -------------------------- redirect flush logic -------------------------- */
    input  wire                   flush_valid,
    input  wire [`ROB_SIZE_LOG:0] flush_robid,

    /* --------------------------- memblock to dcache --------------------------- */
    output wire mem2dcache_flush,  // use to flush dcache process
    /* --------------------------- SQ forwarding query -------------------------- */
    output wire ldu2sq_forward_req_valid,
    output wire [`ROB_SIZE_LOG:0] ldu2sq_forward_req_sqid,
    output wire [`STOREQUEUE_DEPTH-1:0] ldu2sq_forward_req_sqmask,
    output wire [`SRC_RANGE] ldu2sq_forward_req_load_addr,
    output wire [`LS_SIZE_RANGE] ldu2sq_forward_req_load_size,
    input wire ldu2sq_forward_resp_valid,
    input wire [`SRC_RANGE] ldu2sq_forward_resp_data,
    input wire [`SRC_RANGE] ldu2sq_forward_resp_mask
);
  wire [`RESULT_RANGE] ls_address;
  agu u_agu (
      .src1      (src1),
      .imm       (imm),
      .ls_address(ls_address)
  );
  /* -------------------------------------------------------------------------- */
  /*                            store signal generate                            */
  /* -------------------------------------------------------------------------- */

  wire size_1b;
  wire size_1h;
  wire size_1w;
  wire size_2w;
  assign size_1b = ls_size[0];
  assign size_1h = ls_size[1];
  assign size_1w = ls_size[2];
  assign size_2w = ls_size[3];
  wire [          2:0] shift_size;
  wire [         63:0] opstore_write_mask_qual;
  wire [`RESULT_RANGE] opstore_write_data_qual;

  wire [         63:0] write_1b_mask = {56'b0, {8{1'b1}}};
  wire [         63:0] write_1h_mask = {48'b0, {16{1'b1}}};
  wire [         63:0] write_1w_mask = {32'b0, {32{1'b1}}};
  wire [         63:0] write_2w_mask = {64{1'b1}};

  assign shift_size = ls_address[2:0];
  assign opstore_write_mask_qual = size_1b ? write_1b_mask << (shift_size * 8) : size_1h ? write_1h_mask << (shift_size * 8) : size_1w ? write_1w_mask << (shift_size * 8) : write_2w_mask;
  assign opstore_write_data_qual = src2 << (shift_size * 8);


  /* -------------------------------------------------------------------------- */
  /*                                 output logic                               */
  /* -------------------------------------------------------------------------- */
  wire mmio_valid;
  wire mmio_valid_or_store;
  assign mmio_valid                 = instr_valid & instr_ready & ('h30000000 <= ls_address) & (ls_address <= 'h40700000);
  assign mmio_valid_or_store = mmio_valid | is_store & instr_ready & instr_valid;

  assign memblock_out_store_addr = ls_address;
  assign memblock_out_store_data = opstore_write_data_qual;
  assign memblock_out_store_mask = opstore_write_mask_qual;
  assign memblock_out_store_ls_size = ls_size;

  assign memblock_out_instr_valid   = flush_this_beat ? 1'b0 : mmio_valid_or_store ? 1'b1 : ldu_out_instr_valid;
  assign memblock_out_need_to_wb = mmio_valid_or_store ? is_load : ldu_out_need_to_wb;
  assign memblock_out_prd = mmio_valid_or_store ? prd : ldu_out_prd;
  assign memblock_out_mmio_valid = mmio_valid;
  assign memblock_out_robid = mmio_valid_or_store ? robid : ldu_out_robid;
  assign memblock_out_load_data = mmio_valid_or_store ? 'b0 : ldu_out_load_data;


  /* -------------------------------------------------------------------------- */
  /*                                  load unit                                 */
  /* -------------------------------------------------------------------------- */
  /* --------------------------- output to writeback -------------------------- */
  wire                   ldu_out_instr_valid;
  wire                   ldu_out_need_to_wb;
  wire [    `PREG_RANGE] ldu_out_prd;
  wire [`ROB_SIZE_LOG:0] ldu_out_robid;
  wire [  `RESULT_RANGE] ldu_out_load_data;

  wire                   flush_this_beat;
  assign flush_this_beat = instr_valid & flush_valid & ((flush_robid[`ROB_SIZE_LOG] ^ robid[`ROB_SIZE_LOG]) ^ (flush_robid[`ROB_SIZE_LOG-1:0] < robid[`ROB_SIZE_LOG-1:0]));


  loadunit u_loadunit (
      .clock                       (clock),
      .reset_n                     (reset_n),
      .flush_this_beat             (flush_this_beat),
      .instr_valid                 (instr_valid & is_load & ~mmio_valid),
      .instr_ready                 (instr_ready),
      .prd                         (prd),
      .is_load                     (is_load),
      .is_unsigned                 (is_unsigned),
      .imm                         (imm),
      .src1                        (src1),
      .src2                        (src2),
      .ls_size                     (ls_size),
      .robid                       (robid),
      .sqid                        (sqid),
      .load2arb_tbus_index_valid   (load2arb_tbus_index_valid),
      .load2arb_tbus_index_ready   (load2arb_tbus_index_ready),
      .load2arb_tbus_index         (load2arb_tbus_index),
      .load2arb_tbus_write_data    (load2arb_tbus_write_data),
      .load2arb_tbus_write_mask    (load2arb_tbus_write_mask),
      .load2arb_tbus_read_data     (load2arb_tbus_read_data),
      .load2arb_tbus_operation_done(load2arb_tbus_operation_done),
      .load2arb_tbus_operation_type(load2arb_tbus_operation_type),
      .flush_valid                 (flush_valid),
      .flush_robid                 (flush_robid),
      .mem2dcache_flush            (mem2dcache_flush),
      .ldu_out_instr_valid         (ldu_out_instr_valid),
      .ldu_out_need_to_wb          (ldu_out_need_to_wb),
      .ldu_out_prd                 (ldu_out_prd),
      .ldu_out_robid               (ldu_out_robid),
      .ldu_out_load_data           (ldu_out_load_data),
      /* --------------------------------- forward -------------------------------- */
      .ldu2sq_forward_req_valid    (ldu2sq_forward_req_valid),
      .ldu2sq_forward_req_sqid     (ldu2sq_forward_req_sqid),
      .ldu2sq_forward_req_sqmask   (ldu2sq_forward_req_sqmask),
      .ldu2sq_forward_req_load_addr(ldu2sq_forward_req_load_addr),
      .ldu2sq_forward_req_load_size(ldu2sq_forward_req_load_size),
      .ldu2sq_forward_resp_valid   (ldu2sq_forward_resp_valid),
      .ldu2sq_forward_resp_data    (ldu2sq_forward_resp_data),
      .ldu2sq_forward_resp_mask    (ldu2sq_forward_resp_mask)
  );

endmodule
