`include "defines.sv"
module alu (
    input wire [`LREG_RANGE] src1,
    input wire [`LREG_RANGE] src2,
    input wire valid,
    input  wire [`ALU_TYPE_RANGE] alu_type,
    output wire [     `SRC_RANGE] result
);
    /*
    0 = ADD
    1 = SET LESS THAN
    2 = SET LESS THEN UNSIGNED
    3 = XOR
    4 = OR
    5 = AND
    6 = SHIFT LEFT LOGICAL
    7 = SHIFT RIGHT LOGICAL
    8 = SHIFT RIGHT ARH
    9 = SUB
*/
    wire is_add = alu_type[0];
    wire is_set_lt = alu_type[1];
    wire is_set_ltu = alu_type[2];
    wire is_xor = alu_type[3];
    wire is_or = alu_type[4];
    wire is_and = alu_type[5];
    wire is_sll = alu_type[6];
    wire is_srl = alu_type[7];
    wire is_sra = alu_type[8];
    wire is_sub = alu_type[9];

    // wire 
    wire [`SRC_RANGE] src2_qual = is_sub ? ~src2 + 64'b1 : src2;
    wire [`SRC_RANGE] add_sub_result =  src1 + src2_qual;

    reg is_less ;
    wire is_lessu = src1 < src2_qual ;

    reg 
    always @(*) begin
        case(src1[`SRC_WIDTH-1], src2_qual[`SRC_WIDTH-1]) 
            2'b00: is_less = src1[`SRC_WIDTH-2:0 ] < src2_qual[`SRC_WIDTH-2:0 ];
            2'b01: is_less = 1'b0;
            2'b10: is_less = 1'b1;
            2'b11: is_less = src1[`SRC_WIDTH-2:0 ] < src2_qual[`SRC_WIDTH-2:0 ];
        endcase
    end

    wire [`SRC_RANGE] xor_result = src1 ^ src2_qual;
    wire [`SRC_RANGE] or_result = src1 | src2_qual;
    wire [`SRC_RANGE] and_result = src1 & src2_qual;

    wire [`SRC_RANGE] sll_result = src1 << src2_qual[5:0];
    wire [`SRC_RANGE] srl_result = src1 >> src2_qual[5:0];
    wire [`SRC_RANGE] sra_result = src1 >>> src2_qual[5:0];
    
    assign result[`RESULT_RANGE] = (is_set_lt ? {63'b0, is_less} :
                    is_set_ltu ? {63'b0, is_lessu} :
                    is_add | is_sub ? add_sub_result :
                    is_xor ? xor_result :
                    is_or ? or_result :
                    is_and ? and_result :
                    is_sll ? sll_result :
                    is_srl ? srl_result :
                    is_sra ? sra_result) & {64{valid}} ;
endmodule
