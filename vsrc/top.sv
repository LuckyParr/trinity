module top #(
) (
    input  wire        clk,
    input  wire        rst_n,
    output wire [31:0] opt
);


  wire chip_enable = 1'b1;

  simddr u_simddr (
      .clk                   (clk),
      .rst_n                 (rst_n),
      .ddr_chip_enable       (ddr_chip_enable),
      .ddr_index             (ddr_index),
      .ddr_write_enable      (ddr_write_enable),
      .ddr_burst_mode        (ddr_burst_mode),
      .ddr_opstore_write_mask(ddr_opstore_write_mask),
      .ddr_opstore_write_data(ddr_opstore_write_data),
      .ddr_opload_read_data  (ddr_opload_read_data),
      .ddr_pc_read_inst      (ddr_pc_read_inst),
      .ddr_l2_write_data     (ddr_l2_write_data),
      .ddr_operation_done    (ddr_operation_done),
      .ddr_ready             (ddr_ready)
  );



  backend u_backend (
      .clock      (clk),
      .rst_n      (rst_n),
      .rs1        (rs1),
      .rs2        (rs2),
      .rd         (rd),
      .src1       (src1),
      .src2       (src2),
      .imm        (imm),
      .src1_is_reg(src1_is_reg),
      .src2_is_reg(src2_is_reg),
      .need_to_wb (need_to_wb),
      .cx_type    (cx_type),
      .is_unsigned(is_unsigned),
      .alu_type   (alu_type),
      .is_word    (is_word),
      .is_load    (is_load),
      .is_imm     (is_imm),
      .is_store   (is_store),
      .ls_size    (ls_size),
      .muldiv_type(muldiv_type),
      .pc         (pc),
      .instr      (instr),
      .wb_valid   (wb_valid),
      .wb_data    (wb_data)
  );

endmodule
