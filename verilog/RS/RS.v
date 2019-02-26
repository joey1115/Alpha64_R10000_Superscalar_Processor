module RS (
  input  logic         clock, resent, en,
  input  RS_PACKET_IN  rs_packet_in,
  output RS_PACKET_OUT rs_packet_out
);

  RS_ENTRY_t [`NUM_ALU-1:0] RS, next_RS;

  always_comb begin
    next_RS = RS;
    for (int i = 0; i <= `NUM_ALU; i++) begin
      if ( i == `NUM_ALU ) begin
        rs_packet_out.valid = `FALSE;
        break;
      end else if ( rs_packet_in.FU == RS.FU && RS.busy = `FALSE && rs_packet_in.dispatch_en ) begin
        rs_packet_out.ALU_idx = i;
        next_RS.T  = rs_packet_in.dest_idx;
        next_RS.T1 = rs_packet_in.rega_idx;
        next_RS.T2 = rs_packet_in.regb_idx;
        break;
      end
    end
  end

// ROB logic
  always_ff @(posedge clock) begin
    if(reset) begin
      RS <= `SD RS_RESET;
    end else if(en) begin
      RS <= `SD next_RS;
    end // if (f_d_enable)
  end // always

endmodule