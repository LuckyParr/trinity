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
    input  wire [DATA_WIDTH-1:0]    write_data,
    input  wire                     write_sleep_rs1,
    input  wire                     write_sleep_rs2,
    input  wire                     write_enable,
    output reg                      queue_full,  // Indicates no free entries

    // Wake-up interface for RS1
    input  wire [ISSUE_QUEUE_DEPTH_LOG-1:0] wake_rs1_index,
    input  wire                             wake_rs1_enable,

    // Wake-up interface for RS2
    input  wire [ISSUE_QUEUE_DEPTH_LOG-1:0] wake_rs2_index,
    input  wire                             wake_rs2_enable,

    // Read interface
    input  wire                     read_enable,
    output reg  [DATA_WIDTH-1:0]    read_data,
    output reg                      read_data_valid,

    /* ----------------------- read from physical register ---------------------- */
    output wire               isq2prf_prs1_rden,
    output wire [`PREG_RANGE]  isq2prf_prs1_rdaddr,  // Read register 1 address
    input  wire [63:0]        prf2isq_prs1_rddata,  // Data from isq2prf_prs1_rdaddr register

    output wire               isq2prf_prs2_rden,
    output wire [`PREG_RANGE]  isq2prf_prs2_rdaddr,  // Read register 2 address
    input  wire [63:0]        prf2isq_prs2_rddata,  // Data from isq2prf_prs2_rdaddr register

    /* ---------------------------- info write to fu ---------------------------- */
    output reg                instr0_valid,
    input  wire               instr0_ready,

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

    // --------------------------------------------------------
    // 1) Find the first free slot for write (circular search)
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

    // -------------------------------------------------------------
    // 2) Find first valid entry w/ BOTH sleep bits cleared (circular)
    // -------------------------------------------------------------
    reg [ISSUE_QUEUE_DEPTH_LOG-1:0] read_index;
    reg                             found_read_slot;

    always @* begin
        found_read_slot = 1'b0;
        read_index      = read_index_mark;  // default

        for (i = 0; i < ISSUE_QUEUE_DEPTH; i = i + 1) begin
            reg [ISSUE_QUEUE_DEPTH_LOG-1:0] idx;
            idx = (read_index_mark + i) % ISSUE_QUEUE_DEPTH;

            if (!found_read_slot && valid_array[idx] &&
                !sleep_rs1_array[idx] && !sleep_rs2_array[idx]) begin
                read_index      = idx;
                found_read_slot = 1'b1;
            end
        end
    end

    // -------------------------------------------------------------
    // 3) Main sequential logic
    // -------------------------------------------------------------
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            // Reset all internal states
            for (i = 0; i < ISSUE_QUEUE_DEPTH; i = i + 1) begin
                data_array[i]       <= {DATA_WIDTH{1'b0}};
                valid_array[i]      <= 1'b0;
                sleep_rs1_array[i]  <= 1'b0;
                sleep_rs2_array[i]  <= 1'b0;
            end

            read_data         <= {DATA_WIDTH{1'b0}};
            read_data_valid   <= 1'b0;
            queue_full        <= 1'b0;
            instr0_valid      <= 1'b0;

            // Reset the circular pointers
            write_index_mark  <= {ISSUE_QUEUE_DEPTH_LOG{1'b0}};
            read_index_mark   <= {ISSUE_QUEUE_DEPTH_LOG{1'b0}};
        end
        else begin
            if(is_rollingback)begin
                valid_array  <= valid_array & ~needflush_valid;
            end else if(is_walking)begin
                
            end 
            else begin
            // ---------------------------------------
            // A) Handle writes
            // ---------------------------------------
            queue_full <= 1'b0;  // Default not full
            if (write_enable) begin
                if (found_write_slot) begin
                    data_array[write_index]      <= write_data;
                    valid_array[write_index]     <= 1'b1;
                    sleep_rs1_array[write_index] <= write_sleep_rs1;
                    sleep_rs2_array[write_index] <= write_sleep_rs2;

                    // Advance the write pointer
                    write_index_mark <= (write_index + 1) % ISSUE_QUEUE_DEPTH;
                end
                else begin
                    // No free slot => queue is full
                    queue_full <= 1'b1;
                end
            end

            // ---------------------------------------
            // B) Wake-ups
            // ---------------------------------------
            if (wake_rs1_enable) begin
                sleep_rs1_array[wake_rs1_index] <= 1'b0;
            end
            if (wake_rs2_enable) begin
                sleep_rs2_array[wake_rs2_index] <= 1'b0;
            end

            // ---------------------------------------
            // C) Handle reads
            // ---------------------------------------
            read_data_valid <= 1'b0;
            instr0_valid    <= 1'b0; // default

            if (read_enable) begin
                if (found_read_slot) begin
                    read_data             <= data_array[read_index];
                    read_data_valid       <= 1'b1;
                    valid_array[read_index] <= 1'b0;

                    instr0_valid <= 1'b1;

                    // Advance the read pointer
                    read_index_mark <= (read_index + 1) % ISSUE_QUEUE_DEPTH;
                end
                else begin
                    read_data       <= {DATA_WIDTH{1'b0}};
                    read_data_valid <= 1'b0;
                    instr0_valid    <= 1'b0;
                end
            end
        end
    end
    end 

    /* ----------------------- read from physical register ----------------------- */
    assign isq2prf_prs1_rden   = instr0_src1_is_reg;
    assign isq2prf_prs1_rdaddr = instr0_prs1;

    assign isq2prf_prs2_rden   = instr0_src2_is_reg;
    assign isq2prf_prs2_rdaddr = instr0_prs2;

    /* ------------------------------ decode read_data ------------------------------ */
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

    // Decode from read_data
    assign instr0_id          = read_data[247:241];
    assign instr0_pc          = read_data[240:177];
    assign instr0             = read_data[176:145];
    assign instr0_lrs1        = read_data[144:140];
    assign instr0_lrs2        = read_data[139:135];
    assign instr0_lrd         = read_data[134:130];
    assign instr0_prd         = read_data[129:124];
    assign instr0_old_prd     = read_data[123:118];
    assign instr0_need_to_wb  = read_data[117];
    assign instr0_prs1        = read_data[116:111];
    assign instr0_prs2        = read_data[110:105];
    assign instr0_src1_is_reg = read_data[104];
    assign instr0_src2_is_reg = read_data[103];
    assign instr0_imm         = read_data[102:39];
    assign instr0_cx_type     = read_data[38:33];
    assign instr0_is_unsigned = read_data[32];
    assign instr0_alu_type    = read_data[31:21];
    assign instr0_muldiv_type = read_data[20:8];
    assign instr0_is_word     = read_data[7];
    assign instr0_is_imm      = read_data[6];
    assign instr0_is_load     = read_data[5];
    assign instr0_is_store    = read_data[4];
    assign instr0_ls_size     = read_data[3:0];
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
