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
  `define TEST_LEN 1
  CDB_PACKET_IN  [`TEST_LEN-1:0] test_in_raw; // diff_ROB is changed to ROB_tail_idx of the cycle
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
      $display("| rollback_en | ROB_rollback_idx | ROB_tail_idx | diff_ROB |");
      $display("|          %1d  |         %1d        |      %1d      |     %1d    |",
                uut_in.rollback_en, uut_in.ROB_rollback_idx, test_in_raw[cycle_count].diff_ROB, uut_in.diff_ROB);
      // input
      $display("____Input_Data_________________________________________________________");
      $display("| FU# | FU_done | T_idx | ROB_idx | dest_idx |        FU_result        |");
      for (int i=`NUM_FU-1; i>-1; i=i-1) begin
        $display("|  %1d  |    %1d    |   %2d  |    %1d    |    %2d    |  0x%04h_%04h_%04h_%04h  |",
              i, uut_in.FU_done[i], uut_in.T_idx[i], uut_in.ROB_idx[i], uut_in.dest_idx,
              uut_in.FU_result[i][63:48], uut_in.FU_result[i][47:32], uut_in.FU_result[i][31:16], uut_in.FU_result[i][15:0]);
      end
      // internal data and output
      $display("____Internal_Data_and_Output_______________________________________________________");
      $display("| FU# |  taken  | T_idx | ROB_idx | dest_idx |        FU_result        | CDB_valid |");
      for (int i=`NUM_FU-1; i>-1; i=i-1) begin
        $display("|  %1d  |    %1d    |   %2d  |    %1d    |    %2d    |  0x%04h_%04h_%04h_%04h  |     %1d     |",
              i, uut_data[i].taken, uut_data[i].T_idx, uut_data[i].ROB_idx, uut_data[i].dest_idx,
              uut_data[i].T_value[63:48], uut_data[i].T_value[47:32], uut_data[i].T_value[31:16], uut_data[i].T_value[15:0],
              uut_out.CDB_valid[i]);
      end
      $display();
    end
  endtask


  initial begin

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
    // uut_in = test_in[0];
    @(posedge clock)
    display_cycle_info();
    #2;

    $finish;

  end // initial

endmodule  // module test_CDB

