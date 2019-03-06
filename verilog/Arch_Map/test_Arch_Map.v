/////////////////////////////////////////////////////////////////////////
//                                                                     //
//                                                                     //
//   Modulename :  testbench_Arch_Map.v                                //
//                                                                     //
//  Description :  Testbench module for Arch_Map module;               //
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
  logic check_signal;

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
    if (current_input.en == 0) begin
      if (prior_output == current_output) begin
        $display("@@@Passed!!!!No retire signal!!!!");
      end else begin
        $display("@@@Wrong answer!!!!Shouldn't change arch_map when no retire signal");
        $finish;
      end // else
    end else begin
      check_signal = 0;
      for (int i=0; i<31; i++) begin
        if (prior_output[i].PR_idx == current_input.Rob_retire_Told) begin
          check_signal = i;
          break;
        end // if 
      end
      if (check_signal == 0) begin
        if (prior_output == current_output) begin
          $display("@@@Passed!!!!Told has not been used before, no changes!!!!");
        end else begin
          $display("@@@Wrong answer!!!!Shouldn't change arch_map when Told has not been used before");
          $finish;
        end // else
      end else begin
        if (current_output[check_signal].PR_idx == current_input.Rob_retire_T) begin
          $display("@@@Passed!!!!");
        end else begin
          $display("@@@Wrong answer!!!!");
        end // else
      end // else
    end // else
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
    $display("Cycle %d",cycle_count);
    arch_map_packet_in = test[0];
    test_result = arch_map;
    check(test_result, test[0], test_result);
    
    @(negedge clock);
    // Cycle 1
    $display("Cycle %d",cycle_count);
    arch_map_packet_in = test[1];
    check(test_result, test[1], arch_map);
    test_result = arch_map;

    @(negedge clock);
    // Cycle 2
    $display("Cycle %d",cycle_count);
    arch_map_packet_in = test[2];
    check(test_result, test[2], arch_map);
    test_result = arch_map;

    @(negedge clock);
    // Cycle 3
    $display("Cycle %d",cycle_count);
    arch_map_packet_in = test[3];
    check(test_result, test[23, arch_map);
    test_result = arch_map;

    @(negedge clock);
    // Cycle 4
    $display("Cycle %d",cycle_count);
    arch_map_packet_in = test[4];
    check(test_result, test[4], arch_map);
    test_result = arch_map;

    @(negedge clock);
    // Cycle 5
    $display("Cycle %d",cycle_count);
    arch_map_packet_in = test[5];
    check(test_result, test[5], arch_map);
    test_result = arch_map;

    @(negedge clock);
    // Cycle 6
    $display("Cycle %d",cycle_count);
    arch_map_packet_in = test[6];
    check(test_result, test[6], arch_map);
    test_result = arch_map;

    @(negedge clock);
    // Cycle 7
    $display("Cycle %d",cycle_count);
    arch_map_packet_in = test[7];
    check(test_result, test[7], arch_map);
    test_result = arch_map;

    @(negedge clock);
    // Cycle 8
    $display("Cycle %d",cycle_count);
    arch_map_packet_in = test[8];
    check(test_result, test[8], arch_map);
    test_result = arch_map;

    @(negedge clock);
    // Cycle 9
    $display("Cycle %d",cycle_count);
    arch_map_packet_in = test[9];
    check(test_result, test[9], arch_map);
    test_result = arch_map;

    @(negedge clock);
    @(negedge clock);
    @(negedge clock);

    $finish;

  end // initial

endmodule  // module test_Arch_Map

