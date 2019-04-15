`timescale 1ns/100ps

module ROB (
  //inputs
  input  logic                                                      en, clock, reset,
  input  logic                                                      dispatch_en,
  input  logic                                                      rollback_en,
  input  logic               [`NUM_SUPER-1:0]                       complete_en,
  input  logic               [$clog2(`NUM_ROB)-1:0]                 ROB_rollback_idx,
  input  DECODER_ROB_OUT_t                                          decoder_ROB_out,
  input  FL_ROB_OUT_t                                               FL_ROB_out,
  input  MAP_TABLE_ROB_OUT_t                                        Map_Table_ROB_out,
  input  CDB_ROB_OUT_t                                              CDB_ROB_out,
  input  SQ_ROB_OUT_t                                               SQ_ROB_out,
  //Outputs
`ifdef DEBUG
  output ROB_t                                                      rob,
  output logic               [`NUM_SUPER-1:0][63:0]                 retire_NPC,
`endif                
  output logic                                                      ROB_valid,
  output logic               [`NUM_SUPER-1:0]                       retire_en,
  output logic               [`NUM_SUPER-1:0]                       halt_out,
  output logic               [`NUM_SUPER-1:0]                       illegal_out,
  output logic               [`NUM_SUPER-1:0][$clog2(`NUM_ROB)-1:0] ROB_idx,
  output ROB_ARCH_MAP_OUT_t                                         ROB_Arch_Map_out,
  output ROB_MAP_TABLE_OUT_t                                        ROB_MAP_Table_out,
  output ROB_FL_OUT_t                                               ROB_FL_out,
  output ROB_SQ_OUT_t                                               ROB_SQ_out,
  output ROB_LQ_OUT_t                                               ROB_LQ_out
);

`ifndef DEBUG
  ROB_t rob;
`endif

  ROB_t Nrob;

  logic writeTail, moveHead, mispredict, b_t;
  logic [$clog2(`NUM_ROB)-1:0] ROB_rollback_idx_reg, NROB_rollback_idx_reg, ROB_rollback_idx_reg_plus_one;
  logic [1:0] state, Nstate;
  logic [$clog2(`NUM_ROB)-1:0] tail_plus_one;
  logic [$clog2(`NUM_ROB)-1:0] tail_minus_one, tail_minus_two;
  logic [$clog2(`NUM_ROB)-1:0] head_plus_one;

`ifdef DEBUG
  assign retire_NPC[0] = rob.entry[rob.head].NPC;
  assign retire_NPC[1] = rob.entry[head_plus_one].NPC; 
`endif

  assign ROB_SQ_out.wr_mem = '{rob.entry[head_plus_one].wr_mem,rob.entry[rob.head].wr_mem};
  assign ROB_SQ_out.retire[0] = rob.entry[rob.head].complete & rob.entry[rob.head].valid;
  assign ROB_SQ_out.retire[1] = rob.entry[head_plus_one].complete & rob.entry[head_plus_one].valid;

  assign ROB_LQ_out.rd_mem = '{rob.entry[head_plus_one].rd_mem,rob.entry[rob.head].rd_mem};

  assign ROB_Arch_Map_out.T_idx = '{rob.entry[head_plus_one].T_idx, rob.entry[rob.head].T_idx};
  assign ROB_Arch_Map_out.dest_idx = '{rob.entry[head_plus_one].dest_idx, rob.entry[rob.head].dest_idx};
  assign ROB_FL_out.Told_idx = '{rob.entry[head_plus_one].Told_idx, rob.entry[rob.head].Told_idx};

  //assign ROB_valid
  assign ROB_MAP_Table_out.stall_dispatch = (state == 1);
  //!Nrob.entry[Nrob.tail].valid
  assign ROB_rollback_idx_minus_one = ROB_rollback_idx - 1;
  assign tail_plus_one = rob.tail + 1;
  assign tail_minus_one = rob.tail - 1;
  assign tail_minus_two = rob.tail - 2;
  assign head_plus_one = rob.head + 1;
  assign ROB_rollback_idx_reg_plus_one = ROB_rollback_idx_reg + 1;
  
  assign ROB_valid = (ROB_MAP_Table_out.stall_dispatch | rollback_en) ? 0 :
                     (!rob.entry[rob.tail].valid || retire_en[0]) & (!rob.entry[tail_plus_one].valid || retire_en[1]) & !(rob.entry[tail_minus_one].halt || rob.entry[tail_minus_two].halt || rob.entry[tail_minus_one].illegal || rob.entry[tail_minus_two].illegal);
  
  //(tail_plus_one!=rob.head)) && !(rob.entry[tail_minus_one].halt && rob.entry[tail_minus_one].valid);

  //assign ROB_valid = tail_plus_one!=rob.head;
  //assign halt out
  assign halt_out[0] =  (retire_en[0] && rob.entry[rob.head].halt);
  assign halt_out[1] =  (retire_en[1] && rob.entry[head_plus_one].halt);
  assign illegal_out[0] =  (retire_en[0] && rob.entry[rob.head].illegal);
  assign illegal_out[1] =  (retire_en[1] && rob.entry[head_plus_one].illegal);
  assign ROB_idx[0] = dispatch_en ? rob.tail : tail_minus_two;
  assign ROB_idx[1] = dispatch_en ? tail_plus_one : tail_minus_one;

  always_comb begin
    retire_en[0] = rob.entry[rob.head].complete & rob.entry[rob.head].valid & SQ_ROB_out.retire_valid[0] & !rollback_en;
    retire_en[1] = rob.entry[head_plus_one].complete & rob.entry[head_plus_one].valid & retire_en[0] & SQ_ROB_out.retire_valid[1] & !rollback_en;

    // condition for Retire
    moveHead = retire_en[0];
    // condition for Dispatch (only when 2 instruction is able to be dispatched)
    writeTail = dispatch_en;
  end

  always_comb begin
     Nrob = rob;

    //complete stage
    for(int i = 0; i < `NUM_SUPER; i++) begin
      if(complete_en[i]) begin
        Nrob.entry[CDB_ROB_out.ROB_idx[i]].complete = 1;
      end
    end
    
    //Next state logic
    Nrob.tail = (writeTail) ? (tail_plus_one + 1) : Nrob.tail;
    Nrob.head = (moveHead & retire_en[1]) ? (rob.head + `NUM_SUPER) :
                (moveHead)                ? (head_plus_one)         :
                                            Nrob.head;
    Nrob.entry[rob.tail].T_idx = (writeTail) ? FL_ROB_out.T_idx[0] : Nrob.entry[rob.tail].T_idx;
    Nrob.entry[tail_plus_one].T_idx = (writeTail) ? FL_ROB_out.T_idx[1] : Nrob.entry[tail_plus_one].T_idx;
    Nrob.entry[rob.tail].Told_idx = (writeTail) ? Map_Table_ROB_out.Told_idx[0] : Nrob.entry[rob.tail].Told_idx;
    Nrob.entry[tail_plus_one].Told_idx = (writeTail) ? Map_Table_ROB_out.Told_idx[1] : Nrob.entry[tail_plus_one].Told_idx;
    Nrob.entry[rob.tail].dest_idx = (writeTail) ? decoder_ROB_out.dest_idx[0] : Nrob.entry[rob.tail].dest_idx;
    Nrob.entry[tail_plus_one].dest_idx = (writeTail) ? decoder_ROB_out.dest_idx[1] : Nrob.entry[tail_plus_one].dest_idx;
    Nrob.entry[rob.tail].halt = writeTail & decoder_ROB_out.halt[0];
    Nrob.entry[tail_plus_one].halt = writeTail & decoder_ROB_out.halt[1];
    Nrob.entry[rob.tail].illegal = writeTail & decoder_ROB_out.illegal[0];
    Nrob.entry[tail_plus_one].illegal = writeTail & decoder_ROB_out.illegal[1];
    Nrob.entry[rob.tail].NPC = (writeTail) ? decoder_ROB_out.NPC[0] : Nrob.entry[rob.tail].NPC;
    Nrob.entry[tail_plus_one].NPC = (writeTail) ? decoder_ROB_out.NPC[1] : Nrob.entry[tail_plus_one].NPC;
    Nrob.entry[rob.tail].wr_mem = (writeTail) ? decoder_ROB_out.wr_mem[0] : Nrob.entry[rob.tail].wr_mem;
    Nrob.entry[tail_plus_one].wr_mem = (writeTail) ? decoder_ROB_out.wr_mem[1] : Nrob.entry[tail_plus_one].wr_mem;
    Nrob.entry[rob.tail].rd_mem = (writeTail) ? decoder_ROB_out.rd_mem[0] : Nrob.entry[rob.tail].rd_mem;
    Nrob.entry[tail_plus_one].rd_mem = (writeTail) ? decoder_ROB_out.rd_mem[1] : Nrob.entry[tail_plus_one].rd_mem;

    
  
    //update valid and complete bits of entry
    if(rob.head != rob.tail) begin
      Nrob.entry[rob.head].valid = (moveHead) ? 0 : Nrob.entry[rob.head].valid;
      Nrob.entry[head_plus_one].valid = (moveHead & retire_en[1]) ? 0 : Nrob.entry[head_plus_one].valid;
      // Nrob.entry[rob.head].complete = (moveHead) ? 0 : Nrob.entry[rob.head].complete;
      Nrob.entry[rob.tail].valid = (writeTail) ? 1 : Nrob.entry[rob.tail].valid;
      Nrob.entry[tail_plus_one].valid = (writeTail) ? 1 : Nrob.entry[tail_plus_one].valid;
      Nrob.entry[rob.tail].complete = (writeTail | decoder_ROB_out.halt[0] | decoder_ROB_out.illegal[0]) ? 0 : Nrob.entry[rob.tail].complete;
      Nrob.entry[tail_plus_one].complete = (writeTail | decoder_ROB_out.halt[1] | decoder_ROB_out.illegal[1]) ? 0 : Nrob.entry[tail_plus_one].complete;
    end
    else begin
      Nrob.entry[rob.tail].valid = (moveHead) ? 0:
                                   (writeTail) ? 1 : Nrob.entry[rob.tail].valid;
      Nrob.entry[tail_plus_one].valid = (moveHead & retire_en[1]) ? 0 :
                                        (!(moveHead & retire_en[1]) & writeTail) ? 1 : Nrob.entry[head_plus_one].valid;
      Nrob.entry[rob.tail].complete = (writeTail | decoder_ROB_out.halt[0] | decoder_ROB_out.illegal[0]) ? 0 : Nrob.entry[rob.tail].complete;
      Nrob.entry[tail_plus_one].complete = (writeTail | decoder_ROB_out.halt[1] | decoder_ROB_out.illegal[1]) ? 0 : Nrob.entry[tail_plus_one].complete;
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
      1: Nstate = ((rob.head == ROB_rollback_idx_reg) || (rob.head == (ROB_rollback_idx_reg_plus_one))) ? 0 : state;
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
         rob.entry[i].illegal <= `SD 0;
         rob.entry[i].T_idx <= `SD 0;
         rob.entry[i].Told_idx <= `SD 0;
         rob.entry[i].dest_idx <= `SD 0;
         rob.entry[i].wr_mem <= `SD 0;
         rob.entry[i].rd_mem <= `SD 0;
         rob.entry[i].NPC <= `SD 0;
      end
    end // if (reset) else
    else if(en)begin
      rob <= `SD Nrob;
      state <= `SD Nstate;
      ROB_rollback_idx_reg <= `SD NROB_rollback_idx_reg;
    end // else if(en)begin
  end // always_ff

endmodule