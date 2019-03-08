/////////////////////////////////////////////////////////////////////////
//                                                                     //
//                                                                     //
//   Modulename :  test_Map_Table.v                                    //
//                                                                     //
//  Description :  Testbench module for Map_Table module;              //
//                                                                     //
//                                                                     //
/////////////////////////////////////////////////////////////////////////

`timescale 1ns/100ps

`include "Map_Table.vh"

module test_Map_Table;

  // ********* UUT Setup *********
  // UUT input stimulus
  logic en, clock, reset;
  MAP_TABLE_PACKET_IN            map_table_packet_in;

  // UUT output
  MAP_TABLE_PACKET_OUT           map_table_packet_out;
  MAP_TABLE_t [`NUM_MAP_TABLE:0] map_table_out;

  // UUT instantiation
  Map_Table UUT(
    .en(en),
    .clock(clock),
    .reset(reset),
    .map_table_packet_in(map_table_packet_in),
    .map_table_packet_out(map_table_packet_out),
    .map_table_out(map_table_out)
  );


  // ********* System Clock and Cycle Count *********
  // Generate System Clock
  always begin
    #(`VERILOG_CLOCK_PERIOD/2.0);
    clock = ~clock;
  end

  // Generate cycle count
  logic [31:0] cycle_count;
  always @(posedge clock) begin
    if(reset)
      cycle_count <= `SD 0;
    else
      cycle_count <= `SD (cycle_count + 1);
  end


  // ********* Test Case Setup *********
  `define TEST_LEN 1
  MAP_TABLE_PACKET_IN   [`TEST_LEN-1:0] test_in;
  // solutions have one more state than test cases
  MAP_TABLE_PACKET_OUT    [`TEST_LEN:0] test_out;
  MAP_TABLE_t        [`NUM_MAP_TABLE:0] test_table;

  // task applyReset() begin end endtask




  initial begin
    // ********* Test Case *********
    // test[c]: input at cycle c, the corresponding output will be at cycle c+1

    // test_out[c]: output at cycle c (test[c]'s effect is shown by test_out[c+1])
    // {Told_to_ROB, {T1, ready}, {T2, ready}}
    // Cycle 0 tests reset
    test_out[0]  = '{ 0, { 0, 1}, { 0, 1}}; // should all be don't care


    // Reset
    en    = 1'b1;
    clock = 1'b0;
    reset = 1'b0;

    @(negedge clock);
    reset = 1'b1;
    
    // Cycle 0 input
    @(negedge clock);
    
    reset = 1'b0;

    $display("@@@Pass!\n");

    @(negedge clock);
    @(negedge clock);
    @(negedge clock);

    $finish;

  end // initial

endmodule  // module test_Map_Table
