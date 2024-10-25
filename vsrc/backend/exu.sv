`include "defines.sv"
module exu (
    input wire [    `LREG_RANGE] rs1,
    input wire [    `LREG_RANGE] rs2,
    input wire [    `LREG_RANGE] rd,
    input wire [     `SRC_RANGE] src1,
    input wire [     `SRC_RANGE] src2,
    input wire [     `SRC_RANGE] offset,
    input wire                   src1_is_reg,
    input wire                   src2_is_reg,
    input wire                   need_to_wb,
    // input wire is_jump,
    // input wire is_br,
    //sig below is control transfer(xfer) type
    input wire [ `CX_TYPE_RANGE] cx_type,
    input wire [`ALU_TYPE_RANGE] alu_type,
    input wire [`MULDIV_TYPE_RANGE] muldiv_type,
    input wire                   is_load,
    input wire                   is_store,
    input wire [            3:0] size,
    input wire [      `PC_RANGE] pc,
    input wire [   `INSTR_RANGE] instr

);

    agu u_agu(
        .src1       (src1       ),
        .offset     (offset     ),
        .ls_address (ls_address )
    );
    
    alu u_alu(
        .src1     (src1     ),
        .src2     (src2     ),
        .valid    (valid    ),
        .alu_type (alu_type ),
        .result   (result   )
    );
    
    bju u_bju(
        .src1            (src1            ),
        .src2            (src2            ),
        .offset          (offset          ),
        .pc              (pc              ),
        .cx_type         (cx_type         ),
        .valid           (valid           ),
        .dest            (dest            ),
        .redirect_valid  (redirect_valid  ),
        .redirect_target (redirect_target )
    );
    
    muldiv u_muldiv(
        .src1        (src1        ),
        .src2        (src2        ),
        .valid       (valid       ),
        .muldiv_type (muldiv_type ),
        .result      (result      )
    );
    
endmodule
