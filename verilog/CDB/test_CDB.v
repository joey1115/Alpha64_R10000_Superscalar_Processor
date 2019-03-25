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

  // UUT instantiation
  CDB UUT(
    .en(en),
    .clock(clock),
    .reset(reset),
    .CDB_packet_in(uut_in),
    .CDB_packet_out(uut_out),
    .CDB(uut_data)
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
  // Test Case
  `define TEST_LEN 20
  CDB_PACKET_IN  [`TEST_LEN-1:0] test_in_raw; // diff_ROB is changed to ROB_idx of the cycle
  CDB_PACKET_IN  [`TEST_LEN-1:0] test_in;     // the real test_in
  // solutions have one more state than test cases
  CDB_PACKET_OUT   [`TEST_LEN:0] sol_out;


  // Apply test input
  task apply_input;
    begin
      test_in[cycle_count] = test_in_raw[cycle_count];
      test_in[cycle_count].diff_ROB = test_in[cycle_count].diff_ROB - test_in[cycle_count].ROB_rollback_idx;
      uut_in = test_in[cycle_count];
    end
  endtask

  // Display input, internal data, and output at the end of a cycle
  task display_cycle_info;
    begin
      // rollback info
      $display("____Rollback_______________________________________________");
      $display("| rollback_en | ROB_rollback_idx | ROB_idx | diff_ROB |");
      $display("|          %1d  |         %1d        |       %1d      |     %1d    |",
                uut_in.rollback_en, uut_in.ROB_rollback_idx, test_in_raw[cycle_count].diff_ROB, uut_in.diff_ROB);
      // input
      $display("____Input______________________________________________________________");
      $display("| FU# | done | T_idx | ROB_idx | dest_idx |        FU_result        |");
      for (int i=`NUM_FU-1; i>-1; i=i-1) begin
        $display("|  %1d  |    %1d    |   %2d  |    %1d    |    %2d    |  0x%04h_%04h_%04h_%04h  |",
              i, uut_in.done[i], uut_in.T_idx[i], uut_in.ROB_idx[i], uut_in.dest_idx,
              uut_in.FU_result[i][63:48], uut_in.FU_result[i][47:32], uut_in.FU_result[i][31:16], uut_in.FU_result[i][15:0]);
      end
      // internal data and CDB_valid_output
      $display("____Internal_Data_and_CDB_valid_Output_____________________________________________");
      $display("| FU# |  taken  | T_idx | ROB_idx | dest_idx |        FU_result        | CDB_valid |");
      for (int i=`NUM_FU-1; i>-1; i=i-1) begin
        $display("|  %1d  |    %1d    |   %2d  |    %1d    |    %2d    |  0x%04h_%04h_%04h_%04h  |     %1d     |",
              i, uut_data[i].taken, uut_data[i].T_idx, uut_data[i].ROB_idx, uut_data[i].dest_idx,
              uut_data[i].T_value[63:48], uut_data[i].T_value[47:32], uut_data[i].T_value[31:16], uut_data[i].T_value[15:0],
              uut_out.CDB_valid[i]);
      end
      // output (not including CDB_valid)
      $display("____Output____________________________________________________________");
      $display("| complete_en | write_en | T_idx | dest_idx |          T_value        |");
      $display("|        %1d    |     %1d    |   %2d  |    %2d    |  0x%04h_%04h_%04h_%04h  |",
              uut_out.complete_en, uut_out.write_en, uut_out.T_idx, uut_out.dest_idx,
              uut_out.T_value[63:48], uut_out.T_value[47:32], uut_out.T_value[31:16], uut_out.T_value[15:0]);
      $display();
    end
  endtask

  // Check Solution
  task check_solution;
    int pass;
    begin
      pass = 1;
      $display("********* Cycle %2d *********", cycle_count);
      // Display cycle info
      display_cycle_info();
      // Compare UUT output with sol_out
      for (int i=`NUM_FU-1; i>-1; i=i-1) begin
        if (uut_out.CDB_valid[i] != sol_out[cycle_count].CDB_valid[i]) begin
          $display("Incorrect output: CDB_packet_out.CDB_valid[%1d]", i);
          $display("UUT output: %1d", uut_out.CDB_valid[i]);
          $display("Sol output: %1d", sol_out[cycle_count].CDB_valid[i]);
          pass = 0;
        end
      end // for
      if (uut_out.complete_en != sol_out[cycle_count].complete_en) begin
        $display("Incorrect output: CDB_packet_out.complete_en");
        $display("UUT output: %1d", uut_out.complete_en);
        $display("Sol output: %1d", sol_out[cycle_count].complete_en);
        pass = 0;
      end
      if (uut_out.T_idx != sol_out[cycle_count].T_idx) begin
        $display("Incorrect output: CDB_packet_out.T_idx");
        $display("UUT output: %2d", uut_out.T_idx);
        $display("Sol output: %2d", sol_out[cycle_count].T_idx);
        pass = 0;
      end
      if (uut_out.dest_idx != sol_out[cycle_count].dest_idx) begin
        $display("Incorrect output: CDB_packet_out.dest_idx");
        $display("UUT output: %2d", uut_out.dest_idx);
        $display("Sol output: %2d", sol_out[cycle_count].dest_idx);
        pass = 0;
      end
      if (uut_out.T_value != sol_out[cycle_count].T_value) begin
        $display("Incorrect output: CDB_packet_out.T_value");
        $display("UUT output: 0x%04h_%04h_%04h_%04h",
                uut_out.T_value[63:48], uut_out.T_value[47:32], uut_out.T_value[31:16], uut_out.T_value[15:0]);
        $display("Sol output: 0x%04h_%04h_%04h_%04h",
                sol_out[cycle_count].T_value[63:48], sol_out[cycle_count].T_value[47:32], sol_out[cycle_count].T_value[31:16], sol_out[cycle_count].T_value[15:0]);
        pass = 0;
      end
      // Verdict
      if (pass == 1)
        $display("@@@Pass!\n");
      else
        $display("@@@fail\n");
    end
  endtask


  initial begin

    // ********* Test Case *********
    // test_in_raw[c]: raw input at cycle c
    // the resulting combinational logic outputs will be checked at cycle c (sol_out[c])
    // the resulting  sequential   logic outputs will be checked at cycle c+1 (sol_out[c+1])
    // raw input: {rollback_en, ROB_rollback_idx, ROB_idx,
    //             `NUM_FU{done},
    //             `NUM_FU{T_idx},
    //             `NUM_FU{ROB_idx},
    //             `NUM_FU{dest_idx},
    //             `NUM_FU{FU_result}}
    test_in_raw[0] = '{0, 0, 0,
                       '{ 0,  0,  0,  0,  0},
                       '{ 0,  0,  0,  0,  0},
                       '{ 0,  0,  0,  0,  0},
                       '{ 0,  0,  0,  0,  0},
                       '{ 0,  0,  0,  0,  0}};
    
    // sol_out[c]: output at cycle c (test[c]'s effect is shown by sol_out[c+1])
    // checks the resulting combinational logic outputs of test_in[c] (combinational outputs are labeled in quotations below)
    // checks the resulting  sequential   logic outputs of test_in[c-1]
    // output: {`NUM_FU{CDB_valid},
    //           complete_en, write_en, T_idx, dest_idx, T_value}
    sol_out[0] = '{'{1, 1, 1, 1, 1},
                   0, 0, 31, 31, 0};

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
    apply_input();
    @(posedge clock)
    check_solution();
    #2;



    // Cycle (Last one)
    @(negedge clock);
    @(posedge clock)
    check_solution();

    $finish;

  end // initial

endmodule  // module test_CDB

