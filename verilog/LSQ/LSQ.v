`timescale 1ns/100ps

module SQ (
  input  logic                        clock, reset, en, dispatch_en,
  input  DECODER_SQ_OUT_t             decoder_SQ_out,
  input  logic                        rollback_en,
  input  logic [$clog2(`NUM_ROB)-1:0] ROB_rollback_idx,
  input  logic [$clog2(`NUM_ROB)-1:0] diff_ROB,
  output logic                        SQ_valid,
  output SQ_RS_OUT_t                  SQ_RS_out
);
  // TODO: Cache interface
  logic      [$clog2(NUM_LSQ)-1:0]       head, next_head, tail, next_tail;
  SQ_ENTRY_t [`NUM_LSQ-1:0]              sq, next_sq;
  logic      [63:0]                      rega, regb;

  assign next_tail = rollback_en ? SQ_rollback_idx :
                     dispatch_en ? virtual_tail    : tail;
  assign tail_plus_one = tail + 1;
  assign tail_plus_two = tail + 2;
  assign head_plus_one = head + 1;
  assign head_plus_two = head + 2;
  assign SQ_RS_out.SQ_idx = '{tail2, tail1};
  assign next_head = SQ_retire_en ? head_plus_one : head;
  assign SQ_LQ_out = '{ld_hit, ld_value};

  always_comb begin
    case(decoder_SQ_out.wr_mem)
      2'b00: begin
        virtual_tail = tail;
        SQ_valid     = `TRUE;
        tail1        = tail;
        tail2        = tail;
      end
      2'b01: begin
        virtual_tail = tail_plus_one;
        SQ_valid     = tail_plus_one != head;
        tail1        = tail_plus_one;
        tail2        = tail_plus_one;
      end
      2'b10: begin
        virtual_tail = tail_plus_one;
        SQ_valid     = tail_plus_one != head;
        tail1        = tail;
        tail2        = tail_plus_one;
      end
      2'b11: begin
        virtual_tail = tail_plus_two;
        SQ_valid     = tail_plus_one != head && tail_plus_two != head;
        tail1        = tail_plus_one;
        tail2        = tail_plus_two;
      end
    endcase
  end

  always_comb begin
    next_sq = sq;
    case(dispatch_en)
      2'b01, 2'b10: next_sq[tail] = `SQ_ENTRY_RESET_PACKED;
      2'b11: begin
        next_sq[tail]          = `SQ_ENTRY_RESET_PACKED;
        next_sq[tail_plus_one] = `SQ_ENTRY_RESET_PACKED;
      end
    endcase
    for (int i = 0; i < `NUM_SUPER; i++) begin
      if (FU_SQ_out.wr_mem[i]) begin
        next_sq[FU_LSQ_out.SQ_idx[i]] = '{FU_LSQ_out.result[i][63:3], `TRUE, FU_LSQ_out.T1_value[i]};
      end
    end
  end

  always_comb begin
    ld_hit = '{`NUM_SUPER{1'b0}};
    ld_idx = '{`NUM_SUPER{($clog2(`NUM_LSQ)-1){1'b0}}};
    for (int i = 0; i < `NUM_SUPER; i++) begin
      for (int j = head; i != tail; i++) begin
        if (LQ_SQ_out.addr[i] == sq[j].addr && sq[j].valid == `TRUE) begin
            ld_hit[i] = `TRUE;
            ld_idx[i] = j;
        end
      end
    end
  end

  always_comb begin
    for (int i = 0; i < `NUM_SUPER; i++) begin
      ld_value[i] = sq[ld_idx[i]];
    end
  end

  always_ff @(posedge clock) begin
    if (reset) begin
      head <= `SD {`NUM_LSQ{1'b0}};
      tail <= `SD {`NUM_LSQ{1'b0}};
      sq   <= `SD `SQ_RESET;
    end else if (en) begin
      head <= `SD next_head;
      tail <= `SD next_tail;
      sq   <= `SD next_sq;
    end
  end
endmodule

module LQ (
  input  logic                        clock, reset, en, dispatch_en,
  input  DECODER_SQ_OUT_t             decoder_SQ_out,
  input  logic                        rollback_en,
  input  logic [$clog2(`NUM_ROB)-1:0] ROB_rollback_idx,
  input  logic [$clog2(`NUM_ROB)-1:0] diff_ROB,
  output logic                        LQ_valid,
  output LQ_RS_OUT_t                  LQ_RS_out
);
  // TODO: Cache interface
  logic      [$clog2(NUM_LSQ)-1:0] head, next_head, tail, next_tail;
  LQ_ENTRY_t [`NUM_LSQ-1:0]        lq, next_lq;

  assign next_tail = rollback_en ? SQ_rollback_idx :
                     dispatch_en ? virtual_tail    : tail;
  assign tail_plus_one = tail + 1;
  assign tail_plus_two = tail + 2;
  assign head_plus_one = head + 1;
  assign head_plus_two = head + 2;
  assign LQ_RS_out.LQ_idx = '{tail2, tail1};
  assign next_head = LQ_retire_en ? head_plus_one : head;
  assign ld_violate = st_hit != 2'b00;

  always_comb begin
    for (int i = 0; i < `NUM_SUPER; i++) begin
      LQ_valid[i] = SQ_LQ_out.hit[i] || D_cache_hit[i];
    end
  end

  always_comb begin
    for (int i = 0; i < `NUM_SUPER; i++) begin
      for (int j = SQ_LQ_out.LD_idx[i]; j != tail; j++) begin
        if (SQ_LQ_out.addr[i] == lq[j].addr) begin
          st_hit[i] = `TRUE;
          st_idx[i] = j;
          break;
        end
      end
    end
  end

  always_comb begin
    case(st_hit)
      2'b00: begin
        
      end
      2'b01: begin
        ld_rollback_idx = st_idx[0];
      end
      2'b10: begin
        ld_rollback_idx = st_idx[1];
      end
      2'b11: begin
        ld_rollback_idx = st_idx[0];
      end
    endcase
  end

  always_comb begin
    case(decoder_SQ_out.wr_mem)
      2'b00: begin
        virtual_tail = tail;
        LQ_ROB_valid = `TRUE;
        tail1        = tail;
        tail2        = tail;
      end
      2'b01: begin
        virtual_tail = tail_plus_one;
        LQ_ROB_valid = tail_plus_one != head;
        tail1        = tail_plus_one;
        tail2        = tail_plus_one;
      end
      2'b10: begin
        virtual_tail = tail_plus_one;
        LQ_ROB_valid = tail_plus_one != head;
        tail1        = tail;
        tail2        = tail_plus_one;
      end
      2'b11: begin
        virtual_tail = tail_plus_two;
        LQ_ROB_valid = tail_plus_one != head && tail_plus_two != head;
        tail1        = tail_plus_one;
        tail2        = tail_plus_two;
      end
    endcase
  end

  always_comb begin
    next_lq = lq;
    case(dispatch_en)
      2'b01, 2'b10: next_lq[tail] = `LQ_ENTRY_RESET_PACKED;
      2'b11: begin
        next_lq[tail]          = `LQ_ENTRY_RESET_PACKED;
        next_lq[tail_plus_one] = `LQ_ENTRY_RESET_PACKED;
      end
    endcase
    for (int i = 0; i < `NUM_SUPER; i++) begin
      if (FU_LQ_out.rd_mem[i] && LQ_valid[i]) begin
        next_lq[FU_LSQ_out.LQ_idx[i]].addr = FU_LQ_out.result[i][63:3];
      end
    end
  end

  always_ff @(posedge clock) begin
    if (reset) begin
      head <= `SD {`NUM_LSQ{1'b0}};
      tail <= `SD {`NUM_LSQ{1'b0}};
      sq   <= `SD `SQ_RESET;
    end else if (en) begin
      head <= `SD next_head;
      tail <= `SD next_tail;
      sq   <= `SD next_sq;
    end
  end
endmodule