module rob 
(
    input wire               clock,
    input wire               reset_n,
    //ready sigs,cause dispathc only can dispatch when rob,IQ,SQ both have avail entry
    input wire               iq_can_alloc0,
    input wire               iq_can_alloc1,
    input wire               sq_can_alloc,
    //rob enq logic
    input wire               instr0_enq_valid,
    input wire [  `PC_RANGE] instr0_pc,
    input wire [       31:0] instr0,
    input wire [`LREG_RANGE] instr0_lrs1,
    input wire [`LREG_RANGE] instr0_lrs2,
    input wire [`LREG_RANGE] instr0_lrd,
    input wire [`PREG_RANGE] instr0_prd,
    input wire [`PREG_RANGE] instr0_old_prd,
    input wire               instr0_need_to_wb,

    input wire               instr1_enq_valid,
    input wire [  `PC_RANGE] instr1_pc,
    input wire [       31:0] instr1,
    input wire [`LREG_RANGE] instr1_lrs1,
    input wire [`LREG_RANGE] instr1_lrs2,
    input wire [`LREG_RANGE] instr1_lrd,
    input wire [`PREG_RANGE] instr1_prd,
    input wire [`PREG_RANGE] instr1_old_prd,
    input wire               instr1_need_to_wb,

    //counter(temp sig)
    output reg [`ROB_SIZE_LOG-1:0] counter,

    //robidx output put
    output reg [`ROB_SIZE_LOG:0] enqueue_ptr,//id send to dispatch

    //write back port
    input wire                     writeback0_valid,
    input wire [`ROB_SIZE_LOG:0]   writeback0_robid,
    input wire                     writeback0_need_to_wb,

    input wire                     writeback1_valid,
    input wire [`ROB_SIZE_LOG:0]   writeback1_robid,
    input wire                     writeback1_need_to_wb,
    input wire                     writeback1_mmio,

    input wire                     writeback2_valid,
    input wire [`ROB_SIZE_LOG:0]   writeback2_robid,
    input wire                     writeback2_need_to_wb,

    //commit port
    output wire                     commits0_valid,
    output wire [        `PC_RANGE] commits0_pc,
    output wire [             31:0] commits0_instr,
    output wire [      `LREG_RANGE] commits0_lrd,
    output wire [      `PREG_RANGE] commits0_prd,
    output wire [      `PREG_RANGE] commits0_old_prd,
    output wire                     commits0_need_to_wb,   //used to write arch rat
    output wire [`ROB_SIZE_LOG-1:0] commits0_robidx,       //used to wakeup storequeue
    // debug
    output wire                     commits0_skip,


    output wire                     commits1_valid,
    output wire [        `PC_RANGE] commits1_pc,
    output wire [             31:0] commits1_instr,
    output wire [      `LREG_RANGE] commits1_lrd,
    output wire [      `PREG_RANGE] commits1_prd,
    output wire [      `PREG_RANGE] commits1_old_prd,
    output wire [`ROB_SIZE_LOG-1:0] commits1_robidx,
    output wire                     commits1_need_to_wb,
    // debug
    output wire                     commits1_skip,

    //flush
    input wire                     flush_valid,
    input wire [             63:0] flush_target,
    input wire [`ROB_SIZE_LOG-1:0] flush_robidx,

    /* ------------------------------- walk logic ------------------------------- */
    output reg  [        1:0] rob_state,
    output wire               rob_walk0_valid,
    output wire               rob_walk0_complete,
    output wire [`LREG_RANGE] rob_walk0_lrd,
    output wire [`PREG_RANGE] rob_walk0_prd,
    output wire               rob_walk1_valid,
    output wire [`LREG_RANGE] rob_walk1_lrd,
    output wire [`PREG_RANGE] rob_walk1_prd,
    output wire               rob_walk1_complete

); 
/* ----------------------------- internal signal ---------------------------- */
    reg  [    `ROB_SIZE-1:0] enq_dec;
    reg  [        `PC_RANGE] enq_pc_dec                   [0:`ROB_SIZE-1];
    reg  [             31:0] enq_instr_dec                [0:`ROB_SIZE-1];
    reg  [      `LREG_RANGE] enq_lrd_dec                  [0:`ROB_SIZE-1];
    reg  [      `PREG_RANGE] enq_prd_dec                  [0:`ROB_SIZE-1];
    reg  [      `PREG_RANGE] enq_old_prd_dec              [0:`ROB_SIZE-1];
    reg  [    `ROB_SIZE-1:0] enq_need_to_wb_dec;

    wire [    `ROB_SIZE-1:0] entry_valid_dec;
    wire [    `ROB_SIZE-1:0] entry_dec;
    wire [        `PC_RANGE] entry_pc_dec                   [0:`ROB_SIZE-1];
    wire [             31:0] entry_instr_dec                [0:`ROB_SIZE-1];
    wire [      `LREG_RANGE] entry_lrd_dec                  [0:`ROB_SIZE-1];
    wire [      `PREG_RANGE] entry_prd_dec                  [0:`ROB_SIZE-1];
    wire [      `PREG_RANGE] entry_old_prd_dec              [0:`ROB_SIZE-1];
    wire [    `ROB_SIZE-1:0] entry_need_to_wb_dec;
    wire [    `ROB_SIZE-1:0] entry_skip_dec;
    wire [    `ROB_SIZE-1:0] entry_complete_dec;

    reg [`ROB_SIZE-1:0] wb_set_complete_dec;
    reg [`ROB_SIZE-1:0] wb_set_skip_dec;

    reg  [    `ROB_SIZE-1:0] commit_vld_dec;
    reg  [    `ROB_SIZE-1:0] flush_vld_dec;

    wire                     instr0_actually_enq;
    wire                     instr1_actually_enq;

    reg [`ROB_SIZE_LOG:0] dequeue_ptr; // 7bit:contain flag
    reg [`ROB_SIZE_LOG:0] walking_ptr; // 7bit:contain flag


/* ------------------------ update enqueue_ptr[`ROB_SIZE_LOG-1:0] logic ------------------------ */
    always @(*) begin
        integer i;
        for (i = 0; i < `ROB_SIZE; i = i + 1) begin
            enq_valid_dec[i] = 'b0;
            if (instr0_actually_enq & (enqueue_ptr[`ROB_SIZE_LOG-1:0] == i[`ROB_SIZE_LOG-1:0])) begin
                enq_valid_dec[i] = 1'b1;
            end
            if (instr1_actually_enq & ((enqueue_ptr[`ROB_SIZE_LOG-1:0] + 1) == i[`ROB_SIZE_LOG-1:0])) begin
                enq_valid_dec[i+1] = 1'b1;
            end
        end
    end

    reg  [  `ROB_SIZE_LOG:0] enq_num;
    always @(*) begin
        integer i;
        enq_num = 'b0;
        for (i = 0; i < `ROB_SIZE; i = i + 1) begin
            if (enq_valid_dec[i]) begin
                enq_num = enq_num + 1;
            end
        end
    end

    always @(posedge clock or negedge reset_n) begin
        if(~reset_n)begin
            enqueue_ptr <=0;
        end else if(is_rollingback) begin
            enqueue_ptr <= flush_robid + 1;
        end else begin
            enqueue_ptr <= enqueue_ptr + enq_num;         
        end
    end



    /* -------------------------------------------------------------------------- */
    /*                        enq information to dec format                       */
    /* -------------------------------------------------------------------------- */

    always @(*) begin
        integer i;
        for (i = 0; i < `ROB_SIZE; i = i + 1) begin
            entry_pc_dec[i] = 'b0;
            if (instr0_enq_valid & (enqueue_ptr[`ROB_SIZE_LOG-1:0] == i[`ROB_SIZE_LOG-1:0])) begin
                entry_pc_dec[i] = instr0_pc;
            end
            if (instr1_enq_valid & ((enqueue_ptr[`ROB_SIZE_LOG-1:0] + 1) == i[`ROB_SIZE_LOG-1:0])) begin
                entry_pc_dec[i] = instr1_pc;
            end
        end
    end
    always @(*) begin
        integer i;
        for (i = 0; i < `ROB_SIZE; i = i + 1) begin
            entry_instr_dec[i] = 'b0;
            if (instr0_enq_valid & (enqueue_ptr[`ROB_SIZE_LOG-1:0] == i[`ROB_SIZE_LOG-1:0])) begin
                entry_instr_dec[i] = instr0;
            end
            if (instr1_enq_valid & ((enqueue_ptr[`ROB_SIZE_LOG-1:0] + 1) == i[`ROB_SIZE_LOG-1:0])) begin
                entry_instr_dec[i] = instr1;
            end
        end
    end
    always @(*) begin
        integer i;
        for (i = 0; i < `ROB_SIZE; i = i + 1) begin
            entry_lrd_dec[i] = 'b0;
            if (instr0_enq_valid & (enqueue_ptr[`ROB_SIZE_LOG-1:0] == i[`ROB_SIZE_LOG-1:0])) begin
                entry_lrd_dec[i] = instr0_lrd;
            end
            if (instr1_enq_valid & ((enqueue_ptr[`ROB_SIZE_LOG-1:0] + 1) == i[`ROB_SIZE_LOG-1:0])) begin
                entry_lrd_dec[i] = instr1_lrd;
            end
        end
    end
    always @(*) begin
        integer i;
        for (i = 0; i < `ROB_SIZE; i = i + 1) begin
            entry_prd_dec[i] = 'b0;
            if (instr0_enq_valid & (enqueue_ptr[`ROB_SIZE_LOG-1:0] == i[`ROB_SIZE_LOG-1:0])) begin
                entry_prd_dec[i] = instr0_prd;
            end
            if (instr1_enq_valid & ((enqueue_ptr[`ROB_SIZE_LOG-1:0] + 1) == i[`ROB_SIZE_LOG-1:0])) begin
                entry_prd_dec[i] = instr1_prd;
            end
        end
    end
    always @(*) begin
        integer i;
        for (i = 0; i < `ROB_SIZE; i = i + 1) begin
            entry_old_prd_dec[i] = 'b0;
            if (instr0_enq_valid & (enqueue_ptr[`ROB_SIZE_LOG-1:0] == i[`ROB_SIZE_LOG-1:0])) begin
                entry_old_prd_dec[i] = instr0_old_prd;
            end
            if (instr1_enq_valid & ((enqueue_ptr[`ROB_SIZE_LOG-1:0] + 1) == i[`ROB_SIZE_LOG-1:0])) begin
                entry_old_prd_dec[i] = instr1_old_prd;
            end
        end
    end
    always @(*) begin
        integer i;
        for (i = 0; i < `ROB_SIZE; i = i + 1) begin
            entry_need_to_wb_dec[i] = 'b0;
            if (instr0_enq_valid & (enqueue_ptr[`ROB_SIZE_LOG-1:0] == i[`ROB_SIZE_LOG-1:0])) begin
                entry_need_to_wb_dec[i] = instr0_need_to_wb;
            end
            if (instr1_enq_valid & ((enqueue_ptr[`ROB_SIZE_LOG-1:0] + 1) == i[`ROB_SIZE_LOG-1:0])) begin
                entry_need_to_wb_dec[i] = instr1_need_to_wb;
            end
        end
    end


/* ---------------------------- write back logic ---------------------------- */


    always @(*) begin
        integer i;
        for (i = 0; i < `ROB_SIZE; i = i + 1) begin
            wb_set_complete_dec[i] = 'b0;
            if (writeback0_valid & (writeback0_robid[`ROB_SIZE_LOG-1:0] == i[`ROB_SIZE_LOG-1:0])) begin
                wb_set_complete_dec[i] = 1'b1;
            end
            if (writeback1_valid & (writeback1_robid[`ROB_SIZE_LOG-1:0] == i[`ROB_SIZE_LOG-1:0])) begin
                wb_set_complete_dec[i] = 1'b1;
            end
            if (writeback2_valid & (writeback2_robid[`ROB_SIZE_LOG-1:0] == i[`ROB_SIZE_LOG-1:0])) begin
                wb_set_complete_dec[i] = 1'b1;
            end
        end
    end

    //for now only l/s could trigger skip
    always @(*) begin
        integer i;
        for (i = 0; i < `ROB_SIZE; i = i + 1) begin
            wb_set_skip_dec[i] = 'b0;
            if (writeback1_valid & writeback1_mmio & (writeback1_robid[`ROB_SIZE_LOG-1:0] == i[`ROB_SIZE_LOG-1:0])) begin
                wb_set_skip_dec[i] = 1'b1;
            end
        end
    end


/* ------------------------------ dequeue logic ----------------------------- */
    always @(*) begin
        integer i;
        for (i = 0; i < `ROB_SIZE; i = i + 1) begin
            commit_vld_dec[i] = 'b0;
            if (ready_to_commit_dec[i] & (dequeue_ptr[`ROB_SIZE_LOG-1:0] == i[`ROB_SIZE_LOG-1:0])) begin
                commit_vld_dec[i] = 1'b1;
            end
        end
    end

    always @(*) begin
        integer i;
        deq_num = 'b0;
        for (i = 0; i < `ROB_SIZE; i = i + 1) begin
            if (commit_vld_dec[i]) begin
                deq_num = deq_num + 1;
            end
        end
    end


    always @(posedge clock or negedge reset_n) begin
        if(~reset_n)begin
            dequeue_ptr <=0;
        end else begin
            dequeue_ptr <= dequeue_ptr + deq_num;         
        end
    end

/* -------------------------- output commit signal -------------------------- */
    assign commit0_valid       = commit_vld_dec[dequeue_ptr[`ROB_SIZE_LOG-1:0]];
    assign commit0_pc          = entry_pc_dec[dequeue_ptr[`ROB_SIZE_LOG-1:0]];
    assign commit0_instr       = entry_instr_dec[dequeue_ptr[`ROB_SIZE_LOG-1:0]];
    assign commit0_lrd         = entry_lrd_dec[dequeue_ptr[`ROB_SIZE_LOG-1:0]];
    assign commit0_prd         = entry_prd_dec[dequeue_ptr[`ROB_SIZE_LOG-1:0]];
    assign commit0_old_prd     = entry_old_prd_dec[dequeue_ptr[`ROB_SIZE_LOG-1:0]];
    assign commit0_robid       = dequeue_ptr;
    assign commit0_need_to_wb  = entry_need_to_wb_dec[dequeue_ptr[`ROB_SIZE_LOG-1:0]];
    //debug
    assign commit0_skip        = entry_skip_dec[dequeue_ptr[`ROB_SIZE_LOG-1:0]];



//
    reg [`ROB_SIZE_LOG-1:0] counter;
    always @(posedge clock or negedge reset_n) begin
        if (~reset_n) begin
            counter <= 'b0;
        end else begin
            counter <= counter + enq_num[`ROB_SIZE_LOG-1:0] - deq_num[`ROB_SIZE_LOG-1:0];
        end
    end

/* ------------------------------- flush logic ------------------------------ */
    localparam IDLE = 2'b00;
    localparam ROLLBACK = 2'b01;
    localparam WALK = 2'b10;

    assign is_idle = current_state == IDLE;
    assign is_rollingback = current_state == ROLLBACK;
    assign is_walking = current_state == WALK;

    reg [1:0] current_state;
    reg [1:0] next_state;

    always @(posedge clock or negedge reset_n) begin
        if(~reset_n)begin
            current_state <= 0;
        end else begin
            current_state <= next_state;
        end
    end

    always @(*) begin
        case (current_state)
            IDLE:begin
                if(flush_valid)begin
                    next_state = ROLLBACK;        
                end else begin
                    next_state = IDLE;
                end
            end
            ROLLBACK:begin
                if(flush_valid)begin
                    next_state = ROLLBACK;                    
                end else begin
                    next_state = WALK;                    
                end
            end
            WALK:begin
                if(flush_valid)begin
                    next_state = ROLLBACK;                    
                end else if(entry_valid_dec[walking_ptr+1] == 0)begin
                    next_state = IDLE;
                end else begin
                    next_state = WALK;
                end
            end
            default: begin
                
            end
        endcase
    end

    reg [`ROB_SIZE_LOG:0] walking_ptr_latch; // 7bit:contain flag

    always @(posedge clock or negedge reset_n) begin
        if (~reset_n) begin
            walking_ptr_latch <= 'b0;
        end else if (flush_valid) begin
            walking_ptr_latch <= walking_ptr;
        end
    end

    always @(*) begin
        integer i;
        flush_vld_dec = 'b0;
        for (i = 0; i < `ROB_SIZE; i = i + 1) begin
            if (is_rollingback) begin
                    flush_vld_dec[i] = flush_robid[`ROB_SIZE_LOG] ^ dequeue_ptr[`ROB_SIZE_LOG] ^ (flush_robid[`ROB_SIZE_LOG-1:0] < dequeue_ptr[`ROB_SIZE_LOG-1:0]);
                end
            end
        end

/* ------------------------------- walk logic ------------------------------- */

    always @(posedge clock or negedge reset_n) begin
        if (~reset_n) begin
            walking_ptr <= 'b0;
        end else if (is_ovwr) begin
            walking_ptr <= dequeue_ptr;
        end else if (is_walking) begin
            walking_ptr <= walking_ptr + 'd2;
        end
    end

    assign rob_walk0_valid    = entry_valid_dec[walking_idx] & entry_need_to_wb_dec[walking_idx] & is_walking;
    assign rob_walk0_lrd      = entry_lrd_dec[walking_idx];
    assign rob_walk0_prd      = entry_prd_dec[walking_idx];
    assign rob_walk0_complete = entry_complete_dec[walking_idx];

    assign rob_walk1_valid    = entry_valid_dec[walking_idx+'b1] & entry_need_to_wb_dec[walking_idx+'b1] & is_walking;
    assign rob_walk1_lrd      = entry_lrd_dec[walking_idx+'b1];
    assign rob_walk1_prd      = entry_prd_dec[walking_idx+'b1];
    assign rob_walk1_complete = entry_complete_dec[walking_idx+'b1];


/* ----------------------------- internal signal ---------------------------- */


    assign instr0_actually_enq = instr0_enq_valid & iq_can_alloc0 & sq_can_alloc;
    assign instr1_actually_enq = instr1_enq_valid & iq_can_alloc1;    

    genvar i;
    generate
        for (i = 0; i < `ROB_SIZE; i = i + 1) begin : rob_entity
            robentry u_robentry(
                .clock            (clock                  ),//i
                .reset_n          (reset_n                ),//i
                .enq_valid        (enq_valid_dec[i]       ),//i
                .enq_pc           (enq_pc_dec[i]          ),//i
                .enq_instr        (enq_instr_dec[i]       ),//i
                .enq_lrd          (enq_lrd_dec[i]         ),//i
                .enq_prd          (enq_prd_dec[i]         ),//i
                .enq_old_prd      (enq_old_prd_dec[i]     ),//i
                .enq_need_to_wb   (enq_need_to_wb_dec[i]  ),//i
                .enq_skip         ('b0                    ),//i
                .wb_set_complete  (wb_set_complete_dec[i] ),//i
                .wb_set_skip      (wb_set_skip_dec[i]     ),//i
                .entry_valid      (entry_valid_dec[i]     ),//output
                .ready_to_commit  (ready_to_commit_dec[i] ),//output
                .entry_complete   (entry_complete_dec[i]  ),//output
                .entry_pc         (entry_pc_dec[i]        ),//output
                .entry_instr      (entry_instr_dec[i]     ),//output
                .entry_lrd        (entry_lrd_dec[i]       ),//output
                .entry_prd        (entry_prd_dec[i]       ),//output
                .entry_old_prd    (entry_old_prd_dec[i]   ),//output
                .entry_need_to_wb (entry_need_to_wb_dec[i]),//output
                .entry_skip       (entry_skip_dec[i]      ),//output
                .commit_vld   (commit_vld_dec[i]  ),//i
                .flush_vld    (flush_vld_dec[i]   ) //i
                );
        end
    endgenerate

endmodule
