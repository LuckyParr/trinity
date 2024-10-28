`include "defines.sv"
module mem (
    input wire                  clock,
    input wire                  rst_n,
    input wire                  is_load,
    input wire                  is_store,
    // input wire ls_valid,
    input wire [    `SRC_RANGE] src2,
    input wire [ `RESULT_RANGE] ls_address,
    input wire [`LS_SIZE_RANGE] ls_size,

    output reg                  read_valid,
    input  wire                 read_ready,
    output reg  [`RESULT_RANGE] read_address,
    input  wire                 read_done,
    input  wire [`RESULT_RANGE] read_data,
    // output reg read_size,

    output reg                  write_valid,
    input  wire                 write_ready,
    output reg  [`RESULT_RANGE] write_address,
    output reg  [   `SRC_RANGE] write_data,
    output reg  [         63:0] write_mask,
    input  wire                 write_done

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
    wire read_fire = read_valid & read_ready;
    wire write_fire = write_valid & write_ready;
    reg  outstanding_load;
    reg  outstanding_store;

    always @(posedge clock or negedge rst_n) begin
        if (~rst_n) begin
            outstanding_load <= 'b0;
        end else if (read_fire & ~outstanding_load) begin
            outstanding_load <= 'b1;
        end else if (outstanding_load & read_done) begin
            outstanding_load <= 'b0;
        end
    end


    always @(posedge clock or negedge rst_n) begin
        if (~rst_n) begin
            outstanding_store <= 'b0;
        end else if (write_fire & ~outstanding_store) begin
            outstanding_store <= 'b1;
        end else if (outstanding_store & write_done) begin
            outstanding_store <= 'b0;
        end
    end
    wire [          63:0] write_1b_mask = {56'b0, 8'b1};
    wire [          63:0] write_1h_mask = {48'b0, 16'b1};
    wire [          63:0] write_1w_mask = {32'b0, 32'b1};
    wire [          63:0] write_2w_mask = {64'b1};

    wire [           2:0] shift_size = ls_address[2:0];

    wire [          63:0] write_mask_qual = size_1b ? write_1b_mask << (shift_size * 8) : size_1h ? write_1h_mask << (shift_size * 8) : size_1w ? write_1w_mask << (shift_size * 8) : write_2w_mask;

    wire [`RESULET_RANGE] write_data_qual = src2 << (shift_size * 8);
    always @(*) begin
        read_valid    = 'b0;
        read_address  = 'b0;

        write_valid   = 'b0;
        write_address = 'b0;
        write_data    = 'b0;
        write_mask    = 'b0;

        if (is_load & ~outstanding_load) begin
            read_valid   = 1'b1;
            read_address = {3'b0, ls_address[`RESULT_WIDTH-1:3]};
        end
        if (is_store & ~outstanding_store) begin
            write_valid   = 1'b1;
            write_address = {3'b0, ls_address[`RESULT_WIDTH-1:3]};
            write_mask    = write_mask_qual;
            write_data    = write_data_qual;

        end

    end
endmodule
