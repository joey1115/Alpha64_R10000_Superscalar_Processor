/////////////////////////////////////////////////////////////////////////
//                                                                     //
//                                                                     //
//   Modulename :  testbench_ROB.v                                     //
//                                                                     //
//  Description :  Testbench module for ROB module;                    //
//                                                                     //
//                                                                     //
/////////////////////////////////////////////////////////////////////////

`timescale 1ns/100ps

`include "FU.vh"

module test_FU;
  logic clock, reset, CDB_valid;
  FU_IN_t    FU_in;
  FU_OUT_t FU_out;
  logic FU_valid, rollback_en;
  logic [(64*`NUM_MULT_STAGE)-1:0] cres;
  logic [($clog2(`NUM_PR)*`NUM_MULT_STAGE)-1:0] T_idx;
  logic last_done;
  logic [63:0] product_out, T1_value, T2_value;
  logic [4:0]                 last_dest_idx;
  logic [$clog2(`NUM_PR)-1:0] last_T_idx;
  logic [$clog2(`NUM_FL)-1:0] last_FL_idx;
  logic [$clog2(`NUM_ROB)-1:0] last_ROB_idx, ROB_rollback_idx, diff_ROB;
  logic [((`NUM_MULT_STAGE-1)*64)-1:0] internal_T1_values, internal_T2_values;
  logic [`NUM_MULT_STAGE-2:0]                        internal_valids;
  logic [`NUM_MULT_STAGE-2:0]                        internal_dones;
  logic [5*(`NUM_MULT_STAGE-1)-1:0]                  internal_dest_idx;
  logic [($clog2(`NUM_PR)*(`NUM_MULT_STAGE-1))-1:0]  internal_T_idx;
  logic [($clog2(`NUM_ROB)*(`NUM_MULT_STAGE-1))-1:0] internal_ROB_idx;
  logic [($clog2(`NUM_FL)*(`NUM_MULT_STAGE-1))-1:0]  internal_FL_idx;

  mult mult_0 (
    // Inputs
    .clock(clock),
    .reset(reset),
    .rollback_en(rollback_en),
    .ROB_rollback_idx(ROB_rollback_idx),
    .diff_ROB(diff_ROB),
    .FU_in(FU_in),
    .CDB_valid(CDB_valid),
    // Outputs
`ifndef SYNTH_TEST
    .last_done(last_done),
    .product_out(product_out),
    .last_dest_idx(last_dest_idx),
    .last_T_idx(last_T_idx),
    .last_ROB_idx(last_ROB_idx),
    .last_FL_idx(last_FL_idx),
    .T1_value(T1_value),
    .T2_value(T2_value),
    .internal_T1_values(internal_T1_values),
    .internal_T2_values(internal_T2_values),
    .internal_valids(internal_valids),
    .internal_dones(internal_dones),
    .internal_dest_idx(internal_dest_idx),
    .internal_T_idx(internal_T_idx),
    .internal_ROB_idx(internal_ROB_idx),
    .internal_FL_idx(internal_FL_idx),
`endif
    .FU_out(FU_out),
    .FU_valid(FU_valid)
  );
  always begin
    #5;
    clock=~clock;
  end

  task displays_results;
    $display("---------------------------------------MULT----------------------------------------------------\n");
    $display("|-------|---1--- |---2--- |---3-- -|---4--- |---5--- |---6--- |---7--- |---8--- |\n");
    $display("|-valid-|---%b--- |---%b--- |---%b--- |---%b--- |---%b--- |---%b--- |---%b--- |---%b--- |\n", FU_valid, internal_valids[0], internal_valids[1], internal_valids[2], internal_valids[3], internal_valids[4], internal_valids[5], internal_valids[6]);
    $display("|-ready-|---%b--- |---%b--- |---%b--- |---%b--- |---%b--- |---%b--- |---%b--- |---%b--- |\n", FU_in.ready, internal_dones[0], internal_dones[1], internal_dones[2], internal_dones[3], internal_dones[4], internal_dones[5], FU_out.done);
    $display("|-done--|---%b--- |---%b--- |---%b--- |---%b--- |---%b--- |---%b--- |---%b--- |---%b--- |\n", internal_dones[0], internal_dones[1], internal_dones[2], internal_dones[3], internal_dones[4], internal_dones[5], FU_out.done, last_done);
    $display("|--ROB--|---%h--- |---%h--- |---%h--- |---%h--- |---%h--- |---%h--- |---%h--- |---%h--- |\n", FU_in.ROB_idx, internal_ROB_idx[2:0], internal_ROB_idx[5:3], internal_ROB_idx[8:6], internal_ROB_idx[11:9], internal_ROB_idx[14:12], internal_ROB_idx[17:15], FU_out.ROB_idx);
    $display("|--T1---|%8x|%8x|%8x|%8x|%8x|%8x|%8x|%8x|\n", T1_value, internal_T1_values[63:0], internal_T1_values[127:64], internal_T1_values[191:128], internal_T1_values[255:192], internal_T1_values[319:256], internal_T1_values[383:320], internal_T1_values[447:384]);
    $display("|--T2---|%8x|%8x|%8x|%8x|%8x|%8x|%8x|%8x|\n", T2_value, internal_T2_values[63:0], internal_T2_values[127:64], internal_T2_values[191:128], internal_T2_values[255:192], internal_T2_values[319:256], internal_T2_values[383:320], internal_T2_values[447:384]);
    $display("|--re---|%8x|%8x|%8x|%8x|%8x|%8x|%8x|%8x|\n", T1_value*T2_value, internal_T1_values[63:0]*internal_T2_values[63:0], internal_T1_values[127:64]*internal_T2_values[127:64], internal_T1_values[191:128]*internal_T2_values[191:128], internal_T1_values[255:192]*internal_T2_values[255:192], internal_T1_values[319:256]*internal_T2_values[319:256], internal_T1_values[383:320]*internal_T2_values[383:320], internal_T1_values[447:384]*internal_T2_values[447:384]);
    $display("|--so---|%8x|\n", FU_out.result);
    $display("---------------------------------------END-----------------------------------------------------\n");
  endtask

  task displays_inputs;
    $display("--------------------------------------BEGIN----------------------------------------------------\n");
    $display("|-reset-|-ready-|---inst---|-func-|-------NPC--------|-ROB-|-FL-|-T--|-T1_value-|-T2_value-|-T1-|-T2-|-uncond-|-cond-|-CDB-|-ROLL_en-|-ROLL_idx-|-tail_idx-|");
    $display("|---%b---|---%b---|-%8h-|--%2h--|-%16h-|--%1h--|-%2h-|-%2h-|-%8d-|-%8d-|-%h--|-%h--|---%b----|---%b--|-%2h--|----%b----|----%h-----|----%h-----|",
      reset,
      FU_in.ready,
      FU_in.inst,
      FU_in.func,
      FU_in.NPC,
      FU_in.ROB_idx,
      FU_in.FL_idx,
      FU_in.T_idx,
      FU_in.T1_value,
      FU_in.T2_value,
      FU_in.opa_select,
      FU_in.opb_select,
      FU_in.uncond_branch,
      FU_in.cond_branch,
      CDB_valid,
      rollback_en,
      ROB_rollback_idx,
      FU_valid
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
    ALU_OPA_SELECT                        opa_select,
    ALU_OPB_SELECT                        opb_select,
    logic                                 uncond_branch,
    logic                                 cond_branch,
    logic                                 CDB_valid_in,
    logic                                 rollback_en_in,
    logic          [$clog2(`NUM_ROB)-1:0] ROB_rollback_idx_in,
    logic          [$clog2(`NUM_ROB)-1:0] ROB_tail_idx_in
  );
    begin
      displays_results();
      reset = reset_in;
      FU_in.ready = ready;
      FU_in.inst = inst;
      FU_in.func = func;
      FU_in.NPC = NPC;
      FU_in.ROB_idx = ROB_idx;
      FU_in.T_idx = T_idx;
      FU_in.T1_value = T1_value;
      FU_in.T2_value = T2_value;
      FU_in.opa_select = opa_select;
      FU_in.opb_select = opb_select;
      FU_in.uncond_branch = uncond_branch;
      FU_in.cond_branch = cond_branch;
      FU_in.dest_idx = 7;
      FU_in.FL_idx = FL_idx;
      CDB_valid = CDB_valid_in;
      rollback_en = rollback_en_in;
      ROB_rollback_idx = ROB_rollback_idx_in;
      diff_ROB = ROB_tail_idx_in - ROB_rollback_idx_in;
      displays_inputs();
      @(negedge clock);
    end
  endtask

  initial begin
    clock=0;
    //   reset,  ready,       inst,     func, NPC, ROB, FL,    T_idx, T1, T2,       opa_select,       opb_select, uncond,   cond, CDB, ROLL_en, ROLL_idx, tail
    setinput(1, `FALSE, `NOOP_INST, ALU_ADDQ,   0,   0,  0, `ZERO_PR,  0,  0, ALU_OPA_IS_REGA, ALU_OPB_IS_REGB, `FALSE, `FALSE,   1,  `FALSE,        0,    0);
    @(negedge clock);
    //   reset,  ready,       inst,     func, NPC, ROB, FL,    T_idx, T1, T2,       opa_select,       opb_select, uncond,   cond, CDB, ROLL_en, ROLL_idx, tail
    setinput(0,  `TRUE, `NOOP_INST, ALU_ADDQ,   0,   1,  0, `ZERO_PR,  64'h27bb2ee687b0b0fd,  64'h3dd9773448d5d725, ALU_OPA_IS_REGA, ALU_OPB_IS_REGB, `FALSE, `FALSE,   1,  `FALSE,        0,    0);
    //   reset,  ready,       inst,     func, NPC, ROB, FL,    T_idx, T1, T2,       opa_select,       opb_select, uncond,   cond, CDB, ROLL_en, ROLL_idx, tail
    setinput(0,  `TRUE, `NOOP_INST, ALU_ADDQ,   0,   1,  0, `ZERO_PR,  64'h12341234,  64'h98769876, ALU_OPA_IS_REGA, ALU_OPB_IS_REGB, `FALSE, `FALSE,   1,  `FALSE,        0,    0);
    //   reset,  ready,       inst,     func, NPC, ROB, FL,    T_idx, T1, T2,       opa_select,       opb_select, uncond,   cond, CDB, ROLL_en, ROLL_idx, tail
    setinput(0,  `TRUE, `NOOP_INST, ALU_ADDQ,   0,   1,  0, `ZERO_PR,  64'hffffffff,  64'h98769876, ALU_OPA_IS_REGA, ALU_OPB_IS_REGB, `FALSE, `FALSE,   1,  `FALSE,        0,    0);
    //   reset,  ready,       inst,     func, NPC, ROB, FL,    T_idx, T1, T2,       opa_select,       opb_select, uncond,   cond, CDB, ROLL_en, ROLL_idx, tail
    setinput(0,  `TRUE, `NOOP_INST, ALU_ADDQ,   0,   3,  0, `ZERO_PR, 64,  2, ALU_OPA_IS_REGA, ALU_OPB_IS_REGB, `FALSE, `FALSE,   1,  `FALSE,        0,    0);
    //   reset,  ready,       inst,     func, NPC, ROB, FL,    T_idx, T1, T2,       opa_select,       opb_select, uncond,   cond, CDB, ROLL_en, ROLL_idx, tail
    setinput(0,  `TRUE, `NOOP_INST, ALU_ADDQ,   0,   2,  0, `ZERO_PR,  3,  7, ALU_OPA_IS_REGA, ALU_OPB_IS_REGB, `FALSE, `FALSE,   1,  `FALSE,        0,    0);
    //   reset,  ready,       inst,     func, NPC, ROB, FL,    T_idx, T1, T2,       opa_select,       opb_select, uncond,   cond, CDB, ROLL_en, ROLL_idx, tail
    setinput(0,  `TRUE, `NOOP_INST, ALU_ADDQ,   0,   4,  0, `ZERO_PR,  5, 66, ALU_OPA_IS_REGA, ALU_OPB_IS_REGB, `FALSE, `FALSE,   1,  `FALSE,        0,    0);
    //   reset,  ready,       inst,     func, NPC, ROB, FL,    T_idx, T1, T2,       opa_select,       opb_select, uncond,   cond, CDB, ROLL_en, ROLL_idx, tail
    setinput(0,  `TRUE, `NOOP_INST, ALU_ADDQ,   0,   5,  0, `ZERO_PR, 12, 14, ALU_OPA_IS_REGA, ALU_OPB_IS_REGB, `FALSE, `FALSE,   1,  `FALSE,        0,    0);
    //   reset,  ready,       inst,     func, NPC, ROB, FL,    T_idx, T1, T2,       opa_select,       opb_select, uncond,   cond, CDB, ROLL_en, ROLL_idx, tail
    setinput(0,  `TRUE, `NOOP_INST, ALU_ADDQ,   0,   6,  0, `ZERO_PR, 57, 89, ALU_OPA_IS_REGA, ALU_OPB_IS_REGB, `FALSE, `FALSE,   1,  `FALSE,        0,    0);
    //   reset,  ready,       inst,     func, NPC, ROB, FL,    T_idx, T1, T2,       opa_select,       opb_select, uncond,   cond, CDB, ROLL_en, ROLL_idx, tail
    setinput(0,  `TRUE, `NOOP_INST, ALU_ADDQ,   0,   7,  0, `ZERO_PR,  2, 33, ALU_OPA_IS_REGA, ALU_OPB_IS_REGB, `FALSE, `FALSE,   1,  `FALSE,        0,    0);
    //   reset,  ready,       inst,     func, NPC, ROB, FL,    T_idx, T1, T2,       opa_select,       opb_select, uncond,   cond, CDB, ROLL_en, ROLL_idx, tail
    setinput(0,  `TRUE, `NOOP_INST, ALU_ADDQ,   0,   8,  0, `ZERO_PR, 24, 75, ALU_OPA_IS_REGA, ALU_OPB_IS_REGB, `FALSE, `FALSE,   1,  `FALSE,        0,    0);
    //   reset,  ready,       inst,     func, NPC, ROB, FL,    T_idx, T1, T2,       opa_select,       opb_select, uncond,   cond, CDB, ROLL_en, ROLL_idx, tail
    setinput(0, `FALSE, `NOOP_INST, ALU_ADDQ,   0,   0,  0, `ZERO_PR,  0,  0, ALU_OPA_IS_REGA, ALU_OPB_IS_REGB, `FALSE, `FALSE,   1,  `FALSE,        0,    0);
    //   reset,  ready,       inst,     func, NPC, ROB, FL,    T_idx, T1, T2,       opa_select,       opb_select, uncond,   cond, CDB, ROLL_en, ROLL_idx, tail
    setinput(0, `FALSE, `NOOP_INST, ALU_ADDQ,   0,   0,  0, `ZERO_PR,  0,  0, ALU_OPA_IS_REGA, ALU_OPB_IS_REGB, `FALSE, `FALSE,   1,  `FALSE,        5,    2);
    //   reset,  ready,       inst,     func, NPC, ROB, FL,    T_idx, T1, T2,       opa_select,       opb_select, uncond,   cond, CDB, ROLL_en, ROLL_idx, tail
    setinput(0, `FALSE, `NOOP_INST, ALU_ADDQ,   0,   0,  0, `ZERO_PR,  0,  0, ALU_OPA_IS_REGA, ALU_OPB_IS_REGB, `FALSE, `FALSE,   1,  `FALSE,        0,    0);
    //   reset,  ready,       inst,     func, NPC, ROB, FL,    T_idx, T1, T2,       opa_select,       opb_select, uncond,   cond, CDB, ROLL_en, ROLL_idx, tail
    setinput(0, `FALSE, `NOOP_INST, ALU_ADDQ,   0,   0,  0, `ZERO_PR,  0,  0, ALU_OPA_IS_REGA, ALU_OPB_IS_REGB, `FALSE, `FALSE,   1,  `FALSE,        0,    0);
    //   reset,  ready,       inst,     func, NPC, ROB, FL,    T_idx, T1, T2,       opa_select,       opb_select, uncond,   cond, CDB, ROLL_en, ROLL_idx, tail
    setinput(0, `FALSE, `NOOP_INST, ALU_ADDQ,   0,   0,  0, `ZERO_PR,  0,  0, ALU_OPA_IS_REGA, ALU_OPB_IS_REGB, `FALSE, `FALSE,   1,  `FALSE,        0,    0);
    //   reset,  ready,       inst,     func, NPC, ROB, FL,    T_idx, T1, T2,       opa_select,       opb_select, uncond,   cond, CDB, ROLL_en, ROLL_idx, tail
    setinput(0, `FALSE, `NOOP_INST, ALU_ADDQ,   0,   0,  0, `ZERO_PR,  0,  0, ALU_OPA_IS_REGA, ALU_OPB_IS_REGB, `FALSE, `FALSE,   1,  `FALSE,        0,    0);
    //   reset,  ready,       inst,     func, NPC, ROB, FL,    T_idx, T1, T2,       opa_select,       opb_select, uncond,   cond, CDB, ROLL_en, ROLL_idx, tail
    setinput(0, `FALSE, `NOOP_INST, ALU_ADDQ,   0,   0,  0, `ZERO_PR,  0,  0, ALU_OPA_IS_REGA, ALU_OPB_IS_REGB, `FALSE, `FALSE,   1,  `FALSE,        0,    0);
    //   reset,  ready,       inst,     func, NPC, ROB, FL,    T_idx, T1, T2,       opa_select,       opb_select, uncond,   cond, CDB, ROLL_en, ROLL_idx, tail
    setinput(0, `FALSE, `NOOP_INST, ALU_ADDQ,   0,   0,  0, `ZERO_PR,  0,  0, ALU_OPA_IS_REGA, ALU_OPB_IS_REGB, `FALSE, `FALSE,   1,  `FALSE,        0,    0);
    //   reset,  ready,       inst,     func, NPC, ROB, FL,    T_idx, T1, T2,       opa_select,       opb_select, uncond,   cond, CDB, ROLL_en, ROLL_idx, tail
    setinput(0, `FALSE, `NOOP_INST, ALU_ADDQ,   0,   0,  0, `ZERO_PR,  0,  0, ALU_OPA_IS_REGA, ALU_OPB_IS_REGB, `FALSE, `FALSE,   1,  `FALSE,        0,    0);
    //   reset,  ready,       inst,     func, NPC, ROB, FL,    T_idx, T1, T2,       opa_select,       opb_select, uncond,   cond, CDB, ROLL_en, ROLL_idx, tail
    setinput(0, `FALSE, `NOOP_INST, ALU_ADDQ,   0,   0,  0, `ZERO_PR,  0,  0, ALU_OPA_IS_REGA, ALU_OPB_IS_REGB, `FALSE, `FALSE,   1,  `FALSE,        0,    0);
    //   reset,  ready,       inst,     func, NPC, ROB, FL,    T_idx, T1, T2,       opa_select,       opb_select, uncond,   cond, CDB, ROLL_en, ROLL_idx, tail
    setinput(0, `FALSE, `NOOP_INST, ALU_ADDQ,   0,   0,  0, `ZERO_PR,  0,  0, ALU_OPA_IS_REGA, ALU_OPB_IS_REGB, `FALSE, `FALSE,   1,  `FALSE,        0,    0);
    //   reset,  ready,       inst,     func, NPC, ROB, FL,    T_idx, T1, T2,       opa_select,       opb_select, uncond,   cond, CDB, ROLL_en, ROLL_idx, tail
    setinput(0, `FALSE, `NOOP_INST, ALU_ADDQ,   0,   0,  0, `ZERO_PR,  0,  0, ALU_OPA_IS_REGA, ALU_OPB_IS_REGB, `FALSE, `FALSE,   1,  `FALSE,        0,    0);
    //   reset,  ready,       inst,     func, NPC, ROB, FL,    T_idx, T1, T2,       opa_select,       opb_select, uncond,   cond, CDB, ROLL_en, ROLL_idx, tail
    setinput(0, `FALSE, `NOOP_INST, ALU_ADDQ,   0,   0,  0, `ZERO_PR,  0,  0, ALU_OPA_IS_REGA, ALU_OPB_IS_REGB, `FALSE, `FALSE,   1,  `FALSE,        0,    0);
    //   reset,  ready,       inst,     func, NPC, ROB, FL,    T_idx, T1, T2,       opa_select,       opb_select, uncond,   cond, CDB, ROLL_en, ROLL_idx, tail
    setinput(0, `FALSE, `NOOP_INST, ALU_ADDQ,   0,   0,  0, `ZERO_PR,  0,  0, ALU_OPA_IS_REGA, ALU_OPB_IS_REGB, `FALSE, `FALSE,   1,  `FALSE,        0,    0);
    //   reset,  ready,       inst,     func, NPC, ROB, FL,    T_idx, T1, T2,       opa_select,       opb_select, uncond,   cond, CDB, ROLL_en, ROLL_idx, tail
    setinput(0, `FALSE, `NOOP_INST, ALU_ADDQ,   0,   0,  0, `ZERO_PR,  0,  0, ALU_OPA_IS_REGA, ALU_OPB_IS_REGB, `FALSE, `FALSE,   1,  `FALSE,        0,    0);
    //   reset,  ready,       inst,     func, NPC, ROB, FL,    T_idx, T1, T2,       opa_select,       opb_select, uncond,   cond, CDB, ROLL_en, ROLL_idx, tail
    setinput(0, `FALSE, `NOOP_INST, ALU_ADDQ,   0,   0,  0, `ZERO_PR,  0,  0, ALU_OPA_IS_REGA, ALU_OPB_IS_REGB, `FALSE, `FALSE,   1,  `FALSE,        0,    0);
    $finish;
  end
endmodule  // module test_RS

