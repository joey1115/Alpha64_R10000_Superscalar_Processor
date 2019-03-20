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
  MAP_TABLE_PACKET_IN            uut_in;

  // UUT output
  MAP_TABLE_PACKET_OUT           uut_out;
  T_t                     [31:0] uut_table;

  // UUT instantiation
  Map_Table UUT(
    .en(en),
    .clock(clock),
    .reset(reset),
    .map_table_packet_in(uut_in),
    .map_table_packet_out(uut_out),
    .map_table_out(uut_table)
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
    // if(reset)
      // cycle_count <= `SD 0;
    // else
      cycle_count <= `SD (cycle_count + 1);
  end


  // ********* Test Case Setup *********
  `define TEST_LEN 1
  MAP_TABLE_PACKET_IN   [`TEST_LEN-1:0] test_in;
  // solutions have one more state than test cases
  MAP_TABLE_PACKET_OUT    [`TEST_LEN:0] test_out;
  T_t                            [31:0] test_table;

  // Reset test_table
  task resetTestTable;
    begin
      for (int i=0; i<32; i=i+1) begin
        test_table[i].idx        = i;
        test_table[i].ready      = `TRUE;
      end
    end
  endtask

  // Update test_table
  task updateTestTable;
    input logic [4:0] dest_idx;
    input logic [$clog2(`NUM_PR)-1:0] T_idx;
    input logic ready;
    begin
      test_table[dest_idx].idx   = T_idx;
      test_table[dest_idx].ready = ready;
    end
  endtask

  // Display table
  task displayTable;
    input T_t [31:0] map_table_to_display;
    begin
      $display("| REG | PR Tag | + |");
      for (int i=0; i<32; i=i+1) begin
        $display("|  %2d |   %2d   | %1d |", i, map_table_to_display[i].idx, map_table_to_display[i].ready);
      end
      $display("\n");
    end
  endtask

  // Apply input to DUT
  task applyInput;
    input logic test_en;
    input MAP_TABLE_PACKET_IN test_in;
    begin
      en = test_en;
      uut_in = test_in;
    end
  endtask

  // Check solution
  task checkSolution;
    input output_dont_care; // when a hazard happens, output is invalid. So, don't care
    input MAP_TABLE_PACKET_OUT sol_packet_out;
    int pass;
    begin
      pass = 1;
      $display("********* Cycle %2d *********", cycle_count);
      
      // Display Data
      // $display("UUT");
      // displayTable(uut_table);
      // $display("Sol");
      // displayTable(test_table);
      
      // Compare UUT internal data with test_table
      for (int i=0; i<32; i=i+1) begin
        if (uut_table[i].idx != test_table[i].idx) begin
          $display("Incorrect PR_idx in entry %2d", i);
          $display("UUT PR_idx: %2d", uut_table[i].idx);
          $display("Sol PR_idx: %2d", test_table[i].idx);
          pass = 0;
        end
        if (uut_table[i].ready != test_table[i].ready) begin
          $display("Incorrect T_plus_status in entry %2d", i);
          $display("UUT T_plus_status: %1d", uut_table[i].ready);
          $display("Sol T_plus_status: %1d", test_table[i].ready);
          pass = 0;
        end
      end
      
      // Compare UUT output with test_out (solution)
      if (!output_dont_care) begin
        if (uut_out.Told_idx != sol_packet_out.Told_idx) begin
          $display("Incorrect PR_idx in entry %2d", i);
          $display("UUT PR_idx: %2d", uut_table[i].idx);
          $display("Sol PR_idx: %2d", test_table[i].idx);
          pass = 0;
        end
        
      end

      if (pass == 1)
        $display("@@@Pass!\n");
      else
        $display("@@@fail\n");
    end
  endtask




  initial begin
    // ********* Test Case *********
    // test[c]: input at cycle c, the corresponding output will be at cycle c+1
    // {Dispatch_enable, Dispatch_T_idx, Dispatch_T1_idx, Dispatch_T2_idx, Freelist_T,
    //  CDB_T, CDB_enable}
    test_in[0] = '{0,  0,  0,  0,  0,  0, 0};

    // test_out[c]: output at cycle c (test[c]'s effect is shown by test_out[c+1])
    // {Told_to_ROB, {T1, ready}, {T2, ready}}
    // Cycle 0 tests reset
    test_out[0] = '{ 0, { 0, 1}, { 0, 1}}; // should all be don't care


    en    = 1'b1;
    clock = 1'b0;
    reset = 1'b0;
    cycle_count = 0;


    // Reset
    @(negedge clock);
    reset = 1'b1;
    
    // Cycle 0
    @(negedge clock);
    cycle_count = 0;
    reset = 1'b0;


    // Cycle 1
    @(negedge clock);


    $display("@@@Pass!\n");

    @(negedge clock);
    @(negedge clock);
    @(negedge clock);

    $finish;

  end // initial

endmodule  // module test_Map_Table
