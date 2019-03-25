module FL (
  input  logic                                              clock,               // system clock
  input  logic                                              reset,               // system reset
  input  logic                                              dispatch_en,
  input  logic                                              rollback_en,
  input  logic                                              retire_en,
  input  logic           [$clog2(`NUM_FL)-1:0]              FL_rollback_idx,
  input  DECODER_FL_OUT_t                                   decoder_FL_out,
  input  ROB_FL_OUT_t                                       ROB_FL_out,
`ifndef SYNTH_TEST
  output logic           [`NUM_FL-1:0][$clog2(`NUM_PR)-1:0] FL_table, next_FL_table,
  output logic           [$clog2(`NUM_FL)-1:0]              head, next_head,
  output logic           [$clog2(`NUM_FL)-1:0]              tail, next_tail,
`endif
  output logic                                              FL_valid,
  output FL_ROB_OUT_t                                       FL_ROB_out,
  output FL_RS_OUT_t                                        FL_RS_out,
  output FL_MAP_TABLE_OUT_t                                 FL_Map_Table_out
);

`ifdef SYNTH_TEST
  logic [$clog2(`NUM_FL)-1:0]              head, next_head;
  logic [$clog2(`NUM_FL)-1:0]              tail, next_tail;
  logic [`NUM_FL-1:0][$clog2(`NUM_PR)-1:0] FL_table, next_FL_table;
`endif
  logic [$clog2(`NUM_FL)-1:0]              virtual_tail;
  logic                                    move_head;
  logic [$clog2(`NUM_PR)-1:0]              T_idx;
  logic [$clog2(`NUM_FL)-1:0]              FL_idx;

  assign FL_ROB_out       = '{T_idx};
  assign FL_RS_out        = '{T_idx, FL_idx};
  assign FL_Map_Table_out = '{T_idx};

  assign move_head    = retire_en && ROB_FL_out.Told_idx != `ZERO_PR;
  assign next_head    = move_head ? (head + 1) : head;
  assign virtual_tail = decoder_FL_out.dest_idx == `ZERO_REG ? tail : tail + 1;
  assign next_tail    = rollback_en ? FL_rollback_idx :
                        dispatch_en ? virtual_tail    : tail;
  assign FL_idx       = next_tail;
  assign T_idx        = decoder_FL_out.dest_idx == `ZERO_REG ? `ZERO_PR :
                        next_tail == head                    ? ROB_FL_out.Told_idx : FL_table[tail];
  assign FL_valid     = decoder_FL_out.dest_idx == `ZERO_REG || virtual_tail != next_head;

  always_comb begin
    next_FL_table = FL_table;
    next_FL_table[head] = move_head ? ROB_FL_out.Told_idx : FL_table[head];
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
