module issue_queue #(
    parameter ISSUE_QUEUE_DEPTH     = 8,
    parameter ISSUE_QUEUE_DEPTH_LOG = 3,
    parameter DATA_WIDTH            = 248
)(
    // Clock & Reset
    input  wire                     clock,
    input  wire                     reset_n,  // Active-low reset

    /* ----------------------issue queue itself wr/rd port --------------------- */
    // Write interface
    input  wire [DATA_WIDTH-1:0]    wr_data,
    input  wire                     wr_rs1_sleepbit,
    input  wire                     wr_rs2_sleepbit,
    // input  wire                     write_enable,
    input  wire                     isq_in_wr_valid,
    output wire                     isq_out_wr_ready, 
    output reg                      queue_full,  // Indicates no free entries

    // Wake-up interface for RS1
    input  wire [ISSUE_QUEUE_DEPTH_LOG-1:0] wake_rs1_index,
    input  wire                             wake_rs1_enable,

    // Wake-up interface for RS2
    input  wire [ISSUE_QUEUE_DEPTH_LOG-1:0] wake_rs2_index,
    input  wire                             wake_rs2_enable,

    // Read interface
    //input  wire                     read_enable,
    output  reg                     rd_valid,
    input  wire                     rd_ready,
    output reg  [DATA_WIDTH-1:0]    rd_data,

    /* ----------------------- read from physical register ---------------------- */
    output wire               isq2prf_prs1_rden,
    output wire [`PREG_RANGE]  isq2prf_prs1_rdaddr,  // Read register 1 address
    input  wire [63:0]        prf2isq_prs1_rddata,  // Data from isq2prf_prs1_rdaddr register

    output wire               isq2prf_prs2_rden,
    output wire [`PREG_RANGE]  isq2prf_prs2_rdaddr,  // Read register 2 address
    input  wire [63:0]        prf2isq_prs2_rddata,  // Data from isq2prf_prs2_rdaddr register

    /* ---------------------------- info write to fu ---------------------------- */
    output reg                isq_instr0_valid,
    input  wire               isq_instr0_ready,

    output wire [63:0]                    instr0_src1,
    output wire [63:0]                    instr0_src2,
    output   instr0_id,
    output   instr0_pc,
    output   instr0_prd,
    output   instr0_imm,
    output   instr0_need_to_wb,
    output   instr0_cx_type,
    output   instr0_is_unsigned,
    output   instr0_alu_type,
    output   instr0_muldiv_type,
    output   instr0_is_word,
    output   instr0_is_imm,
    output   instr0_is_load,  // to mem.v
    output   instr0_is_store, // to mem.v
    output   instr0_ls_size,  // to mem.v
    output   instr0, // for debug
/* ------------------------------- walk logic ------------------------------- */
    input flush_valid,
    input [`INSTR_ID_WIDTH-1:0] flush_id,
    input wire is_idle,
    input wire is_rollingback,
    input wire is_walking,
    input wire walking_valid0,
    input wire walking_valid1
);
    assign isq_out_wr_ready = valid_array[write_index];
    wire write_enable;
    assign write_enable = isq_in_wr_valid && isq_out_wr_ready;

    wire read_fire; //for debug
    assign read_fire = rd_valid && rd_ready;

    // ----------------------
    // Internal storage
    // ----------------------
    reg [DATA_WIDTH-1:0] data_array        [0:ISSUE_QUEUE_DEPTH-1];
    reg                  valid_array       [0:ISSUE_QUEUE_DEPTH-1];
    reg                  sleep_rs1_array   [0:ISSUE_QUEUE_DEPTH-1];
    reg                  sleep_rs2_array   [0:ISSUE_QUEUE_DEPTH-1];

    // +--------------------------------------------------------------+
    // | Circular search pointers                                     |
    // +--------------------------------------------------------------+
    // Renamed wptr_q -> write_index_mark
    reg [ISSUE_QUEUE_DEPTH_LOG-1:0] write_index_mark;
    // We keep read_index_mark name for read pointer
    reg [ISSUE_QUEUE_DEPTH_LOG-1:0] read_index_mark;

    // "Holding" state for the read side
    reg [ISSUE_QUEUE_DEPTH_LOG-1:0] read_slot_index;  // which entry we are currently holding
    reg                             read_slot_valid;  // do we currently hold an entry?

    // We will drive these from read_slot_*:
    assign rd_valid = read_slot_valid;
    assign rd_data  = data_array[read_slot_index];
    // --------------------------------------------------------
    // A) Find the first free slot for write (circular search)
    // --------------------------------------------------------
    reg [ISSUE_QUEUE_DEPTH_LOG-1:0] write_index;  // renamed from write_index_internal
    reg                             found_write_slot;

    integer i;
    always @* begin
        found_write_slot = 1'b0;
        write_index      = write_index_mark;  // Default

        // Search up to ISSUE_QUEUE_DEPTH times, wrapping around
        for (i = 0; i < ISSUE_QUEUE_DEPTH; i = i + 1) begin
            reg [ISSUE_QUEUE_DEPTH_LOG-1:0] idx;
            idx = (write_index_mark + i) % ISSUE_QUEUE_DEPTH;

            if (!found_write_slot && !valid_array[idx]) begin
                write_index      = idx;
                found_write_slot = 1'b1;
            end
        end
    end

    // ----------------------------------------------------------------
    // B) Circular search for a read slot
    // ----------------------------------------------------------------
    //
    // We only search for a new read slot if:
    //    * we do NOT already hold one (read_slot_valid=0)
    //    * we are not flushing, etc. (omitting flush logic for brevity)
    //
    // Then we do a circular scan from read_index_mark to find
    // the first (valid && !sleep_rs1 && !sleep_rs2).
    // We'll store that index in read_slot_index but NOT immediately
    // pop it from the queue array. We only pop once rd_ready=1.
    //

    reg [ISSUE_QUEUE_DEPTH_LOG-1:0] possible_read_index;
    reg                             found_read_slot;

    //found_read_slot and possible_read_index is just a temporary signal use to find available read slot in the exact cycle that we dont hold a read slot 
    always @* begin
        found_read_slot  = 1'b0;
        possible_read_index = read_index_mark;  // default

        if (!read_slot_valid) begin
            // Only search if we do not hold a slot
            for (i = 0; i < ISSUE_QUEUE_DEPTH; i = i + 1) begin
                reg [ISSUE_QUEUE_DEPTH_LOG-1:0] idx;
                idx = (read_index_mark + i) % ISSUE_QUEUE_DEPTH;
                if (!found_read_slot && valid_array[idx] && !sleep_rs1_array[idx] && !sleep_rs2_array[idx]) 
                begin
                    found_read_slot    = 1'b1;
                    possible_read_index = idx;
                end
            end
        end
    end

    // ----------------------------------------------------------------
    // C) Main sequential always block
    // ----------------------------------------------------------------
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            for (i = 0; i < ISSUE_QUEUE_DEPTH; i = i + 1) begin
                data_array[i]       <= {DATA_WIDTH{1'b0}};
                valid_array[i]      <= 1'b0;
                sleep_rs1_array[i]  <= 1'b0;
                sleep_rs2_array[i]  <= 1'b0;
            end
            write_index_mark <= 0;
            read_index_mark  <= 0;
            queue_full       <= 1'b0;

            read_slot_index  <= 0;
            read_slot_valid  <= 1'b0;
            isq_instr0_valid     <= 1'b0;
        end 
        else begin
            // -----------------------------
            // 1) Possibly flush/rollback
            // -----------------------------
            // We'll omit the actual flush logic or incorporate as needed

            // -----------------------------
            // 2) Handle writes
            // -----------------------------
            queue_full <= 1'b0;  // default
            if (write_enable) begin
                if (found_write_slot) begin
                    // Write into that slot
                    data_array[write_index]      <= wr_data;
                    valid_array[write_index]     <= 1'b1;
                    sleep_rs1_array[write_index] <= wr_rs1_sleepbit;
                    sleep_rs2_array[write_index] <= wr_rs2_sleepbit;
                    // Optionally increment the write_index_mark
                    // This is only a "hint" pointer. Some designs keep it stable
                    // or always move it. We'll do a naive approach:
                    write_index_mark <= (write_index_mark + 1) % ISSUE_QUEUE_DEPTH;
                end
                else begin
                    // No free slot => queue is full
                    queue_full <= 1'b1;
                end
            end

            // -----------------------------
            // 3) Wake-ups
            // -----------------------------
            if (wake_rs1_enable) begin
                sleep_rs1_array[wake_rs1_index] <= 1'b0;
            end
            if (wake_rs2_enable) begin
                sleep_rs2_array[wake_rs2_index] <= 1'b0;
            end

            // -----------------------------
            // 4) Read (handshake) logic
            // -----------------------------
            isq_instr0_valid <= 1'b0; // default

            if (!read_slot_valid) begin
                // We do NOT hold a slot. Check if we found one
                if (found_read_slot) begin
                    // Mark we hold that slot
                    read_slot_index <= possible_read_index;
                    read_slot_valid <= 1'b1;
                end
            end 
            else begin
                // We DO hold a slot => rd_valid=1 to the outside
                // We only pop it if rd_ready=1
                if (rd_ready) begin
                    // *** Now we pop it from the array ***
                    valid_array[read_slot_index] <= 1'b0;
                    
                    // Optionally, move read_index_mark up to the next slot
                    // We'll do something minimal like:
                    read_index_mark <= (read_slot_index + 1) % ISSUE_QUEUE_DEPTH;

                    // We are done holding that slot
                    read_slot_valid <= 1'b0;
                end
            end

            // If you want `isq_instr0_valid` to track the same as `rd_valid`, do:
            isq_instr0_valid <= read_slot_valid;
        end
    end


    /* ----------------------- read from physical register ----------------------- */
    assign isq2prf_prs1_rden   = instr0_src1_is_reg;
    assign isq2prf_prs1_rdaddr = instr0_prs1;

    assign isq2prf_prs2_rden   = instr0_src2_is_reg;
    assign isq2prf_prs2_rdaddr = instr0_prs2;

    /* ------------------------------ decode rd_data ------------------------------ */
    wire [`INSTR_ID_WIDTH-1:0] instr0_id         ;
    wire [63:0]                instr0_pc         ;
    wire [31:0]                instr0            ;
    wire [4:0]                 instr0_lrs1       ;
    wire [4:0]                 instr0_lrs2       ;
    wire [4:0]                 instr0_lrd        ;
    wire [5:0]                 instr0_prd        ;
    wire [5:0]                 instr0_old_prd    ;
    wire                       instr0_need_to_wb ;
    wire [5:0]                 instr0_prs1       ;
    wire [5:0]                 instr0_prs2       ;
    wire                       instr0_src1_is_reg;
    wire                       instr0_src2_is_reg;
    wire [63:0]                instr0_imm        ;
    wire [5:0]                 instr0_cx_type    ;
    wire                       instr0_is_unsigned;
    wire [10:0]                instr0_alu_type   ;
    wire [12:0]                instr0_muldiv_type;
    wire                       instr0_is_word    ;
    wire                       instr0_is_imm     ;
    wire                       instr0_is_load    ;
    wire                       instr0_is_store   ;
    wire [3:0]                 instr0_ls_size    ;

    // Physical register read data
    assign instr0_src1 = prf2isq_prs1_rddata;
    assign instr0_src2 = prf2isq_prs2_rddata;

    // Decode from rd_data
    assign instr0_id          = rd_data[247:241];
    assign instr0_pc          = rd_data[240:177];
    assign instr0             = rd_data[176:145];
    assign instr0_lrs1        = rd_data[144:140];
    assign instr0_lrs2        = rd_data[139:135];
    assign instr0_lrd         = rd_data[134:130];
    assign instr0_prd         = rd_data[129:124];
    assign instr0_old_prd     = rd_data[123:118];
    assign instr0_need_to_wb  = rd_data[117];
    assign instr0_prs1        = rd_data[116:111];
    assign instr0_prs2        = rd_data[110:105];
    assign instr0_src1_is_reg = rd_data[104];
    assign instr0_src2_is_reg = rd_data[103];
    assign instr0_imm         = rd_data[102:39];
    assign instr0_cx_type     = rd_data[38:33];
    assign instr0_is_unsigned = rd_data[32];
    assign instr0_alu_type    = rd_data[31:21];
    assign instr0_muldiv_type = rd_data[20:8];
    assign instr0_is_word     = rd_data[7];
    assign instr0_is_imm      = rd_data[6];
    assign instr0_is_load     = rd_data[5];
    assign instr0_is_store    = rd_data[4];
    assign instr0_ls_size     = rd_data[3:0];
/* ------------------------------- walk logic ------------------------------- */
    reg                  needflush_valid_array       [0:ISSUE_QUEUE_DEPTH-1];
    always @(*) begin
        if(is_rollingback) begin
            for(i = 0; i < `ISSUE_QUEUE_DEPTH; i = i + 1)begin
                if(valid_array[i] && ((flush_id[7] ^ data_array[i][247])^(flush_id[5:0] < data_array[i][246:241])))
                    needflush_valid_array[i] = 1'b1;
            end
        end
    end



// disp2isq_wrdata0 = {
// rob2disp_instr_id ,//7   //[247 : 241]
// instr0_pc         ,//64  //[240 : 177]         
// instr0            ,//32  //[176 : 145]         
// instr0_lrs1       ,//5   //[144 : 140]         
// instr0_lrs2       ,//5   //[139 : 135]         
// instr0_lrd        ,//5   //[134 : 130]         
// instr0_prd        ,//6   //[129 : 124]         
// instr0_old_prd    ,//6   //[123 : 118]         
// instr0_need_to_wb ,//1   //[117 : 117]         
// instr0_prs1       ,//6   //[116 : 111]         
// instr0_prs2       ,//6   //[110 : 105]         
// instr0_src1_is_reg,//1   //[104 : 104]         
// instr0_src2_is_reg,//1   //[103 : 103]         
// instr0_imm        ,//64  //[102 : 39 ]         
// instr0_cx_type    ,//6   //[38  : 33 ]         
// instr0_is_unsigned,//1   //[32  : 32 ]         
// instr0_alu_type   ,//11  //[31  : 21 ]         
// instr0_muldiv_type,//13  //[20  : 8  ]         
// instr0_is_word    ,//1   //[7   : 7  ]         
// instr0_is_imm     ,//1   //[6   : 6  ]         
// instr0_is_load    ,//1   //[5   : 5  ]         
// instr0_is_store   ,//1   //[4   : 4  ]         
// instr0_ls_size     //4   //[3   : 0  ]         
// };



endmodule
