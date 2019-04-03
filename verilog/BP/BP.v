module BP(
  input  clock,
  input  reset,
  input  [`NUM_SUPER-1:0] [63:0]      if_PC_out,          // (from F-stage) PC
  input  [`NUM_SUPER-1:0] [31:0]      if_IR_out,          // (from F-stage) fetched instruction out
  input  [`NUM_SUPER-1:0]             if_valid_inst_out   // (from F-stage) when low, instruction is garbage
  input                               rollback_en,        // (from FU)
  input  [`NUM_SUPER-1:0] FU_BP_OUT_t FU_BP_out,     // (from FU)
  output [`NUM_SUPER-1:0] BP_F_OUT_t  BP_F_out
);

  logic  [`NUM_SUPER-1:0]                                  is_cond_br;
  logic  [`NUM_SUPER-1:0]                                  is_uncond_br;
  logic  [`NUM_SUPER-1:0]          [`NUM_BR_PC_BITS-1:0]   br_PC;
  logic  [`NUM_SUPER-1:0]          [`NUM_BR_PC_BITS-1:0]   FU_br_PC;
  logic  [2**`NUM_BR_PC_BITS-1:0]  [1:0]                   BHT, next_BHT;
  logic  [2**`NUM_BR_PC_BITS-1:0]  [63:0]                  BTB, next_BTB
  logic  [63:0]                                            BTB_NPC;
  logic  [`NUM_SUPER-1:0]          [63:0]                  BTB_take_branch_target;

  assign br_PC[0] = if_PC_out[0][`NUM_BR_PC_BITS+1:2];
  assign br_PC[1] = if_PC_out[1][`NUM_BR_PC_BITS+1:2];
  always_comb begin
    for (int i=0; i<`NUM_SUPER; i++) begin
      is_cond_br[i]   = `FALSE;
      is_uncond_br[i] = `FALSE;
      if (if_valid_inst_out[i]) begin
        case(if_IR_out[i].m.opcode)
          `BLBC_INST, `BEQ_INST, `BLT_INST, `BLE_INST, `BLBS_INST, `BNE_INST, `BGE_INST, `BGT_INST: begin
            is_cond_br[i]      = `TRUE;
            BP_F_out.branch[i] = 1;
          end
          `BR_INST, `BSR_INST, `JSR_GRP: begin
            is_uncond_br[i]    = `TRUE;
            BP_F_out.branch[i] = 0;
          end
          default: begin
          end
        endcase
      end // if
    end
  end // always_comb

  assign BP_F_out[0].take_branch_out = is_uncond_br[0] || (is_cond_br[0] && next_BHT[br_PC[0]][1]) || rollback_en;
  assign BP_F_out[1].take_branch_out = is_uncond_br[1] || (is_cond_br[1] && next_BHT[br_PC[1]][1]) || rollback_en;
  
  assign FU_br_PC[0] = FU_BP_out[0].take_branch_PC[`NUM_BR_PC_BITS+1:2];
  assign FU_br_PC[1] = FU_BP_out[1].take_branch_PC[`NUM_BR_PC_BITS+1:2];
  // Simplified from the 2-bit saturation counter stage machine
  always_comb begin
    next_BHT = BHT;
    for (int i=0; i<`NUM_SUPER; i++) begin
      next_BHT[FU_br_PC[i]][1] = (FU_BP_out[i].take_branch_out && BHT[FU_br_PC[i]][0]) ||
                              (FU_BP_out[i].take_branch_out && BHT[FU_br_PC[i]][1]) ||
                              (BHT[FU_br_PC[i]][1] && BHT[FU_br_PC[i]][0]);
      next_BHT[FU_br_PC[i]][0] = (!BHT[FU_br_PC[i]][1] && !BHT[FU_br_PC[i]][0] && FU_BP_out[i].take_branch_out) ||
                              ( BHT[FU_br_PC[i]][1] &&  FU_BP_out[i].take_branch_out) ||
                              ( BHT[FU_br_PC[i]][1] && !BHT[FU_br_PC[i]][0]);
    end
  end

  // predict branch target for Fetch
  assign BTB_NPC[0] = if_PC_out[0] + 4;
  assign BTB_NPC[1] = if_PC_out[1] + 4;
  assign BTB_take_branch_target[0] = BP_F_out[0].take_branch_out ? next_BTB[br_pc[0]] : BTB_NPC[0];
  assign BTB_take_branch_target[1] = BP_F_out[1].take_branch_out ? next_BTB[br_pc[1]] : BTB_NPC[1];
  //have BP_F_out ???
  assign BP_F_out[0].take_branch_target_out = rollback_en ? FU_BP_out[0].take_branch_target : BTB_take_branch_target[0];
  assign BP_F_out[1].take_branch_target_out = rollback_en ? FU_BP_out[1].take_branch_target : BTB_take_branch_target[1];
  // Refresh BTB
  always_comb begin
    next_BTB = BTB;
    next_BTB[br_pc[0]] = BP_F_out[0].take_branch_out ? FU_BP_out[0].take_branch_target : BTB[br_pc[0]];
    next_BTB[br_pc[1]] = BP_F_out[1].take_branch_out ? FU_BP_out[1].take_branch_target : BTB[br_pc[1]];
  end


  // assign BP_F_out.take_branch_target_out = (rollback_en) ? FU_take_branch_target : BP_take_branch_target;
  always_ff @(posedge clock) begin
    if (reset) begin
      BHT <= `SD `BHT_RESET;
      BTB <= `SD `BTB_RESET;
    end else begin
      BHT <= next_BHT;
      BTB <= next_BTB;
    end
  end

endmodule