module RS_m (
  input  RS_PACKET_IN  rs_packet_in,
  output RS_PACKET_OUT rs_packet_out
);

  RS_ENTRY_t [`NUM_ALU:0] RS, next_RS;

  always_comb begin
    next_RS = RS;
    genvar i;
    for (i = 0; i <= `NUM_ALU; i++) begin
      if ( i == `NUM_ALU ) begin
        rs_packet_out.valid = `FALSE;
        break;
      end else if ( rs_packet_in == RS.FU && RS.busy = `FALSE ) begin
        rs_packet_out.ALU_idx = i;
        next_RS.T = rs_packet_in.dest_idx;
        next_RS.T1 = rs_packet_in.rega_idx;
        next_RS.T2 = rs_packet_in.regb_idx;
      end
    end
  end

// ROB logic
  always_ff @(posedge clock) begin
    if(reset) begin
      RS <= `SD {`NUM_ALU{RS_ENTRY_RESET}};
    end else if(rob_packet_in.en) begin
      RS <= `SD next_RS;
    end // if (f_d_enable)
  end // always

endmodule