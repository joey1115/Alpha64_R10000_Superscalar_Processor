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

`include "CDB.vh"

module test_CDB;

  logic                                      en, clock, reset, rollback_en, write_en, complete_en;
  logic               [$clog2(`NUM_ROB)-1:0] ROB_rollback_idx, diff_ROB, ROB_idx;
  FU_CDB_OUT_t                               FU_CDB_out;
  CDB_entry_t         [`NUM_FU-1:0]          CDB;
  logic               [`NUM_FU-1:0]          CDB_valid;
  CDB_ROB_OUT_t                              CDB_ROB_out;
  CDB_RS_OUT_t                               CDB_RS_out;
  CDB_MAP_TABLE_OUT_t                        CDB_Map_Table_out;
  CDB_PR_OUT_t                               CDB_PR_out;

  CDB cdb_0 (
    .en(en),
    .clock(clock),
    .reset(reset),
    .rollback_en(rollback_en),
    .ROB_rollback_idx(ROB_rollback_idx),
    .diff_ROB(diff_ROB),
    .FU_CDB_out(FU_CDB_out),
`ifdef DEBUG
    .CDB(CDB),
`endif
    .write_en(write_en),
    .complete_en(complete_en),
    .CDB_valid(CDB_valid),
    .CDB_ROB_out(CDB_ROB_out),
    .CDB_RS_out(CDB_RS_out),
    .CDB_Map_Table_out(CDB_Map_Table_out),
    .CDB_PR_out(CDB_PR_out)
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

  // Apply test input
  task apply_input(
  logic                                      rollback_en_in, write_en_in, complete_en_in,
  logic               [$clog2(`NUM_ROB)-1:0] ROB_rollback_idx_in, ROB_idx_in,
  FU_CDB_OUT_t                               FU_CDB_out_in,
  );
  begin
    rollback_en = rollback_en_in;
    write_en = write_en_in;
    complete_en = complete_en_in;
    ROB_rollback_idx = ROB_rollback_idx_in;
    diff_ROB = ROB_idx_in - ROB_rollback_idx_in;
    FU_CDB_out = FU_CDB_out_in;
  end
  endtask

  // Display input, internal data, and output at the end of a cycle
  task display_cycle_info;
    begin
      // rollback info
      $display("____Rollback_______________________________________________");
      $display("| rollback_en | ROB_rollback_idx | diff_ROB |");
      $display("|          %1d  |         %1d        |     %1d    |",
                rollback_en, ROB_rollback_idx, diff_ROB);
      // input
      $display("____Input______________________________________________________________");
      $display("| FU# | done | T_idx | ROB_idx | dest_idx |        FU_out        |");
      for (int i=`NUM_FU-1; i>-1; i=i-1) begin
        $display("|  %1d  |    %1d    |   %2d  |    %1d    |    %2d    |  0x%04h_%04h_%04h_%04h  |",
              i, FU_CDB_out.FU_out[i].done, FU_CDB_out.FU_out[i].T_idx, FU_CDB_out.FU_out[i].ROB_idx, FU_CDB_out.FU_out[i].dest_idx,
              FU_CDB_out.FU_out[i].result[63:48], FU_CDB_out.FU_out[i].result[47:32], FU_CDB_out.FU_out[i].result[31:16], FU_CDB_out.FU_out[i].result[15:0]);
      end
      // internal data and CDB_valid_output
      $display("____Internal_Data_and_CDB_valid_Output_____________________________________________");
      $display("| FU# |  taken  | T_idx | ROB_idx | dest_idx |        FU_out        | CDB_valid |");
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
    //             `NUM_FU{FU_out}}
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
    FU_CDB_out = 0;

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

