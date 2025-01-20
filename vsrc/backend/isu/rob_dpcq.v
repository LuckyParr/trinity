`timescale 1ns / 1ps
module rob_dpcq #( //dual_port_circular_queue
    parameter DATA_WIDTH = 124,         // 64 + 32 + 5 + 5 + 5 + 6 + 6 + 1 = 124 bits
    parameter DEPTH = 64,               // Queue depth set to 64
    parameter STATUS_WIDTH = 1          // Status bitwidth set to 1
)(
    input clk,
    input reset_n,                       // Active-low reset signal

    // Write Port 1
    input wr_en1,
    input [DATA_WIDTH-1:0] wr_data1,

    // Write Port 2
    input wr_en2,
    input [DATA_WIDTH-1:0] wr_data2,

    // Status Write Port 1
    input status_wren1,
    input [$clog2(DEPTH)-1:0] status_wraddr1,  // 6 bits for DEPTH=64
    input [STATUS_WIDTH-1:0] status_wrdata1,   // 1 bit

    // Status Write Port 2
    input status_wren2,
    input [$clog2(DEPTH)-1:0] status_wraddr2,  // 6 bits for DEPTH=64
    input [STATUS_WIDTH-1:0] status_wrdata2,   // 1 bit

    // Read Port 1
    input rd_en1,
    output reg [DATA_WIDTH-1:0] rd_data1,

    // Read Port 2
    input rd_en2,
    output reg [DATA_WIDTH-1:0] rd_data2,

    // Status Flags
    output full,
    output empty
);

    // Local Parameters
    localparam ADDR_WIDTH = $clog2(DEPTH);          // 6 bits for DEPTH=64
    localparam INDEX_WIDTH = $clog2(DEPTH) + 2;    // 8 bits for DEPTH=64

    // Generate Individual Registers for Each Entry
    genvar i;
    generate
        for (i = 0; i < DEPTH; i = i + 1) begin : entry_gen
            reg [DATA_WIDTH-1:0] cqentry_data;
            reg cqentry_valid;
            reg [INDEX_WIDTH-1:0] cqentry_index;
            reg [STATUS_WIDTH-1:0] cqentry_status;
        end
    endgenerate

    // Write Pointer
    reg [ADDR_WIDTH-1:0] enqueue_ptr = 0;  // Renamed from wr_ptr

    // Read Pointer
    reg [ADDR_WIDTH-1:0] dequeue_ptr = 0;  // Renamed from rd_ptr

    // Pointer Counters for Age Comparison
    reg [$clog2(DEPTH)+1:0] wr_count = 0;
    reg [$clog2(DEPTH)+1:0] rd_count = 0;

    // Index Counter for cqentry_index
    reg [INDEX_WIDTH-1:0] index_counter = 0;

    // Status Flags
    assign full = (wr_count - rd_count) >= DEPTH;
    assign empty = (wr_count == rd_count);

    // Data Write Operations
    integer write_count;
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            enqueue_ptr <= 0;                // Reset enqueue_ptr
            wr_count <= 0;
            index_counter <= 0;
            // Initialize all cqentry_data to zero, cqentry_valid to 0, cqentry_index to 0, and cqentry_status to 0
            for (i = 0; i < DEPTH; i = i + 1) begin
                entry_gen[i].cqentry_data <= {DATA_WIDTH{1'b0}};
                entry_gen[i].cqentry_valid <= 1'b0;
                entry_gen[i].cqentry_index <= {INDEX_WIDTH{1'b0}};
                entry_gen[i].cqentry_status <= {STATUS_WIDTH{1'b0}};
            end
        end else begin
            write_count = wr_en1 + wr_en2;

            // Prevent writing more than available space
            if (write_count > (DEPTH - (wr_count - rd_count))) begin
                // Limit the write_count to available space
                write_count = DEPTH - (wr_count - rd_count);
            end

            // Write Port 1
            if (write_count >= 1 && wr_en1 && !full) begin
                entry_gen[enqueue_ptr].cqentry_data <= wr_data1;
                entry_gen[enqueue_ptr].cqentry_valid <= 1'b1;
                entry_gen[enqueue_ptr].cqentry_index <= index_counter;
                enqueue_ptr <= (enqueue_ptr + 1) % DEPTH;
                wr_count <= wr_count + 1;
                index_counter <= index_counter + 1;
            end

            // Write Port 2
            if (write_count == 2 && wr_en2 && !full) begin
                entry_gen[enqueue_ptr].cqentry_data <= wr_data2;
                entry_gen[enqueue_ptr].cqentry_valid <= 1'b1;
                entry_gen[enqueue_ptr].cqentry_index <= index_counter;
                enqueue_ptr <= (enqueue_ptr + 1) % DEPTH;
                wr_count <= wr_count + 1;
                index_counter <= index_counter + 1;
            end
        end
    end

    // Status Write Operations
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            // Reset all status bits to 0
            for (i = 0; i < DEPTH; i = i + 1) begin
                entry_gen[i].cqentry_status <= {STATUS_WIDTH{1'b0}};
            end
        end else begin
            // Status Write Port 1
            if (status_wren1 && status_wraddr1 < DEPTH) begin
                entry_gen[status_wraddr1].cqentry_status <= status_wrdata1;
            end

            // Status Write Port 2
            if (status_wren2 && status_wraddr2 < DEPTH) begin
                entry_gen[status_wraddr2].cqentry_status <= status_wrdata2;
            end
        end
    end

    // Read Operations
    integer read_count;
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            dequeue_ptr <= 0;                // Reset dequeue_ptr
            rd_data1 <= {DATA_WIDTH{1'b0}};
            rd_data2 <= {DATA_WIDTH{1'b0}};
            rd_count <= 0;
            // Optionally, reset read data
        end else begin
            read_count = rd_en1 + rd_en2;

            // Prevent reading more than available data
            if (read_count > (wr_count - rd_count)) begin
                // Limit the read_count to available data
                read_count = wr_count - rd_count;
            end

            // Read Port 1
            if (read_count >= 1 && rd_en1 && !empty) begin
                rd_data1 <= entry_gen[dequeue_ptr].cqentry_data;
                entry_gen[dequeue_ptr].cqentry_valid <= 1'b0;
                dequeue_ptr <= (dequeue_ptr + 1) % DEPTH;
                rd_count <= rd_count + 1;
            end

            // Read Port 2
            if (read_count == 2 && rd_en2 && !empty) begin
                rd_data2 <= entry_gen[dequeue_ptr].cqentry_data;
                entry_gen[dequeue_ptr].cqentry_valid <= 1'b0;
                dequeue_ptr <= (dequeue_ptr + 1) % DEPTH;
                rd_count <= rd_count + 1;
            end
        end
    end

    // Age Comparison Logic
    // Determines if enqueue_ptr has wrapped around and is older than dequeue_ptr
    wire [ADDR_WIDTH+1:0] write_age = wr_count;
    wire [ADDR_WIDTH+1:0] read_age = rd_count;

    wire is_write_older = (write_age < read_age);

    // This flag can be used to manage overwrites or other control logic
    // For example:
    // always @(posedge clk) begin
    //     if (is_write_older) begin
    //         // Handle the condition where enqueue_ptr has wrapped and is older
    //     end
    // end

endmodule
