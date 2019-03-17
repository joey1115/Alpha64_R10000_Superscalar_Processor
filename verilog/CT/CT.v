/**************CDB*********************
*   Fetch
*   Dispatch
*   Issue
*   Execute
*     Input: rollback_en (X/C)
*     Input: ROB_rollback_idx (br module, LSQ)
*   Complete
*     Input: FU_done (X/C) // valid signal from FU
*     Input: T_idx (X/C)  // tag from FU
*     Input: FU_result (X/C) // result from FU
*     Input: ROB_idx (X)
*     Output: CDB_valid (FU)// full entry means hazard(valid=0, entry is free)
*     Output: complete_en (RS, ROB, Map table)          // valid signal to PR
*     Output: write_en (PR)
*     Output: T_idx 	(PR)        // tag to PR
*     Output: T_value (PR)         // result to PR
*   Retire
*/
module CT (
  input  en, clock, reset, 
  input  CT_PACKET_IN  ct_packet_in,
  output CT_PACKET_OUT ct_packet_out
);

  CT_entry_t [`NUM_FU-1:0] ct, next_ct;

  always_comb begin
    next_ct = ct;

    // Update taken, T & result for each empty entry
    // and give CDB_valid to FU, CDB_valid=1 means the entry is free
    for (int i=0; i<`NUM_FU; i++) begin
      ct_packet_out.CDB_valid[i] = !next_ct[i].taken;
      if (next_ct[i].taken == 0 && ct_packet_in.FU_done[i] == 1) begin
        next_ct[i].taken = 1;
        next_ct[i].T = ct_packet_in.T_idx[i];
        next_ct[i].result = ct_packet_in.FU_result[i];
        next_ct[i].ROB_idx = ct_packet_in.ROB_idx[i];
        ct_packet_out.CDB_valid[i] = 0;
      end
    end

    // rollback
    if (rollback_en) begin
      if (ct_packet_in.ROB_tail_idx > ct_packet_in.ROB_rollback_idx) begin
        for (int i=0; i<`NUM_FU; i++)begin
          if ((next_ct[i].ROB_idx > ct_packet_in.ROB_rollback_idx) && (next_ct[i].ROB_idx < ct_packet_in.ROB_tail_idx)) begin
            next_ct[i].taken = 0;
            next_ct[i].T = 0;
            next_ct[i].result = 0;
            next_ct[i].ROB_idx = 0;
            ct_packet_out.CDB_valid[i] = 1;
          end // if
        end // for
      end else if (ct_packet_in.ROB_tail_idx < ct_packet_in.ROB_rollback_idx) begin
        for (int i=0; i<`NUM_FU; i++) begin
          if ((next_ct[i].ROB_idx > ct_packet_in.ROB_rollback_idx) || (next_ct[i].ROB_idx < ct_packet_in.ROB_tail_idx)) begin
            next_ct[i].taken = 0;
            next_ct[i].T = 0;
            next_ct[i].result = 0;
            next_ct[i].ROB_idx = 0;
            ct_packet_out.CDB_valid[i] = 1;
          end // if
        end // for
      end else if (ct_packet_in.ROB_tail_idx == ct_packet_in.ROB_rollback_idx) begin
        for (int i=0; i<`NUM_FU; i++) begin
          if (next_ct[i].ROB_idx != ct_packet_in.ROB_rollback_idx) begin
            next_ct[i].taken = 0;
            next_ct[i].T = 0;
            next_ct[i].result = 0;
            next_ct[i].ROB_idx = 0;
            ct_packet_out.CDB_valid[i] = 1;
          end // if
        end // for
      end
    end else begin
      // broadcast one completed instruction (if one is found)
      ct_packet_out.write_en  = 0;
      ct_packet_out.T_idx      = 0;
      ct_packet_out.T_value    = 0;
      ct_packet_out.complete_en= 0;
      for (int i=0; i<`NUM_FU; i++) begin
        if (next_ct[i].taken) begin
          ct_packet_out.write_en   = 1'b1;
          ct_packet_out.T_idx       = next_ct[i].T;
          ct_packet_out.T_value     = next_ct[i].result;
          ct_packet_out.complete_en = 1'b1;
          // try filling this entry if X_C reg wants to write a new input here
          // (compare T to prevent re-writing the entry with the same inst.)
          if (ct_packet_in.FU_done[i] && ct_packet_in.T_idx[i] != next_ct[i].T) begin
            next_ct[i].T = ct_packet_in.T_idx[i];
            next_ct[i].result = ct_packet_in.FU_result[i];
          end else begin
            next_ct[i].taken = 0;
            ct_packet_out.CDB_valid[i] = 1;
          end // else if
          break;
        end // if
      end // for
    end // else

  end // always

  always_ff @(posedge clock) begin
    if (reset) begin
      for (int i=0; i<`NUM_FU; i++) begin
        ct[i].taken   <= `SD 0;
        ct[i].T       <= `SD 0;
        ct[i].result  <= `SD 0;
        ct[i].ROB_idx <= `SD 0;
      end
    end else if (en) begin
      ct <= `SD next_ct;
    end
  end
endmodule