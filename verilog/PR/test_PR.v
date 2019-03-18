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

  // ********* UUT Setup *********
  // UUT input
  logic en, clock, reset;
  PR_PACKET_IN  uut_in;
  // UUT output
  PR_PACKET_OUT uut_out;
  logic [`NUM_PR-1:0] [63:0] uut_data; // internal register data

  // UUT instantiation
  PR UUT(
    .en(en),
    .clock(clock),
    .reset(reset),
    .pr_packet_in(uut_in),
    .pr_packet_out(uut_out),
    .pr_data(uut_data)
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
  PR_PACKET_IN  [`TEST_LEN-1:0] test_in;
  // solutions have one more state than test cases
  PR_PACKET_OUT   [`TEST_LEN:0] sol_out;
  logic [`NUM_PR-1:0] [63:0]    sol_data;

  // Reset sol_data
  task reset_sol_data;
    begin
      for (int i=0; i<`NUM_PR; i=i+1) begin
        sol_data[i] = 64'b0;
      end
    end
  endtask

  // Update sol_data entry
  task update_test_data;
    input [$clog2(`NUM_PR)-1:0] idx;
    input [63:0] value;
    begin
      sol_data[idx] = value;
    end
  endtask

  // Display data in a physical register
  task display_data;
    input [`NUM_PR-1:0] [63:0] data; // Pysical register data for display
    begin
      $display("| PR |      Value (in hex)     |");
      for (int i=0; i<`NUM_PR; i=i+1) begin
        $display("| %2d |  0x%04h_%04h_%04h_%04h  |", i, data[i][63:48], data[i][47:32], data[i][31:16], data[i][15:0]);
      end
      $display();
    end
  endtask

  task display_out;
    input PR_PACKET_OUT out; // PR output for display
    begin
      for (int i=0; i<`NUM_FU; i=i+1) begin
        $display("_________________FU_%1d_________________", i);
        $display("| T1_value |  0x %04h_%04h_%04h_%04h  |", out.T1_value[i][63:48], out.T1_value[i][47:32], out.T1_value[i][31:16], out.T1_value[i][15:0]);
        $display("| T2_value |  0x %04h_%04h_%04h_%04h  |", out.T2_value[i][63:48], out.T2_value[i][47:32], out.T2_value[i][31:16], out.T2_value[i][15:0]);
      end
      $display();
    end
  endtask

  // // Apply input to UUT
  // task apply_input;
  //   input logic test_en;
  //   input PR_PACKET_IN test_in;
  //   begin
  //     en = test_en;
  //     uut_in = test_in;
  //   end
  // endtask

  // Check Solution
  task check_solution;
    int pass;
    begin
      pass = 1;
      $display("********* Cycle %2d *********", cycle_count);
      // Display Data
      $display("UUT");
      display_data(uut_data);
      $display("Sol");
      display_data(sol_data);
      $display("UUT");
      display_out(uut_out);
      $display("Sol");
      display_out(sol_out);
      // Compare UUT internal data with sol_data
      for (int i=0; i<`NUM_PR; i=i+1) begin
        if (uut_data[i] != sol_data[i]) begin
          $display("Incorrect internal data: pr[%2d]", i);
          $display("UUT value: %2d", uut_data[i]);
          $display("Sol value: %2d", sol_data[i]);
          pass = 0;
        end
      end
      // Compare UUT output with sol_out
      for (int i=0; i<`NUM_FU; i=i+1) begin
        if (uut_out.T1_value[i] != sol_out[cycle_count].T1_value[i]) begin
          $display("Incorrect output: pr_packet_out.T1_value");
          $display("UUT output: %2d", uut_out.T1_value[i]);
          $display("Sol output: %2d", sol_out[cycle_count].T1_value[i]);
          pass = 0;
        end
        if (uut_out.T2_value[i] != sol_out[cycle_count].T2_value[i]) begin
          $display("Incorrect output: pr_packet_out.T2_value");
          $display("UUT output: %2d", uut_out.T2_value[i]);
          $display("Sol output: %2d", sol_out[cycle_count].T2_value[i]);
          pass = 0;
        end
      end // for
      // Verdict
      if (pass == 1)
        $display("@@@Pass!\n");
      else
        $display("@@@fail\n");
    end
  endtask


  initial begin
    // ********* Test Case *********
    // test_in[c]: input at cycle c
    // the resulting combinational logic outputs will be checked at cycle c (sol_out[c])
    // the resulting  sequential   logic outputs will be checked at cycle c+1 (sol_out[c+1])
    // input: {write_en, T_idx, T_value, `NUM_FU{T1_idx}, `NUM_FU{T2_idx}}

    // Cycle 0
    test_in[0] = '{0,  0, 16, '{ 0,  1, 30, 31, 46}, '{32, 63, 46, 48, 61}};

    // sol_out[c]: output at cycle c (test[c]'s effect is shown by sol_out[c+1])
    // checks the resulting combinational logic outputs of test_in[c] (combinational outputs are labeled in quotations below)
    // checks the resulting  sequential   logic outputs of test_in[c-1]
    // output: {`NUM_FU{"T1_value"}, `NUM_FU{"T2_value"}}

    // Cycle 0: check reset
    sol_out[0] = '{'{ 0,  0,  0,  0,  0}, '{ 0,  0,  0,  0,  0}};


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
    uut_in = test_in[0];
    reset_sol_data();
    @(posedge clock)
    check_solution();

    // Cycle 1
    @(negedge clock);

    // @(negedge clock);
    // @(negedge clock);
    // @(negedge clock);

    $finish;

  end // initial

endmodule  // module test_PR

