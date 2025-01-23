module issue_queue #(
    parameter ISSUE_QUEUE_DEPTH = 8,
    parameter DATA_WIDTH        = 248
)(
    // Clock & Reset
    input  wire                     clock,
    input  wire                     reset_n,  // Active-low reset
    /* ----------------------------issue queue itself wr/rd port ---------------------------- */
    // Write interface
    input  wire [DATA_WIDTH-1:0]    write_data,
    input  wire                     write_sleep_rs1,
    input  wire                     write_sleep_rs2,
    input  wire                     write_enable,
    output reg                      queue_full,  // Indicates no free entries

    // Wake-up interface for RS1
    input  wire [$clog2(ISSUE_QUEUE_DEPTH)-1:0] wake_rs1_index,
    input  wire                                 wake_rs1_enable,

    // Wake-up interface for RS2
    input  wire [$clog2(ISSUE_QUEUE_DEPTH)-1:0] wake_rs2_index,
    input  wire                                 wake_rs2_enable,

    // Read interface
    input  wire                     read_enable,
    output reg  [DATA_WIDTH-1:0]    read_data,
    output reg                      read_data_valid,

    /* ----------------------- read from phsical register ----------------------- */
    output wire               isq2prf_prs1_rden,
    output wire [`PREG_RANGE] isq2prf_prs1_rdaddr,  // Read register 1 address
    input reg [63:0] prf2isq_prs1_rddata,  // Data from isq2prf_prs1_rdaddr register

    output wire               isq2prf_prs2_rden,
    output wire [`PREG_RANGE] isq2prf_prs2_rdaddr,  // Read register 2 address
    input reg [63:0] prf2isq_prs2_rddata,  // Data from isq2prf_prs2_rdaddr register

    /* ---------------------------- info write to fu ---------------------------- */
    output reg                instr0_valid,
    input  wire               instr0_ready,

    output wire instr0_src1,
    output wire instr0_src2,
    output   [`INSTR_ID_WIDTH-1:0]       instr0_id,
    output  [`SRC_RANGE] instr0_pc,
//    output reg  [`PREG_RANGE] instr0_prs1,
//    output reg  [`PREG_RANGE] instr0_prs2,
//    output reg                instr0_src1_is_reg,
//    output reg                instr0_src2_is_reg,
    output  [`PREG_RANGE] instr0_prd,
//    output reg [`PREG_RANGE] instr0_old_prd,

    output  [`SRC_RANGE ] instr0_imm               ,
    output                       instr0_need_to_wb ,
    output  [    `CX_TYPE_RANGE] instr0_cx_type    ,
    output                       instr0_is_unsigned,
    output  [   `ALU_TYPE_RANGE] instr0_alu_type   ,
    output  [`MULDIV_TYPE_RANGE] instr0_muldiv_type,
    output                       instr0_is_word    ,
    output                       instr0_is_imm     ,
    output                       instr0_is_load    , //to mem.v
    output                       instr0_is_store   , //to mem.v
    output  [               3:0] instr0_ls_size    , //to mem.v

    output instr0 // send instr itself for debug

);

    // ----------------------
    // Internal memory arrays
    // ----------------------
    reg [DATA_WIDTH-1:0] data_array   [0:ISSUE_QUEUE_DEPTH-1];
    reg                  valid_array  [0:ISSUE_QUEUE_DEPTH-1];
    // Two separate sleep bits per entry
    reg                  sleep_rs1_array [0:ISSUE_QUEUE_DEPTH-1];
    reg                  sleep_rs2_array [0:ISSUE_QUEUE_DEPTH-1];

    // --------------------------------------------------------
    // 1) Find the first free slot for write (i.e. valid=0)
    // --------------------------------------------------------
    reg [$clog2(ISSUE_QUEUE_DEPTH)-1:0] write_index_internal;
    reg                                  found_write_slot;

    integer i;
    always @* begin
        found_write_slot     = 1'b0;
        write_index_internal = {($clog2(ISSUE_QUEUE_DEPTH)){1'b0}};
        for (i = 0; i < ISSUE_QUEUE_DEPTH; i = i + 1) begin
            if (!found_write_slot && !valid_array[i]) begin
                write_index_internal = i[$clog2(ISSUE_QUEUE_DEPTH)-1:0];
                found_write_slot     = 1'b1;
            end
        end
    end

    // -------------------------------------------------------------
    // 2) Find the first valid entry with BOTH sleep bits cleared
    // -------------------------------------------------------------
    reg [$clog2(ISSUE_QUEUE_DEPTH)-1:0] read_index;
    reg                                  found_read_slot;

    always @* begin
        found_read_slot = 1'b0;
        read_index      = {($clog2(ISSUE_QUEUE_DEPTH)){1'b0}};
        for (i = 0; i < ISSUE_QUEUE_DEPTH; i = i + 1) begin
            // Must be valid AND both sleep bits = 0
            if (!found_read_slot && valid_array[i] &&
                !sleep_rs1_array[i] && !sleep_rs2_array[i]) begin
                read_index      = i[$clog2(ISSUE_QUEUE_DEPTH)-1:0];
                found_read_slot = 1'b1;
            end
        end
    end

    // -------------------------------------------------------------
    // 3) Sequential logic
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
            read_data       <= {DATA_WIDTH{1'b0}};
            read_data_valid <= 1'b0;
            queue_full      <= 1'b0;
        end
        else begin
            //------------------------------------------
            // A) Handle write: if a free slot is found
            //------------------------------------------
            queue_full <= 1'b0;  // Default is not full
            if (write_enable) begin
                if (found_write_slot) begin
                    data_array[write_index_internal]       <= write_data;
                    valid_array[write_index_internal]      <= 1'b1;
                    sleep_rs1_array[write_index_internal]  <= write_sleep_rs1;
                    sleep_rs2_array[write_index_internal]  <= write_sleep_rs2;
                end
                else begin
                    // No free slot found => queue is full
                    queue_full <= 1'b1;
                end
            end

            //------------------------------------------
            // B) Wake-up (set the corresponding sleep bit to 0)
            //------------------------------------------
            if (wake_rs1_enable) begin
                sleep_rs1_array[wake_rs1_index] <= 1'b0;
            end
            if (wake_rs2_enable) begin
                sleep_rs2_array[wake_rs2_index] <= 1'b0;
            end

            //------------------------------------------
            // C) Handle read
            //------------------------------------------
            // By default, no valid read output
            read_data_valid <= 1'b0;
            if (read_enable) begin
                if (found_read_slot) begin
                    // Output data for the selected entry
                    read_data       <= data_array[read_index];
                    read_data_valid <= 1'b1;
                    // Once read, clear valid bit
                    valid_array[read_index] <= 1'b0;
                    instr0_valid <= 1'b1; // if can find entry to read, make instr0_valid = 1 to send it to fu
                end
                else begin
                    // If no valid, fully-awake entry found, output invalid
                    read_data       <= {DATA_WIDTH{1'b0}};
                    read_data_valid <= 1'b0;
                    instr0_valid <= 1'b0;
                end
            end
        end
    end



/* ----------------------- read from phsical register ----------------------- */
    assign isq2prf_prs1_rden = instr0_src1_is_reg;
    assign isq2prf_prs1_rdaddr = instr0_prs1;

    assign isq2prf_prs2_rden = instr0_src2_is_reg;
    assign isq2prf_prs2_rdaddr = instr0_prs2;



/* ------------------------------ decode rddata and send some of them to fu----------------------------- */
//  each decoded field
    wire [`INSTR_ID_WIDTH-1:0]  instr0_id         ;
    wire [63:0] instr0_pc         ;
    wire [31:0] instr0            ;
    wire [4:0]  instr0_lrs1       ;
    wire [4:0]  instr0_lrs2       ;
    wire [4:0]  instr0_lrd        ;
    wire [5:0]  instr0_prd        ;
    wire [5:0]  instr0_old_prd    ;
    wire        instr0_need_to_wb ;
    wire [5:0]  instr0_prs1       ;
    wire [5:0]  instr0_prs2       ;
    wire        instr0_src1_is_reg;
    wire        instr0_src2_is_reg;
    wire [63:0] instr0_imm        ;
    wire [5:0]  instr0_cx_type    ;
    wire        instr0_is_unsigned;
    wire [10:0] instr0_alu_type   ;
    wire [12:0] instr0_muldiv_type;
    wire        instr0_is_word    ;
    wire        instr0_is_imm     ;
    wire        instr0_is_load    ;
    wire        instr0_is_store   ;
    wire [3:0]  instr0_ls_size    ;
    // Decode the disp2isq_wrdata0 signal
    assign instr0_src1 =  prf2isq_prs1_rddata;
    assign instr0_src2 =  prf2isq_prs2_rddata;
    assign instr0_id          = read_data[247:241];
    assign instr0_pc          = read_data[240:177];
    assign instr0             = read_data[176:145];
    assign instr0_lrs1        = read_data[144:140];
    assign instr0_lrs2        = read_data[139:135];
    assign instr0_lrd         = read_data[134:130];
    assign instr0_prd         = read_data[129:124];
    assign instr0_old_prd     = read_data[123:118];
    assign instr0_need_to_wb  = read_data[117    ];
    assign instr0_prs1        = read_data[116:111];
    assign instr0_prs2        = read_data[110:105];
    assign instr0_src1_is_reg = read_data[104    ];
    assign instr0_src2_is_reg = read_data[103    ];
    assign instr0_imm         = read_data[102:39 ];
    assign instr0_cx_type     = read_data[38:33  ];
    assign instr0_is_unsigned = read_data[32     ];
    assign instr0_alu_type    = read_data[31:21  ];
    assign instr0_muldiv_type = read_data[20:8   ];
    assign instr0_is_word     = read_data[7      ];
    assign instr0_is_imm      = read_data[6      ];
    assign instr0_is_load     = read_data[5      ];
    assign instr0_is_store    = read_data[4      ];
    assign instr0_ls_size     = read_data[3:0    ];





endmodule
