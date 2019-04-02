module BP(
  input clock,
  input reset,
  input [63:0] if_PC_out,          // (from F-stage) PC
  input [31:0] if_IR_out,          // (from F-stage) fetched instruction out
  input        if_valid_inst_out   // (from F-stage) when low, instruction is garbage
  input        rollback_en,        // (from FU)
  input FU_BP_OUT_t FU_BP_out,     // (from FU)
  output BP_F_OUT_t BP_F_out
);

  logic                                   is_cond_br;
  logic                                   is_uncond_br;
  logic  [`NUM_BR_PC_BITS-1:0]            br_PC;
  logic  [`NUM_BR_PC_BITS-1:0]            FU_br_PC;
  logic  [2**`NUM_BR_PC_BITS-1:0]  [1:0]  BHT, next_BHT;
  logic  [2**`NUM_BR_PC_BITS-1:0]  [63:0] BTB, next_BTB
  logic  [63:0]                           BTB_NPC;

  assign br_PC = if_PC_out[`NUM_BR_PC_BITS+1:2];
  always_comb begin
    is_cond_br   = `FALSE;
    is_uncond_br = `FALSE;
    if (if_valid_inst_out) begin
      case(if_IR_out.m.opcode)
        `BLBC_INST, `BEQ_INST, `BLT_INST, `BLE_INST, `BLBS_INST, `BNE_INST, `BGE_INST, `BGT_INST: begin
          is_cond_br   = `TRUE;
        end
        `BR_INST, `BSR_INST, `JSR_GRP: begin
          is_uncond_br = `TRUE;
        end
        default: begin
        end
      endcase
    end // if
  end // always_comb

  assign BP_F_out.take_branch_out = is_uncond_br || (is_cond_br && next_BHT[br_PC][1]) || rollback_en;
  assign FU_br_PC = FU_BP_out.take_branch_PC[`NUM_BR_PC_BITS+1:2];
  // Simplified from the 2-bit saturation counter stage machine
  always_comb begin
    next_BHT = BHT;
    next_BHT[FU_br_PC][1] = (FU_BP_out.take_branch_out && BHT[FU_br_PC][0]) ||
                            (FU_BP_out.take_branch_out && BHT[FU_br_PC][1]) ||
                            (BHT[FU_br_PC][1] && BHT[FU_br_PC][0]);
    next_BHT[FU_br_PC][0] = (!BHT[FU_br_PC][1] && !BHT[FU_br_PC][0] && FU_BP_out.take_branch_out) ||
                            ( BHT[FU_br_PC][1] &&  FU_BP_out.take_branch_out) ||
                            ( BHT[FU_br_PC][1] && !BHT[FU_br_PC][0]);
  end

  // predict branch target for Fetch
  assign BTB_NPC = if_PC_out + 4;
  assign BTB_take_branch_target = BP_F_out.take_branch_out ? next_BTB[br_pc] : BTB_NPC;
  //??? BP_F_out有吗
  assign BP_F_out.take_branch_target_out = rollback_en ? FU_BP_out.take_branch_target : BTB_take_branch_target;
  // Refresh BTB
  always_comb begin
    next_BTB = BTB;
    next_BTB[br_pc] = BP_F_out.take_branch_out ? FU_BP_out.take_branch_target : BTB[br_pc];
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