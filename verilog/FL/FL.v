module FL (
  input  logic                        clock,               // system clock
  input  logic                        reset,               // system reset
  input  logic                        dispatch_en,
  input  logic                        rollback_en,
  input  logic                        retire_en,
  input  logic [$clog2(`NUM_ROB)-1:0] T_old_idx,
  input  logic [$clog2(`NUM_FL)-1:0]  FL_rollback_idx,
  output logic                        FL_valid,
  output logic [$clog2(`NUM_ROB)-1:0] T_idx,
  output logic [$clog2(`NUM_FL)-1:0]  FL_idx
);

  logic [$clog2(`NUM_FL)-1:0] head;
  logic [$clog2(`NUM_FL)-1:0] tail;

endmodule