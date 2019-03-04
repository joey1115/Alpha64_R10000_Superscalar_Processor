/////////////////////////////////////////////////////////////////////////
//                                                                     //
//                                                                     //
//   Modulename :  testbench_CT.v                                      //
//                                                                     //
//  Description :  Testbench module for CT module;                     //
//                                                                     //
//                                                                     //
/////////////////////////////////////////////////////////////////////////

`timescale 1ns/100ps

`include "../../sys_defs.vh"
`include "CT.vh"

module test_CT;

  // DUT input stimulus
  logic en, clock, reset;
  CT_PACKET_IN ct_packet_in;

  // DUT output
  CT_PACKET_OUT ct_packet_out;

  // DUT instantiation
  CT UUT(
    .en(en),
    .clock(clock),
    .reset(reset),
    .ct_packet_in(ct_packet_in),
    .ct_packet_out(ct_packet_out)
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
    ct_packet_in = 0;

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

endmodule  // module test_ROB

