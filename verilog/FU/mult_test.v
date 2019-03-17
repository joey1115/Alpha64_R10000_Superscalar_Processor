`timescale 1ns/100ps

`include "FU.vh"

module testbench();

  logic clock, reset, CDB_valid;
  FU_PACKET_IN_t    fu_packet_in;
  FU_RESULT_ENTRY_t fu_packet_out;
  logic [`NUM_FU-1:0] fu_valid;
  logic [(64*`NUM_MULT_STAGE)-1:0] cres;
  logic [($clog2(`NUM_PR)*`NUM_MULT_STAGE)-1:0] T_idx;
  logic last_done;
  logic [63:0] product_out;
  logic [$clog2(`NUM_PR)-1:0] last_T_idx;

  mult m0(  .clock(clock),
            .reset(reset),
            .fu_packet(fu_packet_in),
            .CDB_valid(CDB_valid),
            .fu_packet_out(fu_packet_out),
            .fu_valid(fu_valid),
            .last_done(last_done),
            .product_out(product_out),
            .last_T_idx(last_T_idx),
            .last_T_idx(last_ROB_idx),
            .T1_value(T1_value),
            .T2_value(T2_value),
            .internal_T1_values(internal_T1_values),
            .internal_T2_values(internal_T2_values),
            .internal_valids(internal_valids),
            .internal_dones(internal_dones),
            .internal_T_idx(internal_T_idx),
            .internal_ROB_idx(internal_ROB_idx));

  always begin
    #5;
    clock=~clock;
  end

  task displays_results;
    $display("---------------------------------------MULT----------------------------------------------------\n");
    $display("|-------|---1---|---2---|---3---|---4---|---5---|---6---|---7---|---8---|\n");
    $display("|-valid-|--%b---|--%b---|--%b---|--%b---|--%b---|--%b---|--%b---|--%b---|\n", fu_valid, internal_valids[0], internal_valids[1], internal_valids[2], internal_valids[3], internal_valids[4], internal_valids[5], internal_valids[6]);
    $display("|-done--|--%b---|--%b---|--%b---|--%b---|--%b---|--%b---|--%b---|--%b---|\n", internal_dones[0], internal_dones[1], internal_dones[2], internal_dones[3], internal_dones[4], internal_dones[5], last_done, fu_packet_out.done);
    $display("---------------------------------------END-----------------------------------------------------\n");
  endtask

  task setinput(
    logic                                 reset_in,
    logic                                 ready,    // If an entry is ready
    INST_t                                inst,
    ALU_FUNC                              func,
    logic          [63:0]                 NPC,
    logic          [$clog2(`NUM_ROB)-1:0] ROB_idx,
    logic          [$clog2(`NUM_FL)-1:0]  FL_idx,
    logic          [$clog2(`NUM_PR)-1:0]  T_idx,    // Dest idx
    logic          [$clog2(`NUM_PR)-1:0]  T1_value, // T1 idx
    logic          [$clog2(`NUM_PR)-1:0]  T2_value, // T2 idx
    ALU_OPA_SELECT                        T1_select,
    ALU_OPB_SELECT                        T2_select,
    logic                                 uncond_branch,
    logic                                 cond_branch,
    logic          [`NUM_FU-1:0]          CDB_valid
  );
    begin
      displays_results();
      reset = reset_in;
      fu_packet_in.ready = ready;
      fu_packet_in.inst = inst;
      fu_packet_in.func = func;
      fu_packet_in.NPC = NPC;
      fu_packet_in.ROB_idx = ROB_idx;
      fu_packet_in.FL_idx = FL_idx;
      fu_packet_in.T_idx = T_idx;
      fu_packet_in.T1_value = T1_value;
      fu_packet_in.T2_value = T2_value;
      fu_packet_in.T1_select = T1_select;
      fu_packet_in.T2_select = T2_select;
      fu_packet_in.uncond_branch = uncond_branch;
      fu_packet_in.cond_branch = cond_branch;
      displays_inputs();
      @(negedge clock);
    end
  endtask

  initial begin
    clock=0;
    //   reset,  ready,       inst,     func, NPC, ROB, FL,    T_idx, T1, T2,       T1_select,       T2_select, uncond,   cond, CDB
    setinput(0, `FALSE, `NOOP_INST, ALU_ADDQ,   0,   0,  0, `ZERO_PR,  0,  0, ALU_OPA_IS_REGA, ALU_OPB_IS_REGB, `FALSE, `FALSE,   0);
    @(negedge clock);
    //   reset,  ready,       inst,     func, NPC, ROB, FL,    T_idx, T1, T2,       T1_select,       T2_select, uncond,   cond, CDB
    setinput(0, `FALSE, `NOOP_INST, ALU_ADDQ,   0,   0,  0, `ZERO_PR,  0,  0, ALU_OPA_IS_REGA, ALU_OPB_IS_REGB, `FALSE, `FALSE,   0);
    @(negedge clock);
    //   reset,  ready,       inst,     func, NPC, ROB, FL,    T_idx, T1, T2,       T1_select,       T2_select, uncond,   cond, CDB
    setinput(0, `FALSE, `NOOP_INST, ALU_ADDQ,   0,   0,  0, `ZERO_PR,  0,  0, ALU_OPA_IS_REGA, ALU_OPB_IS_REGB, `FALSE, `FALSE,   0);
    @(negedge clock);
    //   reset,  ready,       inst,     func, NPC, ROB, FL,    T_idx, T1, T2,       T1_select,       T2_select, uncond,   cond, CDB
    setinput(0, `FALSE, `NOOP_INST, ALU_ADDQ,   0,   0,  0, `ZERO_PR,  0,  0, ALU_OPA_IS_REGA, ALU_OPB_IS_REGB, `FALSE, `FALSE,   0);
    @(negedge clock);
    //   reset,  ready,       inst,     func, NPC, ROB, FL,    T_idx, T1, T2,       T1_select,       T2_select, uncond,   cond, CDB
    setinput(0, `FALSE, `NOOP_INST, ALU_ADDQ,   0,   0,  0, `ZERO_PR,  0,  0, ALU_OPA_IS_REGA, ALU_OPB_IS_REGB, `FALSE, `FALSE,   0);
    @(negedge clock);
    //   reset,  ready,       inst,     func, NPC, ROB, FL,    T_idx, T1, T2,       T1_select,       T2_select, uncond,   cond, CDB
    setinput(0, `FALSE, `NOOP_INST, ALU_ADDQ,   0,   0,  0, `ZERO_PR,  0,  0, ALU_OPA_IS_REGA, ALU_OPB_IS_REGB, `FALSE, `FALSE,   0);
    @(negedge clock);
    //   reset,  ready,       inst,     func, NPC, ROB, FL,    T_idx, T1, T2,       T1_select,       T2_select, uncond,   cond, CDB
    setinput(0, `FALSE, `NOOP_INST, ALU_ADDQ,   0,   0,  0, `ZERO_PR,  0,  0, ALU_OPA_IS_REGA, ALU_OPB_IS_REGB, `FALSE, `FALSE,   0);
    @(negedge clock);
    //   reset,  ready,       inst,     func, NPC, ROB, FL,    T_idx, T1, T2,       T1_select,       T2_select, uncond,   cond, CDB
    setinput(0, `FALSE, `NOOP_INST, ALU_ADDQ,   0,   0,  0, `ZERO_PR,  0,  0, ALU_OPA_IS_REGA, ALU_OPB_IS_REGB, `FALSE, `FALSE,   0);
    @(negedge clock);
    //   reset,  ready,       inst,     func, NPC, ROB, FL,    T_idx, T1, T2,       T1_select,       T2_select, uncond,   cond, CDB
    setinput(0, `FALSE, `NOOP_INST, ALU_ADDQ,   0,   0,  0, `ZERO_PR,  0,  0, ALU_OPA_IS_REGA, ALU_OPB_IS_REGB, `FALSE, `FALSE,   0);
    @(negedge clock);
    //   reset,  ready,       inst,     func, NPC, ROB, FL,    T_idx, T1, T2,       T1_select,       T2_select, uncond,   cond, CDB
    setinput(0, `FALSE, `NOOP_INST, ALU_ADDQ,   0,   0,  0, `ZERO_PR,  0,  0, ALU_OPA_IS_REGA, ALU_OPB_IS_REGB, `FALSE, `FALSE,   0);
    @(negedge clock);
    //   reset,  ready,       inst,     func, NPC, ROB, FL,    T_idx, T1, T2,       T1_select,       T2_select, uncond,   cond, CDB
    setinput(0, `FALSE, `NOOP_INST, ALU_ADDQ,   0,   0,  0, `ZERO_PR,  0,  0, ALU_OPA_IS_REGA, ALU_OPB_IS_REGB, `FALSE, `FALSE,   0);
    @(negedge clock);
    //   reset,  ready,       inst,     func, NPC, ROB, FL,    T_idx, T1, T2,       T1_select,       T2_select, uncond,   cond, CDB
    setinput(0, `FALSE, `NOOP_INST, ALU_ADDQ,   0,   0,  0, `ZERO_PR,  0,  0, ALU_OPA_IS_REGA, ALU_OPB_IS_REGB, `FALSE, `FALSE,   0);
    @(negedge clock);
    //   reset,  ready,       inst,     func, NPC, ROB, FL,    T_idx, T1, T2,       T1_select,       T2_select, uncond,   cond, CDB
    setinput(0, `FALSE, `NOOP_INST, ALU_ADDQ,   0,   0,  0, `ZERO_PR,  0,  0, ALU_OPA_IS_REGA, ALU_OPB_IS_REGB, `FALSE, `FALSE,   0);
    @(negedge clock);
    fu_packet_in.ready=0;
    // full_hazard = 1;
    // quit = 0;
    // quit <= #10000 1;
    // while(~quit) begin
    //   fu_packet_in.ready=1;
    //   fu_packet_in.T1_value={$random,$random};
    //   fu_packet_in.T2_value={$random,$random};
    //   fu_packet_in.T_idx=fu_packet_in.T_idx + 1;
    //   @(negedge clock);
    //   fu_packet_in.ready=0;
    //   //displays_results();
    // end
    $finish;
  end

endmodule



  
  