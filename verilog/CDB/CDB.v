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
*     Input: dest_idx  (X/C)
*     Output: CDB_valid (FU)  // full entry means hazard(valid=0, entry is free)
*     Output: complete_en (RS, ROB, Map table) 
*     Output: write_en (PR)   // valid signal to PR
*     Output: T_idx 	 (PR)   // tag to PR
*     Output: T_value  (PR)   // result to PR
*     Output: dest_idx (Map table)
*   Retire
***************************************/

module CDB (
  input  logic                                                en, clock, reset,
  input  logic                                                rollback_en,        // rollback_en from X/C
  input  logic                         [$clog2(`NUM_ROB)-1:0] ROB_rollback_idx,   // ROB# of mispredicted branch/incorrect load from br module/LSQ
  input  logic                         [$clog2(`NUM_ROB)-1:0] diff_ROB,           // diff_ROB = ROB_tail of the current cycle - ROB_rollback_idx
  input  FU_CDB_ENTRY_t                         [`NUM_FU-1:0] fu_result,          // done,T_idx,ROB_idx,dest_idx,result from FU
  // input  logic           [`NUM_FU-1:0]                        FU_done,            // valid signal from FU
  // input  logic           [`NUM_FU-1:0]  [$clog2(`NUM_PR)-1:0] T_idx,              // tag from FU
  // input  logic           [`NUM_FU-1:0] [$clog2(`NUM_ROB)-1:0] ROB_idx,            // ROB_idx from FU
  // input  logic           [`NUM_FU-1:0]                  [4:0] dest_idx,           // from FU
  // input  logic           [`NUM_FU-1:0]                 [63:0] FU_result,          // result from FU
`ifndef SYNTH_TEST
  output CDB_entry_t    [`NUM_FU-1:0]                         CDB,
`endif
  output CDB_PACKET_OUT                                       CDB_packet_out
);

`ifdef SYNTH_TEST
  CDB_entry_t [`NUM_FU-1:0] CDB;
`endif
  CDB_entry_t [`NUM_FU-1:0] next_CDB;
  logic [`NUM_FU-1:0] [$clog2(`NUM_ROB)-1:0] diff;


  always_comb begin
    next_CDB = CDB;
    CDB_packet_out.complete_en = 0;
    CDB_packet_out.write_en    = 0;
    CDB_packet_out.T_idx       = `ZERO_PR;
    CDB_packet_out.dest_idx    = `ZERO_REG;
    CDB_packet_out.T_value     = 0;
    CDB_packet_out.ROB_idx     = 0;
    
    // Update taken, T_idx & T_value for each empty entry
    // and give CDB_valid to FU, CDB_valid=1 means the entry is free
    for (int i=0; i<`NUM_FU; i++) begin
      CDB_packet_out.CDB_valid[i] = !next_CDB[i].taken;
      if (!(next_CDB[i].taken) && fu_result[i].FU_done) begin
        next_CDB[i].taken    = 1;
        next_CDB[i].T_idx    = fu_result[i].T_idx;
        next_CDB[i].ROB_idx  = fu_result[i].ROB_idx;
        next_CDB[i].dest_idx = fu_result[i].dest_idx;
        next_CDB[i].T_value  = fu_result[i].FU_result;
        CDB_packet_out.CDB_valid[i] = 0;
      end
    end
    // rollback
    if (rollback_en) begin
      for (int i=0; i<`NUM_FU; i++)begin
        diff[i] = next_CDB[i].ROB_idx - ROB_rollback_idx;
        if (diff_ROB >= diff[i]) begin
          next_CDB[i].taken    = 0;
          next_CDB[i].T_idx    = 0;
          next_CDB[i].ROB_idx  = 0;
          next_CDB[i].dest_idx = 0;
          next_CDB[i].T_value  = 0;
          CDB_packet_out.CDB_valid[i] = 1;
        end
      end
    end
    // broadcast one completed instruction (if one is found)
    for (int i=0; i<`NUM_FU; i++) begin
      // if ((next_CDB[i].taken && `FU_LIST[i] != FU_LD) || (next_CDB[i].taken && `FU_LIST[i] == FU_LD && next_CDB[i].ROB_idx == ROB_head_idx))  begin
      if (next_CDB[i].taken) begin
        CDB_packet_out.complete_en = 1'b1;
        CDB_packet_out.write_en    = 1'b1;
        CDB_packet_out.T_idx       = next_CDB[i].T_idx;
        CDB_packet_out.dest_idx    = next_CDB[i].dest_idx;
        CDB_packet_out.T_value     = next_CDB[i].T_value;
        CDB_packet_out.ROB_idx     = next_CDB[i].ROB_idx;
        // try filling this entry if X_C reg wants to write a new input here
        // (compare T_idx to prevent re-writing the entry with the same inst.)
        if (fu_result[i].FU_done && fu_result[i].T_idx != next_CDB[i].T_idx) begin
          next_CDB[i].T_idx    = fu_result[i].T_idx;
          next_CDB[i].dest_idx = fu_result[i].dest_idx;
          next_CDB[i].T_value  = fu_result[i].FU_result;
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
        CDB[i].taken    <= `SD 0;
        CDB[i].T_idx    <= `SD `ZERO_PR;
        CDB[i].ROB_idx  <= `SD 0;
        CDB[i].dest_idx <= `SD 0;
        CDB[i].T_value  <= `SD 0;
      end
    end else if (en) begin
      CDB <= `SD next_CDB;
    end
  end // always_ff
endmodule