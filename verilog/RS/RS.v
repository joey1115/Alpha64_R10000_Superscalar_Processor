module RS_m (
  input  RS_PACKET_IN  rs_packet_in,
  output RS_PACKET_OUT rs_packet_out
);

  RS_ENTRY_t [$clog2(`NUM_ALU)-1:0] RS, next_RS;

// ROB logic
  always_ff @(posedge clock) begin
    if(reset) begin
      // RS <= `SD 0;
    end else if(rob_packet_in.en) begin
      RS <= `SD next_RS;
    end // if (if_id_enable)
  end // always

endmodule