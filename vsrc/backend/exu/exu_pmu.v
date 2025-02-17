module exu_pmu (
    input clock,
    input end_of_program,
    input [31:0] bju_pmu_situation1_cnt_btype,
    input [31:0] bju_pmu_situation2_cnt_btype,
    input [31:0] bju_pmu_situation3_cnt_btype,
    input [31:0] bju_pmu_situation4_cnt_btype,
    input [31:0] bju_pmu_situation5_cnt_btype,

    input [31:0] bju_pmu_situation1_cnt_jtype,
    input [31:0] bju_pmu_situation2_cnt_jtype,
    input [31:0] bju_pmu_situation3_cnt_jtype,
    input [31:0] bju_pmu_situation4_cnt_jtype,
    input [31:0] bju_pmu_situation5_cnt_jtype
);
//btype
    wire [31:0] sum_btype;
    assign sum_btype = bju_pmu_situation1_cnt_btype+bju_pmu_situation2_cnt_btype+bju_pmu_situation3_cnt_btype+bju_pmu_situation4_cnt_btype+bju_pmu_situation5_cnt_btype;
    wire [31:0] correctness_sum_btype;
    assign correctness_sum_btype = bju_pmu_situation1_cnt_btype+bju_pmu_situation5_cnt_btype;
    real correctness_btype;
    assign correctness_btype = (correctness_sum_btype*100.0)/sum_btype;
    //BJU predict situation counter
    always @(posedge clock) begin
        if (end_of_program) begin
            $display("bju_pmu_situation1_cnt_btype = %d", bju_pmu_situation1_cnt_btype);
            $display("bju_pmu_situation2_cnt_btype = %d", bju_pmu_situation2_cnt_btype);
            $display("bju_pmu_situation3_cnt_btype = %d", bju_pmu_situation3_cnt_btype);
            $display("bju_pmu_situation4_cnt_btype = %d", bju_pmu_situation4_cnt_btype);
            $display("bju_pmu_situation5_cnt_btype = %d", bju_pmu_situation5_cnt_btype);
            //$display("correctness of bpu prediction  = %d%%", (correctness_sum*100)/sum);
            $display("prediction correctness rate of bpu branch instr  = %0.2f%%", correctness_btype);
        end
    end

//jtype
    wire [31:0] sum_jtype;
    assign sum_jtype = bju_pmu_situation1_cnt_jtype+bju_pmu_situation2_cnt_jtype+bju_pmu_situation3_cnt_jtype+bju_pmu_situation4_cnt_jtype+bju_pmu_situation5_cnt_jtype;
    wire [31:0] correctness_sum_jtype;
    assign correctness_sum_jtype = bju_pmu_situation1_cnt_jtype+bju_pmu_situation5_cnt_jtype;
    real correctness_jtype;
    assign correctness_jtype = (correctness_sum_jtype*100.0)/sum_jtype;
    //BJU predict situation counter
    always @(posedge clock) begin
        if (end_of_program) begin
            $display("bju_pmu_situation1_cnt_jtype = %d", bju_pmu_situation1_cnt_jtype);
            $display("bju_pmu_situation2_cnt_jtype = %d", bju_pmu_situation2_cnt_jtype);
            $display("bju_pmu_situation3_cnt_jtype = %d", bju_pmu_situation3_cnt_jtype);
            $display("bju_pmu_situation4_cnt_jtype = %d", bju_pmu_situation4_cnt_jtype);
            $display("bju_pmu_situation5_cnt_jtype = %d", bju_pmu_situation5_cnt_jtype);
            //$display("correctness of bpu prediction  = %d%%", (correctness_sum*100)/sum);
            $display("prediction correctness rate of bpu jump instr (jal/jalr)  = %0.2f%%", correctness_jtype);
        end
    end


endmodule
