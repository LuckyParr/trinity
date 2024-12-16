module dcache 
#(parameter DATA_WIDTH = 64,  // Width of data
  parameter ADDR_WIDTH = 9   // Width of address bus
) (
    
    input wire clock,        // Clock signal
    input wire reset_n,    // Active low reset

    //trinity bus channel as input
    input reg                  tbus_index_valid,
    output  wire               tbus_index_ready,
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
    localparam IDLE           = 3'b000;
    localparam LOOKUP_TAG     = 3'b001;
    localparam WRITE_TAG_DATA = 3'b010;
    localparam READ_DATA      = 3'b011;
    localparam WB_DDR         = 3'b100;
    localparam READ_DDR       = 3'b101;
    localparam REFILL         = 3'b110;
    
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

   
    wire in_idle ;
    wire in_lutag ;
    wire in_wtagdata ;
    assign in_idle = (state == IDLE);
    assign in_lutag = (state == LOOKUP_TAG);
    assign in_wtagdata = (state == WRITE_TAG_DATA);

/* -------------------------------------------------------------------------- */
/*                   IDLE : Stage0                                            */
/* -------------------------------------------------------------------------- */
/* ----------------------------------- latch input ----------------------------------- */
//latch mem access addr/data/mask
reg [63:0] ls_addr_latch ;
always @(posedge clock or reset_n) begin
    if(~reset_n) begin
        ls_addr_latch <= 'b0;
    end else if(in_idle & tbus_index_valid) begin
        ls_addr_latch <= tbus_index;
    end
end
wire [63:0] ls_addr_or;
assign ls_addr_or = tbus_index | ls_addr_latch;

reg [`SRC_RANGE] write_data_latch;
always @(posedge clock or reset_n) begin
    if(~reset_n) begin
        write_data_latch <= 'b0;
    end else if(in_idle & tbus_index_valid) begin
        write_data_latch <= tbus_write_data;
    end
end
wire [`SRC_RANGE] write_data_or;
assign write_data_or = write_data_latch | tbus_write_data;


reg [`SRC_RANGE] write_mask_latch;
always @(posedge clock or reset_n) begin
    if(~reset_n) begin
        write_mask_latch <= 'b0;
    end else if(in_idle & tbus_index_valid) begin
        write_mask_latch <= tbus_write_mask;
    end
end
wire [`SRC_RANGE] write_mask_or;
assign write_mask_or = write_mask_latch | tbus_write_mask;


reg [1:0] operation_type_latch;
always @(posedge clock or reset_n) begin
    if(~reset_n) begin
        operation_type_latch <= 'b0;
    end else if(in_idle & tbus_index_valid) begin
        operation_type_latch <= tbus_operation_type;
    end
end
wire operation_type_or;
assign operation_type_or = operation_type_latch | tbus_operation_type;
wire tbus_is_write ;
tbus_is_write = (operation_type_or == `TBUS_WRITE);
wire tbus_is_read ;
tbus_is_read = (operation_type_or == `TBUS_READ);

//extend latched input write data to 2D array for writing dataarray
wire [DATA_WIDTH-1:0] write_data_8banks[7:0];
for (i=0;i<`DATARAM_BANKNUM;i=i+1)begin
    write_data_8banks[i] = write_data_or;
end

wire [DATA_WIDTH-1:0] write_mask_8banks[7:0];
for (i=0;i<`DATARAM_BANKNUM;i=i+1)begin
    write_mask_8banks[i] = write_mask_or;
end

wire [2:0] bankaddr_or;
assign bankaddr_or = ls_addr_or[5:3];
wire [7:0] bankaddr_onehot_or;
always @(*) begin
    integer i;
    for(i=0;i<`DATARAM_BANKNUM;i=i+1)begin
        bankaddr_onehot_or[i] = (bankaddr_or == i);
    end
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
/*            LOOKUP_TAG : Stage1 : get tagarray dout, check miss / hit , generate tag/data array access logic           */
/* -------------------------------------------------------------------------- */

/* -------------------------- decode tagarray dout -------------------------- */
wire [`TAGRAM_RANGE] tagdout_s1;
wire [18:0] tagdout_ways_data_s1[0:1];
wire [1:0] tagdout_ways_valid_s1 ;
wire [1:0] tagdout_ways_dirty_s1 ;
wire tagdout_ways_full_s1;

assign tagdout_ways_data_s1[0] = tagdout_s1[18:0];
assign tagdout_ways_data_s1[1] = tagdout_s1[38:19];
assign tagdout_ways_valid_s1 = {tagdout_ways_data_s1[1][`TAGRAM_VALID_RANGE], tagdout_ways_data_s1[0][`TAGRAM_VALID_RANGE]  } ;
assign tagdout_ways_dirty_s1= {tagdout_ways_data_s1[1][`TAGRAM_DIRTY_RANGE], tagdout_ways_data_s1[0][`TAGRAM_DIRTY_RANGE]  } ;
assign tagdout_ways_full_s1 = &tagdout_ways_valid_s1;

/* ------------------------- lookup logic ------------------------- */
reg lookup_hit_s1;
reg [1:0] lookup_hitway_onehot_s1;

integer i;
always @(*) begin
    lookup_hit_s1 = 0;
    lookup_hitway_onehot_s1 = 0;
    for(i=0;i<TAGRAM_WAYNUM;i=i+1)begin
        if(tagdout_ways_data_s1[i][`TAGRAM_TAG_RANGE] == ls_addr_or[`TAGRAM_TAG_RANGE] && tagdout_ways_data_s1[i][`TAGRAM_VALID_RANGE] )begin
            lookup_hit_s1  = 1'b1;
            lookup_hitway_onehot_s1[i] = 1'b1;
        end
    end
end

/* ------------------------------------ cal victim way ----------------------------------- */
wire [1:0] random_way_s1;
wire [1:0] dataarray_write_way_s1;
wire [1:0] ff_way_s1;
wire victim_way_dirty;

findfirstone u_findfirstone(
    .in_vector (~tagdout_ways_valid_s1 ),
    .onehot    (ff_way_s1    ),
    .valid     (     )
);

assign random_way_s1 = {random_num[0], ~random_num[0]};//random_num[0] itself is decimal num 
assign dataarray_write_way_s1 = tagdout_ways_full_s1? random_way_s1 : ff_way_s1;
assign victim_way_dirty = &(tagdout_ways_dirty_s1 & tagdout_ways_valid_s1 & dataarray_write_way_s1);

/* -------------------------- calculate victim addr ------------------------- */
wire [`TAGRAM_TAG_RANGE]victim_way_pa;
assign victim_way_pa = tagdout_ways_data_s1[random_num[0]][`TAGRAM_TAG_RANGE];
wire [`RESULT_RANGE] victim_addr;
assign victim_addr = {32'd0,victim_way_pa,ls_addr_or[14:6],6'd0};
reg [`RESULT_RANGE] victim_addr_latch;
always @(posedge clock or negedge reset_n) begin
    if(~reset_n)begin
        victim_addr_latch <= 0;
    end else if (next_state == WB_DDR)begin
        victim_addr_latch <= victim_addr;
    end
end

/* ------------------------------ lookup result ----------------------------- */
wire lu_hit_s1;
wire lu_miss_full_vicdirty ;
wire lu_miss_full_vicclean ;
wire lu_miss_notfull ;

assign lu_hit_s1 = lookup_hit_s1;
assign lu_miss_full_vicdirty = ~lookup_hit_s1 && tagdout_ways_full_s1 && victim_way_dirty;
assign lu_miss_full_vicclean = ~lookup_hit_s1 && tagdout_ways_full_s1 && ~victim_way_dirty;
assign lu_miss_notfull = ~lookup_hit_s1 && ~tagdout_ways_full_s1;

wire read_hit_s1 ;
assign read_hit_s1 = tbus_is_read && lu_hit_s1;
wire write_hit_s1 ;
assign write_hit_s1 = tbus_is_write && lu_hit_s1;




/* -------------------------------------------------------------------------- */
/*                    Stage2 : when state == WRITE_TAG_DATA or READ_DATA                  */
/* -------------------------------------------------------------------------- */

/* --------------------------- when state == READ_DATA, get dataarray bank dout --------------------------- */
wire  [DATA_WIDTH-1:0] data_dout_s2 [7:0];
wire [ `RESULT_RANGE] tbus_read_data_s2;
always @(*) begin
    integer i;
    for(i=0;i<DATARAM_BANKNUM;i=i+1)begin
        tbus_read_data_s2 = {64{dataarray_ce_bank[i]}} && data_dout_s2[i];
    end
end


/* -------------------------------------------------------------------------- */
/*                            tagarray / dataarray                            */
/* -------------------------------------------------------------------------- */

dcache_tagarray u_dcache_tagarray(
    .clock   (clock   ),
    .reset_n (reset_n ),
    .we      (tagarray_we      ),
    .ce      (tagarray_ce    ),
    .raddr   (ls_addr_or[14:6]   ),
    .waddr   (ls_addr_or[14:6]   ),//refill
    .din     (din     ),//refill
    .wmask   (wmask   ),//refill
    .dout    (tagdout_s1    )
);

dcache_dataarray u_dcache_dataarray(
    .clock             (clock             ),
    .reset_n           (reset_n           ),
    .we                (dataarray_we           ),
    .ce_way            (dataarray_ce_way),
    .ce_bank           (dataarray_ce_bank           ),
    .writesetaddr      (ls_addr_or[14:6] ),
    .readsetaddr       (ls_addr_or[14:6]  ),
    .din_bank          (write_data_8banks          ),
    .wmask_bank        (write_mask_8banks        ),
    .dout_bank         (data_dout_s2         ),
);


/* -------------------------------------------------------------------------- */
/*                                     FSM                                    */
/* -------------------------------------------------------------------------- */

    // Next state logic
    always @(*) begin
        case (state)
            IDLE: begin
                if (tbus_index_valid)
                    next_state = LOOKUP_TAG;
                else
                    next_state = IDLE;
            end
            LOOKUP_TAG: begin
                if( write_hit_s1) begin
                    next_state = WRITE_TAG_DATA;
                end else if( read_hit_s1 || lu_miss_full_vicdirty) begin
                    next_state = READ_DATA;
                end else begin//lu_miss_full_vicclean / lu_miss_notfull
                    next_state = READ_DDR;
                end
            end
            WRITE_TAG_DATA: begin
                    next_state = IDLE;                    
            end
            READ_DATA:begin
                if(read_hit_s1) begin
                    next_state = IDLE;
                end else if (lu_miss_full_vicdirty)begin
                    next_state = WB_DDR;
                end
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



/* --------------------------- set tagarray input --------------------------- */
//set tagarray chip_enable / writeenable
reg tagarray_ce ;
reg tagarray_we ;
always @(*) begin   
    if (next_state = LOOKUP_TAG)begin 
        tagarray_ce = 1'b1;
        tagarray_we = 1'b0;       
    end else if(next_state = WRITE_TAG_DATA) begin
        tagarray_ce = 1'b1;
        tagarray_we = 1'b1;        
    end else begin
        tagarray_ce = 1'b0;
        tagarray_we = 1'b0;
    end
end

/* --------------------------- set dataarray input -------------------------- */
wire dataarray_we;
wire [1:0] dataarray_ce_way ;
wire [7:0] dataarray_ce_bank ;
always @(*) begin
    if(~reset_n)begin
        dataarray_we = 0;
        dataarray_ce_way = 0;
        dataarray_ce_bank = 0;
    end else if(next_state == WRITE_TAG_DATA)begin//write dataarray
        dataarray_we = 1;
        dataarray_ce_way = lookup_hitway_onehot_s1;
        dataarray_ce_bank = bankaddr_onehot_or;
    end else if(next_state == READ_DATA)begin//read dataarray
        dataarray_we = 0;
        dataarray_ce_way = lookup_hitway_onehot_s1;
        dataarray_ce_bank = bankaddr_onehot_or;
    end else begin
        dataarray_we = 0;
        dataarray_ce_way = 0;        
        dataarray_ce_bank = 0;
    end
end
    
/* ----------------------- trinity bus  ----------------------- */
always @(*) begin
    if(~reset_n )begin
        tbus_operation_done = 0;
        tbus_read_data =0;
        tbus_index_ready =1;
    end else if(state==IDLE)begin
        tbus_operation_done = 1'b0;
        tbus_read_data = 0;
        tbus_index_ready = 1;    
    end else if(state == WRITE_TAG_DATA)begin
        tbus_operation_done = 1'b1;
        tbus_read_data = 0;
        tbus_index_ready = 0;
    end else if(state == READ_DATA && next_state == IDLE)begin 
        tbus_operation_done = 1'b1;
        tbus_read_data = tbus_read_data_s2;
        tbus_index_ready =0;
    end else begin
        tbus_operation_done <= 'b0;
        tbus_read_data =0;
        tbus_index_ready =0;
    end
end


/* ------------------------------- set ddr bus ------------------------------ */

always @(*) begin
    if(~reset_n)begin
        dcache2arb_tbus_index_valid =0;
        dcache2arb_tbus_index =0;
        dcache2arb_tbus_write_data =0;
        dcache2arb_tbus_write_mask =0;
        dcache2arb_tbus_operation_type =0;
    end else if(state == READ_DATA && next_state==WB_DDR)begin//write back dirty data
        dcache2arb_tbus_index_valid =1;
        dcache2arb_tbus_index =victim_addr_latch;
        dcache2arb_tbus_write_data =tbus_read_data_s2;//64bit
        dcache2arb_tbus_write_mask =write_mask_or;
        dcache2arb_tbus_operation_type =`TBUS_WRITE;        
    end else if(state == LOOKUP_TAG && next_state==READ_DDR)begin//read from ddr
        dcache2arb_tbus_index_valid =1;
        dcache2arb_tbus_index =ls_addr_or;
        dcache2arb_tbus_write_data =0;
        dcache2arb_tbus_write_mask =0;
        dcache2arb_tbus_operation_type =`TBUS_READ;
    end else if(state == WB_DDR && next_state==READ_DDR)begin//read from ddr
        dcache2arb_tbus_index_valid =1;
        dcache2arb_tbus_index =ls_addr_or;
        dcache2arb_tbus_write_data =0;
        dcache2arb_tbus_write_mask =0;
        dcache2arb_tbus_operation_type =`TBUS_READ;
    end else begin
        dcache2arb_tbus_index_valid =0;
        dcache2arb_tbus_index =0;
        dcache2arb_tbus_write_data =0;
        dcache2arb_tbus_write_mask =0;
        dcache2arb_tbus_operation_type =0;
    end
end

endmodule


