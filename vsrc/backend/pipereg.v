`include "defines.sv"
module pipereg (
    input wire               clock,
    input wire               reset_n,
    input wire               stall,
    input wire [`LREG_RANGE] rs1,
    input wire [`LREG_RANGE] rs2,
    input wire [`LREG_RANGE] rd,
    input wire [ `SRC_RANGE] src1,
    input wire [ `SRC_RANGE] src2,
    input wire [ `SRC_RANGE] imm,
    input wire               src1_is_reg,
    input wire               src2_is_reg,
    input wire               need_to_wb,

    //sig below is control transfer(xfer) type
    input wire [    `CX_TYPE_RANGE] cx_type,
    input wire                      is_unsigned,
    input wire [   `ALU_TYPE_RANGE] alu_type,
    input wire                      is_word,
    input wire                      is_load,
    input wire                      is_imm,
    input wire                      is_store,
    input wire [               3:0] ls_size,
    input wire [`MULDIV_TYPE_RANGE] muldiv_type,
    input wire                      instr_valid,
    input wire                      predict_taken,
    input wire [31:0]               predict_target,
    input wire [         `PC_RANGE] pc,
    input wire [      `INSTR_RANGE] instr,

    //note: sig below is emerge from exu
    input wire [`RESULT_RANGE] ls_address,
    input wire [`RESULT_RANGE] alu_result,
    input wire [`RESULT_RANGE] bju_result,
    input wire [`RESULT_RANGE] muldiv_result,

    //note: dont not to fill until mem stage done
    input wire [`RESULT_RANGE] opload_read_data_wb,
    //flush
    input redirect_flush,
    // outputs
    output reg [`LREG_RANGE] out_rs1,
    output reg [`LREG_RANGE] out_rs2,
    output reg [`LREG_RANGE] out_rd,
    output reg [ `SRC_RANGE] out_src1,
    output reg [ `SRC_RANGE] out_src2,
    output reg [ `SRC_RANGE] out_imm,
    output reg               out_src1_is_reg,
    output reg               out_src2_is_reg,
    output reg               out_need_to_wb,


    output reg [    `CX_TYPE_RANGE] out_cx_type,
    output reg                      out_is_unsigned,
    output reg [   `ALU_TYPE_RANGE] out_alu_type,
    output reg                      out_is_word,
    output reg                      out_is_load,
    output reg                      out_is_imm,
    output reg                      out_is_store,
    output reg [               3:0] out_ls_size,
    output reg [`MULDIV_TYPE_RANGE] out_muldiv_type,
    output reg                      out_instr_valid,
    output reg                      out_predict_taken,
    output reg [31:0]               out_predict_target,
    output reg [         `PC_RANGE] out_pc,
    output reg [      `INSTR_RANGE] out_instr,


    output reg [`RESULT_RANGE] out_ls_address,
    output reg [`RESULT_RANGE] out_alu_result,
    output reg [`RESULT_RANGE] out_bju_result,
    output reg [`RESULT_RANGE] out_muldiv_result,
    output reg [`RESULT_RANGE] out_opload_read_data_wb,
    // BHT Write Interface
    input wire bht_write_enable,                 // Write enable for BHT
    input wire [8:0] bht_write_index,            // Set index for BHT write operation
    input wire [1:0] bht_write_counter_select,   // Counter select within the BHT set (0 to 3)
    input wire bht_write_inc,                    // Increment signal for BHT counter
    input wire bht_write_dec,                    // Decrement signal for BHT counter
    input wire bht_valid_in,                     // Valid bit for BHT write operation
    // BTB Write Interface
    input wire          btb_ce         ,
    input wire          btb_we         ,                 // Write enable for BTB
    input wire [128: 0] btb_wmask      ,
    input wire [8:0]    btb_write_index,            // Set index for BTB write operation
    input wire [128: 0] btb_din        ,
    // BHT Write Interface
    output wire       out_bht_write_enable        ,                 // Write enable for BHT
    output wire [8:0] out_bht_write_index         ,            // Set index for BHT write operation
    output wire [1:0] out_bht_write_counter_select,   // Counter select within the BHT set (0 to 3)
    output wire       out_bht_write_inc           ,                    // Increment signal for BHT counter
    output wire       out_bht_write_dec           ,                    // Decrement signal for BHT counter
    output wire       out_bht_valid_in            ,                     // Valid bit for BHT write operation

    // BTB Write Interface
    output wire         out_btb_ce         ,
    output wire         out_btb_we         ,                 // Write enable for BTB
    output wire         out_btb_wmask      ,
    output wire [8:0]   out_btb_write_index,            // Set index for BTB write operation
    output wire [128:0] out_btb_din        
);

    always @(posedge clock or negedge reset_n) begin
        if (~reset_n || redirect_flush & ~stall) begin
            out_instr_valid         <= 'b0;
            out_rs1                 <= 'b0;
            out_rs2                 <= 'b0;
            out_rd                  <= 'b0;
            out_src1                <= 'b0;
            out_src2                <= 'b0;
            out_imm                 <= 'b0;
            out_src1_is_reg         <= 'b0;
            out_src2_is_reg         <= 'b0;
            out_need_to_wb          <= 'b0;

            out_cx_type             <= 'b0;
            out_is_unsigned         <= 'b0;
            out_alu_type            <= 'b0;
            out_is_word             <= 'b0;
            out_is_load             <= 'b0;
            out_is_imm              <= 'b0;
            out_is_store            <= 'b0;
            out_ls_size             <= 'b0;
            out_muldiv_type         <= 'b0;
            out_predict_taken       <= 'b0;
            out_predict_target      <= 'b0;
            out_pc                  <= 'b0;
            out_instr               <= 'b0;

            out_ls_address          <= 'b0;
            out_alu_result          <= 'b0;
            out_bju_result          <= 'b0;
            out_muldiv_result       <= 'b0;
            out_opload_read_data_wb <= 'b0;

            out_bht_write_enable         <= 'b0;        
            out_bht_write_index          <= 'b0;         
            out_bht_write_counter_select <= 'b0;
            out_bht_write_inc            <= 'b0;           
            out_bht_write_dec            <= 'b0;           
            out_bht_valid_in             <= 'b0;            
            out_btb_ce                   <= 'b0;         
            out_btb_we                   <= 'b0;         
            out_btb_wmask                <= 'b0;      
            out_btb_write_index          <= 'b0;
            out_btb_din                  <= 'b0;                    
        end else if (stall) begin
            out_instr_valid               <= out_instr_valid              ;
            out_rs1                       <= out_rs1                      ;
            out_rs2                       <= out_rs2                      ;
            out_rd                        <= out_rd                       ;
            out_src1                      <= out_src1                     ;
            out_src2                      <= out_src2                     ;
            out_imm                       <= out_imm                      ;
            out_src1_is_reg               <= out_src1_is_reg              ;
            out_src2_is_reg               <= out_src2_is_reg              ;
            out_need_to_wb                <= out_need_to_wb               ;
            out_cx_type                   <= out_cx_type                  ;
            out_is_unsigned               <= out_is_unsigned              ;
            out_alu_type                  <= out_alu_type                 ;
            out_is_word                   <= out_is_word                  ;
            out_is_load                   <= out_is_load                  ;
            out_is_imm                    <= out_is_imm                   ;
            out_is_store                  <= out_is_store                 ;
            out_ls_size                   <= out_ls_size                  ;
            out_muldiv_type               <= out_muldiv_type              ;
            out_predict_taken             <= out_predict_taken            ;
            out_predict_target            <= out_predict_target           ;
            out_pc                        <= out_pc                       ;
            out_instr                     <= out_instr                    ;
            out_ls_address                <= out_ls_address               ;
            out_alu_result                <= out_alu_result               ;
            out_bju_result                <= out_bju_result               ;
            out_muldiv_result             <= out_muldiv_result            ;
            out_opload_read_data_wb       <= out_opload_read_data_wb      ;
            
            out_bht_write_enable          <= out_bht_write_enable         ;         
            out_bht_write_index           <= out_bht_write_index          ;          
            out_bht_write_counter_select  <= out_bht_write_counter_select ; 
            out_bht_write_inc             <= out_bht_write_inc            ;            
            out_bht_write_dec             <= out_bht_write_dec            ;            
            out_bht_valid_in              <= out_bht_valid_in             ;             
            out_btb_ce                    <= out_btb_ce                   ;                   
            out_btb_we                    <= out_btb_we                   ;                   
            out_btb_wmask                 <= out_btb_wmask                ;                
            out_btb_write_index           <= out_btb_write_index          ;          
            out_btb_din                   <= out_btb_din                  ;                              
        end else begin
            out_instr_valid               <= instr_valid;
            out_rs1                       <= rs1;
            out_rs2                       <= rs2;
            out_rd                        <= rd;
            out_src1                      <= src1;
            out_src2                      <= src2;
            out_imm                       <= imm;
            out_src1_is_reg               <= src1_is_reg;
            out_src2_is_reg               <= src2_is_reg;
            out_need_to_wb                <= need_to_wb;

            out_cx_type             <= cx_type;
            out_is_unsigned         <= is_unsigned;
            out_alu_type            <= alu_type;
            out_is_word             <= is_word;
            out_is_load             <= is_load;
            out_is_imm              <= is_imm;
            out_is_store            <= is_store;
            out_ls_size             <= ls_size;
            out_muldiv_type         <= muldiv_type;
            out_predict_taken       <= predict_taken ;
            out_predict_target      <= predict_target ;
            out_pc                  <= pc;
            out_instr               <= instr;

            out_ls_address          <= ls_address;
            out_alu_result          <= alu_result;
            out_bju_result          <= bju_result;
            out_muldiv_result       <= muldiv_result;
            out_opload_read_data_wb <= opload_read_data_wb;

            out_bht_write_enable         <= bht_write_enable ;          
            out_bht_write_index          <= bht_write_index ;           
            out_bht_write_counter_select <= bht_write_counter_select ;  
            out_bht_write_inc            <= bht_write_inc ;             
            out_bht_write_dec            <= bht_write_dec ;             
            out_bht_valid_in             <= bht_valid_in ;              
            out_btb_ce                   <= btb_ce ;                    
            out_btb_we                   <= btb_we ;                    
            out_btb_wmask                <= btb_wmask ;                 
            out_btb_write_index          <= btb_write_index ;           
            out_btb_din                  <= btb_din ;                   

        end
    end
endmodule
