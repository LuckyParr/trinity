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

//    input  wire [ `RESULT_RANGE] dcache2arb_tbus_read_data,
    input  wire [ `INST_CACHE_RANGE] dcache2arb_tbus_read_data,
    input  wire                  dcache2arb_tbus_operation_done,
    output wire [  `TBUS_RANGE]  dcache2arb_tbus_operation_type,

    output wire dcache2arb_tbus_burst_mode
//    input wire [511:0] dcache2arb_tbus_read_cl//read 512 bit cacheline
    
);
    
    // Define states using parameters
    localparam IDLE           = 3'b000;
    localparam LOOKUP     = 3'b001;
    localparam WRITE_CACHE = 3'b010;
    localparam READ_CACHE      = 3'b011;
    localparam WRITE_DDR         = 3'b100;
    localparam READ_DDR       = 3'b101;
    localparam REFILL_READ         = 3'b110;
    localparam REFILL_WRITE         = 3'b111;

    
 // State register
    reg [2:0] state 
    reg [2:0] next_state;


   
    wire in_idle ;
    wire in_lookup ;
    wire in_writecache ;
    assign in_idle = (state == IDLE);
    assign in_lookup = (state == LOOKUP);
    assign in_writecache = (state == WRITE_CACHE);

/* -------------------------------------------------------------------------- */
/*                   IDLE : Stage0                                            */
/* -------------------------------------------------------------------------- */
/* ----------------------------------- latch input ----------------------------------- */
//latch 64bit tbus addr
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

//decode bankaddr base on latched tbus addr
wire [2:0] bankaddr_or;
assign bankaddr_or = ls_addr_or[5:3];
wire [7:0] bankaddr_onehot_or;
always @(*) begin
    integer i;
    for(i=0;i<`DATARAM_BANKNUM;i=i+1)begin
        bankaddr_onehot_or[i] = (bankaddr_or == i);
    end
end

//latch 64bit tbus data
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

//latch 64bit tbus wmask
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

//latch tbus operation_type
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
//decode opreation type
wire tbus_is_write ;
tbus_is_write = (operation_type_or == `TBUS_WRITE);
wire tbus_is_read ;
tbus_is_read = (operation_type_or == `TBUS_READ);

//extend latched tbus write data to 2D array for writing dataarray
wire [DATA_WIDTH-1:0] write_data_8banks[7:0];
for (i=0;i<`DATARAM_BANKNUM;i=i+1)begin
    if(bankaddr_onehot_or[i])begin
        write_data_8banks[i] = write_data_or;
    end else begin
        write_data_8banks[i] = 0;        
    end
end
//extend latched tbus wmask to 2D array for writing dataarray
wire [DATA_WIDTH-1:0] write_mask_8banks[7:0];
for (i=0;i<`DATARAM_BANKNUM;i=i+1)begin
    if(bankaddr_onehot_or[i])begin
        write_mask_8banks[i] = write_mask_or;
    end else begin
        write_mask_8banks[i] = 0;        
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
/*            LOOKUP : Stage1 , get tagarray dout, check miss / hit , generate tag/data array access logic           */
/* -------------------------------------------------------------------------- */

/* -------------------------- decode tagarray dout (s1)-------------------------- */
wire [`TAGRAM_RANGE] tagarray_dout;
wire [18:0] tagarray_dout_waycontent_s1[0:1];
wire [1:0] tagarray_dout_wayvalid_s1 ;
wire [1:0] tagarray_dout_waydirty_s1 ;
wire tagarray_dout_wayisfull_s1;

assign tagarray_dout_waycontent_s1[0] = tagarray_dout[18:0]; //way0 is [18:0]
assign tagarray_dout_waycontent_s1[1] = tagarray_dout[38:19];//way1 is [38:19] 
assign tagarray_dout_wayvalid_s1 = {tagarray_dout_waycontent_s1[1][`TAGRAM_VALID_RANGE], tagarray_dout_waycontent_s1[0][`TAGRAM_VALID_RANGE]  } ;
assign tagarray_dout_waydirty_s1= {tagarray_dout_waycontent_s1[1][`TAGRAM_DIRTY_RANGE], tagarray_dout_waycontent_s1[0][`TAGRAM_DIRTY_RANGE]  } ;
assign tagarray_dout_wayisfull_s1 = &tagarray_dout_wayvalid_s1;

//latch tagarray_dout in state lookup
reg [`TAGRAM_RANGE] tagarray_dout_latch;
always @(posedge clock or negedge reset_n) begin
    if(~reset_n)begin
        tagarray_dout_latch <= 0;
    end else if ((state == LOOKUP) && (next_state != LOOKUP))begin
        tagarray_dout_latch <= tagarray_dout;
    end
end
wire [`TAGRAM_RANGE] tagarray_dout_or;
assign tagarray_dout_or = tagarray_dout_latch | tagarray_dout;



/* ------------------------- lookup logic (s1)------------------------- */
reg lookup_hit_s1;
reg [1:0] lookup_hitway_onehot_s1;
reg lookup_hitway_dec_s1;

integer i;
always @(*) begin
    lookup_hit_s1 = 0;
    lookup_hitway_onehot_s1 = 0;
    for(i=0;i<`TAGRAM_WAYNUM;i=i+1)begin
        if(tagarray_dout_waycontent_s1[i][`TAGRAM_TAG_RANGE] == ls_addr_or[`TAGRAM_TAG_RANGE] && tagarray_dout_waycontent_s1[i][`TAGRAM_VALID_RANGE] )begin
            lookup_hit_s1  = 1'b1;
            lookup_hitway_onehot_s1[i] = 1'b1;
            lookup_hitway_dec_s1 = i;
        end
    end
end

//latch victimway_fulladdr in state lookup
reg [1:0] lookup_hitway_oh_latch;
reg lookup_hitway_dec_latch;
always @(posedge clock or negedge reset_n) begin
    if(~reset_n)begin
        lookup_hitway_oh_latch <= 0;
        lookup_hitway_dec_latch <= 0;
    end else if ((state == LOOKUP) && (next_state != LOOKUP))begin
        lookup_hitway_oh_latch <= lookup_hitway_onehot_s1;
        lookup_hitway_dec_latch <= lookup_hitway_dec_s1;
    end
end
wire [1:0] lookup_hitway_oh_or;
assign lookup_hitway_oh_or = lookup_hitway_oh_latch | lookup_hitway_onehot_s1;
wire lookup_hitway_dec_or;
assign lookup_hitway_dec_or = lookup_hitway_dec_latch | lookup_hitway_dec_s1;




/* ------------------------------------ cal victim way (s1)----------------------------------- */
wire [1:0] random_way_s1;
wire [1:0] victimway_oh_s1;
wire [1:0] ff_way_s1;
wire victimway_isdirty_s1;

findfirstone u_findfirstone(
    .in_vector (~tagarray_dout_wayvalid_s1 ),
    .onehot    (ff_way_s1    ),
    .valid     (     )
);

assign random_way_s1 = {random_num[0], ~random_num[0]};//random_num[0] itself is decimal num 
assign victimway_oh_s1 = tagarray_dout_wayisfull_s1? random_way_s1 : ff_way_s1;
assign victimway_isdirty_s1 = |(tagarray_dout_waydirty_s1 & tagarray_dout_wayvalid_s1 & victimway_oh_s1);

/* -------------------------- calculate victim addr (s1)------------------------- */
wire [`TAGRAM_TAG_RANGE]victimway_pa_s1;
assign victimway_pa_s1 = tagarray_dout_waycontent_s1[random_num[0]][`TAGRAM_TAG_RANGE];
wire [`ADDR_RANGE] victimway_fulladdr_s1;
assign victimway_fulladdr_s1 = {32'd0,victimway_pa_s1,ls_addr_or[14:6],6'd0};//64=32+17+9+6
//latch victimway_fulladdr in state lookup
reg [`ADDR_RANGE] victimway_fulladdr_latch;
always @(posedge clock or negedge reset_n) begin
    if(~reset_n)begin
        victimway_fulladdr_latch <= 0;
    end else if ((state == LOOKUP) && (next_state != LOOKUP))begin
        victimway_fulladdr_latch <= victimway_fulladdr_s1;
    end
end
wire [`ADDR_RANGE] victimway_fulladdr_or;
assign victimway_fulladdr_or = victimway_fulladdr_latch | victimway_fulladdr_s1;

/* ------------------------------ lookup result ----------------------------- */
wire lu_hit_s1;
wire lu_miss_s1;
wire lu_miss_full_vicdirty ;
wire lu_miss_full_vicclean ;
wire lu_miss_notfull ;

assign lu_hit_s1 = lookup_hit_s1;
assign lu_miss_s1 = ~lookup_hit_s1;
assign lu_miss_notfull = lu_miss_s1 && ~tagarray_dout_wayisfull_s1;
assign lu_miss_full_vicdirty = lu_miss_s1 && tagarray_dout_wayisfull_s1 && victimway_isdirty_s1;
assign lu_miss_full_vicclean = lu_miss_s1 && tagarray_dout_wayisfull_s1 && ~victimway_isdirty_s1;

wire read_hit_s1 ;
assign read_hit_s1 = tbus_is_read && lu_hit_s1;
wire write_hit_s1 ;
assign write_hit_s1 = tbus_is_write && lu_hit_s1;

/* -------------- prepare tagarray input for state WRITE_CACHE -------------- */
reg [`TAGRAM_RANGE] tagarray_din_writecache_s1;
always @(posedge clock or negedge reset_n) begin
    if(~reset_n)begin
        tagarray_din_writecache_s1 <= 0;
    end else begin
        if(lookup_hitway_dec_or == 1'b0)begin //hit way0
            tagarray_din_writecache_s1 <= {tagarray_dout_or[38:19],tagarray_dout_or[18],1'b1,tagarray_dout_or[16:0]};// set way0 dirty to 1
        end else begin
            tagarray_din_writecache_s1 <= {tagarray_dout_or[38],1'b1,tagarray_dout_or[36:19],tagarray_dout_or[18:0]};// set way1 dirty to 1            
        end
    end
end



/* -------------------------------------------------------------------------- */
/*                    Stage2 : when state == WRITE_CACHE or READ_CACHE                  */
/* -------------------------------------------------------------------------- */
/* -------- when state = WRITE_CACHE , write tagarray and data array -------- */


/* --------------------------- when state == READ_CACHE, get dataarray bank dout --------------------------- */
wire  [DATA_WIDTH-1:0] dataarray_dout_banks [7:0];
wire [ `RESULT_RANGE] tbus_read_data_s2;
always @(*) begin
    integer i;
    for(i=0;i<`DATARAM_BANKNUM;i=i+1)begin
        tbus_read_data_s2 = {64{dataarray_ce_bank[i]}} && dataarray_dout_banks[i];
    end
end

/* -------------------------------------------------------------------------- */
/*      Stage sx : when state == READ_DDR and opreation_done     */
/* -------------------------------------------------------------------------- */
/* --------------------------- get ddr 512bit cacheline data -------------------------- */
reg [`RESULT_RANGE] ddr_512_readdata_sx [7:0];
always @(*) begin
    if(~reset_n)begin
        ddr_512_readdata_sx = 0;
    end else if(state=READ_DDR && dcache2arb_tbus_operation_done)begin
        for(i=0;i<`DATARAM_BANKNUM;i=i+1)
        ddr_512_readdata_sx[i] = dcache2arb_tbus_read_data[(i+1)*64:i*64];        
    end else begin
        ddr_512_readdata_sx = 0;        
    end
end

/* -------- when opload, extract target 64 bit from ddr 512 bit data -------- */
reg [`RESULT_RANGE] masked_ddr_readdata_sx;
always @(*) begin
    if(~reset_n)begin
        masked_ddr_readdata_sx = 0;
    end else if(state=READ_DDR && dcache2arb_tbus_operation_done)begin
        for(i=0;i<`DATARAM_BANKNUM;i=i+1)begin
            if(bankaddr_onehot_or[i])begin
                masked_ddr_readdata_sx =  ddr_512_readdata_sx[i];
                break;                        
            end
        end
    end
end

//latch 64bit tbus wmask
reg [`RESULT_RANGE] masked_ddr_readdata_latch;
always @(posedge clock or reset_n) begin
    if(~reset_n) begin
        masked_ddr_readdata_latch <= 0;
    end else begin
        masked_ddr_readdata_latch <= masked_ddr_readdata_sx;
    end
end
wire [`RESULT_RANGE] masked_ddr_readdata_or;
assign masked_ddr_readdata_or = masked_ddr_readdata_latch | masked_ddr_readdata_sx;




/* ------------------------ when opstore , merge data ----------------------- */
reg [`RESULT_RANGE] merged_512_write_data [7:0];
always @(*) begin
    if(~reset_n)begin
        merged_512_write_data = 0;
    end else if(state=READ_DDR && dcache2arb_tbus_operation_done)begin
        for(i=0;i<`DATARAM_BANKNUM;i=i+1)begin
            if(~bankaddr_onehot_or[i])begin
                merged_512_write_data[i] =  ddr_512_readdata_sx[i];
            end else begin
                merged_512_write_data[i] =  (write_data_8banks[i] & write_mask_8banks[i]) | (ddr_512_readdata_sx[i] & ~write_mask_8banks[i]);                
            end
        end
    end
end


/* --------------------------- state = REFILL_READ -------------------------- */
reg [`TAGRAM_RANGE] tagarray_din_refillread_sx;
always @(posedge clock or negedge reset_n) begin
    if(~reset_n)begin
        tagarray_din_refillread_sx <= 0;
    end else begin
        if(lookup_hitway_dec_or == 1'b0)begin //hit way0
            tagarray_din_refillread_sx <= {tagarray_dout_or[38:19],1'b1,1'b0,ls_addr_or[31:15]};// set way0 dirty to 1
        end else begin
            tagarray_din_refillread_sx <= {1'b1,1'b0,ls_addr_or[31:15],tagarray_dout_or[18:0]};// set way1 dirty to 1            
        end
    end
end

//REFILL_WRITE tag din
reg [`TAGRAM_RANGE] tagarray_din_refillwrite_sx;
always @(posedge clock or negedge reset_n) begin
    if(~reset_n)begin
        tagarray_din_refillwrite_sx <= 0;
    end else begin
        if(lookup_hitway_dec_or == 1'b0)begin //hit way0
            tagarray_din_refillwrite_sx <= {tagarray_dout_or[38:19],1'b1,1'b0,ls_addr_or[31:15]};// set way0 dirty to 1
        end else begin
            tagarray_din_refillwrite_sx <= {1'b1,1'b0,ls_addr_or[31:15],tagarray_dout_or[18:0]};// set way1 dirty to 1            
        end
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
    .raddr   (tagarrray_raddr   ),
    .waddr   (tagarrray_waddr   ),
    .din     (tagarrray_din     ),
    .wmask   (tagarrray_wmask   ),
    .dout    (tagarray_dout    ) //output
);

dcache_dataarray u_dcache_dataarray(
    .clock             (clock             ),
    .reset_n           (reset_n           ),
    .we                (dataarray_we           ),
    .ce_way            (dataarray_ce_way),
    .ce_bank           (dataarray_ce_bank           ),
    .writesetaddr      (dataarray_writesetaddr  ),
    .readsetaddr       (dataarray_readsetaddr    ),
    .din_banks          (dataarray_din_banks               ),
    .wmask_banks        (dataarray_wmask_banks           ),
    .dout_banks         (dataarray_dout_banks             ),//output
);


/* -------------------------------------------------------------------------- */
/*                                     FSM                                    */
/* -------------------------------------------------------------------------- */

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
                    next_state = LOOKUP;
                else
                    next_state = IDLE;
            end
            LOOKUP: begin
                if( write_hit_s1) begin
                    next_state = WRITE_CACHE;
                end else if( read_hit_s1 || lu_miss_full_vicdirty) begin
                    next_state = READ_CACHE;
                end else begin//lu_miss_full_vicclean / lu_miss_notfull
                    next_state = READ_DDR;
                end
            end
            WRITE_CACHE: begin
                    next_state = IDLE;                    
            end
            READ_CACHE:begin
                if(read_hit_s1) begin
                    next_state = IDLE;
                end else if (lu_miss_full_vicdirty)begin
                    next_state = WRITE_DDR;
                end
            end
            WRITE_DDR: begin
                if(dcache2arb_tbus_operation_done)begin
                    next_state = READ_DDR;                    
                end
            end
            READ_DDR: begin
                if(dcache2arb_tbus_operation_done && tbus_is_read)begin
                    next_state = REFILL_READ;
                end else if(dcache2arb_tbus_operation_done && tbus_is_write)begin
                    next_state = REFILL_WRITE;
                end
            end
            REFILL_READ: begin
                next_state = IDLE;
            end
            REFILL_WRITE: begin
                next_state = IDLE;
            end
            default: next_state = IDLE;
        endcase
    end



/* --------------------------- set tagarray input --------------------------- */
//set tagarray chip_enable / writeenable
//TODO: write tag
reg tagarray_ce ;
reg tagarray_we ;
reg [8:0] tagarray_raddr;
reg [8:0] tagarray_waddr;
reg [`TAGRAM_RANGE] tagarray_din;
reg [`TAGRAM_RANGE] tagarray_wmask;

always @(*) begin   
    if (next_state = LOOKUP)begin 
        tagarray_ce = 1'b1;
        tagarray_we = 1'b0;
        tagarray_raddr = ls_addr_or[14:6];
        tagarray_waddr = 0;
        tagarray_din   = 0;
        tagarray_wmask = 0;
    end else if(next_state = WRITE_CACHE ) begin
        tagarray_ce = 1'b1;
        tagarray_we = 1'b1;        
        tagarray_raddr = 0;
        tagarray_waddr = ls_addr_or[14:6];
        tagarray_din   = tagarray_din_writecache_s1;
        tagarray_wmask = {`TAGRAM_LENGTH{1'b1}};
    end else if(next_state = REFILL_READ ) begin
        tagarray_ce = 1'b1;
        tagarray_we = 1'b1;
        tagarray_raddr = 0;
        tagarray_waddr = ls_addr_or[14:6];
        tagarray_din   = tagarray_din_refillread_sx;
        tagarray_wmask = {`TAGRAM_LENGTH{1'b1}};
    end else if(next_state = REFILL_WRITE) begin
        tagarray_ce = 1'b1;
        tagarray_we = 1'b1;        
        tagarray_raddr = 0;
        tagarray_waddr = ls_addr_or[14:6];
        tagarray_din   = tagarray_din_refillwrite_sx;
        tagarray_wmask = {`TAGRAM_LENGTH{1'b1}};
    end else begin
        tagarray_ce = 1'b0;
        tagarray_we = 1'b0;
        tagarray_raddr = 0;
        tagarray_waddr = 0;
        tagarray_din   = 0;
        tagarray_wmask = 0;
    end
end

/* --------------------------- set dataarray input -------------------------- */
wire dataarray_we;
wire [1:0] dataarray_ce_way ;
wire [7:0] dataarray_ce_bank ;
wire [DATA_WIDTH-1:0] dataarray_din_banks[7:0];
wire [DATA_WIDTH-1:0] dataarray_din_banks_allone[7:0];

assign dataarray_din_banks_allone = {8{64'hffff_ffff}};

always @(*) begin
    if(~reset_n)begin
        dataarray_we = 0;
        dataarray_ce_way = 0;
        dataarray_ce_bank = 0;
        dataarray_din_banks = 0;
        dataarray_writesetaddr = 0;
        dataarray_readsetaddr  = 0;
        dataarray_wmask_banks   = 0;
    end else if(next_state == WRITE_CACHE)begin//write dataarray
        dataarray_we = 1;
        dataarray_ce_way = lookup_hitway_onehot_s1;
        dataarray_ce_bank = bankaddr_onehot_or;
        dataarray_din_banks = write_data_8banks;
        dataarray_writesetaddr = ls_addr_or[14:6];
        dataarray_readsetaddr  = 0;
        dataarray_wmask_banks   = write_mask_8banks;
    end else if(next_state == READ_CACHE)begin//read dataarray
        dataarray_we = 0;
        dataarray_ce_way = lookup_hitway_onehot_s1;
        dataarray_ce_bank = bankaddr_onehot_or;
        dataarray_din_banks = 0;
        dataarray_writesetaddr = 0;
        dataarray_readsetaddr  = ls_addr_or[14:6];
        dataarray_wmask_banks   = 0;
    end else if(next_state==REFILL_READ)begin//write 512 ddr read data
        dataarray_we = 1;
        dataarray_ce_way = victimway_oh_s1;
        dataarray_ce_bank = bankaddr_onehot_or;    
        dataarray_din_banks = ddr_512_readdata_sx;
        dataarray_writesetaddr = ls_addr_or[14:6];
        dataarray_readsetaddr  = 0;
        dataarray_wmask_banks   = dataarray_din_banks_allone;
    end else if(next_state==REFILL_WRITE)begin//write 512 merged data
        dataarray_we = 1;
        dataarray_ce_way = victimway_oh_s1;
        dataarray_ce_bank = bankaddr_onehot_or;    
        dataarray_din_banks = merged_512_write_data;
        dataarray_writesetaddr = ls_addr_or[14:6];
        dataarray_readsetaddr  = 0;
        dataarray_wmask_banks   = dataarray_din_banks_allone;
    end else begin
        dataarray_we = 0;
        dataarray_ce_way = 0;        
        dataarray_ce_bank = 0;
        dataarray_din_banks = 0;
        dataarray_writesetaddr = 0;
        dataarray_readsetaddr  = 0;
        dataarray_wmask_banks   = 0;
    end
end
    
/* ----------------------- trinity bus to backend ----------------------- */
always @(*) begin
    if(~reset_n )begin
        tbus_operation_done = 0;
        tbus_read_data =0;
        tbus_index_ready =1;
    end else if(state==IDLE)begin
        tbus_operation_done = 1'b0;
        tbus_read_data = 0;
        tbus_index_ready = 1;    
    end else if(state == WRITE_CACHE)begin
        tbus_operation_done = 1'b1;
        tbus_read_data = 0;
        tbus_index_ready = 1;
    end else if(state == READ_CACHE && next_state == IDLE)begin 
        tbus_operation_done = 1'b1;
        tbus_read_data = tbus_read_data_s2;
        tbus_index_ready =1;
    end else if(state == REFILL_READ && next_state == IDLE)begin 
        tbus_operation_done = 1'b1;
        tbus_read_data = masked_ddr_readdata_or;
        tbus_index_ready =1;
    end else if(state == REFILL_WRITE && next_state == IDLE)begin 
        tbus_operation_done = 1'b1;
        tbus_index_ready =1;
    end else begin
        tbus_operation_done = 'b0;
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
        dcache2arb_tbus_burst_mode =0;
    end else if(state == READ_CACHE && next_state==WRITE_DDR)begin//write back dirty data to ddr
        dcache2arb_tbus_index_valid =1;
        dcache2arb_tbus_index =victimway_fulladdr_latch;
        dcache2arb_tbus_write_data =tbus_read_data_s2;//64bit
        dcache2arb_tbus_write_mask =write_mask_or;
        dcache2arb_tbus_operation_type =`TBUS_WRITE;   
        dcache2arb_tbus_burst_mode =0;
    end else if (state == WRITE_CACHE && dcache2arb_tbus_index_ready)begin
        dcache2arb_tbus_index_valid =0;        
    end else if(state == WRITE_DDR && next_state==READ_DDR)begin//read cacheline from ddr
        dcache2arb_tbus_index_valid =1;
        dcache2arb_tbus_index =ls_addr_or;
        dcache2arb_tbus_write_data =0;
        dcache2arb_tbus_write_mask =0;
        dcache2arb_tbus_operation_type =`TBUS_READ;
        dcache2arb_tbus_burst_mode =1;
    end else if(state == LOOKUP && next_state==READ_DDR)begin//read cacheline from ddr
        dcache2arb_tbus_index_valid =1;
        dcache2arb_tbus_index =ls_addr_or;
        dcache2arb_tbus_write_data =0;
        dcache2arb_tbus_write_mask =0;
        dcache2arb_tbus_operation_type =`TBUS_READ;
        dcache2arb_tbus_burst_mode =1;
    end else begin
        dcache2arb_tbus_index_valid =0;
        dcache2arb_tbus_index =0;
        dcache2arb_tbus_write_data =0;
        dcache2arb_tbus_write_mask =0;
        dcache2arb_tbus_operation_type =0;
        dcache2arb_tbus_burst_mode =0;
    end
end

endmodule


