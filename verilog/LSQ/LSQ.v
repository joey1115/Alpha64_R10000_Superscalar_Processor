`timescale 1ns/100ps

module SQ (
  input  logic                                   clock, reset, en, dispatch_en, rollback_en,
  input  logic            [`NUM_SUPER-1:0]       retire_en, CDB_valid,
  input  logic            [$clog2(`NUM_LSQ)-1:0] SQ_rollback_idx,
  input  logic            [$clog2(`NUM_ROB)-1:0] ROB_rollback_idx,
  input  logic            [$clog2(`NUM_ROB)-1:0] diff_ROB,
  input  DECODER_SQ_OUT_t                        decoder_SQ_out,
  input  LQ_SQ_OUT_t                             LQ_SQ_out,
  input  ROB_SQ_OUT_t                            ROB_SQ_out,
  input  FU_SQ_OUT_t                             FU_SQ_out,
  input  D_CACHE_SQ_OUT_t                        D_cache_SQ_out,
  output logic                                   dispatch_valid,
  output logic            [`NUM_SUPER-1:0]       SQ_valid,
  output SQ_ROB_OUT_t                            SQ_ROB_out,
  output SQ_RS_OUT_t                             SQ_RS_out,
  output SQ_FU_OUT_t                             SQ_FU_out,
  output SQ_LQ_OUT_t                             SQ_LQ_out,
  output SQ_D_CACHE_OUT_t                        SQ_D_cache_out
);

  logic      [$clog2(`NUM_LSQ)-1:0]                 head, next_head, tail, next_tail, tail1, tail2, tail_plus_one, tail_plus_two, head_plus_one, head_plus_two, diff_tail, virtual_tail;
  logic      [`NUM_LSQ-1:0][$clog2(`NUM_LSQ)-1:0]   sq_tmp_idx;
  SQ_ENTRY_t [`NUM_LSQ-1:0]                         sq, next_sq;
  logic      [63:0]                                 ld_value;
  logic                                             wr_en;
  logic      [60:0]                                 addr;
  logic      [63:0]                                 value;
  logic      [`NUM_SUPER-1:0][`NUM_LSQ-1:0]         LD_match;
  logic      [`NUM_LSQ-1:0][$clog2(`NUM_LSQ)-1:0]   sq_map_idx;
  logic      [`NUM_SUPER-1:0]                       retire_valid;
  logic                                             valid1, valid2;
  logic      [`NUM_SUPER-1:0]                       ld_hit;
  logic      [`NUM_SUPER-1:0][$clog2(`NUM_LSQ)-1:0] ld_idx;

  assign tail_plus_one    = tail + 1;
  assign tail_plus_two    = tail + 2;
  assign head_plus_one    = head + 1;
  assign head_plus_two    = head + 2;
  assign head_map_idx     = {$clog2(`NUM_LSQ){1'b1}} - tail + head;
  assign next_tail        = rollback_en ? SQ_rollback_idx :
                            dispatch_en ? virtual_tail    : tail;
  assign SQ_RS_out.SQ_idx = '{tail2, tail1};
  assign SQ_LQ_out        = '{ld_hit, ld_value, SQ_FU_out.done, SQ_FU_out.result[63:3]};
  assign SQ_D_cache_out   = '{wr_en, addr, value};
  assign SQ_ROB_out       = '{retire_valid};
  assign SQ_valid         = ~SQ_FU_out.done | rollback_valid | CDB_valid;

  // Dispatch Valid
  always_comb begin
    case(decoder_SQ_out.wr_mem)
      2'b00: begin
        virtual_tail   = tail;
        dispatch_valid = `TRUE;
        tail1          = tail;
        tail2          = tail;
      end
      2'b01: begin
        virtual_tail   = tail_plus_one;
        dispatch_valid = tail_plus_one != head;
        tail1          = tail_plus_one;
        tail2          = tail_plus_one;
      end
      2'b10: begin
        virtual_tail   = tail_plus_one;
        dispatch_valid = tail_plus_one != head;
        tail1          = tail;
        tail2          = tail_plus_one;
      end
      2'b11: begin
        virtual_tail   = tail_plus_two;
        dispatch_valid = tail_plus_one != head && tail_plus_two != head;
        tail1          = tail_plus_one;
        tail2          = tail_plus_two;
      end
    endcase
  end

  always_comb begin
    case(ROB_SQ_out.wr_mem)
      2'b00: begin
        retire_valid[0] = `TRUE;
        retire_valid[1] = `TRUE;
      end
      2'b01: begin
        retire_valid[0] = D_cache_SQ_out.valid;
        retire_valid[1] = D_cache_SQ_out.valid;
      end
      2'b10: begin
        retire_valid[0] = `TRUE;
        retire_valid[1] = D_cache_SQ_out.valid;
      end
      2'b11: begin
        retire_valid[0] = D_cache_SQ_out.valid;
        retire_valid[1] = `FALSE;
      end
    endcase
  end

  always_comb begin
    case(ROB_SQ_out.wr_mem)
      2'b00: begin
        wr_en           = `FALSE;
        addr            = 61'h0;
        value           = 64'hbaadbeefdeadbeef;
      end
      2'b01: begin
        wr_en           = `TRUE;
        addr            = sq[ROB_SQ_out.SQ_idx[0]].addr;
        value           = sq[ROB_SQ_out.SQ_idx[0]].value;
      end
      2'b10: begin
        wr_en           = `TRUE;
        addr            = sq[ROB_SQ_out.SQ_idx[1]].addr;
        value           = sq[ROB_SQ_out.SQ_idx[1]].value;
      end
      2'b11: begin
        wr_en           = `TRUE;
        addr            = sq[ROB_SQ_out.SQ_idx[0]].addr;
        value           = sq[ROB_SQ_out.SQ_idx[0]].value;
      end
    endcase
  end

  always_comb begin
    case(ROB_SQ_out.wr_mem & retire_en)
      2'b00: next_head = head;
      2'b01: next_head = head_plus_one;
      2'b10: next_head = head_plus_one;
      2'b11: next_head = head_plus_one;
    endcase
  end

  always_comb begin
    for (int i = 0; i < `NUM_SUPER; i++) begin
      diff[i]           = SQ_FU_out.ROB_idx[i] - ROB_rollback_idx;
      rollback_valid[i] = rollback_en && diff_ROB >= diff[i];
    end
  end

  always_comb begin
    for (int i = 0; i < `NUM_SUPER; i++) begin
      if (rollback_valid[i]) begin
        next_SQ_FU_out.done[i]     = `FALSE;
        next_SQ_FU_out.result[i]   = 64'hbaadbeefdeadbeef;
        next_SQ_FU_out.dest_idx[i] = `ZERO_REG;
        next_SQ_FU_out.T_idx[i]    = `ZERO_PR;
        next_SQ_FU_out.ROB_idx[i]  = {$clog2(`NUM_ROB){1'b0}};
        next_SQ_FU_out.FL_idx[i]   = {$clog2(`NUM_FL){1'b0}};
        next_SQ_FU_out.SQ_idx[i]   = {$clog2(`NUM_LSQ){1'b0}};
        next_SQ_FU_out.LQ_idx[i]   = {$clog2(`NUM_LSQ){1'b0}};
        next_SQ_FU_out.T1_value[i] = 64'hbaadbeefdeadbeef;
      end else begin
        next_SQ_FU_out.done[i]     = FU_SQ_out.done[i];
        next_SQ_FU_out.result[i]   = FU_SQ_out.result[i];
        next_SQ_FU_out.dest_idx[i] = FU_SQ_out.dest_idx[i];
        next_SQ_FU_out.T_idx[i]    = FU_SQ_out.T_idx[i];
        next_SQ_FU_out.ROB_idx[i]  = FU_SQ_out.ROB_idx[i];
        next_SQ_FU_out.FL_idx[i]   = FU_SQ_out.FL_idx[i];
        next_SQ_FU_out.SQ_idx[i]   = FU_SQ_out.SQ_idx[i];
        next_SQ_FU_out.LQ_idx[i]   = FU_SQ_out.LQ_idx[i];
        next_SQ_FU_out.T1_value[i] = FU_SQ_out.T1_value[i];
      end
    end
  end

  always_comb begin
    next_sq = sq;
    // Dispatch
    if (dispatch_en) begin
      case(decoder_SQ_out.wr_mem)
        2'b01, 2'b10: next_sq[tail] = `SQ_ENTRY_RESET_PACKED;
        2'b11: begin
          next_sq[tail]          = `SQ_ENTRY_RESET_PACKED;
          next_sq[tail_plus_one] = `SQ_ENTRY_RESET_PACKED;
        end
      endcase
    end
    // Execute
    for (int i = 0; i < `NUM_SUPER; i++) begin
      if (SQ_FU_out.done[i]) begin
        next_sq[SQ_FU_out.SQ_idx[i]] = '{SQ_FU_out.result[i][63:3], `TRUE, SQ_FU_out.T1_value[i]};
      end
    end
  end

  // Age logic
  // Map SQ idx
  always_comb begin
    for (int j = 0; j < `NUM_LSQ; j++) begin
      sq_map_idx[j] = tail + j + 1;
    end
  end

  // Age logic
  always_comb begin
    ld_hit = {`NUM_SUPER{`FALSE}};
    ld_idx = {`NUM_SUPER{`FALSE}};
    for (int i = 0; i < `NUM_SUPER; i++) begin
      for (int j = `NUM_LSQ; j >= 0; j--) begin
        if (LQ_SQ_out.addr[i] == sq[sq_map_idx[j]].addr && sq[sq_map_idx[j]].valid && j >= head_map_idx && j <= LQ_SQ_out.SQ_idx[i]) begin
          ld_hit[i] = `TRUE;
          ld_idx[i] = sq_map_idx[j];
          break;
        end
      end
    end
  end

  always_ff @(posedge clock) begin
    if (reset) begin
      head      <= `SD {($clog2(`NUM_LSQ)){1'b0}};
      tail      <= `SD {($clog2(`NUM_LSQ)){1'b0}};
      sq        <= `SD `SQ_RESET;
      SQ_FU_out <= `SD `SQ_FU_OUT_RESET;
    end else if (en) begin
      head      <= `SD next_head;
      tail      <= `SD next_tail;
      sq        <= `SD next_sq;
      SQ_FU_out <= `SD next_SQ_FU_out;
    end
  end
endmodule

module LQ (
  input  logic                                   clock, reset, en, dispatch_en, rollback_en,
  input  logic            [`NUM_SUPER-1:0]       retire_en, CDB_valid,
  input  logic            [$clog2(`NUM_LSQ)-1:0] LQ_rollback_idx,
  input  logic            [$clog2(`NUM_ROB)-1:0] ROB_rollback_idx,
  input  logic            [$clog2(`NUM_ROB)-1:0] diff_ROB,
  input  DECODER_LQ_OUT_t                        decoder_LQ_out,
  input  D_CACHE_LQ_OUT_t                        D_cache_LQ_out,
  input  FU_LQ_OUT_t                             FU_LQ_out,
  input  ROB_LQ_OUT_t                            ROB_LQ_out,
  input  SQ_LQ_OUT_t                             SQ_LQ_out,
  output logic                                   dispatch_valid,
  output logic            [`NUM_SUPER-1:0]       LQ_valid,
  output LQ_SQ_OUT_t                             LQ_SQ_out,
  output LQ_FU_OUT_t                             LQ_FU_out,
  output LQ_RS_OUT_t                             LQ_RS_out,
  output LQ_D_CACHE_OUT_t                        LQ_D_cache_out
);

  logic      [$clog2(`NUM_LSQ)-1:0]               head, next_head, tail, next_tail, tail1, tail2, virtual_tail, st_idx;
  LQ_ENTRY_t [`NUM_LSQ-1:0]                       lq, next_lq;
  logic      [`NUM_SUPER-1:0]                     st_hit;
  logic      [`NUM_LSQ-1:0][$clog2(`NUM_LSQ)-1:0] lq_map_idx;

  assign next_tail        = rollback_en ? LQ_rollback_idx :
                            dispatch_en ? virtual_tail    : tail;
  assign tail_plus_one    = tail + 1;
  assign tail_plus_two    = tail + 2;
  assign head_plus_one    = head + 1;
  assign head_plus_two    = head + 2;
  assign tail_map_idx     = tail - head;
  assign LQ_RS_out.LQ_idx = '{tail2, tail1};
  assign LQ_valid         = rollback_valid | !LQ_FU_out.done | SQ_LQ_out.hit | D_cache_LQ_out.valid | CDB_valid;

  // Dispatch valid
  always_comb begin
    case(decoder_LQ_out.rd_mem)
      2'b00: begin
        virtual_tail   = tail;
        dispatch_valid = `TRUE;
        tail1          = tail;
        tail2          = tail;
      end
      2'b01: begin
        virtual_tail   = tail_plus_one;
        dispatch_valid = tail_plus_one != head;
        tail1          = tail_plus_one;
        tail2          = tail_plus_one;
      end
      2'b10: begin
        virtual_tail   = tail_plus_one;
        dispatch_valid = tail_plus_one != head;
        tail1          = tail;
        tail2          = tail_plus_one;
      end
      2'b11: begin
        virtual_tail   = tail_plus_two;
        dispatch_valid = tail_plus_one != head && tail_plus_two != head;
        tail1          = tail_plus_one;
        tail2          = tail_plus_two;
      end
    endcase
  end

  always_comb begin
    for (int i = 0; i < `NUM_SUPER; i++) begin
      LQ_SQ_out.SQ_idx[i] = LQ_FU_out.SQ_idx[i];
      LQ_SQ_out.addr[i]   = LQ_FU_out.result[i][63:3];
    end
  end

  always_comb begin
    for (int i = 0; i < `NUM_SUPER; i++) begin
      LQ_D_cache_out.rd_en[i] = LQ_FU_out.done[i] && !rollback_valid[i];
      LQ_D_cache_out.addr[i]  = LQ_FU_out.result[i][63:3];
    end
  end

  always_comb begin
    for (int i = 0; i < `NUM_SUPER; i++) begin
      diff[i]           = FU_LQ_out.ROB_idx[i] - ROB_rollback_idx;
      rollback_valid[i] = rollback_en && diff_ROB >= diff[i];
    end
  end

  always_comb begin
    for (int i = 0; i < `NUM_SUPER; i++) begin
      if (rollback_valid[i]) begin
        next_LQ_FU_out.done[i]     = `FALSE;
        next_LQ_FU_out.result[i]   = 64'hbaadbeefdeadbeef;
        next_LQ_FU_out.dest_idx[i] = `ZERO_REG;
        next_LQ_FU_out.T_idx[i]    = `ZERO_PR;
        next_LQ_FU_out.ROB_idx[i]  = {$clog2(`NUM_ROB){1'b0}};
        next_LQ_FU_out.FL_idx[i]   = {$clog2(`NUM_FL){1'b0}};
        next_LQ_FU_out.SQ_idx[i]   = {$clog2(`NUM_LSQ){1'b0}};
        next_LQ_FU_out.LQ_idx[i]   = {$clog2(`NUM_LSQ){1'b0}};
      end else begin
        next_LQ_FU_out.done[i]     = D_cache_LQ_out.valid[i] || st_hit[i];
        next_LQ_FU_out.result[i]   = D_cache_LQ_out.value[i];
        next_LQ_FU_out.dest_idx[i] = FU_LQ_out.dest_idx[i];
        next_LQ_FU_out.T_idx[i]    = FU_LQ_out.T_idx[i];
        next_LQ_FU_out.ROB_idx[i]  = FU_LQ_out.ROB_idx[i];
        next_LQ_FU_out.FL_idx[i]   = FU_LQ_out.FL_idx[i];
        next_LQ_FU_out.SQ_idx[i]   = FU_LQ_out.SQ_idx[i];
        next_LQ_FU_out.LQ_idx[i]   = FU_LQ_out.LQ_idx[i];
      end
    end
  end

  // Age logic
  // Map LQ idx
  always_comb begin
    for (int j = 0; j < `NUM_LSQ; j++) begin
      lq_map_idx[j] = head + j;
    end
  end

  // Rollback
  always_comb begin
    st_hit = '{`NUM_SUPER{`FALSE}};
    st_idx = {`NUM_SUPER{{$clog2(`NUM_LSQ){1'b0}}}};
    for (int i = 0; i < `NUM_SUPER; i++) begin
      for (int j = 0; j < `NUM_LSQ; j++) begin
        if (SQ_LQ_out.done[i] && SQ_LQ_out.addr[i] == lq[lq_map_idx[j]].addr && j < tail_map_idx) begin
          st_hit[i] = `TRUE;
          st_idx[i] = lq_map_idx[j];
          break;
        end
      end
    end
  end

  // Retire
  always_comb begin
    case(ROB_LQ_out.rd_mem & retire_en)
      2'b00: begin
        next_head = head;
      end
      2'b01: begin
        next_head = head_plus_one;
      end
      2'b10: begin
        next_head = head_plus_one;
      end
      2'b11: begin
        next_head = head_plus_two;
      end
    endcase
  end

  always_comb begin
    next_lq = lq;
    if (dispatch_en) begin
      case(ROB_LQ_out.rd_mem)
        2'b01, 2'b10: next_lq[tail] = `LQ_ENTRY_RESET_PACKED;
        2'b11: begin
          next_lq[tail]          = `LQ_ENTRY_RESET_PACKED;
          next_lq[tail_plus_one] = `LQ_ENTRY_RESET_PACKED;
        end
      endcase
    end
    for (int i = 0; i < `NUM_SUPER; i++) begin
      if (LQ_FU_out.done[i] && LQ_valid[i]) begin
        next_lq[LQ_FU_out.LQ_idx[i]] = '{LQ_FU_out.result[i][63:3], `TRUE};
      end
    end
  end

  always_ff @(posedge clock) begin
    if (reset) begin
      head      <= `SD {($clog2(`NUM_LSQ)){1'b0}};
      tail      <= `SD {($clog2(`NUM_LSQ)){1'b0}};
      lq        <= `SD `LQ_RESET;
      LQ_FU_out <= `SD `LQ_FU_OUT_RESET;
    end else if (en) begin
      head      <= `SD next_head;
      tail      <= `SD next_tail;
      lq        <= `SD next_lq;
      LQ_FU_out <= `SD next_LQ_FU_out;
    end
  end
endmodule

module LSQ (
  input  logic                                   clock, reset, en, dispatch_en, rollback_en,
  input  logic            [`NUM_SUPER-1:0]       retire_en, CDB_SQ_valid, CDB_LQ_valid,
  input  logic            [$clog2(`NUM_LSQ)-1:0] SQ_rollback_idx,
  input  logic            [$clog2(`NUM_LSQ)-1:0] LQ_rollback_idx,
  input  logic            [$clog2(`NUM_ROB)-1:0] ROB_rollback_idx,
  input  logic            [$clog2(`NUM_ROB)-1:0] diff_ROB,
  input  DECODER_SQ_OUT_t                        decoder_SQ_out,
  input  DECODER_LQ_OUT_t                        decoder_LQ_out,
  input  DECODER_SQ_OUT_t                        D_cache_SQ_out,
  input  D_CACHE_LQ_OUT_t                        D_cache_LQ_out,
  input  FU_SQ_OUT_t                             FU_SQ_out,
  input  FU_LQ_OUT_t                             FU_LQ_out,
  input  ROB_SQ_OUT_t                            ROB_SQ_out,
  input  ROB_LQ_OUT_t                            ROB_LQ_out,
  output logic                                   LSQ_valid,
  output logic            [`NUM_SUPER-1:0]       SQ_valid,
  output logic            [`NUM_SUPER-1:0]       LQ_valid,
  output SQ_ROB_OUT_t                            SQ_ROB_out,
  output SQ_FU_OUT_t                             SQ_FU_out,
  output LQ_FU_OUT_t                             LQ_FU_out,
  output SQ_RS_OUT_t                             SQ_RS_out,
  output LQ_RS_OUT_t                             LQ_RS_out,
  output SQ_D_CACHE_OUT_t                        SQ_D_cache_out,
  output LQ_D_CACHE_OUT_t                        LQ_D_cache_out
);

  LQ_SQ_OUT_t LQ_SQ_out;
  SQ_LQ_OUT_t SQ_LQ_out;
  logic       SQ_dispatch_valid, LQ_dispatch_valid;

  assign LSQ_valid = SQ_dispatch_valid && LQ_dispatch_valid;

  SQ sq_0 (
    // Input
    .clock(clock),
    .reset(reset),
    .en(en),
    .dispatch_en(dispatch_en),
    .rollback_en(rollback_en),
    .retire_en(retire_en),
    .CDB_valid(CDB_SQ_valid),
    .SQ_rollback_idx(SQ_rollback_idx),
    .ROB_rollback_idx(ROB_rollback_idx),
    .diff_ROB(diff_ROB),
    .decoder_SQ_out(decoder_SQ_out),
    .LQ_SQ_out(LQ_SQ_out),
    .ROB_SQ_out(ROB_SQ_out),
    .FU_SQ_out(FU_SQ_out),
    .D_cache_SQ_out(D_cache_SQ_out),
    // Output
    .dispatch_valid(SQ_dispatch_valid),
    .SQ_valid(SQ_valid),
    .SQ_ROB_out(SQ_ROB_out),
    .SQ_RS_out(SQ_RS_out),
    .SQ_FU_out(SQ_FU_out),
    .SQ_LQ_out(SQ_LQ_out),
    .SQ_D_cache_out(SQ_D_cache_out)
  );

  LQ lq_0 (
    // Input
    .clock(clock),
    .reset(reset),
    .en(en),
    .dispatch_en(dispatch_en),
    .rollback_en(rollback_en),
    .retire_en(retire_en),
    .CDB_valid(CDB_LQ_valid),
    .LQ_rollback_idx(LQ_rollback_idx),
    .ROB_rollback_idx(ROB_rollback_idx),
    .diff_ROB(diff_ROB),
    .decoder_LQ_out(decoder_LQ_out),
    .D_cache_LQ_out(D_cache_LQ_out),
    .FU_LQ_out(FU_LQ_out),
    .ROB_LQ_out(ROB_LQ_out),
    .SQ_LQ_out(SQ_LQ_out),
    // Output
    .dispatch_valid(LQ_dispatch_valid),
    .LQ_valid(LQ_valid),
    .LQ_SQ_out(LQ_SQ_out),
    .LQ_FU_out(LQ_FU_out),
    .LQ_RS_out(LQ_RS_out),
    .LQ_D_cache_out(LQ_D_cache_out)
  );
endmodule
