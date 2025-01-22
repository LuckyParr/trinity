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
    output reg [DATA_WIDTH-1:0] rd_data1

    // // Status Flags
    // output full,
    // output empty
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

    // ----------------------------------------------------------
    // Pointer counters for tracking how many have been written/read
    // ----------------------------------------------------------
    // reg [$clog2(DEPTH)+1:0] wr_count = 0;
    // reg [$clog2(DEPTH)+1:0] rd_count = 0;

    // ----------------------------------------------------------
    // Status Flags
    // ----------------------------------------------------------
    // // 'full'  when difference between wr_count and rd_count is DEPTH
    // // 'empty' when wr_count == rd_count
    // assign full  = ((wr_count - rd_count) >= DEPTH);
    // assign empty = (wr_count == rd_count);

    // ----------------------------------------------------------
    // Initialization and Write Operations
    // ----------------------------------------------------------
    integer i;
    integer write_count;
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            // Reset pointers, counters
            enqueue_ptr   <= 0;
            //wr_count      <= 0;

            // Clear out the entire memory
            for (i = 0; i < DEPTH; i = i + 1) begin
                mem[i]       <= (i[5:0]+6'd32);
                valid_mem[i] <= 1'b1;
            end

        end else begin
            // Determine how many writes are requested
            // (wr_en0 + wr_en1 can be 0, 1, or 2)
            write_count = wr_en0 + wr_en1;

            // // Do not exceed available space (DEPTH - occupancy)
            // if (write_count > (DEPTH - (wr_count - rd_count))) begin
            //     write_count = DEPTH - (wr_count - rd_count);
            // end

            if (write_count == 1 && wr_en0 && !full) begin
                mem[enqueue_ptr]       <= wr_data0;
                valid_mem[enqueue_ptr] <= 1'b1;

                enqueue_ptr   <= (enqueue_ptr + 1) % DEPTH;
                //wr_count      <= wr_count + 1;
            end else if (write_count == 2 && wr_en1 && !full) begin
                mem[enqueue_ptr]       <= wr_data0;
                valid_mem[enqueue_ptr] <= 1'b1;
                mem[enqueue_ptr+1]       <= wr_data1;
                valid_mem[enqueue_ptr+1] <= 1'b1;

                enqueue_ptr   <= (enqueue_ptr + 2) % DEPTH;
                //wr_count      <= wr_count + 2;
            end
        end
    end

    // ----------------------------------------------------------
    // Read Operations
    // ----------------------------------------------------------
    integer read_count;
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            // Reset pointers, counters, and output data
            dequeue_ptr <= 0;
            //rd_data0    <= {DATA_WIDTH{1'b0}};
            //rd_data1    <= {DATA_WIDTH{1'b0}};
            rd_count    <= 0;

        end else begin
            // Determine how many reads are requested
            // (rd_en0 + rd_en1 can be 0, 1, or 2)
            read_count = rd_en0 + rd_en1;

            // // Do not exceed the number of valid entries (wr_count - rd_count)
            // if (read_count > (wr_count - rd_count)) begin
            //     read_count = wr_count - rd_count;
            // end

            if (read_count == 1 && rd_en0 && !empty) begin
                //rd_data0               <= mem[dequeue_ptr];
                valid_mem[dequeue_ptr] <= 1'b0;    
                dequeue_ptr            <= (dequeue_ptr + 1) % DEPTH;
                rd_count               <= rd_count + 1;
            end else if (read_count == 2 && rd_en1 && !empty) begin
                //rd_data1               <= mem[dequeue_ptr];
                valid_mem[dequeue_ptr] <= 1'b0;    
                valid_mem[dequeue_ptr+1] <= 1'b0;    
                dequeue_ptr            <= (dequeue_ptr + 2) % DEPTH;
                rd_count               <= rd_count + 2;
            end
        end
    end

    always @(*) begin
        if (read_count == 1 && rd_en0 && !empty) begin
            rd_data0               = mem[dequeue_ptr];
        end else if (read_count == 2 && rd_en1 && !empty)begin
            rd_data1               = mem[dequeue_ptr+1];            
        end else begin
            rd_data0 = 0;
            rd_data1 = 0;
        end
    end

endmodule
