`timescale 1ns/100ps

module PR (
  input  logic                                            en, clock, reset,
  input  logic                                            write_en,         // (complete) write enable  from CDB
  input  CDB_PR_OUT_t                                     CDB_PR_out,
  input  RS_PR_OUT_t                                      RS_PR_out,
`ifndef SYNTH_TEST
  output logic         [`NUM_PR-1:0][63:0]                pr_data,
`endif
  output PR_FU_OUT_t                                      PR_FU_out
);

  logic [`NUM_PR-1:0] [63:0] pr, next_pr;

`ifndef SYNTH_TEST
  assign pr_data = pr;
`endif

  always_comb begin
    next_pr = pr;
    // Complete
    if (write_en && CDB_PR_out.T_idx != `ZERO_PR) begin
      next_pr[CDB_PR_out.T_idx] = CDB_PR_out.T_value;
    end
  end

  always_comb begin
    // Execution
    for (int i=0; i<`NUM_FU; i++) begin
      PR_FU_out.T1_value[i] = pr[RS_PR_out.FU_T_idx[i].T1_idx];
      PR_FU_out.T2_value[i] = pr[RS_PR_out.FU_T_idx[i].T2_idx];
    end // for
  end // always_comb

  always_ff @(posedge clock) begin
    if (reset) begin
      pr <= `SD {(`NUM_PR*64){1'b0}};
    end else if (en) begin
      pr <= `SD next_pr;
    end
  end // always_ff
endmodule
