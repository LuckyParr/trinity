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
    input  logic [CONDITION_WIDTH-1:0] intwb2memisq_writeback_mask,
    input  logic [`ROB_SIZE_LOG:0]    intwb2memisq_writeback_robid,
    input  logic [CONDITION_WIDTH-1:0] intwb2memisq_writeback_data // write back set sleep bit =1
);

    wire update_valid  = intwb2memisq_writeback_valid;
    wire update_mask   = intwb2memisq_writeback_mask;
    wire update_robid = intwb2memisq_writeback_robid;
    wire update_data = intwb2memisq_writeback_data;

    circular_queue_1r1w #(
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
        .update_valid (update_valid),
        .update_mask  (update_mask),
        .update_robid   (update_robid),
        .update_data  (update_data)
    );

endmodule
