
module DifftestRunaheadRedirectEvent(
  input         clock,
  input         enable,
  input         io_valid,
  input  [63:0] io_pc,
  input  [63:0] io_target_pc,
  input  [63:0] io_checkpoint_id,
  input  [ 7:0] io_coreid
);
`ifndef SYNTHESIS
`ifdef DIFFTEST

import "DPI-C" function void v_difftest_RunaheadRedirectEvent (
  input   longint io_pc,
  input   longint io_target_pc,
  input   longint io_checkpoint_id,
  input      byte io_coreid
);


  always @(posedge clock) begin
    if (enable)
      v_difftest_RunaheadRedirectEvent (io_pc, io_target_pc, io_checkpoint_id, io_coreid);
  end
`endif
`endif
endmodule
