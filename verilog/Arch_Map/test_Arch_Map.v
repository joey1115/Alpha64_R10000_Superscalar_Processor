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
`include "Arch_Map.vh"

module test_Arch_Map;

  // DUT input stimulus
  logic en, clock, reset;
  ARCH_MAP_PACKET_IN arch_map_packet_in;

  // DUT output
  ARCH_MAP_PACKET_OUT arch_map_packet_out;

  // DUT instantiation
  Arch_Map UUT(
    .en(en),
    .clock(clock),
    .reset(reset),
    .arch_map_packet_in(arch_map_packet_in),
    .arch_map_packet_out(arch_map_packet_out)
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
    en = 1'b1;
    clock = 1'b0;
    reset = 1'b0;
    @(negedge clock);
    reset = 1'b0;
    $display("@@@Pass!!!!!!!!!!!!!!!!!!");

    @(negedge clock);
    @(negedge clock);
    @(negedge clock);

    $finish;

  end // initial

endmodule  // module test_Arch_Map

