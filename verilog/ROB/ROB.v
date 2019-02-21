//READ T and T_old of head or tail.
//WRITE T_old and T for Head or tail.
//Increment head (oldest inst).
//Increment tail (newer inst).
module rob_m (
  input clock, reset,
  input logic ht,
  input COMMAND cmd, //WRITE, READ
  input increment,    //ADD T/H
  input logic [$clog2(`NUM_PR)-1:0] T_in,    
  input logic [$clog2(`NUM_PR)-1:0] T_old_in,
  output logic [$clog2(`NUM_PR)-1:0] T_out,    
  output logic [$clog2(`NUM_PR)-1:0] T_old_out,
  output logic out
);

  ROB_ENTRY_t [`NUM_ROB - 1:0] rob;
  logic writeTail, readHead, readTail, incHead, incTail;
  logic [$clog2(`NUM_ROB)-1: 0] headPointer, tailPointer; // not sure if register ok or need param


  always_ff @ (posedge clock) begin
    if(reset) begin
      headPointer = 0;
      tailPointer = 0;
      for(int i=0; i < `NUM_ROB; i++) begin
        rob.valid = 0;
      end
    end
    else begin
      if(incTail)
        tailPointer <= #`SD tailPointer + 1;
      else
        tailPointer <= #`SD tailPointer;

      if(incHead)
        headPointer <= #`SD headPointer + 1;
      else
        headPointer <= #`SD headPointer;

      if(writeTail) begin
        rob[tailPointer].T <= #`SD T_in;
        rob[tailPointer].T_old <= #`SD T_old_in;
      end
    end
  end

  always_comb begin
    writeTail = (cmd == WRITE) && ~ht;
    readTail = (cmd == READ) && ~ht;
    readHead = (cmd == READ) && ht;
    incHead = increment && ht;
    incTail = increment && ~ht;

    if(readTail) begin
      T_out = rob[tailPointer].T;
      T_old_out = rob[tailPointer].T_old;
      out = rob[tailPointer].valid;
    end
    else if (readHead) begin
      T_out = rob[headPointer].T;
      T_old_out = rob[headPointer].T_old;
      out = rob[headPointer].valid;
    end
  end
endmodule