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

  // Generate System Clock
  always begin
    #(`VERILOG_CLOCK_PERIOD/2.0);
    clock = ~clock;
  end

  // Update cycle count
  always @(posedge clock) begin
    if(reset)
      cycle_count <= `SD 0;
    else
      cycle_count <= `SD (cycle_count + 1);
  end


  initial begin

    /***** Test Case #1 *****/


    // Reset
    en    = 1'b1;
    clock = 1'b0;
    reset = 1'b0;

    @(negedge clock);
    reset = 1'b1;
    
    // Cycle 0
    @(negedge clock);
    reset = 1'b0;
    $display("@@@Pass!");

    @(negedge clock);
    @(negedge clock);
    @(negedge clock);

    $finish;

  end // initial

endmodule  // module testbench_PR

