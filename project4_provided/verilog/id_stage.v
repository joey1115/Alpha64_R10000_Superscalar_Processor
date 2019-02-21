/////////////////////////////////////////////////////////////////////////
//                                                                     //
//   Modulename :  d_stage.v                                          //
//                                                                     //
//  Description :  instruction decode (ID) stage of the pipeline;      // 
//                 decode the instruction fetch register operands, and // 
//                 compute immediate operand (if applicable)           // 
//                                                                     //
/////////////////////////////////////////////////////////////////////////


`timescale 1ns/100ps


  // Decode an instruction: given instruction bits IR produce the
  // appropriate datapath control signals.
  //
  // This is a *combinational* module (basically a PLA).
  //
module decoder(
  input [31:0] inst,
  input valid_inst_in,  // ignore inst when low, outputs will
                        // reflect noop (except valid_inst)
  output ALU_OPA_SELECT opa_select,
  output ALU_OPB_SELECT opb_select,
  output DEST_REG_SEL   dest_reg, // mux selects
  output ALU_FUNC       alu_func,
  output logic rd_mem, wr_mem, ldl_mem, stc_mem, cond_branch, uncond_branch,
  output logic halt,      // non-zero on a halt
  output logic cpuid,     // get CPUID instruction
  output logic illegal,   // non-zero on an illegal instruction
  output logic valid_inst // for counting valid instructions executed
                          // and for making the fetch stage die on halts/
                          // keeping track of when to allow the next
                          // instruction out of fetch
                          // 0 for HALT and illegal instructions (die on halt)
);

  assign valid_inst = valid_inst_in && !illegal;

  always_comb begin
    // default control values:
    // - valid instructions must override these defaults as necessary.
    //   opa_select, opb_select, and alu_func should be set explicitly.
    // - invalid instructions should clear valid_inst.
    // - These defaults are equivalent to a noop
    // * see sys_defs.vh for the constants used here
    opa_select = ALU_OPA_IS_REGA;
    opb_select = ALU_OPB_IS_REGB;
    alu_func = ALU_ADDQ;
    dest_reg = DEST_NONE;
    rd_mem = `FALSE;
    wr_mem = `FALSE;
    ldl_mem = `FALSE;
    stc_mem = `FALSE;
    cond_branch = `FALSE;
    uncond_branch = `FALSE;
    halt = `FALSE;
    cpuid = `FALSE;
    illegal = `FALSE;
    if(valid_inst_in) begin
      case ({inst[31:29], 3'b0})
        6'h0:
          case (inst[31:26])
            `PAL_INST: begin
              if (inst[25:0] == `PAL_HALT)
                halt = `TRUE;
              else if (inst[25:0] == `PAL_WHAMI) begin
                cpuid = `TRUE;
                dest_reg = DEST_IS_REGA;   // get cpuid writes to r0
              end else
                illegal = `TRUE;
              end
            default: illegal = `TRUE;
          endcase // case(inst[31:26])
       
        6'h10:
        begin
          opa_select = ALU_OPA_IS_REGA;
          opb_select = inst[12] ? ALU_OPB_IS_ALU_IMM : ALU_OPB_IS_REGB;
          dest_reg = DEST_IS_REGC;
          case (inst[31:26])
            `INTA_GRP:
              case (inst[11:5])
                `CMPULT_INST:  alu_func = ALU_CMPULT;
                `ADDQ_INST:    alu_func = ALU_ADDQ;
                `SUBQ_INST:    alu_func = ALU_SUBQ;
                `CMPEQ_INST:   alu_func = ALU_CMPEQ;
                `CMPULE_INST:  alu_func = ALU_CMPULE;
                `CMPLT_INST:   alu_func = ALU_CMPLT;
                `CMPLE_INST:   alu_func = ALU_CMPLE;
                default:        illegal = `TRUE;
              endcase // case(inst[11:5])
            `INTL_GRP:
              case (inst[11:5])
                `AND_INST:    alu_func = ALU_AND;
                `BIC_INST:    alu_func = ALU_BIC;
                `BIS_INST:    alu_func = ALU_BIS;
                `ORNOT_INST:  alu_func = ALU_ORNOT;
                `XOR_INST:    alu_func = ALU_XOR;
                `EQV_INST:    alu_func = ALU_EQV;
                default:       illegal = `TRUE;
              endcase // case(inst[11:5])
            `INTS_GRP:
              case (inst[11:5])
                `SRL_INST:  alu_func = ALU_SRL;
                `SLL_INST:  alu_func = ALU_SLL;
                `SRA_INST:  alu_func = ALU_SRA;
                default:    illegal = `TRUE;
              endcase // case(inst[11:5])
            `INTM_GRP:
              case (inst[11:5])
                `MULQ_INST:       alu_func = ALU_MULQ;
                default:          illegal = `TRUE;
              endcase // case(inst[11:5])
            `ITFP_GRP:       illegal = `TRUE;       // unimplemented
            `FLTV_GRP:       illegal = `TRUE;       // unimplemented
            `FLTI_GRP:       illegal = `TRUE;       // unimplemented
            `FLTL_GRP:       illegal = `TRUE;       // unimplemented
          endcase // case(inst[31:26])
        end
           
        6'h18:
          case (inst[31:26])
            `MISC_GRP:       illegal = `TRUE; // unimplemented
            `JSR_GRP:
            begin
              // JMP, JSR, RET, and JSR_CO have identical semantics
              opa_select = ALU_OPA_IS_NOT3;
              opb_select = ALU_OPB_IS_REGB;
              alu_func = ALU_AND; // clear low 2 bits (word-align)
              dest_reg = DEST_IS_REGA;
              uncond_branch = `TRUE;
            end
            `FTPI_GRP:       illegal = `TRUE;       // unimplemented
          endcase // case(inst[31:26])
           
        6'h08, 6'h20, 6'h28:
        begin
          opa_select = ALU_OPA_IS_MEM_DISP;
          opb_select = ALU_OPB_IS_REGB;
          alu_func = ALU_ADDQ;
          dest_reg = DEST_IS_REGA;
          case (inst[31:26])
            `LDA_INST:  /* defaults are OK */;
            `LDQ_INST:
            begin
              rd_mem = `TRUE;
              dest_reg = DEST_IS_REGA;
            end // case: `LDQ_INST
            `LDQ_L_INST:
              begin
              rd_mem = `TRUE;
              ldl_mem = `TRUE;
              dest_reg = DEST_IS_REGA;
            end // case: `LDQ_L_INST
            `STQ_INST:
            begin
              wr_mem = `TRUE;
              dest_reg = DEST_NONE;
            end // case: `STQ_INST
            `STQ_C_INST:
            begin
              wr_mem = `TRUE;
              stc_mem = `TRUE;
              dest_reg = DEST_IS_REGA;
            end // case: `STQ_INST
            default:       illegal = `TRUE;
          endcase // case(inst[31:26])
        end
           
        6'h30, 6'h38:
        begin
          opa_select = ALU_OPA_IS_NPC;
          opb_select = ALU_OPB_IS_BR_DISP;
          alu_func = ALU_ADDQ;
          case (inst[31:26])
            `FBEQ_INST, `FBLT_INST, `FBLE_INST,
            `FBNE_INST, `FBGE_INST, `FBGT_INST:
            begin
              // FP conditionals not implemented
              illegal = `TRUE;
            end

            `BR_INST, `BSR_INST:
            begin
              dest_reg = DEST_IS_REGA;
              uncond_branch = `TRUE;
            end

            default:
              cond_branch = `TRUE; // all others are conditional
          endcase // case(inst[31:26])
        end
      endcase // case(inst[31:29] << 3)
    end // if(~valid_inst_in)
  end // always
   
endmodule // decoder

module d_stage(
  input         clock,                // system clock
  input         reset,                // system reset
  input R_REG_PACKET r_packet_in,
  input F_D_PACKET f_d_packet_in,
  output S_X_PACKET s_packet_out
);

  assign s_packet_out.NPC = f_d_packet_in.NPC;
  assign s_packet_out.inst = f_d_packet_in.inst;

  DEST_REG_SEL dest_reg_select;

  // instruction fields read from IF/ID pipeline register
  wire    [4:0] ra_idx = f_d_packet_in.inst[25:21];   // inst operand A register index
  wire    [4:0] rb_idx = f_d_packet_in.inst[20:16];   // inst operand B register index
  wire    [4:0] rc_idx = f_d_packet_in.inst[4:0];     // inst operand C register index

  // Instantiate the register file used by this pipeline
  regfile regf_0 (
    .rda_idx(ra_idx),
    .rda_out(s_packet_out.rega_value), 
    .rdb_idx(rb_idx),
    .rdb_out(s_packet_out.regb_value),
    .wr_clk(clock),
    .wr_en(r_packet_in.wr_en),
    .wr_idx(r_packet_in.wr_idx),
    .wr_data(r_packet_in.wr_data)
  );

  // instantiate the instruction decoder
  decoder decoder_0 (
    // Input
    .inst(f_d_packet_in.inst),
    .valid_inst_in(f_d_packet_in.valid),
    // Outputs
    .opa_select(s_packet_out.opa_select),
    .opb_select(s_packet_out.opb_select),
    .alu_func(s_packet_out.alu_func),
    .dest_reg(dest_reg_select),
    .rd_mem(s_packet_out.rd_mem),
    .wr_mem(s_packet_out.wr_mem),
    .ldl_mem(s_packet_out.ldl_mem),
    .stc_mem(s_packet_out.stc_mem),
    .cond_branch(s_packet_out.cond_branch),
    .uncond_branch(s_packet_out.uncond_branch),
    .halt(s_packet_out.halt),
    .cpuid(s_packet_out.cpuid),
    .illegal(s_packet_out.illegal),
    .valid_inst(s_packet_out.valid)
  );

  // mux to generate dest_reg_idx based on
  // the dest_reg_select output from decoder
  always_comb begin
    case (dest_reg_select)
      DEST_IS_REGC: s_packet_out.dest_reg_idx = rc_idx;
      DEST_IS_REGA: s_packet_out.dest_reg_idx = ra_idx;
      DEST_NONE:    s_packet_out.dest_reg_idx = `ZERO_REG;
      default:      s_packet_out.dest_reg_idx = `ZERO_REG; 
    endcase
  end
   
endmodule // module d_stage
