/////////////////////////////////////////////////////////////////////////
//                                                                     //
//                                                                     //
//   Modulename :  testbench_ROB.v                                     //
//                                                                     //
//  Description :  Testbench module for ROB module;                    //
//                                                                     //
//                                                                     //
/////////////////////////////////////////////////////////////////////////

`timescale 1ns/100ps

`include "sys_defs.vh"

module testbench_ROB;

  // DUT input stimulus
  logic en, clock, reset;
  ROB_PACKET_IN rob_packet_in;

  // DUT output
  ROB_PACKET_OUT rob_packet_out;

  // DUT instantiation
  rob_m DUT(
    .en(en),
    .clock(clock),
    .reset(reset),
    .rob_packet_in(rob_packet_in),
    .rob_packet_out(rob_packet_out)
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
    $monitor("Time:%4.0f", $time);
    // Reset
    en    = 1'b1;
    clock = 1'b0;
    reset = 1'b1;

    // Load initial line

    // Test begins
    @(negedge clock);
    reset = 1'b0;

    @(negedge clock);
    $display("Try and it worked");
    $finish;

  end // initial

endmodule  // module testbench_ROB

