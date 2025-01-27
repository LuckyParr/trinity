module mem_isq #(
    parameter DEPTH           = 8,
    parameter DATA_WIDTH      = 248,
    parameter CONDITION_WIDTH = 2
)(
    input  logic                      clock,
    input  logic                      reset_n,
    
    // Enqueue interface
    input  logic                      enqueue_valid,    
    output logic                      enqueue_ready,    
    input  logic [DATA_WIDTH-1:0]     enqueue_data,
    input  logic [CONDITION_WIDTH-1:0] enqueue_condition,

    // Dequeue interface
    output logic                      dequeue_valid,    
    input  logic                      dequeue_ready,    
    output logic [DATA_WIDTH-1:0]     dequeue_data,
    output logic [CONDITION_WIDTH-1:0] dequeue_condition,
    output logic [($clog2(DEPTH)+1)-1:0] memisq_id,

    // Flush interface
    input  logic                      flush_valid,
    input  logic [`ROB_SIZE_LOG:0]    flush_robid,

    // Update condition interface
    input  logic                      intwb2memisq_writeback_valid,
    input  logic [`ROB_SIZE_LOG:0]    intwb2memisq_writeback_robid,
    input  logic [CONDITION_WIDTH-1:0] intwb2memisq_writeback_data // write back set sleep bit =1
);

    assign update_condition_valid  = intwb2memisq_writeback_valid;
    assign update_condition_robid = intwb2memisq_writeback_robid;
    assign update_condition_data = intwb2memisq_writeback_data;

    circular_queue #(
        .DEPTH           (DEPTH),
        .DATA_WIDTH      (DATA_WIDTH),
        .CONDITION_WIDTH (CONDITION_WIDTH)
    ) u_circular_queue (
        .clock                  (clock),
        .reset_n                (reset_n),

        // Enqueue
        .enqueue_valid          (enqueue_valid),
        .enqueue_ready          (enqueue_ready),
        .enqueue_data           (enqueue_data),
        .enqueue_condition      (enqueue_condition),

        // Dequeue
        .dequeue_valid          (dequeue_valid),
        .dequeue_ready          (dequeue_ready),
        .dequeue_data           (dequeue_data),
        .dequeue_condition      (dequeue_condition),
        .dequeue_selfid          (memisq_id),

        // Flush
        .flush_valid            (flush_valid),
        .flush_robid               (flush_robid),

        // Update condition
        .update_condition_valid (update_condition_valid),
        .update_condition_robid   (update_condition_robid),
        .update_condition_data  (update_condition_data)
    );

endmodule
