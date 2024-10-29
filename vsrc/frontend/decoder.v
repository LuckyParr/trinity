module decoder (
    input wire clk,
    input wire rst_n,
    input wire fifo_empty,                
    input wire [31:0] fifo_data_out,  
    input [63:0] rs1_regdata,
    input [63:0] rs2_regdata,


    output reg [4:0] rs1,
    output reg [4:0] rs2,
    output reg [4:0] rd,
    output reg [63:0] src1,
    output reg [63:0] src2,
    output reg [63:0] imm,
    output reg  src1_is_reg,
    output reg  src2_is_reg,
    output reg  need_to_wb,
    output reg [5:0] cx_type,
    output reg  is_unsigned,
    output reg [9:0] alu_type,
    output reg  is_word,
    output reg  is_imm,
    output reg  is_load,
    output reg  is_store,
    output reg [3:0] ls_size,
    output reg [12:0] muldiv_type

);

    reg [6:0] opcode;
    reg [2:0] funct3;
    reg [6:0] funct7;

    localparam OPCODE_LUI    = 7'b0110111;
    localparam OPCODE_AUIPC  = 7'b0010111;
    localparam OPCODE_JAL    = 7'b1101111;
    localparam OPCODE_JALR   = 7'b1100111;
    localparam OPCODE_BRANCH = 7'b1100011;
    localparam OPCODE_LOAD   = 7'b0000011;
    localparam OPCODE_SOTRE  = 7'b0100011;
    localparam OPCODE_ALU_ITYPE  = 7'b0010011;
    localparam OPCODE_ALU_RTYPE  = 7'b0110011;
    localparam OPCODE_FENCE  = 7'b0001111;
    localparam OPCODE_ENV    = 7'b1110011;
    localparam OPCODE_ALU_ITYPE_WORD  = 7'b0011011;
    localparam OPCODE_ALU_RTYPE_WORD  = 7'b0111011;

    reg [11:0] imm_itype;
    reg [11:0] imm_stype;
    reg [12:0] imm_btype;
    reg [19:0] imm_utype;
    reg [20:0] imm_jtype;
    reg [63:0] imm_itype_64_s;
    reg [63:0] imm_itype_64_u;
    reg [63:0] imm_stype_64;
    reg [63:0] imm_btype_64_s;
    reg [63:0] imm_btype_64_u;
    reg [63:0] imm_utype_64;
    reg [63:0] imm_jtype_64;


    always@(*)begin
        if(!fifo_empty)begin
            imm_itype = fifo_data_out[31:20];
            imm_stype = {fifo_data_out[31:25],fifo_data_out[11:7]} ;

            imm_btype[11] = fifo_data_out[7];
            imm_btype[4:1] = fifo_data_out[11:8];
            imm_btype[10:5] = fifo_data_out[30:25];
            imm_btype[12] = fifo_data_out[31];
            imm_btype[0] = 1'b0;

            imm_utype = fifo_data_out[31:12];

            imm_jtype[19:12] =  fifo_data_out[19:12];
            imm_jtype[11] =  fifo_data_out[20];
            imm_jtype[10:1] =  fifo_data_out[30:21];
            imm_jtype[20] =  fifo_data_out[31];
            imm_jtype[0] =  1'b0;

            imm_itype_64_s = {52{imm_itype[11]},imm_itype};
            imm_itype_64_u = {52'd0,imm_itype};
            imm_stype_64 = {52{imm_stype[11]},imm_stype};
            imm_btype_64_s = {51{imm_btype[12]},imm_btype};
            imm_btype_64_u = {51'b0,imm_btype};
            imm_utype_64 = {32{imm_utype[20]},imm_utype,12'b0};
            imm_jtype_64 = {43{imm_jtype[20]},imm_jtype};


            rs1 = fifo_data_out[19:15];
            rs2 = fifo_data_out[24:20];
            rd = fifo_data_out[11:7];
            src1 = 64'b0;
            src2 = 64'b0;
            src1_is_reg = 1'b0;
            src2_is_reg = 1'b0;
            need_to_wb = 1'b0;
            cx_type = 6'b0;
            is_unsigned = 1'b0;
            alu_type = 10'b0;
            is_word = 1'b0;
            is_imm = 1'b0;
            is_load = 1'b0;
            is_store = 1'b0;
            ls_size = 4'b0;
            muldiv_type = 12'b0;

            src1 = rs1_regdata;
            src2 = rs2_regdata;

            opcode = fifo_data_out[6:0];
            funct3 = fifo_data_out[14:12];
            funct7 = fifo_data_out[31:25];
            case(opcode)
                OPCODE_LUI   : 
                    imm = imm_utype_64;
                    alu_type = `IS_LUI;
                OPCODE_AUIPC : 
                    imm = imm_utype_64;
                    alu_type = `IS_AUIPC;
               OPCODE_JAL   : 
                    imm = imm_jtype_64;
                    cx_type = `IS_JAL;
                OPCODE_JALR  : 
                    imm = imm_itype_64_s;
                    cx_type = `IS_JALR;
                OPCODE_BRANCH: 
                    case(funct3)
                        000:
                            imm = imm_btype_64_s;
                            cx_type = `IS_BEQ;
                        001:
                            imm = imm_btype_64_s;
                            cx_type = `IS_BNE;
                        100:
                            imm = imm_btype_64_s;
                            cx_type = `IS_BLT;
                        101:
                            imm = imm_btype_64_s;
                            cx_type = `IS_BGE;
                        110:
                            imm = imm_btype_64_u;
                            cx_type = `IS_BLT;
                            is_unsigned = 1'b1;
                        111:
                            imm = imm_btype_64_u;
                            cx_type = `IS_BGE;
                            is_unsigned = 1'b1;
                        endcase
                OPCODE_LOAD  : 
                    is_load = 1'b1;
                    case(funct3)
                        000 ：
                            imm = imm_itype_64_s;
                            ls_size = `IS_B;
                        001 ：
                            imm = imm_itype_64_s;
                            ls_size = `IS_H;
                        010 ：
                            imm = imm_itype_64_s;
                            ls_size = `IS_W;
                        011 :  // RV64I extention
                            imm = imm_itype_64_s;
                            ls_size = `IS_D;                            
                        100 ：
                            imm = imm_itype_64_u;
                            ls_size = `IS_B;
                            is_unsigned = 1'b1;
                        101 ：
                            imm = imm_itype_64_u;
                            ls_size = `IS_H;
                            is_unsigned = 1'b1;
                        110 :  // RV64I extention
                            imm = imm_itype_64_s;
                            is_unsigned = 1'b1;
                            ls_size = `IS_W;
                        endcase
                OPCODE_STORE : 
                    is_store = 1'b1;
                    imm = imm_stype_64;
                    case(funct3)
                        000:
                            ls_size = `IS_B;
                        001:
                            ls_size = `IS_H;
                        010:
                            ls_size = `IS_W;
                        011: // RV64I extention
                            ls_size = `IS_D;
                        endcase
                OPCODE_ALU_ITYPE : 
                            imm = imm_itype_64_s;
                    case({funct7,funct3})
                        ???????000:
                            is_imm = 1'b1;
                            alu_type = `IS_ADD;
                        ???????010:
                            is_imm = 1'b1;
                            alu_type = `IS_SLT;
                        ???????011:
                            is_imm = 1'b1;
                            is_unsigned = 1'b1;
                            alu_type = `IS_SLT;
                        ???????100:
                            is_imm = 1'b1;
                            alu_type = `IS_XOR;
                        ???????110:
                            is_imm = 1'b1;
                            alu_type = `IS_OR;
                        ???????111:
                            is_imm = 1'b1;
                            alu_type = `IS_AND;
                        0000000001:
                            is_imm = 1'b1;
                            alu_type = `IS_SLL;
                        0000000101:
                            is_imm = 1'b1;
                            alu_type = `IS_SRL;
                        0100000101:
                            is_imm = 1'b1;
                            alu_type = `IS_SRA;
                        endcase
                OPCODE_ALU_RTYPE : 
                    case({funct7,funct3})
                        0000000000:
                            alu_type = `IS_ADD;
                        0100000000:
                            alu_type = `IS_SUB;
                        0000000001:
                            alu_type = `IS_SLL;
                        0000000010:
                            alu_type = `IS_SLT;
                        0000000011:
                            is_unsigned = 1'b1;
                            alu_type = `IS_SLT;
                        0000000100:
                            alu_type = `IS_XOR;
                        0000000101:
                            alu_type = `IS_SRL;
                        0100000101:
                            alu_type = `IS_SRA;
                        0000000110:
                            alu_type = `IS_OR;
                        0000000111:
                            alu_type = `IS_AND;
                        endcase
                OPCODE_FENCE : 
                OPCODE_ENV   : 
                OPCODE_ALU_ITYPE_WORD :
                    is_word = 1'b1;
                    case({funct7,funct3})
                    ???????000:
                            is_imm = 1'b1;
                            alu_type = `IS_ADD;
                    0000000001:
                            is_imm = 1'b1;
                            alu_type = `IS_SLL;
                    0000000101:
                            is_imm = 1'b1;
                            alu_type = `IS_SRL;
                    0100000101:
                            is_imm = 1'b1;
                            alu_type = `IS_SRA;  
                    endcase                  
                OPCODE_ALU_RTYPE_WORD :
                    is_word = 1'b1;
                    case({funct7,funct3})
                        0000000000:
                            alu_type = `IS_ADD;
                        0100000000:
                            alu_type = `IS_SUB;                        
                        0000000001:
                            alu_type = `IS_SLL;
                        0000000101:
                            alu_type = `IS_SRL;
                        0100000101:
                            alu_type = `IS_SRA;
                        endcase                            
                default: 64'd0;
            endcase
    end
    end



endmodule
