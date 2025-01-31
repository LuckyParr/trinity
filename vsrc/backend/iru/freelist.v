`timescale 1ns / 1ps
module freelist #(
    parameter DATA_WIDTH = 6,  //data store physical reg number
    parameter DEPTH      = 32  //number of free ohysical reg
)(
    input clock,
    input reset_n,                      // Active-low reset signal

    // Write Port 0
    //input wr_en0,
    input commit0_valid,
    input commit0_need_to_wb,
    input [DATA_WIDTH-1:0] commit0_old_prd,

    // Write Port 1
    //input wr_en1,
    input commit1_valid,
    input commit1_need_to_wb,
    input [DATA_WIDTH-1:0] commit1_old_prd,

    // Read Port 0
    input rn2fl_instr0_lrd_valid,
    output reg [DATA_WIDTH-1:0] fl2rn_instr0prd,

    // Read Port 1
    input rn2fl_instr1_lrd_valid,
    output reg [DATA_WIDTH-1:0] fl2rn_instr1prd,

    //walk signal
    input wire [1:0] rob_state;
    input wire walking_valid0,
    input wire walking_valid1,

);

    wire wr_en0 = commit0_valid && commit0_need_to_wb;
    wire wr_en1 = commit1_valid && commit1_need_to_wb;

    wire is_idle;
    wire is_rollback;
    wire is_walk;

    assign is_idle = (rob_state == `ROB_STATE_IDLE);
    assign is_rollback = (rob_state == `ROB_STATE_ROLLIBACK);
    assign is_walk = (rob_state == `ROB_STATE_WALK);



    // ----------------------------------------------------------
    // Local Parameters
    // ----------------------------------------------------------
    localparam ADDR_WIDTH  = $clog2(DEPTH);    // For DEPTH=32, ADDR_WIDTH=5

    // ----------------------------------------------------------
    // Memory arrays to hold data, validity
    // ----------------------------------------------------------
    reg [DATA_WIDTH-1:0] mem      [0:DEPTH-1];
    reg                  valid_mem[0:DEPTH-1];

    // ----------------------------------------------------------
    // Write Pointer, Read Pointer
    // ----------------------------------------------------------
    reg [ADDR_WIDTH-1:0] enqueue_ptr = 0;   // write pointer
    reg [ADDR_WIDTH-1:0] dequeue_ptr = 0;   // read pointer

 integer i;
integer write_count;
integer read_count;

always @(posedge clock or negedge reset_n) begin
    if (!reset_n) begin
        // ----------------------------------------------------------
        // Reset logic for both read and write
        // ----------------------------------------------------------
        enqueue_ptr <= 0;
        dequeue_ptr <= 0;
        rd_count    <= 0;
        // (If you have wr_count or other counters, reset them here as well)

        for (i = 0; i < DEPTH; i = i + 1) begin
            mem[i]       <= (i[5:0] + 6'd32);
            valid_mem[i] <= 1'b1;
        end

    end else begin
        // ----------------------------------------------------------
        // Write Operations
        // ----------------------------------------------------------
        write_count = wr_en0 + wr_en1;
        // Single write
        if (write_count == 1 && wr_en0 ) begin
            mem[enqueue_ptr]       <= commit0_old_prd;
            valid_mem[enqueue_ptr] <= 1'b1;            
            enqueue_ptr <= (enqueue_ptr + 1) % DEPTH;
        // Double write
        end else if (write_count == 2 && wr_en1 ) begin
            mem[enqueue_ptr]         <= commit0_old_prd;
            valid_mem[enqueue_ptr]   <= 1'b1;
            mem[enqueue_ptr + 1]     <= commit1_old_prd;
            valid_mem[enqueue_ptr + 1] <= 1'b1;
            enqueue_ptr <= (enqueue_ptr + 2) % DEPTH;
        end

        // ----------------------------------------------------------
        // Flush Operations
        // ----------------------------------------------------------
        if (is_rollback) begin
            // Roll back the dequeue pointer to enqueue pointer
            dequeue_ptr <= enqueue_ptr;

        end else if (is_walk) begin
            // "Walking" logic updates
            dequeue_ptr <= dequeue_ptr + walking_valid0 + walking_valid1;

            if (walking_valid0) begin
                valid_mem[dequeue_ptr] <= 1'b1; // restore valid
                mem[dequeue_ptr]       <= walking_old_prd0;
            end
            
            if (walking_valid1) begin
                valid_mem[dequeue_ptr + 1] <= 1'b1; // restore valid
                mem[dequeue_ptr + 1]       <= walking_old_prd1;
            end
        // ----------------------------------------------------------
        // Read Operations
        // ----------------------------------------------------------

        end else begin
            // Normal read logic
            read_count = rn2fl_instr0_lrd_valid + rn2fl_instr1_lrd_valid;

            // Single read
            if (read_count == 1 && rn2fl_instr0_lrd_valid) begin
                // fl2rn_instr0prd <= mem[dequeue_ptr];    // if reading out
                valid_mem[dequeue_ptr] <= 1'b0;
                dequeue_ptr            <= (dequeue_ptr + 1) % DEPTH;
                // rd_count               <= rd_count + 1;

            // Double read
            end else if (read_count == 2 && rn2fl_instr1_lrd_valid) begin
                // fl2rn_instr0prd <= mem[dequeue_ptr];      // if reading out
                // fl2rn_instr1prd <= mem[dequeue_ptr + 1];  // if reading out
                valid_mem[dequeue_ptr]     <= 1'b0;
                valid_mem[dequeue_ptr + 1] <= 1'b0;
                dequeue_ptr               <= (dequeue_ptr + 2) % DEPTH;
                // rd_count                  <= rd_count + 2;
            end
        end
    end
end


    always @(*) begin
        if (read_count == 1 && rn2fl_instr0_lrd_valid ) begin
            fl2rn_instr0prd               = mem[dequeue_ptr];
            fl2rn_instr1prd               = 0;            
        end else if (read_count == 2 && rn2fl_instr1_lrd_valid )begin
            fl2rn_instr0prd               = mem[dequeue_ptr];
            fl2rn_instr1prd               = mem[dequeue_ptr+1];            
        end else begin
            fl2rn_instr0prd = 0;
            fl2rn_instr1prd = 0;
        end
    end



endmodule
