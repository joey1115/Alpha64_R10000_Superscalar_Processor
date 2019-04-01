`timescale 1ns/100ps

module RS (
  input  logic                                                     clock, reset, en, dispatch_en, rollback_en,
  input  logic              [`NUM_SUPER-1:0]                       complete_en,
  input  logic              [`NUM_FU-1:0]                          FU_valid,
  input  logic              [$clog2(`NUM_ROB)-1:0]                 ROB_rollback_idx,
  input  logic              [$clog2(`NUM_ROB)-1:0]                 diff_ROB,
  input  logic              [`NUM_SUPER-1:0][$clog2(`NUM_ROB)-1:0] ROB_idx,
  input  DECODER_RS_OUT_t                                          decoder_RS_out,
  input  FL_RS_OUT_t                                               FL_RS_out,
  input  MAP_TABLE_RS_OUT_t                                        Map_Table_RS_out,
  input  CDB_RS_OUT_t                                              CDB_RS_out,
`ifdef DEBUG
  output RS_ENTRY_t         [`NUM_FU-1:0]                          RS_out,
  output logic              [`NUM_FU-1:0]                          RS_match_hit,   // If a RS entry is ready
  output logic              [`NUM_SUPER-1:0][$clog2(`NUM_FU)-1:0]  RS_match_idx,
`endif
  output logic                                                     RS_valid,
  output RS_FU_OUT_t                                               RS_FU_out,
  output RS_PR_OUT_t                                               RS_PR_out
);

  FU_PACKET_t    [`NUM_FU-1:0]                         FU_packet;      // List of output fu
  RS_ENTRY_t     [`NUM_FU-1:0]                         RS, next_RS;
  FU_t           [`NUM_FU-1:0]                         FU_list;        // List of FU
  FU_IDX_ENTRY_t [`NUM_FU-1:0]                         FU_T_idx;
  logic          [`NUM_FU-1:0]                         T1_CDB;         // If T1 is complete
  logic          [`NUM_FU-1:0]                         T2_CDB;         // If T2 is complete
  logic          [`NUM_FU-1:0]                         T1_ready;       // If T1 is ready
  logic          [`NUM_FU-1:0]                         T2_ready;       // If T2 is ready
  logic          [`NUM_FU-1:0]                         RS_entry_ready;       // If T2 is ready
  logic          [`NUM_FU-1:0]                         RS_rollback;    // If a RS entry is ready
  logic          [`NUM_FU-1:0]                         FU_entry_match;
  logic          [`NUM_FU-1:0][$clog2(`NUM_ROB)-1:0]   diff;
`ifndef DEBUG
  logic          [`NUM_FU-1:0]                         RS_match_hit;   // If a RS entry is ready
  logic          [`NUM_SUPER-1:0][$clog2(`NUM_FU)-1:0] RS_match_idx;
`endif

  assign RS_FU_out = '{FU_packet};
  assign RS_PR_out = '{FU_T_idx};
  assign RS_valid  = RS_match_hit == {`NUM_SUPER{`TRUE}};
`ifdef DEBUG
  assign RS_out = RS;
`endif

  always_comb begin
    for (int i = 0; i < `NUM_SUPER; i++) begin
      RS_match_hit[i] =  `FALSE;
      RS_match_idx[i] = {$clog2(`NUM_FU){1'b0}};
      for (int j = i; j < `NUM_FU; j = j + `NUM_SUPER) begin
        if ( RS[j].busy == `FALSE && FU_entry_match[j] ) begin
          RS_match_hit[i] = `TRUE; // RS entry match
          RS_match_idx[i] = j;
          break;
        end
      end // for (int i = 0; i < `NUM_FU; i++) begin
    end
  end

  always_comb begin
    for (int i = 0; i < `NUM_SUPER; i++) begin
      for (int j = 0; j < `NUM_FU; j = j + 2) begin
        T1_CDB[j]   = RS[j].T1.idx == CDB_RS_out.T_idx[i] && CDB_RS_out.T_idx[i] != `ZERO_PR && complete_en[i]; // T1 is complete
        T1_ready[j] = RS[j].T1.ready || T1_CDB[j];                     // T1 is ready or updated by CDB
      end // for (int i = 0; i < `NUM_FU; i++) begin
    end
  end // always_comb begin

  always_comb begin
    for (int i = 0; i < `NUM_SUPER; i++) begin
      for (int j = 0; j < `NUM_FU; j = j + 2) begin
        T2_CDB[j]   = RS[j].T1.idx == CDB_RS_out.T_idx[i] && CDB_RS_out.T_idx[i] != `ZERO_PR && complete_en[i]; // T1 is complete
        T2_ready[j] = RS[j].T1.ready || T2_CDB[j];                     // T1 is ready or updated by CDB
      end // for (int i = 0; i < `NUM_FU; i++) begin
    end
  end // always_comb begin

  always_comb begin
    for (int j = 0; j < `NUM_FU; j++) begin
      RS_entry_ready[j] = RS[j].T1.ready && RS[j].T2.ready;
    end // for (int i = 0; i < `NUM_FU; i++) begin
  end // always_comb begin

  always_comb begin
    for (int i = 0; i < `NUM_SUPER; i++) begin
      for (int j = 0; j < `NUM_FU; j = j + 2) begin
        FU_entry_match[j] = FU_list[j] == decoder_RS_out.FU[i];
      end // for (int i = 0; i < `NUM_FU; i++) begin
    end
  end

  always_comb begin
    for (int j = 0; j < `NUM_FU; j++) begin
      diff[j]        = RS[j].ROB_idx - ROB_rollback_idx;                // diff
      RS_rollback[j] = ( diff_ROB >= diff[j] ) && rollback_en;          // Rollback
    end // for (int i = 0; i < `NUM_FU; i++) begin
  end // always_comb begin

  always_comb begin
    for (int j = 0; j < `NUM_FU; j++) begin
      FU_packet[j].ready         = RS_entry_ready[j];   // Ready to issue
      FU_packet[j].ROB_idx       = RS[j].ROB_idx;       // op code
      FU_packet[j].inst          = RS[j].inst;          // inst
      FU_packet[j].func          = RS[j].func;          // op code
      FU_packet[j].NPC           = RS[j].NPC;           // op code
      FU_packet[j].dest_idx      = RS[j].dest_idx;      // op code
      FU_packet[j].opa_select    = RS[j].opa_select;    // Output T2_idx
      FU_packet[j].opb_select    = RS[j].opb_select;    // Output T2_idx
      FU_packet[j].uncond_branch = RS[j].uncond_branch; // Output T2_idx
      FU_packet[j].cond_branch   = RS[j].cond_branch;   // Output T2_idx
      FU_packet[j].FL_idx        = RS[j].FL_idx;        // op code
      FU_packet[j].T_idx         = RS[j].T_idx;         // Output T_idx
      FU_T_idx[j].T1_idx         = RS[j].T1.idx;        // Output T1_idx
      FU_T_idx[j].T2_idx         = RS[j].T2.idx;        // Output T2_idx
    end
  end

  always_comb begin
    next_RS = RS;
    for (int j = 0; j < `NUM_FU; j++) begin
      next_RS[j].T1.ready = T1_ready[j]; // T1 ready
      next_RS[j].T2.ready = T2_ready[j]; // T2 ready
      if ( RS_entry_ready[j] || RS_rollback[j] ) begin
        next_RS[j] = `RS_ENTRY_RESET; // Clear RS entry
      end // if ( RS[i].busy == `FALSE && dispatch_en ) begin
    end // for (int i = 0; i < `NUM_FU; i++) begin
    for (int i = 0; i < `NUM_SUPER; i++) begin
      if ( dispatch_en ) begin // RS entry was not busy and inst ready to dispatch and FU match
        next_RS[RS_match_idx[i]].busy          = `TRUE;                        // RS entry busy
        next_RS[RS_match_idx[i]].ROB_idx       = ROB_idx[i];                      // op code
        next_RS[RS_match_idx[i]].inst          = decoder_RS_out.inst[i];          // inst
        next_RS[RS_match_idx[i]].func          = decoder_RS_out.func[i];          // func
        next_RS[RS_match_idx[i]].NPC           = decoder_RS_out.NPC[i];           // Write T1 select
        next_RS[RS_match_idx[i]].dest_idx      = decoder_RS_out.dest_idx[i];      // Write T1 select
        next_RS[RS_match_idx[i]].opa_select    = decoder_RS_out.opa_select[i];    // Output T2_idx
        next_RS[RS_match_idx[i]].opb_select    = decoder_RS_out.opb_select[i];    // Output T2_idx
        next_RS[RS_match_idx[i]].uncond_branch = decoder_RS_out.uncond_branch[i]; // Output T2_idx
        next_RS[RS_match_idx[i]].cond_branch   = decoder_RS_out.cond_branch[i];   // Output T2_idx
        next_RS[RS_match_idx[i]].FL_idx        = FL_RS_out.FL_idx[i];             // Write T1 select
        next_RS[RS_match_idx[i]].T_idx         = FL_RS_out.T_idx[i];              // Write T
        next_RS[RS_match_idx[i]].T1            = Map_Table_RS_out.T1[i];          // Write T1
        next_RS[RS_match_idx[i]].T2            = Map_Table_RS_out.T2[i];          // Write T2
      end
    end
  end // always_comb begin

  assign FU_list = {{(`NUM_ALU){FU_ALU}}, {(`NUM_MULT){FU_MULT}}, {(`NUM_BR){FU_BR}}, {(`NUM_ST){FU_ST}}, {(`NUM_LD){FU_LD}}};

  always_ff @(posedge clock) begin
    if(reset) begin
      RS <= `SD `RS_RESET;
    end else if(en) begin
      RS <= `SD next_RS;
    end // else if(en) begin
  end // always
endmodule // RS
