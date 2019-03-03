module RS (
  input  logic         clock, reset, en,
  input  RS_PACKET_IN  rs_packet_in,
  output RS_PACKET_OUT rs_packet_out
);

  RS_ENTRY_t [`NUM_FU-1:0] RS, next_RS;
  FU_t       [`NUM_FU-1:0] FU_list = `FU_LIST;
  logic      [`NUM_FU-1:0] T1_ready;
  logic      [`NUM_FU-1:0] T2_ready;
  logic      [`NUM_FU-1:0] RS_entry_ready;
  logic                    dispatched;
  assign rs_packet_out.RS = next_RS;

  // Hazard
  always_comb begin
    rs_packet_out.valid = `FALSE;
    for (int i = 0; i < `NUM_FU; i++) begin
      T1_ready[i]       = RS[i].T1.ready || RS[i].T1.idx == rs_packet_in.CDB_T; // T1 is ready or updated by CDB
      T2_ready[i]       = RS[i].T2.ready || RS[i].T2.idx == rs_packet_in.CDB_T; // T2 is ready or updated by CDB
      RS_entry_ready[i] = T1_ready[i] && T2_ready[i] || RS[i].busy == `FALSE;   // T1 and T2 are ready to issue
      if ( RS_entry_ready[i] && FU_list[i] == rs_packet_in.FU) begin            // FU match
        rs_packet_out.valid = `TRUE;                                            // No hazard
        break;
      end
    end
  end

  always_comb begin
    next_RS = RS;

    // Complete
    for (int i = 0; i < `NUM_FU; i++) begin
      if ( rs_packet_in.complete_en ) begin             // CDB ready to update
        if ( RS[i].T1.idx == rs_packet_in.CDB_T ) begin // T1 idx match
          next_RS[i].T1.ready = `TRUE;                  // T1 ready
        end
        if ( RS[i].T2.idx == rs_packet_in.CDB_T ) begin // T1 idx match
          next_RS[i].T2.ready = `TRUE;                  // T2 ready
        end
      end
    end

    // Issue
    for (int i = 0; i < `NUM_FU; i++) begin
      if ( RS_entry_ready[i] ) begin                           // T1 and T2 are ready to issue
        rs_packet_out.FU_packet_out[i].ready  = `TRUE;         // Ready to issue
        rs_packet_out.FU_packet_out[i].T_idx  = RS[i].T_idx;   // Output T_idx
        rs_packet_out.FU_packet_out[i].T1_idx = RS[i].T1.idx;  // Output T1_idx
        rs_packet_out.FU_packet_out[i].T2_idx = RS[i].T2.idx;  // Output T2_idx
        next_RS[i] = '{`FALSE, `ZERO_REG, `T_RESET, `T_RESET}; // Clear RS entry
      end else begin
        rs_packet_out.FU_packet_out[i] = '{`FALSE, `ZERO_REG, `ZERO_REG, `ZERO_REG}; // Output not ready
      end
    end

    dispatched = `FALSE;
    //Dispatch
    for (int i = 0; i < `NUM_FU; i++) begin
      if ( RS[i].busy == `FALSE && rs_packet_in.dispatch_en && rs_packet_in.FU == FU_list[i] ) begin // RS entry was not busy and inst ready to dispatch and FU match
        if ( rs_packet_in.T1.ready && rs_packet_in.T2.ready ) begin                                  // Input T1 and T2 are ready
          rs_packet_out.FU_packet_out[i].ready  = `TRUE;                                             // Ready to issue
          rs_packet_out.FU_packet_out[i].T_idx  = rs_packet_in.dest_idx;                             // Output T_idx
          rs_packet_out.FU_packet_out[i].T1_idx = rs_packet_in.T1.idx;                               // Output T1_idx
          rs_packet_out.FU_packet_out[i].T2_idx = rs_packet_in.T2.idx;                               // Output T2_idx
          next_RS[i] = '{`FALSE, `ZERO_REG, `T_RESET, `T_RESET};                                     // RS entry not busy
        end else begin                                                                               // T1 or T2 is not ready
          next_RS[i].busy  = `TRUE;                                                                  // RS entry busy
          next_RS[i].T_idx = rs_packet_in.dest_idx;                                                  // Write T
          next_RS[i].T1    = rs_packet_in.T1;                                                        // Write T1
          next_RS[i].T2    = rs_packet_in.T2;                                                        // Write T2
        end // if ( rs_packet_in.T1.ready && rs_packet_in.T2.ready ) begin
        dispatched = `TRUE;
        break;
      end // if ( RS[i].busy == `FALSE && rs_packet_in.dispatch_en ) begin
    end

    // Dispatch
    if ( dispatched == `FALSE ) begin                                                 // If inst has not been dispatched
      for (int i = 0; i < `NUM_FU; i++) begin
        if ( ( next_RS[i].busy == `FALSE ) && rs_packet_in.dispatch_en && rs_packet_in.FU == FU_list[i] ) begin // If previous inst left
          next_RS[i].busy  = `TRUE;                                                                             // RS entry busy
          next_RS[i].T_idx = rs_packet_in.dest_idx;                                                             // Write T
          next_RS[i].T1    = rs_packet_in.T1;                                                                   // Write T1
          next_RS[i].T2    = rs_packet_in.T2;                                                                   // Write T2
          break;
        end
      end
    end

  end

// ROB logic
  always_ff @(posedge clock) begin
    if(reset) begin
      RS <= `SD `RS_RESET;
    end else if(en) begin
      RS <= `SD next_RS;
    end // if (f_d_enable)
  end // always

endmodule