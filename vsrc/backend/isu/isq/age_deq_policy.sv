`inlcude "defines.sv"
module age_deq_policy (
    input wire clock,
    input wire reset_n,
        input wire   [   `ISSUE_QUEUE_DEPTH-1:0] iq_entries_wren_oh,
        input wire [  `ISSUE_QUEUE_LOG -1 : 0] enq_ptr,
    input wire [   `ISSUE_QUEUE_DEPTH-1:0] iq_entries_ready_to_go,
    input wire [   `ISSUE_QUEUE_DEPTH-1:0] iq_entries_valid,

input       wire deq_fire,
 input   wire [`ISSUE_QUEUE_DEPTH-1:0] iq_entries_clear_entry,
    input wire[`ISSUE_QUEUE_LOG-1:0] deq_ptr,
    

    output reg oldest_found,
    output reg[`ISSUE_QUEUE_DEPTH-1:0] oldest_idx_oh

);


    // age_matrix[i][j] = 1 => "entry i" is older than "entry j"
    // reg   [`ISSUE_QUEUE_DEPTH-1:0] age_matrix[0:`ISSUE_QUEUE_DEPTH-1];
    reg   [`ISSUE_QUEUE_DEPTH-1:0] [`ISSUE_QUEUE_DEPTH-1:0]age_matrix;
    reg   [`ISSUE_QUEUE_DEPTH-1:0]                 needflush_dec;


    // ----------------------------------------------------------
    // Combinational logic: find the oldest ready entry (for dequeue)
    // ----------------------------------------------------------

    reg   any_j_older;
    always@(*) begin
        integer i;
        integer j;
        oldest_idx_oh = 'b0;
        oldest_found       = 1'b0;
        // Check if there's any j that is older than i
        any_j_older        = 1'b0;
        for ( i = 0; i < `ISSUE_QUEUE_DEPTH; i++) begin
            if (iq_entries_ready_to_go[i]) begin
                // // Check if there's any j that is older than i
                // logic any_j_older = 1'b0;
                for (j = 0; j < `ISSUE_QUEUE_DEPTH; j++) begin
                    if (j != i && age_matrix[j][i] && iq_entries_valid[j]) begin
                        any_j_older = 1'b1; //have any other older
                        break;
                    end
                end

                // If no j is older and we haven't chosen an oldest yet
                if (!any_j_older && !oldest_found) begin
                    oldest_idx_oh[i] = 1'b1;
                    oldest_found       = 1'b1;
                end
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
            for ( i = 0; i < `ISSUE_QUEUE_DEPTH; i++) begin
                for ( j = 0; j < `ISSUE_QUEUE_DEPTH; j++) begin
                    age_matrix[i][j] <= 1'b0;
                end
            end
        end else begin
            // ================================
            // Enqueue if enq_valid & enq_ready
            // ================================
            if (|iq_entries_wren_oh ) begin
                // Update age_matrix for the new entry enq_ptr
                // The new entry is "younger" than all existing valid entries
                for ( j = 0; j < `ISSUE_QUEUE_DEPTH; j++) begin
                    if (j != enq_ptr) begin
                        if (iq_entries_valid[j]) begin
                            // j is older than free_idx_for_enq
                            age_matrix[j][enq_ptr] <= 1'b1;
                            age_matrix[enq_ptr][j] <= 1'b0;
                        end else begin
                            age_matrix[j][enq_ptr] <= 1'b0;
                            age_matrix[enq_ptr][j] <= 1'b0;
                        end
                    end
                end
            end

            // ================================
            // Dequeue if we found an oldest ready entry & deq_ready
            // ================================
            if (deq_fire) begin

                // Clear row & column in the age_matrix
                for (int j = 0; j < `ISSUE_QUEUE_DEPTH; j++) begin
                    age_matrix[deq_ptr][j] <= 1'b0;
                    age_matrix[j][deq_ptr] <= 1'b0;
                end
            end
        end
    end

endmodule