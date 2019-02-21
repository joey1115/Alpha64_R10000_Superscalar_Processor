/////////////////////////////////////////////////////////////////////////
//                                                                     //
//   Modulename :  r_stage.v                                          //
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


module r_stage(
  input         clock,                // system clock
  input         reset,                // system reset
  input  C_R_PACKET   c_r_packet_in,

  output R_REG_PACKET r_packet_out
    // Always enabled if valid inst
);

endmodule // module r_stage

