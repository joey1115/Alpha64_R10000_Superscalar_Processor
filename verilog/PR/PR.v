/***********************************************
 * PR/FL procedure:
 * 
 * ----- Retire -----
 * 1. free the tag retired from ROB
 * input: r from complete stage, T_old from ROB
 * 
 * --- Complete ---
 * 1. X stage result write back to PR
 * input: X_C_valid, X_C_T, X_C_result from X/C reg
 * 
 * ---- Excution ----
 * 1. send reg values to FU
 * input: S_X_T1, S_X_T2
 * output: T1_value, T2_value (X_C_result can be interally
 * forward to T1 or T2)
 * 
 * ---- Dispatch ---
 * 1. struct hazard when full
 *   input: inst_dispatch from dispatch control
 *   output: struct_hazard to dispatch control
 * 2. send tag to ROB, RS and MapTable
 *   output: T to ROB, RS, and MapTable
 * 
 ************************************************/

module PR (
  input  en, clock, reset,
  input  PR_PACKET_IN  pr_packet_in,
  output PR_PACKET_OUT pr_packet_out
);

  PR_entry_t [`NUM_PR-1:0] pr, next_pr;
//  PR_t pr, next_pr;

  always_comb begin
    next_pr = pr;
    pr_packet_out.struct_hazard = 1;
    pr_packet_out.T = 0;

    // Retire
    if (pr_packet_in.r) begin
      next_pr[pr_packet_in.T_old].free = PR_FREE;
    end
    // Complete
    if (pr_packet_in.X_C_valid) begin
      next_pr[pr_packet_in.X_C_T].value = pr_packet_in.X_C_result;
    end // if
    // Execution
    for (int i=0; i<`NUM_FU; i++) begin
      if (pr_packet_in.X_C_T == pr_packet_in.S_X_T1[i]) begin
        pr_packet_out.T1_value[i] = pr_packet_in.X_C_result;             // forwarding
      end else begin
        pr_packet_out.T1_value[i] = next_pr[pr_packet_in.S_X_T1[i]].value;
      end
      if (pr_packet_in.X_C_T == pr_packet_in.S_X_T2[i]) begin
        pr_packet_out.T2_value[i] = pr_packet_in.X_C_result;             // forwarding
      end else begin 
        pr_packet_out.T2_value[i] = next_pr[pr_packet_in.S_X_T2[i]].value;
      end
    end
    // Dispatch
    for (logic [$clog2(`NUM_PR):0] i=0; i<`NUM_PR; i++) begin
      if (pr[i].free == PR_FREE) begin
        pr_packet_out.struct_hazard = 1'b0;
        pr_packet_out.T = i;
        break;
      end // if
    end // for
  end

  always_ff @(posedge clock) begin
    if (reset) begin
      pr <= `SD {`NUM_PR{64'b0, PR_FREE}};
    end else if (en && pr_packet_in.inst_dispatch) begin
      pr <= `SD next_pr;
    end // if
  end // always

endmodule