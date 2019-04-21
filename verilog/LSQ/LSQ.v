`timescale 1ns/100ps

module SQ (
  // Input
  input  logic                                                   clock, reset, en, dispatch_en, rollback_en,
  input  logic            [`NUM_SUPER-1:0]                       retire_en, CDB_valid,
  input  logic            [$clog2(`NUM_LSQ)-1:0]                 SQ_rollback_idx,
  input  logic            [$clog2(`NUM_ROB)-1:0]                 ROB_rollback_idx,
  input  logic            [$clog2(`NUM_ROB)-1:0]                 diff_ROB,
  input  DECODER_SQ_OUT_t                                        decoder_SQ_out,
  input  LQ_SQ_OUT_t                                             LQ_SQ_out,
  input  ROB_SQ_OUT_t                                            ROB_SQ_out,
  input  FU_SQ_OUT_t                                             FU_SQ_out,
  input  D_CACHE_SQ_OUT_t                                        D_cache_SQ_out,
  // Output
  output logic                                                   dispatch_valid,
`ifdef DEBUG
  output SQ_ENTRY_t  [`NUM_LSQ-1:0]                              sq,
  output logic       [$clog2(`NUM_LSQ)-1:0]                      head,
  output logic       [$clog2(`NUM_LSQ)-1:0]                      tail,
`endif
  output logic            [`NUM_SUPER-1:0][$clog2(`NUM_LSQ)-1:0] SQ_idx,
  output SQ_ROB_OUT_t                                            SQ_ROB_out,
  output SQ_FU_OUT_t                                             SQ_FU_out,
  output SQ_LQ_OUT_t                                             SQ_LQ_out,
  output SQ_D_CACHE_OUT_t                                        SQ_D_cache_out
);

  // SQ_FU_OUT_t                                        next_SQ_FU_out;
`ifndef DEBUG
  SQ_ENTRY_t  [`NUM_LSQ-1:0]                         sq;
  logic       [$clog2(`NUM_LSQ)-1:0]                 head;
  logic       [$clog2(`NUM_LSQ)-1:0]                 tail;
`endif
  logic       [$clog2(`NUM_LSQ)-1:0]                 next_head, next_tail, tail_plus_one, tail_plus_two, head_plus_one, head_plus_two, virtual_tail;
  logic       [`NUM_SUPER-1:0][$clog2(`NUM_LSQ)-1:0] head_map_idx;
  SQ_ENTRY_t  [`NUM_LSQ-1:0]                         next_sq;
  logic       [`NUM_SUPER-1:0][`NUM_LSQ-1:0][$clog2(`NUM_LSQ)-1:0]   sq_map_idx;
  logic       [`NUM_SUPER-1:0]                       retire_valid;
  logic       [`NUM_SUPER-1:0]                       st_hit, st_valid;
  logic       [`NUM_SUPER-1:0][$clog2(`NUM_LSQ)-1:0] st_idx, SQ_idx_minus_one;
  logic       [`NUM_SUPER-1:0]                       rollback_valid;
  logic       [`NUM_SUPER-1:0][$clog2(`NUM_ROB)-1:0] diff;

  assign tail_plus_one       = tail + 1;
  assign tail_plus_two       = tail + 2;
  assign head_plus_one       = head + 1;
  assign head_plus_two       = head + 2;
  assign next_tail           = rollback_en ? SQ_rollback_idx :
                               dispatch_en ? virtual_tail    : tail;
  assign SQ_ROB_out          = '{retire_valid};
  assign SQ_idx_minus_one[0] =  FU_SQ_out.SQ_idx[0] - 1;
  assign SQ_idx_minus_one[1] =  FU_SQ_out.SQ_idx[1] - 1;

  always_comb begin
    for (int i = 0; i < `NUM_SUPER; i++) begin
      if (rollback_valid[i]) begin
        SQ_FU_out.done[i]     = `FALSE;
        SQ_FU_out.result[i]   = 64'hbaadbeefdeadbeef;
        SQ_FU_out.dest_idx[i] = `ZERO_REG;
        SQ_FU_out.T_idx[i]    = `ZERO_PR;
        SQ_FU_out.ROB_idx[i]  = {$clog2(`NUM_ROB){1'b0}};
      end else begin
        SQ_FU_out.done[i]     = FU_SQ_out.done[i];
        SQ_FU_out.result[i]   = FU_SQ_out.result[i];
        SQ_FU_out.dest_idx[i] = FU_SQ_out.dest_idx[i];
        SQ_FU_out.T_idx[i]    = FU_SQ_out.T_idx[i];
        SQ_FU_out.ROB_idx[i]  = FU_SQ_out.ROB_idx[i];
      end
    end
  end

  always_comb begin
    for (int i = 0; i < `NUM_SUPER; i++) begin
      SQ_LQ_out.hit[i]   = st_hit[i];
      SQ_LQ_out.valid[i] = st_valid[i];
      SQ_LQ_out.value[i] = sq[sq_map_idx[i][st_idx[i]]].value;
    end
    SQ_LQ_out.LQ_idx = sq[head].LQ_idx;
    SQ_LQ_out.retire = (ROB_SQ_out.wr_mem & ROB_SQ_out.retire) != 2'b00;
    SQ_LQ_out.addr   = sq[head].addr;
  end

  // Dispatch valid
  always_comb begin
    case(decoder_SQ_out.wr_mem)
      2'b00: begin
        virtual_tail   = tail;
        dispatch_valid = `TRUE;
        SQ_idx         = '{tail, tail};
      end
      2'b01: begin
        virtual_tail   = tail_plus_one;
        dispatch_valid = tail_plus_one != head;
        SQ_idx         = '{tail_plus_one, tail_plus_one};
      end
      2'b10: begin
        virtual_tail   = tail_plus_one;
        dispatch_valid = tail_plus_one != head;
        SQ_idx         = '{tail_plus_one, tail};
      end
      2'b11: begin
        virtual_tail   = tail_plus_two;
        dispatch_valid = tail_plus_one != head && tail_plus_two != head;
        SQ_idx         = '{tail_plus_two, tail_plus_one};
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

  assign SQ_D_cache_out.wr_en = (ROB_SQ_out.wr_mem[0] & ROB_SQ_out.retire[0]) | (ROB_SQ_out.wr_mem[1] & (ROB_SQ_out.retire == 2'b11));
  assign SQ_D_cache_out.addr  = sq[head].addr;
  assign SQ_D_cache_out.value = sq[head].value;
  

  always_comb begin
    case(ROB_SQ_out.wr_mem & retire_en)
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
        next_head = head_plus_one;
      end
    endcase
  end

  always_comb begin
    for (int i = 0; i < `NUM_SUPER; i++) begin
      diff[i]           = FU_SQ_out.ROB_idx[i] - ROB_rollback_idx;
      rollback_valid[i] = rollback_en && diff_ROB >= diff[i] && diff[i] != {$clog2(`NUM_ROB){1'b0}};
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
      if (FU_SQ_out.done[i] & !rollback_valid[0]) begin
        next_sq[SQ_idx_minus_one[i]] = '{FU_SQ_out.result[i][63:3], `TRUE, FU_SQ_out.T1_value[i], FU_SQ_out.LQ_idx[i]};
      end
    end
  end

  // Age logic
  // Map SQ idx
  always_comb begin
    for (int i = 0; i < `NUM_SUPER; i++) begin
      for (int j = 0; j < `NUM_LSQ; j++) begin
        sq_map_idx[i][j] = LQ_SQ_out.SQ_idx[i] + j;
      end
    end
  end

  always_comb begin
    for (int i = 0; i < `NUM_SUPER; i++) begin
      head_map_idx[i] = {$clog2(`NUM_LSQ){1'b1}} - LQ_SQ_out.SQ_idx[i] + head;
    end
  end

  // Valid logic
  always_comb begin
    st_valid = {`NUM_SUPER{`TRUE}};
    for (int i = 0; i < `NUM_SUPER; i++) begin
      for (int j = `NUM_LSQ - 1; j >= 0; j--) begin
        if (!sq[sq_map_idx[i][j]].valid && j > head_map_idx[i]) begin
          st_valid[i] = `FALSE;
          break;
        end
      end
    end
  end

  // Age logic
  always_comb begin
    st_hit = {`NUM_SUPER{`FALSE}};
    st_idx = {`NUM_SUPER{{($clog2(`NUM_SUPER)){{1'b0}}}}};
    for (int i = 0; i < `NUM_SUPER; i++) begin
      for (int j = `NUM_LSQ - 1; j >= 0; j--) begin
        if (LQ_SQ_out.addr[i] == sq[sq_map_idx[i][j]].addr && sq[sq_map_idx[i][j]].valid && j > head_map_idx[i]) begin
          st_hit[i] = `TRUE;
          st_idx[i] = j;
          break;
        end
      end
    end
  end

  // synopsys sync_set_reset "reset"
  always_ff @(posedge clock) begin
    if (reset) begin
      head      <= `SD {($clog2(`NUM_LSQ)){1'b0}};
      tail      <= `SD {($clog2(`NUM_LSQ)){1'b0}};
      sq        <= `SD `SQ_RESET;
      // SQ_FU_out <= `SD `SQ_FU_OUT_RESET;
    end else if (en) begin
      head      <= `SD next_head;
      tail      <= `SD next_tail;
      sq        <= `SD next_sq;
      // SQ_FU_out <= `SD next_SQ_FU_out;
    end
  end
endmodule

module LQ (
  // Input
  input  logic                                                   clock, reset, en, dispatch_en, rollback_en,
  input  logic            [`NUM_SUPER-1:0]                       retire_en, CDB_valid,
  input  logic            [$clog2(`NUM_LSQ)-1:0]                 LQ_rollback_idx,
  input  logic            [$clog2(`NUM_ROB)-1:0]                 ROB_rollback_idx,
  input  logic            [$clog2(`NUM_ROB)-1:0]                 diff_ROB,
  input  logic            [`NUM_SUPER-1:0][$clog2(`NUM_ROB)-1:0] ROB_idx,
  input  logic            [`NUM_SUPER-1:0][$clog2(`NUM_FL)-1:0]  FL_idx,
  input  logic            [`NUM_SUPER-1:0][$clog2(`NUM_LSQ)-1:0] SQ_idx,
  input  DECODER_LQ_OUT_t                                        decoder_LQ_out,
  input  D_CACHE_LQ_OUT_t                                        D_cache_LQ_out,
  input  FU_LQ_OUT_t                                             FU_LQ_out,
  input  ROB_LQ_OUT_t                                            ROB_LQ_out,
  input  SQ_LQ_OUT_t                                             SQ_LQ_out,
  // Output
  output logic                                                   dispatch_valid,
`ifdef DEBUG
  output LQ_ENTRY_t       [`NUM_LSQ-1:0]                         lq,
  output logic            [$clog2(`NUM_LSQ)-1:0]                 head,
  output logic            [$clog2(`NUM_LSQ)-1:0]                 tail,
`endif
  output logic            [`NUM_SUPER-1:0]                       LQ_valid,
  output logic            [`NUM_SUPER-1:0][$clog2(`NUM_LSQ)-1:0] LQ_idx,
  output LQ_SQ_OUT_t                                             LQ_SQ_out,
  output LQ_FU_OUT_t                                             LQ_FU_out,
  output LQ_D_CACHE_OUT_t                                        LQ_D_cache_out,
  output LQ_BP_OUT_t                                             LQ_BP_out
);

`ifndef DEBUG
  LQ_ENTRY_t  [`NUM_LSQ-1:0]                         lq;
  logic       [$clog2(`NUM_LSQ)-1:0]                 head;
  logic       [$clog2(`NUM_LSQ)-1:0]                 tail;
`endif
  LQ_ENTRY_t  [`NUM_LSQ-1:0]                         next_lq;
  // LQ_FU_OUT_t                                        next_LQ_FU_out;
  logic       [$clog2(`NUM_LSQ)-1:0]                 next_head, next_tail, virtual_tail, head_plus_one, head_plus_two, tail_plus_one, tail_plus_two, tail_map_idx, ld_idx;
  logic                                              ld_hit;
  logic       [`NUM_SUPER-1:0][$clog2(`NUM_LSQ)-1:0] LQ_idx_minus_one;
  logic       [`NUM_LSQ-1:0][$clog2(`NUM_LSQ)-1:0]   lq_map_idx;
  logic       [`NUM_SUPER-1:0]                       rollback_valid;
  logic       [`NUM_SUPER-1:0][$clog2(`NUM_ROB)-1:0] diff;

  assign next_tail           = rollback_en ? LQ_rollback_idx :
                               dispatch_en ? virtual_tail    : tail;
  assign tail_plus_one       = tail + 1;
  assign tail_plus_two       = tail + 2;
  assign head_plus_one       = head + 1;
  assign head_plus_two       = head + 2;
  assign LQ_idx_minus_one[0] = FU_LQ_out.LQ_idx[0] - 1;
  assign LQ_idx_minus_one[1] = FU_LQ_out.LQ_idx[1] - 1;
  assign tail_map_idx        = SQ_LQ_out.LQ_idx - head;

  assign LQ_valid = (CDB_valid & LQ_FU_out.done) | (~FU_LQ_out.done) | rollback_valid;

  always_comb begin
    LQ_BP_out.LQ_target.ROB_idx    = lq[lq_map_idx[ld_idx]].ROB_idx - 1;
    LQ_BP_out.LQ_target.FL_idx     = lq[lq_map_idx[ld_idx]].FL_idx - 1;
    LQ_BP_out.LQ_target.SQ_idx     = lq[lq_map_idx[ld_idx]].SQ_idx;
    LQ_BP_out.LQ_target.LQ_idx     = lq_map_idx[ld_idx];
    LQ_BP_out.LQ_target.target_PC  = lq[lq_map_idx[ld_idx]].PC;
    LQ_BP_out.LQ_target.LQ_violate = ld_hit & SQ_LQ_out.retire;
  end

  // Dispatch valid
  always_comb begin
    case(decoder_LQ_out.rd_mem)
      2'b00: begin
        virtual_tail   = tail;
        dispatch_valid = `TRUE;
        LQ_idx         = '{tail, tail};
      end
      2'b01: begin
        virtual_tail   = tail_plus_one;
        dispatch_valid = tail_plus_one != head;
        LQ_idx         = '{tail_plus_one, tail_plus_one};
      end
      2'b10: begin
        virtual_tail   = tail_plus_one;
        dispatch_valid = tail_plus_one != head;
        LQ_idx         = '{tail_plus_one, tail};
      end
      2'b11: begin
        virtual_tail   = tail_plus_two;
        dispatch_valid = tail_plus_one != head && tail_plus_two != head;
        LQ_idx         = '{tail_plus_two, tail_plus_one};
      end
    endcase
  end

  always_comb begin
    for (int i = 0; i < `NUM_SUPER; i++) begin
      LQ_SQ_out.SQ_idx[i] = FU_LQ_out.SQ_idx[i];
      LQ_SQ_out.addr[i]   = FU_LQ_out.result[i][63:3];
    end
  end

  always_comb begin
    case(FU_LQ_out.done)
      2'b00: begin
        LQ_D_cache_out.rd_en = `FALSE;
        LQ_D_cache_out.addr  = 61'h0;
        LQ_D_cache_out.ROB_idx = 0;
      end
      2'b01: begin
        LQ_D_cache_out.rd_en = FU_LQ_out.done[0] & SQ_LQ_out.valid[0] & ~SQ_LQ_out.hit[0] & ~rollback_valid[0];
        LQ_D_cache_out.addr  = FU_LQ_out.result[0][63:3];
        LQ_D_cache_out.ROB_idx = FU_LQ_out.ROB_idx[0];
      end
      2'b10: begin
        LQ_D_cache_out.rd_en = FU_LQ_out.done[1] & SQ_LQ_out.valid[1] & ~SQ_LQ_out.hit[1] & ~rollback_valid[1];
        LQ_D_cache_out.addr  = FU_LQ_out.result[1][63:3];
        LQ_D_cache_out.ROB_idx = FU_LQ_out.ROB_idx[1];
      end
      2'b11: begin
        LQ_D_cache_out.rd_en = FU_LQ_out.done[0] & SQ_LQ_out.valid[1] & ~SQ_LQ_out.hit[0] & ~rollback_valid[0];
        LQ_D_cache_out.addr  = FU_LQ_out.result[0][63:3];
        LQ_D_cache_out.ROB_idx = FU_LQ_out.ROB_idx[0];
      end
    endcase
  end

  always_comb begin
    LQ_FU_out.dest_idx[0] = FU_LQ_out.dest_idx[0];
    LQ_FU_out.dest_idx[1] = FU_LQ_out.dest_idx[1];
    LQ_FU_out.T_idx[0]    = FU_LQ_out.T_idx[0];
    LQ_FU_out.T_idx[1]    = FU_LQ_out.T_idx[1];
    LQ_FU_out.ROB_idx[0]  = FU_LQ_out.ROB_idx[0];
    LQ_FU_out.ROB_idx[1]  = FU_LQ_out.ROB_idx[1];
    LQ_FU_out.result[0]   = SQ_LQ_out.hit[0] ? SQ_LQ_out.value[0] : D_cache_LQ_out.value;
    LQ_FU_out.result[1]   = SQ_LQ_out.hit[1] ? SQ_LQ_out.value[1] : D_cache_LQ_out.value;
    case(FU_LQ_out.done)
      2'b00: begin
        LQ_FU_out.done[0] = `FALSE;
        LQ_FU_out.done[1] = `FALSE;
      end
      2'b01: begin
        LQ_FU_out.done[0] = (D_cache_LQ_out.valid | SQ_LQ_out.hit[0]) & SQ_LQ_out.valid[0] & ~rollback_valid[0];
        LQ_FU_out.done[1] = `FALSE;
      end
      2'b10: begin
        LQ_FU_out.done[0] = `FALSE;
        LQ_FU_out.done[1] = (D_cache_LQ_out.valid | SQ_LQ_out.hit[1]) & SQ_LQ_out.valid[1] & ~rollback_valid[1];
      end
      2'b11: begin
        LQ_FU_out.done[0] = (D_cache_LQ_out.valid | SQ_LQ_out.hit[0]) & SQ_LQ_out.valid[0] & ~rollback_valid[0];
        LQ_FU_out.done[1] = SQ_LQ_out.hit[1] & SQ_LQ_out.valid[1] & ~rollback_valid[1];
      end
    endcase
  end

  always_comb begin
    for (int i = 0; i < `NUM_SUPER; i++) begin
      diff[i]           = FU_LQ_out.ROB_idx[i] - ROB_rollback_idx;
      rollback_valid[i] = rollback_en && diff_ROB >= diff[i] && diff[i] != {$clog2(`NUM_ROB){1'b0}};
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
    ld_hit = `FALSE;
    ld_idx = {$clog2(`NUM_LSQ){1'b0}};
    for (int i = 0; i < `NUM_SUPER; i++) begin
      for (int j = 0; j < `NUM_LSQ; j++) begin
        if (SQ_LQ_out.addr == lq[lq_map_idx[j]].addr && j < tail_map_idx) begin
          ld_hit = `TRUE;
          ld_idx = j;
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
      case(decoder_LQ_out.rd_mem)
        2'b01: begin
          next_lq[tail].addr    = 61'h0;
          // next_lq[tail].valid   = `FALSE;
          next_lq[tail].ROB_idx = ROB_idx[0];
          next_lq[tail].FL_idx  = FL_idx[0];
          next_lq[tail].SQ_idx  = SQ_idx[0];
          next_lq[tail].PC      = decoder_LQ_out.PC[0];
        end
        2'b10: begin
          next_lq[tail].addr    = 61'h0;
          // next_lq[tail].valid   = `FALSE;
          next_lq[tail].ROB_idx = ROB_idx[1];
          next_lq[tail].FL_idx  = FL_idx[1];
          next_lq[tail].SQ_idx  = SQ_idx[1];
          next_lq[tail].PC      = decoder_LQ_out.PC[1];
        end
        2'b11: begin
          next_lq[tail].addr             = 61'h0;
          // next_lq[tail].valid            = `FALSE;
          next_lq[tail].ROB_idx          = ROB_idx[0];
          next_lq[tail].FL_idx           = FL_idx[0];
          next_lq[tail].SQ_idx           = SQ_idx[0];
          next_lq[tail].PC               = decoder_LQ_out.PC[0];
          next_lq[tail_plus_one].addr    = 61'h0;
          next_lq[tail_plus_one].valid   = `FALSE;
          next_lq[tail_plus_one].ROB_idx = ROB_idx[1];
          next_lq[tail_plus_one].FL_idx  = FL_idx[1];
          next_lq[tail_plus_one].SQ_idx  = SQ_idx[1];
          next_lq[tail_plus_one].PC      = decoder_LQ_out.PC[1];
        end
      endcase
    end
    case(FU_LQ_out.done)
      2'b00: begin
        // Nothing
      end
      2'b01: begin
        next_lq[LQ_idx_minus_one[0]].addr  = FU_LQ_out.result[0][63:3];
        // next_lq[LQ_idx_minus_one[0]].valid = SQ_LQ_out.hit[0] || D_cache_LQ_out.valid;
      end
      2'b10: begin
        next_lq[LQ_idx_minus_one[1]].addr  = FU_LQ_out.result[1][63:3];
        // next_lq[LQ_idx_minus_one[1]].valid = SQ_LQ_out.hit[1] || D_cache_LQ_out.valid;
      end
      2'b11: begin
        next_lq[LQ_idx_minus_one[0]].addr  = FU_LQ_out.result[0][63:3];
        // next_lq[LQ_idx_minus_one[0]].valid = SQ_LQ_out.hit[0] || D_cache_LQ_out.valid;
        next_lq[LQ_idx_minus_one[1]].addr  = FU_LQ_out.result[1][63:3];
        // next_lq[LQ_idx_minus_one[1]].valid = SQ_LQ_out.hit[1];
      end
    endcase
  end

  // synopsys sync_set_reset "reset"
  always_ff @(posedge clock) begin
    if (reset) begin
      head      <= `SD {($clog2(`NUM_LSQ)){1'b0}};
      tail      <= `SD {($clog2(`NUM_LSQ)){1'b0}};
      lq        <= `SD `LQ_RESET;
      // LQ_FU_out <= `SD `LQ_FU_OUT_RESET;
    end else if (en) begin
      head      <= `SD next_head;
      tail      <= `SD next_tail;
      lq        <= `SD next_lq;
      // LQ_FU_out <= `SD next_LQ_FU_out;
    end
  end
endmodule

module LSQ (
  // Input
  input  logic                                                   clock, reset, en, dispatch_en, rollback_en,
  input  logic            [`NUM_SUPER-1:0]                       retire_en, CDB_SQ_valid, CDB_LQ_valid,
  input  logic            [$clog2(`NUM_LSQ)-1:0]                 SQ_rollback_idx,
  input  logic            [$clog2(`NUM_LSQ)-1:0]                 LQ_rollback_idx,
  input  logic            [$clog2(`NUM_ROB)-1:0]                 ROB_rollback_idx,
  input  logic            [$clog2(`NUM_ROB)-1:0]                 diff_ROB,
  input  logic            [`NUM_SUPER-1:0][$clog2(`NUM_ROB)-1:0] ROB_idx,
  input  logic            [`NUM_SUPER-1:0][$clog2(`NUM_FL)-1:0]  FL_idx,
  input  DECODER_SQ_OUT_t                                        decoder_SQ_out,
  input  DECODER_LQ_OUT_t                                        decoder_LQ_out,
  input  D_CACHE_SQ_OUT_t                                        D_cache_SQ_out,
  input  D_CACHE_LQ_OUT_t                                        D_cache_LQ_out,
  input  FU_SQ_OUT_t                                             FU_SQ_out,
  input  FU_LQ_OUT_t                                             FU_LQ_out,
  input  ROB_SQ_OUT_t                                            ROB_SQ_out,
  input  ROB_LQ_OUT_t                                            ROB_LQ_out,
  // Output
`ifdef DEBUG
  output SQ_ENTRY_t       [`NUM_LSQ-1:0]                         SQ_table,
  output logic            [$clog2(`NUM_LSQ)-1:0]                 SQ_head,
  output logic            [$clog2(`NUM_LSQ)-1:0]                 SQ_tail,
  output LQ_ENTRY_t       [`NUM_LSQ-1:0]                         LQ_table,
  output logic            [$clog2(`NUM_LSQ)-1:0]                 LQ_head,
  output logic            [$clog2(`NUM_LSQ)-1:0]                 LQ_tail,
`endif
  output logic                                                   LSQ_valid,
  output logic            [`NUM_SUPER-1:0]                       LQ_valid,
  output logic            [`NUM_SUPER-1:0][$clog2(`NUM_LSQ)-1:0]     SQ_idx,
  output logic            [`NUM_SUPER-1:0][$clog2(`NUM_LSQ)-1:0]     LQ_idx,
  output SQ_ROB_OUT_t                                            SQ_ROB_out,
  output SQ_FU_OUT_t                                             SQ_FU_out,
  output LQ_FU_OUT_t                                             LQ_FU_out,
  output SQ_D_CACHE_OUT_t                                        SQ_D_cache_out,
  output LQ_D_CACHE_OUT_t                                        LQ_D_cache_out,
  output LQ_BP_OUT_t                                             LQ_BP_out
);

  LQ_SQ_OUT_t LQ_SQ_out;
  SQ_LQ_OUT_t SQ_LQ_out;
  logic       SQ_dispatch_valid, LQ_dispatch_valid;

  assign LSQ_valid = SQ_dispatch_valid && LQ_dispatch_valid;

  SQ sq_0 (
    // Input
    .clock            (clock),
    .reset            (reset),
    .en               (en),
    .dispatch_en      (dispatch_en),
    .rollback_en      (rollback_en),
    .retire_en        (retire_en),
    .CDB_valid        (CDB_SQ_valid),
    .SQ_rollback_idx  (SQ_rollback_idx),
    .ROB_rollback_idx (ROB_rollback_idx),
    .diff_ROB         (diff_ROB),
    .decoder_SQ_out   (decoder_SQ_out),
    .LQ_SQ_out        (LQ_SQ_out),
    .ROB_SQ_out       (ROB_SQ_out),
    .FU_SQ_out        (FU_SQ_out),
    .D_cache_SQ_out   (D_cache_SQ_out),
    // Output
    .dispatch_valid   (SQ_dispatch_valid),
  `ifdef DEBUG
    .sq               (SQ_table),
    .head             (SQ_head),
    .tail             (SQ_tail),
  `endif
    .SQ_idx           (SQ_idx),
    .SQ_ROB_out       (SQ_ROB_out),
    .SQ_FU_out        (SQ_FU_out),
    .SQ_LQ_out        (SQ_LQ_out),
    .SQ_D_cache_out   (SQ_D_cache_out)
  );

  LQ lq_0 (
    // Input
    .clock            (clock),
    .reset            (reset),
    .en               (en),
    .dispatch_en      (dispatch_en),
    .rollback_en      (rollback_en),
    .retire_en        (retire_en),
    .CDB_valid        (CDB_LQ_valid),
    .LQ_rollback_idx  (LQ_rollback_idx),
    .ROB_rollback_idx (ROB_rollback_idx),
    .diff_ROB         (diff_ROB),
    .ROB_idx          (ROB_idx),
    .FL_idx           (FL_idx),
    .SQ_idx           (SQ_idx),
    .decoder_LQ_out   (decoder_LQ_out),
    .D_cache_LQ_out   (D_cache_LQ_out),
    .FU_LQ_out        (FU_LQ_out),
    .ROB_LQ_out       (ROB_LQ_out),
    .SQ_LQ_out        (SQ_LQ_out),
    // Output
    .dispatch_valid   (LQ_dispatch_valid),
`ifdef DEBUG
    .lq               (LQ_table),
    .head             (LQ_head),
    .tail             (LQ_tail),
`endif
    .LQ_valid         (LQ_valid),
    .LQ_idx           (LQ_idx),
    .LQ_SQ_out        (LQ_SQ_out),
    .LQ_FU_out        (LQ_FU_out),
    .LQ_D_cache_out   (LQ_D_cache_out),
    .LQ_BP_out        (LQ_BP_out)
  );
endmodule
