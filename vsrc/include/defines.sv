`define LREG_RANGE 4:0
`define SRC_RANGE 63:0
`define SRC_WIDTH 64

`define RESULT_RANGE 63:0
`define RESULT_WIDTH 64
`define ALU_TYPE_RANGE 9:0
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
`define ALU_TYPE_WIDTH 10
`define PC_RANGE 47:0
`define PC_WIDTH 48
`define INSTR_RANGE 31:0
`define CX_TYPE_RANGE 7:0
/*
    0 = JAL
    1 = JALR
    2 = BEQ
    3 = BNE
    4 = BLT
    5 = BGE
    6 = BLTU
    7 = BGEU
*/

`define MULDIV_TYPE_RANGE 12:0
/*
    0 = MUL
    1 = MULH
    2 = MULHSU
    3 = MULHU
    4 = DIV
    5 = DIVU
    6 = REM
    7 = REMU
    8 = MULW
    9 = DIVW
    10 = DIVUW
    11 = REMW
    12 = REMUW
*/