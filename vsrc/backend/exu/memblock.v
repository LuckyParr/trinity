`include "defines.sv"
module memblock (
    input  wire                  clock,
    input  wire                  reset_n,
    input  wire                  instr_valid,
    output wire                  instr_ready,
    input  wire [  `INSTR_RANGE] instr, // for debug
    input  wire [     `PC_RANGE] pc,//for debug
    input  wire [`INSTR_ID_WIDTH-1:0] robid,
/* -------------------------- calculation meterial -------------------------- */
    input  wire [    `SRC_RANGE   ] src1    ,
    input  wire [    `SRC_RANGE   ] src2    ,
    input  wire [      `PREG_RANGE] prd     ,
    input  wire [    `SRC_RANGE   ] imm     ,
    input  wire                  is_load    ,
    input  wire                  is_store   ,
    input  wire                  is_unsigned,
    input  wire [`LS_SIZE_RANGE] ls_size    ,

    //input  wire                  predict_taken,
    //input  wire [31:0]           predict_target,  

/* --------------------------- trinity bus channel -------------------------- */
    output reg                  tbus_index_valid,
    input  wire                 tbus_index_ready,
    output reg  [`RESULT_RANGE] tbus_index,
    output reg  [   `SRC_RANGE] tbus_write_data,
    output reg  [         63:0] tbus_write_mask,

    input  wire [ `RESULT_RANGE] tbus_read_data,
    input  wire                 tbus_operation_done,
    output wire [  `TBUS_OPTYPE_RANGE] tbus_operation_type,

/* -------------------------- output to wb pipereg -------------------------- */
    // output valid, pc , inst, robid
    // output wire [ `INSTR_RANGE] out_instr,
    // output wire [    `PC_RANGE] out_pc,
    output wire                        memblock_out_instr_valid,
    output wire [`INSTR_ID_WIDTH-1:0]  memblock_out_robid,
    output wire [`PREG_RANGE]          memblock_out_prd,
    output wire                        memblock_out_need_to_wb,
    output wire                        memblock_out_mmio_valid,
    output wire [`RESULT_RANGE]        memblock_out_opload_rddata, // output rddata at same cycle as operation_done
    output wire [      `INSTR_RANGE ]  memblock_out_instr,//for debug
    output wire [         `PC_RANGE ]  memblock_out_pc, //for debug

    /* -------------------------- redirect flush logic -------------------------- */
    input  wire                          flush_valid,
    input  wire   [`INSTR_ID_WIDTH-1:0]  flush_robid,
    output wire                     mem2dcache_flush // use to flush dcache process

);
    assign memblock_out_pc          =  pc;    
    assign memblock_out_instr       =  instr; //for debug

    wire op_processing;
    //assign instr_ready = ~mem_stall;
    assign instr_ready = ~op_processing;//use this to stop issue queue from issuing, AND with exu ready then connect to isq 

    //when redirect instr from wb pipereg is older than current instr in exu, flush instr in exu
    wire need_flush;
    assign need_flush = flush_valid && ((flush_robid[7]^memblock_out_robid[7])^(flush_robid[6:0] < memblock_out_robid[6:0]));
    assign mem2dcache_flush = need_flush;

    reg                     need_to_wb_latch;
    reg [`INSTR_ID_WIDTH-1:0]               id_latch;
    reg [      `PREG_RANGE] prd_latch;
    assign memblock_out_instr_valid = is_outstanding & (tbus_operation_done) & ~need_flush | memblock_out_mmio_valid;;
    // assign out_instr       = instr;
    // assign out_pc          = pc;
    assign memblock_out_robid          = id_latch;
    assign memblock_out_prd         = prd_latch;
    assign memblock_out_need_to_wb  = need_to_wb_latch;

/* ---------------------------- calculate address --------------------------- */
    wire [`RESULT_RANGE] ls_address;
    agu u_agu (
        .src1      (src1),
        .imm       (imm),
        .ls_address(ls_address)
    );


    localparam IDLE = 2'b00;
    localparam PENDING = 2'b01;
    localparam OUTSTANDING = 2'b10;
    reg  [1:0] ls_state;
    wire       is_idle = ls_state == IDLE;
    wire       is_pending = ls_state == PENDING;
    wire       is_outstanding = ls_state == OUTSTANDING;
    /*
    0 = B
    1 = HALF WORD
    2 = WORD
    3 = DOUBLE WORD
    */
    wire       size_1b = ls_size[0];
    wire       size_1h = ls_size[1];
    wire       size_1w = ls_size[2];
    wire       size_2w = ls_size[3];

    wire       ls_valid = is_load | is_store;


    wire       read_fire = tbus_index_valid & tbus_index_ready & (tbus_operation_type == `TBUS_READ);
    wire       read_pending = tbus_index_valid & ~tbus_index_ready & (tbus_operation_type == `TBUS_READ);


    wire       write_fire = tbus_index_valid & tbus_index_ready & (tbus_operation_type == `TBUS_WRITE);
    wire       write_pending = tbus_index_valid & ~tbus_index_ready & (tbus_operation_type == `TBUS_WRITE);

    reg        outstanding_load_q;
    reg        outstanding_store_q;

    always @(posedge clock or negedge reset_n) begin
        if(~reset_n)begin
            outstanding_load_q <= 'b0;
        end else if(read_fire & ~tbus_operation_done) begin
            outstanding_load_q <= 'b1;
        end else if (tbus_operation_done) begin
            outstanding_load_q <= 'b0;
        end
    end
    always @(posedge clock or negedge reset_n) begin
        if(~reset_n)begin
            outstanding_store_q <= 'b0;
        end else if(write_fire & ~tbus_operation_done) begin
            outstanding_store_q <= 'b1;
        end else if (tbus_operation_done) begin
            outstanding_store_q <= 'b0;
        end
    end

    wire opload_operation_done;
    wire opstore_operation_done;

    assign opload_operation_done = outstanding_load_q & tbus_operation_done;
    assign opstore_operation_done = outstanding_store_q & tbus_operation_done;
    
    wire   mmio_valid = instr_valid & (is_load | is_store) & ('h30000000 <= ls_address) & (ls_address <= 'h40700000);

    always @(posedge clock or negedge reset_n) begin 
        if(reset_n == 1'b0) 
            memblock_out_mmio_valid <= 0; 
        else 
            memblock_out_mmio_valid <= mmio_valid; 
    end

    wire [         63:0] write_1b_mask = {56'b0, {8{1'b1}}};
    wire [         63:0] write_1h_mask = {48'b0, {16{1'b1}}};
    wire [         63:0] write_1w_mask = {32'b0, {32{1'b1}}};
    wire [         63:0] write_2w_mask = {64{1'b1}};

    wire [          2:0] shift_size = ls_address[2:0];

    wire [         63:0] opstore_write_mask_qual = size_1b ? write_1b_mask << (shift_size * 8) : size_1h ? write_1h_mask << (shift_size * 8) : size_1w ? write_1w_mask << (shift_size * 8) : write_2w_mask;

    wire [`RESULT_RANGE] opstore_write_data_qual = src2 << (shift_size * 8);
    reg  [`RESULT_RANGE] opload_read_data_wb_raw;

    always @(*) begin
        if (opload_operation_done) begin
            case ({
                size_1b, size_1h, size_1w, size_2w, is_unsigned
            })

                5'b10001: begin
                    opload_read_data_wb_raw = (tbus_read_data >> ((ls_address[2:0]) * 8));
                    memblock_out_opload_rddata     = {56'h0, opload_read_data_wb_raw[7:0]};
                end
                5'b01001: begin
                    opload_read_data_wb_raw = tbus_read_data >> ((ls_address[2:1]) * 16);
                    memblock_out_opload_rddata     = {48'h0, opload_read_data_wb_raw[15:0]};
                end
                5'b00101: begin
                    opload_read_data_wb_raw = tbus_read_data >> ((ls_address[2]) * 32);
                    memblock_out_opload_rddata     = {32'h0, opload_read_data_wb_raw[31:0]};
                end
                5'b00010: memblock_out_opload_rddata = tbus_read_data;
                5'b10000: begin
                    opload_read_data_wb_raw = tbus_read_data >> ((ls_address[2:0]) * 8);
                    memblock_out_opload_rddata     = {{56{opload_read_data_wb_raw[7]}}, opload_read_data_wb_raw[7:0]};
                end
                5'b01000: begin
                    opload_read_data_wb_raw = tbus_read_data >> ((ls_address[2:1]) * 16);
                    memblock_out_opload_rddata     = {{48{opload_read_data_wb_raw[15]}}, opload_read_data_wb_raw[15:0]};
                end
                5'b00100: begin
                    opload_read_data_wb_raw = tbus_read_data >> ((ls_address[2]) * 32);
                    memblock_out_opload_rddata     = {{32{opload_read_data_wb_raw[31]}}, opload_read_data_wb_raw[31:0]};
                end
                default:  ;
            endcase
        end
    end


    always @(*) begin
        tbus_index_valid    = 'b0;
        tbus_index          = 'b0;
        tbus_write_data     = 'b0;
        tbus_write_mask     = 'b0;
        tbus_operation_type = 'b0;

        if (is_load & instr_valid) begin
            if ((~is_outstanding) & ~mmio_valid) begin
                tbus_index_valid    = 1'b1;
                tbus_index          = ls_address[`RESULT_WIDTH-1:0];
                tbus_operation_type = `TBUS_READ;
            end
        end else if (is_store & instr_valid) begin
            if (~is_outstanding & ~mmio_valid) begin
                tbus_index_valid    = 1'b1;
                tbus_index          = ls_address[`RESULT_WIDTH-1:0];
                tbus_write_mask     = opstore_write_mask_qual;
                tbus_write_data     = opstore_write_data_qual;
                tbus_operation_type = `TBUS_WRITE;
            end
        end else begin

        end

    end

    always @(posedge clock or negedge reset_n) begin
        if (~reset_n) begin
            ls_state <= IDLE;
        end else begin
            case (ls_state)
                IDLE: begin
                    if (read_pending | write_pending) begin
                        ls_state <= PENDING;
                    end else if (read_fire | write_fire) begin
                        ls_state <= OUTSTANDING;
                    end
                end

                PENDING: begin
                    if (read_fire | write_fire) begin
                        ls_state <= OUTSTANDING;
                    end
                end

                OUTSTANDING: begin
                    if (opload_operation_done | opstore_operation_done) begin
                        ls_state <= IDLE;
                    end
                end

                default: ;
            endcase

        end

    end

    //assign mem_stall =  (~is_idle | tbus_index_valid) & //when tbus_index_valid = 1, means lsu have an req due to send, stall immediately
    //                    ~((is_outstanding) & (opload_operation_done | opstore_operation_done)); //when operation done, no need to stall anymore
    assign op_processing = ~idle;                     


    /* -------------------------------------------------------------------------- */
    /* latch input signal when entry is issued from isq, because isq entry valid bit is 0 after selection, so it would not hold itself                               */
    /* -------------------------------------------------------------------------- */
    wire req_fire;
    assign req_fire = write_fire || read_fire;
    always @(posedge clock or negedge reset_n) begin
        if (~reset_n) begin
            need_to_wb_latch <= 'b0;
        end else if (req_fire | mmio_valid) begin
            need_to_wb_latch <= instr_valid & is_load;
        end else if (tbus_operation_done | is_idle) begin
            need_to_wb_latch <= 'b0;
        end
    end

    always @(posedge clock or negedge reset_n) begin
        if (~reset_n) begin
            prd_latch <= 'b0;
        end else if (req_fire | mmio_valid) begin
            prd_latch <= prd;
        end else if (tbus_operation_done | is_idle) begin
            prd_latch <= 'b0;
        end
    end

    always @(posedge clock or negedge reset_n) begin
        if (~reset_n) begin
            id_latch <= 'b0;
        end else if (req_fire | mmio_valid) begin
            id_latch <= robid;
        end else if (tbus_operation_done | is_idle) begin
            id_latch <= 'b0;
        end
    end



endmodule
