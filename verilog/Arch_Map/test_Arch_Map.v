】/////////////////////////////////////////////////////////////////////////
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
  // ARCH_MAP_PACKET_OUT arch_map_packet_out;

  // DUT instantiation
  Arch_Map UUT(
    .en(en),
    .clock(clock),
    .reset(reset),
    .arch_map_packet_in(arch_map_packet_in),
    .arch_map(arch_map)
  );

  logic [31:0] cycle_count;
  ARCH_MAP_t [31:0] test_result;
  ARCH_MAP_PACKET_IN test;

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

  task check;
    input ARCH_MAP_t [31:0] prior_output;
    input ARCH_MAP_PACKET_IN current_input;
    input ARCH_MAP_t [31:0] current_output;
    for ()
  endtask




  initial begin

    //***** Test Case #1 *****//
    // test{retire signal, T_old from ROB, T from ROB}
    test[0] = '{0,  0, 32}; // retire signal = 0, no changes
    test[1] = '{0,  1, 35};
    test[2] = '{0,  2, 39};
    test[3] = '{0, 31, 49};
    test[4] = '{0, 32, 44};
    test[5] = '{0, 63, 60};

    test[6] = '{1,  0, 32}; // retire signal = 1, make changes
    test[7] = '{1, 32, 34};
    test[8] = '{1, 34, 63};
    test[9] = '{1, 33, 35};


    en = 1'b1;
    clock = 1'b0;
    reset = 1'b0;
    @(negedge clock);
    reset = 1'b1;
    @(negedge clock);
    reset = 1'b0;
    $display("@@@Let's begin testbench!!!!!!!!!!!!!!!!!!");
    
    // Cycle 0
    @(negedge clock);
    arch_map_packet_in = test[0];
    test_result = arch_map;
    check()


    @(negedge clock);
    @(negedge clock);
    @(negedge clock);

    $finish;

  end // initial

endmodule  // module test_Arch_Map

