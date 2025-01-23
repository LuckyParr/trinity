`timescale 1ns / 1ps

module rob #(
    parameter DATA_WIDTH   = 124, // 64 pc + 32 instr + 5 lrs1 + 5 lrs2 + 5 lrd + 6 prd + 6 old_prd + 1 rd_valid = 124 bits
    parameter DEPTH        = 64,  // Queue depth set to 64
    parameter STATUS_WIDTH = 1 ,   // Status bitwidth set to 1: "complete" or "ready to commit"
    parameter DEPTH_LOG    = 6,
    parameter ADDR_WIDTH  = $clog2(DEPTH), // 6 bit
    parameter INDEX_WIDTH = $clog2(DEPTH) + 1  // 6 bit + 1 bit flaf

)(
    input  clock,
    input  reset_n,  // Active-low reset

    // Write Port 0
    input                  wr_en0,
    input [DATA_WIDTH-1:0] wr_data0,

    // Write Port 1
    input                  wr_en1,
    input [DATA_WIDTH-1:0] wr_data1,

    // Status Write Port 0
    input                       status_wren0,
    input [ADDR_WIDTH-1:0]      status_wraddr0,
    input [STATUS_WIDTH-1:0]    status_wrdata0,

    // Status Write Port 1
    input                       status_wren1,
    input [ADDR_WIDTH-1:0]      status_wraddr1,
    input [STATUS_WIDTH-1:0]    status_wrdata1,

    // Commit Port (newly added):
    output reg                  commit_valid,       // Indicates that commit_data is valid this cycle
    output reg [DATA_WIDTH-1:0] commit_data,        // Data of the entry being committed

    // // Status Flags
    // output full,
    // output empty,

    //rob2 
    output wire [INDEX_WIDTH-1:0] rob2disp_instr_cnt, //7 bit
    output wire [INDEX_WIDTH-1:0] rob2disp_instr_id, //7 bit

    //flush signal
    input wire                          flush_valid,
    input wire [63:0]                   flush_target,
    input wire [`INSTR_ID_WIDTH-1:0]    flush_id, 
    //walk signal
    output wire is_idle,
    output wire is_rollingback,
    output wire is_walking

);

    // Queue storage arrays
    reg [DATA_WIDTH-1:0]   cqentry_data   [0:DEPTH-1];
    reg                    cqentry_valid  [0:DEPTH-1];
    reg [INDEX_WIDTH-1:0]  cqentry_index  [0:DEPTH-1];
    reg [STATUS_WIDTH-1:0] cqentry_status [0:DEPTH-1];

    // Pointers and counters
    reg [ADDR_WIDTH-1:0]     enqueue_ptr  ;  // points to the next location to write
    reg [ADDR_WIDTH-1:0]     dequeue_ptr  ;  // points to the next location to commit (read out)
    //reg [$clog2(DEPTH):0]  wr_count      = 0;  // total number of entries written
    //reg [$clog2(DEPTH):0]  rd_count      = 0;  // total number of entries removed via commit
    reg [INDEX_WIDTH-1:0]    instr_id ;  // increments for each new entry

    // // Status flags
    // assign full  = ((wr_count - rd_count) >= DEPTH);
    // assign empty = (wr_count == rd_count);
    reg [INDEX_WIDTH-1:0] instr_avail_cnt;//represent available instr number in rob
    assign rob2disp_instr_cnt = instr_avail_cnt;// what to do in flush, can be send with flush signal from intblock
    assign rob2disp_instr_id = instr_id;
    //--------------------------------------------------------------------------
    // Write Logic
    //--------------------------------------------------------------------------
    integer i;
    integer write_count;
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            enqueue_ptr   <= 0;
            //wr_count      <= 0;
            instr_id <= 0;
            instr_avail_cnt <= 0;
            // Reset all queue entries
            for (i = 0; i < DEPTH; i = i + 1) begin
                cqentry_data[i]   <= {DATA_WIDTH{1'b0}};
                cqentry_valid[i]  <= 1'b0;
                cqentry_index[i]  <= {INDEX_WIDTH{1'b0}};
                cqentry_status[i] <= {STATUS_WIDTH{1'b0}};
            end
        end else if (current_state == IDLE && next_state == ROLLBACK)begin // when flush_valid, ROLLBACK enqueue_ptr to flush_id
                enqueue_ptr <= flush_id[5:0]+1; // rollback enqueue ptr
                instr_id <= flush_id + 1;       // rollback instr_id
                cqentry_valid <= cqentry_unflush_valid;   // rollback valid vector 
        end else begin
            // Count how many writes are requested in this cycle
            write_count = wr_en0 + wr_en1;
            if (write_count == 1 && wr_en0 && !full) begin
                cqentry_data[enqueue_ptr]   <= wr_data0;
                cqentry_valid[enqueue_ptr]  <= 1'b1;
                cqentry_index[enqueue_ptr]  <= instr_id;
                cqentry_status[enqueue_ptr] <= {STATUS_WIDTH{1'b0}}; // status defaults to 0

                enqueue_ptr   <= (enqueue_ptr + 1) % DEPTH;
                instr_avail_cnt <= instr_avail_cnt + 1 ;
                //wr_count      <= wr_count + 1;
                instr_id <= instr_id + 1;
            end else if (write_count == 2 && wr_en1 && !full) begin
                cqentry_data[enqueue_ptr]   <= wr_data0;
                cqentry_valid[enqueue_ptr]  <= 1'b1;
                cqentry_index[enqueue_ptr]  <= instr_id;
                cqentry_status[enqueue_ptr] <= {STATUS_WIDTH{1'b0}}; // status defaults to 0

                cqentry_data[enqueue_ptr+1]   <= wr_data1;
                cqentry_valid[enqueue_ptr+1]  <= 1'b1;
                cqentry_index[enqueue_ptr+1]  <= instr_id+1;
                cqentry_status[enqueue_ptr+1] <= {STATUS_WIDTH{1'b0}};

                enqueue_ptr   <= (enqueue_ptr + 2) % DEPTH;
                instr_avail_cnt <= instr_avail_cnt + 2 ;
                //wr_count      <= wr_count + 2;
                instr_id <= instr_id + 2;
            end
        end
    end

    //--------------------------------------------------------------------------
    // Status Write Logic
    //--------------------------------------------------------------------------
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            for (i = 0; i < DEPTH; i = i + 1) begin
                cqentry_status[i] <= {STATUS_WIDTH{1'b0}};
            end
        end
        else begin
            // Status Write Port 0
            if (status_wren0 && (status_wraddr0 < DEPTH)) begin
                cqentry_status[status_wraddr0] <= status_wrdata0;
            end

            // Status Write Port 1
            if (status_wren1 && (status_wraddr1 < DEPTH)) begin
                cqentry_status[status_wraddr1] <= status_wrdata1;
            end
        end
    end

    //--------------------------------------------------------------------------
    // Commit Logic (new)
    //--------------------------------------------------------------------------
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            dequeue_ptr  <= 0;
            //rd_count     <= 0;
            commit_valid <= 0;
            commit_data  <= {DATA_WIDTH{1'b0}};
        end
        else begin
            // Default: no commit unless conditions are met
            commit_valid <= 0;

            // Check if queue is non-empty AND
            // status bit at dequeue_ptr is set (indicating "ready to commit").
            if (!empty && cqentry_status[dequeue_ptr] == 1'b1) begin
                commit_valid   <= 1'b1;
                commit_data    <= cqentry_data[dequeue_ptr];

                // "Remove" from the queue
                cqentry_valid[dequeue_ptr] <= 1'b0; // Invalidate
                dequeue_ptr               <= (dequeue_ptr + 1) % DEPTH;
                instr_avail_cnt <= instr_avail_cnt - 1 ;
                //rd_count                  <= rd_count + 1;
            end
        end
    end

/* ---------------------------- flush walk logic ---------------------------- */
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
        IDLE:
            if(flush_valid)begin
                next_state = ROLLBACK;        
            end else begin
                next_state = IDLE;
            end
        ROLLBACK:
            next_state = WALK;
        WALK:
            if(cqentry_valid[walking_ptr+1] == 0)begin
                next_state = IDLE;
            end else begin
                next_state = WALK;
            end
        default: 
    endcase
end

//roll back cqentry_valid vector logic
reg  cqentry_needflush_valid  [0:DEPTH-1];
always @(*) begin
    for(i = 0; i<DEPTH;i=i+1)begin
        if(current_state == IDLE && next_state == ROLLBACK)begin
            if(enqueue_ptr > flush_id[5:0])begin
                cqentry_needflush_valid[i] = (i[DEPTH_LOG-1:0] > flush_id[5:0]) & (i[DEPTH_LOG-1:0] < enqueue_ptr);
            end else begin
                cqentry_needflush_valid[i] = (i[DEPTH_LOG-1:0] > flush_id[5:0]) | (i[DEPTH_LOG-1:0] < enqueue_ptr);
            end
        end
    end
end

wire cqentry_unflush_valid [0:DEPTH-1];
assign cqentry_unflush_valid = ~cqentry_needflush_valid;

//walk logic
    reg [ADDR_WIDTH-1:0]  walking_ptr ;  // points to the next location to commit (read out)
    always @(posedge clock or negedge reset_n) begin
        if (~reset_n) begin
            walking_ptr <= 0;
        end else if (is_rollingback) begin
            walking_ptr <= dequeue_ptr;
        end else if (is_walking) begin
            walking_ptr <= walking_ptr + 'd2;
        end
    end




endmodule
