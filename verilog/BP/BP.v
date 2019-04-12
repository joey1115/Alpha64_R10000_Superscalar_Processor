`timescale 1ns/100ps

module BP(
  input  logic                               clock,
  input  logic                               reset,
  input  logic       [`NUM_SUPER-1:0] [63:0] if_NPC_out,         // (from F-stage) PC
  input  logic       [`NUM_SUPER-1:0] [31:0] if_IR_out,          // (from F-stage) fetched instruction out
  input  F_BP_OUT_t                          F_BP_out,           // (from F-stage) when low, instruction is garbage
  input  FU_BP_OUT_t                         FU_BP_out,          // (from FU)
  output logic                               rollback_en,
  output logic       [$clog2(`NUM_ROB)-1:0]  ROB_rollback_idx,
  output logic       [$clog2(`NUM_FL)-1:0]   FL_rollback_idx,
  output logic       [$clog2(`NUM_LSQ)-1:0]  SQ_rollback_idx,
  output logic       [$clog2(`NUM_LSQ)-1:0]  LQ_rollback_idx,
  output logic       [$clog2(`NUM_ROB)-1:0]  diff_ROB,
  output BP_F_OUT_t                          BP_F_out
);

  logic  [`NUM_SUPER-1:0]                                  is_cond_br;
  logic  [`NUM_SUPER-1:0]                                  is_uncond_br;
  logic  [`NUM_SUPER-1:0]          [`NUM_BH_IDX_BITS-1:0]  bh_idx;
  logic  [`NUM_SUPER-1:0]          [`NUM_BH_IDX_BITS-1:0]  bh_idx_FU;
  logic  [2**`NUM_BH_IDX_BITS-1:0] [1:0]                   BHT, next_BHT;
  logic  [2**`NUM_BH_IDX_BITS-1:0] [63:0]                  BTB, next_BTB;
  logic  [$clog2(`NUM_ROB)-1:0]                            diff_ROB1, diff_ROB2;

  assign BP_F_out.rollback_en = rollback_en;

  // 1. Identify Branch
  always_comb begin
    for (int i=0; i<`NUM_SUPER; i++) begin
      is_cond_br[i]      = `FALSE;
      is_uncond_br[i]    = `FALSE;
      if (F_BP_out.inst_valid[i] && !rollback_en) begin
        case(if_IR_out[i][31:26]) // if_IR_out[i].m.opcode
          `BLBC_INST, `BEQ_INST, `BLT_INST, `BLE_INST, `BLBS_INST, `BNE_INST, `BGE_INST, `BGT_INST: begin
            is_cond_br[i]      = `TRUE;
          end
          `BR_INST, `BSR_INST, `JSR_GRP: begin
            is_uncond_br[i]    = `TRUE;
          end
          default: begin
          end
        endcase
      end // if
    end
  end // always_comb


  // 2. Determine take or not
  assign bh_idx[0] = if_NPC_out[0][`NUM_BH_IDX_BITS+1:2];
  assign bh_idx[1] = if_NPC_out[1][`NUM_BH_IDX_BITS+1:2];

  assign BP_F_out.take_branch_out[0] = is_uncond_br[0] || (is_cond_br[0] && next_BHT[bh_idx[0]][1]) || rollback_en;
  assign BP_F_out.take_branch_out[1] = is_uncond_br[1] || (is_cond_br[1] && next_BHT[bh_idx[1]][1]) || rollback_en;

  // Update BHT
  assign bh_idx_FU[0] = FU_BP_out.take_branch_NPC_out[0][`NUM_BH_IDX_BITS+1:2];
  assign bh_idx_FU[1] = FU_BP_out.take_branch_NPC_out[1][`NUM_BH_IDX_BITS+1:2];

  always_comb begin
    next_BHT = BHT;
    for (int i=0; i<`NUM_SUPER; i++) begin
      if (FU_BP_out.is_branch_out[i]) begin
        // Simplified from the 2-bit saturation counter stage machine
        next_BHT[bh_idx_FU[i]][1] = (FU_BP_out.take_branch_out[i] && BHT[bh_idx_FU[i]][0]) ||
                                (FU_BP_out.take_branch_out[i] && BHT[bh_idx_FU[i]][1]) ||
                                (BHT[bh_idx_FU[i]][1] && BHT[bh_idx_FU[i]][0]);
        next_BHT[bh_idx_FU[i]][0] = (!BHT[bh_idx_FU[i]][1] && !BHT[bh_idx_FU[i]][0] && FU_BP_out.take_branch_out[i]) ||
                                (BHT[bh_idx_FU[i]][1] &&  FU_BP_out.take_branch_out[i]) ||
                                (BHT[bh_idx_FU[i]][1] && !BHT[bh_idx_FU[i]][0]);
      end // if
    end // for
  end

  always_ff @(posedge clock) begin
    if (reset) begin
      BHT <= `SD `BHT_RESET;
    end else begin
      BHT <= `SD next_BHT;
    end
  end

  assign BP_F_out.inst_valid[0] = !rollback_en && F_BP_out.inst_valid[0];
  assign BP_F_out.inst_valid[1] = !rollback_en && !BP_F_out.take_branch_out[0] && F_BP_out.inst_valid[1];

  // 3. Predict branch target
  assign BP_F_out.take_branch_target_out = (rollback_en)                 ? FU_BP_out.take_branch_target_out[FU_BP_out.take_branch_selection] :
                                           (BP_F_out.take_branch_out[0]) ? next_BTB[bh_idx[0]] :
                                           (BP_F_out.take_branch_out[1]) ? next_BTB[bh_idx[1]] :
                                           if_NPC_out[1];

  // Update BTB
  always_comb begin
    next_BTB = BTB;
    if (rollback_en && FU_BP_out.take_branch_out[FU_BP_out.take_branch_selection]) begin
      next_BTB[bh_idx_FU[FU_BP_out.take_branch_selection]] = FU_BP_out.take_branch_target_out[FU_BP_out.take_branch_selection];
    end
  end

  always_ff @(posedge clock) begin
    if (reset) begin
      BTB <= `SD `BTB_RESET;
    end else begin
      BTB <= next_BTB;
    end
  end

  
  // TO BP
  assign diff_ROB   = ROB_idx[1] - ROB_rollback_idx;
  assign diff_ROB1  = ROB_idx[1] - BR_target[0].ROB_idx;
  assign diff_ROB2  = ROB_idx[1] - BR_target[1].ROB_idx;
  assign diff_ROB3  = ROB_idx[1] - LD_target.ROB_idx[0];
  assign diff_ROB4  = ROB_idx[1] - LD_target.ROB_idx[1];

  assign FU_BP_out.is_branch_out = {FU_out[`NUM_FU-`NUM_ALU-`NUM_MULT-`NUM_BR+1].done, FU_out[`NUM_FU-`NUM_ALU-`NUM_MULT-`NUM_BR].done};
  assign FU_BP_out.take_branch_out = take_branch;
  assign FU_BP_out.take_branch_target_out[1] = (take_branch[1]) ? FU_out[`NUM_FU-`NUM_ALU-`NUM_MULT-`NUM_BR+1].result : NPC[1];
  assign FU_BP_out.take_branch_target_out[0] = (take_branch[0]) ? FU_out[`NUM_FU-`NUM_ALU-`NUM_MULT-`NUM_BR].result   : NPC[0];
  assign FU_BP_out.take_branch_NPC_out = NPC;

  assign predict_wrong[1] = FU_out[`NUM_FU-`NUM_ALU-`NUM_MULT-`NUM_BR+1].done
           && (FU_in[`NUM_FU-`NUM_ALU-`NUM_MULT-`NUM_BR+1].target != FU_BP_out.take_branch_target_out[1]);
  assign predict_wrong[0] = FU_out[`NUM_FU-`NUM_ALU-`NUM_MULT-`NUM_BR].done
           && (FU_in[`NUM_FU-`NUM_ALU-`NUM_MULT-`NUM_BR].target   != FU_BP_out.take_branch_target_out[0]);

  assign rollback_en = predict_wrong[1] || predict_wrong[0];

  always_comb begin
    case(predict_wrong)
      2'b00: begin
        rollback_en1        = `FALSE;
        ROB_rollback_idx1   = {`NUM_ROB{1'b0}};
        FL_rollback_idx1    = {`NUM_FL{1'b0}};
        SQ_rollback_idx1    = {`NUM_LSQ{1'b0}};
        LQ_rollback_idx1    = {`NUM_LSQ{1'b0}};
        take_branch_target1 = 64'hbaadbeefdeadbeef;
        diff_ROB5           = {`NUM_ROB{1'b0}};
      end
      2'b01: begin
        rollback_en1        = `TRUE;
        ROB_rollback_idx1   = BR_target[0].ROB_idx + 1;
        FL_rollback_idx1    = BR_target[0].FL_idx;
        SQ_rollback_idx1    = BR_target[0].SQ_idx;
        LQ_rollback_idx1    = BR_target[0].LQ_idx;
        take_branch_target1 = BR_target[0].result;
        diff_ROB5           = diff_ROB1;
      end
      2'b10: begin
        rollback_en1        = `TRUE;
        ROB_rollback_idx1   = BR_target[1].ROB_idx + 1;
        FL_rollback_idx1    = BR_target[1].FL_idx;
        SQ_rollback_idx1    = BR_target[1].SQ_idx;
        LQ_rollback_idx1    = BR_target[1].LQ_idx;
        take_branch_target1 = BR_target[1].result;
        diff_ROB5           = diff_ROB2;
      end
      2'b11: begin
        rollback_en1        = `TRUE;
        ROB_rollback_idx1   = (diff_ROB1 >= diff_ROB2) ? (BR_target[0].ROB_idx + 1) : (BR_target[1].ROB_idx + 1);
        FL_rollback_idx1    = (diff_ROB1 >= diff_ROB2) ? BR_target[0].FL_idx : BR_target[1].FL_idx;
        SQ_rollback_idx1    = (diff_ROB1 >= diff_ROB2) ? BR_target[0].SQ_idx : BR_target[1].SQ_idx;
        LQ_rollback_idx1    = (diff_ROB1 >= diff_ROB2) ? BR_target[0].LQ_idx : BR_target[1].LQ_idx;
        take_branch_target1 = (diff_ROB1 >= diff_ROB2) ? BR_target[0].result : BR_target[1].result;
        diff_ROB5           = (diff_ROB1 >= diff_ROB2) ? diff_ROB1 : diff_ROB2;
      end
    endcase
  end

  always_comb begin
    case(LQ_violate)
      2'b00: begin
        rollback_en2        = `FALSE;
        ROB_rollback_idx2   = {`NUM_ROB{1'b0}};
        FL_rollback_idx2    = {`NUM_FL{1'b0}};
        SQ_rollback_idx2    = {`NUM_LSQ{1'b0}};
        LQ_rollback_idx2    = {`NUM_LSQ{1'b0}};
        take_branch_target2 = 64'hbaadbeefdeadbeef;
        diff_ROB6           = {`NUM_ROB{1'b0}};
      end
      2'b01: begin
        rollback_en2        = `TRUE;
        ROB_rollback_idx2   = LD_target.ROB_idx[0];
        FL_rollback_idx2    = LD_target.FL_idx[0] - 1;
        SQ_rollback_idx2    = LD_target.SQ_idx[0];
        LQ_rollback_idx2    = LD_target.LQ_idx[0];
        take_branch_target2 = LD_target.NPC[0] - 4;
        diff_ROB6           = diff_ROB3;
      end
      2'b10: begin
        rollback_en2        = `TRUE;
        ROB_rollback_idx2   = LD_target.ROB_idx[1];
        FL_rollback_idx2    = LD_target.FL_idx[1] - 1;
        SQ_rollback_idx2    = LD_target.SQ_idx[1];
        LQ_rollback_idx2    = LD_target.LQ_idx[1];
        take_branch_target2 = LD_target.NPC[1] - 4;
        diff_ROB6           = diff_ROB4;
      end
      2'b11: begin
        rollback_en2        = `TRUE;
        ROB_rollback_idx2   = (diff_ROB3 >= diff_ROB4) ? LD_target.ROB_idx[0] : LD_target.ROB_idx[1];
        FL_rollback_idx2    = (diff_ROB3 >= diff_ROB4) ? (LD_target.FL_idx[0] - 1) : (LD_target.FL_idx[1] - 1);
        SQ_rollback_idx2    = (diff_ROB3 >= diff_ROB4) ? LD_target.SQ_idx[0] : LD_target.SQ_idx[1];
        LQ_rollback_idx2    = (diff_ROB3 >= diff_ROB4) ? LD_target.LQ_idx[0] : LD_target.LQ_idx[1];
        take_branch_target2 = (diff_ROB3 >= diff_ROB4) ? (LD_target.NPC[0] - 4) : (LD_target.NPC[1] - 4);
        diff_ROB6           = (diff_ROB3 >= diff_ROB4) ? diff_ROB3 : diff_ROB4;
      end
    endcase
  end

  always_comb begin
    case('{rollback_en2, rollback_en1})
      2'b00: begin
        rollback_en        = `FALSE;
        ROB_rollback_idx   = {`NUM_ROB{1'b0}};
        FL_rollback_idx    = {`NUM_FL{1'b0}};
        SQ_rollback_idx    = {`NUM_LSQ{1'b0}};
        LQ_rollback_idx    = {`NUM_LSQ{1'b0}};
        take_branch_target = 64'hbaadbeefdeadbeef;
      end
      2'b01: begin
        rollback_en        = `TRUE;
        ROB_rollback_idx   = ROB_rollback_idx1;
        FL_rollback_idx    = FL_rollback_idx1;
        SQ_rollback_idx    = SQ_rollback_idx1;
        LQ_rollback_idx    = LQ_rollback_idx1;
        take_branch_target = take_branch_target1;
      end
      2'b10: begin
        rollback_en        = `TRUE;
        ROB_rollback_idx   = ROB_rollback_idx2;
        FL_rollback_idx    = FL_rollback_idx2;
        SQ_rollback_idx    = SQ_rollback_idx2;
        LQ_rollback_idx    = LQ_rollback_idx2;
        take_branch_target = take_branch_target2;
      end
      2'b11: begin
        rollback_en        = `TRUE;
        ROB_rollback_idx   = (diff_ROB5 >= diff_ROB6) ? ROB_rollback_idx1 : ROB_rollback_idx2;
        FL_rollback_idx    = (diff_ROB5 >= diff_ROB6) ? FL_rollback_idx1 : FL_rollback_idx2;
        SQ_rollback_idx    = (diff_ROB5 >= diff_ROB6) ? SQ_rollback_idx1 : SQ_rollback_idx2;
        LQ_rollback_idx    = (diff_ROB5 >= diff_ROB6) ? LQ_rollback_idx1 : LQ_rollback_idx2;
        take_branch_target = (diff_ROB5 >= diff_ROB6) ? take_branch_target1 : take_branch_target2;
      end
    endcase
  end

endmodule
