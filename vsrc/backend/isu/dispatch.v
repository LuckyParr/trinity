module dispatch#()
(
    input  wire               clock,
    input  wire               reset_n,
    /* --------------------------- from rename instr0 --------------------------- */
    input  wire               instr0_valid,
    output wire               disp2rn_instr0_ready,
    //data to rob
    input  wire [  `PC_RANGE] instr0_pc,
    input  wire [       31:0] instr0,
    input  wire [`LREG_RANGE] instr0_lrs1,
    input  wire [`LREG_RANGE] instr0_lrs2,
    input  wire [`LREG_RANGE] instr0_lrd,
    input wire  [`PREG_RANGE] instr0_prd,
    input wire  [`PREG_RANGE] instr0_old_prd,
    input wire                instr0_need_to_wb,
    //remain info go to issue queue alone with above signals
    input wire [`PREG_RANGE]        instr0_prs1,
    input wire [`PREG_RANGE]        instr0_prs2,
    input wire                      instr0_src1_is_reg,
    input wire                      instr0_src2_is_reg,
    input wire [              63:0] instr0_imm,
    input wire [    `CX_TYPE_RANGE] instr0_cx_type,
    input wire                      instr0_is_unsigned,
    input wire [   `ALU_TYPE_RANGE] instr0_alu_type,
    input wire [`MULDIV_TYPE_RANGE] instr0_muldiv_type,
    input wire                      instr0_is_word,
    input wire                      instr0_is_imm,
    input wire                      instr0_is_load,
    input wire                      instr0_is_store,
    input wire [               3:0] instr0_ls_size,


    /* --------------------------- from rename instr1 --------------------------- */
    input  wire               instr1_valid,
    output wire               instr1_ready,
    //data to rob
    input  wire [  `PC_RANGE] instr1_pc,
    input  wire [       31:0] instr1,
    input  wire [`LREG_RANGE] instr1_lrs1,
    input  wire [`LREG_RANGE] instr1_lrs2,
    input  wire [`LREG_RANGE] instr1_lrd,
    input wire  [`PREG_RANGE] instr1_prd,
    input wire  [`PREG_RANGE] instr1_old_prd,
    input wire                instr1_need_to_wb,

    input wire [`PREG_RANGE] instr1_prs1,
    input wire [`PREG_RANGE] instr1_prs2,
    input wire                      instr1_src1_is_reg,
    input wire                      instr1_src2_is_reg,
    input wire [              63:0] instr1_imm,
    input wire [    `CX_TYPE_RANGE] instr1_cx_type,
    input wire                      instr1_is_unsigned,
    input wire [   `ALU_TYPE_RANGE] instr1_alu_type,
    input wire [`MULDIV_TYPE_RANGE] instr1_muldiv_type,
    input wire                      instr1_is_word,
    input wire                      instr1_is_imm,
    input wire                      instr1_is_load,
    input wire                      instr1_is_store,
    input wire [               3:0] instr1_ls_size,


    // signal from rob
    input wire [INDEX_WIDTH-1:0] rob2disp_instr_cnt, //7 bit
    input wire [INDEX_WIDTH-1:0] rob2disp_instr_id, //7 bit

    //write rob
    output wire disp2rob_wren0,
    output wire [124-1:0] disp2rob_wrdata0,
    output wire disp2rob_wren1
    output wire [124-1:0] disp2rob_wrdata1,

    // read from busy_vector
    // Read Port 0
    output wire [5:0] disp2bt_instr0rs1_rdaddr, // Address for disp2bt_instr0rs1_busy
    input wire bt2disp_instr0rs1_busy,      // Data output for disp2bt_instr0rs1_busy
    // Read Port 1
    output wire [5:0] disp2bt_instr0rs2_rdaddr, // Address for disp2bt_instr0rs2_busy
    input wire bt2disp_instr0rs2_busy,      // Data output for disp2bt_instr0rs2_busy
    // Read Port 2
    output wire [5:0] disp2bt_instr1rs1_rdaddr, // Address for disp2bt_instr1rs1_busy
    input wire bt2disp_instr1rs1_busy,      // Data output for disp2bt_instr1rs1_busy
    // Read Port 3
    output wire [5:0] disp2bt_instr1rs2_rdaddr, // Address for disp2bt_instr1rs2_busy
    input wire bt2disp_instr1rs2_busy,      // Data output for disp2bt_instr1rs2_busy
    
    // write busy bit to 1 in busy_vector
    // Write Port 0 - Allocate Instruction 0
    output wire alloc_instr0rd_en0,             // Enable for alloc_instr0rd_addr0
    output wire [5:0] alloc_instr0rd_addr0,     // Address for alloc_instr0rd_addr0
    // Write Port 1 - Allocate Instruction 1
    output wire alloc_instr1rd_en1,             // Enable for alloc_instr1rd_addr1
    output wire [5:0] alloc_instr1rd_addr1,     // Address for alloc_instr1rd_addr1

    //write data to issue_queue
    output wire disp2isq_wren0,
    output wire [231-1:0]disp2isq_wrdata0

);

/* --------------------- write instr0 and instr1 to rob --------------------- */
assign disp2rob_wren0 = instr0_valid;
assign disp2rob_wrdata0 = {instr0_pc,instr0,instr0_lrs1,instr0_lrs2,instr0_lrd,instr0_prd,instr0_old_prd,instr0_need_to_wb};

assign disp2rob_wren1 = instr1_valid;
assign disp2rob_wrdata1 = {instr1_pc,instr1,instr1_lrs1,instr1_lrs2,instr1_lrd,instr1_prd,instr1_old_prd,instr1_need_to_wb};

/* ------------ write prd0 and prd1 busy bit to 1 in busy_vector ------------ */
assign alloc_instr0rd_en0 = instr0_need_to_wb;
assign alloc_instr0rd_addr0 = instr0_prd;
assign alloc_instr1rd_en1 = instr1_need_to_wb
assign alloc_instr1rd_addr1 = instr1_prd;

/* ------- read instr0 and instr1 rs1 rs2 busy status from busy_vector ------ */
assign disp2bt_instr0rs1_rdaddr = instr0_prs1; //use to set sleep bit in issue queue
assign disp2bt_instr0rs2_rdaddr = instr0_prs2; //use to set sleep bit in issue queue
assign disp2bt_instr1rs1_rdaddr = instr1_prs1; //use to set sleep bit in issue queue
assign disp2bt_instr1rs2_rdaddr = instr1_prs2; //use to set sleep bit in issue queue


/* ------------- send instr0 instr1 and sleep bit to issue queue ------------ */
assign disp2isq_wren0 = instr0_valid;
assign disp2isq_wrdata0 = 
                        {
                        rob2disp_instr_id ,//7   //[247 : 241]
                        instr0_pc         ,//64  //[240 : 177]         
                        instr0            ,//32  //[176 : 145]         
                        instr0_lrs1       ,//5   //[144 : 140]         
                        instr0_lrs2       ,//5   //[139 : 135]         
                        instr0_lrd        ,//5   //[134 : 130]         
                        instr0_prd        ,//6   //[129 : 124]         
                        instr0_old_prd    ,//6   //[123 : 118]         
                        instr0_need_to_wb ,//1   //[117 : 117]         
                        instr0_prs1       ,//6   //[116 : 111]         
                        instr0_prs2       ,//6   //[110 : 105]         
                        instr0_src1_is_reg,//1   //[104 : 104]         
                        instr0_src2_is_reg,//1   //[103 : 103]         
                        instr0_imm        ,//64  //[102 : 39 ]         
                        instr0_cx_type    ,//6   //[38  : 33 ]         
                        instr0_is_unsigned,//1   //[32  : 32 ]         
                        instr0_alu_type   ,//11  //[31  : 21 ]         
                        instr0_muldiv_type,//13  //[20  : 8  ]         
                        instr0_is_word    ,//1   //[7   : 7  ]         
                        instr0_is_imm     ,//1   //[6   : 6  ]         
                        instr0_is_load    ,//1   //[5   : 5  ]         
                        instr0_is_store   ,//1   //[4   : 4  ]         
                        instr0_ls_size     //4   //[3   : 0  ]         
                        };
//total:248 bit

      
     
     
     
     
     
     
     
     
     
     
     
    
    
    
    
   
   
   
   
   
   





endmodule