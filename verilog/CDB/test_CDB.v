/////////////////////////////////////////////////////////////////////////
//                                                                     //
//                                                                     //
//   Modulename :  testbench_CDB.v                                     //
//                                                                     //
//  Description :  Testbench module for CDB module;                    //
//                                                                     //
//                                                                     //
/////////////////////////////////////////////////////////////////////////

`timescale 1ns/100ps

`include "../../sys_defs.vh"
`include "CDB.vh"

module test_CDB;

  // ********* UUT Setup *********
  // UUT input
  logic en, clock, reset;
  CDB_PACKET_IN uut_in;
  // UUT output
  CDB_PACKET_OUT uut_out;
  CDB_entry_t [`NUM_FU-1:0] uut_data;

  // DUT instantiation
  CDB UUT(
    .en(en),
    .clock(clock),
    .reset(reset),
    .CDB_packet_in(uut_in),
    .CDB_packet_out(uut_out),
    .CDB(uut_data)
  );

  logic [31:0] cycle_count;

  // Test Cases Define

  // Check Sol task

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

    $display("@@@Pass!!!!!!!!!!!!!!!!!!!!!!!!!");
    /***** Test Case #1 *****/
    // Reset
    en    = 1'b1;
    clock = 1'b0;
    reset = 1'b0;
    uut_in = 0;

    @(negedge clock);
    reset = 1'b1;
    
    // Cycle 0
    @(negedge clock);
    reset = 1'b0;

    @(negedge clock);
    @(negedge clock);
    @(negedge clock);

    $finish;

  end // initial

endmodule  // module test_CDB

