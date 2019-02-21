// /////////////////////////////////////////////////////////////////////////
// //                                                                     //
// //   Modulename :  s_stage.v                                           //
// //                                                                     //
// //  Description :  instruction decode (ID) stage of the pipeline;      // 
// //                 decode the instruction fetch register operands, and // 
// //                 compute immediate operand (if applicable)           // 
// //                                                                     //
// /////////////////////////////////////////////////////////////////////////


`timescale 1ns/100ps

module s_stage(
  input                clock,                // system clock
  input                reset,                // system reset
  input  D_S_PACKET  d_s_packet_in,
  output S_X_PACKET  s_packet_out
);

endmodule // module d_stage
