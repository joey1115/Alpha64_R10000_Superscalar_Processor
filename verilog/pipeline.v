`timescale 1ns/100ps

module pipeline (
  input         clock,                    // System clock
  input         reset,                    // System reset
  input [3:0]   mem2proc_response,        // Tag from memory about current request
  input [63:0]  mem2proc_data,            // Data coming back from memory
  input [3:0]   mem2proc_tag,              // Tag from memory about current reply
`ifdef DEBUG
  output ROB_t                                           pipeline_ROB,
  output RS_ENTRY_t   [`NUM_FU-1:0]                      pipeline_RS,
  output logic        [31:0][$clog2(`NUM_PR)-1:0]        pipeline_ARCHMAP,
  output T_t          [31:0]                             pipeline_MAPTABLE,
  output CDB_entry_t  [`NUM_FU-1:0]                      pipeline_CDB,
  output logic        [`NUM_SUPER-1:0]                   complete_en,
  output CDB_PR_OUT_t                                    CDB_PR_out,
  output logic                                           dispatch_en,
  output logic                                           ROB_valid,
  output logic                                           RS_valid,
  output logic                                           FL_valid,
  output logic                                           rollback_en,
  output logic        [`NUM_PR-1:0][63:0]                pipeline_PR,
  output INST_ENTRY_t [`NUM_FB-1:0]                      pipeline_FB,
  output logic        [$clog2(`NUM_FL)-1:0]              FL_head,
  output logic        [$clog2(`NUM_FL)-1:0]              FL_tail,
  output logic        [$clog2(`NUM_FB)-1:0]              FB_head,
  output logic        [$clog2(`NUM_FB)-1:0]              FB_tail,
  output logic        [`NUM_FL-1:0][$clog2(`NUM_PR)-1:0] pipeline_FL,
  output logic        [`NUM_SUPER-1:0][4:0]              pipeline_commit_wr_idx,
  output logic        [`NUM_SUPER-1:0][63:0]             pipeline_commit_wr_data,
  output logic        [`NUM_SUPER-1:0]                   pipeline_commit_wr_en,
  output logic        [`NUM_SUPER-1:0][63:0]             pipeline_commit_NPC,
`endif
  output logic        [1:0]                               proc2mem_command,    // command sent to memory
  output logic        [63:0]                              proc2mem_addr,      // Address sent to memory
  output logic        [63:0]                              proc2mem_data,      // Data sent to memory
  output logic        [3:0]                               pipeline_completed_insts,
  output ERROR_CODE   pipeline_error_status
);

  logic                                          en;
  logic       [`NUM_SUPER-1:0]                   if_valid_inst_out;
`ifndef DEBUG
  logic                                          dispatch_en;
  logic       [`NUM_PR-1:0][63:0]                pipeline_PR;
  logic       [`NUM_FL-1:0][$clog2(`NUM_PR)-1:0] pipeline_FL;
  CDB_entry_t [`NUM_FU-1:0]                      pipeline_CDB;
  ROB_t                                          pipeline_ROB;
  RS_ENTRY_t  [`NUM_FU-1:0]                      pipeline_RS;
  logic       [31:0][$clog2(`NUM_PR)-1:0]        pipeline_ARCHMAP;
  T_t         [31:0]                             pipeline_MAPTABLE;
`endif
  logic       [`NUM_SUPER-1:0]                   write_en;
`ifndef DEBUG
  logic                   [`NUM_SUPER-1:0]       complete_en;
`endif
  logic                   [`NUM_FU-1:0]          CDB_valid;
  CDB_ROB_OUT_t                                  CDB_ROB_out;
  CDB_RS_OUT_t                                   CDB_RS_out;
  CDB_MAP_TABLE_OUT_t                            CDB_Map_Table_out;
`ifndef DEBUG
  CDB_PR_OUT_t                                   CDB_PR_out;
`endif
  DECODER_ROB_OUT_t                              decoder_ROB_out;
  DECODER_RS_OUT_t                               decoder_RS_out;
  DECODER_FL_OUT_t                               decoder_FL_out;
  DECODER_MAP_TABLE_OUT_t                        decoder_Map_Table_out;
  DECODER_SQ_OUT_t                               decoder_SQ_out;
  DECODER_LQ_OUT_t                               decoder_LQ_out;
`ifndef DEBUG
  logic                                          FL_valid;
`endif
  FL_ROB_OUT_t                                   FL_ROB_out;
  FL_RS_OUT_t                                    FL_RS_out;
  FL_MAP_TABLE_OUT_t                             FL_Map_Table_out;
  logic                   [`NUM_FU-1:0]          FU_valid;
`ifndef DEBUG
  logic                                          rollback_en;
`endif
  logic                   [$clog2(`NUM_FL)-1:0]  FL_rollback_idx;
  logic                   [$clog2(`NUM_ROB)-1:0] ROB_rollback_idx;
  logic                   [$clog2(`NUM_ROB)-1:0] diff_ROB;
  // logic                                          take_branch_out;
  // logic                   [63:0]                 take_branch_target;
  FU_CDB_OUT_t                                   FU_CDB_out;
  FU_SQ_OUT_t                                    FU_SQ_out;
  FU_LQ_OUT_t                                    FU_LQ_out;
  logic                                          LSQ_valid;
  FU_BP_OUT_t                                    FU_BP_out;
  MAP_TABLE_ROB_OUT_t                            Map_Table_ROB_out;
  MAP_TABLE_RS_OUT_t                             Map_Table_RS_out;
  PR_FU_OUT_t                                    PR_FU_out;
`ifndef DEBUG
  logic                                          ROB_valid;
`endif
  logic                   [`NUM_SUPER-1:0]       retire_en;
  logic                                          halt_out;
  logic                                          illegal_out;
  logic            [`NUM_SUPER-1:0][$clog2(`NUM_ROB)-1:0] ROB_idx;
  ROB_ARCH_MAP_OUT_t                             ROB_Arch_Map_out;
  ROB_FL_OUT_t                                   ROB_FL_out;
`ifndef DEBUG
  logic                                          RS_valid;
`endif
  RS_FU_OUT_t                                    RS_FU_out;
  RS_PR_OUT_t                                    RS_PR_out;
  F_DECODER_OUT_t                                F_decoder_out;
  // To be modified
  D_CACHE_SQ_OUT_t                               D_cache_SQ_out;
  D_CACHE_LQ_OUT_t                               D_cache_LQ_out;
  ARCH_MAP_MAP_TABLE_OUT_t                       ARCH_MAP_MAP_Table_out;
  // F_DECODER_OUT_t                                F_decoder_out;
  LQ_BP_OUT_t                                    LQ_BP_out;
  logic                   [$clog2(`NUM_LSQ)-1:0] SQ_rollback_idx;
  logic                   [$clog2(`NUM_LSQ)-1:0] LQ_rollback_idx;


  logic                   [`NUM_SUPER-1:0][63:0]retire_NPC;
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
  BP_F_OUT_t   BP_F_out;
  logic [`NUM_SUPER-1:0][63:0] if_NPC_out, if_PC_out;
  logic [`NUM_SUPER-1:0][31:0] if_IR_out;
  logic [`NUM_SUPER-1:0][63:0] if_target_out;
  F_BP_OUT_t                   F_BP_out;
  logic fetch_en;
  logic inst_out_valid;
  logic get_fetch_buff;
  FB_DECODER_OUT_t FB_decoder_out;

  logic [3:0] num_inst;
`ifdef DEBUG
  logic       [`NUM_FL-1:0][$clog2(`NUM_PR)-1:0]                          FL_table, next_FL_table;
  logic       [$clog2(`NUM_FL)-1:0]                                       next_head;
  logic       [$clog2(`NUM_FL)-1:0]                                       next_tail;
  logic       [`NUM_SUPER-1:0]                                            RS_match_hit;
  logic       [`NUM_SUPER-1:0][$clog2(`NUM_FU)-1:0]                       RS_match_idx;
`endif

  assign en           = `TRUE;
  assign get_fetch_buff = ROB_valid && RS_valid && FL_valid && !rollback_en;
  assign dispatch_en  = get_fetch_buff && inst_out_valid;
  
  //assign F_decoder_en = fetch_en;
  //assign when an instruction retires/completed
  assign pipeline_completed_insts = num_inst;
  assign pipeline_error_status    = halt_out ? HALTED_ON_HALT :
                                    illegal_out  ? HALTED_ON_ILLEGAL:
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
`ifdef DEBUG
  always_comb begin
    case(retire_en)
      2'b00: num_inst = 0;
      2'b01, 2'b10: num_inst = 1;
      2'b11: num_inst = 2;
    endcase
  end
  always_comb begin
    for(int i = 0; i < `NUM_SUPER; i++) begin
      pipeline_commit_wr_idx[i] = ROB_Arch_Map_out.dest_idx[i];
      pipeline_commit_wr_data[i] = pipeline_PR[ROB_Arch_Map_out.T_idx[i]];
      pipeline_commit_wr_en[i] = (ROB_Arch_Map_out.T_idx[i] == 31)? 0 : retire_en[i];
      pipeline_commit_NPC[i] = retire_NPC[i];
    end
  end
`endif
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
    .Imem2proc_data(Icache_data_out),
    .Imem_valid(Icache_valid_out),
    .BP_F_out(BP_F_out),
    // Outputs
    .proc2Imem_addr(proc2Icache_addr),
    .if_PC_out(if_PC_out),
    .if_NPC_out(if_NPC_out), 
    .if_IR_out(if_IR_out),
    .if_target_out(if_target_out),
    .if_valid_inst_out(if_valid_inst_out),
    .F_BP_out(F_BP_out)
  );

  FETCH_BUFFER FETCH_BUFFER_0 (
    .en(en),
    .clock(clock),
    .reset(reset),
    .if_PC_out(if_PC_out),
    .if_NPC_out(if_NPC_out),
    .if_IR_out(if_IR_out),
    .if_target_out(if_target_out),
    .if_valid_inst_out(if_valid_inst_out),
    .get_next_inst(dispatch_en),
    .rollback_en(rollback_en),
`ifdef DEBUG
    .FB(pipeline_FB),
    .head(FB_head),
    .tail(FB_tail),
`endif
    .FB_decoder_out(FB_decoder_out),
    .inst_out_valid(inst_out_valid),
    .fetch_en(fetch_en)
  );

  Arch_Map arch_map_0 (
    .en(en),
    .clock(clock),
    .reset(reset),
    .retire_en(retire_en),
`ifndef DEBUG
    .ROB_Arch_Map_out(ROB_Arch_Map_out),
`else
    .ROB_Arch_Map_out(ROB_Arch_Map_out),
    .next_arch_map(pipeline_ARCHMAP),
`endif
    .ARCH_MAP_MAP_Table_out(ARCH_MAP_MAP_Table_out)
  );

  BP BP_0 (
    // inputs
    .clock(clock),
    .reset(reset),
    .if_NPC_out(if_NPC_out),
    .if_IR_out(if_IR_out),
    .F_BP_out(F_BP_out),
    .FU_BP_out(FU_BP_out),
    .ROB_idx(ROB_idx),
    .LQ_BP_out(LQ_BP_out),
    // outputs
    .rollback_en(rollback_en),
    .ROB_rollback_idx(ROB_rollback_idx),
    .FL_rollback_idx(FL_rollback_idx),
    .SQ_rollback_idx(SQ_rollback_idx),
    .LQ_rollback_idx(LQ_rollback_idx),
    .diff_ROB(diff_ROB),
    .BP_F_out(BP_F_out)
  );

  CDB cdb_0 (
    .en(en),
    .clock(clock),
    .reset(reset),
    .rollback_en(rollback_en),
    .ROB_rollback_idx(ROB_rollback_idx),
    .diff_ROB(diff_ROB),
    .FU_CDB_out(FU_CDB_out),
`ifdef DEBUG
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
    .FB_decoder_out(FB_decoder_out),
    .decoder_ROB_out(decoder_ROB_out),
    .decoder_RS_out(decoder_RS_out),
    .decoder_FL_out(decoder_FL_out),
    .decoder_Map_Table_out(decoder_Map_Table_out),
    .decoder_SQ_out(decoder_SQ_out),
    .decoder_LQ_out(decoder_LQ_out),
    .illegal(illegal)
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
`ifdef DEBUG
    .FL_table(pipeline_FL),
    .next_FL_table(next_FL_table),
    .head(FL_head),
    .next_head(next_head),
    .tail(FL_tail),
    .next_tail(next_tail),
`endif
    .FL_valid(FL_valid),
    .FL_idx(FL_idx),
    .FL_ROB_out(FL_ROB_out),
    .FL_RS_out(FL_RS_out),
    .FL_Map_Table_out(FL_Map_Table_out)
  );

  FU fu_0 (
    // Input
    .clock(clock),
    .reset(reset),
    .en(en),
    // .ROB_idx(ROB_idx),
    .rollback_en(rollback_en),
    .ROB_rollback_idx(ROB_rollback_idx),
    .diff_ROB(diff_ROB),
    .CDB_valid(CDB_valid),
    .LQ_valid(LQ_valid),
    .RS_FU_out(RS_FU_out),
    .PR_FU_out(PR_FU_out),
    .SQ_FU_out(SQ_FU_out),
    .LQ_FU_out(LQ_FU_out),
    // Output
    .FU_valid(FU_valid),
    .FU_CDB_out(FU_CDB_out),
    .FU_SQ_out(FU_SQ_out),
    .FU_LQ_out(FU_LQ_out),
    .FU_BP_out(FU_BP_out)
  );

  LSQ lsq_0 (
    // Input
    .clock(clock),
    .reset(reset),
    .en(en),
    .dispatch_en(dispatch_en),
    .rollback_en(rollback_en),
    .retire_en(retire_en),
    .ROB_idx(ROB_idx),
    .FL_idx(FL_idx),
    .CDB_SQ_valid(CDB_SQ_valid),        // TODO
    .CDB_LQ_valid(CDB_LQ_valid),        // TODO
    .SQ_rollback_idx(SQ_rollback_idx),
    .LQ_rollback_idx(LQ_rollback_idx),
    .ROB_rollback_idx(ROB_rollback_idx),
    .diff_ROB(diff_ROB),
    .decoder_SQ_out(decoder_SQ_out),
    .decoder_LQ_out(decoder_LQ_out),
    .D_cache_SQ_out(D_cache_SQ_out),    // To be modified
    .D_cache_LQ_out(D_cache_LQ_out),    // To be modified
    .FU_SQ_out(FU_SQ_out),              // TODO
    .FU_LQ_out(FU_LQ_out),              // TODO
    .ROB_SQ_out(ROB_SQ_out),            // TODO
    .ROB_LQ_out(ROB_LQ_out),            // TODO
    // Output
    .LSQ_valid(LSQ_valid),
    .LQ_valid(LQ_valid),                // TODO
    .SQ_idx(SQ_idx),
    .LQ_idx(LQ_idx),
    .SQ_ROB_out(SQ_ROB_out),            // TODO
    .SQ_FU_out(SQ_FU_out),              // TODO
    .LQ_FU_out(LQ_FU_out),              // TODO
    .SQ_D_cache_out(SQ_D_cache_out),
    .LQ_D_cache_out(LQ_D_cache_out),
    .LQ_BP_out(LQ_BP_out)
  );

  Map_Table map_table_0 (
    // Input
    .clock(clock),
    .reset(reset),
    .en(en),
    .dispatch_en(dispatch_en),
    .rollback_en(rollback_en),
    .complete_en(complete_en),
    .ROB_rollback_idx(ROB_rollback_idx),
    .ROB_idx(ROB_idx),
    .decoder_Map_Table_out(decoder_Map_Table_out),
    .FL_Map_Table_out(FL_Map_Table_out),
    .CDB_Map_Table_out(CDB_Map_Table_out),
    .ARCH_MAP_MAP_Table_out(ARCH_MAP_MAP_Table_out),
`ifdef DEBUG
    .map_table_out(pipeline_MAPTABLE),
`endif
    .Map_Table_ROB_out(Map_Table_ROB_out),
    .Map_Table_RS_out(Map_Table_RS_out)
  );

  PR pr_0 (
    .clock(clock),
    .reset(reset),
    .en(en),
    .write_en(write_en),
    .CDB_PR_out(CDB_PR_out),
    .RS_PR_out(RS_PR_out),
`ifdef DEBUG
    .pr_data(pipeline_PR),
`endif
    .PR_FU_out(PR_FU_out)
  );

  ROB rob_0 (
    .clock(clock),
    .reset(reset),
    .en(en),
    .dispatch_en(dispatch_en),
    .complete_en(complete_en),
    .rollback_en(rollback_en),
    .ROB_rollback_idx(ROB_rollback_idx),
    .decoder_ROB_out(decoder_ROB_out),
    .FL_ROB_out(FL_ROB_out),
    .Map_Table_ROB_out(Map_Table_ROB_out),
    .CDB_ROB_out(CDB_ROB_out),
    .SQ_ROB_out(SQ_ROB_out),
`ifdef DEBUG
    .rob(pipeline_ROB),
    .retire_NPC(retire_NPC),
`endif
    .ROB_valid(ROB_valid),
    .retire_en(retire_en),
    .halt_out(halt_out),
    .illegal_out(illegal_out),
    .ROB_idx(ROB_idx),
    .ROB_Arch_Map_out(ROB_Arch_Map_out),
    .ROB_FL_out(ROB_FL_out),
    .ROB_SQ_out(ROB_SQ_out),
    .ROB_LQ_out(ROB_LQ_out)
  );

  RS rs_0 (
    // Input
    .clock(clock),
    .reset(reset),
    .en(en),
    .dispatch_en(dispatch_en),
    .rollback_en(rollback_en),
    .complete_en(complete_en),
    .FU_valid(FU_valid),
    .ROB_rollback_idx(ROB_rollback_idx),
    .diff_ROB(diff_ROB),
    .ROB_idx(ROB_idx),
    .FL_idx(FL_idx),
    .SQ_idx(SQ_idx),
    .LQ_idx(LQ_idx),
    .decoder_RS_out(decoder_RS_out),
    .FL_RS_out(FL_RS_out),
    .Map_Table_RS_out(Map_Table_RS_out),
    .CDB_RS_out(CDB_RS_out),
    // Output
`ifdef DEBUG
    .RS_out(pipeline_RS),
    .RS_match_hit(RS_match_hit),   // If a RS entry is ready
    .RS_match_idx(RS_match_idx),
`endif
    .RS_valid(RS_valid),
    .RS_FU_out(RS_FU_out),
    .RS_PR_out(RS_PR_out)
  );
endmodule  // module verisimple
