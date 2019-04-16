`timescale 1ns/100ps

module FL (
  input  logic                                                    clock,               // system clock
  input  logic                                                    reset,               // system reset
  input  logic                                                    dispatch_en,
  input  logic                                                    rollback_en,
  input  logic              [`NUM_SUPER-1:0]                      retire_en,
  input  logic              [$clog2(`NUM_FL)-1:0]                 FL_rollback_idx,
  input  DECODER_FL_OUT_t                                         decoder_FL_out,
  input  ROB_FL_OUT_t                                             ROB_FL_out,
`ifdef DEBUG
  output logic              [`NUM_FL-1:0][$clog2(`NUM_PR)-1:0]    FL_table, next_FL_table,
  output logic              [$clog2(`NUM_FL)-1:0]                 head, next_head,
  output logic              [$clog2(`NUM_FL)-1:0]                 tail, next_tail,
`endif
  output logic                                                    FL_valid,
  output logic              [`NUM_SUPER-1:0][$clog2(`NUM_FL)-1:0] FL_idx,
  output FL_ROB_OUT_t                                             FL_ROB_out,
  output FL_RS_OUT_t                                              FL_RS_out,
  output FL_MAP_TABLE_OUT_t                                       FL_Map_Table_out
);

`ifndef DEBUG
  logic [$clog2(`NUM_FL)-1:0]                 head, next_head;
  logic [$clog2(`NUM_FL)-1:0]                 tail, next_tail;
  logic [`NUM_FL-1:0][$clog2(`NUM_PR)-1:0]    FL_table, next_FL_table;
`endif
  logic [$clog2(`NUM_FL)-1:0]                 head_plus_one, head_plus_two;
  logic [$clog2(`NUM_FL)-1:0]                 tail_plus_one, tail_plus_two;
  logic [$clog2(`NUM_FL)-1:0]                 virtual_tail;
  logic [`NUM_SUPER-1:0]                      move_head;
  logic [`NUM_SUPER-1:0][$clog2(`NUM_PR)-1:0] T_idx;
  logic                                       head1, head2;

  assign FL_ROB_out       = '{T_idx};
  assign FL_RS_out        = '{T_idx};
  assign FL_Map_Table_out = '{T_idx};
  assign next_head       = head + head1 + head2;
  assign next_tail       = rollback_en ? FL_rollback_idx :
                           dispatch_en ? virtual_tail    : tail;
  assign tail_plus_one   = tail + 1;
  assign tail_plus_two   = tail + 2;
  assign head_plus_one   = head + 1;
  assign head_plus_two   = head + 2;

  always_comb begin
    if (decoder_FL_out.dest_idx[0] != `ZERO_REG && decoder_FL_out.dest_idx[1] != `ZERO_REG) begin
      virtual_tail = tail_plus_two;
      FL_valid     = tail_plus_two != head;
    end else if (decoder_FL_out.dest_idx[0] != `ZERO_REG && decoder_FL_out.dest_idx[1] == `ZERO_REG) begin
      virtual_tail = tail_plus_one;
      FL_valid     = tail_plus_one != head;
    end else if (decoder_FL_out.dest_idx[0] == `ZERO_REG && decoder_FL_out.dest_idx[1] != `ZERO_REG) begin
      virtual_tail = tail_plus_one;
      FL_valid     = tail_plus_one != head;
    end else begin
      virtual_tail = tail;
      FL_valid     = `TRUE;
    end
  end

  always_comb begin
    if (decoder_FL_out.dest_idx[0] != `ZERO_REG && decoder_FL_out.dest_idx[1] != `ZERO_REG) begin
      T_idx = '{FL_table[tail_plus_one], FL_table[tail]};
    end else if (decoder_FL_out.dest_idx[0] != `ZERO_REG && decoder_FL_out.dest_idx[1] == `ZERO_REG) begin
      T_idx = '{`ZERO_PR_UNPACKED, FL_table[tail]};
    end else if (decoder_FL_out.dest_idx[0] == `ZERO_REG && decoder_FL_out.dest_idx[1] != `ZERO_REG) begin
      T_idx = '{FL_table[tail], `ZERO_PR_UNPACKED};
    end else begin
      T_idx = '{`ZERO_PR_UNPACKED, `ZERO_PR_UNPACKED};
    end
  end

  always_comb begin
    if (decoder_FL_out.dest_idx[0] != `ZERO_REG && decoder_FL_out.dest_idx[1] != `ZERO_REG) begin
      FL_idx = '{tail_plus_two, tail_plus_one};
    end else if (decoder_FL_out.dest_idx[0] != `ZERO_REG && decoder_FL_out.dest_idx[1] == `ZERO_REG) begin
      FL_idx = '{tail_plus_one, tail_plus_one};
    end else if (decoder_FL_out.dest_idx[0] == `ZERO_REG && decoder_FL_out.dest_idx[1] != `ZERO_REG) begin
      FL_idx = '{tail_plus_one, tail};
    end else begin
      FL_idx = '{tail, tail};
    end
  end

  always_comb begin
    if (retire_en[0] && ROB_FL_out.Told_idx[0] != `ZERO_PR) begin
      head1 = `TRUE;
    end else begin
      head1 = `FALSE;
    end
  end

  always_comb begin
    if (retire_en == 2'b11 && ROB_FL_out.Told_idx[1] != `ZERO_PR) begin
      head2 = `TRUE;
    end else begin
      head2 = `FALSE;
    end
  end

  always_comb begin
    next_FL_table = FL_table;
    if (head1 && head2) begin
      next_FL_table[head] = ROB_FL_out.Told_idx[0];
      next_FL_table[head_plus_one] = ROB_FL_out.Told_idx[1];
    end else if (head1 && !head2) begin
      next_FL_table[head] = ROB_FL_out.Told_idx[0];
    end else if (!head1 && head2) begin
      next_FL_table[head] = ROB_FL_out.Told_idx[1];
    end
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
