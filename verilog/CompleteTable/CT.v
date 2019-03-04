module CT (
  input  en, clock, reset, 
  input  CT_PACKET_IN  ct_packet_in,
  output CT_PACKET_OUT ct_packet_out
);

  CT_entry_t [$clog2(`NUM_FU)-1:0] ct, next_ct;

  always_comb begin
    next_ct = ct;

    // Update taken, T & result for each empty entry
    // and give full_hazard to FU
    for (int i=0; i<`NUM_FU; i++) begin
      ct_packet_out.full_hazard[i] = next_ct[i].taken;
      if (next_ct[i].taken == 0 && ct_packet_in.X_C_valid[i] == 1) begin
        next_ct[i].taken == 1;
        next_ct[i].T = ct_packet_in.X_C_T[i];
        next_ct[i].result = ct_packet_in.X_C_result[i];
        ct_packet_out.full_hazard[i] = 1;
      end
    end
    // broadcast one completed instruction (if one is found)
    ct_packet_out.valid  = 0;
    ct_packet_out.T      = 0;
    ct_packet_out.result = 0;
    for (int i=0; i<`NUM_FU; i++) begin
      if (next_ct[i].taken) begin
        ct_packet_out.valid = 1'b1;
        ct_packet_out.T = next_ct[i].T;
        ct_packet_out.result = next_ct[i].result;
        // try filling this entry if X_C reg wants to write a new input here
        // (compare T to prevent re-writing the entry with the same inst.)
        if (ct_packet_in.X_C_valid[i] && ct_packet_in.X_C_T != next_ct[i].T) begin
          next_ct[i].T = ct_packet_in.X_C_T[i];
          next_ct[i].result = ct_packet_in.X_C_result[i];
        end else begin
          next_ct[i].taken = 0;
          ct_packet_out.full_hazard[i] = 0;
        end // else if
        break;
      end // if
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