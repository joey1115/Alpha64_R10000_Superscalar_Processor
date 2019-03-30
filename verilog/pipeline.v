/////////////////////////////////////////////////////////////////////////
//                                                                     //
//   Modulename :  pipeline.v                                          //
//                                                                     //
//  Description :  Top-level module of the verisimple pipeline;        //
//                 This instantiates and connects the 5 stages of the  //
//                 Verisimple pipeline togeather.                      //
//                                                                     //
//                                                                     //
/////////////////////////////////////////////////////////////////////////

`timescale 1ns/100ps

`define DEBUG

module pipeline (
  input         clock,                    // System clock
  input         reset,                    // System reset
  input [3:0]   mem2proc_response,        // Tag from memory about current request
  input [63:0]  mem2proc_data,            // Data coming back from memory
  input [3:0]   mem2proc_tag,              // Tag from memory about current reply
`ifndef SYNTH_TEST
  output ROB_t                                           pipeline_ROB,
  output RS_ENTRY_t   [`NUM_FU-1:0]                      pipeline_RS,
  output logic        [31:0][$clog2(`NUM_PR)-1:0]        pipeline_ARCHMAP,
  output T_t          [31:0]                             pipeline_MAPTABLE,
  output CDB_entry_t  [`NUM_FU-1:0]                      pipeline_CDB,
  output logic                                           complete_en,
  output CDB_PR_OUT_t                                    CDB_PR_out,
  output logic                                           dispatch_en,
  output logic                                           ROB_valid,
  output logic                                           RS_valid,
  output logic                                           FL_valid,
  output logic                                           rollback_en,
  output logic        [`NUM_PR-1:0][63:0]                pipeline_PR,
  output logic        [$clog2(`NUM_FL)-1:0]              FL_head,
  output logic        [$clog2(`NUM_FL)-1:0]              FL_tail,
  output logic        [`NUM_FL-1:0][$clog2(`NUM_PR)-1:0] pipeline_FL,
  // output logic [4:0]  pipeline_commit_wr_idx,
  // output logic [63:0] pipeline_commit_wr_data,
  // output logic        pipeline_commit_wr_en,
  // output logic [63:0] pipeline_commit_NPC
`endif
  output logic [1:0]  proc2mem_command,    // command sent to memory
  output logic [63:0] proc2mem_addr,      // Address sent to memory
  output logic [63:0] proc2mem_data,      // Data sent to memory
  output logic [3:0]  pipeline_completed_insts,
  output ERROR_CODE   pipeline_error_status
);
  logic                                          en, F_decoder_en, illegal, if_valid_inst_out, halt;
`ifdef SYNTH_TEST
  logic                                          dispatch_en;
  logic       [`NUM_PR-1:0][63:0]                pipeline_PR;
  logic       [`NUM_FL-1:0][$clog2(`NUM_PR)-1:0] pipeline_FL;
  CDB_entry_t [`NUM_FU-1:0]                      pipeline_CDB;
  ROB_t                                          pipeline_ROB;
  RS_ENTRY_t  [`NUM_FU-1:0]                      pipeline_RS;
  logic       [31:0][$clog2(`NUM_PR)-1:0]        pipeline_ARCHMAP;
  T_t         [31:0]                             pipeline_MAPTABLE;
`endif
  logic                                          write_en;
`ifdef SYNTH_TEST
  logic                                          complete_en;
`endif
  logic                   [`NUM_FU-1:0]          CDB_valid;
  CDB_ROB_OUT_t                                  CDB_ROB_out;
  CDB_RS_OUT_t                                   CDB_RS_out;
  CDB_MAP_TABLE_OUT_t                            CDB_Map_Table_out;
`ifdef SYNTH_TEST
  CDB_PR_OUT_t                                   CDB_PR_out;
`endif
  DECODER_ROB_OUT_t                              decoder_ROB_out;
  DECODER_RS_OUT_t                               decoder_RS_out;
  DECODER_FL_OUT_t                               decoder_FL_out;
  DECODER_MAP_TABLE_OUT_t                        decoder_Map_Table_out;
`ifdef SYNTH_TEST
  logic                                          FL_valid;
`endif
  FL_ROB_OUT_t                                   FL_ROB_out;
  FL_RS_OUT_t                                    FL_RS_out;
  FL_MAP_TABLE_OUT_t                             FL_Map_Table_out;
  logic                   [`NUM_FU-1:0]          FU_valid;
`ifdef SYNTH_TEST
  logic                                          rollback_en;
`endif
  logic                   [$clog2(`NUM_FL)-1:0]  FL_rollback_idx;
  logic                   [$clog2(`NUM_ROB)-1:0] ROB_rollback_idx;
  logic                   [$clog2(`NUM_ROB)-1:0] diff_ROB;
  logic                                          take_branch_out;
  logic                   [63:0]                 take_branch_target;
  FU_CDB_OUT_t                                   FU_CDB_out;
  MAP_TABLE_ROB_OUT_t                            Map_Table_ROB_out;
  MAP_TABLE_RS_OUT_t                             Map_Table_RS_out;
  PR_FU_OUT_t                                    PR_FU_out;
`ifdef SYNTH_TEST
  logic                                          ROB_valid;
`endif
  logic                                          retire_en;
  logic                                          halt_out;
  logic                   [$clog2(`NUM_ROB)-1:0] ROB_idx;
  ROB_ARCH_MAP_OUT_t                             ROB_Arch_Map_out;
  ROB_FL_OUT_t                                   ROB_FL_out;
`ifdef SYNTH_TEST
  logic                                          RS_valid;
`endif
  RS_FU_OUT_t                                    RS_FU_out;
  RS_PR_OUT_t                                    RS_PR_out;
  F_DECODER_OUT_t                                F_decoder_out;
  // memory registers
  logic [1:0] proc2Dmem_command;
  logic [1:0] proc2Imem_command;
  logic [63:0] proc2Dmem_addr;
  logic [63:0] proc2Imem_addr;

  // Icache wires
  logic [63:0] cachemem_data;
  logic        cachemem_valid;
  logic  [4:0] Icache_rd_idx;
  logic  [7:0] Icache_rd_tag;
  logic  [4:0] Icache_wr_idx;
  logic  [7:0] Icache_wr_tag;
  logic        Icache_wr_en;
  logic [63:0] Icache_data_out, proc2Icache_addr;
  logic        Icache_valid_out;
  logic [3:0]  Imem2proc_response;
  logic [63:0] if_NPC_out;
  logic [31:0] if_IR_out;
  logic fetch_en;
`ifndef SYNTH_TEST
  logic       [`NUM_FL-1:0][$clog2(`NUM_PR)-1:0]                          FL_table, next_FL_table;
  logic       [$clog2(`NUM_FL)-1:0]                                       next_head;
  logic       [$clog2(`NUM_FL)-1:0]                                       next_tail;
  logic                                                                   last_done;
  logic       [63:0]                                                      product_out;
  logic       [4:0]                                                       last_dest_idx;
  logic       [$clog2(`NUM_PR)-1:0]                                       last_T_idx;
  logic       [$clog2(`NUM_ROB)-1:0]                                      last_ROB_idx;
  logic       [$clog2(`NUM_FL)-1:0]                                       last_FL_idx;
  logic       [63:0]                                                      T1_value;
  logic       [63:0]                                                      T2_value;
  logic       [((`NUM_MULT_STAGE-1)*64)-1:0]                              internal_T1_values, internal_T2_values;
  logic       [`NUM_MULT_STAGE-2:0]                                       internal_valids;
  logic       [`NUM_MULT_STAGE-2:0]                                       internal_dones;
  logic       [5*(`NUM_MULT_STAGE-1)-1:0]                                 internal_dest_idx;
  logic       [($clog2(`NUM_PR)*(`NUM_MULT_STAGE-1))-1:0]                 internal_T_idx;
  logic       [($clog2(`NUM_ROB)*(`NUM_MULT_STAGE-1))-1:0]                internal_ROB_idx;
  logic       [($clog2(`NUM_FL)*(`NUM_MULT_STAGE-1))-1:0]                 internal_FL_idx;
  logic       [`NUM_FU-1:0]                                               RS_match_hit;
  logic       [$clog2(`NUM_FU)-1:0]                                       RS_match_idx;
`endif

  assign en           = `TRUE;
  assign fetch_en = ROB_valid && RS_valid && FL_valid && !rollback_en;
  assign dispatch_en  = fetch_en && F_decoder_out.valid;
  assign F_decoder_en = fetch_en;
  //assign when an instruction retires/completed
  assign pipeline_completed_insts = {3'b0, retire_en};
  assign pipeline_error_status    = halt_out ? HALTED_ON_HALT :
                                               NO_ERROR;
  assign proc2Dmem_command = BUS_NONE;
  assign proc2Dmem_addr = 0;
  
  assign proc2mem_command =
    (proc2Dmem_command==BUS_NONE) ? proc2Imem_command:proc2Dmem_command;
  assign proc2mem_addr =
    (proc2Dmem_command==BUS_NONE) ? proc2Imem_addr:proc2Dmem_addr;
  //TODO: Uncomment and pass for mem stage in the pipeline
  // assign Dmem2proc_response = 
  //   (proc2Dmem_command==`BUS_NONE) ? 0 : mem2proc_response;
  assign Imem2proc_response = (proc2Dmem_command==BUS_NONE) ? mem2proc_response : 0;

   // Actual cache (data and tag RAMs)
  cache cachememory (
    // inputs
    .clock(clock),
    .reset(reset),
    .wr1_en(Icache_wr_en),
    .wr1_idx(Icache_wr_idx),
    .wr1_tag(Icache_wr_tag),
    .wr1_data(mem2proc_data),
    .rd1_idx(Icache_rd_idx),
    .rd1_tag(Icache_rd_tag),
    // outputs
    .rd1_data(cachemem_data),
    .rd1_valid(cachemem_valid)
  );

  // Cache controller
  icache icache_0(
    // inputs 
    .clock(clock),
    .reset(reset),
    .Imem2proc_response(Imem2proc_response),
    .Imem2proc_data(mem2proc_data),
    .Imem2proc_tag(mem2proc_tag),
    .proc2Icache_addr(proc2Icache_addr),
    .cachemem_data(cachemem_data),
    .cachemem_valid(cachemem_valid),
    // outputs
    .proc2Imem_command(proc2Imem_command),
    .proc2Imem_addr(proc2Imem_addr),
    .Icache_data_out(Icache_data_out),
    .Icache_valid_out(Icache_valid_out),
    .current_index(Icache_rd_idx),
    .current_tag(Icache_rd_tag),
    .last_index(Icache_wr_idx),
    .last_tag(Icache_wr_tag),
    .data_write_enable(Icache_wr_en)
  );

  F_stage F_stage_0 (
    // Inputs
    .clock (clock),
    .reset (reset),
    .get_next_inst(fetch_en), //only go to next insn when high
    .take_branch_out(take_branch_out),
    .take_branch_target(take_branch_target),
    .Imem2proc_data(Icache_data_out),
    .Imem_valid(Icache_valid_out),
    // Outputs
    .if_NPC_out(if_NPC_out), 
    .if_IR_out(if_IR_out),
    .proc2Imem_addr(proc2Icache_addr),
    .if_valid_inst_out(if_valid_inst_out)
  );

  //////////////////////////////////////////////////
  //                                              //
  //            IF/ID Pipeline Register           //
  //                                              //
  //////////////////////////////////////////////////
  always_ff @(posedge clock) begin
    if (reset) begin
      F_decoder_out <= `SD `F_DECODER_OUT_RESET;
    end else if (F_decoder_en) begin
      F_decoder_out.inst   <= `SD if_IR_out;
      F_decoder_out.NPC    <= `SD if_NPC_out;
      F_decoder_out.valid  <= `SD if_valid_inst_out;
    end // if (F_decoder_en)
  end // always

  Arch_Map arch_map_0 (
    .en(en),
    .clock(clock),
    .reset(reset),
    .retire_en(retire_en),
`ifdef SYNTH_TEST
    .ROB_Arch_Map_out(ROB_Arch_Map_out)
`else
    .ROB_Arch_Map_out(ROB_Arch_Map_out),
    .next_arch_map(pipeline_ARCHMAP)
`endif
  );

  CDB cdb_0 (
    .en(en),
    .clock(clock),
    .reset(reset),
    .rollback_en(rollback_en),
    .ROB_rollback_idx(ROB_rollback_idx),
    .diff_ROB(diff_ROB),
    .FU_CDB_out(FU_CDB_out),
`ifndef SYNTH_TEST
    .CDB(pipeline_CDB),
`endif
    .write_en(write_en),
    .complete_en(complete_en),
    .CDB_valid(CDB_valid),
    .CDB_ROB_out(CDB_ROB_out),
    .CDB_RS_out(CDB_RS_out),
    .CDB_Map_Table_out(CDB_Map_Table_out),
    .CDB_PR_out(CDB_PR_out)
  );

  decoder decoder_0 (
    .F_decoder_out(F_decoder_out),
    .decoder_ROB_out(decoder_ROB_out),
    .decoder_RS_out(decoder_RS_out),
    .decoder_FL_out(decoder_FL_out),
    .decoder_Map_Table_out(decoder_Map_Table_out),
    .illegal(illegal),
    .halt(halt)
  );

  FL fl_0 (
    .clock(clock),
    .reset(reset),
    .dispatch_en(dispatch_en),
    .rollback_en(rollback_en),
    .retire_en(retire_en),
    .FL_rollback_idx(FL_rollback_idx),
    .decoder_FL_out(decoder_FL_out),
    .ROB_FL_out(ROB_FL_out),
`ifndef SYNTH_TEST
    .FL_table(pipeline_FL),
    .next_FL_table(next_FL_table),
    .head(FL_head),
    .next_head(next_head),
    .tail(FL_tail),
    .next_tail(next_tail),
`endif
    .FL_valid(FL_valid),
    .FL_ROB_out(FL_ROB_out),
    .FL_RS_out(FL_RS_out),
    .FL_Map_Table_out(FL_Map_Table_out)
  );

  FU fu_0 (
    .clock(clock),
    .reset(reset),
    .ROB_idx(ROB_idx),
    .CDB_valid(CDB_valid),
    .RS_FU_out(RS_FU_out),
    .PR_FU_out(PR_FU_out),
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
    .FU_valid(FU_valid),
    .rollback_en(rollback_en),
    .ROB_rollback_idx(ROB_rollback_idx),
    .FL_rollback_idx(FL_rollback_idx),
    .diff_ROB(diff_ROB),
    .take_branch_out(take_branch_out),
    .take_branch_target(take_branch_target),
    .FU_CDB_out(FU_CDB_out)
  );

  Map_Table map_table_0 (
    .en(en),
    .clock(clock),
    .reset(reset),
    .dispatch_en(dispatch_en),
    .rollback_en(rollback_en),
    .complete_en(complete_en),
    .ROB_rollback_idx(ROB_rollback_idx),
    .ROB_idx(ROB_idx),
    .decoder_Map_Table_out(decoder_Map_Table_out),
    .FL_Map_Table_out(FL_Map_Table_out),
    .CDB_Map_Table_out(CDB_Map_Table_out),
`ifndef SYNTH_TEST
    .map_table_out(pipeline_MAPTABLE),
`endif
    .Map_Table_ROB_out(Map_Table_ROB_out),
    .Map_Table_RS_out(Map_Table_RS_out)
  );

  PR pr_0 (
    .en(en),
    .clock(clock),
    .reset(reset),
    .write_en(write_en),
    .CDB_PR_out(CDB_PR_out),
    .RS_PR_out(RS_PR_out),
`ifndef SYNTH_TEST
    .pr_data(pipeline_PR),
`endif
    .PR_FU_out(PR_FU_out)
  );

  ROB rob_0 (
    .en(en),
    .clock(clock),
    .reset(reset),
    .dispatch_en(dispatch_en),
    .complete_en(complete_en),
    .rollback_en(rollback_en),
    .ROB_rollback_idx(ROB_rollback_idx),
    .decoder_ROB_out(decoder_ROB_out),
    .FL_ROB_out(FL_ROB_out),
    .Map_Table_ROB_out(Map_Table_ROB_out),
    .CDB_ROB_out(CDB_ROB_out),
`ifndef SYNTH_TEST
    .rob(pipeline_ROB),
`endif
    .ROB_valid(ROB_valid),
    .retire_en(retire_en),
    .halt_out(halt_out),
    .ROB_idx(ROB_idx),
    .ROB_Arch_Map_out(ROB_Arch_Map_out),
    .ROB_FL_out(ROB_FL_out)
  );

  RS rs_0 (
    .clock(clock),
    .reset(reset),
    .en(en),
    .complete_en(complete_en),
    .dispatch_en(dispatch_en),
    .rollback_en(rollback_en),
    .FU_valid(FU_valid),
    .ROB_rollback_idx(ROB_rollback_idx),
    .diff_ROB(diff_ROB),
    .ROB_idx(ROB_idx),
    .decoder_RS_out(decoder_RS_out),
    .FL_RS_out(FL_RS_out),
    .Map_Table_RS_out(Map_Table_RS_out),
    .CDB_RS_out(CDB_RS_out),
`ifndef SYNTH_TEST
    .RS_out(pipeline_RS),
    .RS_match_hit(RS_match_hit),   // If a RS entry is ready
    .RS_match_idx(RS_match_idx),
`endif
    .RS_valid(RS_valid),
    .RS_FU_out(RS_FU_out),
    .RS_PR_out(RS_PR_out)
  );

  
endmodule  // module verisimple
