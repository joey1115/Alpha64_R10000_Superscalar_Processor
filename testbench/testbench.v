/////////////////////////////////////////////////////////////////////////
//                                                                     //
//                                                                     //
//   Modulename :  testbench.v                                         //
//                                                                     //
//  Description :  Testbench module for the verisimple pipeline;       //
//                                                                     //
//                                                                     //
/////////////////////////////////////////////////////////////////////////

`timescale 1ns/100ps

// ******** WARNING !!! *********
// ******** WARNING !!! *********
// ******** WARNING !!! *********
// DANGEROUS FEATURE: HALT_ON_TIMEOUT should always be uncommented
// unless you know the pipeline will never reach the halt instruction and run forever
`define HALT_ON_TIMEOUT_CLOCK_COUNT //STOP ON CLOCK COUNT FOR CPI
`define HALT_ON_TIMEOUT_CYCLE_COUNT //STOP ON CYCLE COUNT (DURATION OF PROGRAM)

// `define HALT_ON_CYCLE
// After runing for TIMEOUT_CYCLES cycles, halt!
`define TIMEOUT_MAX_CYCLES 10000
`define TIMEOUT_MAX_CLOCK 10000


`define PRINT_DISPATCH_EN
// `define PRINT_FETCHBUFFER
// `define PRINT_ROB
// `define PRINT_RS
// `define PRINT_MAP_TABLE
// `define PRINT_FREELIST
// `define PRINT_CDB
// `define PRINT_ARCHMAP
// `define PRINT_REG
`define PRINT_MEMBUS
`define PRINT_SQ
`define PRINT_LQ
// `define PRINT_DCACHE_BANK
// `define PRINT_MSHR_ENTRY
`define PRINT_COUNT

`include "sys_defs.vh"
`include "verilog/ROB/ROB.vh"

extern void print_open();
extern void print_cycles();
// extern void print_stage(string div, int inst, int npc, int valid_inst);
extern void print_ROB_ht(int head, int tail);
extern void print_ROB_entry(int i, int valid, int T, int T_old, int dest_idx, int complete, int halt, int illegal, int NPC_hi, int NPC_lo, int wr_mem, int rd_mem);
extern void print_RS_head();
extern void print_RS_entry(string funcType, int busy, int inst, int func, int NPC_hi, int NPC_lo, int dest_idx, int ROB_idx, int FL_idx, int T_idx, int T1, int T1_ready, int T2, int T2_ready, int T1_select, int T2_select, int SQ_idx, int LQ_idx, int uncond_branch, int cond_branch, int wr_mem, int rd_mem, int target_hi, int target_lo);
extern void print_maptable_head();
extern void print_maptable_entry(int reg_idx, int T, int ready, int PR_data_hi, int PR_data_lo);
extern void print_CDB_head();
extern void print_CDB_entry(int taken, int T_idx, int ROB_idx, int dest_idx, int T_value_HI, int T_value_LO);
extern void print_archmap_head();
extern void print_archmap_entry(int reg_idx, int pr);
extern void print_dispatch_en(int dispatch_en, int ROB_valid, int RS_valid, int FL_valid, int rollback_en);
extern void print_freelist_head(int FL_head, int FL_tail);
extern void print_freelist_entry(int i, int freePR);
extern void print_fetchbuffer_head(int FB_head, int FB_tail);
extern void print_fetchbuffer_entry(int i, int valid, int NPC_hi, int NPC_lo, int inst);

extern void print_num(int i);
extern void print_enter();
extern void print_sq_head(int head, int tail);
extern void print_sq_entry(int idx, int valid, int addr_hi, int addr_lo, int value_hi, int value_lo);
extern void print_lq_head(int head, int tail);
extern void print_lq_entry(int idx, int valid, int addr_hi, int addr_lo, int ROB_idx, int FL_idx, int SQ_idx, int PC_hi, int PC_lo);
extern void print_MSHR_entry(int MSHR_DEPTH, int valid, int data_hi, int data_lo, int dirty, int addr_hi, int addr_lo, int inst_type, int proc2mem_command, int complete, int mem_tag, int state);
extern void print_Dcache_head();
extern void print_MSHR_head(int writeback_head, int head, int tail, int mem_bus);
extern void print_Dcache_bank(int data_hi, int data_lo, int tag_hi,int tag_lo, int dirty, int valid);
extern void print_reg(int wb_reg_wr_data_out_hi_1, int wb_reg_wr_data_out_lo_1,
                      int wb_reg_wr_data_out_hi_2, int wb_reg_wr_data_out_lo_2,
                      int wb_reg_wr_idx_out_1, int wb_reg_wr_idx_out_2,
                      int wb_reg_wr_en_out_1, int wb_reg_wr_en_out_2);
extern void print_membus(int proc2mem_command, int mem2proc_response,
                         int proc2mem_addr_hi, int proc2mem_addr_lo,
                         int proc2mem_data_hi, int proc2mem_data_lo);
extern void print_close();
extern void print_count(int count_hi, int count_lo);


module testbench;

  // Registers and wires used in the testbench
  logic        clock;
  logic        reset;
  logic [31:0] clock_count, next_clock_count;
  logic [31:0] instr_count, next_instr_count;
  int          wb_fileno;

  logic  [1:0] proc2mem_command;
  logic [63:0] proc2mem_addr;
  logic [63:0] proc2mem_data;
  logic  [3:0] mem2proc_response;
  logic [63:0] mem2proc_data;
  logic  [3:0] mem2proc_tag;

  logic  [3:0] pipeline_completed_insts;
  logic  [3:0] pipeline_error_status;
  logic [`NUM_SUPER-1:0] [4:0] pipeline_commit_wr_idx;
  logic [`NUM_SUPER-1:0][63:0] pipeline_commit_wr_data;
  logic [`NUM_SUPER-1:0]       pipeline_commit_wr_en;
  logic [`NUM_SUPER-1:0][63:0] pipeline_commit_NPC;


  logic state_count, next_state_count;
  logic stop_cycle;

  logic [64:0] clock_cycle;


  ROB_t pipeline_ROB;
  RS_ENTRY_t [`NUM_FU-1:0]  pipeline_RS;
  logic [31:0][$clog2(`NUM_PR)-1:0] pipeline_ARCHMAP;
  T_t [31:0] pipeline_MAPTABLE;
  CDB_entry_t [`NUM_FU-1:0] pipeline_CDB;
  logic [`NUM_SUPER-1:0] complete_en;
  CDB_PR_OUT_t CDB_PR_out;
  logic dispatch_en, ROB_valid, RS_valid, FL_valid, rollback_en;
  logic [`NUM_PR-1:0][63:0] pipeline_PR;
  logic [`NUM_FL-1:0][$clog2(`NUM_PR)-1:0] pipeline_FL;
  logic [$clog2(`NUM_FL)-1:0]              FL_head, FL_tail;
  INST_ENTRY_t [`NUM_FB-1:0]               pipeline_FB;
  logic [$clog2(`NUM_FB)-1:0]              FB_head, FB_tail;
  SQ_ENTRY_t     [`NUM_LSQ-1:0]            pipeline_SQ;
  logic          [$clog2(`NUM_LSQ)-1:0]    SQ_head, SQ_tail;
  LQ_ENTRY_t     [`NUM_LSQ-1:0]            pipeline_LQ;
  logic          [$clog2(`NUM_LSQ)-1:0]    LQ_head, LQ_tail;
  D_CACHE_LINE_t [`NUM_WAY-1:0][`NUM_IDX-1:0] Dcache_bank;
  MSHR_ENTRY_t   [`MSHR_DEPTH-1:0]            MSHR_queue;
  logic          [$clog2(`MSHR_DEPTH)-1:0]        MSHR_writeback_head;
  logic          [$clog2(`MSHR_DEPTH)-1:0]        MSHR_head;
  logic          [$clog2(`MSHR_DEPTH)-1:0]        MSHR_tail;
  logic          [63:0]                           count;
  

  // Instantiate the Pipeline
  `DUT(pipeline) pipeline_0 (// Inputs
    .clock             (clock),
    .reset             (reset),
    .mem2proc_response (mem2proc_response),
    .mem2proc_data     (mem2proc_data),
    .mem2proc_tag      (mem2proc_tag),
`ifdef DEBUG
    //needed to tell if inst is completed added to inst count
    .pipeline_ROB(pipeline_ROB),
    .pipeline_RS(pipeline_RS),
    .pipeline_ARCHMAP(pipeline_ARCHMAP),
    .pipeline_MAPTABLE(pipeline_MAPTABLE),
    .pipeline_CDB(pipeline_CDB),
    .pipeline_FB(pipeline_FB),
    .complete_en(complete_en),
    .CDB_PR_out(CDB_PR_out),
    .dispatch_en(dispatch_en),
    .ROB_valid(ROB_valid),
    .RS_valid(RS_valid),
    .FL_valid(FL_valid),
    .rollback_en(rollback_en),
    .pipeline_PR(pipeline_PR),
    .pipeline_FL(pipeline_FL),
    .FL_head(FL_head),
    .FL_tail(FL_tail),
    .FB_head(FB_head),
    .FB_tail(FB_tail),
    .pipeline_SQ(pipeline_SQ),
    .SQ_head(SQ_head),
    .SQ_tail(SQ_tail),
    .pipeline_LQ(pipeline_LQ),
    .LQ_head(LQ_head),
    .LQ_tail(LQ_tail),
    .Dcache_bank(Dcache_bank),
    .MSHR_queue(MSHR_queue),
    .MSHR_writeback_head(MSHR_writeback_head),
    .MSHR_head(MSHR_head),
    .MSHR_tail(MSHR_tail),
    .count(count),
`endif
    // Outputs
    .pipeline_commit_wr_idx(pipeline_commit_wr_idx),
    .pipeline_commit_wr_data(pipeline_commit_wr_data),
    .pipeline_commit_wr_en(pipeline_commit_wr_en),
    .pipeline_commit_NPC(pipeline_commit_NPC),
    .pipeline_completed_insts(pipeline_completed_insts),
    .pipeline_error_status(pipeline_error_status),
    .proc2mem_command  (proc2mem_command),
    .proc2mem_addr     (proc2mem_addr),
    .proc2mem_data     (proc2mem_data),
    .stop_cycle       (stop_cycle)
  );

  // Instantiate the Data Memory
  mem memory (
    // Inputs
    .clk               (clock),
    .proc2mem_command  (proc2mem_command),
    .proc2mem_addr     (proc2mem_addr),
    .proc2mem_data     (proc2mem_data),

    // Outputs
    .mem2proc_response (mem2proc_response),
    .mem2proc_data     (mem2proc_data),
    .mem2proc_tag      (mem2proc_tag)
  );

  // Generate System Clock
  always begin
    #(`VERILOG_CLOCK_PERIOD/2.0);
    clock = ~clock;
  end

  // Task to display # of elapsed clock edges
  task show_clk_count;
    real cpi;

    begin
      cpi = (clock_count + 1.0) / (instr_count-1);
      $display("@@  %0d cycles / %0d instrs = %f CPI\n@@",
      clock_count+1, (instr_count-1), cpi);
      $display("@@  %4.2f ns total time to execute\n@@\n",
      clock_count*`VIRTUAL_CLOCK_PERIOD);
    end

  endtask  // task show_clk_count

  // Show contents of a range of Unified Memory, in both hex and decimal
  task show_mem_with_decimal;
    input [31:0] start_addr;
    input [31:0] end_addr;
    int showing_data;
    begin
      $display("@@@");
      showing_data=0;
      for(int k=start_addr;k<=end_addr; k=k+1)
        if (memory.unified_memory[k] != 0)
        begin
          $display("@@@ mem[%5d] = %x : %0d", k*8,  memory.unified_memory[k],
                                memory.unified_memory[k]);
          showing_data=1;
        end
        else if(showing_data!=0)
        begin
          $display("@@@");
          showing_data=0;
        end
      $display("@@@");
    end
  endtask  // task show_mem_with_decimal

  initial begin
    `ifdef DUMP
      $vcdplusdeltacycleon;
      $vcdpluson();
      $vcdplusmemon(memory.unified_memory);
    `endif

    clock = 1'b0;
    reset = 1'b0;

    // Pulse the reset signal
    $display("@@\n@@\n@@  %t  Asserting System reset......", $realtime);
    reset = 1'b1;
    @(posedge clock);
    @(posedge clock);

    $readmemh("program.mem", memory.unified_memory);

    @(posedge clock);
    @(posedge clock);
    `SD;
    // This reset is at an odd time to avoid the pos & neg clock edges

    reset = 1'b0;
    $display("@@  %t  Deasserting System reset......\n@@\n@@", $realtime);

    wb_fileno = $fopen("writeback.out");

    //Open header AFTER throwing the reset otherwise the reset state is displayed
    print_open();
  end


  // Count the number of posedges and number of instructions completed
  // till simulation ends
  always @(posedge clock or posedge reset) begin
    if(reset) begin
      clock_count <= `SD 0;
      instr_count <= `SD 0;
      clock_cycle <= `SD 0;
    end else begin
      clock_count <= `SD next_clock_count;
      instr_count <= `SD next_instr_count;
      clock_cycle <= `SD clock_cycle + 1;
    end
  end

  always_comb begin
    next_state_count = (stop_cycle) ? 1 : state_count;
    next_clock_count = (next_state_count == 0) ? clock_count + 1 : clock_count;
    next_instr_count = (instr_count + pipeline_completed_insts);
  end

  always_ff @(posedge clock) begin
    if(reset)
      state_count <= `SD 0;
    else
      state_count <= `SD next_state_count;
  end


  always @(negedge clock) begin
    if(reset)
      $display(  "@@\n@@  %t : System STILL at reset, can't show anything\n@@",
            $realtime);
    else begin
      `SD;
      `SD;
      print_cycles();

      //print dispatch_en
`ifdef PRINT_DISPATCH_EN
      print_dispatch_en({{(32-1){1'b0}},dispatch_en}, {{(32-1){1'b0}},ROB_valid}, {{(32-1){1'b0}},RS_valid}, {{(32-1){1'b0}},FL_valid}, {{(32-1){1'b0}},rollback_en});
`endif

      //print fetch buffer
`ifdef PRINT_FETCHBUFFER
      print_fetchbuffer_head({{(32-$clog2(`NUM_FB)){1'b0}},FB_head}, {{(32-$clog2(`NUM_FB)){1'b0}},FB_tail});
      for(int i=0; i < `NUM_FB; i++) begin
        print_fetchbuffer_entry(i, {31'h0, pipeline_FB[i].valid}, pipeline_FB[i].NPC[63:32], pipeline_FB[i].NPC[31:0], pipeline_FB[i].inst);
      end
`endif

      // print ROB
`ifdef PRINT_ROB
      print_ROB_ht({{(32-$clog2(`NUM_ROB)){1'b0}},pipeline_ROB.head}, {{(32-$clog2(`NUM_ROB)){1'b0}},pipeline_ROB.tail});
      for(int i = 0; i < `NUM_ROB; i++) begin
        print_ROB_entry(i,{{(32-1){1'b0}},pipeline_ROB.entry[i].valid}, {{(32-$clog2(`NUM_PR)){1'b0}},pipeline_ROB.entry[i].T_idx}, {{(32-$clog2(`NUM_PR)){1'b0}},pipeline_ROB.entry[i].Told_idx},{{(32-5){1'b0}},pipeline_ROB.entry[i].dest_idx},{{(32-1){1'b0}},pipeline_ROB.entry[i].complete},{{(32-1){1'b0}},pipeline_ROB.entry[i].halt},{{(32-1){1'b0}},pipeline_ROB.entry[i].illegal}, pipeline_ROB.entry[i].NPC[63:32], pipeline_ROB.entry[i].NPC[31:0], {{(31){1'b0}},pipeline_ROB.entry[i].wr_mem}, {{(31){1'b0}},pipeline_ROB.entry[i].rd_mem});
      end
`endif

      //print RS
`ifdef PRINT_RS
      print_RS_head();
      for(int i = 0; i < `NUM_LD; i++) begin
        print_RS_entry("LD  ",
                      {{(32-1){1'b0}},pipeline_RS[i].busy},
                      pipeline_RS[i].inst.I,
                      {{(32-5){1'b0}},pipeline_RS[i].func},
                      pipeline_RS[i].NPC[63:32],
                      pipeline_RS[i].NPC[31:0],
                      {{(32-5){1'b0}},pipeline_RS[i].dest_idx},
                      {{(32-$clog2(`NUM_ROB)){1'b0}},pipeline_RS[i].ROB_idx},
                      {{(32-$clog2(`NUM_FL)){1'b0}},pipeline_RS[i].FL_idx},
                      {{(32-$clog2(`NUM_PR)){1'b0}},pipeline_RS[i].T_idx},
                      {{(32-$clog2(`NUM_PR)){1'b0}},pipeline_RS[i].T1.idx},
                      {{(32-1){1'b0}},pipeline_RS[i].T1.ready},
                      {{(32-$clog2(`NUM_PR)){1'b0}},pipeline_RS[i].T2.idx},
                      {{(32-1){1'b0}},pipeline_RS[i].T2.ready},
                      {{(32-2){1'b0}},pipeline_RS[i].opa_select},
                      {{(32-2){1'b0}},pipeline_RS[i].opb_select},
                      {{(32-$clog2(`NUM_LSQ)){1'b0}},pipeline_RS[i].SQ_idx},
                      {{(32-$clog2(`NUM_LSQ)){1'b0}},pipeline_RS[i].LQ_idx},
                      {{(32-1){1'b0}},pipeline_RS[i].uncond_branch},
                      {{(32-1){1'b0}},pipeline_RS[i].cond_branch},
                      {{(32-1){1'b0}},pipeline_RS[i].wr_mem},
                      {{(32-1){1'b0}},pipeline_RS[i].rd_mem},
                      pipeline_RS[i].target[63:32],
                      pipeline_RS[i].target[31:0]);
      end
      for(int i =`NUM_LD; i < (`NUM_LD + `NUM_ST); i++) begin
        print_RS_entry("ST  ",
                      {{(32-1){1'b0}},pipeline_RS[i].busy},
                      pipeline_RS[i].inst.I,
                      {{(32-5){1'b0}},pipeline_RS[i].func},
                      pipeline_RS[i].NPC[63:32],
                      pipeline_RS[i].NPC[31:0],
                      {{(32-5){1'b0}},pipeline_RS[i].dest_idx},
                      {{(32-$clog2(`NUM_ROB)){1'b0}},pipeline_RS[i].ROB_idx},
                      {{(32-$clog2(`NUM_FL)){1'b0}},pipeline_RS[i].FL_idx},
                      {{(32-$clog2(`NUM_PR)){1'b0}},pipeline_RS[i].T_idx},
                      {{(32-$clog2(`NUM_PR)){1'b0}},pipeline_RS[i].T1.idx},
                      {{(32-1){1'b0}},pipeline_RS[i].T1.ready},
                      {{(32-$clog2(`NUM_PR)){1'b0}},pipeline_RS[i].T2.idx},
                      {{(32-1){1'b0}},pipeline_RS[i].T2.ready},
                      {{(32-2){1'b0}},pipeline_RS[i].opa_select},
                      {{(32-2){1'b0}},pipeline_RS[i].opb_select},
                      {{(32-$clog2(`NUM_LSQ)){1'b0}},pipeline_RS[i].SQ_idx},
                      {{(32-$clog2(`NUM_LSQ)){1'b0}},pipeline_RS[i].LQ_idx},
                      {{(32-1){1'b0}},pipeline_RS[i].uncond_branch},
                      {{(32-1){1'b0}},pipeline_RS[i].cond_branch},
                      {{(32-1){1'b0}},pipeline_RS[i].wr_mem},
                      {{(32-1){1'b0}},pipeline_RS[i].rd_mem},
                      pipeline_RS[i].target[63:32],
                      pipeline_RS[i].target[31:0]);
      end
      for(int i = ( `NUM_LD + `NUM_ST); i < ( `NUM_LD + `NUM_ST + `NUM_BR); i++) begin
        print_RS_entry("BR  ",
                      {{(32-1){1'b0}},pipeline_RS[i].busy},
                      pipeline_RS[i].inst,
                      {{(32-5){1'b0}},pipeline_RS[i].func},
                      pipeline_RS[i].NPC[63:32],
                      pipeline_RS[i].NPC[31:0],
                      {{(32-5){1'b0}},pipeline_RS[i].dest_idx},
                      {{(32-$clog2(`NUM_ROB)){1'b0}},pipeline_RS[i].ROB_idx},
                      {{(32-$clog2(`NUM_FL)){1'b0}},pipeline_RS[i].FL_idx},
                      {{(32-$clog2(`NUM_PR)){1'b0}},pipeline_RS[i].T_idx},
                      {{(32-$clog2(`NUM_PR)){1'b0}},pipeline_RS[i].T1.idx},
                      {{(32-1){1'b0}},pipeline_RS[i].T1.ready},
                      {{(32-$clog2(`NUM_PR)){1'b0}},pipeline_RS[i].T2.idx},
                      {{(32-1){1'b0}},pipeline_RS[i].T2.ready},
                      {{(32-2){1'b0}},pipeline_RS[i].opa_select},
                      {{(32-2){1'b0}},pipeline_RS[i].opb_select},
                      {{(32-$clog2(`NUM_LSQ)){1'b0}},pipeline_RS[i].SQ_idx},
                      {{(32-$clog2(`NUM_LSQ)){1'b0}},pipeline_RS[i].LQ_idx},
                      {{(32-1){1'b0}},pipeline_RS[i].uncond_branch},
                      {{(32-1){1'b0}},pipeline_RS[i].cond_branch},
                      {{(32-1){1'b0}},pipeline_RS[i].wr_mem},
                      {{(32-1){1'b0}},pipeline_RS[i].rd_mem},
                      pipeline_RS[i].target[63:32],
                      pipeline_RS[i].target[31:0]);
      end
      for(int i = ( `NUM_LD + `NUM_ST + `NUM_BR); i < ( `NUM_LD + `NUM_ST + `NUM_BR + `NUM_MULT); i++) begin
        print_RS_entry("MULT",
                      {{(32-1){1'b0}},pipeline_RS[i].busy},
                      pipeline_RS[i].inst,
                      {{(32-5){1'b0}},pipeline_RS[i].func},
                      pipeline_RS[i].NPC[63:32],
                      pipeline_RS[i].NPC[31:0],
                      {{(32-5){1'b0}},pipeline_RS[i].dest_idx},
                      {{(32-$clog2(`NUM_ROB)){1'b0}},pipeline_RS[i].ROB_idx},
                      {{(32-$clog2(`NUM_FL)){1'b0}},pipeline_RS[i].FL_idx},
                      {{(32-$clog2(`NUM_PR)){1'b0}},pipeline_RS[i].T_idx},
                      {{(32-$clog2(`NUM_PR)){1'b0}},pipeline_RS[i].T1.idx},
                      {{(32-1){1'b0}},pipeline_RS[i].T1.ready},
                      {{(32-$clog2(`NUM_PR)){1'b0}},pipeline_RS[i].T2.idx},
                      {{(32-1){1'b0}},pipeline_RS[i].T2.ready},
                      {{(32-2){1'b0}},pipeline_RS[i].opa_select},
                      {{(32-2){1'b0}},pipeline_RS[i].opb_select},
                      {{(32-$clog2(`NUM_LSQ)){1'b0}},pipeline_RS[i].SQ_idx},
                      {{(32-$clog2(`NUM_LSQ)){1'b0}},pipeline_RS[i].LQ_idx},
                      {{(32-1){1'b0}},pipeline_RS[i].uncond_branch},
                      {{(32-1){1'b0}},pipeline_RS[i].cond_branch},
                      {{(32-1){1'b0}},pipeline_RS[i].wr_mem},
                      {{(32-1){1'b0}},pipeline_RS[i].rd_mem},
                      pipeline_RS[i].target[63:32],
                      pipeline_RS[i].target[31:0]);
      end
      for(int i = ( `NUM_LD + `NUM_ST + `NUM_BR + `NUM_MULT); i < ( `NUM_LD + `NUM_ST + `NUM_BR + `NUM_MULT + `NUM_ALU); i++) begin
        print_RS_entry("ALU ",
                      {{(32-1){1'b0}},pipeline_RS[i].busy},
                      pipeline_RS[i].inst,
                      {{(32-5){1'b0}},pipeline_RS[i].func},
                      pipeline_RS[i].NPC[63:32],
                      pipeline_RS[i].NPC[31:0],
                      {{(32-5){1'b0}},pipeline_RS[i].dest_idx},
                      {{(32-$clog2(`NUM_ROB)){1'b0}},pipeline_RS[i].ROB_idx},
                      {{(32-$clog2(`NUM_FL)){1'b0}},pipeline_RS[i].FL_idx},
                      {{(32-$clog2(`NUM_PR)){1'b0}},pipeline_RS[i].T_idx},
                      {{(32-$clog2(`NUM_PR)){1'b0}},pipeline_RS[i].T1.idx},
                      {{(32-1){1'b0}},pipeline_RS[i].T1.ready},
                      {{(32-$clog2(`NUM_PR)){1'b0}},pipeline_RS[i].T2.idx},
                      {{(32-1){1'b0}},pipeline_RS[i].T2.ready},
                      {{(32-2){1'b0}},pipeline_RS[i].opa_select},
                      {{(32-2){1'b0}},pipeline_RS[i].opb_select},
                      {{(32-$clog2(`NUM_LSQ)){1'b0}},pipeline_RS[i].SQ_idx},
                      {{(32-$clog2(`NUM_LSQ)){1'b0}},pipeline_RS[i].LQ_idx},
                      {{(32-1){1'b0}},pipeline_RS[i].uncond_branch},
                      {{(32-1){1'b0}},pipeline_RS[i].cond_branch},
                      {{(32-1){1'b0}},pipeline_RS[i].wr_mem},
                      {{(32-1){1'b0}},pipeline_RS[i].rd_mem},
                      pipeline_RS[i].target[63:32],
                      pipeline_RS[i].target[31:0]);
      end
`endif

      //print Map table
`ifdef PRINT_MAP_TABLE
      print_maptable_head();
      for(int i = 0; i < 32; i++) begin
        print_maptable_entry(i,{{(32-$clog2(`NUM_PR)){1'b0}},pipeline_MAPTABLE[i].idx},{{(32-1){1'b0}},pipeline_MAPTABLE[i].ready}, pipeline_PR[pipeline_MAPTABLE[i].idx][63:32], pipeline_PR[pipeline_MAPTABLE[i].idx][31:0]);
      end
`endif

      //print Freelist
`ifdef PRINT_FREELIST
      print_freelist_head({{(32 - $clog2(`NUM_ROB)){1'b0}},FL_head}, {{(32 - $clog2(`NUM_ROB)){1'b0}},FL_tail});
      for(int i = 0; i < `NUM_ROB; i++) begin
        print_freelist_entry(i,{{(32 - $clog2(`NUM_PR)){1'b0}},pipeline_FL[i]});
      end
`endif

      //print CDB
`ifdef PRINT_CDB
      print_CDB_head();
      for(int i = 0; i < `NUM_FU; i++) begin
        print_CDB_entry({{(32-1){1'b0}},pipeline_CDB[i].taken}, {{(32-$clog2(`NUM_PR)){1'b0}},pipeline_CDB[i].T_idx}, {{(32-$clog2(`NUM_ROB)){1'b0}},pipeline_CDB[i].ROB_idx}, {{(32-5){1'b0}},pipeline_CDB[i].dest_idx}, pipeline_CDB[i].T_value[63:32], pipeline_CDB[i].T_value[31:0]);
      end
`endif

      //print archmap
`ifdef PRINT_ARCHMAP
      print_archmap_head();
      for(int i = 0; i < 32; i++) begin
        print_archmap_entry(i,{{(32-$clog2(`NUM_PR)){1'b0}},pipeline_ARCHMAP[i]});
      end
`endif

`ifdef PRINT_SQ
      print_sq_head({{(32-$clog2(`NUM_LSQ)){1'b0}},SQ_head}, {{(32-$clog2(`NUM_LSQ)){1'b0}},SQ_tail});
      for(int i = 0; i < `NUM_LSQ; i++) begin
        print_sq_entry(i, {31'h0, pipeline_SQ[i].valid}, pipeline_SQ[i].addr[60:29], {pipeline_SQ[i].addr[28:0],3'b0}, pipeline_SQ[i].value[63:32], pipeline_SQ[i].value[31:0]);
      end
`endif

`ifdef PRINT_LQ
      print_lq_head({{(32-$clog2(`NUM_LSQ)){1'b0}},LQ_head}, {{(32-$clog2(`NUM_LSQ)){1'b0}},LQ_tail});
      for(int i = 0; i < `NUM_LSQ; i++) begin
        print_lq_entry(i, {31'h0, pipeline_LQ[i].valid}, pipeline_LQ[i].addr[60:29], {pipeline_LQ[i].addr[28:0],3'b0}, {{(32-$clog2(`NUM_ROB)){1'b0}},pipeline_LQ[i].ROB_idx}, {{(32-$clog2(`NUM_FL)){1'b0}},pipeline_LQ[i].FL_idx}, {{(32-$clog2(`NUM_LSQ)){1'b0}},pipeline_LQ[i].SQ_idx}, pipeline_LQ[i].PC[63:32], pipeline_LQ[i].PC[31:0]);
      end
`endif

`ifdef PRINT_COUNT
      print_count(count[63:32], count[31:0]);
`endif

`ifdef PRINT_DCACHE_BANK
    print_Dcache_head();
    for(int i=0; i < `NUM_IDX; i++) begin
      print_num(i);
      for(int j=0; j < `NUM_WAY; j++) begin
        print_Dcache_bank(Dcache_bank[j][i].data[63:32], Dcache_bank[j][i].data[31:0], {{(64-`NUM_TAG_BITS){1'b0}},Dcache_bank[j][i].tag[`NUM_TAG_BITS-1:32]},Dcache_bank[j][i].tag[31:0],{{(31){1'b0}},Dcache_bank[j][i].dirty},{{(31){1'b0}},Dcache_bank[j][i].valid});
      end
      print_enter();
    end
`endif

`ifdef PRINT_MSHR_ENTRY
    print_MSHR_head({{(32-$clog2(`MSHR_DEPTH)){1'b0}},MSHR_writeback_head},{{(32-$clog2(`MSHR_DEPTH)){1'b0}},MSHR_head},{{(32-$clog2(`MSHR_DEPTH)){1'b0}},MSHR_tail}, {{(32-2){1'b0}},proc2mem_command});
    for(int i = 0; i < `MSHR_DEPTH; i++) begin
      print_MSHR_entry(i,{{(31){1'b0}},MSHR_queue[i].valid}, MSHR_queue[i].data[63:32],MSHR_queue[i].data[31:0],{{(31){1'b0}},MSHR_queue[i].dirty}, MSHR_queue[i].addr[63:32], MSHR_queue[i].addr[31:0], {{(30){1'b0}},MSHR_queue[i].inst_type}, {{(30){1'b0}},MSHR_queue[i].proc2mem_command}, {{(31){1'b0}},MSHR_queue[i].complete}, {{(28){1'b0}},MSHR_queue[i].mem_tag}, {{(30){1'b0}},MSHR_queue[i].state} );
    end
`endif

      //print reg
`ifdef PRINT_REG
      print_reg(CDB_PR_out.T_value[0][63:32], CDB_PR_out.T_value[0][31:0],
                CDB_PR_out.T_value[1][63:32], CDB_PR_out.T_value[1][31:0],
                {{(32-$clog2(`NUM_PR)){1'b0}},CDB_PR_out.T_idx[0]},{{(32-$clog2(`NUM_PR)){1'b0}},CDB_PR_out.T_idx[1]},
                {31'b0,complete_en[0]}, {31'b0,complete_en[1]});
`endif

      //print mem_bus
`ifdef PRINT_MEMBUS
      print_membus({30'b0,proc2mem_command}, {28'b0,mem2proc_response},
            proc2mem_addr[63:32], proc2mem_addr[31:0],
            proc2mem_data[63:32], proc2mem_data[31:0]);
`endif

            
      if(pipeline_completed_insts>0) begin
        for(int i=0; i < pipeline_completed_insts; i++) begin
          if(pipeline_commit_wr_en[i]) begin
            $fdisplay(wb_fileno, "PC=%x, REG[%d]=%x",
                pipeline_commit_NPC[i]-4,
                pipeline_commit_wr_idx[i],
                pipeline_commit_wr_data[i]);
          end
          else begin
            $fdisplay(wb_fileno, "PC=%x, ---",pipeline_commit_NPC[i]-4);
          end
        end
      end
            


      // deal with any halting conditions
`ifdef HALT_ON_TIMEOUT_CLOCK_COUNT
      if (clock_count > `TIMEOUT_MAX_CLOCK)
      begin
        $display(  "@@@ Unified Memory contents hex on left, decimal on right: ");
        show_mem_with_decimal(0,`MEM_64BIT_LINES - 1);
        // 8Bytes per line, 16kB total

        $display("@@  %t : System halted\n@@", $realtime);

        $display(  "@@@ System halted on Timeout (Program ran too long)");
        $display("@@@\n@@");
        show_clk_count;
        print_close(); // close the pipe_print output file
        $fclose(wb_fileno);
        #100 $finish;
      end
`endif

`ifdef HALT_ON_TIMEOUT_CYCLE_COUNT
      if (clock_cycle > `TIMEOUT_MAX_CYCLES)
      begin
        $display(  "@@@ Unified Memory contents hex on left, decimal on right: ");
        show_mem_with_decimal(0,`MEM_64BIT_LINES - 1);
        // 8Bytes per line, 16kB total

        $display("@@  %t : System halted\n@@", $realtime);

        $display(  "@@@ System halted on Timeout (Program + overhead ran too long)");
        $display("@@@\n@@");
        show_clk_count;
        print_close(); // close the pipe_print output file
        $fclose(wb_fileno);
        #100 $finish;
      end
`endif

      if(pipeline_error_status!=NO_ERROR)
      begin
        $display(  "@@@ Unified Memory contents hex on left, decimal on right: ");
              show_mem_with_decimal(0,`MEM_64BIT_LINES - 1);
        // 8Bytes per line, 16kB total

        $display("@@  %t : System halted\n@@", $realtime);

        case(pipeline_error_status)
          HALTED_ON_MEMORY_ERROR:
            $display(  "@@@ System halted on memory error");
          HALTED_ON_HALT:
            $display(  "@@@ System halted on HALT instruction");
          HALTED_ON_ILLEGAL:
            $display(  "@@@ System halted on illegal instruction(illegal insn decoded)");
          default:
            $display(  "@@@ System halted on unknown error code %x",
                  pipeline_error_status);
        endcase
        $display("@@@\n@@");
        show_clk_count;
        print_close(); // close the pipe_print output file
        $fclose(wb_fileno);
        #100 $finish;
      end

    end  // if(reset)
  end
endmodule  // module testbench

