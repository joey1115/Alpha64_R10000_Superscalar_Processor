/////////////////////////////////////////////////////////////////////////
//                                                                     //
//   Modulename :  wb_stage.v                                          //
//                                                                     //
//  Description :   writeback (WB) stage of the pipeline;              //
//                  determine the destination register of the          //
//                  instruction and write the result to the register   //
//                  file (if not to the zero register), also reset the //
//                  NPC in the fetch stage to the correct next PC      //
//                  address.                                           // 
//                                                                     //
//                                                                     //
/////////////////////////////////////////////////////////////////////////

`timescale 1ns/100ps


module wb_stage(
  input         clock,                // system clock
  input         reset,                // system reset
  input C_R_PACKET c_r_packet_in,

  output R_REG_PACKET r_packet_out
    // Always enabled if valid inst
);

  wire   [63:0] result_mux;

  // Mux to select register writeback data:
  // ALU/MEM result, unless taken branch, in which case we write
  // back the old NPC as the return address.  Note that ALL branches
  // and jumps write back the 'link' value, but those that don't
  // want it specify ZERO_REG as the destination.
  assign result_mux = (c_r_packet_in.take_branch) ? c_r_packet_in.NPC : c_r_packet_in.result;

  // Generate signals for write-back to register file
  // r_packet_out.wr_en computation is sort of overkill since the reg file
  // has a special way of handling `ZERO_REG but there is no harm 
  // in putting this here.  Hopefully it illustrates how the pipeline works.
  assign r_packet_out.wr_en  = c_r_packet_in.dest_reg_idx != `ZERO_REG;
  assign r_packet_out.wr_idx = c_r_packet_in.dest_reg_idx;
  assign r_packet_out.wr_data = result_mux;

endmodule // module wb_stage

