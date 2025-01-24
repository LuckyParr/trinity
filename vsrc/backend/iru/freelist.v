`timescale 1ns / 1ps
module freelist #(
    parameter DATA_WIDTH = 6,  //data store physical reg number
    parameter DEPTH      = 32  //number of free ohysical reg
)(
    input clock,
    input reset_n,                      // Active-low reset signal

    // Write Port 0
    input wr_en0,
    input [DATA_WIDTH-1:0] wr_data0,

    // Write Port 1
    input wr_en1,
    input [DATA_WIDTH-1:0] wr_data1,

    // Read Port 0
    input rd_en0,
    output reg [DATA_WIDTH-1:0] rd_data0,

    // Read Port 1
    input rd_en1,
    output reg [DATA_WIDTH-1:0] rd_data1,

    // // Status Flags
    // output full,
    // output empty
    //walk signal
    input wire is_idle,
    input wire is_rollingback,
    input wire is_walking,
    input wire walking_valid0,
    input wire walking_valid1,
    input wire [5:0] walking_old_prd0,
    input wire [5:0] walking_old_prd1

);

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
            mem[enqueue_ptr]       <= wr_data0;
            valid_mem[enqueue_ptr] <= 1'b1;            
            enqueue_ptr <= (enqueue_ptr + 1) % DEPTH;
        // Double write
        end else if (write_count == 2 && wr_en1 ) begin
            mem[enqueue_ptr]         <= wr_data0;
            valid_mem[enqueue_ptr]   <= 1'b1;
            mem[enqueue_ptr + 1]     <= wr_data1;
            valid_mem[enqueue_ptr + 1] <= 1'b1;
            enqueue_ptr <= (enqueue_ptr + 2) % DEPTH;
        end

        // ----------------------------------------------------------
        // Flush Operations
        // ----------------------------------------------------------
        if (is_rollingback) begin
            // Roll back the dequeue pointer to enqueue pointer
            dequeue_ptr <= enqueue_ptr;

        end else if (is_walking) begin
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
            read_count = rd_en0 + rd_en1;

            // Single read
            if (read_count == 1 && rd_en0) begin
                // rd_data0 <= mem[dequeue_ptr];    // if reading out
                valid_mem[dequeue_ptr] <= 1'b0;
                dequeue_ptr            <= (dequeue_ptr + 1) % DEPTH;
                // rd_count               <= rd_count + 1;

            // Double read
            end else if (read_count == 2 && rd_en1) begin
                // rd_data0 <= mem[dequeue_ptr];      // if reading out
                // rd_data1 <= mem[dequeue_ptr + 1];  // if reading out
                valid_mem[dequeue_ptr]     <= 1'b0;
                valid_mem[dequeue_ptr + 1] <= 1'b0;
                dequeue_ptr               <= (dequeue_ptr + 2) % DEPTH;
                // rd_count                  <= rd_count + 2;
            end
        end
    end
end


    always @(*) begin
        if (read_count == 1 && rd_en0 ) begin
            rd_data0               = mem[dequeue_ptr];
            rd_data1               = 0;            
        end else if (read_count == 2 && rd_en1 )begin
            rd_data0               = mem[dequeue_ptr];
            rd_data1               = mem[dequeue_ptr+1];            
        end else begin
            rd_data0 = 0;
            rd_data1 = 0;
        end
    end



endmodule
