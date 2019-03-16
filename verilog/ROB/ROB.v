//READ T and T_old of head or tail.
//WRITE T_old and T for Head or tail.
//Increment head (oldest inst).
//Increment tail (newer inst).

`timescale 1ns/100ps

`include "../../sys_defs.vh"
`include "ROB.vh"

`define DEBUG

module ROB (
  //inputs
  input en, clock, reset,
  input logic dispatch_en,
  input logic [$clog2(`NUM_PR)-1:0] T_idx, //T_idx
  input logic [$clog2(`NUM_PR)-1:0] Told_idx, //Told_idx
  input logic [$clog2(`NUM_ARCH_TABLE)-1:0] dest_idx, //from the decoder
  
  // rollback function
  input logic [$clog2(`NUM_ROB)-1:0] ROB_rollback_idx,
  input logic rollback_en,

  // complete function
  input ROB_PACKET_COMPLETE_IN rob_packet_complete_in,

  //Outputs
  `ifdef DEBUG
  output ROB_t rob,
  `endif

  output logic ROB_valid,                   //rob_packet_out.struct_hazard
  output ROB_PACKET_RS_OUT rob_packet_rs_out,
  output ROB_PACKET_FREELIST_OUT rob_packet_freelist_out,
  output ROB_PACKET_ARCHMAP_OUT rob_packet_archmap_out,
);

  `ifndef DEBUG
  ROB_t rob;
  `endif

  ROB_t Nrob;

  logic writeTail, moveHead, mispredict, b_t, retire;
  logic [$clog2(`NUM_ROB)-1:0] real_tail_idx;

  always_comb begin
    Nrob = rob;

    retire = Nrob.entry[rob.head].complete;

    // condition for Retire
    moveHead = (retire) 
                && en 
                && rob.entry[rob.head].valid;
    // condition for Dispatch
    writeTail = (dispatch_en) 
                && en 
                && (!rob_packet_out.struct_hazard || retire) 
                && !rollback_en;

    //complete stage
    if(rob_packet_complete_in.complete_en) begin
      Nrob.entry[rob_packet_complete_in.complete_ROB_idx].complete = 1;
    end

    // next state logic
    Nrob.tail = (writeTail) ? (rob.tail + 1) : rob.tail;
    Nrob.head = (moveHead) ? (rob.head + 1) : rob.head;
    Nrob.entry[rob.tail].T = (writeTail) ? T_idx : rob.entry[rob.tail].T;
    Nrob.entry[rob.tail].T_old = (writeTail) ? Told_idx : rob.entry[rob.tail].T_old;
    Nrob.entry[rob.tail].dest_idx = (writeTail) ? dest_idx : rob.entry[rob.tail].dest_idx;
  
    //update valid and complete bits of entry
    if(rob.head != rob.tail) begin
      Nrob.entry[rob.head].valid = (moveHead) ? 0 : rob.entry[rob.head].valid;
      Nrob.entry[rob.head].complete = (moveHead) ? 0 : rob.entry[rob.head].valid;
      Nrob.entry[rob.tail].valid = (writeTail) ? 1 : rob.entry[rob.tail].valid;
      Nrob.entry[rob.tail].complete = (writeTail) ? 0 : rob.entry[rob.tail].complete;
    end
    else begin
      Nrob.entry[rob.tail].valid = (writeTail) ? 1 :
                                    (moveHead) ? 0 : rob.entry[rob.head].valid;
      Nrob.entry[rob.head].complete = (moveHead) ? 0 : rob.entry[rob.head].complete;
    end

    //rollback functionality
    b_t = ROB_rollback_idx >= rob.tail;

    mispredict = rollback_en && rob.entry[ROB_rollback_idx].valid;

    if(mispredict) begin
        if(b_t) begin
          for(int i=0; i < `NUM_ROB; i++) begin
            //flush only branch less than tail and greater than branch
            if( i < rob.tail || i > ROB_rollback_idx)
              Nrob.entry[i].valid = 0;
          end
        end
        else begin
          for(int i=0; i < `NUM_ROB; i++) begin
            //flush instructions between tail and branch
            if( i < rob.tail && i > ROB_rollback_idx)
              Nrob.entry[i].valid = 0;
          end
        end
        //move tail index to after branch
        Nrob.tail = ROB_rollback_idx + 1;
    end

    //set signals for Freeing freelist
    rob_packet_out_to_freelist.head_T_old_out = rob.entry[rob.head].T_old;
    rob_packet_out_to_freelist.freePR = retire;

  end

  always_comb begin
    real_tail_idx = rob.tail - 1;
  
    // tail index
    rob_packet_rs_out.ROB_tail_idx = real_tail_idx;
    rob_packet_freelist_out.ROB_tail_idx = real_tail_idx;
    
    //retire archmap signal
    rob_packet_archmap_out.retire_en = retire;
    rob_packet_archmap_out.dest_idx = rob.entry[real_tail_idx].dest_idx;
    rob_packet_archmap_out.T_idx_head = rob.entry[real_tail_idx].T_idx_head;

    //ROB hazard
    ROB_valid = !rob.entry[rob.tail].valid;
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