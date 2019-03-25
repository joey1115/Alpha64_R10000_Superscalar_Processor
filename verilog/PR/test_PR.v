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
  `define TEST_LEN 23
  PR_PACKET_IN  [`TEST_LEN-1:0] test_in;
  // solutions have one more state than test cases
  PR_PACKET_OUT   [`TEST_LEN:0] sol_out;


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
      for (int i=`NUM_FU-1; i>-1; i=i-1) begin
        $display("_________________FU_%1d________________", i);
        $display("| T1_value |  0x%04h_%04h_%04h_%04h  |", out.T1_value[i][63:48], out.T1_value[i][47:32], out.T1_value[i][31:16], out.T1_value[i][15:0]);
        $display("| T2_value |  0x%04h_%04h_%04h_%04h  |", out.T2_value[i][63:48], out.T2_value[i][47:32], out.T2_value[i][31:16], out.T2_value[i][15:0]);
      end
      $display();
    end
  endtask


  // Check Solution
  task check_solution;
    int pass;
    begin
      pass = 1;
      $display("********* Cycle %2d *********", cycle_count);
      // Display Data
      $display("UUT");
      display_data(uut_data);
      $display("UUT");
      display_out(uut_out);
      $display("Sol");
      display_out(sol_out[cycle_count]);
      // Compare UUT output with sol_out
      for (int i=0; i<`NUM_FU; i=i+1) begin
        if (uut_out.T1_value[i] != sol_out[cycle_count].T1_value[i]) begin
          $display("Incorrect output: pr_packet_out.T1_value[%1d]", i);
          $display("UUT output: %2d", uut_out.T1_value[i]);
          $display("Sol output: %2d", sol_out[cycle_count].T1_value[i]);
          pass = 0;
        end
        if (uut_out.T2_value[i] != sol_out[cycle_count].T2_value[i]) begin
          $display("Incorrect output: pr_packet_out.T2_value[%1d]", i);
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
    // input: {write_enable, T_idx, T_value, `NUM_FU{T1_idx}, `NUM_FU{T2_idx}}

    test_in[0]  = '{0, 40, 16, '{40,  1, 30, 31, 46}, '{32, 63, 56, 48, 61}};

    test_in[1]  = '{1,  0, 10, '{ 0, 10, 20, 31, 45}, '{33, 62, 55, 49, 60}};
    test_in[2]  = '{1,  1, 11, '{ 0,  1, 20, 31, 45}, '{33, 62, 55, 49, 60}};
    test_in[3]  = '{1,  2, 12, '{ 1, 10,  2, 31, 45}, '{33, 62, 55, 49, 60}};
    test_in[4]  = '{1,  3, 13, '{ 2, 10, 20,  3, 45}, '{33, 62, 55, 49, 60}};
    test_in[5]  = '{1,  4, 14, '{ 3, 10, 20, 31,  4}, '{33, 62, 55, 49, 60}};
    test_in[6]  = '{1,  5, 15, '{ 4, 10, 20, 31, 45}, '{ 5, 62, 55, 49, 60}};
    test_in[7]  = '{1,  6, 16, '{ 5, 10, 20, 31, 45}, '{33,  6, 55, 49, 60}};
    test_in[8]  = '{1,  7, 17, '{ 6, 10, 20, 31, 45}, '{33, 62,  7, 49, 60}};
    test_in[9]  = '{1,  8, 18, '{ 7, 10, 20, 31, 45}, '{33, 62, 55,  8, 60}};
    test_in[10] = '{1,  9, 19, '{ 8, 10, 20, 31, 45}, '{33, 62, 55, 49,  9}};

    test_in[11] = '{1, 28, 64'hFFFFFFFFFFFFFFFF, '{29, 29, 29, 29, 29}, '{29, 29, 29, 29, 29}};
    test_in[12] = '{1, 29, 64'hFFFFFFFFFFFFFFFE, '{29, 29, 29, 29, 29}, '{29, 29, 29, 29, 29}};
    test_in[13] = '{1, 30, 64'hFFFFFFFFFFFFFFFD, '{29, 29, 29, 29, 29}, '{29, 29, 29, 29, 29}};
    test_in[14] = '{1, 31, 64'hFFFFFFFFFFFFFFFC, '{31, 31, 31, 31, 31}, '{31, 31, 31, 31, 31}};
    test_in[15] = '{1, 32, 64'hFFFFFFFFFFFFFFFB, '{31, 31, 31, 31, 31}, '{31, 31, 31, 31, 31}};

    test_in[16] = '{0, 63, 63, '{63, 59, 49, 39, 29}, '{19,  9,  3,  1,  0}};
    test_in[17] = '{1, 63, 64, '{63, 59, 49, 39, 29}, '{19,  9,  3,  1,  0}};
    test_in[18] = '{1, 62, 65, '{63, 59, 49, 39, 29}, '{19,  9,  3,  1,  0}};
    test_in[19] = '{1, 61, 66, '{63, 59, 49, 39, 29}, '{19,  9,  3,  1,  0}};

    test_in[20] = '{1, 60, 67, '{63, 59, 49, 39, 29}, '{19,  9,  3,  1,  0}}; // en = 0
    test_in[21] = '{1, 60, 68, '{63, 59, 49, 39, 29}, '{19,  9, 60,  1,  0}}; // en = 0
    test_in[22] = '{1, 60, 69, '{63, 59, 49, 39, 29}, '{19,  9, 60,  1,  0}}; // en = 1

    // sol_out[c]: output at cycle c (test[c]'s effect is shown by sol_out[c+1])
    // checks the resulting combinational logic outputs of test_in[c] (combinational outputs are labeled in quotations below)
    // checks the resulting  sequential   logic outputs of test_in[c-1]
    // output: {`NUM_FU{"T1_value"}, `NUM_FU{"T2_value"}}

    // Cycle 0: reset and no forwarding when write_enable is low
    sol_out[0]  = '{'{ 0,  0,  0,  0,  0}, '{ 0,  0,  0,  0,  0}};
    // Cycle 1-10: test write_enable and forwarding (fill in PR[0]-PR[9])
    sol_out[1]  = '{'{10,  0,  0,  0,  0}, '{ 0,  0,  0,  0,  0}};
    sol_out[2]  = '{'{10, 11,  0,  0,  0}, '{ 0,  0,  0,  0,  0}};
    sol_out[3]  = '{'{11,  0, 12,  0,  0}, '{ 0,  0,  0,  0,  0}};
    sol_out[4]  = '{'{12,  0,  0, 13,  0}, '{ 0,  0,  0,  0,  0}};
    sol_out[5]  = '{'{13,  0,  0,  0, 14}, '{ 0,  0,  0,  0,  0}};
    sol_out[6]  = '{'{14,  0,  0,  0,  0}, '{15,  0,  0,  0,  0}};
    sol_out[7]  = '{'{15,  0,  0,  0,  0}, '{ 0, 16,  0,  0,  0}};
    sol_out[8]  = '{'{16,  0,  0,  0,  0}, '{ 0,  0, 17,  0,  0}};
    sol_out[9]  = '{'{17,  0,  0,  0,  0}, '{ 0,  0,  0, 18,  0}};
    sol_out[10] = '{'{18,  0,  0,  0,  0}, '{ 0,  0,  0,  0, 19}};
    sol_out[11] = '{'{ 0,  0,  0,  0,  0}, '{ 0,  0,  0,  0,  0}};
    // Cycle 11-15: writing PR[31] is write only and no forwarding; test reading the same register
    sol_out[12] = '{'{64'hFFFFFFFFFFFFFFFE, 64'hFFFFFFFFFFFFFFFE, 64'hFFFFFFFFFFFFFFFE, 64'hFFFFFFFFFFFFFFFE, 64'hFFFFFFFFFFFFFFFE}, 
                    '{64'hFFFFFFFFFFFFFFFE, 64'hFFFFFFFFFFFFFFFE, 64'hFFFFFFFFFFFFFFFE, 64'hFFFFFFFFFFFFFFFE, 64'hFFFFFFFFFFFFFFFE}};
    sol_out[13] = '{'{64'hFFFFFFFFFFFFFFFE, 64'hFFFFFFFFFFFFFFFE, 64'hFFFFFFFFFFFFFFFE, 64'hFFFFFFFFFFFFFFFE, 64'hFFFFFFFFFFFFFFFE}, 
                    '{64'hFFFFFFFFFFFFFFFE, 64'hFFFFFFFFFFFFFFFE, 64'hFFFFFFFFFFFFFFFE, 64'hFFFFFFFFFFFFFFFE, 64'hFFFFFFFFFFFFFFFE}};
    sol_out[14] = '{'{ 0,  0,  0,  0,  0}, '{ 0,  0,  0,  0,  0}};
    sol_out[15] = '{'{ 0,  0,  0,  0,  0}, '{ 0,  0,  0,  0,  0}};
    // Cycle 16-19: Check PR[63], PR[62], and PR[61] (correctness at boundary)
    sol_out[16] = '{'{ 0,  0,  0,  0, 64'hFFFFFFFFFFFFFFFE}, '{ 0, 19, 13, 11, 10}};
    sol_out[17] = '{'{64,  0,  0,  0, 64'hFFFFFFFFFFFFFFFE}, '{ 0, 19, 13, 11, 10}};
    sol_out[18] = '{'{64,  0,  0,  0, 64'hFFFFFFFFFFFFFFFE}, '{ 0, 19, 13, 11, 10}};
    sol_out[19] = '{'{64,  0,  0,  0, 64'hFFFFFFFFFFFFFFFE}, '{ 0, 19, 13, 11, 10}};
    // Cycle 20-22: Check en signal
    sol_out[20] = '{'{64,  0,  0,  0, 64'hFFFFFFFFFFFFFFFE}, '{ 0, 19, 13, 11, 10}};
    sol_out[21] = '{'{64,  0,  0,  0, 64'hFFFFFFFFFFFFFFFE}, '{ 0, 19,  0, 11, 10}};
    sol_out[22] = '{'{64,  0,  0,  0, 64'hFFFFFFFFFFFFFFFE}, '{ 0, 19, 69, 11, 10}};
    // Don't care about the output. Only check PR internal data in this cycle
    sol_out[23] = '{'{64,  0,  0,  0, 64'hFFFFFFFFFFFFFFFE}, '{ 0, 19, 69, 11, 10}}; // don't care


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
    @(posedge clock)
    check_solution();
    #2;

    // Cycle 1-20
    while (cycle_count < 20) begin
      @(negedge clock);
      uut_in = test_in[cycle_count];
      @(posedge clock)
      check_solution();
      #2;
    end

    // Cycle 20
    @(negedge clock);
    en = 1'b0;    // disable PR
    uut_in = test_in[20];
    @(posedge clock)
    check_solution();
    #2;
    
    // Cycle 21
    @(negedge clock);
    uut_in = test_in[21];
    @(posedge clock)
    check_solution();
    #2;

    // Cycle 22
    @(negedge clock);
    en = 1'b1;    // enable PR
    uut_in = test_in[22];
    @(posedge clock)
    check_solution();
    #2;

    // Cycle 23
    @(negedge clock);
    @(posedge clock)
    check_solution();

    $finish;

  end // initial

endmodule  // module test_PR

