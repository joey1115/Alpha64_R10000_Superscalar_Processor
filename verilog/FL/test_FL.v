`timescale 1ns/100ps

`include "FL.vh"

module test_FL;

  logic                                    clock,               // system clock
  logic                                    reset,               // system reset
  logic                                    dispatch_en,
  logic                                    rollback_en,
  logic                                    retire_en,
  logic [$clog2(`NUM_ROB)-1:0]             T_old_idx,
  logic [$clog2(`NUM_FL)-1:0]              FL_rollback_idx,
  //`ifdef DEBUG
  logic [`NUM_FL-1:0][$clog2(`NUM_PR)-1:0] FL_table, next_FL_table,
  logic [$clog2(`NUM_FL)-1:0]              head, next_head;
  logic [$clog2(`NUM_FL)-1:0]              tail, next_tail;
  //`endif
  logic                                    FL_valid,
  logic [$clog2(`NUM_ROB)-1:0]             T_idx,
  logic [$clog2(`NUM_FL)-1:0]              FL_idx

  FL UUT(
	  .clock(clock),
	  .reset(reset),
	  .dispatch_en(dispatch_en),
	  .rollback_en(rollback_en),
	  .retire_en(retire_en),
	  .T_old_idx(T_old_idx),
	  .FL_rollback_idx(FL_rollback_idx),
	  .FL_table(FL_table),
	  .next_FL_table(next_FL_table),
	  .head(head),
	  .next_head(next_head),
	  .tail(tail),
	  .next_tail(next_tail),
	  .FL_valid(FL_valid),
	  .T_idx(T_idx),
	  .FL_idx(FL_idx),
  )
  always begin
    #(`VERILOG_CLOCK_PERIOD/2.0);
    clock = ~clock;
  end

  initial begin
  
  clock = 1'b0;
  reset = 1'b0;
  dispatch_en = 1'b0;
  rollback_en = 1'b0;
  retire_en   = 1'b0;

  @(negedge clock);
  reset = 1'b1;
  @(negedge clock);
  reset = 1'b0;
  dispatch_en = 1'b1;
  

  end



endmodule  // module test_FL

