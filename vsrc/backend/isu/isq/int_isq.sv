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
    // Broadcast condition updates
    //-----------------------------------------------------
    input  logic                         update_condition_valid,
    input  logic [`ROB_SIZE_LOG:0]       update_condition_robid,
    input  logic [CONDITION_WIDTH-1:0]  update_condition_mask,
    input  logic [CONDITION_WIDTH-1:0]  update_condition_in,

    //-----------------------------------------------------
    // Flush interface
    //-----------------------------------------------------
    input  logic                   flush_valid,
    input  logic [`ROB_SIZE_LOG:0]  flush_robid
);

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
        .flush_robid              (flush_robid)
    );

endmodule
