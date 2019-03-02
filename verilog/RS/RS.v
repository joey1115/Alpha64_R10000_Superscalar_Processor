module RS (
  input  logic         clock, reset, en,
  input  RS_PACKET_IN  rs_packet_in,
  output RS_PACKET_OUT rs_packet_out
);

  RS_ENTRY_t [`NUM_FU-1:0] RS, next_RS;
  FU_t       [`NUM_FU-1:0] FU_list = `FU_LIST;
  assign rs_packet_out.RS = next_RS;

  always_comb begin
    next_RS = RS;
    rs_packet_out.valid = `FALSE;
    for (int i = 0; i < `NUM_FU; i++) begin
      // Complete
      if ( rs_packet_in.complete_en ) begin
        if ( RS[i].T1.idx == rs_packet_in.CDB_T ) begin
          next_RS[i].T1.ready = `TRUE;
        end
        if ( RS[i].T2.idx == rs_packet_in.CDB_T ) begin
          next_RS[i].T2.ready = `TRUE;
        end
      end
      // Issue
      if ( FU_valid_list[i] ) begin
        
      end
      // Dispatch
      if ( rs_packet_in.FU == FU_list[i] && RS[i].busy == `FALSE && rs_packet_in.dispatch_en ) begin
        rs_packet_out.valid = `TRUE;
        rs_packet_out.FU_idx = i;
        next_RS[i].busy = `TRUE;
        next_RS[i].T    = rs_packet_in.dest_idx;
        next_RS[i].T1   = rs_packet_in.T1;
        next_RS[i].T2   = rs_packet_in.T2;
        break;
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