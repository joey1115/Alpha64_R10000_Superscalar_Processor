`timescale 1ns/100ps

module alu (
  // Input
  input  logic                        clock, reset, en
  input  FU_IN_t                      FU_in,
  input  logic                        CDB_valid,
  input  logic                        rollback_en,
  input  logic [$clog2(`NUM_ROB)-1:0] ROB_rollback_idx,
  input  logic [$clog2(`NUM_ROB)-1:0] diff_ROB,
  // Output
  output FU_OUT_t                     FU_out,
  output logic                        FU_valid
);

  logic [63:0]                 regA, regB;
  logic                        rollback_valid;
  logic [$clog2(`NUM_ROB)-1:0] diff;

  assign diff           = FU_in.ROB_idx - ROB_rollback_idx;
  assign rollback_valid = rollback_en && diff_ROB > diff;
  assign FU_valid       = CDB_valid || !FU_in.ready || rollback_valid;

  function signed_lt;
    input [63:0] a, b;
    if (a[63] == b[63]) 
      signed_lt = (a < b); // signs match: signed compare same as unsigned
    else
      signed_lt = a[63];   // signs differ: a is smaller if neg, larger if pos
  endfunction

  always_comb begin
    regA = 64'hbaadbeefdeadbeef;
    case (FU_in.opa_select)
      ALU_OPA_IS_REGA:     regA = FU_in.T1_value;
      ALU_OPA_IS_MEM_DISP: regA = { {48{FU_in.inst[15]}}, FU_in.inst.m.mem_disp };
    endcase
  end

  always_comb begin
    regB = 64'hbaadbeefdeadbeef;
    case (FU_in.opb_select)
      ALU_OPB_IS_REGB:    regB = FU_in.T2_value;
      ALU_OPB_IS_ALU_IMM: regB = { 56'b0, FU_in.inst.i.LIT };
    endcase 
  end

  always_comb begin
    case (FU_in.func)
      ALU_ADDQ:   FU_out.result = regA + regB;
      ALU_SUBQ:   FU_out.result = regA - regB;
      ALU_AND:    FU_out.result = regA & regB;
      ALU_BIC:    FU_out.result = regA & ~regB;
      ALU_BIS:    FU_out.result = regA | regB;
      ALU_ORNOT:  FU_out.result = regA | ~regB;
      ALU_XOR:    FU_out.result = regA ^ regB;
      ALU_EQV:    FU_out.result = regA ^ ~regB;
      ALU_SRL:    FU_out.result = regA >> regB[5:0];
      ALU_SLL:    FU_out.result = regA << regB[5:0];
      ALU_SRA:    FU_out.result = (regA >> regB[5:0]) | ({64{regA[63]}} << (64 - regB[5:0])); // arithmetic from logical shift
      ALU_CMPULT: FU_out.result = { 63'd0, (regA < regB) };
      ALU_CMPEQ:  FU_out.result = { 63'd0, (regA == regB) };
      ALU_CMPULE: FU_out.result = { 63'd0, (regA <= regB) };
      ALU_CMPLT:  FU_out.result = { 63'd0, signed_lt(regA, regB) };
      ALU_CMPLE:  FU_out.result = { 63'd0, (signed_lt(regA, regB) || (regA == regB)) };
      default:    FU_out.result = 64'hdeadbeefbaadbeef;  // here only to force
    endcase
    FU_out.dest_idx = FU_in.dest_idx;
    FU_out.T_idx    = FU_in.T_idx;
    FU_out.FL_idx   = FU_in.FL_idx;
    FU_out.SQ_idx   = FU_in.SQ_idx;
    FU_out.LQ_idx   = FU_in.LQ_idx;
    FU_out.ROB_idx  = FU_in.ROB_idx;
    FU_out.done     = !rollback_valid && FU_in.ready;
  end
endmodule // alu

module mult_stage (
  // Input
  input  logic                        clock, reset, en, ready, valid,
  input  logic [63:0]                 product_in, mplier_in, mcand_in,
  input  logic [4:0]                  dest_idx,
  input  logic [$clog2(`NUM_PR)-1:0]  T_idx,
  input  logic [$clog2(`NUM_ROB)-1:0] ROB_idx,
  input  logic                        rollback_en,
  input  logic [$clog2(`NUM_ROB)-1:0] ROB_rollback_idx,
  input  logic [$clog2(`NUM_ROB)-1:0] diff_ROB,
  input  logic [$clog2(`NUM_FL)-1:0]  FL_idx,
  input  logic [$clog2(`NUM_LSQ)-1:0] SQ_idx,
  input  logic [$clog2(`NUM_LSQ)-1:0] LQ_idx,
  // Output
  output logic                        done,
  output logic [63:0]                 product_out, mplier_out, mcand_out,
  output logic [4:0]                  dest_idx_out,
  output logic [$clog2(`NUM_PR)-1:0]  T_idx_out,
  output logic [$clog2(`NUM_ROB)-1:0] ROB_idx_out,
  output logic [$clog2(`NUM_FL)-1:0]  FL_idx_out,
  output logic [$clog2(`NUM_LSQ)-1:0] SQ_idx_out,
  output logic [$clog2(`NUM_LSQ)-1:0] LQ_idx_out
);

  logic [63:0]                   next_mplier_out;
  logic [63:0]                   next_mcand_out;
  logic [63:0]                   next_product_out;
  logic [4:0]                    next_dest_idx_out;
  logic [$clog2(`NUM_PR)-1:0]    next_T_idx_out;
  logic [$clog2(`NUM_LSQ)-1:0]   next_SQ_idx_out;
  logic [$clog2(`NUM_LSQ)-1:0]   next_LQ_idx_out;
  logic [$clog2(`NUM_PR)-1:0]    next_ROB_idx_out;
  logic [$clog2(`NUM_FL)-1:0]    next_FL_idx_out;
  logic [63:0]                   partial_product, next_mplier, next_mcand, next_product;
  logic                          rollback_valid_out, rollback_valid;
  logic                          next_done;
  logic [$clog2(`NUM_ROB)-1:0]   diff;
`ifdef MULT_FORWARDING
  logic [$clog2(`NUM_ROB)-1:0]   diff_out;
`endif

`ifdef MULT_FORWARDING
  assign diff_out           = ROB_idx_out - ROB_rollback_idx;
  assign diff               = ROB_idx - ROB_rollback_idx;
  assign rollback_valid_out = rollback_en && diff_ROB >= diff_out;
  assign rollback_valid     = rollback_en && diff_ROB > diff;
  assign valid_out          = !ready || valid || rollback_valid_out;
`else
  assign diff               = next_ROB_idx_out - ROB_rollback_idx;
  assign rollback_valid     = rollback_en && diff_ROB > diff;
  assign next_mplier_out    = valid ? next_mplier : mplier_out;
  assign next_mcand_out     = valid ? next_mcand : mcand_out;
  assign next_product_out   = valid ? next_product : product_out;
  assign next_dest_idx_out  = valid ? dest_idx : dest_idx_out;
  assign next_T_idx_out     = valid ? T_idx : T_idx_out;
  assign next_ROB_idx_out   = valid ? ROB_idx : ROB_idx_out;
  assign next_FL_idx_out    = valid ? FL_idx : FL_idx_out;
  assign next_SQ_idx_out    = valid ? SQ_idx : SQ_idx_out;
  assign next_LQ_idx_out    = valid ? LQ_idx : LQ_idx_out;
  assign next_done          = valid ? ready : done;
`endif
  assign next_product       = product_in + partial_product;
  assign partial_product    = mplier_in[64/`NUM_MULT_STAGE-1:0] * mcand_in;
  assign next_mplier        = {{64/`NUM_MULT_STAGE{1'b0}}, mplier_in[63:64/`NUM_MULT_STAGE]};
  assign next_mcand         = {mcand_in[63-64/`NUM_MULT_STAGE:0], {(64/`NUM_MULT_STAGE){1'b0}}};

`ifdef MULT_FORWARDING
  always_comb begin
    if ( !valid && !rollback_valid_out ) begin
      next_mplier_out   = mplier_out;
      next_mcand_out    = mcand_out;
      next_product_out  = product_out;
      next_dest_idx_out = dest_idx_out;
      next_T_idx_out    = T_idx_out;
      next_ROB_idx_out  = ROB_idx_out;
      next_FL_idx_out   = FL_idx_out;
      next_SQ_idx_out   = SQ_idx_out;
      next_LQ_idx_out   = LQ_idx_out;
      next_done         = done;
    end else if ( valid && !rollback_valid ) begin
      next_mplier_out   = next_mplier;
      next_mcand_out    = next_mcand;
      next_product_out  = next_product;
      next_dest_idx_out = dest_idx;
      next_T_idx_out    = T_idx;
      next_ROB_idx_out  = ROB_idx;
      next_FL_idx_out   = FL_idx;
      next_SQ_idx_out   = SQ_idx;
      next_LQ_idx_out   = LQ_idx;
      next_done         = ready;
    end else begin
      next_mplier_out   = 64'hbaadbeefdeadbeef;
      next_mcand_out    = 64'hbaadbeefdeadbeef;
      next_product_out  = 64'hbaadbeefdeadbeef;
      next_dest_idx_out = `ZERO_REG;
      next_T_idx_out    = `ZERO_PR;
      next_ROB_idx_out  = {$clog2(`NUM_ROB){1'b0}};
      next_FL_idx_out   = {$clog2(`NUM_FL){1'b0}};
      next_SQ_idx_out   = {$clog2(`NUM_LSQ){1'b0}};
      next_LQ_idx_out   = {$clog2(`NUM_LSQ){1'b0}};
      next_done         = `FALSE;
    end
  end
`endif

  always_ff @(posedge clock) begin
`ifdef MULT_FORWARDING
    if ( reset ) begin
`else
    if ( reset || rollback_valid ) begin
`endif
      mplier_out   <= `SD 64'hbaadbeefdeadbeef;
      mcand_out    <= `SD 64'hbaadbeefdeadbeef;
      product_out  <= `SD 64'hbaadbeefdeadbeef;
      dest_idx_out <= `SD `ZERO_REG;
      T_idx_out    <= `SD `ZERO_PR;
      ROB_idx_out  <= {$clog2(`NUM_ROB){1'b0}};
      FL_idx_out   <= {$clog2(`NUM_FL){1'b0}};
      SQ_idx_out   <= {$clog2(`NUM_LSQ){1'b0}};
      LQ_idx_out   <= {$clog2(`NUM_LSQ){1'b0}};
      done         <= `SD `FALSE;
    end else if (en) begin
      mplier_out       <= `SD next_mplier_out;
      mcand_out        <= `SD next_mcand_out;
      product_out      <= `SD next_product_out;
      dest_idx_out     <= `SD next_dest_idx_out;
      T_idx_out        <= `SD next_T_idx_out;
      ROB_idx_out      <= `SD next_ROB_idx_out;
      FL_idx_out       <= `SD next_FL_idx_out;
      SQ_idx_out       <= `SD next_SQ_idx_out;
      LQ_idx_out       <= `SD next_LQ_idx_out;
      done             <= `SD next_done;
    end
  end
endmodule

module mult (
  // Input
  input  logic                                                          clock, reset, en
  input  FU_IN_t                                                        FU_in,
  input  logic                                                          CDB_valid,
  input  logic                                                          rollback_en,
  input  logic             [$clog2(`NUM_ROB)-1:0]                       ROB_rollback_idx,
  input  logic             [$clog2(`NUM_ROB)-1:0]                       diff_ROB,
  // Output
  output FU_OUT_t                                                       FU_out,
  output logic                                                          FU_valid
);

  logic                                              last_done;
  logic [63:0]                                       product_out;
  logic [4:0]                                        last_dest_idx;
  logic [$clog2(`NUM_PR)-1:0]                        last_T_idx;
  logic [$clog2(`NUM_ROB)-1:0]                       last_ROB_idx;
  logic [$clog2(`NUM_FL)-1:0]                        last_FL_idx;
  logic [$clog2(`NUM_LSQ)-1:0]                       last_SQ_idx;
  logic [$clog2(`NUM_LSQ)-1:0]                       last_LQ_idx;
  logic [((`NUM_MULT_STAGE-1)*64)-1:0]               internal_T1_values, internal_T2_values;
`ifdef MULT_FORWARDING
  logic [`NUM_MULT_STAGE-2:0]                        internal_valids;
`endif
  logic [`NUM_MULT_STAGE-2:0]                        internal_dones;
  logic [5*(`NUM_MULT_STAGE-1)-1:0]                  internal_dest_idx;
  logic [($clog2(`NUM_PR)*(`NUM_MULT_STAGE-1))-1:0]  internal_T_idx;
  logic [($clog2(`NUM_ROB)*(`NUM_MULT_STAGE-1))-1:0] internal_ROB_idx;
  logic [($clog2(`NUM_FL)*(`NUM_MULT_STAGE-1))-1:0]  internal_FL_idx;
  logic [($clog2(`NUM_LSQ)*(`NUM_MULT_STAGE-1))-1:0] internal_SQ_idx;
  logic [($clog2(`NUM_LSQ)*(`NUM_MULT_STAGE-1))-1:0] internal_LQ_idx;
  logic [63:0]                                       mcand_out, mplier_out, regA, regB;
  logic [((`NUM_MULT_STAGE-1)*64)-1:0]               internal_products, internal_mcands, internal_mpliers;
  logic [63:0]                                       result;
  logic                                              done;
  logic [4:0]                                        dest_idx;
  logic [$clog2(`NUM_PR)-1:0]                        T_idx;
  logic [$clog2(`NUM_ROB)-1:0]                       ROB_idx;
  logic [$clog2(`NUM_FL)-1:0]                        FL_idx;
  logic [$clog2(`NUM_LSQ)-1:0]                       SQ_idx;
  logic [$clog2(`NUM_LSQ)-1:0]                       LQ_idx;

  assign done     = last_done;
  assign result   = product_out;
  assign dest_idx = last_dest_idx;
  assign T_idx    = last_T_idx;
  assign ROB_idx  = last_ROB_idx;
  assign FL_idx   = last_FL_idx;
  assign SQ_idx   = last_SQ_idx;
  assign LQ_idx   = last_LQ_idx;
  assign FU_out   = '{done, result, dest_idx, T_idx, ROB_idx, FL_idx, SQ_idx, LQ_idx};
  assign regA     = FU_in.T1_value;

  always_comb begin
    regB = 64'hbaadbeefdeadbeef;
    case (FU_in.opb_select)
      ALU_OPB_IS_REGB:    regB = FU_in.T2_value;
      ALU_OPB_IS_ALU_IMM: regB = { 56'b0, FU_in.inst.i.LIT };
    endcase 
  end

  mult_stage mult_stage_0 [`NUM_MULT_STAGE-1:0] (
    // input
    .clock({`NUM_MULT_STAGE{clock}}),
    .reset({`NUM_MULT_STAGE{reset}}),
    .en({`NUM_MULT_STAGE{en}})
    .ready({internal_dones, FU_in.ready}),
`ifdef MULT_FORWARDING
    .valid({CDB_valid, internal_valids}),
`else
    .valid({`NUM_MULT_STAGE{CDB_valid}}),
`endif
    .product_in({internal_products, {64{1'b0}}}),
    .mplier_in({internal_mpliers, regA}),
    .mcand_in({internal_mcands, regB}),
    .dest_idx({internal_dest_idx, FU_in.dest_idx}),
    .T_idx({internal_T_idx, FU_in.T_idx}),
    .ROB_idx({internal_ROB_idx, FU_in.ROB_idx}),
    .rollback_en({`NUM_MULT_STAGE{rollback_en}}),
    .ROB_rollback_idx({`NUM_MULT_STAGE{ROB_rollback_idx}}),
    .diff_ROB({`NUM_MULT_STAGE{diff_ROB}}),
    .FL_idx({internal_FL_idx, FU_in.FL_idx}),
    .SQ_idx({internal_SQ_idx, FU_in.SQ_idx}),
    .LQ_idx({internal_LQ_idx, FU_in.LQ_idx}),
    // Ouput
    .done({last_done, internal_dones}),
`ifdef MULT_FORWARDING
    .valid_out({internal_valids, FU_valid}),
`endif
    .product_out({product_out, internal_products}),
    .mplier_out({mplier_out, internal_mpliers}),
    .mcand_out({mcand_out, internal_mcands}),
    .dest_idx_out({last_dest_idx, internal_dest_idx}),
    .T_idx_out({last_T_idx, internal_T_idx}),
    .ROB_idx_out({last_ROB_idx, internal_ROB_idx}),
    .FL_idx_out({last_FL_idx, internal_FL_idx}),
    .SQ_idx_out({last_SQ_idx, internal_SQ_idx}),
    .LQ_idx_out({last_LQ_idx, internal_LQ_idx})
  );
endmodule

module br(
  // Input
  input  logic                           clock, reset, en
  input  FU_IN_t                         FU_in,
  input  logic                           CDB_valid,
  input  logic    [$clog2(`NUM_ROB)-1:0] ROB_rollback_idx;
  input  logic    [$clog2(`NUM_ROB)-1:0] diff_ROB;
  // Output
  output FU_OUT_t                        FU_out,
  output BR_TARGET_t                     BR_target;
  output logic                           take_branch,
  output                                 FU_valid,
);

  logic result;
  logic [63:0] regA, regB;
  assign FU_valid = CDB_valid || !FU_in.ready;
  assign take_branch = FU_in.uncond_branch || (FU_in.cond_branch && result);
  assign diff           = FU_in.ROB_idx - ROB_rollback_idx;
  assign rollback_valid = rollback_en && diff_ROB > diff;

  always_comb begin
    BR_target.ROB_idx = FU_in.ROB_idx;
    BR_target.FL_idx  = FU_in.FL_idx;
    BR_target.SQ_idx  = FU_in.SQ_idx;
    BR_target.LQ_idx  = FU_in.LQ_idx;
  end

  always_comb begin
    result = `FALSE;
    if(FU_in.ready == `TRUE) begin
      case (FU_in.inst.r.br_func[1:0])                                      // 'full-case'  All cases covered, no need for a default
        2'b00: result = (FU_in.T1_value[0] == 0);                           // LBC: (lsb(opa) == 0) ?
        2'b01: result = (FU_in.T1_value == 0);                              // EQ: (opa == 0) ?
        2'b10: result = (FU_in.T1_value[63] == 1);                          // LT: (signed(opa) < 0) : check sign bit
        2'b11: result = (FU_in.T1_value[63] == 1) || (FU_in.T1_value == 0); // LE: (signed(opa) <= 0)
      endcase
      // negate cond if func[2] is set
      if (FU_in.inst.r.br_func[2]) begin
        result = ~result;
      end
    end
  end

  always_comb begin
    regA = 64'hbaadbeefdeadbeef;
    case (FU_in.opa_select)
      ALU_OPA_IS_NPC:      regA = FU_in.NPC;
      ALU_OPA_IS_NOT3:     regA = ~64'h3;
    endcase
  end

  always_comb begin
    regB = 64'hbaadbeefdeadbeef;
    case (FU_in.opb_select)
      ALU_OPB_IS_REGB:    regB = FU_in.T2_value;
      ALU_OPB_IS_BR_DISP: regB = { {41{FU_in.inst[20]}}, FU_in.inst[20:0], 2'b00 };
    endcase 
  end

  always_comb begin
    if (rollback_valid) begin
      FU_out = `FU_OUT_RESET;
    end else begin
      case (FU_in.func)
        ALU_ADDQ:     FU_out.result = regA + regB;
        ALU_AND:      FU_out.result = regA & regB;
        default:      FU_out.result = 64'hdeadbeefbaadbeef;  // here only to force
      endcase
      FU_out.dest_idx = FU_in.dest_idx;
      FU_out.T_idx    = FU_in.T_idx;
      FU_out.ROB_idx  = FU_in.ROB_idx;
      FU_out.FL_idx   = FU_in.FL_idx;
      FU_out.SQ_idx   = FU_in.SQ_idx;
      FU_out.LQ_idx   = FU_in.LQ_idx;
      FU_out.done     = FU_in.ready;
    end
  end
endmodule // brcond

module ld (
  // Input
  input  logic                        clock, reset, en
  input  FU_IN_t                      FU_in,
  input  logic                        LQ_valid,
  input  logic                        rollback_en,
  input  logic [$clog2(`NUM_ROB)-1:0] ROB_rollback_idx,
  input  logic [$clog2(`NUM_ROB)-1:0] diff_ROB,
  // Output
  output logic                        FU_valid,
  output LD_OUT_t                     LD_out
);

  logic                           rollback_valid;
  logic    [$clog2(`NUM_ROB)-1:0] diff;
  logic    [63:0]                 regA, regB, result;

  assign diff               = FU_in.ROB_idx - ROB_rollback_idx;
  assign rollback_valid     = rollback_en && diff_ROB > diff;
  assign regA               = { {48{FU_in.inst[15]}}, FU_in.inst.m.mem_disp };
  assign regB               = FU_in.T2_value;
  assign result             = regA + regB;
  assign FU_valid           = !FU_in.done || LQ_valid || rollback_valid;

  always_comb begin
    if ( rollback_valid ) begin
      LD_out = `LD_OUT_RESET;
    end else begin
      LD_out.done     = FU_in.done;
      LD_out.result   = result;
      LD_out.dest_idx = FU_in.dest_idx;
      LD_out.T_idx    = FU_in.T_idx;
      LD_out.ROB_idx  = FU_in.ROB_idx;
      LD_out.FL_idx   = FU_in.FL_idx;
      LD_out.SQ_idx   = FU_in.SQ_idx;
      LD_out.LQ_idx   = FU_in.LQ_idx;
    end
  end
endmodule

module st (
  // Input
  input  logic                        clock, reset, en
  input  FU_IN_t                      FU_in,
  input  logic                        SQ_valid,
  input  logic                        rollback_en,
  input  logic [$clog2(`NUM_ROB)-1:0] ROB_rollback_idx,
  input  logic [$clog2(`NUM_ROB)-1:0] diff_ROB,
  // Output
  output logic                        FU_valid,
  output ST_OUT_t                     ST_out
);

  logic                           rollback_valid;
  logic    [$clog2(`NUM_ROB)-1:0] diff;
  logic    [63:0]                 regA, regB, result;

  assign diff           = FU_in.ROB_idx - ROB_rollback_idx;
  assign rollback_valid = rollback_en && diff_ROB > diff;
  assign regA           = { {48{FU_in.inst[15]}}, FU_in.inst.m.mem_disp };
  assign regB           = FU_in.T2_value;
  assign result         = regA + regB;
  assign FU_valid       = !FU_in.done || SQ_valid || rollback_valid;

  always_comb begin
    if ( rollback_valid ) begin
      ST_out = `ST_OUT_RESET;
    end else begin
      ST_out.done     = FU_in.done;
      ST_out.result   = result;
      ST_out.dest_idx = FU_in.dest_idx;
      ST_out.T_idx    = FU_in.T_idx;
      ST_out.ROB_idx  = FU_in.ROB_idx;
      ST_out.FL_idx   = FU_in.FL_idx;
      ST_out.SQ_idx   = FU_in.SQ_idx;
      ST_out.LQ_idx   = FU_in.LQ_idx;
      ST_out.T1_value = FU_in.T1_value;
    end
  end
endmodule

module FU (
  // Input
  input  logic                                               clock,               // system clock
  input  logic                                               reset,               // system reset
  input  logic                                               en,               // system reset
  input  logic        [`NUM_SUPER-1:0][$clog2(`NUM_ROB)-1:0] ROB_idx,
  input  logic        [`NUM_FU-1:0]                          CDB_valid,
  input  logic        [`NUM_SUPER-1:0]                       SQ_valid,
  input  logic        [`NUM_SUPER-1:0]                       LQ_valid,
  input  logic        [`NUM_SUPER-1:0]                       LQ_violate,
  input  LQ_TARGET_t                                         LQ_target,
  input  RS_FU_OUT_t                                         RS_FU_out,
  input  PR_FU_OUT_t                                         PR_FU_out,
  input  SQ_FU_OUT_t                                         SQ_FU_out,
  input  LQ_FU_OUT_t                                         LQ_FU_out,
  // Output
  output logic        [`NUM_FU-1:0]                          FU_valid,
  output logic                                               rollback_en,
  output logic        [$clog2(`NUM_ROB)-1:0]                 ROB_rollback_idx,
  output logic        [$clog2(`NUM_FL)-1:0]                  FL_rollback_idx,
  output logic        [$clog2(`NUM_LSQ)-1:0]                 SQ_rollback_idx,
  output logic        [$clog2(`NUM_LSQ)-1:0]                 LQ_rollback_idx,
  output logic        [$clog2(`NUM_ROB)-1:0]                 diff_ROB,
  output logic                                               take_branch_out,
  output logic        [63:0]                                 take_branch_target,
  output FU_CDB_OUT_t                                        FU_CDB_out,
  output FU_SQ_OUT_t                                         FU_SQ_out,
  output FU_LQ_OUT_t                                         FU_LQ_out
);

  FU_OUT_t       [`NUM_FU-1:0]          FU_out;
  FU_IN_t        [`NUM_FU-1:0]          FU_in;
  logic          [`NUM_BR-1:0]          take_branch;
  FU_IDX_ENTRY_t [`NUM_FU-1:0]          FU_T_idx;
  logic          [$clog2(`NUM_ROB)-1:0] diff_ROB1, diff_ROB2;
  LD_OUT_t       [`NUM_SUPER-1:0]       ST_out;
  LD_OUT_t       [`NUM_SUPER-1:0]       LD_out;

  assign FU_CDB_out = '{FU_out};
  assign diff_ROB   = ROB_idx[0] - ROB_rollback_idx;
  assign diff_ROB1  = ROB_idx[0] - BR_target[0].ROB_idx;
  assign diff_ROB2  = ROB_idx[0] - BR_target[1].ROB_idx;
  assign diff_ROB3  = ROB_idx[0] - .ROB_idx[0];
  assign diff_ROB4  = ROB_idx[0] - .ROB_idx[0];

  always_comb begin
    case(take_branch)
      2'b00: begin
        rollback_en1        = `FALSE;
        ROB_rollback_idx1   = {`NUM_ROB{1'b0}};
        FL_rollback_idx1    = {`NUM_FL{1'b0}};
        SQ_rollback_idx1    = {`NUM_LSQ{1'b0}};
        LQ_rollback_idx1    = {`NUM_LSQ{1'b0}};
        take_branch_target1 = 64'hbaadbeefdeadbeef;
        take_branch_out1    = `FALSE;
      end
      2'b01: begin
        rollback_en1        = `TRUE;
        ROB_rollback_idx1   = FU_out[`NUM_FU-`NUM_ALU-`NUM_MULT-`NUM_BR].ROB_idx + 1;
        FL_rollback_idx1    = FU_out[`NUM_FU-`NUM_ALU-`NUM_MULT-`NUM_BR].FL_idx;
        SQ_rollback_idx1    = FU_out[`NUM_FU-`NUM_ALU-`NUM_MULT-`NUM_BR].SQ_idx;
        LQ_rollback_idx1    = FU_out[`NUM_FU-`NUM_ALU-`NUM_MULT-`NUM_BR].LQ_idx;
        take_branch_target1 = FU_out[`NUM_FU-`NUM_ALU-`NUM_MULT-`NUM_BR].result;
        take_branch_out1    = `TRUE;
      end
      2'b10: begin
        rollback_en1        = `TRUE;
        ROB_rollback_idx1   = FU_out[`NUM_FU-`NUM_ALU-`NUM_MULT-`NUM_BR+1].ROB_idx + 1;
        FL_rollback_idx1    = FU_out[`NUM_FU-`NUM_ALU-`NUM_MULT-`NUM_BR+1].FL_idx;
        SQ_rollback_idx1    = FU_out[`NUM_FU-`NUM_ALU-`NUM_MULT-`NUM_BR+1].SQ_idx;
        LQ_rollback_idx1    = FU_out[`NUM_FU-`NUM_ALU-`NUM_MULT-`NUM_BR+1].LQ_idx;
        take_branch_target1 = FU_out[`NUM_FU-`NUM_ALU-`NUM_MULT-`NUM_BR+1].result;
        take_branch_out1    = `TRUE;
      end
      2'b11: begin
        rollback_en1        = `TRUE;
        ROB_rollback_idx1   = (diff_ROB1 >= diff_ROB2) ? (FU_out[`NUM_FU-`NUM_ALU-`NUM_MULT-`NUM_BR].ROB_idx + 1) : (FU_out[`NUM_FU-`NUM_ALU-`NUM_MULT-`NUM_BR+1].ROB_idx + 1);
        FL_rollback_idx1    = (diff_ROB1 >= diff_ROB2) ? FU_out[`NUM_FU-`NUM_ALU-`NUM_MULT-`NUM_BR].FL_idx : FU_out[`NUM_FU-`NUM_ALU-`NUM_MULT-`NUM_BR+1].FL_idx;
        SQ_rollback_idx1    = (diff_ROB1 >= diff_ROB2) ? FU_out[`NUM_FU-`NUM_ALU-`NUM_MULT-`NUM_BR].SQ_idx : FU_out[`NUM_FU-`NUM_ALU-`NUM_MULT-`NUM_BR+1].SQ_idx;
        LQ_rollback_idx1    = (diff_ROB1 >= diff_ROB2) ? FU_out[`NUM_FU-`NUM_ALU-`NUM_MULT-`NUM_BR].LQ_idx : FU_out[`NUM_FU-`NUM_ALU-`NUM_MULT-`NUM_BR+1].LQ_idx;
        take_branch_target1 = (diff_ROB1 >= diff_ROB2) ? FU_out[`NUM_FU-`NUM_ALU-`NUM_MULT-`NUM_BR].result : FU_out[`NUM_FU-`NUM_ALU-`NUM_MULT-`NUM_BR+1].result;
        take_branch_out1    = `TRUE;
      end
    endcase
  end

  always_comb begin
    case(LQ_violate)
      2'b00: begin
        rollback_en        = `FALSE;
        ROB_rollback_idx   = {`NUM_ROB{1'b0}};
        FL_rollback_idx    = {`NUM_FL{1'b0}};
        take_branch_target = 64'hbaadbeefdeadbeef;
        take_branch_out    = `FALSE;
      end
      2'b01: begin
        rollback_en        = `TRUE;
        ROB_rollback_idx   = LQ_target_ROB_idx[0];
        FL_rollback_idx    = FU_out[`NUM_FU-`NUM_ALU-`NUM_MULT-`NUM_BR].FL_idx;
        take_branch_target = FU_out[`NUM_FU-`NUM_ALU-`NUM_MULT-`NUM_BR].result;
        take_branch_out    = `TRUE;
      end
      2'b10: begin
        rollback_en        = `TRUE;
        ROB_rollback_idx   = FU_out[`NUM_FU-`NUM_ALU-`NUM_MULT-`NUM_BR+1].ROB_idx;
        FL_rollback_idx    = FU_out[`NUM_FU-`NUM_ALU-`NUM_MULT-`NUM_BR+1].FL_idx;
        take_branch_target = FU_out[`NUM_FU-`NUM_ALU-`NUM_MULT-`NUM_BR+1].result;
        take_branch_out    = `TRUE;
      end
      2'b11: begin
        rollback_en        = `TRUE;
        ROB_rollback_idx   = (diff_ROB1 >= diff_ROB2) ? FU_out[`NUM_FU-`NUM_ALU-`NUM_MULT-`NUM_BR].ROB_idx : FU_out[`NUM_FU-`NUM_ALU-`NUM_MULT-`NUM_BR+1].ROB_idx;
        FL_rollback_idx    = (diff_ROB1 >= diff_ROB2) ? FU_out[`NUM_FU-`NUM_ALU-`NUM_MULT-`NUM_BR].FL_idx : FU_out[`NUM_FU-`NUM_ALU-`NUM_MULT-`NUM_BR+1].FL_idx;
        take_branch_target = (diff_ROB1 >= diff_ROB2) ? FU_out[`NUM_FU-`NUM_ALU-`NUM_MULT-`NUM_BR].result : FU_out[`NUM_FU-`NUM_ALU-`NUM_MULT-`NUM_BR+1].result;
        take_branch_out    = `TRUE;
      end
    endcase
  end

  always_comb begin
    for (int i = 0; i < `NUM_FU; i++) begin
      FU_in[i].ready         = RS_FU_out.FU_packet[i].ready;    // If an entry is ready
      FU_in[i].inst          = RS_FU_out.FU_packet[i].inst;
      FU_in[i].func          = RS_FU_out.FU_packet[i].func;
      FU_in[i].NPC           = RS_FU_out.FU_packet[i].NPC;
      FU_in[i].dest_idx      = RS_FU_out.FU_packet[i].dest_idx;
      FU_in[i].ROB_idx       = RS_FU_out.FU_packet[i].ROB_idx;
      FU_in[i].FL_idx        = RS_FU_out.FU_packet[i].FL_idx;
      FU_in[i].SQ_idx        = RS_FU_out.FU_packet[i].SQ_idx;
      FU_in[i].LQ_idx        = RS_FU_out.FU_packet[i].LQ_idx;
      FU_in[i].T_idx         = RS_FU_out.FU_packet[i].T_idx;    // Dest idx
      FU_in[i].opa_select    = RS_FU_out.FU_packet[i].opa_select;
      FU_in[i].opb_select    = RS_FU_out.FU_packet[i].opb_select;
      FU_in[i].uncond_branch = RS_FU_out.FU_packet[i].uncond_branch;
      FU_in[i].cond_branch   = RS_FU_out.FU_packet[i].cond_branch;
      FU_in[i].T1_value      = PR_FU_out.T1_value[i]; // T1 idx
      FU_in[i].T2_value      = PR_FU_out.T2_value[i]; // T2 idx
    end
  end

  always_comb begin
    for (int i = 0; i < `NUM_SUPER; i++) begin
      FU_SQ_out.done[i]     = SQ_out[i].done;
      FU_SQ_out.result[i]   = SQ_out[i].result;
      FU_SQ_out.dest_idx[i] = SQ_out[i].dest_idx;
      FU_SQ_out.T_idx[i]    = SQ_out[i].T_idx;
      FU_SQ_out.ROB_idx[i]  = SQ_out[i].ROB_idx;
      FU_SQ_out.FL_idx[i]   = SQ_out[i].FL_idx;
      FU_SQ_out.SQ_idx[i]   = SQ_out[i].SQ_idx;
      FU_SQ_out.LQ_idx[i]   = SQ_out[i].LQ_idx;
      FU_SQ_out.T1_value[i] = SQ_out[i].T1_value;
    end
  end

  always_comb begin
    for (int i = `NUM_FU-`NUM_ALU-`NUM_MULT-`NUM_BR-`NUM_ST; i < `NUM_FU-`NUM_ALU-`NUM_MULT-`NUM_BR; i++) begin
      FU_CDB_out[i].FU_out.done     = SQ_FU_out.done[i];
      FU_CDB_out[i].FU_out.result   = SQ_FU_out.result[i];
      FU_CDB_out[i].FU_out.dest_idx = SQ_FU_out.dest_idx[i];
      FU_CDB_out[i].FU_out.T_idx    = SQ_FU_out.T_idx[i];
      FU_CDB_out[i].FU_out.ROB_idx  = SQ_FU_out.ROB_idx[i];
      FU_CDB_out[i].FU_out.FL_idx   = SQ_FU_out.FL_idx[i];
      FU_CDB_out[i].FU_out.SQ_idx   = SQ_FU_out.SQ_idx[i];
      FU_CDB_out[i].FU_out.LQ_idx   = SQ_FU_out.LQ_idx[i];
    end
  end

  always_comb begin
    for (int i = 0; i < `NUM_SUPER; i++) begin
      FU_LQ_out.done[i]     = LD_out[i].done;
      FU_LQ_out.result[i]   = LD_out[i].result;
      FU_LQ_out.dest_idx[i] = LD_out[i].dest_idx;
      FU_LQ_out.T_idx[i]    = LD_out[i].T_idx;
      FU_LQ_out.ROB_idx[i]  = LD_out[i].ROB_idx;
      FU_LQ_out.FL_idx[i]   = LD_out[i].FL_idx;
      FU_LQ_out.SQ_idx[i]   = LD_out[i].SQ_idx;
      FU_LQ_out.LQ_idx[i]   = LD_out[i].LQ_idx;
    end
  end

  always_comb begin
    for (int i = `NUM_FU-`NUM_ALU-`NUM_MULT-`NUM_BR-`NUM_ST-`NUM_LD; i < `NUM_FU-`NUM_ALU-`NUM_MULT-`NUM_BR-`NUM_ST; i++) begin
      FU_CDB_out[i].FU_out.done     = LQ_FU_out.done[i];
      FU_CDB_out[i].FU_out.result   = LQ_FU_out.result[i];
      FU_CDB_out[i].FU_out.dest_idx = LQ_FU_out.dest_idx[i];
      FU_CDB_out[i].FU_out.T_idx    = LQ_FU_out.T_idx[i];
      FU_CDB_out[i].FU_out.ROB_idx  = LQ_FU_out.ROB_idx[i];
      FU_CDB_out[i].FU_out.FL_idx   = LQ_FU_out.FL_idx[i];
      FU_CDB_out[i].FU_out.SQ_idx   = LQ_FU_out.SQ_idx[i];
      FU_CDB_out[i].FU_out.LQ_idx   = LQ_FU_out.LQ_idx[i];
    end
  end

  alu alu_0 [`NUM_ALU-1:0] (
    // Inputs
    .clock({`NUM_ALU{clock}}),
    .reset({`NUM_ALU{reset}}),
    .en({`NUM_ALU{en}}),
    .rollback_en({`NUM_ALU{rollback_en}}),
    .ROB_rollback_idx({`NUM_ALU{ROB_rollback_idx}}),
    .diff_ROB({`NUM_ALU{diff_ROB}}),
    .FU_in(FU_in[`NUM_FU-1:(`NUM_FU-`NUM_ALU)]),
    .CDB_valid(CDB_valid[`NUM_FU-1:(`NUM_FU-`NUM_ALU)]),
    // Output
    .FU_valid(FU_valid[`NUM_FU-1:(`NUM_FU-`NUM_ALU)]),
    .FU_out(FU_out[`NUM_FU-1:(`NUM_FU-`NUM_ALU)])
  );

  mult mult_0 [`NUM_MULT-1:0] (
    // Inputs
    .clock({`NUM_MULT{clock}}),
    .reset({`NUM_MULT{reset}}),
    .en({`NUM_MULT{en}}),
    .rollback_en({`NUM_MULT{rollback_en}}),
    .ROB_rollback_idx({`NUM_MULT{ROB_rollback_idx}}),
    .diff_ROB({`NUM_MULT{diff_ROB}}),
    .FU_in(FU_in[(`NUM_FU-`NUM_ALU-1):(`NUM_FU-`NUM_ALU-`NUM_MULT)]),
    .CDB_valid(CDB_valid[(`NUM_FU-`NUM_ALU-1):(`NUM_FU-`NUM_ALU-`NUM_MULT)]),
    // Outputs
    .FU_valid(FU_valid[(`NUM_FU-`NUM_ALU-1):(`NUM_FU-`NUM_ALU-`NUM_MULT)]),
    .FU_out(FU_out[(`NUM_FU-`NUM_ALU-1):(`NUM_FU-`NUM_ALU-`NUM_MULT)])
  );

  br br_0 [`NUM_BR-1:0] (
    // Inputs
    .clock({`NUM_BR{clock}}),
    .reset({`NUM_BR{reset}}),
    .en({`NUM_BR{en}}),
    .FU_in(FU_in[(`NUM_FU-`NUM_ALU-`NUM_MULT-1):(`NUM_FU-`NUM_ALU-`NUM_MULT-`NUM_BR)]),
    .CDB_valid(CDB_valid[(`NUM_FU-`NUM_ALU-`NUM_MULT-1):(`NUM_FU-`NUM_ALU-`NUM_MULT-`NUM_BR)]),
    // Output
    .FU_valid(FU_valid[(`NUM_FU-`NUM_ALU-`NUM_MULT-1):(`NUM_FU-`NUM_ALU-`NUM_MULT-`NUM_BR)]),
    .take_branch(take_branch[`NUM_BR-1:0]),
    .FU_out(FU_out[(`NUM_FU-`NUM_ALU-`NUM_MULT-1):(`NUM_FU-`NUM_ALU-`NUM_MULT-`NUM_BR)])
  );

  st st_0 [`NUM_ST-1:0] (
    // Inputs
    .clock({`NUM_ST{clock}}),
    .reset({`NUM_ST{reset}}),
    .en({`NUM_ST{en}}),
    .SQ_valid(SQ_valid),
    .rollback_en({`NUM_ST{rollback_en}}),
    .ROB_rollback_idx({`NUM_ST{ROB_rollback_idx}}),
    .diff_ROB({`NUM_ST{diff_ROB}}),
    .FU_in(FU_in[(`NUM_FU-`NUM_ALU-`NUM_MULT-`NUM_BR-1):(`NUM_FU-`NUM_ALU-`NUM_MULT-`NUM_BR-`NUM_ST)]),
    // Output
    .FU_valid(FU_valid[(`NUM_FU-`NUM_ALU-`NUM_MULT-`NUM_BR-1):(`NUM_FU-`NUM_ALU-`NUM_MULT-`NUM_BR-`NUM_ST)]),
    .ST_out(ST_out)
  );

  ld ld_0 [`NUM_LD-1:0] (
    // Input
    .clock({`NUM_LD{clock}}),
    .reset({`NUM_LD{reset}}),
    .en({`NUM_LD{en}}),
    .LQ_valid(LQ_valid),
    .rollback_en({`NUM_LD{rollback_en}}),
    .ROB_rollback_idx({`NUM_LD{ROB_rollback_idx}}),
    .diff_ROB({`NUM_LD{diff_ROB}}),
    .FU_in(FU_in[(`NUM_FU-`NUM_ALU-`NUM_MULT-`NUM_BR-`NUM_ST-1):(`NUM_FU-`NUM_ALU-`NUM_MULT-`NUM_BR-`NUM_ST-`NUM_LD)]),
    // Output
    .FU_valid(FU_valid[(`NUM_FU-`NUM_ALU-`NUM_MULT-`NUM_BR-`NUM_ST-1):(`NUM_FU-`NUM_ALU-`NUM_MULT-`NUM_BR-`NUM_ST-`NUM_LD)]),
    .LD_out(LD_out)
  );
endmodule // FU
