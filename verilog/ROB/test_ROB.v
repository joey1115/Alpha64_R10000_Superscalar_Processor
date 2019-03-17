/////////////////////////////////////////////////////////////////////////
//                                                                     //
//                                                                     //
//   Modulename :  testbench_ROB.v                                     //
//                                                                     //
//  Description :  Testbench module for ROB module;                    //
//                                                                     //
//                                                                     //
/////////////////////////////////////////////////////////////////////////

`timescale 1ns/100ps

`include "../../sys_defs.vh"
`include "ROB.vh"

module test_ROB;

  //input
  logic en;
  logic clock;
  logic reset;
  logic dispatch_en;
  logic [$clog2(`NUM_PR)-1:0] T_idx;
  logic [$clog2(`NUM_PR)-1:0] Told_idx;
  logic [$clog2(`NUM_ARCH_TABLE)-1:0] dest_idx;
  logic [$clog2(`NUM_ROB)-1:0] ROB_rollback_idx;
  logic rollback_en;
  ROB_PACKET_COMPLETE_IN rob_packet_complete_in;

  //output
  ROB_t rob;
  logic ROB_valid;
  ROB_PACKET_RS_OUT rob_packet_rs_out;
  ROB_PACKET_FREELIST_OUT rob_packet_freelist_out;
  ROB_PACKET_ARCHMAP_OUT rob_packet_archmap_out;

  ROB UUT(.en(en),
          .clock(clock),
          .reset(reset),
          .dispatch_en(dispatch_en),
          .T_idx(T_idx),
          .Told_idx(Told_idx),
          .dest_idx(dest_idx),
          .ROB_rollback_idx(ROB_rollback_idx),
          .rollback_en(rollback_en),
          .rob(rob),
          .ROB_valid(ROB_valid),
          .rob_packet_rs_out(rob_packet_rs_out),
          .rob_packet_freelist_out(rob_packet_freelist_out),
          .rob_packet_archmap_out(rob_packet_archmap_out)
  );

  task printInput;
      begin
        $display("---------------------------INPUT START----------------------------");
        $display(" en | reset | dispatch_en | T_idx | T_old_idx | dest_idx | ROB_rollback_idx | rollback_en | dispatch en | complete_en | complete_ROB_idx");
        $display(" %b  |  %b    |      %b     | %d | %d | %d | %d | %b | %b | %d |",
                  en,
                  reset,
                  dispatch_en,
                  [$clog2(`NUM_PR)-1:0] T_idx,
                  [$clog2(`NUM_PR)-1:0] Told_idx,
                  [$clog2(`NUM_ARCH_TABLE)-1:0] dest_idx,
                  [$clog2(`NUM_ROB)-1:0] ROB_rollback_idx,
                  rollback_en,
                  complete_en,
                  [$clog2(`NUM_ROB)-1:0] complete_ROB_idx);
        $display("---------------------------INPUT END-----------------------------");
      end
  endtask

  task printOutput;
    begin
      $display("---------------------------OUTPUT START----------------------------");
      $display(" ROB_valid: %b", ROB_valid);
      $display(" rob_packet_rs_out.rob_tail_idx: %d", rob_packet_rs_out.rob_tail_idx);
      $display("rob_packet_freelist_out.ROB_tail_idx: %d", rob_packet_freelist_out.ROB_tail_idx);
      $display("rob_packet_archmap_out.dest_idx: %d", rob_packet_archmap_out.dest_idx);
      $display("rob_packet_archmap_out.T_idx_head: %d", rob_packet_archmap_out.T_idx_head);
      $display("rob_packet_archmap_out.retire_en: %d", rob_packet_archmap_out.retire_en);
    end
  endtask

  task printOut;
    begin
      $display("---------------------------ROB START----------------------------");
      $display("head: %d\ntail: %d", rob.head, rob.tail - 1);
      $display(" # | valid | T | T_old | dest_idx | complete");
      for(int i = 0; i < NUM_ROB; i++) begin
        $display(" %d |   %b   | %d | %d | %d | %b",
                i,
                rob.entry[i].valid,
                rob.entry[i].T,
                rob.entry[i].T_old,
                rob.entry[i].dest_idx,
                rob.entry[i].complete);
      end
      $display("---------------------------ROB END-----------------------------");
    end
  endtask

  task setInput(
    logic en_in,
    logic reset_in,
    logic dispatch_en_in,
    logic [$clog2(`NUM_PR)-1:0] T_idx_in,
    logic [$clog2(`NUM_PR)-1:0] Told_idx_in,
    logic [$clog2(`NUM_ARCH_TABLE)-1:0] dest_idx_in,
    logic [$clog2(`NUM_ROB)-1:0] ROB_rollback_idx_in,
    logic rollback_en_in,
    logic complete_en_in,
    logic [$clog2(`NUM_ROB)-1:0] complete_ROB_idx_in);
      
    begin
      printInput();

      //set input
      en = en_in;
      reset = reset_in;
      dispatch_en = dispatch_en_in;
      T_idx = T_idx_in;
      Told_idx = Told_idx_in;
      dest_idx = dest_idx_in;
      ROB_rollback_idx = ROB_rollback_idx_in;
      rollback_en = rollback_en_in;
      rob_packet_complete_in.complete_en = complete_en;
      rob_packet_complete_in.complete_ROB_idx = complete_ROB_idx_in;
      //wait unitl clocks
      @ (negedge clock);
      @ (posedge clock);
      printOut();
      printOutput();
      
    end
  endtask

  initial begin
    
    // Reset
    en    = 1'b1;
    clock = 1'b0;
    reset = 1'b1;
    rob_packet_in = 0;

    @(negedge clock);

    setInput(en_in.(1),
            .reset_in(0),
            .dispatch_en_in(1),
            .T_idx_in(11),
            .Told_idx_in(01),
            .dest_idx_in(1),
            .ROB_rollback_idx_in(0),
            .rollback_en_in(0),
            .complete_en(0),
            .complete_ROB_idx_in(0));

    setInput(en_in.(1),
            .reset_in(0),
            .dispatch_en_in(1),
            .T_idx_in(12),
            .Told_idx_in(02),
            .dest_idx_in(2),
            .ROB_rollback_idx_in(0),
            .rollback_en_in(0),
            .complete_en(0),
            .complete_ROB_idx_in(0));

    $finish;
  end



//   // DUT input stimulus
//   logic en, clock, reset;
//   ROB_PACKET_IN rob_packet_in;

//   // DUT output
//   ROB_PACKET_OUT rob_packet_out;
//   ROB_t          rob;

//   // DUT instantiation
//   ROB UUT(
//     .en(en),
//     .clock(clock),
//     .reset(reset),
//     .rob_packet_in(rob_packet_in),
//     .rob_packet_out(rob_packet_out),
//     .rob(rob)
//   );

//   logic [31:0] cycle_count;

//   // Test Cases #1: Lecture Slides
//   `define TEST1_LEN 46
//   ROB_PACKET_IN  [`TEST1_LEN-1:0] test1;
//   // solutions have one more state than test cases
//   ROB_PACKET_OUT   [`TEST1_LEN:0] test1_out;

//   // Check Sol: compare ROB output to solution
//   task check_Sol;
//     input logic   [31:0] cycle_count;
//     input ROB_PACKET_OUT uut_out;
//     input ROB_PACKET_OUT sol_out;
//     int pass;
//     begin
//       pass = 1;
//       $display("********* Cycle %2d *********", cycle_count);
//       if (uut_out.T_out != sol_out.T_out && sol_out.out_correct != 0) begin
//         $display("Incorrect rob_packet_out.T_out");
//         $display("UUT output: %1d", uut_out.T_out);
//         $display("sol output: %1d", sol_out.T_out);
//         pass = 0;
//       end
//       if (uut_out.T_old_out != sol_out.T_old_out && sol_out.out_correct != 0) begin
//         $display("Incorrect rob_packet_out.T_old_out");
//         $display("UUT output: %1d", uut_out.T_old_out);
//         $display("sol output: %1d", sol_out.T_old_out);
//         pass = 0;
//       end
//       if (uut_out.out_correct != sol_out.out_correct) begin
//         $display("Incorrect rob_packet_out.out_correct");
//         $display("UUT output: %1d", uut_out.out_correct);
//         $display("sol output: %1d", sol_out.out_correct);
//         pass = 0;
//       end
//       if (uut_out.struct_hazard != sol_out.struct_hazard) begin
//         $display("Incorrect rob_packet_out.struct_hazard");
//         $display("UUT output: %1d", uut_out.struct_hazard);
//         $display("sol output: %1d", sol_out.struct_hazard);
//         pass = 0;
//       end
//       if (uut_out.head_idx_out != sol_out.head_idx_out) begin
//         $display("Incorrect rob_packet_out.head_idx_out");
//         $display("UUT output: %1d", uut_out.head_idx_out);
//         $display("sol output: %1d", sol_out.head_idx_out);
//         pass = 0;
//       end
//       if (uut_out.ins_rob_idx != sol_out.ins_rob_idx && sol_out.out_correct != 0) begin
//         $display("Incorrect rob_packet_out.ins_rob_idx");
//         $display("UUT output: %1d", uut_out.ins_rob_idx);
//         $display("sol output: %1d", sol_out.ins_rob_idx);
//         pass = 0;
//       end
//       if (pass == 1)
//         $display("@@@Pass!\n");
//       else
//         $display("@@@fail\n");
//     end
//   endtask // task check_Sol

//   // Generate System Clock
//   always begin
//     #(`VERILOG_CLOCK_PERIOD/2.0);
//     clock = ~clock;
//   end

//   // Update cycle count
//   always @(posedge clock) begin
//     if(reset)
//       cycle_count <= `SD 0;
//     else
//       cycle_count <= `SD (cycle_count + 1);
//   end


//   initial begin

//     /***** Test Case #1 *****/

//     // test1[c]: input at cycle c, the corresponding output will be at cycle c+1
//     // {r, inst_dispatch, T_in, T_old_in, flush_branch_idx, branch_mispredict}
//     // Cycle 0-6: simulates Lecture Slides with stalls added
//     test1[0]  = '{0, 1,  5,  2, 0, 0};
//     test1[1]  = '{0, 0,  6,  3, 0, 0}; // test stall (inst_dispatch)
//     test1[2]  = '{0, 1,  6,  3, 0, 0};
//     test1[3]  = '{0, 1, 31, 31, 0, 0}; // store inst, no destination
//     test1[4]  = '{0, 1,  7,  4, 0, 0}; // test stall (enable) here
//     test1[5]  = '{0, 1,  7,  4, 0, 0};
//     test1[6]  = '{1, 1,  8,  5, 0, 0};
//     // Cycle 7-10: fill up all entries of ROB
//     test1[7]  = '{0, 1,  9, 19, 0, 0};
//     test1[8]  = '{0, 1, 10, 20, 0, 0};
//     test1[9]  = '{0, 1, 11, 21, 0, 0};
//     test1[10] = '{0, 1, 12, 22, 0, 0};
//     // Cycle 11: check struct hazard detection
//     test1[11] = '{0, 1, 13, 23, 0, 0};
//     // Cycle 12: the head retires and new inst should be dispatched at the same cycle
//     test1[12] = '{1, 1, 13, 23, 0, 0};
//     // Cycle 13-20: retire all instructions
//     test1[13] = '{1, 0, 14, 24, 0, 0};
//     test1[14] = '{1, 0, 14, 24, 0, 0};
//     test1[15] = '{1, 0, 14, 24, 0, 0};
//     test1[16] = '{1, 0, 14, 24, 0, 0};
//     test1[17] = '{1, 0, 14, 24, 0, 0};
//     test1[18] = '{1, 0, 14, 24, 0, 0};
//     test1[19] = '{1, 0, 14, 24, 0, 0};
//     test1[20] = '{1, 0, 14, 24, 0, 0};
//     // Cycle 21: try retire when ROB is empty
//     test1[21] = '{1, 0, 14, 24, 0, 0};
//     // Cycle 22-29: fill in instructions again
//     test1[22] = '{0, 1,  2, 12, 0, 0};
//     test1[23] = '{0, 1,  3, 13, 0, 0};
//     test1[24] = '{0, 1,  4, 14, 0, 0};
//     test1[25] = '{0, 1,  5, 15, 0, 0};
//     test1[26] = '{0, 1,  6, 16, 0, 0};
//     test1[27] = '{0, 1,  7, 17, 0, 0};
//     test1[28] = '{0, 1, 10, 20, 0, 0};
//     test1[29] = '{0, 1, 11, 21, 0, 0};
//     // Cycle 30: branch exception
//     test1[30] = '{0, 1, 12, 22, 7, 1}; // flush anything after ROB#7 (with inst_dispatch ON)
//     test1[31] = '{0, 0, 12, 22, 4, 1}; // flush right after flush
//     test1[32] = '{0, 1, 12, 22, 4, 0}; // write something after flush
//     test1[33] = '{1, 1, 13, 23, 3, 1}; // flush and retire at the same time
//     test1[34] = '{1, 0, 13, 23, 3, 1}; // flush again at the same spot, and retire
//     // Cycle 35-43: reset and fill up the ROB and flush the head
//     test1[35] = '{0, 1, 10, 20, 0, 0}; // reset here
//     test1[36] = '{0, 1,  0, 10, 0, 0};
//     test1[37] = '{0, 1,  1, 11, 0, 0};
//     test1[38] = '{0, 1,  2, 12, 0, 0};
//     test1[39] = '{0, 1,  3, 13, 0, 0};
//     test1[40] = '{0, 1,  4, 14, 0, 0};
//     test1[41] = '{0, 1,  5, 15, 0, 0};
//     test1[42] = '{0, 1,  6, 16, 0, 0};
//     test1[43] = '{0, 1,  7, 17, 0, 0};
//     test1[44] = '{0, 0, 13, 23, 0, 1}; // flush at index 0 (head)

//     // test1_out[c]: output at cycle c (test1[c]'s effect is shown by test1_out[c+1])
//     // {T_out, T_old_out, out_correct, struct_hazard, head_idx_out, ins_rob_idx}
//     // Cycle 0 tests reset
//     test1_out[0]  = '{ 0,  0, 0, 0, 0, 0}; // T_out, T_old_out should be don't care
//     // simulates lecture slides with stalls added
//     test1_out[1]  = '{ 5,  2, 1, 0, 0, 0};
//     test1_out[2]  = '{ 5,  2, 1, 0, 0, 0};
//     test1_out[3]  = '{ 6,  3, 1, 0, 0, 1};
//     test1_out[4]  = '{31, 31, 1, 0, 0, 2};
//     test1_out[5]  = '{31, 31, 1, 0, 0, 2};
//     test1_out[6]  = '{ 7,  4, 1, 0, 0, 3};
//     test1_out[7]  = '{ 8,  5, 1, 0, 1, 4};
//     // all entries of ROB are filled at cycle 11
//     test1_out[8]  = '{ 9, 19, 1, 0, 1, 5};
//     test1_out[9]  = '{10, 20, 1, 0, 1, 6};
//     test1_out[10] = '{11, 21, 1, 0, 1, 7};
//     test1_out[11] = '{12, 22, 1, 1, 1, 0}; // test ROB# roll-over
//     // struct hazard happens here
//     test1_out[12] = '{12, 22, 1, 1, 1, 0};
//     // the head retires and the new inst takes its entry
//     test1_out[13] = '{13, 23, 1, 1, 2, 1};
//     // retire all instructions
//     test1_out[14] = '{13, 23, 1, 0, 3, 1};
//     test1_out[15] = '{13, 23, 1, 0, 4, 1};
//     test1_out[16] = '{13, 23, 1, 0, 5, 1};
//     test1_out[17] = '{13, 23, 1, 0, 6, 1};
//     test1_out[18] = '{13, 23, 1, 0, 7, 1};
//     test1_out[19] = '{13, 23, 1, 0, 0, 1}; // test ROB head idx roll-over
//     test1_out[20] = '{13, 23, 1, 0, 1, 1};
//     test1_out[21] = '{13, 23, 0, 0, 2, 1};
//     // don't move head when over-retire
//     test1_out[22] = '{13, 23, 0, 0, 2, 1};
//     // fill in instructions again
//     test1_out[23] = '{ 2, 12, 1, 0, 2, 2};
//     test1_out[24] = '{ 3, 13, 1, 0, 2, 3};
//     test1_out[25] = '{ 4, 14, 1, 0, 2, 4};
//     test1_out[26] = '{ 5, 15, 1, 0, 2, 5};
//     test1_out[27] = '{ 6, 16, 1, 0, 2, 6};
//     test1_out[28] = '{ 7, 17, 1, 0, 2, 7};
//     test1_out[29] = '{10, 20, 1, 0, 2, 0};
//     test1_out[30] = '{11, 21, 1, 1, 2, 1};
//     // branch exception (flush anything after ROB#7)
//     test1_out[31] = '{ 7, 17, 1, 0, 2, 7};
//     test1_out[32] = '{ 4, 14, 1, 0, 2, 4};
//     test1_out[33] = '{12, 22, 1, 0, 2, 5};
//     test1_out[34] = '{ 3, 13, 1, 0, 3, 3};
//     test1_out[35] = '{ 3, 13, 0, 0, 4, 3};
//     // reset and fill up the ROB and flush the head
//     test1_out[36] = '{10, 20, 0, 0, 0, 0}; // reset here
//     test1_out[37] = '{ 0, 10, 1, 0, 0, 0};
//     test1_out[38] = '{ 1, 11, 1, 0, 0, 1};
//     test1_out[39] = '{ 2, 12, 1, 0, 0, 2};
//     test1_out[40] = '{ 3, 13, 1, 0, 0, 3};
//     test1_out[41] = '{ 4, 14, 1, 0, 0, 4};
//     test1_out[42] = '{ 5, 15, 1, 0, 0, 5};
//     test1_out[43] = '{ 6, 16, 1, 0, 0, 6};
//     test1_out[44] = '{ 7, 17, 1, 1, 0, 7};
//     test1_out[45] = '{ 0, 10, 1, 0, 0, 0};


//     // Reset
//     en    = 1'b1;
//     clock = 1'b0;
//     reset = 1'b0;
//     rob_packet_in = 0;

//     @(negedge clock);
//     reset = 1'b1;
    
//     // Cycle 0
//     @(negedge clock);
//     reset = 1'b0;
//     check_Sol(cycle_count, rob_packet_out, test1_out[cycle_count]);
//     rob_packet_in = test1[0];

//     // Cycle 1
//     @(negedge clock);
//     check_Sol(cycle_count, rob_packet_out, test1_out[cycle_count]);
//     rob_packet_in = test1[1];

//     // Cycle 2
//     @(negedge clock);
//     check_Sol(cycle_count, rob_packet_out, test1_out[cycle_count]);
//     rob_packet_in = test1[2];

//     // Cycle 3
//     @(negedge clock);
//     check_Sol(cycle_count, rob_packet_out, test1_out[cycle_count]);
//     rob_packet_in = test1[3];

//     // Cycle 4
//     @(negedge clock);
//     check_Sol(cycle_count, rob_packet_out, test1_out[cycle_count]);
//     en = 1'b0;
//     rob_packet_in = test1[4];

//     // Cycle 5
//     @(negedge clock);
//     check_Sol(cycle_count, rob_packet_out, test1_out[cycle_count]);
//     en = 1'b1;
//     rob_packet_in = test1[5];

//     for (int i = 6; i < 35; i=i+1) begin
//       @(negedge clock);
//       check_Sol(cycle_count, rob_packet_out, test1_out[cycle_count]);
//       rob_packet_in = test1[i];
//     end

//     // Cycle 35
//     @(negedge clock);
//     check_Sol(cycle_count, rob_packet_out, test1_out[cycle_count]);
//     reset = 1'b1;
//     rob_packet_in = test1[35];

//     // Cycle 36: Reset takes effect
//     @(negedge clock);
//     //$display("Reset");
//     cycle_count = 36;
//     check_Sol(cycle_count, rob_packet_out, test1_out[cycle_count]);
//     reset = 1'b0;
//     rob_packet_in = test1[36];
    
//     for (int i = 37; i < `TEST1_LEN; i=i+1) begin
//       @(negedge clock);
//       check_Sol(cycle_count, rob_packet_out, test1_out[cycle_count]);
//       rob_packet_in = test1[i];
//     end

//     @(negedge clock);
//     @(negedge clock);
//     @(negedge clock);

//     $finish;

//   end // initial

endmodule  // module testbench_ROB