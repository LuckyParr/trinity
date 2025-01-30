module int_isq #(
    //------------------------------------------------------------------
    // Match parameters used by age_buffer
    //------------------------------------------------------------------
    parameter DATA_WIDTH      = 248,
    parameter CONDITION_WIDTH = 2,
    parameter INDEX_WIDTH     = 4,
    parameter DEPTH           = 8
)(
    input  logic                   clock,
    input  logic                   reset_n,

    //-----------------------------------------------------
    // Enqueue interface
    //-----------------------------------------------------
    input  logic [DATA_WIDTH-1:0]       enq_data,
    input  logic [CONDITION_WIDTH-1:0]  enq_condition,
    input  logic [INDEX_WIDTH-1:0]      enq_index,
    input  logic                         enq_valid,  
    output logic                         enq_ready,  

    //-----------------------------------------------------
    // Dequeue interface
    //-----------------------------------------------------
    output logic [DATA_WIDTH-1:0]       deq_data,
    output logic [CONDITION_WIDTH-1:0]  deq_condition,
    output logic [INDEX_WIDTH-1:0]      deq_index,
    output logic                         deq_valid,  
    input  logic                         deq_ready,  

    //-----------------------------------------------------
    // writeback to set condition to 1
    //-----------------------------------------------------
    input  wire                       writeback0_valid,
    input  wire                       writeback0_need_to_wb,
    input  wire [`PREG_RANGE]         writeback0_prd,

    input wire                        writeback1_valid,
    input wire                        writeback1_need_to_wb,
    input wire [`PREG_RANGE]          writeback1_prd,
    //-----------------------------------------------------
    // Flush interface
    //-----------------------------------------------------
    input  logic                    flush_valid,
    input  logic [`INSTR_ID_WIDTH:0]  flush_robid
);
    logic [DEPTH-1:0][DATA_WIDTH-1:0]      data_out_array;
    logic [DEPTH-1:0][CONDITION_WIDTH-1:0] condition_out_array;
    logic [DEPTH-1:0][INDEX_WIDTH-1:0]     index_out_array;
    logic [DEPTH-1:0]                      valid_out_array;


    //-----------------------------------------------------
    // condition updates for writeback0
    //-----------------------------------------------------
    logic                         update_condition_valid;
    logic [`INSTR_ID_WIDTH:0]       update_condition_robid;
    logic [CONDITION_WIDTH-1:0]  update_condition_mask;
    logic [CONDITION_WIDTH-1:0]  update_condition_in;

    assign update_condition_valid = writeback0_valid && writeback0_need_to_wb && (writeback0_prd_match_prs1 || writeback0_prd_match_prs2);

    wire writeback0_prd_match_prs1;
    wire writeback0_prd_match_prs2;

    always @(*) begin
        integer i;
        update_condition_mask = 0;
        update_condition_in = 0;
        update_condition_robid = 0;
        writeback0_prd_match_prs1 = 0;
        writeback0_prd_match_prs2 = 0;
        for (i=0;i < DEPTH; i=i+1) begin
            //instr0_prs1
            if((data_out_array[i][116 : 111] == writeback0_prd) && valid_out_array[i])begin
                update_condition_mask = 2'b10;
                update_condition_in = 2'b10;
                update_condition_robid = index_out_array[i];
                writeback0_prd_match_prs1 = 1'b1;
            end
            //instr0_prs2
            if((data_out_array[i][110 : 105] == writeback0_prd) && valid_out_array[i])begin
                update_condition_mask = 2'b01;
                update_condition_in = 2'b01;
                update_condition_robid = index_out_array[i];
                writeback0_prd_match_prs2 = 1'b1;
            end            
        end
    end

    
    // --------------------------------------------------------------------
    // Instantiate the age_buffer module
    // --------------------------------------------------------------------
    age_buffer_1r1w #(
        .DATA_WIDTH      (DATA_WIDTH),
        .CONDITION_WIDTH (CONDITION_WIDTH),
        .INDEX_WIDTH     (INDEX_WIDTH),
        .DEPTH           (DEPTH)
    ) u_age_buffer (
        .clock                    (clock),
        .reset_n                  (reset_n),

        // Enqueue
        .enq_data                 (enq_data),
        .enq_condition            (enq_condition),
        .enq_index                (enq_index),
        .enq_valid                (enq_valid),
        .enq_ready                (enq_ready),

        // Dequeue
        .deq_data                 (deq_data),
        .deq_condition            (deq_condition),
        .deq_index                (deq_index),
        .deq_valid                (deq_valid),
        .deq_ready                (deq_ready),

        // Condition updates
        .update_condition_valid   (update_condition_valid),
        .update_condition_robid   (update_condition_robid),
        .update_condition_mask    (update_condition_mask),
        .update_condition_in      (update_condition_in),

        // Flush interface
        .flush_valid              (flush_valid),
        .flush_robid              (flush_robid),

        //output array
        .data_out_array     (data_out_array     ),
        .condition_out_array(condition_out_array),
        .index_out_array    (index_out_array    ),
        .valid_out_array    (valid_out_array    )
    );

endmodule
