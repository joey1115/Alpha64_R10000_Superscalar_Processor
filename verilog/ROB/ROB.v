//READ T and T_old of head or tail.
//WRITE T_old and T for Head or tail.
//Increment head (oldest inst).
//Increment tail (newer inst).

`timescale 1ns/100ps

`define DEBUG

module rob_m (
  input en, clock, reset,
  input ROB_PACKET_IN rob_packet_in,

  `ifdef DEBUG
  output ROB_t rob,
  `endif

  output ROB_PACKET_OUT rob_packet_out
);

  `ifndef DEBUG
  ROB_t rob;
  `endif

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
    // To flush instructions in ROB until branch
    else if(rob_packet_in.branch_mispredict) begin 
      //if the branch idx is greater or equal to tail
      if(rob_packet_in.flush_branch_idx >= rob.tail) begin
        for(int i=0; i < `NUM_ROB; i++) begin
          //flush only branch greater less than tail and greater than branch
          if( i < rob.tail || i > rob_packet_in.flush_branch_idx)
            rob.entry[i].valid <= `SD 0;
        end
      end
      //if the branch idx is less than to tail
      else begin
        for(int i=0; i < `NUM_ROB; i++) begin
          //flush instructions between tail and branch
          if( i < rob.tail && i > rob_packet_in.flush_branch_idx)
            rob.entry[i].valid <= `SD 0;
        end
      end
    end
    else begin
      rob.tail <= `SD nextTailPointer;
      rob.head <= `SD nextHeadPointer;

      rob.entry[rob.tail].T <= `SD nextT;
      rob.entry[rob.tail].T_old <= `SD nextT_old;
      rob.entry[rob.tail].valid <= `SD nextTailValid;
      if (rob.tail != rob.head) begin
        rob.entry[rob.head].valid <= `SD nextHeadValid;
      end
    end // if (reset) else
  end // always_ff

  always_comb begin
    // for Retire
    moveHead = (rob_packet_in.r) && en;
    nextHeadPointer = (moveHead) ? (rob.head + 1) : rob.head;
    nextHeadValid = (moveHead) ? 0 : rob.entry[rob.head].valid;
    // for Complete
    rob_packet_out.head_idx_out = rob.head;
    // for Dispatch
    rob_packet_out.struct_hazard = rob.entry[rob.tail].valid;
    writeTail = (rob_packet_in.inst_dispatch) && en && ~rob_packet_out.struct_hazard;

    nextTailPointer = (writeTail) ? (rob.tail + 1) : rob.tail;
    nextT = (writeTail) ? rob_packet_in.T_in : rob.entry[rob.tail].T;
    nextT_old = (writeTail) ? rob_packet_in.T_old_in : rob.entry[rob.tail].T_old;
    nextTailValid = (writeTail) ? 1 : rob.entry[rob.tail].valid;

    rob_packet_out.out_correct = rob.entry[rob.tail - 1].valid;
    //rob_packet_out.ins_rob_idx = (rob.tail - 1);
    rob_packet_out.ins_rob_idx = rob.tail;
    rob_packet_out.T_out = rob.entry[rob.tail - 1].T;
    rob_packet_out.T_old_out = rob.entry[rob.tail - 1].T_old;

  end
endmodule