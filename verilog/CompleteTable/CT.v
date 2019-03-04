module PR_m (
  input  PR_PACKET_IN  pr_packet_in,
  output PR_PACKET_OUT pr_packet_out
);

  PR_t [$clog2(`NUM_PR)-1:0] PR, next_PR;

// ROB logic
  always_ff @(posedge clock) begin
    if(reset) begin
      PR <= `SD {`NUM_PR{'{0, PR_FREE}};
    end else if(rob_packet_in.en) begin
      PR <= `SD next_PR;
    end // if (f_d_enable)
  end // always

endmodule