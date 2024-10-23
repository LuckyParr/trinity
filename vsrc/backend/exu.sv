`include "deinfes.sv"
module exu (
    input wire [`LR_RANGE] rs1,
    input wire [`LR_RANGE] rs2,
    input wire [`LR_RANGE] rd,
    input wire [`SRC_RANGE] src1,
    input wire [`SRC_RANGE] src2,
    input wire src1_is_reg,
    input wire src2_is_reg,
    input wire need_to_wb,
    input wire is_jump,
    input wire is_br,
    //sig below is br type(need to add jump type?)
    input wire [3:0] br_type,
    input wire is_load,
    input wire is_store,
    input wire [3:0] size,
    


);
    
endmodule