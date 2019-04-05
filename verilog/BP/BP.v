


module BP(
  input  clock,
  input  reset,
  input  [`NUM_SUPER-1:0] [63:0]      if_NPC_out,         // (from F-stage) PC
  input  [`NUM_SUPER-1:0] [31:0]      if_IR_out,          // (from F-stage) fetched instruction out
  input  F_BP_OUT_t                   F_BP_out,   // (from F-stage) when low, instruction is garbage
  input                               rollback_en,        // (from FU)
  input  FU_BP_OUT_t                  FU_BP_out,          // (from FU)
  output BP_F_OUT_t                   BP_F_out
);

  logic  [`NUM_SUPER-1:0]                                  is_cond_br;
  logic  [`NUM_SUPER-1:0]                                  is_uncond_br;
  logic  [`NUM_SUPER-1:0]          [`NUM_BH_IDX_BITS-1:0]  bh_idx;
  logic  [`NUM_SUPER-1:0]          [`NUM_BH_IDX_BITS-1:0]  bh_idx_FU;
  logic  [`NUM_SUPER-1:0]                                  take_branch;
  logic  [2**`NUM_BH_IDX_BITS-1:0] [1:0]                   BHT, next_BHT;
  logic  [2**`NUM_BH_IDX_BITS-1:0] [63:0]                  BTB, next_BTB
  // logic  [63:0]                                            BTB_NPC;
  // logic  [`NUM_SUPER-1:0]          [63:0]                  BTB_take_branch_target;


  // 1. Identify Branch
  always_comb begin
    for (int i=0; i<`NUM_SUPER; i++) begin
      is_cond_br[i]      = `FALSE;
      is_uncond_br[i]    = `FALSE;
      // BP_F_out.branch[i] = `FALSE;
      if (F_BP_out.inst_valid[i] && !rollback_en) begin
        case(if_IR_out[i].m.opcode)
          `BLBC_INST, `BEQ_INST, `BLT_INST, `BLE_INST, `BLBS_INST, `BNE_INST, `BGE_INST, `BGT_INST: begin
            is_cond_br[i]      = `TRUE;
            // BP_F_out.branch[i] = `TRUE;
          end
          `BR_INST, `BSR_INST, `JSR_GRP: begin
            is_uncond_br[i]    = `TRUE;
            // BP_F_out.branch[i] = `TRUE;
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

  assign take_branch[0] = is_uncond_br[0] || (is_cond_br[0] && next_BHT[bh_idx[0]][1]) || rollback_en;
  assign take_branch[1] = is_uncond_br[1] || (is_cond_br[1] && next_BHT[bh_idx[1]][1]) || rollback_en;
  assign BP_F_out.take_branch_out = take_branch[0] || take_branch[1]; 

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

  assign BP_F_out.inst_valid[0] = F_BP_out.inst_valid[0];
  assign BP_F_out.inst_valid[1] = take_branch[0] ? 0:
                                  F_BP_out.inst_valid[1];

  // 3. Predict branch target
  assign BP_F_out.take_branch_target_out = (rollback_en)                 ? FU_BP_out.take_branch_target_out[FU_BP_out.take_branch_selection] :
                                           (take_branch[0]) ? next_BTB[bh_idx[0]] :
                                           (take_branch[1]) ? next_BTB[bh_idx[1]] :
                                           if_NPC_out[1];


  // Update BTB
  always_comb begin
    next_BTB = BTB;
    if (rollback_en && FU_BP_out.take_branch_out[FU_BP_out.take_branch_selection]) begin
      next_BTB[bh_idx_FU[FU_BP_out.take_branch_selection]] = FU_BP_out.take_branch_out[FU_BP_out.take_branch_selection] ? FU_BP_out.take_branch_target_out[FU_BP_out.take_branch_selection]
                                                                                                                        : BTB[bh_idx[FU_BP_out.take_branch_selection]];
    end
  end


  // assign BP_F_out.take_branch_target_out = (rollback_en) ? FU_take_branch_target : BP_take_branch_target;
  always_ff @(posedge clock) begin
    if (reset) begin
      BTB <= `SD `BTB_RESET;
    end else begin
      BTB <= next_BTB;
    end
  end

endmodule



 // assign BTB_NPC[0] = if_PC_out[0] + 4;
  // assign BTB_NPC[1] = if_PC_out[1] + 4;

  // assign BTB_take_branch_target[0] = take_branch[0] ? next_BTB[br_pc[0]] : BTB_NPC[0];
  // assign BTB_take_branch_target[1] = take_branch[1] ? next_BTB[br_pc[1]] : BTB_NPC[1];
  
  //have BP_F_out ???
  // assign BP_F_out[0].take_branch_target_out = rollback_en ? FU_BP_out.take_branch_target : BTB_take_branch_target[0];
  // assign BP_F_out[1].take_branch_target_out = rollback_en ? FU_BP_out.take_branch_target : BTB_take_branch_target[1];
 