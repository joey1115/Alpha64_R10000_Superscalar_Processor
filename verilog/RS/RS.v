module RS (
  input  logic         clock, reset, en,
  input  RS_PACKET_IN  rs_packet_in,
  output RS_PACKET_OUT rs_packet_out
);

  RS_ENTRY_t [`NUM_FU-1:0] RS, next_RS;
  FU_t       [`NUM_FU-1:0] FU_list = `FU_LIST; // List of FU
  logic      [`NUM_FU-1:0] T1_CDB;             // If T1 is complete
  logic      [`NUM_FU-1:0] T2_CDB;             // If T2 is complete
  logic      [`NUM_FU-1:0] T1_ready;           // If T1 is ready
  logic      [`NUM_FU-1:0] T2_ready;           // If T2 is ready
  logic      [`NUM_FU-1:0] RS_entry_ready;     // If a RS entry is ready
  logic      [`NUM_FU-1:0] RS_entry_empty;     // If a RS entry is ready
  logic                    dispatched;     // If a RS entry is ready
  assign rs_packet_out.RS = next_RS;

  // Hazard
  always_comb begin
    rs_packet_out.valid = `FALSE;
    for (int i = 0; i < `NUM_FU; i++) begin
      T1_CDB[i]         = RS[i].T1.idx == rs_packet_in.CDB_T && rs_packet_in.complete_en; // T1 is complete
      T2_CDB[i]         = RS[i].T2.idx == rs_packet_in.CDB_T && rs_packet_in.complete_en; // T2 is complete
      T1_ready[i]       = RS[i].T1.ready || T1_CDB[i];                                    // T1 is ready or updated by CDB
      T2_ready[i]       = RS[i].T2.ready || T1_CDB[i];                                    // T2 is ready or updated by CDB
      RS_entry_ready[i] = T1_ready[i] && T2_ready[i];                                     // T1 and T2 are ready to issue
      RS_entry_empty[i] = ( RS_entry_ready[i]  || RS[i].busy == `FALSE );                 // RS entry empty
      if ( RS_entry_empty[i] && FU_list[i] == rs_packet_in.FU ) begin                     // FU match
        rs_packet_out.valid = `TRUE;                                                      // No hazard
        break;
      end // if ( ( RS_entry_ready[i]  || RS[i].busy == `FALSE ) && FU_list[i] == rs_packet_in.FU ) begin
    end // for (int i = 0; i < `NUM_FU; i++) begin
  end // always_comb begin

  always_comb begin
    next_RS = RS;
    dispatched = `FALSE;
    rs_packet_out.FU_packet_out = `FU_RESET;

    for (int i = 0; i < `NUM_FU; i++) begin

      // Complete
      if ( T1_CDB[i] ) begin // T1 idx match
        next_RS[i].T1.ready = `TRUE; // T1 ready
      end // if ( RS[i].T1.idx == rs_packet_in.CDB_T ) begin
      if ( T2_CDB[i] ) begin // T1 idx match
        next_RS[i].T2.ready = `TRUE; // T2 ready
      end // if ( RS[i].T2.idx == rs_packet_in.CDB_T ) begin

      // Issue
      if ( RS_entry_ready[i] ) begin                                                 // T1 and T2 are ready to issue
        rs_packet_out.FU_packet_out[i].ready  = `TRUE;                               // Ready to issue
        rs_packet_out.FU_packet_out[i].T_idx  = RS[i].T_idx;                         // Output T_idx
        rs_packet_out.FU_packet_out[i].T1_idx = RS[i].T1.idx;                        // Output T1_idx
        rs_packet_out.FU_packet_out[i].T2_idx = RS[i].T2.idx;                        // Output T2_idx
        next_RS[i] = '{`FALSE, `ZERO_REG, `T_RESET, `T_RESET};                       // Clear RS entry
      end // if ( RS_entry_ready[i] ) begin

      //Dispatch
      if ( RS_entry_empty[i] && FU_list[i] == rs_packet_in.FU && rs_packet_in.dispatch_en ) begin // RS entry was not busy and inst ready to dispatch and FU match
        dispatched       = `TRUE;
        next_RS[i].busy  = `TRUE;                                                                 // RS entry busy
        next_RS[i].T_idx = rs_packet_in.dest_idx;                                                 // Write T
        next_RS[i].T1    = rs_packet_in.T1;                                                       // Write T1
        next_RS[i].T2    = rs_packet_in.T2;                                                       // Write T2
        break;
      end // if ( RS[i].busy == `FALSE && rs_packet_in.dispatch_en ) begin

    end // for (int i = 0; i < `NUM_FU; i++) begin

  end // always_comb begin

// ROB logic
  always_ff @(posedge clock) begin
    if(reset) begin
      RS <= `SD `RS_RESET;
    end else if(en) begin
      RS <= `SD next_RS;
    end // else if(en) begin
  end // always

endmodule // RS