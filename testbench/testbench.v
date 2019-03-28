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

`include "sys_defs.vh"
`include "verilog/ROB/ROB.vh"

extern void print_open();
extern void print_cycles();
// extern void print_stage(string div, int inst, int npc, int valid_inst);
extern void print_ROB_ht(int head, int tail);
extern void print_ROB_entry(int i, int valid, int T, int T_old, int dest_idx, int complete, int halt);
extern void print_RS_head();
extern void print_RS_entry(string funcType, int busy, int inst, int func, int NPC_hi, int NPC_lo, int dest_idx, int ROB_idx, int FL_idx, int T_idx, int T1, int T1_ready, int T2, int T2_ready, int opa_select, int opb_select);
extern void print_maptable_head();
extern void print_maptable_entries(int reg_idx, int T, int ready, int PR_data_hi, int PR_data_lo);
extern void print_CDB_head();
extern void print_CDB_entries(int taken, int T_idx, int ROB_idx, int dest_idx, int T_value_HI, int T_value_LO);
extern void print_archmap_head();
extern void print_archmap_entries(int reg_idx, int pr);
extern void print_dispatch_en(int dispatch_en, int ROB_valid, int RS_valid, int FL_valid, int rollback_en);
extern void print_freelist_head(int FL_head, int FL_tail);
extern void print_freelist_entry(int i, int freePR);

extern void print_reg(int wb_reg_wr_data_out_hi, int wb_reg_wr_data_out_lo,
                      int wb_reg_wr_idx_out, int wb_reg_wr_en_out);
extern void print_membus(int proc2mem_command, int mem2proc_response,
                         int proc2mem_addr_hi, int proc2mem_addr_lo,
                         int proc2mem_data_hi, int proc2mem_data_lo);
extern void print_close();


module testbench;

  // Registers and wires used in the testbench
  logic        clock;
  logic        reset;
  logic [31:0] clock_count;
  logic [31:0] instr_count;
  int          wb_fileno;

  logic  [1:0] proc2mem_command;
  logic [63:0] proc2mem_addr;
  logic [63:0] proc2mem_data;
  logic  [3:0] mem2proc_response;
  logic [63:0] mem2proc_data;
  logic  [3:0] mem2proc_tag;

  logic  [3:0] pipeline_completed_insts;
  logic  [3:0] pipeline_error_status;
  //logic  [4:0] pipeline_commit_wr_idx;
  //logic [63:0] pipeline_commit_wr_data;
  //logic        pipeline_commit_wr_en;
  logic [63:0] pipeline_commit_NPC;

  ROB_t pipeline_ROB;
  RS_ENTRY_t [`NUM_FU-1:0]  pipeline_RS;
  logic [31:0][$clog2(`NUM_PR)-1:0] pipeline_ARCHMAP;
  T_t [31:0] pipeline_MAPTABLE;
  CDB_entry_t [`NUM_FU-1:0] pipeline_CDB;
  logic complete_en;
  CDB_PR_OUT_t CDB_PR_out;
  logic dispatch_en, ROB_valid, RS_valid, FL_valid, rollback_en;
  logic [`NUM_PR-1:0][63:0] pipeline_PR;
  logic [`NUM_FL-1:0][$clog2(`NUM_PR)-1:0] FL_table;
  logic [$clog2(`NUM_FL)-1:0]              FL_head, FL_tail;





  // logic [63:0] if_NPC_out;
  // logic [31:0] if_IR_out;
  // logic        if_valid_inst_out;
  // logic [63:0] if_id_NPC;
  // logic [31:0] if_id_IR;
  // logic        if_id_valid_inst;
  // logic [63:0] id_ex_NPC;
  // logic [31:0] id_ex_IR;
  // logic        id_ex_valid_inst;
  // logic [63:0] ex_mem_NPC;
  // logic [31:0] ex_mem_IR;
  // logic        ex_mem_valid_inst;
  // logic [63:0] mem_wb_NPC;
  // logic [31:0] mem_wb_IR;
  // logic        mem_wb_valid_inst;

  // // Strings to hold instruction opcode
  // logic  [8*7:0] if_instr_str;
  // logic  [8*7:0] id_instr_str;
  // logic  [8*7:0] ex_instr_str;
  // logic  [8*7:0] mem_instr_str;
  // logic  [8*7:0] wb_instr_str;


  // Instantiate the Pipeline
  `DUT(pipeline) pipeline_0 (// Inputs
    .clock             (clock),
    .reset             (reset),
    .mem2proc_response (mem2proc_response),
    .mem2proc_data     (mem2proc_data),
    .mem2proc_tag      (mem2proc_tag),

            // Outputs
    .proc2mem_command  (proc2mem_command),
    .proc2mem_addr     (proc2mem_addr),
    .proc2mem_data     (proc2mem_data),

    //needed to tell if inst is completed added to inst count
    .pipeline_completed_insts(pipeline_completed_insts),


    .pipeline_error_status(pipeline_error_status),
    //.pipeline_commit_wr_data(pipeline_commit_wr_data),
    //.pipeline_commit_wr_idx(pipeline_commit_wr_idx),
    //.pipeline_commit_wr_en(pipeline_commit_wr_en),
    //.pipeline_commit_NPC(pipeline_commit_NPC),

    .pipeline_ROB(pipeline_ROB),
    .pipeline_RS(pipeline_RS),
    .pipeline_ARCHMAP(pipeline_ARCHMAP),
    .pipeline_MAPTABLE(pipeline_MAPTABLE),
    .pipeline_CDB(pipeline_CDB),
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
    .FL_tail(FL_tail)

    // .if_NPC_out(if_NPC_out),
    // .if_IR_out(if_IR_out),
    // .if_valid_inst_out(if_valid_inst_out),
    // .if_id_NPC(if_id_NPC),
    // .if_id_IR(if_id_IR),
    // .if_id_valid_inst(if_id_valid_inst),
    // .id_ex_NPC(id_ex_NPC),
    // .id_ex_IR(id_ex_IR),
    // .id_ex_valid_inst(id_ex_valid_inst),
    // .ex_mem_NPC(ex_mem_NPC),
    // .ex_mem_IR(ex_mem_IR),
    // .ex_mem_valid_inst(ex_mem_valid_inst),
    // .mem_wb_NPC(mem_wb_NPC),
    // .mem_wb_IR(mem_wb_IR),
    // .mem_wb_valid_inst(mem_wb_valid_inst)
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
      cpi = (clock_count + 1.0) / instr_count;
      $display("@@  %0d cycles / %0d instrs = %f CPI\n@@",
      clock_count+1, instr_count, cpi);
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
    // print_header("Cycle:      IF      |     ID      |     EX      |     MEM     |     WB      Reg Result");
  end


  // Count the number of posedges and number of instructions completed
  // till simulation ends
  always @(posedge clock or posedge reset) begin
    if(reset) begin
      clock_count <= `SD 0;
      instr_count <= `SD 0;
    end else begin
      clock_count <= `SD (clock_count + 1);
      instr_count <= `SD (instr_count + pipeline_completed_insts);
    end
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
      print_dispatch_en({{(32-1){1'b0}},dispatch_en}, {{(32-1){1'b0}},ROB_valid}, {{(32-1){1'b0}},RS_valid}, {{(32-1){1'b0}},FL_valid}, {{(32-1){1'b0}},rollback_en});
      // print ROB
      print_ROB_ht({{(32-$clog2(`NUM_ROB)){1'b0}},pipeline_ROB.head}, {{(32-$clog2(`NUM_ROB)){1'b0}},pipeline_ROB.tail});
      for(int i = 0; i < `NUM_ROB; i++) begin
      print_ROB_entry(i,{{(32-1){1'b0}},pipeline_ROB.entry[i].valid}, {{(32-$clog2(`NUM_PR)){1'b0}},pipeline_ROB.entry[i].T_idx}, {{(32-$clog2(`NUM_PR)){1'b0}},pipeline_ROB.entry[i].Told_idx},{{(32-5){1'b0}},pipeline_ROB.entry[i].dest_idx},{{(32-1){1'b0}},pipeline_ROB.entry[i].complete},{{(32-1){1'b0}},pipeline_ROB.entry[i].halt});
      end
      //print RS
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
                      {{(32-2){1'b0}},pipeline_RS[i].opb_select});
      end
      for(int i = `NUM_LD; i < (`NUM_LD + `NUM_ST); i++) begin
        print_RS_entry("ST  ",
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
                      {{(32-2){1'b0}},pipeline_RS[i].opb_select});
      end
      for(int i = (`NUM_LD + `NUM_ST); i < (`NUM_LD + `NUM_ST + `NUM_BR); i++) begin
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
                      {{(32-2){1'b0}},pipeline_RS[i].opb_select});
      end
      for(int i = (`NUM_LD + `NUM_ST + `NUM_BR); i < (`NUM_LD + `NUM_ST + `NUM_BR + `NUM_MULT); i++) begin
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
                      {{(32-2){1'b0}},pipeline_RS[i].opb_select});
      end
      for(int i = (`NUM_LD + `NUM_ST + `NUM_BR + `NUM_MULT); i < (`NUM_LD + `NUM_ST + `NUM_BR + `NUM_MULT + `NUM_ALU); i++) begin
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
                      {{(32-2){1'b0}},pipeline_RS[i].opb_select});
      end

      //print Map table
      print_maptable_head();
      for(int i = 0; i < 32; i++) begin
        print_maptable_entries(i,{{(32-$clog2(`NUM_PR)){1'b0}},pipeline_MAPTABLE[i].idx},{{(32-1){1'b0}},pipeline_MAPTABLE[i].ready}, pipeline_PR[pipeline_MAPTABLE[i].idx][63:32], pipeline_PR[pipeline_MAPTABLE[i].idx][31:0]);
      end

      //print Freelist
      print_freelist_head(FL_head, FL_tail);
      for(int i = 0; i < `NUM_ROB; i++) begin
        print_freelist_entry(i,pipeline_FL[i]);
      end

      //print CDB
      print_CDB_head();
      for(int i = 0; i < `NUM_FU; i++) begin
        print_CDB_entries({{(32-1){1'b0}},pipeline_CDB[i].taken}, {{(32-$clog2(`NUM_PR)){1'b0}},pipeline_CDB[i].T_idx}, {{(32-$clog2(`NUM_ROB)){1'b0}},pipeline_CDB[i].ROB_idx}, {{(32-5){1'b0}},pipeline_CDB[i].dest_idx}, pipeline_CDB[i].T_value[63:32], pipeline_CDB[i].T_value[31:0]);
      end

      //print archmap
      print_archmap_head();
      for(int i = 0; i < 32; i++) begin
        print_archmap_entries(i,{{(32-$clog2(`NUM_PR)){1'b0}},pipeline_ARCHMAP[i]});
      end

      //print PR
      // print_PR_head();



       print_reg(CDB_PR_out.T_value[63:32], CDB_PR_out.T_value[31:0],
            {{(32-$clog2(`NUM_PR)){1'b0}},CDB_PR_out.T_idx}, {31'b0,complete_en});
       print_membus({30'b0,proc2mem_command}, {28'b0,mem2proc_response},
            proc2mem_addr[63:32], proc2mem_addr[31:0],
            proc2mem_data[63:32], proc2mem_data[31:0]);


      // print the writeback information to writeback.out
      // if(pipeline_completed_insts>0) begin
      //   if(pipeline_commit_wr_en)
      //     $fdisplay(  wb_fileno, "PC=%x, REG[%d]=%x",
      //           pipeline_commit_NPC-4,
      //           pipeline_commit_wr_idx,
      //           pipeline_commit_wr_data);
      // else
      //   $fdisplay(wb_fileno, "PC=%x, ---",pipeline_commit_NPC-4);
      // end

      // deal with any halting conditions
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

