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

  // DUT input stimulus
  logic en, clock, reset;
  PR_PACKET_IN pr_packet_in;
  // DUT output
  PR_PACKET_OUT pr_packet_out;

  // DUT instantiation
  PR UUT(
    .en(en),
    .clock(clock),
    .reset(reset),
    .pr_packet_in(pr_packet_in),
    .pr_packet_out(pr_packet_out)
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



  // Test Cases #1: Lecture Slides
  `define TEST1_LEN 46
  PR_PACKET_IN  [`TEST1_LEN-1:0] test1;
  // solutions have one more state than test cases
  PR_PACKET_OUT   [`TEST1_LEN:0] test1_out;

  // Check Sol: compare ROB output to solution
  task check_Sol;
    input logic   [31:0] cycle_count;
    input PR_PACKET_OUT uut_out;
    input PR_PACKET_OUT sol_out;
    int pass;
    begin
      pass = 1;
      $display("********* Cycle %2d *********", cycle_count);
      if (uut_out.T1_value != sol_out.T1_value && sol_out.struct_hazard == 0) begin
        $display("Incorrect pr_packet_out.T1_value");
        $display("UUT output: %1d", uut_out.T1_value);
        $display("sol output: %1d", sol_out.T1_value);
        pass = 0;
      end
      if (uut_out.T2_value != sol_out.T2_value && sol_out.struct_hazard == 0) begin
        $display("Incorrect pr_packet_out.T2_value");
        $display("UUT output: %1d", uut_out.T2_value);
        $display("sol output: %1d", sol_out.T2_value);
        pass = 0;
      end
      if (uut_out.struct_hazard != sol_out.struct_hazard) begin
        $display("Incorrect pr_packet_out.struct_hazard");
        $display("UUT output: %1d", uut_out.struct_hazard);
        $display("sol output: %1d", sol_out.struct_hazard);
        pass = 0;
      end
      if (uut_out.T != sol_out.T && sol_out.struct_hazard == 0) begin
        $display("Incorrect pr_packet_out.T");
        $display("UUT output: %1d", uut_out.T);
        $display("sol output: %1d", sol_out.T);
        pass = 0;
      end
      if (pass == 1)
        $display("@@@Pass!\n");
      else
        $display("@@@fail\n");
    end
  endtask // task check_Sol

  task Insert_T1_T2   // insert T1 and T2 to test1
    input logic [$clog2(`TEST1_LEN)-1:0] 
  endtask


  initial begin


  // for (int i=0; i<`TEST1_LEN; i++) begin
  //   test1[i].r = $random %2;                // input retire signal 
  //   test1[i].T_old = i;            // input T_old from ROB
  //   test1[i].X_C_valid = 1;        // input ready bit from exe
  //   test1[i].X_C_T = i+1;          // input tag of result from exe
  //   test1[i].X_C_result = 3*i;     // input result from exe
  //   test1[i].inst_dispatch =1 ;      // input dispatch_hazard
  //   for (int j = 0; j<$clog2(`NUM_FU)-1;j++ ) begin
  //     test1[i].S_X_T1[j] = i;      // input T1 from FU
  //     test1[i].S_X_T2[j] = 0;      // input T2 from FU
  //     test1_out[i+1].T1_value[j] = 1;    // output T1_value 
  //     test1_out[i+1].T2_value[j] = 1;   // output T2_value
  //   end
  //   test1_out[i+1].struct_hazard = 1;       // output hazard
  //   test1_out[i+1].T = 1;        // output free tag 
  // end

    /***** Test Case #1 *****/

    // test1[c]: input at cycle c, the corresponding output will be at cycle c+1
    // input {r, T_old, X_C_valid, X_C_T, X_C_result, S_X_T1, S_X_T2, inst_dispatch,}
    // Cycle 0-6: simulates Lecture Slides with stalls added
    test1[0]  = '{1, 0,  1,  0, 2, 0, 1};
    test1[1]  = '{0, 0,  0,  3, 0, 0}; // test stall (inst_dispatch)
    test1[2]  = '{0, 1,  0,  3, 0, 0};
    test1[3]  = '{0, 1,  0, 31, 0, 0}; // store inst, no destination
    test1[4]  = '{0, 1,  0,  4, 0, 0}; // test stall (enable) here
    test1[5]  = '{0, 1,  0,  4, 0, 0};
    test1[6]  = '{1, 1,  0,  5, 0, 0};
    // Cycle 7-10: fill up all entries of ROB
    test1[7]  = '{0, 1,  1, 19, 0, 0};
    test1[8]  = '{0, 1,  1, 20, 0, 0};
    test1[9]  = '{0, 1,  1, 21, 0, 0};
    test1[10] = '{0, 1,  1, 22, 0, 0};
    // Cycle 11: check struct hazard detection
    test1[11] = '{0, 1, 13, 23, 0, 0};
    // Cycle 12: the head retires and new inst should be dispatched at the same cycle
    test1[12] = '{1, 1, 13, 23, 0, 0};
    // Cycle 13-20: retire all instructions
    test1[13] = '{1, 0, 14, 24, 0, 0};
    test1[14] = '{1, 0, 14, 24, 0, 0};
    test1[15] = '{1, 0, 14, 24, 0, 0};
    test1[16] = '{1, 0, 14, 24, 0, 0};
    test1[17] = '{1, 0, 14, 24, 0, 0};
    test1[18] = '{1, 0, 14, 24, 0, 0};
    test1[19] = '{1, 0, 14, 24, 0, 0};
    test1[20] = '{1, 0, 14, 24, 0, 0};
    // Cycle 21: try retire when ROB is empty
    test1[21] = '{1, 0, 14, 24, 0, 0};
    // Cycle 22-29: fill in instructions again
    test1[22] = '{0, 1,  2, 12, 0, 0};
    test1[23] = '{0, 1,  3, 13, 0, 0};
    test1[24] = '{0, 1,  4, 14, 0, 0};
    test1[25] = '{0, 1,  5, 15, 0, 0};
    test1[26] = '{0, 1,  6, 16, 0, 0};
    test1[27] = '{0, 1,  7, 17, 0, 0};
    test1[28] = '{0, 1, 10, 20, 0, 0};
    test1[29] = '{0, 1, 11, 21, 0, 0};
    // Cycle 30: branch exception
    test1[30] = '{0, 1, 12, 22, 7, 1}; // flush anything after ROB#7 (with inst_dispatch ON)
    test1[31] = '{0, 0, 12, 22, 4, 1}; // flush right after flush
    test1[32] = '{0, 1, 12, 22, 4, 0}; // write something after flush
    test1[33] = '{1, 1, 13, 23, 3, 1}; // flush and retire at the same time
    test1[34] = '{1, 0, 13, 23, 3, 1}; // flush again at the same spot, and retire
    // Cycle 35-43: reset and fill up the ROB and flush the head
    test1[35] = '{0, 1, 10, 20, 0, 0}; // reset here
    test1[36] = '{0, 1,  0, 10, 0, 0};
    test1[37] = '{0, 1,  1, 11, 0, 0};
    test1[38] = '{0, 1,  2, 12, 0, 0};
    test1[39] = '{0, 1,  3, 13, 0, 0};
    test1[40] = '{0, 1,  4, 14, 0, 0};
    test1[41] = '{0, 1,  5, 15, 0, 0};
    test1[42] = '{0, 1,  6, 16, 0, 0};
    test1[43] = '{0, 1,  7, 17, 0, 0};
    test1[44] = '{0, 0, 13, 23, 0, 1}; // flush at index 0 (head)

    // test1_out[c]: output at cycle c (test1[c]'s effect is shown by test1_out[c+1])
    // output {T1_value, T2_value, struct_hazard, T}
    // Cycle 0 tests reset
    test1_out[0]  = '{ 2,  3, 0, 0}; // T_out, T_old_out should be don't care
    // simulates lecture slides with stalls added
    // test1_out[1]  = '{ 5,  2, 1, 0, 0, 0};
    // test1_out[2]  = '{ 5,  2, 1, 0, 0, 0};
    // test1_out[3]  = '{ 6,  3, 1, 0, 0, 1};
    // test1_out[4]  = '{31, 31, 1, 0, 0, 2};
    // test1_out[5]  = '{31, 31, 1, 0, 0, 2};
    // test1_out[6]  = '{ 7,  4, 1, 0, 0, 3};
    // test1_out[7]  = '{ 8,  5, 1, 0, 1, 4};
    // // all entries of ROB are filled at cycle 11
    // test1_out[8]  = '{ 9, 19, 1, 0, 1, 5};
    // test1_out[9]  = '{10, 20, 1, 0, 1, 6};
    // test1_out[10] = '{11, 21, 1, 0, 1, 7};
    // test1_out[11] = '{12, 22, 1, 1, 1, 0}; // test ROB# roll-over
    // // struct hazard happens here
    // test1_out[12] = '{12, 22, 1, 1, 1, 0};
    // // the head retires and the new inst takes its entry
    // test1_out[13] = '{13, 23, 1, 1, 2, 1};
    // // retire all instructions
    // test1_out[14] = '{13, 23, 1, 0, 3, 1};
    // test1_out[15] = '{13, 23, 1, 0, 4, 1};
    // test1_out[16] = '{13, 23, 1, 0, 5, 1};
    // test1_out[17] = '{13, 23, 1, 0, 6, 1};
    // test1_out[18] = '{13, 23, 1, 0, 7, 1};
    // test1_out[19] = '{13, 23, 1, 0, 0, 1}; // test ROB head idx roll-over
    // test1_out[20] = '{13, 23, 1, 0, 1, 1};
    // test1_out[21] = '{13, 23, 0, 0, 2, 1};
    // // don't move head when over-retire
    // test1_out[22] = '{13, 23, 0, 0, 2, 1};
    // // fill in instructions again
    // test1_out[23] = '{ 2, 12, 1, 0, 2, 2};
    // test1_out[24] = '{ 3, 13, 1, 0, 2, 3};
    // test1_out[25] = '{ 4, 14, 1, 0, 2, 4};
    // test1_out[26] = '{ 5, 15, 1, 0, 2, 5};
    // test1_out[27] = '{ 6, 16, 1, 0, 2, 6};
    // test1_out[28] = '{ 7, 17, 1, 0, 2, 7};
    // test1_out[29] = '{10, 20, 1, 0, 2, 0};
    // test1_out[30] = '{11, 21, 1, 1, 2, 1};
    // // branch exception (flush anything after ROB#7)
    // test1_out[31] = '{ 7, 17, 1, 0, 2, 7};
    // test1_out[32] = '{ 4, 14, 1, 0, 2, 4};
    // test1_out[33] = '{12, 22, 1, 0, 2, 5};
    // test1_out[34] = '{ 3, 13, 1, 0, 3, 3};
    // test1_out[35] = '{ 3, 13, 0, 0, 4, 3};
    // // reset and fill up the ROB and flush the head
    // test1_out[36] = '{10, 20, 0, 0, 0, 0}; // reset here
    // test1_out[37] = '{ 0, 10, 1, 0, 0, 0};
    // test1_out[38] = '{ 1, 11, 1, 0, 0, 1};
    // test1_out[39] = '{ 2, 12, 1, 0, 0, 2};
    // test1_out[40] = '{ 3, 13, 1, 0, 0, 3};
    // test1_out[41] = '{ 4, 14, 1, 0, 0, 4};
    // test1_out[42] = '{ 5, 15, 1, 0, 0, 5};
    // test1_out[43] = '{ 6, 16, 1, 0, 0, 6};
    // test1_out[44] = '{ 7, 17, 1, 1, 0, 7};
    // test1_out[45] = '{ 0, 10, 1, 0, 0, 0};


    // Reset
    en    = 1'b1;
    clock = 1'b0;
    reset = 1'b0;
    pr_packet_in = 0;

    @(negedge clock);
    reset = 1'b1;
    
    // Cycle 0
    @(negedge clock);
    reset = 1'b0;
    check_Sol(cycle_count, pr_packet_out, test1_out[cycle_count]);
    $display("cycle_count = %1d", cycle_count);
    pr_packet_in = test1[0];

    // Cycle 1
    @(negedge clock);
    check_Sol(cycle_count, pr_packet_out, test1_out[cycle_count]);
    pr_packet_in = test1[1];

    // // Cycle 2
    // @(negedge clock);
    // check_Sol(cycle_count, pr_packet_out, test1_out[cycle_count]);
    // pr_packet_in = test1[2];

    // // Cycle 3
    // @(negedge clock);
    // check_Sol(cycle_count, pr_packet_out, test1_out[cycle_count]);
    // pr_packet_in = test1[3];

    // // Cycle 4
    // @(negedge clock);
    // check_Sol(cycle_count, pr_packet_out, test1_out[cycle_count]);
    // en = 1'b0;
    // pr_packet_in = test1[4];

    // // Cycle 5
    // @(negedge clock);
    // check_Sol(cycle_count, pr_packet_out, test1_out[cycle_count]);
    // en = 1'b1;
    // pr_packet_in = test1[5];

    // for (int i = 6; i < 35; i=i+1) begin
    //   @(negedge clock);
    //   check_Sol(cycle_count, pr_packet_out, test1_out[cycle_count]);
    //   pr_packet_in = test1[i];
    // end

    // // Cycle 35
    // @(negedge clock);
    // check_Sol(cycle_count, pr_packet_out, test1_out[cycle_count]);
    // reset = 1'b1;
    // pr_packet_in = test1[35];

    // // Cycle 36: Reset takes effect
    // @(negedge clock);
    // //$display("Reset");
    // cycle_count = 36;
    // check_Sol(cycle_count, pr_packet_out, test1_out[cycle_count]);
    // reset = 1'b0;
    // pr_packet_in = test1[36];
    
    // for (int i = 37; i < `TEST1_LEN; i=i+1) begin
    //   @(negedge clock);
    //   check_Sol(cycle_count, pr_packet_out, test1_out[cycle_count]);
    //   pr_packet_in = test1[i];
    // end

    // @(negedge clock);
    // @(negedge clock);
    // @(negedge clock);

    $finish;

  end // initial

endmodule  // module testbench_PR

