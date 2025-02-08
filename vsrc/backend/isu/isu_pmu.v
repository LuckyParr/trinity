module isu_pmu (
    input clock,
    input end_of_program,
    input [31:0] intisq_pmu_block_enq_cycle_cnt,
    input [31:0] intisq_pmu_can_issue_more

);

    always @(posedge clock) begin
        if (end_of_program) begin
            $display("intisq_pmu_block_enq_cycle_cnt = %d", intisq_pmu_block_enq_cycle_cnt);
            $display("intisq_pmu_can_issue_more = %d", intisq_pmu_can_issue_more);
        end
    end



    
endmodule