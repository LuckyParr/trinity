module cqentry (
    input logic clock,
    input logic reset_n,

    // Clear signal (highest priority)
    input logic                            clear_entry,

    // Write-enable to load new values (data, condition, index, valid)
    input logic                            wr_en,
    input logic [     `ISQ_DATA_WIDTH-1:0] data_in,
    input logic [`ISQ_CONDITION_WIDTH-1:0] condition_in,
    input logic [    `ISQ_INDEX_WIDTH-1:0] index_in,
    input logic                            valid_in,

    // Update condition port (no conflict on same entry in same cycle)
    input logic                            update_valid,
    input logic [`ISQ_CONDITION_WIDTH-1:0] update_mask,
    input logic [`ISQ_CONDITION_WIDTH-1:0] update_in,

    // Outputs
    output logic [     `ISQ_DATA_WIDTH-1:0] data_out,
    output logic [`ISQ_CONDITION_WIDTH-1:0] condition_out,
    output logic [    `ISQ_INDEX_WIDTH-1:0] index_out,
    output logic                            valid_out,
    // ready_to_dequeue = valid_out && (&condition_out)
    output logic                            ready_to_dequeue_out
);

    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            condition_out <= '0;
        end else begin
            // Highest priority: clear
            if (clear_entry) begin
                condition_out <= '0;
            end  // Next: normal write enable
            else if (wr_en) begin
                condition_out <= condition_in;
            end
            //update condition bit
            if (update_valid) begin
                condition_out <= (update_in & update_mask) | (condition_out & ~update_mask);
            end
        end
    end

    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            data_out <= '0;
        end else begin
            if (clear_entry) begin
                data_out <= '0;
            end else if (wr_en) begin
                data_out <= data_in;
            end
        end
    end

    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            index_out <= '0;
        end else begin
            if (clear_entry) begin
                index_out <= '0;
            end else if (wr_en) begin
                index_out <= index_in;
            end
        end
    end

    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            valid_out <= '0;
        end else begin
            if (clear_entry) begin
                valid_out <= '0;
            end else if (wr_en) begin
                valid_out <= valid_in;
            end
        end
    end


    // All bits of condition_out must be 1 => ready
    assign ready_to_dequeue_out = valid_out && (&condition_out);

endmodule
