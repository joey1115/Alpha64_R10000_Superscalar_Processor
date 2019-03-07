//READ T and T_old of head or tail.
//WRITE T_old and T for Head or tail.
//Increment head (oldest inst).
//Increment tail (newer inst).

`timescale 1ns/100ps

`include "../../sys_defs.vh"
`include "ROB.vh"

`define DEBUG

module ROB (
  input en, clock, reset,
  input ROB_PACKET_IN rob_packet_in,
  input ROB_PACKET_COMPLETE_IN rob_packet_complete_in,

  `ifdef DEBUG
  output ROB_t rob,
  `endif

  output ROB_PACKET_OUT rob_packet_out,
  output ROB_PACKET_OUT_TO_FREELIST rob_packet_out_to_freelist
);

  `ifndef DEBUG
  ROB_t rob;
  `endif

  ROB_t Nrob;

  logic writeTail, moveHead, mispredict, b_t, retire;
  logic [$clog2(`NUM_ROB)-1:0] real_tail_idx;

  always_comb begin
    Nrob = rob;

    // update complete table
    if(rob_packet_complete_in.valid) begin
      for(int i=0; i < `NUM_ROB; i++) begin
        if((rob_packet_complete_in.T == rob.entry[i].T) && rob.entry[i].valid) begin
          Nrob.entry[i].complete = 1;
        end
        // else
        //   Nrob.entry[i].complete = rob.entry[i].complete;
      end
    end

    retire = Nrob.entry[rob.head].complete;

    // condition for Retire
    moveHead = (retire) 
                && en 
                && rob.entry[rob.head].valid;
    // condition for Dispatch
    writeTail = (rob_packet_in.inst_dispatch) 
                && en 
                && (!rob_packet_out.struct_hazard || retire) 
                && !rob_packet_in.branch_mispredict;

    // next state logic
    Nrob.tail = (writeTail) ? (rob.tail + 1) : rob.tail;
    Nrob.head = (moveHead) ? (rob.head + 1) : rob.head;
    Nrob.entry[rob.tail].T = (writeTail) ? rob_packet_in.T_in : rob.entry[rob.tail].T;
    Nrob.entry[rob.tail].T_old = (writeTail) ? rob_packet_in.T_old_in : rob.entry[rob.tail].T_old;
  
    //update valid bits of entry
    if(rob.head != rob.tail) begin
      Nrob.entry[rob.head].valid = (moveHead) ? 0 : rob.entry[rob.head].valid;
      Nrob.entry[rob.head].complete = (moveHead) ? 0 : rob.entry[rob.head].valid;
      Nrob.entry[rob.tail].valid = (writeTail) ? 1 : rob.entry[rob.tail].valid;
    end
    else begin
      Nrob.entry[rob.tail].valid = (writeTail) ? 1 :
                                    (moveHead) ? 0 : rob.entry[rob.head].valid;
      Nrob.entry[rob.tail].complete = (writeTail) ? 1 :
                                      (moveHead) ? 0 : rob.entry[rob.head].complete;
    end

    b_t = rob_packet_in.flush_branch_idx >= rob.tail;

    mispredict = rob_packet_in.branch_mispredict && rob.entry[rob_packet_in.flush_branch_idx].valid;

    if(mispredict) begin
        if(b_t) begin
          for(int i=0; i < `NUM_ROB; i++) begin
            //flush only branch less than tail and greater than branch
            if( i < rob.tail || i > rob_packet_in.flush_branch_idx)
              Nrob.entry[i].valid = 0;
          end
        end
        else begin
          for(int i=0; i < `NUM_ROB; i++) begin
            //flush instructions between tail and branch
            if( i < rob.tail && i > rob_packet_in.flush_branch_idx)
              Nrob.entry[i].valid = 0;
          end
        end
        //move tail index to after branch
        Nrob.tail = rob_packet_in.flush_branch_idx + 1;
    end

    //set signals for Freeing freelist
    rob_packet_out_to_freelist.head_T_old_out = rob.entry[rob.head].T_old;
    rob_packet_out_to_freelist.freePR = retire;

  end

  always_comb begin
    real_tail_idx = rob.tail - 1;
    //outputs
    rob_packet_out.out_correct = rob.entry[real_tail_idx].valid;
    //rob_packet_out.ins_rob_idx = real_tail_idx;
    rob_packet_out.T_out = rob.entry[real_tail_idx].T;
    rob_packet_out.T_old_out = rob.entry[real_tail_idx].T_old;
    // output for Complete
    //rob_packet_out.head_idx_out = rob.head;
    // output for Dispatch
    rob_packet_out.struct_hazard = rob.entry[rob.tail].valid;
  end

  always_ff @ (posedge clock) begin
    if(reset) begin
      rob.tail <= `SD 0;
      rob.head <= `SD 0;
      for(int i=0; i < `NUM_ROB; i++) begin
         rob.entry[i].valid <= `SD 0;
         rob.entry[i].complete <= `SD 0;
      end
    end // if (reset) else
    else if(en)begin
      rob <= `SD Nrob;
    end // else if(en)begin
  end // always_ff

endmodule