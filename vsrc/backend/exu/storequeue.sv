`include "defines.sv"
/* verilator lint_off UNOPTFLAT */
module storequeue (
    input wire clock,
    input wire reset_n,

    //enq from dispatch
    //NOTE:Why enq from dispathch?If enq from IQ(issue queue),ooo memory access could cause load does not hit store.
    input  wire                   disp2sq_valid,
    output wire                   sq_can_alloc,
    input  wire [`ROB_SIZE_LOG:0] disp2sq_robid,
    //debug
    input  wire [      `PC_RANGE] disp2sq_pc,

    /* -------------------------- writeback fill field -------------------------- */
    input wire                   memwb_instr_valid,
    input wire                   memwb_mmio_valid,
    input wire [`ROB_SIZE_LOG:0] memwb_robid,
    input wire [     `SRC_RANGE] memwb_store_addr,
    input wire [     `SRC_RANGE] memwb_store_data,
    input wire [     `SRC_RANGE] memwb_store_mask,
    input wire [            3:0] memwb_store_ls_size,
    /* --------------------------------- commit --------------------------------- */
    input wire                   commit0_valid,
    input wire [`ROB_SIZE_LOG:0] commit0_robid,

    input wire                   commit1_valid,
    input wire [`ROB_SIZE_LOG:0] commit1_robid,

    /* -------------------------- redirect flush logic -------------------------- */
    input wire                     flush_valid,
    input wire [  `ROB_SIZE_LOG:0] flush_robid,
    input wire [`STOREQUEUE_LOG:0] flush_sqid,


    /* ------------------------- sq to dcache port ------------------------ */
    output reg                  sq2arb_tbus_index_valid,
    input  wire                 sq2arb_tbus_index_ready,
    output reg  [`RESULT_RANGE] sq2arb_tbus_index,
    output reg  [   `SRC_RANGE] sq2arb_tbus_write_data,
    output reg  [         63:0] sq2arb_tbus_write_mask,

    input  wire [     `RESULT_RANGE] sq2arb_tbus_read_data,
    output wire [`TBUS_OPTYPE_RANGE] sq2arb_tbus_operation_type,
    input  wire                      sq2arb_tbus_operation_done,

    output wire [    `STOREQUEUE_LOG:0] sq2disp_sqid,
    /* --------------------------- SQ forwarding  -------------------------- */
    input  wire                         ldu2sq_forward_req_valid,
    input  wire [    `STOREQUEUE_LOG:0] ldu2sq_forward_req_sqid,
    input  wire [`STOREQUEUE_DEPTH-1:0] ldu2sq_forward_req_sqmask,
    input  wire [           `SRC_RANGE] ldu2sq_forward_req_load_addr,
    input  wire [       `LS_SIZE_RANGE] ldu2sq_forward_req_load_size,
    output wire                         ldu2sq_forward_resp_valid,
    output wire [           `SRC_RANGE] ldu2sq_forward_resp_data,
    output wire [           `SRC_RANGE] ldu2sq_forward_resp_mask


);
    /* -------------------------------------------------------------------------- */
    /*                         store queue entries entity                         */
    /* -------------------------------------------------------------------------- */


    reg  [   `STOREQUEUE_DEPTH-1:0] sq_entries_enq_valid_dec;
    //pc used to debug
    reg  [               `PC_RANGE] sq_entries_enq_pc_dec           [`STOREQUEUE_DEPTH-1:0];
    reg  [         `ROB_SIZE_LOG:0] sq_entries_enq_robid_dec        [`STOREQUEUE_DEPTH-1:0];

    reg  [   `STOREQUEUE_DEPTH-1:0] sq_entries_wb_valid_dec;
    reg  [   `STOREQUEUE_DEPTH-1:0] sq_entries_wb_mmio_dec;
    //below sig could save
    // reg  [              `SRC_RANGE] sq_entries_wb_store_addr_dec    [`STOREQUEUE_DEPTH-1:0];
    // reg  [              `SRC_RANGE] sq_entries_wb_store_data_dec    [`STOREQUEUE_DEPTH-1:0];
    // reg  [              `SRC_RANGE] sq_entries_wb_store_mask_dec    [`STOREQUEUE_DEPTH-1:0];
    // reg  [                     3:0] sq_entries_wb_store_ls_size_dec [`STOREQUEUE_DEPTH-1:0];


    reg  [         `ROB_SIZE_LOG:0] sq_entries_robid_dec            [`STOREQUEUE_DEPTH-1:0];

    // reg  [   `STOREQUEUE_DEPTH-1:0] sq_entries_commit_dec;
    reg  [   `STOREQUEUE_DEPTH-1:0] sq_entries_issuing_dec;
    reg  [   `STOREQUEUE_DEPTH-1:0] flush_dec;

    wire [   `STOREQUEUE_DEPTH-1:0] sq_entries_ready_to_go_dec;
    wire [   `STOREQUEUE_DEPTH-1:0] sq_entries_valid_dec;
    wire [   `STOREQUEUE_DEPTH-1:0] sq_entries_mmio_dec;

    wire [              `SRC_RANGE] sq_entries_deq_store_addr_dec   [`STOREQUEUE_DEPTH-1:0];
    wire [              `SRC_RANGE] sq_entries_deq_store_data_dec   [`STOREQUEUE_DEPTH-1:0];
    wire [              `SRC_RANGE] sq_entries_deq_store_mask_dec   [`STOREQUEUE_DEPTH-1:0];
    wire [                     3:0] sq_entries_deq_store_ls_size_dec[`STOREQUEUE_DEPTH-1:0];


    /* -------------------------------------------------------------------------- */
    /*                                  pointers                                  */
    /* -------------------------------------------------------------------------- */
    wire [     `STOREQUEUE_LOG : 0] enq_ptr;
    wire [`STOREQUEUE_DEPTH -1 : 0] enq_ptr_oh;

    wire [     `STOREQUEUE_LOG : 0] deq_ptr;
    reg  [`STOREQUEUE_DEPTH -1 : 0] deq_ptr_oh;

    /* -------------------------------------------------------------------------- */
    /*                                  enq logic                                 */
    /* -------------------------------------------------------------------------- */

    wire                            enq_has_avail_entry;
    wire                            enq_fire;
    assign enq_has_avail_entry = |(enq_ptr_oh & ~sq_entries_valid_dec);
    assign enq_fire            = enq_has_avail_entry & disp2sq_valid;

    assign sq_can_alloc        = ~(~enq_has_avail_entry & disp2sq_valid);

    assign sq2disp_sqid        = enq_ptr;

    always @(*) begin
        integer i;
        sq_entries_enq_valid_dec = 'b0;
        if (enq_fire) begin
            for (i = 0; i < `STOREQUEUE_DEPTH; i = i + 1) begin
                sq_entries_enq_valid_dec[i] = enq_ptr_oh[i];
            end
        end
    end

    `MACRO_ENQ_DEC(enq_ptr_oh, sq_entries_enq_robid_dec, disp2sq_robid, `STOREQUEUE_DEPTH)
    `MACRO_ENQ_DEC(enq_ptr_oh, sq_entries_enq_pc_dec, disp2sq_pc, `STOREQUEUE_DEPTH)

    inorder_enq_policy #(
        .QUEUE_SIZE    (`STOREQUEUE_DEPTH),
        .QUEUE_SIZE_LOG(`STOREQUEUE_LOG)
    ) u_inorder_enq_policy (
        .clock      (clock),
        .reset_n    (reset_n),
        .flush_valid(flush_valid),
        .flush_sqid (flush_sqid),
        .enq_fire   (enq_fire),
        .enq_ptr    (enq_ptr),
        .enq_ptr_oh (enq_ptr_oh)
    );



    /* -------------------------------------------------------------------------- */
    /*                           writeback fill logic                             */
    /* -------------------------------------------------------------------------- */



    always @(*) begin
        integer i;
        sq_entries_wb_valid_dec = 'b0;
        if (memwb_instr_valid) begin
            for (i = 0; i < `STOREQUEUE_DEPTH; i = i + 1) begin
                if ((memwb_robid == sq_entries_robid_dec[i])) begin
                    sq_entries_wb_valid_dec[i] = 1'b1;
                end
            end
        end
    end

    always @(*) begin
        integer i;
        sq_entries_wb_mmio_dec = 'b0;
        if (memwb_instr_valid) begin
            for (i = 0; i < `STOREQUEUE_DEPTH; i = i + 1) begin
                if ((memwb_robid == sq_entries_robid_dec[i])) begin
                    sq_entries_wb_mmio_dec[i] = memwb_mmio_valid;
                end
            end
        end
    end


    /* -------------------------------------------------------------------------- */
    /*                             commit wakeup logic                            */
    /* -------------------------------------------------------------------------- */
    reg  [`STOREQUEUE_DEPTH-1:0] commit0_dec;
    reg  [`STOREQUEUE_DEPTH-1:0] commit1_dec;
    wire [`STOREQUEUE_DEPTH-1:0] commits_dec;
    assign commits_dec = commit0_dec | commit1_dec;
    always @(*) begin
        integer i;
        commit0_dec = 'b0;
        if (commit0_valid) begin
            for (i = 0; i < `STOREQUEUE_DEPTH; i = i + 1) begin
                if (sq_entries_valid_dec[i] & (commit0_robid == sq_entries_robid_dec[i])) begin
                    commit0_dec[i] = 1'b1;
                end
            end
        end
    end
    always @(*) begin
        integer i;
        commit1_dec = 'b0;
        if (commit1_valid) begin
            for (i = 0; i < `STOREQUEUE_DEPTH; i = i + 1) begin
                if (sq_entries_valid_dec[i] & (commit1_robid == sq_entries_robid_dec[i])) begin
                    commit1_dec[i] = 1'b1;
                end
            end
        end
    end




    /* -------------------------------------------------------------------------- */
    /*                                 flush logic                                */
    /* -------------------------------------------------------------------------- */

    //when ready togo,cannot flush use robidx,cause idx compare would be lleagal
    always @(flush_valid or flush_robid) begin
        integer i;
        flush_dec = 'b0;
        for (i = 0; i < `STOREQUEUE_DEPTH; i = i + 1) begin
            if (flush_valid) begin
                if (flush_valid & sq_entries_valid_dec[i] & (~sq_entries_ready_to_go_dec[i]) & ((flush_robid[`ROB_SIZE_LOG] ^ sq_entries_robid_dec[i][`ROB_SIZE_LOG]) ^ (flush_robid[`ROB_SIZE_LOG-1:0] <= sq_entries_robid_dec[i][`ROB_SIZE_LOG-1:0]))) begin
                    flush_dec[i] = 1'b1;
                end
            end
        end
    end

    /* -------------------------------------------------------------------------- */
    /*                                  deq logic                                 */
    /* -------------------------------------------------------------------------- */
    wire                         deq_fire;
    wire                         deq_has_req;
    wire                         mmio_fake_fire;
    reg  [`STOREQUEUE_DEPTH-1:0] deq_ptr_mask;

    assign deq_has_req    = (|(deq_ptr_oh & sq_entries_valid_dec & sq_entries_ready_to_go_dec & ~sq_entries_mmio_dec));
    assign mmio_fake_fire = (|(deq_ptr_oh & sq_entries_valid_dec & sq_entries_ready_to_go_dec & sq_entries_mmio_dec));
    assign deq_fire       = deq_has_req & sq2arb_tbus_index_ready | mmio_fake_fire;


    always @(*) begin
        integer i;
        sq_entries_issuing_dec = 'b0;
        if (deq_fire) begin
            for (i = 0; i < `STOREQUEUE_DEPTH; i = i + 1) begin
                sq_entries_issuing_dec[i] = deq_ptr_oh[i];
            end
        end
    end


    always @(*) begin
        integer i;
        deq_ptr_mask = 'b0;
        for (i = 0; i < `STOREQUEUE_DEPTH; i = i + 1) begin
            if (deq_ptr_oh[i] == 1'b0) begin
                deq_ptr_mask[i] = 'b1;
            end else begin
                break;
            end
        end
    end


    inorder_deq_policy #(
        .QUEUE_SIZE    (`STOREQUEUE_DEPTH),
        .QUEUE_SIZE_LOG(`STOREQUEUE_LOG)
    ) u_inorder_deq_policy (
        .clock     (clock),
        .reset_n   (reset_n),
        .deq_fire  (deq_fire),
        .deq_ptr_oh(deq_ptr_oh),
        .deq_ptr   (deq_ptr)
    );


    /* -------------------------------------------------------------------------- */
    /*                                 dcache arb                                 */
    /* -------------------------------------------------------------------------- */

    assign sq2arb_tbus_operation_type = `TBUS_WRITE;

    `MACRO_DEQ_DEC(deq_ptr_oh, sq2arb_tbus_index, sq_entries_deq_store_addr_dec, `STOREQUEUE_DEPTH)
    `MACRO_DEQ_DEC(deq_ptr_oh, sq2arb_tbus_write_data, sq_entries_deq_store_data_dec, `STOREQUEUE_DEPTH)
    `MACRO_DEQ_DEC(deq_ptr_oh, sq2arb_tbus_write_mask, sq_entries_deq_store_mask_dec, `STOREQUEUE_DEPTH)

    assign sq2arb_tbus_index_valid = deq_has_req;



    /* -------------------------------------------------------------------------- */
    /*                                  forwading                                 */
    /* -------------------------------------------------------------------------- */
    // jpz note:below cite from Kunminghu Core.
    // "Compare deqPtr (deqPtr) and forward.sqIdx, we have two cases:
    // (1) if they have the same flag, we need to check range(tail, sqIdx)
    // (2) if they have different flags, we need to check range(tail, VirtualLoadQueueSize) and range(0, sqIdx)""
    wire                         same_flag;
    wire [`STOREQUEUE_DEPTH-1:0] cmp_sqmask;
    assign same_flag  = ldu2sq_forward_req_sqid[`STOREQUEUE_LOG] == deq_ptr[`STOREQUEUE_LOG];
    assign cmp_sqmask = same_flag ? ldu2sq_forward_req_sqmask ^ deq_ptr_mask : ldu2sq_forward_req_sqmask | ~deq_ptr_mask;
    //we can use cam to checkout addr hit
    reg  [`STOREQUEUE_DEPTH-1:0] cmp_addr_hit;
    wire [           `SRC_RANGE] cmp_addr_mask;
    assign cmp_addr_mask = ldu2sq_forward_req_load_size[0] ? {64{1'b1}} : ldu2sq_forward_req_load_size[1] ? {{63{1'b1}}, 1'b0} : ldu2sq_forward_req_load_size[2] ? {{62{1'b1}}, 2'b0} : {{61{1'b1}}, 3'b0};

    always @(*) begin
        integer i;
        cmp_addr_hit = 'b0;
        for (i = 0; i < `STOREQUEUE_DEPTH; i = i + 1) begin
            if (cmp_sqmask[i] & sq_entries_valid_dec[i] & ldu2sq_forward_req_valid) begin
                if ((sq_entries_deq_store_addr_dec[i] & cmp_addr_mask) == (ldu2sq_forward_req_load_addr & cmp_addr_mask)) begin
                    cmp_addr_hit[i] = 1'b1;
                end
            end
        end
    end






    genvar i;
    generate
        for (i = 0; i < `STOREQUEUE_DEPTH; i = i + 1) begin : sq_entity
            sq_entry u_sq_entry (
                .clock                  (clock),
                .reset_n                (reset_n),
                .enq_valid              (sq_entries_enq_valid_dec[i]),
                .enq_robid              (sq_entries_enq_robid_dec[i]),
                .enq_pc                 (sq_entries_enq_pc_dec[i]),
                /* -------------------------- writeback fill field -------------------------- */
                .writeback_valid        (sq_entries_wb_valid_dec[i]),
                .writeback_mmio         (sq_entries_wb_mmio_dec[i]),
                .writeback_store_addr   (memwb_store_addr),
                .writeback_store_data   (memwb_store_data),
                .writeback_store_mask   (memwb_store_mask),
                .writeback_store_ls_size(memwb_store_ls_size),
                .robid                  (sq_entries_robid_dec[i]),
                .commit                 (commits_dec[i]),
                .issuing                (sq_entries_issuing_dec[i]),
                .flush                  (flush_dec[i]),
                .valid                  (sq_entries_valid_dec[i]),
                .mmio                   (sq_entries_mmio_dec[i]),
                .ready_to_go            (sq_entries_ready_to_go_dec[i]),
                .deq_store_addr         (sq_entries_deq_store_addr_dec[i]),
                .deq_store_data         (sq_entries_deq_store_data_dec[i]),
                .deq_store_mask         (sq_entries_deq_store_mask_dec[i]),
                .deq_store_ls_size      (sq_entries_deq_store_ls_size_dec[i])
            );
        end
    endgenerate

    /* verilator lint_off UNOPTFLAT */
endmodule
