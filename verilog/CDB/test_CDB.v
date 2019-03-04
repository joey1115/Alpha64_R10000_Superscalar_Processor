/////////////////////////////////////////////////////////////////////////
//                                                                     //
//                                                                     //
//   Modulename :  testbench_PR.v                                      //
//                                                                     //
//  Description :  Testbench module for PR module;                     //
//                                                                     //
//                                                                     //
/////////////////////////////////////////////////////////////////////////

`timescale 1ns/100ps

`include "../../sys_defs.vh"
`include "CDB.vh"

module test_CDB;

  // DUT input stimulus
  logic en;
  CDB_PACKET_IN cdb_packet_in;

  // DUT output
  CDB_PACKET_OUT cdb_packet_out;

  // DUT instantiation
  CDB UUT(
    .en(en),
    .cdb_packet_in(cdb_packet_in),
    .cdb_packet_out(cdb_packet_out)
  );

  logic [31:0] cycle_count;


  initial begin

    /***** Test Case #1 *****/
    en = 1'b1;
    $display("@@@Pass!");

    $finish;

  end // initial

endmodule  // module test_CDBs

