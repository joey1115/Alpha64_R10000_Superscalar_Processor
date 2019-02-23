//READ T and T_old of head or tail.
//WRITE T_old and T for Head or tail.
//Increment head (oldest inst).
//Increment tail (newer inst).

/***** Quick Lookup *****

`define NUM_PR                 64
`define NUM_ROB                8

struct ROB_PACKET_IN
  logic r;
  logic inst_dispatch;
  logic [$clog2(`NUM_PR)-1:0] T_in;
  logic [$clog2(`NUM_PR)-1:0] T_old_in;

struct ROB_PACKET_OUT
  logic [$clog2(`NUM_PR)-1:0] T_out;
  logic [$clog2(`NUM_PR)-1:0] T_old_out;
  logic out_correct;
  logic struct_hazard;
  logic [$clog2(`NUM_ROB)-1:0] head_idx_out;
  logic [$clog2(`NUM_ROB)-1:0] ins_rob_idx;

struct ROB_t
  logic [$clog2(`NUM_ROB)-1:0] head;
  logic [$clog2(`NUM_ROB)-1:0] tail;
  ROB_ENTRY_t [`NUM_ROB-1:0] entry;

struct ROB_ENTRY_t
  // HT_t                        ht;
  // INST_t                      inst;
  logic valid;
  logic [$clog2(`NUM_PR)-1:0] T;
  logic [$clog2(`NUM_PR)-1:0] T_old;

 ***********************/
`timescale 1ns/100ps

module rob_m (
  input en, clock, reset,
  input ROB_PACKET_IN rob_packet_in,

  output ROB_PACKET_OUT rob_packet_out
);

  ROB_t rob;
  
  logic nextTailValid;
  logic nextHeadValid;
  logic [$clog2(`NUM_ROB)-1:0] nextTailPointer, nextHeadPointer;
  logic [$clog2(`NUM_PR)-1:0] nextT, nextT_old;
  logic writeTail, moveHead;

  always_ff @ (posedge clock) begin
    if(reset) begin
      rob.tail <= `SD 0;
      rob.head <= `SD 0;
      for(int i=0; i < `NUM_ROB; i++) begin
         rob.entry[i].valid <= `SD 0;
      end
    end
    else begin
      rob.tail <= `SD nextTailPointer;
      rob.head <= `SD nextHeadPointer;

      rob.entry[rob.tail].T <= `SD nextT;
      rob.entry[rob.tail].T_old <= `SD nextT_old;
      rob.entry[rob.tail].valid <= `SD nextTailValid;

      rob.entry[rob.head].valid <= `SD nextHeadValid;
    end
  end

  always_comb begin
    writeTail = (rob_packet_in.inst_dispatch) && en && ~rob_packet_out.struct_hazard;
    moveHead = (rob_packet_in.r) && en;

    nextTailPointer = (writeTail) ? (rob.tail + 1) : rob.tail;
    nextT = (writeTail) ? rob_packet_in.T_in : rob.entry[rob.tail].T;
    nextT_old = (writeTail) ? rob_packet_in.T_old_in : rob.entry[rob.tail].T_old;
    nextTailValid = (writeTail) ? 1 : rob.entry[rob.tail].valid;

    nextHeadPointer = (moveHead) ? (rob.head + 1) : rob.head;
    nextHeadValid = (moveHead) ? 0 : rob.entry[rob.head].valid;

    rob_packet_out.out_correct = rob.entry[rob.tail - 1].valid;
    rob_packet_out.ins_rob_idx = (rob.tail - 1);
    rob_packet_out.T_out = rob.entry[rob.tail - 1].T;
    rob_packet_out.T_old_out = rob.entry[rob.tail - 1].T_old;

    rob_packet_out.struct_hazard = rob.entry[rob.tail].valid;

    rob_packet_out.head_idx_out = rob.head;

  end
endmodule