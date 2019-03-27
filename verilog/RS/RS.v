`timescale 1ns/100ps

module RS (
  input  logic                                     clock, reset, en, complete_en, dispatch_en, rollback_en,
  input  logic              [`NUM_FU-1:0]          FU_valid,
  input  logic              [$clog2(`NUM_ROB)-1:0] ROB_rollback_idx,
  input  logic              [$clog2(`NUM_ROB)-1:0] diff_ROB,
  input  logic              [$clog2(`NUM_ROB)-1:0] ROB_idx,
  input  DECODER_RS_OUT_t                          decoder_RS_out,
  input  FL_RS_OUT_t                               FL_RS_out,
  input  MAP_TABLE_RS_OUT_t                        Map_Table_RS_out,
  input  CDB_RS_OUT_t                              CDB_RS_out,
`ifndef SYNTH_TEST
  output RS_ENTRY_t         [`NUM_FU-1:0]          RS_out,
  output logic              [`NUM_FU-1:0]          RS_match_hit,   // If a RS entry is ready
  output logic              [$clog2(`NUM_FU)-1:0]  RS_match_idx,
`endif
  output logic                                     RS_valid,
  output RS_FU_OUT_t                               RS_FU_out,
  output RS_PR_OUT_t                               RS_PR_out
);

  FU_PACKET_t    [`NUM_FU-1:0]                       FU_packet;      // List of output fu
  RS_ENTRY_t     [`NUM_FU-1:0]                       RS, next_RS;
  FU_t           [`NUM_FU-1:0]                       FU_list;        // List of FU
  FU_IDX_ENTRY_t [`NUM_FU-1:0]                       FU_T_idx;
  logic          [`NUM_FU-1:0]                       T1_CDB;         // If T1 is complete
  logic          [`NUM_FU-1:0]                       T2_CDB;         // If T2 is complete
  logic          [`NUM_FU-1:0]                       T1_ready;       // If T1 is ready
  logic          [`NUM_FU-1:0]                       T2_ready;       // If T2 is ready
  logic          [`NUM_FU-1:0]                       RS_entry_ready; // If a RS entry is ready
  logic          [`NUM_FU-1:0]                       RS_entry_empty; // If a RS entry is ready
  logic          [`NUM_FU-1:0]                       RS_rollback;    // If a RS entry is ready
  logic          [`NUM_FU-1:0]                       FU_entry_match;
  logic          [`NUM_FU-1:0][$clog2(`NUM_ROB)-1:0] diff;
`ifdef SYNTH_TEST
  logic                                              RS_match_hit;   // If a RS entry is ready
  logic          [$clog2(`NUM_FU)-1:0]               RS_match_idx;
`endif

  assign RS_FU_out = '{FU_packet};
  assign RS_PR_out = '{FU_T_idx};
  assign RS_valid  = RS_match_hit;

`ifndef SYNTH_TEST
  assign RS_out = RS;
`endif

  always_comb begin
    RS_match_hit =  `FALSE;
    RS_match_idx = {$clog2(`NUM_FU){1'b0}};
    for (int i = 0; i < `NUM_FU; i++) begin
      if ( ( RS_entry_empty[i] || RS[i].busy == `FALSE ) && FU_entry_match[i] ) begin
        RS_match_hit = `TRUE; // RS entry match
        RS_match_idx = i;
        break;
      end
    end // for (int i = 0; i < `NUM_FU; i++) begin
  end

  always_comb begin
    for (int i = 0; i < `NUM_FU; i++) begin
      FU_entry_match[i] = FU_list[i] == decoder_RS_out.FU;
      diff[i]           = RS[i].ROB_idx - ROB_rollback_idx;                // diff
      RS_rollback[i]    = ( diff_ROB >= diff[i] ) && rollback_en;          // Rollback
      T1_CDB[i]         = RS[i].T1.idx == CDB_RS_out.T_idx && complete_en; // T1 is complete
      T2_CDB[i]         = RS[i].T2.idx == CDB_RS_out.T_idx && complete_en; // T2 is complete
      T1_ready[i]       = RS[i].T1.ready || T1_CDB[i];                     // T1 is ready or updated by CDB
      T2_ready[i]       = RS[i].T2.ready || T2_CDB[i];                     // T2 is ready or updated by CDB
      RS_entry_ready[i] = T1_ready[i] && T2_ready[i];                      // T1 and T2 are ready to issue
      RS_entry_empty[i] = RS_entry_ready[i] && FU_valid[i];                // Entry is going to be empty
    end // for (int i = 0; i < `NUM_FU; i++) begin
  end // always_comb begin

  always_comb begin
    for (int i = 0; i < `NUM_FU; i++) begin
      FU_packet[i].ready         = RS_entry_ready[i] && !RS_rollback[i]; // Ready to issue
      FU_packet[i].ROB_idx       = RS[i].ROB_idx;                        // op code
      FU_packet[i].inst          = RS[i].inst;                           // inst
      FU_packet[i].func          = RS[i].func;                           // op code
      FU_packet[i].NPC           = RS[i].NPC;                            // op code
      FU_packet[i].dest_idx      = RS[i].dest_idx;                       // op code
      FU_packet[i].opa_select    = RS[i].opa_select;                     // Output T2_idx
      FU_packet[i].opb_select    = RS[i].opb_select;                     // Output T2_idx
      FU_packet[i].uncond_branch = RS[i].uncond_branch;                  // Output T2_idx
      FU_packet[i].cond_branch   = RS[i].cond_branch;                    // Output T2_idx
      FU_packet[i].FL_idx        = RS[i].FL_idx;                         // op code
      FU_packet[i].T_idx         = RS[i].T_idx;                          // Output T_idx
      FU_T_idx[i].T1_idx         = RS[i].T1.idx;                         // Output T1_idx
      FU_T_idx[i].T2_idx         = RS[i].T2.idx;                         // Output T2_idx
    end
  end

  always_comb begin
    next_RS = RS;
    for (int i = 0; i < `NUM_FU; i++) begin
      next_RS[i].T1.ready = T1_ready[i]; // T1 ready
      next_RS[i].T2.ready = T2_ready[i]; // T2 ready
      if ( RS_entry_empty[i] || RS_rollback[i] ) begin
        next_RS[i] = `RS_ENTRY_RESET; // Clear RS entry
      end // if ( RS[i].busy == `FALSE && dispatch_en ) begin
    end // for (int i = 0; i < `NUM_FU; i++) begin
    if ( RS_match_hit && dispatch_en ) begin // RS entry was not busy and inst ready to dispatch and FU match
      next_RS[RS_match_idx].busy          = `TRUE;                        // RS entry busy
      next_RS[RS_match_idx].ROB_idx       = ROB_idx;                      // op code
      next_RS[RS_match_idx].inst          = decoder_RS_out.inst;          // inst
      next_RS[RS_match_idx].func          = decoder_RS_out.func;          // func
      next_RS[RS_match_idx].NPC           = decoder_RS_out.NPC;           // Write T1 select
      next_RS[RS_match_idx].dest_idx      = decoder_RS_out.dest_idx;      // Write T1 select
      next_RS[RS_match_idx].opa_select    = decoder_RS_out.opa_select;    // Output T2_idx
      next_RS[RS_match_idx].opb_select    = decoder_RS_out.opb_select;    // Output T2_idx
      next_RS[RS_match_idx].uncond_branch = decoder_RS_out.uncond_branch; // Output T2_idx
      next_RS[RS_match_idx].cond_branch   = decoder_RS_out.cond_branch;   // Output T2_idx
      next_RS[RS_match_idx].FL_idx        = FL_RS_out.FL_idx;             // Write T1 select
      next_RS[RS_match_idx].T_idx         = FL_RS_out.T_idx;              // Write T
      next_RS[RS_match_idx].T1            = Map_Table_RS_out.T1;          // Write T1
      next_RS[RS_match_idx].T2            = Map_Table_RS_out.T2;          // Write T2
    end
  end // always_comb begin

  always_ff @(posedge clock) begin
    FU_list <= `SD `FU_LIST;
    if(reset) begin
      RS <= `SD `RS_RESET;
    end else if(en) begin
      RS <= `SD next_RS;
    end // else if(en) begin
  end // always

endmodule // RS
