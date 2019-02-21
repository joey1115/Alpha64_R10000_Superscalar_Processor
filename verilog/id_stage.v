// /////////////////////////////////////////////////////////////////////////
// //                                                                     //
// //   Modulename :  id_stage.v                                          //
// //                                                                     //
// //  Description :  instruction decode (ID) stage of the pipeline;      // 
// //                 decode the instruction fetch register operands, and // 
// //                 compute immediate operand (if applicable)           // 
// //                                                                     //
// /////////////////////////////////////////////////////////////////////////


`timescale 1ns/100ps

module id_stage(
  input                clock,                // system clock
  input                reset,                // system reset
  input  R_REG_PACKET r_packet_in,
  input  F_D_PACKET  f_d_packet_in,
  output S_X_PACKET  s_packet_out
);
  DECODER_PACKET_OUT decoder_packet_out;
  DECODER_PACKET_IN  decoder_packet_in;

  assign decoder_packet_in.inst  = f_d_packet_in.inst;
  assign decoder_packet_in.valid = f_d_packet_in.valid;

  assign s_packet_out.NPC           = f_d_packet_in.NPC;
  assign s_packet_out.inst          = f_d_packet_in.inst;
  assign s_packet_out.opa_select    = decoder_packet_out.opa_select;
  assign s_packet_out.opb_select    = decoder_packet_out.opb_select;
  assign s_packet_out.alu_func      = decoder_packet_out.alu_func;
  assign s_packet_out.rd_mem        = decoder_packet_out.rd_mem;
  assign s_packet_out.wr_mem        = decoder_packet_out.wr_mem;
  assign s_packet_out.ldl_mem       = decoder_packet_out.ldl_mem;
  assign s_packet_out.stc_mem       = decoder_packet_out.stc_mem;
  assign s_packet_out.cond_branch   = decoder_packet_out.cond_branch;
  assign s_packet_out.uncond_branch = decoder_packet_out.uncond_branch;
  assign s_packet_out.halt          = decoder_packet_out.halt;
  assign s_packet_out.cpuid         = decoder_packet_out.cpuid;
  assign s_packet_out.illegal       = decoder_packet_out.illegal;
  assign s_packet_out.valid         = decoder_packet_out.valid;
  assign s_packet_out.dest_reg_idx  = decoder_packet_out.dest_reg_idx;

  // Instantiate the register file used by this pipeline
  regfile regf_0 (
    .rda_idx(f_d_packet_in.inst.r.rega_idx),
    .rdb_idx(f_d_packet_in.inst.r.regb_idx),
    .wr_idx(r_packet_in.wr_idx),
    .wr_data(r_packet_in.wr_data),
    .wr_en(r_packet_in.wr_en),
    .wr_clk(clock),
    .rda_out(s_packet_out.rega_value), 
    .rdb_out(s_packet_out.regb_value)
  );

  // instantiate the instruction decoder
  decoder decoder_0 (
    .decoder_packet_in(decoder_packet_in),
    .decoder_packet_out(decoder_packet_out)
  );
endmodule // module id_stage
