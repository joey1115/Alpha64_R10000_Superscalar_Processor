`timescale 1ns/100ps

`include "sys_defs.vh"

module testbench_map_table;

  // DUT input stimulus
  logic en, clock, reset;
  MAP_TABLE_PACKET_IN map_table_packet_in;

  // DUT output
  MAP_TABLE_PACKET_OUT map_table_packet_out;
  MAP_TABLE_t          map_table;

  // DUT instantiation
  map_table UUT(
    .en(en),
    .clock(clock),
    .reset(reset),
    .map_table_packet_in(map_table_packet_in),
    .map_table_packet_out(map_table_packet_out)
  );

  logic [31:0] cycle_count;

  // Test Cases #1: Lecture Slides
  `define TEST1_LEN 5
  map_table_packet_in  [`TEST1_LEN-1:0] test1;
  // solutions have one more state than test cases
  map_table_packet_out   [`TEST1_LEN:0] test1_out;

  // Check Sol: compare ROB output to solution
  task check_Sol;
    input logic   [31:0] cycle_count;
    input map_table_packet_out uut_out;
    input map_table_packet_out sol_out;
    int pass;
    begin
      pass = 1;
      $display("********* Cycle %2d *********", cycle_count);
      if (uut_out.T_out != sol_out.T_out && sol_out.out_correct != 0) begin
        $display("Incorrect map_table_packet_out.T_out");
        $display("UUT output: %1d", uut_out.T_out);
        $display("sol output: %1d", sol_out.T_out);
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
      check_Sol(cycle_count, map_table_packet_out, test1_out[cycle_count]);
  end

  initial begin

    /***** Test Case #1 *****/

    // test1[c]: input at cycle c
    // {r, inst_dispatch, T_in, T_old_in, flush_branch_idx, branch_mispredict}
    // Cycle 0-6: simulates Lecture Slides with stalls added
    test1[0]  = '{1, 1,  33,  20, 1};
    test1[1]  = '{1, 2,  34,  19, 1}; // test stall (inst_dispatch)
	test1[2]  = '{1, 3,  35,  18, 1};
	test1[3]  = '{1, 4,  36,  17, 1};
	test1[4]  = '{1, 5,  37,  16, 1};

    
    // Cycle 0 tests reset
    test1_out[0]  = '{1}; // T_out, T_old_out should be don't care
    // simulates lecture slides with stalls added
    test1_out[1]  = '{2};
	test1_out[2]  = '{3};
	test1_out[3]  = '{4};
	test1_out[4]  = '{5};


    // Reset
    en    = 1'b1;
    clock = 1'b0;
    reset = 1'b0;

    @(negedge clock);
    reset = 1'b1;
    
    // Cycle 0 input
    @(negedge clock);
    reset = 1'b0;
    map_table_packet_in = test1[0];

    // Cycle 1 input
    @(negedge clock);
    reset = 1'b0;
    map_table_packet_in = test1[1];

    // Cycle 2 input
    @(negedge clock);
    map_table_packet_in = test1[2];

    // Cycle 3 input
    @(negedge clock);
    map_table_packet_in = test1[3];

    // Cycle 4 input
    @(negedge clock);
    en = 1'b0;
    map_table_packet_in = test1[4];

    $finish;

  end // initial

endmodule  // module testbench_ROB

/* 
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
} ROB_PACKET_OUT; */