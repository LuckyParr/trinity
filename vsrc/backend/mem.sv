`include "defines.sv"
module mem (
    input wire                  clock,
    input wire                  reset_n,
    input wire                  is_load,
    input wire                  is_store,

    input wire [    `SRC_RANGE] src2,
    input wire [ `RESULT_RANGE] ls_address,
    input wire [`LS_SIZE_RANGE] ls_size,

    output reg                  opload_index_valid,
    input  wire                 opload_index_ready,
    output reg  [`RESULT_RANGE] opload_index,

    input  wire                 opload_operation_done,
    input  wire [`RESULT_RANGE] opload_read_data,

    output reg                  opstore_index_valid,
    input  wire                 opstore_index_ready,
    output reg  [`RESULT_RANGE] opstore_index,
    output reg  [   `SRC_RANGE] opstore_write_data,
    output reg  [         63:0] opstore_write_mask,
    input  wire                 opstore_operation_done,

    //read data to wb stage
    output  wire [`RESULT_RANGE] opload_read_data_wb


);
    /*
    0 = B
    1 = HALF WORD
    2 = WORD
    3 = DOUBLE WORD
*/
    wire size_1b = ls_size[0];
    wire size_1h = ls_size[1];
    wire size_1w = ls_size[2];
    wire size_2w = ls_size[3];

    wire ls_valid = is_load | is_store;
    wire read_fire = opload_index_valid & opload_index_ready;
    wire write_fire = opstore_index_valid & opstore_index_ready;
    reg  outstanding_load_q;
    reg  outstanding_store_q;
    wire outstanding_load_ns;
    wire outstanding_store_ns;

    assign outstanding_load_ns = ~outstanding_load_q & read_fire;
    assign outstanding_store_ns = ~outstanding_store_q & write_fire;
    
    always @(posedge clock or negedge reset_n) begin
        if (~reset_n) begin
            outstanding_load_q <= 'b0;
        end else  begin
            outstanding_load_q <= outstanding_load_ns;
        end 
    end

    always @(posedge clock or negedge reset_n) begin
        if (~reset_n) begin
            outstanding_store_q <= 'b0;
        end else  begin
            outstanding_store_q <= outstanding_store_ns;
        end 
    end

    // always @(posedge clock or negedge reset_n) begin
    //     if (~reset_n) begin
    //         outstanding_store <= 'b0;
    //     end else if (write_fire & ~outstanding_store) begin
    //         outstanding_store <= 'b1;
    //     end else if (outstanding_store & opstore_operation_done) begin
    //         outstanding_store <= 'b0;
    //     end
    // end
    wire [          63:0] write_1b_mask = {56'b0, 8'b1};
    wire [          63:0] write_1h_mask = {48'b0, 16'b1};
    wire [          63:0] write_1w_mask = {32'b0, 32'b1};
    wire [          63:0] write_2w_mask = {64'b1};

    wire [           2:0] shift_size = ls_address[2:0];

    wire [          63:0] opstore_write_mask_qual = size_1b ? write_1b_mask << (shift_size * 8) : size_1h ? write_1h_mask << (shift_size * 8) : size_1w ? write_1w_mask << (shift_size * 8) : write_2w_mask;

    wire [`RESULT_RANGE] opstore_write_data_qual = src2 << (shift_size * 8);
    always @(*) begin
        opload_index_valid    = 'b0;
        opload_index  = 'b0;

        opstore_index_valid   = 'b0;
        opstore_index = 'b0;
        opstore_write_data    = 'b0;
        opstore_write_mask    = 'b0;

        if (is_load & ~outstanding_load_q) begin
            opload_index_valid   = 1'b1;
            opload_index = {3'b0, ls_address[`RESULT_WIDTH-1:3]};
        end
        if (is_store & ~outstanding_store_q) begin
            opstore_index_valid   = 1'b1;
            opstore_index = {3'b0, ls_address[`RESULT_WIDTH-1:3]};
            opstore_write_mask    = opstore_write_mask_qual;
            opstore_write_data    = opstore_write_data_qual;
        end

    end
endmodule
