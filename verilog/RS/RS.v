`timescale 1ns/100ps

module RS (
  input  logic                                     clock, reset, en, complete_en, dispatch_en, rollback_en,
  input  DECODER_PACKET_OUT                        decoder_packet_out,
  input  FL_RS_OUT_t                               fl_rs_out,
  input  ROB_RS_OUT_t                              rob_rs_out,
  input  T_t                                       T1,               // T1
  input  T_t                                       T2,               // T2
  input  logic              [$clog2(`NUM_PR)-1:0]  CDB_T_idx,        // CDB tag
  input  logic              [`NUM_FU-1:0]          fu_valid,         // FU done
  input  logic              [$clog2(`NUM_ROB)-1:0] ROB_rollback_idx, // FU done
  input  logic              [$clog2(`NUM_ROB)-1:0] diff_ROB,
`ifndef SYNTH_TEST
  output RS_ENTRY_t         [`NUM_FU-1:0]          RS_out,
  output logic              [`NUM_FU-1:0]          RS_match_hit,   // If a RS entry is ready
  output logic              [$clog2(`NUM_FU)-1:0]  RS_match_idx,
`ifdef RS_FORWARDING
  output logic                                     FU_forward_hit, // If a RS entry is ready
  output logic              [$clog2(`NUM_FU)-1:0]  FU_forward_idx, // If a RS entry is ready
`endif
`endif
  output RS_PACKET_OUT                             rs_packet_out,
  output logic                                     RS_valid
);

  RS_ENTRY_t [`NUM_FU-1:0]                       RS, next_RS;
  FU_t       [`NUM_FU-1:0]                       FU_list = `FU_LIST; // List of FU
  logic      [`NUM_FU-1:0]                       T1_CDB;             // If T1 is complete
  logic      [`NUM_FU-1:0]                       T2_CDB;             // If T2 is complete
  logic      [`NUM_FU-1:0]                       T1_ready;           // If T1 is ready
  logic      [`NUM_FU-1:0]                       T2_ready;           // If T2 is ready
  logic      [`NUM_FU-1:0]                       RS_entry_ready;     // If a RS entry is ready
  logic      [`NUM_FU-1:0]                       RS_entry_empty;     // If a RS entry is ready
  logic      [`NUM_FU-1:0]                       RS_rollback;        // If a RS entry is ready
  logic      [`NUM_FU-1:0]                       FU_entry_match;
  logic      [`NUM_FU-1:0][$clog2(`NUM_ROB)-1:0] diff;
`ifdef SYNTH_TEST
  logic                                          RS_match_hit;       // If a RS entry is ready
  logic      [$clog2(`NUM_FU)-1:0]               RS_match_idx;
`ifdef RS_FORWARDING
  logic                                          FU_forward_hit;     // If a RS entry is ready
  logic      [$clog2(`NUM_FU)-1:0]               FU_forward_idx;     // If a RS entry is ready
`endif
`endif

`ifndef SYNTH_TEST
  assign RS_out = RS;
`endif
`ifndef RS_FORWARDING
  assign RS_valid   = RS_match_hit;
`else
  assign RS_valid   = RS_match_hit || FU_forward_hit;

  always_comb begin
    FU_forward_hit = `FALSE;
    FU_forward_idx = {$clog2(`NUM_FU){1'b0}};
    if ( rs_packet_in.T1.ready && rs_packet_in.T2.ready ) begin
      for (int i = 0; i < `NUM_FU; i++) begin
        if ( ( !RS_entry_ready[i] || RS[i].busy == `FALSE ) && rs_packet_in.fu_valid[i] && FU_entry_match[i] ) begin
          FU_forward_hit = `TRUE;
          FU_forward_idx = i;
          break;
        end
      end
    end
  end
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
      FU_entry_match[i] = FU_list[i] == decoder_packet_out.FU;
      diff[i]           = RS[i].ROB_idx - rs_packet_in.ROB_rollback_idx;         // diff
      RS_rollback[i]    = ( rs_packet_in.diff_ROB >= diff[i] ) && rollback_en;   // Rollback
      T1_CDB[i]         = RS[i].T1.idx == rs_packet_in.CDB_T_idx && complete_en; // T1 is complete
      T2_CDB[i]         = RS[i].T2.idx == rs_packet_in.CDB_T_idx && complete_en; // T2 is complete
      T1_ready[i]       = RS[i].T1.ready || T1_CDB[i];                           // T1 is ready or updated by CDB
      T2_ready[i]       = RS[i].T2.ready || T2_CDB[i];                           // T2 is ready or updated by CDB
      RS_entry_ready[i] = T1_ready[i] && T2_ready[i];                            // T1 and T2 are ready to issue
      RS_entry_empty[i] = RS_entry_ready[i] && rs_packet_in.fu_valid[i];         // Entry is going to be empty
    end // for (int i = 0; i < `NUM_FU; i++) begin
  end // always_comb begin

  always_comb begin
    for (int i = 0; i < `NUM_FU; i++) begin
      rs_packet_out.FU_packet_out[i].ready     = RS_entry_ready[i] && !RS_rollback[i]; // Ready to issue
      rs_packet_out.FU_packet_out[i].inst      = RS[i].inst;                           // inst
      rs_packet_out.FU_packet_out[i].func      = RS[i].func;                           // op code
      rs_packet_out.FU_packet_out[i].NPC       = RS[i].NPC;                            // op code
      rs_packet_out.FU_packet_out[i].NPC       = RS[i].NPC;                            // op code
      rs_packet_out.FU_packet_out[i].dest_idx  = RS[i].dest_idx;                       // op code
      rs_packet_out.FU_packet_out[i].FL_idx    = RS[i].FL_idx;                         // op code
      rs_packet_out.FU_packet_out[i].T_idx     = RS[i].T_idx;                          // Output T_idx
      rs_packet_out.FU_packet_out[i].T1_idx    = RS[i].T1.idx;                         // Output T1_idx
      rs_packet_out.FU_packet_out[i].T2_idx    = RS[i].T2.idx;                         // Output T2_idx
      rs_packet_out.FU_packet_out[i].T1_select = RS[i].T1_select;                      // Output T2_idx
      rs_packet_out.FU_packet_out[i].T2_select = RS[i].T2_select;                      // Output T2_idx
    end
`ifdef RS_FORWARDING
    if ( FU_forward_hit && dispatch_en ) begin
      rs_packet_out.FU_packet_out[FU_forward_idx].ready      = `TRUE;                  // Ready to issue
      rs_packet_out.FU_packet_out[FU_forward_idx].inst       = decoder_packet_out.inst;      // inst
      rs_packet_out.FU_packet_out[FU_forward_idx].func       = decoder_packet_out.func;      // op code
      rs_packet_out.FU_packet_out[FU_forward_idx].NPC        = decoder_packet_out.NPC;       // op code
      rs_packet_out.FU_packet_out[FU_forward_idx].dest_idx   = decoder_packet_out.dest_idx;  // op code
      rs_packet_out.FU_packet_out[FU_forward_idx].opa_select = decoder_packet_out.opa_select; // Output T2_idx
      rs_packet_out.FU_packet_out[FU_forward_idx].opb_select = decoder_packet_out.opb_select; // Output T2_idx
      rs_packet_out.FU_packet_out[FU_forward_idx].ROB_idx    = rob_rs_out.ROB_idx;   // op code
      rs_packet_out.FU_packet_out[FU_forward_idx].FL_idx     = fl_rs_out.FL_idx;    // op code
      rs_packet_out.FU_packet_out[FU_forward_idx].T_idx      = fl_rs_out.T_idx;     // Output T_idx
      rs_packet_out.FU_packet_out[FU_forward_idx].T1_idx     = rs_packet_in.T1.idx;    // Output T1_idx
      rs_packet_out.FU_packet_out[FU_forward_idx].T2_idx     = rs_packet_in.T2.idx;    // Output T2_idx
    end
`endif
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
`ifdef RS_FORWARDING
    if ( RS_match_hit && !FU_forward_hit && dispatch_en ) begin // RS entry was not busy and inst ready to dispatch and FU match
`else
    if ( RS_match_hit && dispatch_en ) begin // RS entry was not busy and inst ready to dispatch and FU match
`endif
      next_RS[RS_match_idx].busy      = `TRUE;                  // RS entry busy
      next_RS[RS_match_idx].inst      = rs_packet_in.inst;      // inst
      next_RS[RS_match_idx].func      = rs_packet_in.func;      // func
      next_RS[RS_match_idx].NPC       = rs_packet_in.NPC;       // Write T1 select
      next_RS[RS_match_idx].NPC       = rs_packet_in.NPC;       // Write T1 select
      next_RS[RS_match_idx].dest_idx  = rs_packet_in.dest_idx;  // Write T1 select
      next_RS[RS_match_idx].FL_idx    = fl_rs_out.FL_idx;    // Write T1 select
      next_RS[RS_match_idx].T_idx     = fl_rs_out.T_idx;     // Write T
      next_RS[RS_match_idx].T1.ready  = rs_packet_in.T1.ready;  // Write T1
      next_RS[RS_match_idx].T2.ready  = rs_packet_in.T2.ready;  // Write T2
      next_RS[RS_match_idx].T1.idx    = rs_packet_in.T1.idx;    // Write T1
      next_RS[RS_match_idx].T2.idx    = rs_packet_in.T2.idx;    // Write T2
      next_RS[RS_match_idx].T1_select = rs_packet_in.T1_select; // Write T1 select
      next_RS[RS_match_idx].T2_select = rs_packet_in.T2_select; // Write T1 select
    end
  end // always_comb begin

  always_ff @(posedge clock) begin
    if(reset) begin
      RS <= `SD `RS_RESET;
    end else if(en) begin
      RS <= `SD next_RS;
    end // else if(en) begin
  end // always

endmodule // RS
