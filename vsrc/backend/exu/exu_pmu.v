module exu_pmu (
    input clock,
    input end_of_program,
    input [31:0] bju_pmu_situation1_cnt,
    input [31:0] bju_pmu_situation2_cnt,
    input [31:0] bju_pmu_situation3_cnt,
    input [31:0] bju_pmu_situation4_cnt,
    input [31:0] bju_pmu_situation5_cnt
);

    wire [31:0] sum;
    assign sum = bju_pmu_situation1_cnt+bju_pmu_situation2_cnt+bju_pmu_situation3_cnt+bju_pmu_situation4_cnt+bju_pmu_situation5_cnt;
    wire [31:0] correctness_sum;
    assign correctness_sum = bju_pmu_situation1_cnt+bju_pmu_situation5_cnt;
    real correctness;
    assign correctness = (correctness_sum*100.0)/sum;
    //BJU predict situation counter
    always @(posedge clock) begin
        if (end_of_program) begin
            $display("bju_pmu_situation1_cnt = %d", bju_pmu_situation1_cnt);
            $display("bju_pmu_situation2_cnt = %d", bju_pmu_situation2_cnt);
            $display("bju_pmu_situation3_cnt = %d", bju_pmu_situation3_cnt);
            $display("bju_pmu_situation4_cnt = %d", bju_pmu_situation4_cnt);
            $display("bju_pmu_situation5_cnt = %d", bju_pmu_situation5_cnt);
            //$display("correctness of bpu prediction  = %d%%", (correctness_sum*100)/sum);
            $display("correctness of bpu prediction  = %0.2f%%", correctness);
        end
    end




endmodule
