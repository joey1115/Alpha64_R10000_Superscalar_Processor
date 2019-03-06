`timescale 1ns/100ps

module RS (
  input  logic         clock, reset, en,
  input  RS_PACKET_IN  rs_packet_in,

`ifdef DEBUG
  output RS_ENTRY_t [`NUM_FU-1:0] RS_out,
  output logic      [`NUM_FU-1:0] RS_entry_match,     // If a RS entry is ready
`endif
  
  output logic         rs_hazard,       // RS hazard
  output RS_PACKET_OUT rs_packet_out
);

  RS_ENTRY_t [`NUM_FU-1:0] RS, next_RS;
  FU_t       [`NUM_FU-1:0] FU_list = `FU_LIST; // List of FU
  logic      [`NUM_FU-1:0] T1_CDB;             // If T1 is complete
  logic      [`NUM_FU-1:0] T2_CDB;             // If T2 is complete
  // logic                    T1_CDB_in;          // If T1 is complete
  // logic                    T2_CDB_in;          // If T2 is complete
  logic      [`NUM_FU-1:0] T1_ready;           // If T1 is ready
  logic      [`NUM_FU-1:0] T2_ready;           // If T2 is ready
  // logic                    T1_ready_in;        // If T1 is ready
  // logic                    T2_ready_in;        // If T2 is ready
  logic      [`NUM_FU-1:0] RS_T_ready;         // If a RS entry is ready
  // logic                    T_ready_in;         // If a RS entry is ready
  // logic      [`NUM_FU-1:0] RS_entry_ready;     // If a RS entry is ready
  // logic      [`NUM_FU-1:0] RS_entry_forward;   // If a RS entry is ready
  logic      [`NUM_FU-1:0] RS_entry_empty;     // If a RS entry is ready
  
`ifndef DEBUG
  logic      [`NUM_FU-1:0] RS_entry_match;     // If a RS entry is ready
`endif

`ifdef DEBUG
  assign RS_out = RS;
`endif

  assign rs_hazard = RS_entry_match == 0;
  // assign T1_CDB_in = rs_packet_in.T1.idx == rs_packet_in.CDB_T && rs_packet_in.complete_en;
  // assign T2_CDB_in = rs_packet_in.T2.idx == rs_packet_in.CDB_T && rs_packet_in.complete_en;
  // assign T1_ready_in = rs_packet_in.T1.ready || T1_CDB_in;
  // assign T2_ready_in = rs_packet_in.T1.ready || T2_CDB_in;
  // assign T_ready_in = T1_ready_in && T2_ready_in;

  always_comb begin
    for (int i = 0; i < `NUM_FU; i++) begin

      T1_CDB[i]         = RS[i].T1.idx == rs_packet_in.CDB_T && rs_packet_in.complete_en; // T1 is complete
      T2_CDB[i]         = RS[i].T2.idx == rs_packet_in.CDB_T && rs_packet_in.complete_en; // T2 is complete
      T1_ready[i]       = RS[i].T1.ready || T1_CDB[i];                                    // T1 is ready or updated by CDB
      T2_ready[i]       = RS[i].T2.ready || T1_CDB[i];                                    // T2 is ready or updated by CDB
      RS_T_ready[i]     = T1_ready[i] && T2_ready[i] && rs_packet_in.fu_hazard[i];        // T1 and T2 are ready to issue
      RS_entry_empty[i] = RS_T_ready[i] || RS[i].busy == `FALSE;                          // RS entry empty
      RS_entry_match[i] = RS_entry_empty[i] && FU_list[i] == rs_packet_in.FU;             // RS entry match

  //     RS_entry_ready[i]   = RS[i].busy == `FALSE && rs_packet_in.fu_hazard[i] == `TRUE && FU_list[i] == rs_packet_in.FU;
  //     RS_entry_forward[i] = T_ready_in && RS_entry_ready[i];

    end // for (int i = 0; i < `NUM_FU; i++) begin
  end // always_comb begin

  always_comb begin
    next_RS = RS;
    rs_packet_out.FU_packet_out = `FU_RESET;

    // Complete
    for (int i = 0; i < `NUM_FU; i++) begin

      if ( T1_CDB[i] ) begin // T1 idx match
        next_RS[i].T1.ready = `TRUE; // T1 ready
      end // if ( RS[i].T1.idx == rs_packet_in.CDB_T ) begin
      if ( T2_CDB[i] ) begin // T1 idx match
        next_RS[i].T2.ready = `TRUE; // T2 ready
      end // if ( RS[i].T2.idx == rs_packet_in.CDB_T ) begin

    // end // for (int i = 0; i < `NUM_FU; i++) begin

    // Issue
    // for (int i = 0; i < `NUM_FU; i++) begin

      if ( RS_T_ready[i] ) begin                              // T1 and T2 are ready to issue
        rs_packet_out.FU_packet_out[i].ready  = `TRUE;        // Ready to issue
        rs_packet_out.FU_packet_out[i].T_idx  = RS[i].T_idx;  // Output T_idx
        rs_packet_out.FU_packet_out[i].T1_idx = RS[i].T1.idx; // Output T1_idx
        rs_packet_out.FU_packet_out[i].T2_idx = RS[i].T2.idx; // Output T2_idx
        rs_packet_out.FU_packet_out[i].func   = RS[i].func;   // op code
        rs_packet_out.FU_packet_out[i].inst   = RS[i].inst;   // inst
        next_RS[i] = `RS_ENTRY_RESET; // Clear RS entry
      end // if ( RS_entry_ready[i] ) begin

    end // for (int i = 0; i < `NUM_FU; i++) begin

    // Dispatch
    if ( rs_packet_in.dispatch_en ) begin
      for (int i = 0; i < `NUM_FU; i++) begin

        if ( RS_entry_match[i] ) begin              // RS entry was not busy and inst ready to dispatch and FU match
          next_RS[i].busy  = `TRUE;                 // RS entry busy
          next_RS[i].inst  = rs_packet_in.inst;     // inst
          next_RS[i].func  = rs_packet_in.func;     // func
          next_RS[i].T_idx = rs_packet_in.dest_idx; // Write T
          next_RS[i].T1    = rs_packet_in.T1;       // Write T1
          next_RS[i].T2    = rs_packet_in.T2;       // Write T2
          break;
        end // if ( RS[i].busy == `FALSE && rs_packet_in.dispatch_en ) begin

      end // for (int i = 0; i < `NUM_FU; i++) begin

      // // Dispatch
      // for (int i = 0; i < `NUM_FU; i++) begin

      //   if ( RS_entry_forward == 0 ) begin
          
      //     if ( RS_entry_match[i] ) begin              // RS entry was not busy and inst ready to dispatch and FU match
      //       next_RS[i].busy  = `TRUE;                 // RS entry busy
      //       next_RS[i].inst  = rs_packet_in.inst;     // inst
      //       next_RS[i].func  = rs_packet_in.func;     // func
      //       next_RS[i].T_idx = rs_packet_in.dest_idx; // Write T
      //       next_RS[i].T1    = rs_packet_in.T1;       // Write T1
      //       next_RS[i].T2    = rs_packet_in.T2;       // Write T2
      //       break;
      //     end // if ( RS[i].busy == `FALSE && rs_packet_in.dispatch_en ) begin

      //   end else if ( RS_entry_forward[i] ) begin

      //     rs_packet_out.FU_packet_out[i].ready  = `TRUE;                 // Ready to issue
      //     rs_packet_out.FU_packet_out[i].T_idx  = rs_packet_in.dest_idx; // Output T_idx
      //     rs_packet_out.FU_packet_out[i].T1_idx = rs_packet_in.T1.idx;   // Output T1_idx
      //     rs_packet_out.FU_packet_out[i].T2_idx = rs_packet_in.T2.idx;   // Output T2_idx
      //     rs_packet_out.FU_packet_out[i].func   = rs_packet_in.func;     // op code
      //     rs_packet_out.FU_packet_out[i].inst   = rs_packet_in.inst;     // inst
      //     break;

      //   end

      // end // for (int i = 0; i < `NUM_FU; i++) begin
    end

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