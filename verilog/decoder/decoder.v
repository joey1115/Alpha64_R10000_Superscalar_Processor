`timescale 1ns/100ps

module decoder(
  input  FB_DECODER_OUT_t        FB_decoder_out,
  output DECODER_ROB_OUT_t       decoder_ROB_out,
  output DECODER_RS_OUT_t        decoder_RS_out,
  output DECODER_FL_OUT_t        decoder_FL_out,
  output DECODER_MAP_TABLE_OUT_t decoder_Map_Table_out,
  output DECODER_SQ_OUT_t        decoder_SQ_out,
  output DECODER_LQ_OUT_t        decoder_LQ_out
  // output logic                   illegal
);

  INST_t         [`NUM_SUPER-1:0]       inst;  // fetched instruction out
  logic          [`NUM_SUPER-1:0][63:0] PC, NPC;  // fetched instruction out
  ALU_OPA_SELECT [`NUM_SUPER-1:0]       opa_select;  // fetched instruction out
  ALU_OPB_SELECT [`NUM_SUPER-1:0]       opb_select;
  logic          [`NUM_SUPER-1:0]       rd_mem, wr_mem, ldl_mem, stc_mem, cond_branch, uncond_branch, halt;
  logic          [`NUM_SUPER-1:0][63:0] target;
  logic          [`NUM_SUPER-1:0]       cpuid;     // get CPUID instruction
  logic          [`NUM_SUPER-1:0]       internal_illegal;   // non-zero on an illegal instruction
  logic          [`NUM_SUPER-1:0]       valid; // for counting valid instructions executed
  logic          [`NUM_SUPER-1:0][4:0]  dest_idx;
  FU_t           [`NUM_SUPER-1:0]       FU;
  ALU_FUNC       [`NUM_SUPER-1:0]       func;
  logic          [`NUM_SUPER-1:0][4:0]  rega_idx;
  logic          [`NUM_SUPER-1:0][4:0]  regb_idx;
  logic                                 illegal;

  assign decoder_ROB_out       = '{halt, dest_idx, internal_illegal, NPC, wr_mem, rd_mem};
  assign decoder_RS_out        = '{FU, inst, func, NPC, dest_idx, opa_select, opb_select, cond_branch, uncond_branch, wr_mem, rd_mem, target};
  assign decoder_FL_out        = '{dest_idx};
  assign decoder_Map_Table_out = '{dest_idx, rega_idx, regb_idx};
  assign decoder_SQ_out        = '{wr_mem};
  assign decoder_LQ_out        = '{rd_mem, PC};
  assign illegal               = internal_illegal[0] | internal_illegal[1];

  inst_decoder inst_decoder_0 (
    // Input
    .valid_in      (FB_decoder_out.valid),
    .inst_in       (FB_decoder_out.inst[0]),
    .PC_in         (FB_decoder_out.PC[0]),
    .NPC_in        (FB_decoder_out.NPC[0]),
    .target_in     (FB_decoder_out.target[0]),
    // Output
    .inst          (inst[0]),
    .PC            (PC[0]),
    .NPC           (NPC[0]),
    .opa_select    (opa_select[0]),
    .opb_select    (opb_select[0]),
    .rd_mem        (rd_mem[0]),
    .wr_mem        (wr_mem[0]),
    .ldl_mem       (ldl_mem[0]),
    .stc_mem       (stc_mem[0]),
    .cond_branch   (cond_branch[0]),
    .uncond_branch (uncond_branch[0]),
    .target        (target[0]),
    .cpuid         (cpuid[0]),
    .valid         (valid[0]),
    .dest_idx      (dest_idx[0]),
    .FU            (FU[0]),
    .func          (func[0]),
    .rega_idx      (rega_idx[0]),
    .regb_idx      (regb_idx[0]),
    .illegal       (internal_illegal[0]),
    .halt          (halt[0])
  );

  inst_decoder inst_decoder_1 (
    // Input
    .valid_in      (FB_decoder_out.valid),
    .inst_in       (FB_decoder_out.inst[1]),
    .PC_in         (FB_decoder_out.PC[1]),
    .NPC_in        (FB_decoder_out.NPC[1]),
    .target_in     (FB_decoder_out.target[1]),
    // Output
    .inst          (inst[1]),
    .PC            (PC[1]),
    .NPC           (NPC[1]),
    .opa_select    (opa_select[1]),
    .opb_select    (opb_select[1]),
    .rd_mem        (rd_mem[1]),
    .wr_mem        (wr_mem[1]),
    .ldl_mem       (ldl_mem[1]),
    .stc_mem       (stc_mem[1]),
    .cond_branch   (cond_branch[1]),
    .uncond_branch (uncond_branch[1]),
    .target        (target[1]),
    .cpuid         (cpuid[1]),
    .valid         (valid[1]),
    .dest_idx      (dest_idx[1]),
    .FU            (FU[1]),
    .func          (func[1]),
    .rega_idx      (rega_idx[1]),
    .regb_idx      (regb_idx[1]),
    .illegal       (internal_illegal[1]),
    .halt          (halt[1])
  );

endmodule // decoder

module inst_decoder(
  input  logic                 valid_in,
  input  INST_t                inst_in,
  input  logic          [63:0] PC_in,
  input  logic          [63:0] NPC_in,
  input  logic          [63:0] target_in,
  output INST_t                inst,  // fetched instruction ou,
  output logic          [63:0] PC,  // fetched instruction ou,
  output logic          [63:0] NPC,  // fetched instruction ou,
  output ALU_OPA_SELECT        opa_select,  // fetched instruction ou,
  output ALU_OPB_SELECT        opb_select,
  output logic                 rd_mem, wr_mem, ldl_mem, stc_mem, cond_branch, uncond_branch,
  output logic          [63:0] target,
  output logic                 cpuid,     // get CPUID instructio,
  output logic                 valid, // for counting valid instructions execute,
  output logic          [4:0]  dest_idx,
  output FU_t                  FU,
  output ALU_FUNC              func,
  output logic          [4:0]  rega_idx,
  output logic          [4:0]  regb_idx,
  output logic                 illegal,
  output logic                 halt
);

  assign target = target_in;
  always_comb begin
    inst          = `NOOP_INST;
    PC            = 64'hbaadbeefdeadbeef;
    NPC           = 64'hbaadbeefdeadbeef;
    opa_select    = ALU_OPA_IS_REGA;
    opb_select    = ALU_OPB_IS_REGB;
    func          = ALU_ADDQ;
    dest_idx      = `ZERO_REG;
    rd_mem        = `FALSE;
    wr_mem        = `FALSE;
    ldl_mem       = `FALSE;
    stc_mem       = `FALSE;
    cond_branch   = `FALSE;
    uncond_branch = `FALSE;
    FU            = FU_ALU;
    valid         = `FALSE;
    halt          = `FALSE;
    cpuid         = `FALSE;
    illegal       = `FALSE;
    rega_idx      = `ZERO_REG;
    regb_idx      = `ZERO_REG;
    if(valid_in) begin
      inst          = inst_in;
      PC            = PC_in;
      NPC           = NPC_in;
      valid = `TRUE;
      case(inst_in.m.opcode)
        `PAL_INST: begin
          case (inst_in.p.func)
            `PAL_HALT: begin
              halt = `TRUE;
            end
            `PAL_WHAMI: begin
              cpuid    = `TRUE;
              dest_idx = inst_in.r.rega_idx;
            end
            default: begin
              illegal = `TRUE;
              valid   = `FALSE;
            end
          endcase
        end

        `LDA_INST: begin
          opa_select = ALU_OPA_IS_MEM_DISP;
          opb_select = ALU_OPB_IS_REGB;
          func       = ALU_ADDQ;
          dest_idx   = inst_in.r.rega_idx;
          regb_idx   = inst_in.r.regb_idx;
          FU         = FU_ALU;
        end

        // `LDAH_INST, `LDBU_INST, `LDQ_U_INST, `LDWU_INST, `STW_INST, `STB_INST, `STQ_U_INST, `LDF_INST, `LDG_INST, `LDS_INST, `LDT_INST, `STF_INST, `STG_INST, `STS_INST, `STT_INST, `LDL_INST: begin
        //   illegal = `TRUE;
        // end

        `INTA_GRP: begin
          opa_select = ALU_OPA_IS_REGA;
          opb_select = inst_in.i.IMM ? ALU_OPB_IS_ALU_IMM : ALU_OPB_IS_REGB;
          dest_idx   = inst_in.r.regc_idx;
          FU         = FU_ALU;
          rega_idx   = inst_in.r.rega_idx;
          regb_idx   = inst_in.i.IMM ? `ZERO_REG : inst_in.r.regb_idx;
          case (inst_in.i.func)
            `CMPULT_INST: func = ALU_CMPULT;
            `ADDQ_INST:   func = ALU_ADDQ;
            `SUBQ_INST:   func = ALU_SUBQ;
            `CMPEQ_INST:  func = ALU_CMPEQ;
            `CMPULE_INST: func = ALU_CMPULE;
            `CMPLT_INST:  func = ALU_CMPLT;
            `CMPLE_INST:  func = ALU_CMPLE;
            default: begin
              illegal = `TRUE;
              valid   = `FALSE;
            end
          endcase // case(inst_in[11:5])
        end

        `INTL_GRP: begin
          opa_select = ALU_OPA_IS_REGA;
          opb_select = inst_in.i.IMM ? ALU_OPB_IS_ALU_IMM : ALU_OPB_IS_REGB;
          dest_idx   = inst_in.r.regc_idx;
          FU         = FU_ALU;
          rega_idx   = inst_in.r.rega_idx;
          regb_idx   = inst_in.i.IMM ? `ZERO_REG : inst_in.r.regb_idx;
          case (inst_in.i.func)
            `AND_INST:   func = ALU_AND;
            `BIC_INST:   func = ALU_BIC;
            `BIS_INST:   func = ALU_BIS;
            `ORNOT_INST: func = ALU_ORNOT;
            `XOR_INST:   func = ALU_XOR;
            `EQV_INST:   func = ALU_EQV;
            default: begin
              illegal = `TRUE;
              valid   = `FALSE;
            end
          endcase // case(inst_in[11:5])
        end

        `INTS_GRP: begin
          opa_select = ALU_OPA_IS_REGA;
          opb_select = inst_in.i.IMM ? ALU_OPB_IS_ALU_IMM : ALU_OPB_IS_REGB;
          dest_idx   = inst_in.r.regc_idx;
          FU         = FU_ALU;
          rega_idx   = inst_in.r.rega_idx;
          regb_idx   = inst_in.i.IMM ? `ZERO_REG : inst_in.r.regb_idx;
          case (inst_in.i.func)
            `SRL_INST: func = ALU_SRL;
            `SLL_INST: func = ALU_SLL;
            `SRA_INST: func = ALU_SRA;
            default: begin
              illegal = `TRUE;
              valid   = `FALSE;
            end
          endcase // case(inst_in[11:5])
        end

        `INTM_GRP: begin
          opa_select = ALU_OPA_IS_REGA;
          opb_select = inst_in.i.IMM ? ALU_OPB_IS_ALU_IMM : ALU_OPB_IS_REGB;
          dest_idx   = inst_in.r.regc_idx;
          FU         = FU_MULT;
          rega_idx   = inst_in.r.rega_idx;
          regb_idx   = inst_in.i.IMM ? `ZERO_REG : inst_in.r.regb_idx;
          case (inst_in.i.func)
            `MULQ_INST: func = ALU_MULQ;
            default: begin
              illegal = `TRUE;
              valid   = `FALSE;
            end
          endcase // case(inst_in[11:5])
        end

        // `ITFP_GRP, `FLTV_GRP, `FLTI_GRP, `FLTL_GRP, `MISC_GRP, `FTPI_GRP: begin
        //   illegal = `TRUE;       // unimplemented
        // end

        `LDQ_INST: begin
          opa_select = ALU_OPA_IS_MEM_DISP;
          opb_select = ALU_OPB_IS_REGB;
          func       = ALU_ADDQ;
          dest_idx   = inst_in.r.rega_idx;
          rd_mem     = `TRUE;
          FU         = FU_LD;
          rega_idx   = `ZERO_REG;
          regb_idx   = inst_in.r.regb_idx;
        end // case: `LDQ_INST

        // `LDL_L_INST, `STL_INST, `STL_C_INST: begin
        //   illegal = `TRUE;
        // end

        // `LDQ_L_INST: begin
        //   opa_select = ALU_OPA_IS_MEM_DISP;
        //   opb_select = ALU_OPB_IS_REGB;
        //   func       = ALU_ADDQ;
        //   dest_idx   = inst_in.r.rega_idx;
        //   rd_mem     = `TRUE;
        //   ldl_mem    = `TRUE;
        //   FU         = FU_LD;
        //   rega_idx   = `ZERO_REG;
        //   regb_idx   = inst_in.r.regb_idx;
        // end

        `STQ_INST: begin
          opa_select = ALU_OPA_IS_MEM_DISP;
          opb_select = ALU_OPB_IS_REGB;
          func       = ALU_ADDQ;
          wr_mem     = `TRUE;
          dest_idx   = `ZERO_REG;
          FU         = FU_ST;
          rega_idx   = inst_in.r.rega_idx;
          regb_idx   = inst_in.r.regb_idx;
        end

        // `STQ_C_INST: begin
        //   opa_select = ALU_OPA_IS_MEM_DISP;
        //   opb_select = ALU_OPB_IS_REGB;
        //   func       = ALU_ADDQ;
        //   dest_idx   = `ZERO_REG;
        //   wr_mem     = `TRUE;
        //   stc_mem    = `TRUE;
        //   FU         = FU_ST;
        //   rega_idx   = inst_in.r.rega_idx;
        //   regb_idx   = inst_in.r.regb_idx;
        // end

        `BR_INST, `BSR_INST: begin
          dest_idx      = inst_in.r.rega_idx;
          uncond_branch = `TRUE;
          opa_select    = ALU_OPA_IS_NPC;
          opb_select    = ALU_OPB_IS_BR_DISP;
          func          = ALU_ADDQ;
          FU            = FU_BR;
        end

        // `FBEQ_INST, `FBLT_INST, `FBLE_INST, `FBNE_INST, `FBGE_INST, `FBGT_INST: begin
        //   illegal = `TRUE;
        // end

        `BLBC_INST, `BEQ_INST, `BLT_INST, `BLE_INST, `BLBS_INST, `BNE_INST, `BGE_INST, `BGT_INST: begin
          opa_select  = ALU_OPA_IS_NPC;
          opb_select  = ALU_OPB_IS_BR_DISP;
          func        = ALU_ADDQ;
          cond_branch = `TRUE; // all others are conditional
          FU          = FU_BR;
          rega_idx    = inst_in.r.rega_idx;
          regb_idx    = `ZERO_REG;
        end

        `JSR_GRP: begin
          // JMP, JSR, RET, and JSR_CO have identical semantics
          opa_select    = ALU_OPA_IS_NOT3;
          opb_select    = ALU_OPB_IS_REGB;
          func          = ALU_AND; // clear low 2 bits (word-align)
          dest_idx      = inst_in.r.rega_idx;
          uncond_branch = `TRUE;
          FU            = FU_BR;
          rega_idx      = `ZERO_REG;
          regb_idx      = inst_in.r.regb_idx;
        end

        default: begin
          illegal = `TRUE;
          valid   = `FALSE;
        end
      endcase
    end // if(~valid_in)
  end // always
endmodule // inst_decoder