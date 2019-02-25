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
  logic r;
  logic inst_dispatch;
  logic [$clog2(`NUM_PR)-1:0] T_in;
  logic [$clog2(`NUM_PR)-1:0] T_old_in;
} ROB_PACKET_IN;

typedef struct packed {
  logic [$clog2(`NUM_PR)-1:0] T_out;
  logic [$clog2(`NUM_PR)-1:0] T_old_out;
  logic out_correct;
  logic struct_hazard;
  logic [$clog2(`NUM_ROB)-1:0] head_idx_out;
  logic [$clog2(`NUM_ROB)-1:0] ins_rob_idx;
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
  rob_m DUT(
    .en(en),
    .clock(clock),
    .reset(reset),
    .rob_packet_in(rob_packet_in),
    .rob_packet_out(rob_packet_out),
    .rob(rob)
  );

  logic [31:0] cycle_count;

/*   task show_ROB;
    input [31:0] start_addr;
    input [31:0] end_addr;
    int showing_data;
    begin
    
    end
  endtask  // task show_ROB */

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

  always @(negedge clock) begin
    $display("\n");
    $display("cycle:%3d", cycle_count);
    $display("head:%4d", rob.head);
    $display("tail:%4d", rob.tail);
    $display("entry0:%2d", rob.entry[0].valid);
  end

  initial begin
    $display("_____________");
    $display("| Time:%4.0f |", $time);
    // Reset
    en    = 1'b1;
    clock = 1'b0;
    reset = 1'b0;
    @(negedge clock);
    reset = 1'b1;

    // Load initial line

    // Test begins
    @(negedge clock);
    reset = 1'b0;

    @(negedge clock);
    @(negedge clock);
    @(negedge clock);
    @(negedge clock);

    $finish;

  end // initial

endmodule  // module testbench_ROB

