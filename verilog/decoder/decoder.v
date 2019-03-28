////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//   Modulename :  decoder.v                                                  //
//                                                                            //   
//  Description :  decodes instructions and determine if valid or             //
//                   illegal.                                                 //
//                   input [31:0] inst,                                       //
//                   input valid_inst_in,                                     //
//                                                                            //
//                   output ALU_OPA_SELECT opa_select,                        //
//                   output ALU_OPB_SELECT opb_select,                        //
//                   output DEST_REG_SEL   dest_reg,                          //
//                   output ALU_FUNC       func    ,                          //
//                   output logic rd_mem, wr_mem, ldl_mem, \                  //
//                                stc_mem, cond_branch, uncond_branch,        //
//                   output logic halt,                                       //
//                   output logic cpuid,                                      //
//                   output logic illegal,                                    //
//                   output logic valid_inst                                  //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////

`timescale 1ns/100ps

module decoder(
  input  F_DECODER_OUT_t         F_decoder_out,
  output DECODER_ROB_OUT_t       decoder_ROB_out,
  output DECODER_RS_OUT_t        decoder_RS_out,
  output DECODER_FL_OUT_t        decoder_FL_out,
  output DECODER_MAP_TABLE_OUT_t decoder_Map_Table_out,
  output logic                   illegal,
  output logic                   halt
);

  INST_t                inst;  // fetched instruction out
  logic          [63:0] NPC;  // fetched instruction out
  ALU_OPA_SELECT        opa_select;  // fetched instruction out
  ALU_OPB_SELECT        opb_select;
  logic                 rd_mem, wr_mem, ldl_mem, stc_mem, cond_branch, uncond_branch;
  logic                 cpuid;     // get CPUID instruction
  //logic                 illegal;   // non-zero on an illegal instruction
  logic                 valid; // for counting valid instructions executed
  logic          [4:0]  dest_idx;
  FU_t                  FU;
  ALU_FUNC              func;
  logic          [4:0]  rega_idx;
  logic          [4:0]  regb_idx;

  assign decoder_ROB_out       = '{halt, dest_idx};
  assign decoder_RS_out        = '{FU, inst, func, NPC, dest_idx, opa_select, opb_select, cond_branch, uncond_branch};
  assign decoder_FL_out        = '{dest_idx};
  assign decoder_Map_Table_out = '{dest_idx, rega_idx, regb_idx};

  always_comb begin
    inst          = `NOOP_INST;
    NPC           = 64'h0;
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
    if(F_decoder_out.valid) begin
      inst          = F_decoder_out.inst;
      NPC           = F_decoder_out.NPC;
      valid = `TRUE;
      case(F_decoder_out.inst.m.opcode)
        `PAL_INST: begin
          case (F_decoder_out.inst.p.func)
            `PAL_HALT: begin
              halt = `TRUE;
            end
            `PAL_WHAMI: begin
              cpuid        = `TRUE;
              dest_idx = F_decoder_out.inst.r.rega_idx;
            end
            default: begin
              illegal = `TRUE;
              valid   = `FALSE;
            end
          endcase
        end

        `LDA_INST: begin
          opa_select   = ALU_OPA_IS_MEM_DISP;
          opb_select   = ALU_OPB_IS_REGB;
          func         = ALU_ADDQ;
          dest_idx     = F_decoder_out.inst.r.rega_idx;
          FU           = FU_LD;
        end

        // `LDAH_INST, `LDBU_INST, `LDQ_U_INST, `LDWU_INST, `STW_INST, `STB_INST, `STQ_U_INST, `LDF_INST, `LDG_INST, `LDS_INST, `LDT_INST, `STF_INST, `STG_INST, `STS_INST, `STT_INST, `LDL_INST: begin
        //   illegal = `TRUE;
        // end

        `INTA_GRP: begin
          opa_select   = ALU_OPA_IS_REGA;
          opb_select   = F_decoder_out.inst.i.IMM ? ALU_OPB_IS_ALU_IMM : ALU_OPB_IS_REGB;
          dest_idx     = F_decoder_out.inst.r.regc_idx;
          FU           = FU_ALU;
          rega_idx     = F_decoder_out.inst.r.rega_idx;
          regb_idx     = F_decoder_out.inst.i.IMM ? `ZERO_REG : F_decoder_out.inst.r.regb_idx;
          case (F_decoder_out.inst.i.func)
            `CMPULT_INST: func     = ALU_CMPULT;
            `ADDQ_INST:   func     = ALU_ADDQ;
            `SUBQ_INST:   func     = ALU_SUBQ;
            `CMPEQ_INST:  func     = ALU_CMPEQ;
            `CMPULE_INST: func     = ALU_CMPULE;
            `CMPLT_INST:  func     = ALU_CMPLT;
            `CMPLE_INST:  func     = ALU_CMPLE;
            default: begin
              illegal = `TRUE;
              valid   = `FALSE;
            end
          endcase // case(F_decoder_out.inst[11:5])
        end

        `INTL_GRP: begin
          opa_select   = ALU_OPA_IS_REGA;
          opb_select   = F_decoder_out.inst.i.IMM ? ALU_OPB_IS_ALU_IMM : ALU_OPB_IS_REGB;
          dest_idx     = F_decoder_out.inst.r.regc_idx;
          FU           = FU_ALU;
          rega_idx     = F_decoder_out.inst.r.rega_idx;
          regb_idx     = F_decoder_out.inst.i.IMM ? `ZERO_REG : F_decoder_out.inst.r.regb_idx;
          case (F_decoder_out.inst.i.func)
            `AND_INST:   func     = ALU_AND;
            `BIC_INST:   func     = ALU_BIC;
            `BIS_INST:   func     = ALU_BIS;
            `ORNOT_INST: func     = ALU_ORNOT;
            `XOR_INST:   func     = ALU_XOR;
            `EQV_INST:   func     = ALU_EQV;
            default: begin
              illegal = `TRUE;
              valid   = `FALSE;
            end
          endcase // case(F_decoder_out.inst[11:5])
        end

        `INTS_GRP: begin
          opa_select   = ALU_OPA_IS_REGA;
          opb_select   = F_decoder_out.inst.i.IMM ? ALU_OPB_IS_ALU_IMM : ALU_OPB_IS_REGB;
          dest_idx     = F_decoder_out.inst.r.regc_idx;
          FU           = FU_ALU;
          rega_idx     = F_decoder_out.inst.r.rega_idx;
          regb_idx     = F_decoder_out.inst.i.IMM ? `ZERO_REG : F_decoder_out.inst.r.regb_idx;
          case (F_decoder_out.inst.i.func)
            `SRL_INST: func     = ALU_SRL;
            `SLL_INST: func     = ALU_SLL;
            `SRA_INST: func     = ALU_SRA;
            default: begin
              illegal = `TRUE;
              valid   = `FALSE;
            end
          endcase // case(F_decoder_out.inst[11:5])
        end

        `INTM_GRP: begin
          opa_select = ALU_OPA_IS_REGA;
          opb_select = F_decoder_out.inst.i.IMM ? ALU_OPB_IS_ALU_IMM : ALU_OPB_IS_REGB;
          dest_idx   = F_decoder_out.inst.r.regc_idx;
          FU         = FU_MULT;
          rega_idx   = F_decoder_out.inst.r.rega_idx;
          regb_idx   = F_decoder_out.inst.i.IMM ? `ZERO_REG : F_decoder_out.inst.r.regb_idx;
          case (F_decoder_out.inst.i.func)
            `MULQ_INST: func     = ALU_MULQ;
            default: begin
              illegal = `TRUE;
              valid   = `FALSE;
            end
          endcase // case(F_decoder_out.inst[11:5])
        end

        // `ITFP_GRP, `FLTV_GRP, `FLTI_GRP, `FLTL_GRP, `MISC_GRP, `FTPI_GRP: begin
        //   illegal = `TRUE;       // unimplemented
        // end

        `LDQ_INST: begin
          opa_select   = ALU_OPA_IS_MEM_DISP;
          opb_select   = ALU_OPB_IS_REGB;
          func         = ALU_ADDQ;
          dest_idx     = F_decoder_out.inst.r.rega_idx;
          rd_mem       = `TRUE;
          FU           = FU_LD;
          rega_idx     = `ZERO_REG;
          regb_idx     = F_decoder_out.inst.r.regb_idx;
        end // case: `LDQ_INST

        // `LDL_L_INST, `STL_INST, `STL_C_INST: begin
        //   illegal = `TRUE;
        // end

        `LDQ_L_INST: begin
          opa_select   = ALU_OPA_IS_MEM_DISP;
          opb_select   = ALU_OPB_IS_REGB;
          func         = ALU_ADDQ;
          dest_idx     = F_decoder_out.inst.r.rega_idx;
          rd_mem       = `TRUE;
          ldl_mem      = `TRUE;
          FU           = FU_LD;
          rega_idx     = `ZERO_REG;
          regb_idx     = F_decoder_out.inst.r.regb_idx;
        end

        `STQ_INST: begin
          opa_select   = ALU_OPA_IS_MEM_DISP;
          opb_select   = ALU_OPB_IS_REGB;
          func         = ALU_ADDQ;
          wr_mem       = `TRUE;
          dest_idx     = `ZERO_REG;
          FU           = FU_ST;
          rega_idx     = `ZERO_REG;
          regb_idx     = F_decoder_out.inst.r.regb_idx;
        end

        `STQ_C_INST: begin
          opa_select   = ALU_OPA_IS_MEM_DISP;
          opb_select   = ALU_OPB_IS_REGB;
          func         = ALU_ADDQ;
          dest_idx = F_decoder_out.inst.r.rega_idx;
          wr_mem       = `TRUE;
          stc_mem      = `TRUE;
          FU           = FU_ST;
          rega_idx     = `ZERO_REG;
          regb_idx     = F_decoder_out.inst.r.regb_idx;
        end

        `BR_INST, `BSR_INST: begin
          dest_idx      = F_decoder_out.inst.r.rega_idx;
          uncond_branch = `TRUE;
          opa_select    = ALU_OPA_IS_NPC;
          opb_select    = ALU_OPB_IS_BR_DISP;
          func          = ALU_ADDQ;
          FU            = FU_ALU;
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
          rega_idx    = F_decoder_out.inst.r.rega_idx;
          regb_idx    = `ZERO_REG;
        end

        `JSR_GRP: begin
          // JMP, JSR, RET, and JSR_CO have identical semantics
          opa_select    = ALU_OPA_IS_NOT3;
          opb_select    = ALU_OPB_IS_REGB;
          func          = ALU_AND; // clear low 2 bits (word-align)
          dest_idx      = F_decoder_out.inst.r.rega_idx;
          uncond_branch = `TRUE;
          FU            = FU_BR;
          rega_idx      = `ZERO_REG;
          regb_idx      = F_decoder_out.inst.r.regb_idx;
        end

        default: begin
          illegal = `TRUE;
          valid   = `FALSE;
        end

      endcase
    end // if(~F_decoder_out.valid)
  end // always
   
endmodule // decoder
