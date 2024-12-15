module dcache 
#(parameter DATA_WIDTH = 64,  // Width of data
  parameter ADDR_WIDTH = 9   // Width of address bus
) (
    
    input wire clock,        // Clock signal
    input wire reset_n,    // Active low reset

    //trinity bus channel as input
    input reg                  tbus_index_valid,
    output  wire                 tbus_index_ready,
    input reg  [`RESULT_RANGE] tbus_index,
    input reg  [   `SRC_RANGE] tbus_write_data,
    input reg  [   `SRC_RANGE] tbus_write_mask,

    output  wire [ `RESULT_RANGE] tbus_read_data,
    output  wire                 tbus_operation_done,
    input wire [  `TBUS_RANGE] tbus_operation_type,
    

    //trinity bus channel as output
    output reg                  dcache2arb_tbus_index_valid,
    input  wire                 dcache2arb_tbus_index_ready,
    output reg  [`RESULT_RANGE] dcache2arb_tbus_index,
    output reg  [   `SRC_RANGE] dcache2arb_tbus_write_data,
    output reg  [   `SRC_RANGE] dcache2arb_tbus_write_mask,

    input  wire [ `RESULT_RANGE] dcache2arb_tbus_read_data,
    input  wire                  dcache2arb_tbus_operation_done,
    output wire [  `TBUS_RANGE]  dcache2arb_tbus_operation_type,
    
);
    
    // Define states using parameters
    localparam IDLE          = 3'b000;
    localparam READ_TAG      = 3'b001;
    localparam READWRITE_DATA = 3'b010;
    localparam WB_DDR        = 3'b011;
    localparam READ_DDR      = 3'b100;
    localparam REFILL        = 3'b101;

   

/* -------------------------------------------------------------------------- */
/*                                     stage0                                    */
/* -------------------------------------------------------------------------- */

/* ----------------------------------- latch input ----------------------------------- */

//indicate to access tag array
reg tag_ce ;
always @(*) begin
    if(state == IDLE)begin
        tag_ce = tbus_index_valid;
    end else if(state == READWRITE_DATA) begin
        tag_ce = 1'b1;
    end
end

wire in_idle ;
assign in_idle = (state == IDLE);
wire in_rw_data = (state == READWRITE_DATA);

//latch mem access addr
reg [63:0] ls_addr_latch ;
always @(posedge clock or reset_n) begin
    if(~reset_n) begin
        ls_addr_latch <= 'b0;
    end else if(in_idle & tbus_index_valid) begin
        ls_addr_latch <= tbus_index;
    end
end

//set idx to read
wire [8:0] tag_setaddr_s0;
assign tag_setaddr_s0 = tbus_index[14:6];

reg [`SRC_RANGE] write_data_latch;
always @(posedge clock or reset_n) begin
    if(~reset_n) begin
        write_data_latch <= 'b0;
    end else if(in_idle & tbus_index_valid) begin
        write_data_latch <= tbus_write_data;
    end
end

reg [`SRC_RANGE] write_mask_latch;
always @(posedge clock or reset_n) begin
    if(~reset_n) begin
        write_mask_latch <= 'b0;
    end else if(in_idle & tbus_index_valid) begin
        write_mask_latch <= tbus_write_mask;
    end
end


wire [DATA_WIDTH-1:0] write_data_8banks[7:0];
for (i=0;i<`TAGRAM_BANKNUM;i=i+1)begin
    write_data_8banks[i] = write_data_latch;
end

wire [DATA_WIDTH-1:0] write_mask_8banks[7:0];
for (i=0;i<`TAGRAM_BANKNUM;i=i+1)begin
    write_mask_8banks[i] = write_mask_latch;
end

/* ------------------------------- lfsr random ------------------------------ */
wire [7:0] seed;
assign seed = 8'hFF;
wire [7:0] random_num;

lfsr_random u_lfsr_random(
    .clock      (clock      ),
    .reset_n    (reset_n    ),
    .seed       (seed       ),
    .random_num (random_num )
);




    /* -------------------------------------------------------------------------- */
    /*           stage 1: miss / hit , generate data array access logic           */
    /* -------------------------------------------------------------------------- */

/* ------------------------- generate him/miss sigs ------------------------- */
wire [`TAGRAM_RANGE] tag_dout_s1;
wire [18:0] tag_read_data_way_s1[0:1];
reg tagram_hit_s1;
reg [1:0] tagram_hitway_onehot_s1;


assign tag_read_data_way_s1[0] = tag_dout_s1[18:0];
assign tag_read_data_way_s1[1] = tag_dout_s1[38:19];
wire [1:0] tag_way_valid_s1 = {tag_read_data_way_s1[1][`TAGRAM_VALID_RANGE], tag_read_data_way_s1[0][`TAGRAM_VALID_RANGE]  } ;
wire [1:0] tag_way_dirty_s1 = {tag_read_data_way_s1[1][`TAGRAM_DIRTY_RANGE], tag_read_data_way_s1[0][`TAGRAM_DIRTY_RANGE]  } ;
wire tag_way_full_s1;
assign tag_way_full_s1 = &tag_way_valid_s1;
integer i;
always @(*) begin
    tagram_hit_s1 = 0;
    tagram_hitway_onehot_s1 = 0;
    for(i=0;i<TAGRAM_WAYNUM;i=i+1)begin
        if(tag_read_data_way_s1[i][`TAGRAM_TAG_RANGE] == ls_addr_latch[`TAGRAM_TAG_RANGE] && tag_read_data_way_s1[i][`TAGRAM_VALID_RANGE] )begin
            tagram_hit_s1  = 1'b1;
            tagram_hitway_onehot_s1[i] = 1'b1;
        end
    end
end

/* ------------------------------------ cal victim way ----------------------------------- */
wire [1:0] random_way_s1;
wire [1:0] data_write_way_s1;
wire [1:0] ff_way_s1;
wire victim_way_dirty;

findfirstone u_findfirstone(
    .in_vector (~tag_way_valid_s1 ),
    .onehot    (ff_way_s1    ),
    .valid     (     )
);

assign random_way_s1 = {random_num[0], ~random_num[0]};
assign data_write_way_s1 = tag_way_full_s1? random_way_s1 : ff_way_s1;
assign victim_way_dirty = &(tag_way_dirty_s1 & tag_way_valid_s1 & data_write_way_s1);



//bankidx OH generate,used to r/w dataarray
wire [2:0] tag_bankaddr_s1;
assign tag_bankaddr_s1 = ls_addr_latch[5:3];
wire [7:0] tag_bankaddr_onehot_s1;
always @(*) begin
    integer i;
    for(i=0;i<`TAGRAM_BANKNUM;i=i+1)begin
        tag_bankaddr_onehot_s1[i] = (tag_bankaddr_s1 == i);
    end
end


wire [1:0] ce_way_dataarray ;
reg [1:0] ce_way_latch;

assign ce_way_dataarray = tagram_hitway_onehot_s1;
always @(posedge clock ) begin
    ce_way_latch <= tagram_hitway_onehot_s1;
end


reg ce_bank_dataarray_latch;
wire [7:0] ce_bank_dataarray ;

assign ce_bank_dataarray = tag_bankaddr_onehot_s1;
always @(posedge clock ) begin
    ce_bank_dataarray_latch <= tag_bankaddr_onehot_s1;
end

wire read_hit_s1 = (tbus_operation_type == `TBUS_READ) && tagram_hit_s1;
wire write_hit_s1 = (tbus_operation_type == `TBUS_WRITE) && tagram_hit_s1;
assign writeenable_bank = write_hit_s1?1'd1:1'd0;




    /* -------------------------------------------------------------------------- */
    /*                    Stage2 : get read data array result / wirte done                   */
    /* -------------------------------------------------------------------------- */

wire  [DATA_WIDTH-1:0] data_dout_s2 [7:0];
always @(*) begin
    integer i;
    for(i=0;i<TAGRAM_BANKNUM;i=i+1)begin
        tbus_read_data = {64{ce_bank_dataarray_latch[i]}} && data_dout_s2[i];
    end
end

always @(posedge clock or negedge reset_n) begin
    if(~reset_n)begin
        tbus_operation_done = 0;
    end else if(in_rw_data)begin
        tbus_operation_done = 1'b1;
    end else begin
        tbus_operation_done <= 'b0;
    end
end

dcache_tagarray u_dcache_tagarray(
    .clock   (clock   ),
    .reset_n (reset_n ),
    .we      (we      ),
    .ce      ( tag_ce    ),
    .waddr   (waddr   ),
    .raddr   (tag_setaddr_s0   ),
    .din     (din     ),
    .wmask   (wmask   ),
    .dout    (tag_dout_s1    )
);

dcache_dataarray u_dcache_dataarray(
    .clock             (clock             ),
    .reset_n           (reset_n           ),
    .ce_way            (ce_way_dataarray),
    .writeenable_bank  (writeenable_bank           ),
    .ce_bank           (ce_bank_dataarray           ),
    .writewayaddr (writewayaddr ),
    .readwayaddr  (readwayaddr  ),
    .din_bank          (write_data_8banks          ),
    .wmask_bank        (write_mask_8banks        ),
    .dout_bank         (data_dout_s2         ),
);


/* -------------------------------------------------------------------------- */
/*                                     FSM                                    */
/* -------------------------------------------------------------------------- */
 // State register
    reg [2:0] state 
    reg [2:0] next_state;

    // State transition logic
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n)
            state <= IDLE; // Reset to IDLE state
        else
            state <= next_state;
    end

    // Next state logic
    always @(*) begin
        case (state)
            IDLE: begin
                if (tbus_index_valid)
                    next_state = READ_TAG;
                else
                    next_state = IDLE;
            end
            READ_TAG: begin
                if(tagram_hit_s1) begin
                    next_state = READWRITE_DATA;
                end else if(victim_way_dirty) begin
                    next_state = WB_DDR;
                end else begin
                    next_state = READ_DDR;
                end
            end
            READWRITE_DATA: begin
                    next_state = IDLE;                    
            end
            WB_DDR: begin
                // Add condition for transitioning to next state
                next_state = READ_DDR;
            end
            READ_DDR: begin
                // Add condition for transitioning to next state
                next_state = REFILL;
            end
            REFILL: begin
                // Add condition for transitioning to IDLE or another state
                next_state = IDLE;
            end
            default: next_state = IDLE;
        endcase
    end
endmodule


