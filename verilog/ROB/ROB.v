`timescale 1ns/100ps

module ROB (
  //inputs
  input  logic                                      en, clock, reset,
  input  logic                                      dispatch_en,
  input  logic                                      rollback_en,
  input  logic                                      complete_en,
  input  logic               [$clog2(`NUM_ROB)-1:0] ROB_rollback_idx,
  input  DECODER_ROB_OUT_t                          decoder_ROB_out,
  input  FL_ROB_OUT_t                               FL_ROB_out,
  input  MAP_TABLE_ROB_OUT_t                        Map_Table_ROB_out,
  input  CDB_ROB_OUT_t                              CDB_ROB_out,
  //Outputs
`ifndef SYNTH_TEST
  output ROB_t                                      rob,
`endif
  output logic                                      ROB_valid,
  output logic                                      retire_en,
  output logic                                      halt_out,
  output logic               [$clog2(`NUM_ROB)-1:0] ROB_idx,
  output ROB_ARCH_MAP_OUT_t                         ROB_Arch_Map_out,
  output ROB_FL_OUT_t                               ROB_FL_out
);

`ifdef SYNTH_TEST
  ROB_t rob;
`endif

  ROB_t Nrob;

  logic writeTail, moveHead, mispredict, b_t, stall_dispatch;
  logic [$clog2(`NUM_ROB)-1:0] ROB_rollback_idx_reg, NROB_rollback_idx_reg;
  logic [1:0] state, Nstate;

  assign ROB_Arch_Map_out = '{rob.entry[rob.head].T_idx, rob.entry[rob.head].dest_idx};
  assign ROB_FL_out       = '{rob.entry[rob.head].Told_idx};

  //assign ROB_valid
  assign stall_dispatch = (state == 1);
  assign ROB_valid = (stall_dispatch)? 0 : !Nrob.entry[Nrob.tail].valid;

  //assign halt out
  assign halt_out = retire_en & rob.entry[rob.head].halt;

  assign ROB_idx = Nrob.tail - 1;

  always_comb begin
    retire_en = rob.entry[rob.head].complete;

    // condition for Retire
    moveHead = (retire_en) 
                && en 
                && rob.entry[rob.head].valid;
    // condition for Dispatch
    writeTail = (dispatch_en) 
                && en 
                && (!rob.entry[rob.tail].valid || retire_en) 
                && !rollback_en;
  end

  always_comb begin
     Nrob = rob;

    //complete stage
    if(complete_en) begin
      Nrob.entry[CDB_ROB_out.ROB_idx].complete = 1;
    end
    
    //Next state logic
    Nrob.tail = (writeTail) ? (rob.tail + 1) : Nrob.tail;
    Nrob.head = (moveHead) ? (rob.head + 1) : Nrob.head;
    Nrob.entry[rob.tail].T_idx = (writeTail) ? FL_ROB_out.T_idx : Nrob.entry[rob.tail].T_idx;
    Nrob.entry[rob.tail].Told_idx = (writeTail) ? Map_Table_ROB_out.Told_idx : Nrob.entry[rob.tail].Told_idx;
    Nrob.entry[rob.tail].dest_idx = (writeTail) ? decoder_ROB_out.dest_idx : Nrob.entry[rob.tail].dest_idx;
    Nrob.entry[rob.tail].halt = writeTail & decoder_ROB_out.halt;

    
  
    //update valid and complete bits of entry
    if(rob.head != rob.tail) begin
      Nrob.entry[rob.head].valid = (moveHead) ? 0 : Nrob.entry[rob.head].valid;
      // Nrob.entry[rob.head].complete = (moveHead) ? 0 : Nrob.entry[rob.head].complete;
      Nrob.entry[rob.tail].valid = (writeTail) ? 1 : Nrob.entry[rob.tail].valid;
      Nrob.entry[rob.tail].complete = (writeTail) ? 0 : Nrob.entry[rob.tail].complete;
    end
    else begin
      Nrob.entry[rob.tail].valid = (writeTail) ? 1 :
                                    (moveHead) ? 0 : Nrob.entry[rob.head].valid;
      Nrob.entry[rob.tail].complete = (writeTail) ? 0 : Nrob.entry[rob.head].complete;
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
    
   
  end

  assign NROB_rollback_idx_reg = (mispredict) ? ROB_rollback_idx : ROB_rollback_idx_reg;

  always_comb begin
    case(state)
      0: Nstate = (mispredict) ? 1 : state;
      1: Nstate = (rob.head == ROB_rollback_idx_reg) ? 0 : state;
      default: Nstate = state;
    endcase 
  end
  always_ff @ (posedge clock) begin
    if(reset) begin
      state <= `SD 0;
      ROB_rollback_idx_reg <= `SD 0;
      rob.tail <= `SD 0;
      rob.head <= `SD 0;
      for(int i=0; i < `NUM_ROB; i++) begin
         rob.entry[i].valid <= `SD 0;
         rob.entry[i].complete <= `SD 0;
         rob.entry[i].halt <= `SD 0;
         rob.entry[i].T_idx <= `SD 0;
         rob.entry[i].Told_idx <= `SD 0;
         rob.entry[i].dest_idx <= `SD 0;
      end
    end // if (reset) else
    else if(en)begin
      rob <= `SD Nrob;
      state <= `SD Nstate;
      ROB_rollback_idx_reg <= `SD NROB_rollback_idx_reg;
    end // else if(en)begin
  end // always_ff

endmodule