`timescale 1ns/100ps

`include "FU.vh"

module testbench();

  logic clock, reset, CDB_valid;
  FU_PACKET_IN_t    fu_packet_in;
  FU_RESULT_ENTRY_t fu_packet_out;
  logic fu_valid, ROB_rollback_en;
  logic [(64*`NUM_MULT_STAGE)-1:0] cres;
  logic [($clog2(`NUM_PR)*`NUM_MULT_STAGE)-1:0] T_idx;
  logic last_done;
  logic [63:0] product_out, T1_value, T2_value;
  logic [$clog2(`NUM_PR)-1:0] last_T_idx;
  logic [$clog2(`NUM_ROB)-1:0] last_ROB_idx, ROB_rollback_idx, ROB_tail_idx;
  logic [((`NUM_MULT_STAGE-1)*64)-1:0] internal_T1_values, internal_T2_values;
  logic [`NUM_MULT_STAGE-2:0]                        internal_valids;
  logic [`NUM_MULT_STAGE-3:0]                        internal_dones;
  logic [($clog2(`NUM_PR)*(`NUM_MULT_STAGE-2))-1:0]  internal_T_idx;
  logic [($clog2(`NUM_ROB)*(`NUM_MULT_STAGE-2))-1:0] internal_ROB_idx;

  mult m0(  .clock(clock),
            .reset(reset),
            .fu_packet(fu_packet_in),
            .CDB_valid(CDB_valid),
            .fu_packet_out(fu_packet_out),
            .fu_valid(fu_valid),
            .ROB_rollback_en(ROB_rollback_en),
            .ROB_rollback_idx(ROB_rollback_idx),
            .last_done(last_done),
            .product_out(product_out),
            .last_T_idx(last_T_idx),
            .last_ROB_idx(last_ROB_idx),
            .ROB_tail_idx(ROB_tail_idx),
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
    $display("|-valid-|---%b---|---%b---|---%b---|---%b---|---%b---|---%b---|---%b---|---%b---|\n", fu_valid, internal_valids[0], internal_valids[1], internal_valids[2], internal_valids[3], internal_valids[4], internal_valids[5], internal_valids[6]);
    $display("|-ready-|---%b---|---%b---|---%b---|---%b---|---%b---|---%b---|---%b---|---%b---|\n", fu_packet_in.ready, internal_dones[0], internal_dones[1], internal_dones[2], internal_dones[3], internal_dones[4], internal_dones[5], fu_packet_out.done);
    $display("|-done--|---%b---|---%b---|---%b---|---%b---|---%b---|---%b---|---%b---|---%b---|\n", internal_dones[0], internal_dones[1], internal_dones[2], internal_dones[3], internal_dones[4], internal_dones[5], fu_packet_out.done, last_done);
    $display("|--ROB--|---%h---|---%h---|---%h---|---%h---|---%h---|---%h---|---%h---|---%h---|\n", internal_ROB_idx[2:0], internal_ROB_idx[5:3], internal_ROB_idx[8:6], internal_ROB_idx[11:9], internal_ROB_idx[14:12], internal_ROB_idx[17:15], fu_packet_out.ROB_idx, last_ROB_idx);
    $display("|--T1---|%7d|%7d|%7d|%7d|%7d|%7d|%7d|%7d|\n", T1_value, internal_T1_values[63:0], internal_T1_values[127:64], internal_T1_values[191:128], internal_T1_values[255:192], internal_T1_values[319:256], internal_T1_values[383:320], internal_T1_values[447:384]);
    $display("|--T2---|%7d|%7d|%7d|%7d|%7d|%7d|%7d|%7d|\n", T2_value, internal_T2_values[63:0], internal_T2_values[127:64], internal_T2_values[191:128], internal_T2_values[255:192], internal_T2_values[319:256], internal_T2_values[383:320], internal_T2_values[447:384]);
    $display("---------------------------------------END-----------------------------------------------------\n");
  endtask

  task displays_inputs;
    $display("--------------------------------------BEGIN----------------------------------------------------\n");
    $display("|-reset-|-ready-|---inst---|-func-|-------NPC--------|-ROB-|-FL-|-T--|-T1_value-|-T2_value-|-T1-|-T2-|-uncond-|-cond-|-CDB-|-ROLL_en-|-ROLL_idx-|-tail_idx-|");
    $display("|---%b---|---%b---|-%8h-|--%2h--|-%16h-|--%1h--|-%2h-|-%2h-|-%8d-|-%8d-|-%h--|-%h--|---%b----|---%b--|-%2h--|----%b----|----%h-----|----%h-----|",
      reset,
      fu_packet_in.ready,
      fu_packet_in.inst,
      fu_packet_in.func,
      fu_packet_in.NPC,
      fu_packet_in.ROB_idx,
      fu_packet_in.FL_idx,
      fu_packet_in.T_idx,
      fu_packet_in.T1_value,
      fu_packet_in.T2_value,
      fu_packet_in.T1_select,
      fu_packet_in.T2_select,
      fu_packet_in.uncond_branch,
      fu_packet_in.cond_branch,
      CDB_valid,
      ROB_rollback_en,
      ROB_rollback_idx,
      ROB_tail_idx
    );
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
    logic          [63:0]                 T1_value, // T1 idx
    logic          [63:0]                 T2_value, // T2 idx
    ALU_OPA_SELECT                        T1_select,
    ALU_OPB_SELECT                        T2_select,
    logic                                 uncond_branch,
    logic                                 cond_branch,
    logic                                 CDB_valid_in,
    logic                                 ROB_rollback_en_in,
    logic          [$clog2(`NUM_ROB)-1:0] ROB_rollback_idx_in,
    logic          [$clog2(`NUM_ROB)-1:0] ROB_tail_idx_in
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
      CDB_valid = CDB_valid_in;
      ROB_rollback_en = ROB_rollback_en_in;
      ROB_rollback_idx = ROB_rollback_idx_in;
      ROB_tail_idx = ROB_tail_idx_in;
      displays_inputs();
      @(negedge clock);
    end
  endtask

  initial begin
    clock=0;
    //   reset,  ready,       inst,     func, NPC, ROB, FL,    T_idx, T1, T2,       T1_select,       T2_select, uncond,   cond, CDB, ROLL_en, ROLL_idx, tail
    setinput(1, `FALSE, `NOOP_INST, ALU_ADDQ,   0,   0,  0, `ZERO_PR,  0,  0, ALU_OPA_IS_REGA, ALU_OPB_IS_REGB, `FALSE, `FALSE,   0,  `FALSE,        0,    0);
    @(negedge clock);
    //   reset,  ready,       inst,     func, NPC, ROB, FL,    T_idx, T1, T2,       T1_select,       T2_select, uncond,   cond, CDB, ROLL_en, ROLL_idx, tail
    setinput(0,  `TRUE, `NOOP_INST, ALU_ADDQ,   0,   1,  0, `ZERO_PR,  1,  2, ALU_OPA_IS_REGA, ALU_OPB_IS_REGB, `FALSE, `FALSE,   0,  `FALSE,        0,    0);
    //   reset,  ready,       inst,     func, NPC, ROB, FL,    T_idx, T1, T2,       T1_select,       T2_select, uncond,   cond, CDB, ROLL_en, ROLL_idx, tail
    setinput(0,  `TRUE, `NOOP_INST, ALU_ADDQ,   0,   3,  0, `ZERO_PR, 64,  2, ALU_OPA_IS_REGA, ALU_OPB_IS_REGB, `FALSE, `FALSE,   0,  `FALSE,        0,    0);
    //   reset,  ready,       inst,     func, NPC, ROB, FL,    T_idx, T1, T2,       T1_select,       T2_select, uncond,   cond, CDB, ROLL_en, ROLL_idx, tail
    setinput(0,  `TRUE, `NOOP_INST, ALU_ADDQ,   0,   2,  0, `ZERO_PR,  3,  7, ALU_OPA_IS_REGA, ALU_OPB_IS_REGB, `FALSE, `FALSE,   0,  `FALSE,        0,    0);
    //   reset,  ready,       inst,     func, NPC, ROB, FL,    T_idx, T1, T2,       T1_select,       T2_select, uncond,   cond, CDB, ROLL_en, ROLL_idx, tail
    setinput(0,  `TRUE, `NOOP_INST, ALU_ADDQ,   0,   4,  0, `ZERO_PR,  5, 66, ALU_OPA_IS_REGA, ALU_OPB_IS_REGB, `FALSE, `FALSE,   0,  `FALSE,        0,    0);
    //   reset,  ready,       inst,     func, NPC, ROB, FL,    T_idx, T1, T2,       T1_select,       T2_select, uncond,   cond, CDB, ROLL_en, ROLL_idx, tail
    setinput(0,  `TRUE, `NOOP_INST, ALU_ADDQ,   0,   5,  0, `ZERO_PR, 12, 14, ALU_OPA_IS_REGA, ALU_OPB_IS_REGB, `FALSE, `FALSE,   0,  `FALSE,        0,    0);
    //   reset,  ready,       inst,     func, NPC, ROB, FL,    T_idx, T1, T2,       T1_select,       T2_select, uncond,   cond, CDB, ROLL_en, ROLL_idx, tail
    setinput(0,  `TRUE, `NOOP_INST, ALU_ADDQ,   0,   6,  0, `ZERO_PR, 57, 89, ALU_OPA_IS_REGA, ALU_OPB_IS_REGB, `FALSE, `FALSE,   0,  `FALSE,        0,    0);
    //   reset,  ready,       inst,     func, NPC, ROB, FL,    T_idx, T1, T2,       T1_select,       T2_select, uncond,   cond, CDB, ROLL_en, ROLL_idx, tail
    setinput(0,  `TRUE, `NOOP_INST, ALU_ADDQ,   0,   7,  0, `ZERO_PR,  2, 33, ALU_OPA_IS_REGA, ALU_OPB_IS_REGB, `FALSE, `FALSE,   0,  `FALSE,        0,    0);
    //   reset,  ready,       inst,     func, NPC, ROB, FL,    T_idx, T1, T2,       T1_select,       T2_select, uncond,   cond, CDB, ROLL_en, ROLL_idx, tail
    setinput(0,  `TRUE, `NOOP_INST, ALU_ADDQ,   0,   8,  0, `ZERO_PR, 24, 75, ALU_OPA_IS_REGA, ALU_OPB_IS_REGB, `FALSE, `FALSE,   0,  `FALSE,        0,    0);
    //   reset,  ready,       inst,     func, NPC, ROB, FL,    T_idx, T1, T2,       T1_select,       T2_select, uncond,   cond, CDB, ROLL_en, ROLL_idx, tail
    setinput(0, `FALSE, `NOOP_INST, ALU_ADDQ,   0,   0,  0, `ZERO_PR,  0,  0, ALU_OPA_IS_REGA, ALU_OPB_IS_REGB, `FALSE, `FALSE,   0,  `FALSE,        0,    0);
    //   reset,  ready,       inst,     func, NPC, ROB, FL,    T_idx, T1, T2,       T1_select,       T2_select, uncond,   cond, CDB, ROLL_en, ROLL_idx, tail
    setinput(0, `FALSE, `NOOP_INST, ALU_ADDQ,   0,   0,  0, `ZERO_PR,  0,  0, ALU_OPA_IS_REGA, ALU_OPB_IS_REGB, `FALSE, `FALSE,   0,   `TRUE,        5,    2);
    //   reset,  ready,       inst,     func, NPC, ROB, FL,    T_idx, T1, T2,       T1_select,       T2_select, uncond,   cond, CDB, ROLL_en, ROLL_idx, tail
    setinput(0, `FALSE, `NOOP_INST, ALU_ADDQ,   0,   0,  0, `ZERO_PR,  0,  0, ALU_OPA_IS_REGA, ALU_OPB_IS_REGB, `FALSE, `FALSE,   0,  `FALSE,        0,    0);
    //   reset,  ready,       inst,     func, NPC, ROB, FL,    T_idx, T1, T2,       T1_select,       T2_select, uncond,   cond, CDB, ROLL_en, ROLL_idx, tail
    setinput(0, `FALSE, `NOOP_INST, ALU_ADDQ,   0,   0,  0, `ZERO_PR,  0,  0, ALU_OPA_IS_REGA, ALU_OPB_IS_REGB, `FALSE, `FALSE,   0,  `FALSE,        0,    0);
    //   reset,  ready,       inst,     func, NPC, ROB, FL,    T_idx, T1, T2,       T1_select,       T2_select, uncond,   cond, CDB, ROLL_en, ROLL_idx, tail
    setinput(0, `FALSE, `NOOP_INST, ALU_ADDQ,   0,   0,  0, `ZERO_PR,  0,  0, ALU_OPA_IS_REGA, ALU_OPB_IS_REGB, `FALSE, `FALSE,   0,  `FALSE,        0,    0);
    //   reset,  ready,       inst,     func, NPC, ROB, FL,    T_idx, T1, T2,       T1_select,       T2_select, uncond,   cond, CDB, ROLL_en, ROLL_idx, tail
    setinput(0, `FALSE, `NOOP_INST, ALU_ADDQ,   0,   0,  0, `ZERO_PR,  0,  0, ALU_OPA_IS_REGA, ALU_OPB_IS_REGB, `FALSE, `FALSE,   0,  `FALSE,        0,    0);
    //   reset,  ready,       inst,     func, NPC, ROB, FL,    T_idx, T1, T2,       T1_select,       T2_select, uncond,   cond, CDB, ROLL_en, ROLL_idx, tail
    setinput(0, `FALSE, `NOOP_INST, ALU_ADDQ,   0,   0,  0, `ZERO_PR,  0,  0, ALU_OPA_IS_REGA, ALU_OPB_IS_REGB, `FALSE, `FALSE,   0,  `FALSE,        0,    0);
    //   reset,  ready,       inst,     func, NPC, ROB, FL,    T_idx, T1, T2,       T1_select,       T2_select, uncond,   cond, CDB, ROLL_en, ROLL_idx, tail
    setinput(0, `FALSE, `NOOP_INST, ALU_ADDQ,   0,   0,  0, `ZERO_PR,  0,  0, ALU_OPA_IS_REGA, ALU_OPB_IS_REGB, `FALSE, `FALSE,   0,  `FALSE,        0,    0);
    $finish;
  end

endmodule



  
  