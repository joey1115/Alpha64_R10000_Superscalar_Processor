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


  // Decode an instruction: given instruction bits IR produce the
  // appropriate datapath control signals.
  //
  // This is a *combinational* module (basically a PLA).
  //
module decoder(
  input  F_D_PACKET         decoder_packet_in,
  output DECODER_PACKET_OUT decoder_packet_out
);

  always_comb begin
    // default control values:
    // - valid instructions must override these defaults as necessary.
    //   decoder_packet_out.opa_select, decoder_packet_out.opb_select, and decoder_packet_out.func     should be set explicitly.
    // - invalid instructions should clear decoder_packet_out.valid_inst.
    // - These defaults are equivalent to a noop
    // * see sys_defs.vh for the constants used here
    decoder_packet_out = `DECODER_PACKET_OUT_DEFAULT;
    if(decoder_packet_in.valid) begin
      decoder_packet_out.valid = `TRUE;
      case(decoder_packet_in.inst.m.opcode)
        `PAL_INST: begin
          case (decoder_packet_in.inst.p.func)
            `PAL_HALT: begin
              decoder_packet_out.halt = `TRUE;
            end
            `PAL_WHAMI: begin
              decoder_packet_out.cpuid        = `TRUE;
              decoder_packet_out.dest_reg_idx = decoder_packet_in.inst.r.rega_idx;
            end
            default: begin
              decoder_packet_out.illegal = `TRUE;
              decoder_packet_out.valid   = `FALSE;
            end
          endcase
        end

        `LDA_INST: begin
          decoder_packet_out.opa_select   = ALU_OPA_IS_MEM_DISP;
          decoder_packet_out.opb_select   = ALU_OPB_IS_REGB;
          decoder_packet_out.func         = ALU_ADDQ;
          decoder_packet_out.dest_reg_idx = decoder_packet_in.inst.r.rega_idx;
          decoder_packet_out.FU           = FU_LD;
        end

        // `LDAH_INST, `LDBU_INST, `LDQ_U_INST, `LDWU_INST, `STW_INST, `STB_INST, `STQ_U_INST, `LDF_INST, `LDG_INST, `LDS_INST, `LDT_INST, `STF_INST, `STG_INST, `STS_INST, `STT_INST, `LDL_INST: begin
        //   decoder_packet_out.illegal = `TRUE;
        // end

        `INTA_GRP: begin
          decoder_packet_out.opa_select   = ALU_OPA_IS_REGA;
          decoder_packet_out.opb_select   = decoder_packet_in.inst.i.IMM ? ALU_OPB_IS_ALU_IMM : ALU_OPB_IS_REGB;
          decoder_packet_out.dest_reg_idx = decoder_packet_in.inst.r.regc_idx;
          decoder_packet_out.FU           = FU_ALU;
          case (decoder_packet_in.inst.i.func)
            `CMPULT_INST: decoder_packet_out.func     = ALU_CMPULT;
            `ADDQ_INST:   decoder_packet_out.func     = ALU_ADDQ;
            `SUBQ_INST:   decoder_packet_out.func     = ALU_SUBQ;
            `CMPEQ_INST:  decoder_packet_out.func     = ALU_CMPEQ;
            `CMPULE_INST: decoder_packet_out.func     = ALU_CMPULE;
            `CMPLT_INST:  decoder_packet_out.func     = ALU_CMPLT;
            `CMPLE_INST:  decoder_packet_out.func     = ALU_CMPLE;
            default: begin
              decoder_packet_out.illegal = `TRUE;
              decoder_packet_out.valid   = `FALSE;
            end
          endcase // case(decoder_packet_in.inst[11:5])
        end

        `INTL_GRP: begin
          decoder_packet_out.opa_select   = ALU_OPA_IS_REGA;
          decoder_packet_out.opb_select   = decoder_packet_in.inst.i.IMM ? ALU_OPB_IS_ALU_IMM : ALU_OPB_IS_REGB;
          decoder_packet_out.dest_reg_idx = decoder_packet_in.inst.r.regc_idx;
          decoder_packet_out.FU           = FU_ALU;
          case (decoder_packet_in.inst.i.func)
            `AND_INST:   decoder_packet_out.func     = ALU_AND;
            `BIC_INST:   decoder_packet_out.func     = ALU_BIC;
            `BIS_INST:   decoder_packet_out.func     = ALU_BIS;
            `ORNOT_INST: decoder_packet_out.func     = ALU_ORNOT;
            `XOR_INST:   decoder_packet_out.func     = ALU_XOR;
            `EQV_INST:   decoder_packet_out.func     = ALU_EQV;
            default: begin
              decoder_packet_out.illegal = `TRUE;
              decoder_packet_out.valid   = `FALSE;
            end
          endcase // case(decoder_packet_in.inst[11:5])
        end

        `INTS_GRP: begin
          decoder_packet_out.opa_select   = ALU_OPA_IS_REGA;
          decoder_packet_out.opb_select   = decoder_packet_in.inst.i.IMM ? ALU_OPB_IS_ALU_IMM : ALU_OPB_IS_REGB;
          decoder_packet_out.dest_reg_idx = decoder_packet_in.inst.r.regc_idx;
          decoder_packet_out.FU           = FU_ALU;
          case (decoder_packet_in.inst.i.func)
            `SRL_INST: decoder_packet_out.func     = ALU_SRL;
            `SLL_INST: decoder_packet_out.func     = ALU_SLL;
            `SRA_INST: decoder_packet_out.func     = ALU_SRA;
            default: begin
              decoder_packet_out.illegal = `TRUE;
              decoder_packet_out.valid   = `FALSE;
            end
          endcase // case(decoder_packet_in.inst[11:5])
        end

        `INTM_GRP: begin
          decoder_packet_out.opa_select = ALU_OPA_IS_REGA;
          decoder_packet_out.opb_select = decoder_packet_in.inst.i.IMM ? ALU_OPB_IS_ALU_IMM : ALU_OPB_IS_REGB;
          decoder_packet_out.dest_reg_idx = decoder_packet_in.inst.r.regc_idx;
          decoder_packet_out.FU           = FU_ALU;
          case (decoder_packet_in.inst.i.func)
            `MULQ_INST: decoder_packet_out.func     = ALU_MULQ;
            default: begin
              decoder_packet_out.illegal = `TRUE;
              decoder_packet_out.valid   = `FALSE;
            end
          endcase // case(decoder_packet_in.inst[11:5])
        end

        // `ITFP_GRP, `FLTV_GRP, `FLTI_GRP, `FLTL_GRP, `MISC_GRP, `FTPI_GRP: begin
        //   decoder_packet_out.illegal = `TRUE;       // unimplemented
        // end

        `LDQ_INST: begin
          decoder_packet_out.opa_select   = ALU_OPA_IS_MEM_DISP;
          decoder_packet_out.opb_select   = ALU_OPB_IS_REGB;
          decoder_packet_out.func         = ALU_ADDQ;
          decoder_packet_out.dest_reg_idx = decoder_packet_in.inst.r.rega_idx;
          decoder_packet_out.rd_mem       = `TRUE;
          decoder_packet_out.FU           = FU_LD;
        end // case: `LDQ_INST

        // `LDL_L_INST, `STL_INST, `STL_C_INST: begin
        //   decoder_packet_out.illegal = `TRUE;
        // end

        `LDQ_L_INST: begin
          decoder_packet_out.opa_select   = ALU_OPA_IS_MEM_DISP;
          decoder_packet_out.opb_select   = ALU_OPB_IS_REGB;
          decoder_packet_out.func         = ALU_ADDQ;
          decoder_packet_out.dest_reg_idx = decoder_packet_in.inst.r.rega_idx;
          decoder_packet_out.rd_mem       = `TRUE;
          decoder_packet_out.ldl_mem      = `TRUE;
          decoder_packet_out.FU           = FU_LD;
        end

        `STQ_INST: begin
          decoder_packet_out.opa_select   = ALU_OPA_IS_MEM_DISP;
          decoder_packet_out.opb_select   = ALU_OPB_IS_REGB;
          decoder_packet_out.func         = ALU_ADDQ;
          decoder_packet_out.wr_mem       = `TRUE;
          decoder_packet_out.dest_reg_idx = `ZERO_REG;
          decoder_packet_out.FU           = FU_ST;
        end

        `STQ_C_INST: begin
          decoder_packet_out.opa_select   = ALU_OPA_IS_MEM_DISP;
          decoder_packet_out.opb_select   = ALU_OPB_IS_REGB;
          decoder_packet_out.func         = ALU_ADDQ;
          decoder_packet_out.dest_reg_idx = decoder_packet_in.inst.r.rega_idx;
          decoder_packet_out.wr_mem       = `TRUE;
          decoder_packet_out.stc_mem      = `TRUE;
          decoder_packet_out.FU           = FU_ST;
        end

        `BR_INST, `BSR_INST: begin
          decoder_packet_out.dest_reg_idx  = decoder_packet_in.inst.r.rega_idx;
          decoder_packet_out.uncond_branch = `TRUE;
          decoder_packet_out.opa_select    = ALU_OPA_IS_NPC;
          decoder_packet_out.opb_select    = ALU_OPB_IS_BR_DISP;
          decoder_packet_out.func          = ALU_ADDQ;
          decoder_packet_out.FU            = FU_ALU;
        end

        // `FBEQ_INST, `FBLT_INST, `FBLE_INST, `FBNE_INST, `FBGE_INST, `FBGT_INST: begin
        //   decoder_packet_out.illegal = `TRUE;
        // end

        `BLBC_INST, `BEQ_INST, `BLT_INST, `BLE_INST, `BLBS_INST, `BNE_INST, `BGE_INST, `BGT_INST: begin
          decoder_packet_out.opa_select  = ALU_OPA_IS_NPC;
          decoder_packet_out.opb_select  = ALU_OPB_IS_BR_DISP;
          decoder_packet_out.func        = ALU_ADDQ;
          decoder_packet_out.cond_branch = `TRUE; // all others are conditional
          decoder_packet_out.FU          = FU_BR;
        end

        `JSR_GRP: begin
          // JMP, JSR, RET, and JSR_CO have identical semantics
          decoder_packet_out.opa_select    = ALU_OPA_IS_NOT3;
          decoder_packet_out.opb_select    = ALU_OPB_IS_REGB;
          decoder_packet_out.func          = ALU_AND; // clear low 2 bits (word-align)
          decoder_packet_out.dest_reg_idx  = decoder_packet_in.inst.r.rega_idx;
          decoder_packet_out.uncond_branch = `TRUE;
          decoder_packet_out.FU            = FU_BR;
        end

        default: begin
          decoder_packet_out.illegal = `TRUE;
          decoder_packet_out.valid   = `FALSE;
        end

      endcase
    end // if(~decoder_packet_in.valid)
  end // always
   
endmodule // decoder
