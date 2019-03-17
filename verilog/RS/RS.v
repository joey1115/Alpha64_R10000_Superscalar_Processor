`timescale 1ns/100ps

module RS (
  input  logic         clock, reset, en,
  input  RS_PACKET_IN  rs_packet_in,

`ifdef DEBUG
  output RS_ENTRY_t [`NUM_FU-1:0] RS_out,
  output logic      [`NUM_FU-1:0] RS_entry_match,     // If a RS entry is ready
`endif

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
  logic      [`NUM_FU-1:0] RS_rollback;        // If a RS entry is ready

`ifdef RS_FORWARDING
  logic                    T1_CDB_in;          // If T1 is complete
  logic                    T2_CDB_in;          // If T2 is complete
  logic                    T1_ready_in;        // If T1 is ready
  logic                    T2_ready_in;        // If T2 is ready
  logic                    T_ready_in;         // If a RS entry is ready
  logic      [`NUM_FU-1:0] FU_entry_forward;   // If a RS entry is ready

  assign T1_CDB_in = rs_packet_in.T1.idx == rs_packet_in.CDB_T && rs_packet_in.complete_en;
  assign T2_CDB_in = rs_packet_in.T2.idx == rs_packet_in.CDB_T && rs_packet_in.complete_en;
  assign T1_ready_in = rs_packet_in.T1.ready || T1_CDB_in;
  assign T2_ready_in = rs_packet_in.T1.ready || T2_CDB_in;
  assign T_ready_in = T1_ready_in && T2_ready_in;

  always_comb begin

    FU_entry_forward[i] = {`NUM_FU{`FALSE}};

    for (int i = 0; i < `NUM_FU; i++) begin

      if ( T_ready_in && ( RS[i].busy == `FALSE || !RS_entry_ready[i] ) && rs_packet_in.fu_valid[i] && FU_list[i] == rs_packet_in.FU && rs_packet_in.dispatch_en ) begin

        FU_entry_forward[i] = `TRUE;
        break;

      end

    end

  end
`endif

`ifndef DEBUG
  logic      [`NUM_FU-1:0] RS_entry_match;     // If a RS entry is ready
`endif

`ifdef DEBUG
  assign RS_out = RS;
`endif

  always_comb begin

    for (int i = 0; i < `NUM_FU; i++) begin

      T1_CDB[i]         = RS[i].T1.idx == rs_packet_in.CDB_T && rs_packet_in.complete_en; // T1 is complete
      T2_CDB[i]         = RS[i].T2.idx == rs_packet_in.CDB_T && rs_packet_in.complete_en; // T2 is complete
      T1_ready[i]       = RS[i].T1.ready || T1_CDB[i];                                    // T1 is ready or updated by CDB
      T2_ready[i]       = RS[i].T2.ready || T2_CDB[i];                                    // T2 is ready or updated by CDB

      if ( rs_packet_in.rollback_en ) begin

        if ( rs_packet_in.ROB_tail_idx > rs_packet_in.ROB_rollback_idx ) begin

          RS_rollback[i] = rs_packet_in.rollback_en && ( RS[i].ROB_idx >= rs_packet_in.ROB_tail_idx || RS[i].ROB_idx < rs_packet_in.ROB_rollback_idx );

        end else begin

          RS_rollback[i] = rs_packet_in.rollback_en && ( RS[i].ROB_idx >= rs_packet_in.ROB_tail_idx && RS[i].ROB_idx < rs_packet_in.ROB_rollback_idx );

        end

      end else begin

        RS_rollback[i] = `FALSE;

      end

      RS_entry_ready[i] = T1_ready[i] && T2_ready[i] && !RS_rollback[i];                                               // T1 and T2 are ready to issue
      RS_entry_empty[i] = ( RS_entry_ready[i] && rs_packet_in.fu_valid[i] ) || RS[i].busy == `FALSE || RS_rollback[i];

    end // for (int i = 0; i < `NUM_FU; i++) begin

  end // always_comb begin

  always_comb begin

    RS_entry_match[i] =  {`NUM_FU{`FALSE}};

    for (int i = 0; i < `NUM_FU; i++) begin

      if ( RS_entry_empty[i] && FU_list[i] == rs_packet_in.FU && rs_packet_in.dispatch_en ) begin

        RS_entry_match[i] = `TRUE; // RS entry match
        break;

      end

    end // for (int i = 0; i < `NUM_FU; i++) begin

  end

  // Issue
  always_comb begin

    rs_packet_out.rs_valid = RS_entry_match != 0;

    for (int i = 0; i < `NUM_FU; i++) begin

      if ( RS_rollback[i] ) begin
        
        rs_packet_out.FU_packet_out[i] = FU_PACKET_ENTRY_RESET;

`ifdef RS_FORWARDING
      end else if ( FU_entry_forward[i] ) begin

        rs_packet_out.FU_packet_out[i].ready     = FU_entry_forward[i];    // Ready to issue
        rs_packet_out.FU_packet_out[i].inst      = rs_packet_in.inst;      // inst
        rs_packet_out.FU_packet_out[i].func      = rs_packet_in.func;      // op code
        rs_packet_out.FU_packet_out[i].NPC       = rs_packet_in.NPC;       // op code
        rs_packet_out.FU_packet_out[i].ROB_idx   = rs_packet_in.ROB_idx;   // op code
        rs_packet_out.FU_packet_out[i].FL_idx    = rs_packet_in.FL_idx;    // op code
        rs_packet_out.FU_packet_out[i].T_idx     = rs_packet_in.T_idx;     // Output T_idx
        rs_packet_out.FU_packet_out[i].T1_idx    = rs_packet_in.T1.idx;    // Output T1_idx
        rs_packet_out.FU_packet_out[i].T2_idx    = rs_packet_in.T2.idx;    // Output T2_idx
        rs_packet_out.FU_packet_out[i].T1_select = rs_packet_in.T1_select; // Output T2_idx
        rs_packet_out.FU_packet_out[i].T2_select = rs_packet_in.T2_select; // Output T2_idx
`endif

      end else begin

        rs_packet_out.FU_packet_out[i].ready     = RS_entry_ready[i]; // Ready to issue
        rs_packet_out.FU_packet_out[i].inst      = RS[i].inst;        // inst
        rs_packet_out.FU_packet_out[i].func      = RS[i].func;        // op code
        rs_packet_out.FU_packet_out[i].NPC       = RS[i].NPC;         // op code
        rs_packet_out.FU_packet_out[i].ROB_idx   = RS[i].ROB_idx;     // op code
        rs_packet_out.FU_packet_out[i].FL_idx    = RS[i].FL_idx;      // op code
        rs_packet_out.FU_packet_out[i].T_idx     = RS[i].T_idx;       // Output T_idx
        rs_packet_out.FU_packet_out[i].T1_idx    = RS[i].T1.idx;      // Output T1_idx
        rs_packet_out.FU_packet_out[i].T2_idx    = RS[i].T2.idx;      // Output T2_idx
        rs_packet_out.FU_packet_out[i].T1_select = RS[i].T1_select;   // Output T2_idx
        rs_packet_out.FU_packet_out[i].T2_select = RS[i].T2_select;   // Output T2_idx

      end

    end

  end

  always_comb begin
    next_RS = RS;

    for (int i = 0; i < `NUM_FU; i++) begin

      // Complete
      next_RS[i].T1.ready = T1_ready[i]; // T1 ready
      next_RS[i].T2.ready = T2_ready[i]; // T2 ready

      // Dispatch
`ifdef RS_FORWARDING
      if ( RS_entry_match[i] && !FU_entry_forward[i] ) begin // RS entry was not busy and inst ready to dispatch and FU match
`else
      if ( RS_entry_match[i] ) begin // RS entry was not busy and inst ready to dispatch and FU match
`endif

        next_RS[i].busy      = RS_entry_match[i];      // RS entry busy
        next_RS[i].inst      = rs_packet_in.inst;      // inst
        next_RS[i].func      = rs_packet_in.func;      // func
        next_RS[i].NPC       = rs_packet_in.NPC;       // Write T1 select
        next_RS[i].ROB_idx   = rs_packet_in.ROB_idx;   // Write T1 select
        next_RS[i].FL_idx    = rs_packet_in.FL_idx;    // Write T1 select
        next_RS[i].T_idx     = rs_packet_in.T_idx;     // Write T
        next_RS[i].T1.ready  = T1_ready[i];            // Write T1
        next_RS[i].T2.ready  = T2_ready[i];            // Write T2
        next_RS[i].T1.idx    = rs_packet_in.T1.idx;    // Write T1
        next_RS[i].T2.idx    = rs_packet_in.T2.idx;    // Write T2
        next_RS[i].T1_select = rs_packet_in.T1_select; // Write T1 select
        next_RS[i].T2_select = rs_packet_in.T2_select; // Write T1 select

      end  else if ( RS_entry_empty[i] ) begin

        next_RS[i] = `RS_ENTRY_RESET; // Clear RS entry

      end // if ( RS[i].busy == `FALSE && rs_packet_in.dispatch_en ) begin

    end // for (int i = 0; i < `NUM_FU; i++) begin

  end // always_comb begin

  always_ff @(posedge clock) begin
    if(reset) begin
      RS <= `SD `RS_RESET;
    end else if(en) begin
      RS <= `SD next_RS;
    end // else if(en) begin
  end // always

endmodule // RS
