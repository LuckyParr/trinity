module cqentry #(
    parameter DATA_WIDTH      = 32,
    parameter CONDITION_WIDTH = 2,
    parameter INDEX_WIDTH     = 4
)(
    input  logic                      clock,
    input  logic                      reset_n,

    // Write-enable to load new values (data, condition, index, valid)
    input  logic                      wr_en,

    // Clear signal (highest priority)
    input  logic                      clear_entry,

    // Inputs to store (for enqueue)
    input  logic [DATA_WIDTH-1:0]      data_in,
    input  logic [CONDITION_WIDTH-1:0] condition_in,
    input  logic [INDEX_WIDTH-1:0]     index_in,
    input  logic                       valid_in,

    // Update condition port (no conflict on same entry in same cycle)
    input  logic                       update_condition_valid,
    input  logic [CONDITION_WIDTH-1:0] update_condition_in,
    
    // Outputs
    output logic [DATA_WIDTH-1:0]      data_out,
    output logic [CONDITION_WIDTH-1:0] condition_out,
    output logic [INDEX_WIDTH-1:0]     index_out,
    output logic                       valid_out,

    // ready_to_dequeue = valid_out && (&condition_out)
    output logic                       ready_to_dequeue_out
);

    always_ff @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            data_out       <= '0;
            condition_out  <= '0;
            index_out      <= '0;
            valid_out      <= 1'b0;
        end 
        else begin
            // Highest priority: clear
            if (clear_entry) begin
                data_out       <= '0;
                condition_out  <= '0;
                index_out      <= '0;
                valid_out      <= 1'b0;
            end
            // Next: normal write enable
            else if (wr_en) begin
                data_out      <= data_in;
                condition_out <= condition_in;
                index_out     <= index_in;
                valid_out     <= valid_in;
            end
            // Otherwise, hold current contents

            // Finally, update condition if requested
            if (update_condition_valid) begin
                condition_out <= update_condition_in;
            end
        end
    end

    // All bits of condition_out must be 1 => ready
    assign ready_to_dequeue_out = valid_out && (&condition_out);

endmodule
