/***********************************************
 * PR procedure:
 * 
 * Important Note:
 * Physical Register 31 is read-only.
 * It is the zero register and contains value zero
 * 
 * --- Complete ---
 * 1. X stage result write back to PR
 * input: write_en (CDB), T_idx (CDB), T_value (CDB)
 * 
 * ---- Excution ----
 * 1. send reg values to FU
 * input: T1_idx, T2_idx
 * output: T1_value, T2_value (T_value can be interally
 * forward to T1_value or T2_value)
 * 
 ************************************************/

`define DEBUG_PR

`timescale 1ns/100ps

module PR (
  input  en, clock, reset,
  input  PR_PACKET_IN  pr_packet_in,

  `ifdef DEBUG_PR
  output logic [`NUM_PR-1:0] [63:0] pr_data,
  `endif
  output PR_PACKET_OUT pr_packet_out
);

  logic [`NUM_PR-1:0] [63:0] pr, next_pr;

  `ifdef DEBUG_PR
  assign pr_data = pr;
  `endif

  always_comb begin
    next_pr = pr;

    // Complete
    if (en && pr_packet_in.write_en && pr_packet_in.T_idx != 31) begin
      next_pr[pr_packet_in.T_idx] = pr_packet_in.T_value;
    end

    // Execution
    for (int i=0; i<`NUM_FU; i++) begin
      if (en && pr_packet_in.write_en && (pr_packet_in.T_idx == pr_packet_in.T1_idx[i]) && (pr_packet_in.T_idx != 31)) begin
      // if (1==2) begin
        pr_packet_out.T1_value[i] = pr_packet_in.T_value;    // forwarding
      end else begin
        pr_packet_out.T1_value[i] = next_pr[pr_packet_in.T1_idx[i]];
      end

      if (en && pr_packet_in.write_en && (pr_packet_in.T_idx == pr_packet_in.T2_idx[i]) && (pr_packet_in.T_idx != 31)) begin
      // if (1==2) begin
        pr_packet_out.T2_value[i] = pr_packet_in.T_value;    // forwarding
      end else begin
        pr_packet_out.T2_value[i] = next_pr[pr_packet_in.T2_idx[i]];
      end
    end // for

  end // always_comb

  always_ff @(posedge clock) begin
    if (reset) begin
      for (int i=0; i<`NUM_PR; i++) begin
        pr[i] <= `SD 64'b0;
      end
    end else if (en) begin
      pr <= `SD next_pr;
    end
  end // always_ff

endmodule