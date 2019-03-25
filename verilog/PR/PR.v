/***********************************************
 * PR procedure:
 * 
 * Important Note:
 * Physical Register 31(`ZERO_PR) is read-only.
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


`timescale 1ns/100ps

module PR (
  input  logic                                            en, clock, reset,
  input  logic                                            write_en;                                      // (complete) write enable  from CDB
  input  CDB_PR_OUT_t                                     CDB_PR_out,
  input  FU_PR_OUT_t                                      FU_PR_out;
`ifndef SYNTH_TEST
  output logic         [`NUM_PR-1:0][63:0]                pr_data,
`endif
  output PR_PACKET_OUT                                    pr_packet_out
);

  logic [`NUM_PR-1:0] [63:0] pr, next_pr;

`ifndef SYNTH_TEST
  assign pr_data = pr;
`endif

  always_comb begin
    next_pr = pr;

    // Complete
    if (en && write_en && T_idx != `ZERO_PR) begin
      next_pr[T_idx] = T_value;
    end

    // Execution
    for (int i=0; i<`NUM_FU; i++) begin
      if (en && write_en && (T_idx == T1_idx[i]) && (T_idx != `ZERO_PR)) begin
        pr_packet_out.T1_value[i] = T_value;    // forwarding
      end else begin
        pr_packet_out.T1_value[i] = next_pr[T1_idx[i]];
      end

      if (en && write_en && (T_idx == T2_idx[i]) && (T_idx != `ZERO_PR)) begin
        pr_packet_out.T2_value[i] = T_value;    // forwarding
      end else begin
        pr_packet_out.T2_value[i] = next_pr[T2_idx[i]];
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