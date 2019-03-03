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
`include "PR.vh"

module test_PR;

  // DUT input stimulus
  logic en, clock, reset;
  PR_PACKET_IN pr_packet_in;

  // DUT output
  PR_PACKET_OUT pr_packet_out;

  // DUT instantiation
  PR UUT(
    .en(en),
    .clock(clock),
    .reset(reset),
    .pr_packet_in(pr_packet_in),
    .pr_packet_out(pr_packet_out)
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

