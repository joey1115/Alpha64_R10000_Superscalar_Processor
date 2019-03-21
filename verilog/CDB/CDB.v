/*****************CDB******************
*   Fetch
*   Dispatch
*   Issue
*   Execute
*     Input: rollback_en (X/C)
*     Input: ROB_rollback_idx (br module, LSQ)
*     Input: diff_ROB (FU)    // diff_ROB = ROB_tail of the current cycle - ROB_rollback idx
*   Complete
*     Input: FU_done   (X/C)  // valid signal from FU
*     Input: T_idx     (X/C)  // tag from FU
*     Input: ROB_idx   (X/C)
*     Input: FU_result (X/C)  // result from FU
*     Output: CDB_valid (FU)  // full entry means hazard(valid=0, entry is free)
*     Output: complete_en (RS, ROB, Map table) 
*     Output: write_en (PR)   // valid signal to PR
*     Output: T_idx 	 (PR)   // tag to PR
*     Output: T_value  (PR)   // result to PR
*   Retire
***************************************/

module CDB (
  input  en, clock, reset, 
  input  CDB_PACKET_IN  CDB_packet_in,

  `ifndef SYNTH_TEST
  output CDB_entry_t [`NUM_FU-1:0] CDB,
  `endif
  output CDB_PACKET_OUT CDB_packet_out
);

  `ifdef SYNTH_TEST
  CDB_entry_t [`NUM_FU-1:0] CDB;
  `endif
  CDB_entry_t [`NUM_FU-1:0] next_CDB;
  logic [`NUM_FU-1:0] [$clog2(`NUM_ROB)-1:0] diff;


  always_comb begin
    next_CDB = CDB;
    CDB_packet_out.write_en   = 0;
    CDB_packet_out.T_idx      = 31;
    CDB_packet_out.T_value    = 0;
    CDB_packet_out.complete_en= 0;
    
    // Update taken, T & result for each empty entry
    // and give CDB_valid to FU, CDB_valid=1 means the entry is free
    for (int i=0; i<`NUM_FU; i++) begin
      CDB_packet_out.CDB_valid[i] = !next_CDB[i].taken;
      if (!(next_CDB[i].taken) && CDB_packet_in.FU_done[i]) begin
        next_CDB[i].taken   = 1;
        next_CDB[i].T       = CDB_packet_in.T_idx[i];
        next_CDB[i].result  = CDB_packet_in.FU_result[i];
        next_CDB[i].ROB_idx = CDB_packet_in.ROB_idx[i];
        next_CDB[i].dest_idx= CDB_packet_in.dest_idx[i];
        CDB_packet_out.CDB_valid[i] = 0;
      end
    end
    // rollback
    if (CDB_packet_in.rollback_en) begin
      for (int i=0; i<`NUM_FU; i++)begin
        diff[i] = next_CDB[i].ROB_idx - CDB_packet_in.ROB_rollback_idx;
        if (CDB_packet_in.diff_ROB >= diff[i]) begin
          next_CDB[i].taken   = 0;
          next_CDB[i].T       = 0;
          next_CDB[i].result  = 0;
          next_CDB[i].ROB_idx = 0;
          CDB_packet_out.CDB_valid[i] = 1;
        end
      end
    end
    // broadcast one completed instruction (if one is found)
    for (int i=0; i<`NUM_FU; i++) begin
      if (next_CDB[i].taken) begin
        CDB_packet_out.write_en    = 1'b1;
        CDB_packet_out.T_idx       = next_CDB[i].T;
        CDB_packet_out.T_value     = next_CDB[i].result;
        CDB_packet_out.complete_en = 1'b1;
        CDB_packet_out.dest_idx    = next_CDB[i].dest_idx;
        // try filling this entry if X_C reg wants to write a new input here
        // (compare T to prevent re-writing the entry with the same inst.)
        if (CDB_packet_in.FU_done[i] && CDB_packet_in.T_idx[i] != next_CDB[i].T) begin
          next_CDB[i].T = CDB_packet_in.T_idx[i];
          next_CDB[i].result = CDB_packet_in.FU_result[i];
        end else begin
          next_CDB[i].taken = 0;
          CDB_packet_out.CDB_valid[i] = 1;
        end // else
        break;
      end // if
    end // for

  end // always_comb

  always_ff @(posedge clock) begin
    if (reset) begin
      for (int i=0; i<`NUM_FU; i++) begin
        CDB[i].taken   <= `SD 0;
        CDB[i].T       <= `SD 0;
        CDB[i].result  <= `SD 0;
        CDB[i].ROB_idx <= `SD 0;
      end
    end else if (en) begin
      CDB <= `SD next_CDB;
    end
  end // always_ff
endmodule