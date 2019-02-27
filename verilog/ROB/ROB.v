//READ T and T_old of head or tail.
//WRITE T_old and T for Head or tail.
//Increment head (oldest inst).
//Increment tail (newer inst).

`timescale 1ns/100ps

`define DEBUG

module ROB (
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

  ROB_t Nrob;


  //logic nextTailValid;
  //logic nextHeadValid;
  //logic [$clog2(`NUM_ROB)-1:0] nextTailPointer, nextHeadPointer;
  //logic [$clog2(`NUM_PR)-1:0] nextT, nextT_old;
  logic writeTail, moveHead, mispredict, b_t;

  always_comb begin
    Nrob = rob;
    // condition for Retire
    moveHead = (rob_packet_in.r) 
                && en 
                && rob.entry[rob.head].valid;
    // condition for Dispatch
    writeTail = (rob_packet_in.inst_dispatch) 
                && en 
                && (!rob_packet_out.struct_hazard || rob_packet_in.r) 
                && !rob_packet_in.branch_mispredict;

    // next state logic
    Nrob.tail = (writeTail) ? (rob.tail + 1) : rob.tail;
    Nrob.head = (moveHead) ? (rob.head + 1) : rob.head;
    Nrob.entry[rob.tail].T = (writeTail) ? rob_packet_in.T_in : rob.entry[rob.tail].T;
    Nrob.entry[rob.tail].T_old = (writeTail) ? rob_packet_in.T_old_in : rob.entry[rob.tail].T_old;
  
    //update valid bits of entry
    Nrob.entry[rob.head].valid = (moveHead) ? 0 : rob.entry[rob.head].valid;
    Nrob.entry[rob.tail].valid = (writeTail) ? 1 : rob.entry[rob.tail].valid;

    b_t = rob_packet_in.flush_branch_idx >= rob.tail;

    mispredict = rob_packet_in.branch_mispredict && rob.entry[rob_packet_in.flush_branch_idx].valid;

    if(mispredict) begin
      $display("mispredict");
        if(b_t) begin
          $display("flush away tail and branch");
          for(int i=0; i < `NUM_ROB; i++) begin
            //flush only branch less than tail and greater than branch
            if( i < rob.tail || i > rob_packet_in.flush_branch_idx)
              Nrob.entry[i].valid = 0;
          end
        end
        else begin
          $display("flush between tail and branch");
          for(int i=0; i < `NUM_ROB; i++) begin
            //flush instructions between tail and branch
            if( i < rob.tail && i > rob_packet_in.flush_branch_idx)
              Nrob.entry[i].valid = 0;
          end
        end
        //move tail index to after branch
        Nrob.tail = rob_packet_in.flush_branch_idx + 1;
    end

    //outputs
    rob_packet_out.out_correct = rob.entry[rob.tail - 1].valid;
    rob_packet_out.ins_rob_idx = rob.tail - 1;
    rob_packet_out.T_out = rob.entry[rob.tail - 1].T;
    rob_packet_out.T_old_out = rob.entry[rob.tail - 1].T_old;
    // output for Complete
    rob_packet_out.head_idx_out = rob.head;
    // output for Dispatch
    rob_packet_out.struct_hazard = Nrob.entry[rob.tail].valid;

  end

  always_ff @ (posedge clock) begin
    if(reset) begin
      rob.tail <= `SD 0;
      rob.head <= `SD 0;
      for(int i=0; i < `NUM_ROB; i++) begin
         rob.entry[i].valid <= `SD 0;
      end
    end
    else begin
      rob <= `SD Nrob;
    end // if (reset) else
  end // always_ff

endmodule