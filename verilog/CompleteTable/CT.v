module CT (
  input  en, clock, reset, 
  input  CT_PACKET_IN  ct_packet_in,
  output CT_PACKET_OUT ct_packet_out
);

  CT_entry_t [$clog2(`NUM_FU)-1:0] ct, next_ct;

  always_comb begin
    next_ct = ct;
    // save T & result, give stall signal
    for (int i=0; i<`NUM_FU; i++) begin
      if (next_ct[i].taken == 0 && ct_packet_in.X_C_valid[i] == 1) begin
        next_ct[i].taken == 1;
        next_ct[i].T = ct_packet_in.X_C_T[i];
        next_ct[i].result = ct_packet_in.X_C_result[i];
        ct_packet_out.full_hazard[i] = 1;
      end else if (next_ct[i].taken == 1) begin
        ct_packet_out.full_hazard[i] = 1;
      end
    end
    // broadcast
    for (int i=0; i<`NUM_FU; i++) begin
      if (ct_packet_out.full_hazard[i] == 1) begin
        ct_packet_out.valid = next_ct[i].taken;
        ct_packet_out.T = next_ct[i].T;
        ct_packet_out.result = next_ct[i].result;
        next_ct[i].taken = 0;
        ct_packet_out.full_hazard[i] = 0;
        break;
      end
    end

  end

  always_ff @(posedge clock) begin
    if (reset) begin
      ct <= `SD {`NUM_FU{0, 0, 0}};
    end else if (en) begin
      ct <= `SD next_ct;
    end
  end
endmodule