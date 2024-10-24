
module DifftestRunaheadEvent(
  input         clock,
  input         enable,
  input         io_valid,
  input         io_branch,
  input         io_may_replay,
  input  [63:0] io_pc,
  input  [63:0] io_checkpoint_id,
  input  [ 7:0] io_coreid,
  input  [ 7:0] io_index
);
`ifndef SYNTHESIS
`ifdef DIFFTEST

import "DPI-C" function void v_difftest_RunaheadEvent (
  input       bit io_branch,
  input       bit io_may_replay,
  input   longint io_pc,
  input   longint io_checkpoint_id,
  input      byte io_coreid,
  input      byte io_index
);


  always @(posedge clock) begin
    if (enable)
      v_difftest_RunaheadEvent (io_branch, io_may_replay, io_pc, io_checkpoint_id, io_coreid, io_index);
  end
`endif
`endif
endmodule
