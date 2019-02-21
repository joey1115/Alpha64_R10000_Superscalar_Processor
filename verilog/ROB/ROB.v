module ROB_m (
  input  ROB_PACKET_IN  rob_packet_in,
  output ROB_PACKET_OUT rob_packet_out
);

ROB_ENTRY_t [$clog2(`NUM_ROB)-1:0] ROB, next_ROB;

// ROB logic
  always_ff @(posedge clock) begin
    if(reset) begin
      // ROB       <= `SD {`NUM_ROB{'{HT_FREE, PR_FREE}};
    end else if(rob_packet_in.en) begin
      ROB       <= `SD next_ROB;
    end // if (f_d_enable)
  end // always

endmodule