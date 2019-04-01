module BP(
  input clock,
  input reset,
  input F_BP_OUT_t F_BP_out,
  input [63:0] if_PC_out,          // (from F-stage) PC
  input [31:0] if_IR_out,          // (from F-stage) fetched instruction out
  input        if_valid_inst_out   // (from F-stage) when low, instruction is garbage
  input        rollback_en,        // (from FU)
  input FU_BP_OUT_t FU_BP_out,     // (from FU)
  output BP_F_OUT_t BP_F_out
);

  logic                                  is_cond_br;
  logic                                  is_uncond_br;
  logic  [`NUM_BR_PC_BITS-1:0]           br_PC;
  logic  [2**`NUM_BR_PC_BITS-1:0]  [1:0] BHT;

  assign br_PC = F_BP_out.PC_reg[`NUM_BR_PC_BITS+1:2];
  always_comb begin
    is_cond_br   = `FALSE;
    is_uncond_br = `FALSE;
    if (F_BP_out.if_valid_inst_out) begin
      case(F_BP_out.inst.m.opcode)
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

  assign BP_F_out.take_branch_out = is_uncond_br || (is_cond_br && BHT[br_PC][1]) || rollback_en;
  always_comb begin
  
  end

  // assign BP_F_out.take_branch_target_out = (rollback_en) ? FU_take_branch_target : BP_take_branch_target;
  

endmodule