`include "defines.sv"
module age_deq_policy (
    input wire                           clock,
    input wire                           reset_n,
    input wire [ `ISSUE_QUEUE_DEPTH-1:0] iq_entries_ready_to_go,
    input wire [ `ISSUE_QUEUE_DEPTH-1:0] iq_entries_valid,
    /* ------------------------------ enqueue fire ------------------------------ */
    input wire [ `ISSUE_QUEUE_DEPTH-1:0] iq_entries_wren_oh,
    input wire [`ISSUE_QUEUE_LOG -1 : 0] enq_ptr,
    /* ------------------------------ dequeue fire ------------------------------ */
    input wire [ `ISSUE_QUEUE_DEPTH-1:0] iq_entries_clear_entry,
    input wire [   `ISSUE_QUEUE_LOG-1:0] deq_ptr,

    output reg                          oldest_found,
    output reg [`ISSUE_QUEUE_DEPTH-1:0] oldest_idx_oh

);


    // age_matrix[i][j] = 1 => "entry i" is older than "entry j"
    // reg   [`ISSUE_QUEUE_DEPTH-1:0] age_matrix[0:`ISSUE_QUEUE_DEPTH-1];
    reg [`ISSUE_QUEUE_DEPTH-1:0][`ISSUE_QUEUE_DEPTH-1:0] age_matrix;
    reg [`ISSUE_QUEUE_DEPTH-1:0]                         needflush_dec;


    // ----------------------------------------------------------
    // Combinational logic: find the oldest ready entry (for dequeue)
    // ----------------------------------------------------------

    reg [`ISSUE_QUEUE_DEPTH-1:0]                         any_j_older;
    always @(*) begin
        integer i;
        integer j;
        // Check if there's any j that is older than i
        any_j_older = 'b0;
        for (i = 0; i < `ISSUE_QUEUE_DEPTH; i++) begin  // 列
            if (iq_entries_ready_to_go[i]) begin
                // // Check if there's any j that is older than i
                for (j = 0; j < `ISSUE_QUEUE_DEPTH; j++) begin  // 行
                    if (j != i && age_matrix[j][i] && iq_entries_valid[j]) begin
                        // any_j_older = 1'b1;  //have any other older
                        any_j_older[i] = 1'b1;  //have any other older
                        break;
                    end
                end
            end
        end
    end

    always @(*) begin
        integer i;
        oldest_idx_oh = 'b0;
        oldest_found  = 1'b0;
        for (i = 0; i < `ISSUE_QUEUE_DEPTH; i++) begin  // 列
            if (any_j_older[i] == 0 && iq_entries_valid[i] == 1) begin
                oldest_idx_oh[i] = 1'b1;
                oldest_found     = 1'b1;
            end
        end
    end

    // ----------------------------------------------------------
    // Main sequential block
    //   - Update age_matrix
    // ----------------------------------------------------------
    always @(posedge clock or negedge reset_n) begin
        integer i;
        integer j;
        if (!reset_n) begin
            // Reset everything
            for (i = 0; i < `ISSUE_QUEUE_DEPTH; i++) begin
                for (j = 0; j < `ISSUE_QUEUE_DEPTH; j++) begin
                    age_matrix[i][j] <= 1'b0;
                end
            end
        end else begin
            // ================================
            // Enqueue if enq_valid & enq_ready
            // ================================
            if (|iq_entries_wren_oh) begin
                // Update age_matrix for the new entry enq_ptr
                // The new entry is "younger" than all existing valid entries
                for (j = 0; j < `ISSUE_QUEUE_DEPTH; j++) begin
                    if (j != enq_ptr) begin  //对角线永为0
                        if (iq_entries_valid[j]) begin
                            // j is older than free_idx_for_enq
                            age_matrix[j][enq_ptr] <= 1'b1;  //有效行，写入列置1
                            age_matrix[enq_ptr][j] <= 1'b0;  //写入行，有效列为0
                        end else begin
                            age_matrix[j][enq_ptr] <= 1'b0;  //无效行，写入列置0
                            age_matrix[enq_ptr][j] <= 1'b0;  //写入行，无效列为0
                        end
                    end
                end
            end

            // ================================
            // Dequeue if we found an oldest ready entry & deq_ready
            // ================================
            if (|iq_entries_clear_entry) begin

                // Clear row & column in the age_matrix
                for (int j = 0; j < `ISSUE_QUEUE_DEPTH; j++) begin
                    age_matrix[deq_ptr][j] <= 1'b0;
                    age_matrix[j][deq_ptr] <= 1'b0;
                end
            end
        end
    end

    //for debug
    wire [`ISSUE_QUEUE_DEPTH-1:0] age_matrix_row_0 = age_matrix[0];
    wire [`ISSUE_QUEUE_DEPTH-1:0] age_matrix_row_1 = age_matrix[1];
    wire [`ISSUE_QUEUE_DEPTH-1:0] age_matrix_row_2 = age_matrix[2];
    wire [`ISSUE_QUEUE_DEPTH-1:0] age_matrix_row_3 = age_matrix[3];
    wire [`ISSUE_QUEUE_DEPTH-1:0] age_matrix_row_4 = age_matrix[4];
    wire [`ISSUE_QUEUE_DEPTH-1:0] age_matrix_row_5 = age_matrix[5];
    wire [`ISSUE_QUEUE_DEPTH-1:0] age_matrix_row_6 = age_matrix[6];
    wire [`ISSUE_QUEUE_DEPTH-1:0] age_matrix_row_7 = age_matrix[7];





endmodule
