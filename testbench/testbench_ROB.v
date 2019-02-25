/////////////////////////////////////////////////////////////////////////
//                                                                     //
//                                                                     //
//   Modulename :  testbench_ROB.v                                     //
//                                                                     //
//  Description :  Testbench module for ROB module;                    //
//                                                                     //
//                                                                     //
/////////////////////////////////////////////////////////////////////////

/***** Quick Lookup *****

`define NUM_PR                 64
`define NUM_ROB                8

typedef struct packed {
  logic valid;
  logic [$clog2(`NUM_PR)-1:0] T;
  logic [$clog2(`NUM_PR)-1:0] T_old;
} ROB_ENTRY_t;

typedef struct packed {
  logic [$clog2(`NUM_ROB)-1:0] head;
  logic [$clog2(`NUM_ROB)-1:0] tail;
  ROB_ENTRY_t [`NUM_ROB-1:0] entry;
} ROB_t;

typedef struct packed {
  logic r;                                        //retire, increase head, invalidate entry
  logic inst_dispatch;                            //dispatch, increase tail, validate entry
  logic [$clog2(`NUM_PR)-1:0] T_in;               //T_in data to input to T during dispatch
  logic [$clog2(`NUM_PR)-1:0] T_old_in;           //T_onld_in data to input to T_old during dispatch
  logic [$clog2(`NUM_ROB)-1:0] flush_branch_idx;  //ROB idx of branch inst
  logic branch_mispredict;                        //set high when branch mispredicted, will invalidate entry except branch inst
} ROB_PACKET_IN;

typedef struct packed {
  logic [$clog2(`NUM_PR)-1:0] T_out;              //output tail's T
  logic [$clog2(`NUM_PR)-1:0] T_old_out;          //output tail's T_old
  logic out_correct;                              //tells whether output is valid (empty entry)
  logic struct_hazard;                            //tells whether structural hazard reached
  logic [$clog2(`NUM_ROB)-1:0] head_idx_out;      //tells the rob idx of the head
  logic [$clog2(`NUM_ROB)-1:0] ins_rob_idx;       //tells the rob idx of the dispatched inst
} ROB_PACKET_OUT;

 ***********************/

`timescale 1ns/100ps

`include "sys_defs.vh"

module testbench_ROB;

  // DUT input stimulus
  logic en, clock, reset;
  ROB_PACKET_IN rob_packet_in;

  // DUT output
  ROB_PACKET_OUT rob_packet_out;
  ROB_t          rob;

  // DUT instantiation
  rob_m UUT(
    .en(en),
    .clock(clock),
    .reset(reset),
    .rob_packet_in(rob_packet_in),
    .rob_packet_out(rob_packet_out),
    .rob(rob)
  );

  logic [31:0] cycle_count;

  // Test Cases #1: Lecture Slides
  `define TEST1_LEN 21
  ROB_PACKET_IN  [`TEST1_LEN-1:0] test1;
  // solutions have one more state than test cases
  ROB_PACKET_OUT   [`TEST1_LEN:0] test1_out;

  // Check Sol: compare ROB output to solution
  task check_Sol;
    input logic   [31:0] cycle_count;
    input ROB_PACKET_OUT uut_out;
    input ROB_PACKET_OUT sol_out;
    int pass;
    begin
      pass = 1;
      $display("********* Cycle %2d *********", cycle_count);
      if (uut_out.T_out != sol_out.T_out && cycle_count != 0) begin
        $display("Incorrect rob_packet_out.T_out");
        $display("UUT output: %1d", uut_out.T_out);
        $display("sol output: %1d", sol_out.T_out);
        pass = 0;
      end
      if (uut_out.T_old_out != sol_out.T_old_out && cycle_count != 0) begin
        $display("Incorrect rob_packet_out.T_old_out");
        $display("UUT output: %1d", uut_out.T_old_out);
        $display("sol output: %1d", sol_out.T_old_out);
        pass = 0;
      end
      if (uut_out.out_correct != sol_out.out_correct) begin
        $display("Incorrect rob_packet_out.out_correct");
        $display("UUT output: %1d", uut_out.out_correct);
        $display("sol output: %1d", sol_out.out_correct);
        pass = 0;
      end
      if (uut_out.struct_hazard != sol_out.struct_hazard) begin
        $display("Incorrect rob_packet_out.struct_hazard");
        $display("UUT output: %1d", uut_out.struct_hazard);
        $display("sol output: %1d", sol_out.struct_hazard);
        pass = 0;
      end
      if (uut_out.head_idx_out != sol_out.head_idx_out) begin
        $display("Incorrect rob_packet_out.head_idx_out");
        $display("UUT output: %1d", uut_out.head_idx_out);
        $display("sol output: %1d", sol_out.head_idx_out);
        pass = 0;
      end
      if (uut_out.ins_rob_idx != sol_out.ins_rob_idx) begin
        $display("Incorrect rob_packet_out.ins_rob_idx");
        $display("UUT output: %1d", uut_out.ins_rob_idx);
        $display("sol output: %1d", sol_out.ins_rob_idx);
        pass = 0;
      end
      if (pass == 1)
        $display("@@@Pass!\n");
      else
        $display("@@@fail\n");
    end
  endtask // task check_Sol

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

  // Check correctness
  always @(negedge clock) begin
    if (cycle_count >= 0 && cycle_count <= `TEST1_LEN)
      check_Sol(cycle_count, rob_packet_out, test1_out[cycle_count]);
  end

  initial begin

    /***** Test Case #1 *****/

    // test1[c]: input at cycle c
    // {r, inst_dispatch, T_in, T_old_in, flush_branch_idx, branch_mispredict}
    // Cycle 0-6: simulates Lecture Slides with stalls added
    test1[0]  = '{0, 1,  5,  2, 0, 0};
    test1[1]  = '{0, 0,  6,  3, 0, 0}; // test stall (inst_dispatch)
    test1[2]  = '{0, 1,  6,  3, 0, 0};
    test1[3]  = '{0, 1, 31, 31, 0, 0}; // store inst, no destination
    test1[4]  = '{0, 1,  7,  4, 0, 0}; // test stall (enable) here
    test1[5]  = '{0, 1,  7,  4, 0, 0};
    test1[6]  = '{1, 1,  8,  5, 0, 0};
    // Cycle 7-10: fill up all entries of ROB
    test1[7]  = '{0, 1,  9, 19, 0, 0};
    test1[8]  = '{0, 1, 10, 20, 0, 0};
    test1[9]  = '{0, 1, 11, 21, 0, 0};
    test1[10] = '{0, 1, 12, 22, 0, 0};
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

    // test1_out[c]: output at cycle c (test1[c]'s effect is shown by test1_out[c+1])
    // {T_out, T_old_out, out_correct, struct_hazard, head_idx_out, ins_rob_idx}
    // Cycle 0 tests reset
    test1_out[0]  = '{ 0,  0, 0, 0, 0, 0}; // T_out, T_old_out should be don't care
    // simulates lecture slides with stalls added
    test1_out[1]  = '{ 5,  2, 1, 0, 0, 0};
    test1_out[2]  = '{ 5,  2, 1, 0, 0, 0};
    test1_out[3]  = '{ 6,  3, 1, 0, 0, 1};
    test1_out[4]  = '{31, 31, 1, 0, 0, 2};
    test1_out[5]  = '{31, 31, 1, 0, 0, 2};
    test1_out[6]  = '{ 7,  4, 1, 0, 0, 3};
    test1_out[7]  = '{ 8,  5, 1, 0, 1, 4};
    // all entries of ROB are filled at cycle 11
    test1_out[8]  = '{ 9, 19, 1, 0, 1, 5};
    test1_out[9]  = '{10, 20, 1, 0, 1, 6};
    test1_out[10] = '{11, 21, 1, 0, 1, 7};
    test1_out[11] = '{12, 22, 1, 0, 1, 0}; // test ROB# roll-over
    // struct hazard happens here
    test1_out[12] = '{12, 22, 0, 1, 1, 0};
    // the head retires and the new inst takes its entry
    test1_out[13] = '{13, 13, 1, 0, 2, 1};
    // retire all instructions
    test1_out[14] = '{13, 13, 1, 0, 3, 1};
    test1_out[15] = '{13, 13, 1, 0, 4, 1};
    test1_out[16] = '{13, 13, 1, 0, 5, 1};
    test1_out[17] = '{13, 13, 1, 0, 6, 1};
    test1_out[18] = '{13, 13, 1, 0, 7, 1};
    test1_out[19] = '{13, 13, 1, 0, 0, 1}; // test ROB head idx roll-over
    test1_out[20] = '{13, 13, 1, 0, 1, 1};
    test1_out[21] = '{13, 13, 0, 0, 2, 1};



    // Reset
    en    = 1'b1;
    clock = 1'b0;
    reset = 1'b0;
    
    // Cycle 0 input
    @(negedge clock);
    reset = 1'b1;
    rob_packet_in = test1[0];

    // Cycle 1 input
    @(negedge clock);
    reset = 1'b0;
    rob_packet_in = test1[1];

    // Cycle 2 input
    @(negedge clock);
    rob_packet_in = test1[2];

    // Cycle 3 input
    @(negedge clock);
    en = 1'b0;
    rob_packet_in = test1[2];

    // Cycle 4 input
    @(negedge clock);
    en = 1'b1;
    rob_packet_in = test1[3];

    // Cycle 5 input
    @(negedge clock);
    rob_packet_in = test1[4];

    // Cycle 6 input
    @(negedge clock);
    rob_packet_in = test1[5];

    for (int i = 6; i < `TEST1_LEN; i=i+1) begin
      @(negedge clock);
      rob_packet_in = test1[i];
    end

    @(negedge clock);
    @(negedge clock);
    @(negedge clock);

    $finish;

  end // initial

endmodule  // module testbench_ROB

