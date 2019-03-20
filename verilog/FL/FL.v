module FL (
  input  logic                                    clock,               // system clock
  input  logic                                    reset,               // system reset
  input  logic                                    dispatch_en,
  input  logic                                    rollback_en,
  input  logic                                    retire_en,
  input  logic [$clog2(`NUM_PR)-1:0]              T_old_idx,
  input  logic [$clog2(`NUM_FL)-1:0]              FL_rollback_idx,
  input  logic [4:0]                              dest_idx,
`ifndef SYNTH_TEST
  output logic [`NUM_FL-1:0][$clog2(`NUM_PR)-1:0] FL_table, next_FL_table,
  output logic [$clog2(`NUM_FL)-1:0]              head, next_head,
  output logic [$clog2(`NUM_FL)-1:0]              tail, next_tail,
`endif
  output logic                                    FL_valid,
  output logic [$clog2(`NUM_PR)-1:0]              T_idx,
  output logic [$clog2(`NUM_FL)-1:0]              FL_idx
);

`ifdef SYNTH_TEST
  logic [$clog2(`NUM_FL)-1:0]              head, next_head;
  logic [$clog2(`NUM_FL)-1:0]              tail, next_tail;
  logic [`NUM_FL-1:0][$clog2(`NUM_PR)-1:0] FL_table, next_FL_table;
`endif
  logic [$clog2(`NUM_FL)-1:0]              virtual_tail;
  logic                                    move_head;

  assign move_head    = retire_en && T_old_idx != `ZERO_PR;
  assign next_head    = move_head ? (head + 1) : head;
  assign virtual_tail = dest_idx == `ZERO_REG ? tail : tail + 1;
  assign next_tail    = rollback_en ? FL_rollback_idx :
                        dispatch_en ? virtual_tail    : tail;
  assign FL_idx       = next_tail;
  assign T_idx        = dest_idx == `ZERO_REG ? `ZERO_PR  :
                        next_tail == head     ? T_old_idx : FL_table[head];
  assign FL_valid     = virtual_tail != next_head;

  always_comb begin
    next_FL_table = FL_table;
    next_FL_table[head] = move_head ? T_old_idx : FL_table[head];
  end

  always_ff @(posedge clock) begin
    if ( reset ) begin
      head <= `SD 0;
      tail <= `SD 0;
      for (int i = 0; i < `NUM_FL; i++) begin
        FL_table[i] <= `SD i + 32;
      end
    end else begin
      head     <= `SD next_head;
      tail     <= `SD next_tail;
      FL_table <= `SD next_FL_table;
    end
  end

endmodule