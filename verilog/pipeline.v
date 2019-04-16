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
  output SQ_ENTRY_t       [`NUM_LSQ-1:0]                 pipeline_SQ,
  output logic            [$clog2(`NUM_LSQ)-1:0]         SQ_head,
  output logic            [$clog2(`NUM_LSQ)-1:0]         SQ_tail,
  output LQ_ENTRY_t       [`NUM_LSQ-1:0]                 pipeline_LQ,
  output logic            [$clog2(`NUM_LSQ)-1:0]         LQ_head,
  output logic            [$clog2(`NUM_LSQ)-1:0]         LQ_tail,
// 
  output D_CACHE_LINE_t [`NUM_WAY-1:0][`NUM_IDX-1:0]     Dcache_bank,
  output MSHR_ENTRY_t   [`MSHR_DEPTH-1:0]                MSHR_queue,
  output logic          [$clog2(`MSHR_DEPTH)-1:0]        MSHR_writeback_head,
  output logic          [$clog2(`MSHR_DEPTH)-1:0]        MSHR_head,
  output logic          [$clog2(`MSHR_DEPTH)-1:0]        MSHR_tail,
`endif
  output logic        [`NUM_SUPER-1:0][4:0]              pipeline_commit_wr_idx,
  output logic        [`NUM_SUPER-1:0][63:0]             pipeline_commit_wr_data,
  output logic        [`NUM_SUPER-1:0]                   pipeline_commit_wr_en,
  output logic        [`NUM_SUPER-1:0][63:0]             pipeline_commit_NPC,
  output logic        [1:0]                              proc2mem_command,    // command sent to memory
  output logic        [63:0]                             proc2mem_addr,      // Address sent to memory
  output logic        [63:0]                             proc2mem_data,      // Data sent to memory
  output logic        [3:0]                              pipeline_completed_insts,
  output ERROR_CODE                                      pipeline_error_status,
  output logic                                           stop_cycle
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
  logic                   [`NUM_ST-1:0]          CDB_SQ_valid;
  logic                   [`NUM_LD-1:0]          CDB_LQ_valid;
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
  ROB_SQ_OUT_t                                   ROB_SQ_out;
  ROB_LQ_OUT_t                                   ROB_LQ_out;
`ifndef DEBUG
  logic                                          ROB_valid;
`endif
  logic                   [`NUM_SUPER-1:0]       retire_en;
  logic                   [`NUM_SUPER-1:0]       halt_out;
  logic                   [`NUM_SUPER-1:0]       illegal_out;
  logic            [`NUM_SUPER-1:0][$clog2(`NUM_ROB)-1:0] ROB_idx;
  ROB_ARCH_MAP_OUT_t                             ROB_Arch_Map_out;
  ROB_MAP_TABLE_OUT_t                            ROB_MAP_Table_out;
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
// `ifdef DEBUG
//   SQ_ENTRY_t       [`NUM_LSQ-1:0]                         SQ_table;
//   logic            [$clog2(`NUM_LSQ)-1:0]                 SQ_head;
//   logic            [$clog2(`NUM_LSQ)-1:0]                 SQ_tail;
//   LQ_ENTRY_t                                              LQ_table;
//   logic            [$clog2(`NUM_LSQ)-1:0]                 LQ_head;
//   logic            [$clog2(`NUM_LSQ)-1:0]                 LQ_tail;
// `endif
  LQ_BP_OUT_t                                    LQ_BP_out;
  logic                   [$clog2(`NUM_LSQ)-1:0] SQ_rollback_idx;
  logic                   [$clog2(`NUM_LSQ)-1:0] LQ_rollback_idx;
  logic            [`NUM_SUPER-1:0][$clog2(`NUM_FL)-1:0] FL_idx;
  logic            [`NUM_SUPER-1:0][$clog2(`NUM_LSQ)-1:0] SQ_idx;
  logic            [`NUM_SUPER-1:0][$clog2(`NUM_LSQ)-1:0] LQ_idx;
  logic            [`NUM_SUPER-1:0]                      LQ_valid;
  SQ_FU_OUT_t                                            SQ_FU_out;
  LQ_FU_OUT_t                                            LQ_FU_out;
  SQ_ROB_OUT_t                                           SQ_ROB_out;
  SQ_D_CACHE_OUT_t                                       SQ_D_cache_out;
  LQ_D_CACHE_OUT_t                                       LQ_D_cache_out;


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
  logic [3:0]  Dmem2proc_response;
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

  logic [63:0] rd1_data;
  logic rd1_hit;
  logic wr1_hit;
  logic evicted_dirty;
  logic evicted_valid;
  SASS_ADDR evicted_addr;
  logic [63:0] evicted_data;
  logic wr1_en, wr1_dirty, wr1_from_mem, wr1_valid;
  SASS_ADDR rd1_addr,wr1_addr;
  logic [63:0] wr1_data;
  logic mshr_valid;
  logic mshr_empty;
  logic [1:0] miss_addr_hit;
  logic mem_wr;
  logic mem_dirty;
  logic [63:0] mem_data;
  SASS_ADDR mem_addr;
  logic rd_wb_en;
  logic rd_wb_dirty;
  logic [63:0] rd_wb_data;
  SASS_ADDR rd_wb_addr;
  logic wr_wb_en;
  logic wr_wb_dirty;
  logic [63:0] wr_wb_data;
  SASS_ADDR wr_wb_addr;
  logic [2:0]           miss_en;
  SASS_ADDR [2:0]       miss_addr;
  logic [2:0][63:0]     miss_data_in;
  MSHR_INST_TYPE [2:0]  inst_type;
  logic [2:0][1:0]      mshr_proc2mem_command;
  SASS_ADDR [1:0]       search_addr;
  MSHR_INST_TYPE [1:0]  search_type;
  logic [63:0]          search_wr_data;
  logic [1:0]           search_en;
  logic                 stored_rd_wb;
  logic                 stored_wr_wb;
  logic                 stored_mem_wr;
  logic                 write_back;
  logic                 write_back_stage;
  logic                 cache_valid;
  logic                 halt_pipeline;
  logic                 illegal_out_pipeline;
  logic                 fetch_en_in;

  assign en           = `TRUE;
  assign get_fetch_buff = ROB_valid && RS_valid && FL_valid && !rollback_en;
  assign dispatch_en  = get_fetch_buff && inst_out_valid;

  assign stop_cycle = halt_out[0] | halt_out[1];
  
  assign write_back = halt_out[0] | halt_out[1];
  //assign F_decoder_en = fetch_en;
  //assign when an instruction retires/completed
  assign pipeline_completed_insts = num_inst;
  assign pipeline_error_status    = halt_pipeline ? HALTED_ON_HALT :
                                    illegal_out_pipeline ? HALTED_ON_ILLEGAL:
                                               NO_ERROR;

  assign illegal_out_pipeline = illegal_out[0] || (~halt_out[0] & illegal_out[1]);
  // assign proc2Dmem_command = BUS_NONE;
  // assign proc2Dmem_addr = 0;
  assign proc2mem_command =
    (proc2Dmem_command==BUS_NONE) ? proc2Imem_command:proc2Dmem_command;
  assign proc2mem_addr =
    (proc2Dmem_command==BUS_NONE) ? proc2Imem_addr:proc2Dmem_addr;
  //TODO: Uncomment and pass for mem stage in the pipeline
  assign Dmem2proc_response = 
    (proc2Dmem_command==BUS_NONE) ? 0 : mem2proc_response;
  assign Imem2proc_response = (proc2Dmem_command==BUS_NONE) ? mem2proc_response : 0;

  assign fetch_en_in = fetch_en & (proc2Dmem_command==BUS_NONE);
`ifdef DEBUG
  always_comb begin
    if(write_back_stage)begin
      num_inst = 0;
    end   
    else if(write_back) begin
      if(halt_out[0] & !halt_out[1])
        num_inst = 1;
      else if(!halt_out[0] & halt_out[1])
        num_inst = 2;
    end
    else begin
      case(retire_en)
        2'b00: num_inst = 0;
        2'b01, 2'b10: num_inst = 1;
        2'b11: num_inst = 2;
      endcase
    end
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
    .clock     (clock),
    .reset     (reset),
    .wr1_en    (Icache_wr_en),
    .wr1_idx   (Icache_wr_idx),
    .wr1_tag   (Icache_wr_tag),
    .wr1_data  (mem2proc_data),
    .rd1_idx   (Icache_rd_idx),
    .rd1_tag   (Icache_rd_tag),
    // outputs
    .rd1_data  (cachemem_data),
    .rd1_valid (cachemem_valid)
  );

  // Cache controller
  icache icache_0(
    // inputs 
    .clock              (clock),
    .reset              (reset),
    .Imem2proc_response (Imem2proc_response),
    .Imem2proc_data     (mem2proc_data),
    .Imem2proc_tag      (mem2proc_tag),
    .proc2Icache_addr   (proc2Icache_addr),
    .cachemem_data      (cachemem_data),
    .cachemem_valid     (cachemem_valid),
    // outputs
    .proc2Imem_command  (proc2Imem_command),
    .proc2Imem_addr     (proc2Imem_addr),
    .Icache_data_out    (Icache_data_out),
    .Icache_valid_out   (Icache_valid_out),
    .current_index      (Icache_rd_idx),
    .current_tag        (Icache_rd_tag),
    .last_index         (Icache_wr_idx),
    .last_tag           (Icache_wr_tag),
    .data_write_enable  (Icache_wr_en)
  );

  //D cache modules
  Dcache_controller dcache_controller (
    .clock(clock),
    .reset(reset),
    //proc to cache            
    .sq_d_cache_out(SQ_D_cache_out),
    .lq_d_cache_out(LQ_D_cache_out),

    //cache to proc                                 
    .d_cache_lq_out(D_cache_LQ_out),
    .d_cache_sq_out(D_cache_SQ_out), // tells if a store can be moved on.

    //Dcachemem to cache                                  
    .rd1_data(rd1_data),
    .rd1_hit(rd1_hit),
    .wr1_hit(wr1_hit),
    .evicted_dirty(evicted_dirty),
    .evicted_valid(evicted_valid),
    .evicted_addr(evicted_addr),
    .evicted_data(evicted_data),

    // cache to Dcachemem                       
    .wr1_en(wr1_en),
    .wr1_dirty(wr1_dirty),
    .wr1_from_mem(wr1_from_mem),
    .wr1_valid(wr1_valid),
    .rd1_addr(rd1_addr),
    .wr1_addr(wr1_addr),
    .wr1_data(wr1_data),

    //MSHR to cache                                 
    .mshr_valid(mshr_valid),
    .mshr_empty(mshr_empty),

    .miss_addr_hit(miss_addr_hit),

    .mem_wr(mem_wr),
    .mem_dirty(mem_dirty),
    .mem_data(mem_data),
    .mem_addr(mem_addr),

    .rd_wb_en(rd_wb_en),
    .rd_wb_dirty(rd_wb_dirty),
    .rd_wb_data(rd_wb_data),
    .rd_wb_addr(rd_wb_addr),

    .wr_wb_en(wr_wb_en),
    .wr_wb_dirty(wr_wb_dirty),
    .wr_wb_data(wr_wb_data),
    .wr_wb_addr(wr_wb_addr),

    //cache to MSHR (loading)                                 
    .miss_en(miss_en),
    .miss_addr(miss_addr),
    .miss_data_in(miss_data_in),
    .inst_type(inst_type),
    .mshr_proc2mem_command(mshr_proc2mem_command),
    //cache to MSHR (searching)                                 
    .search_addr(search_addr),
    .search_type(search_type),
    .search_wr_data(search_wr_data),
    .search_en(search_en),
    //cache to MSHR (Written back)                      
    .stored_rd_wb(stored_rd_wb),
    .stored_wr_wb(stored_wr_wb),
    .stored_mem_wr(stored_mem_wr),
    .write_back(write_back),
    .cache_valid(cache_valid),
    .halt_pipeline(halt_pipeline),
    .write_back_stage(write_back_stage)
);

  Dcache dcache_0 (
    .clock(clock),
    .reset(reset),
    //enable signals 
    .wr1_en(wr1_en),
    .wr1_from_mem(wr1_from_mem),
    //addr from proc
    .rd1_addr(rd1_addr),
    .wr1_addr(wr1_addr),
    .rd1_data_out(rd1_data),
    .rd1_hit_out(rd1_hit),
    .wr1_hit_out(wr1_hit),
    .wr1_data(wr1_data),
    .wr1_dirty(wr1_dirty),
    .wr1_valid(wr1_valid),
  `ifdef DEBUG
    .cache_bank(Dcache_bank),
  `endif
    .evicted_dirty_out(evicted_dirty), 
    .evicted_valid_out(evicted_valid),
    .evicted_addr_out(evicted_addr),
    .evicted_data_out(evicted_data)
  );

  MSHR mshr_0 (
    .clock(clock),
    .reset(reset),
        
    //stored to cache input      
    .stored_rd_wb(stored_rd_wb),
    .stored_wr_wb(stored_wr_wb),
    .stored_mem_wr(stored_mem_wr),
        
    //storing to the MSHR      
    .miss_en(miss_en),
    .miss_addr(miss_addr),
    .miss_data_in(miss_data_in),
    .inst_type(inst_type),
    .mshr_proc2mem_command(mshr_proc2mem_command),
        
    //looking up the MSHR      
    .search_addr(search_addr), //address to search
    .search_type(search_type), //address search type (might not need)
    .search_wr_data(search_wr_data),
    .search_en(search_en),
        
`ifdef DEBUG
    .MSHR_queue(MSHR_queue),
    .writeback_head(MSHR_writeback_head),
    .head(MSHR_head),
    .tail(MSHR_tail),
`endif
    .miss_addr_hit(miss_addr_hit), // if address search in the MSHR
        
    .mem_wr(mem_wr),
    .mem_dirty(mem_dirty),
    .mem_data(mem_data),
    .mem_addr(mem_addr),
  
    .rd_wb_en(rd_wb_en),
    .rd_wb_dirty(rd_wb_dirty),
    .rd_wb_data(rd_wb_data),
    .rd_wb_addr(rd_wb_addr),
  
    .wr_wb_en(wr_wb_en),
    .wr_wb_dirty(wr_wb_dirty),
    .wr_wb_data(wr_wb_data),
    .wr_wb_addr(wr_wb_addr),
  
    //mshr to cache      
    .mshr_valid(mshr_valid),
    .mshr_empty(mshr_empty),
  
    //mem to mshr
    .mem2proc_response(Dmem2proc_response),
    .mem2proc_data(mem2proc_data),     // data resulting from a load
    .mem2proc_tag(mem2proc_tag),       // 0 = no value, other=tag of transaction
  
    //cache to mshr
    .proc2mem_addr(proc2Dmem_addr),
    .proc2mem_data(proc2mem_data),
    .proc2mem_command(proc2Dmem_command)
  );

  F_stage F_stage_0 (
    // Inputs
    .clock             (clock),
    .reset             (reset),
    .get_next_inst     (fetch_en_in), //only go to next insn when high
    .Imem2proc_data    (Icache_data_out),
    .Imem_valid        (Icache_valid_out),
    .BP_F_out          (BP_F_out),
    // Outputs
    .proc2Imem_addr    (proc2Icache_addr),
    .if_PC_out         (if_PC_out),
    .if_NPC_out        (if_NPC_out), 
    .if_IR_out         (if_IR_out),
    .if_target_out     (if_target_out),
    .if_valid_inst_out (if_valid_inst_out),
    .F_BP_out          (F_BP_out)
  );

  FETCH_BUFFER FETCH_BUFFER_0 (
    .clock             (clock),
    .reset             (reset),
    .en                (en),
    .if_PC_out         (if_PC_out),
    .if_NPC_out        (if_NPC_out),
    .if_IR_out         (if_IR_out),
    .if_target_out     (if_target_out),
    .if_valid_inst_out (if_valid_inst_out),
    .get_next_inst     (dispatch_en),
    .rollback_en       (rollback_en),
`ifdef DEBUG
    .FB                (pipeline_FB),
    .head              (FB_head),
    .tail              (FB_tail),
`endif
    .FB_decoder_out    (FB_decoder_out),
    .inst_out_valid    (inst_out_valid),
    .fetch_en          (fetch_en)
  );

  Arch_Map arch_map_0 (
    .clock                  (clock),
    .reset                  (reset),
    .en                     (en),
    .retire_en              (retire_en),
    .ROB_Arch_Map_out       (ROB_Arch_Map_out),
`ifdef DEBUG
    .next_arch_map          (pipeline_ARCHMAP),
`endif
    .ARCH_MAP_MAP_Table_out (ARCH_MAP_MAP_Table_out)
  );

  BP BP_0 (
    // inputs
    .clock            (clock),
    .reset            (reset),
    .if_NPC_out       (if_NPC_out),
    .if_IR_out        (if_IR_out),
    .F_BP_out         (F_BP_out),
    .FU_BP_out        (FU_BP_out),
    .ROB_idx          (ROB_idx),
    .LQ_BP_out        (LQ_BP_out),
    // outputs
    .rollback_en      (rollback_en),
    .ROB_rollback_idx (ROB_rollback_idx),
    .FL_rollback_idx  (FL_rollback_idx),
    .SQ_rollback_idx  (SQ_rollback_idx),
    .LQ_rollback_idx  (LQ_rollback_idx),
    .diff_ROB         (diff_ROB),
    .BP_F_out         (BP_F_out)
  );

  CDB cdb_0 (
    .clock             (clock),
    .reset             (reset),
    .en                (en),
    .rollback_en       (rollback_en),
    .ROB_rollback_idx  (ROB_rollback_idx),
    .diff_ROB          (diff_ROB),
    .FU_CDB_out        (FU_CDB_out),
`ifdef DEBUG
    .CDB               (pipeline_CDB),
`endif
    .write_en          (write_en),
    .complete_en       (complete_en),
    .CDB_valid         (CDB_valid),
    .CDB_SQ_valid      (CDB_SQ_valid),
    .CDB_LQ_valid      (CDB_LQ_valid),
    .CDB_ROB_out       (CDB_ROB_out),
    .CDB_RS_out        (CDB_RS_out),
    .CDB_Map_Table_out (CDB_Map_Table_out),
    .CDB_PR_out        (CDB_PR_out)
  );

  decoder decoder_0 (
    .FB_decoder_out        (FB_decoder_out),
    .decoder_ROB_out       (decoder_ROB_out),
    .decoder_RS_out        (decoder_RS_out),
    .decoder_FL_out        (decoder_FL_out),
    .decoder_Map_Table_out (decoder_Map_Table_out),
    .decoder_SQ_out        (decoder_SQ_out),
    .decoder_LQ_out        (decoder_LQ_out)
    // .illegal               (illegal)
  );

  FL fl_0 (
    .clock            (clock),
    .reset            (reset),
    .dispatch_en      (dispatch_en),
    .rollback_en      (rollback_en),
    .retire_en        (retire_en),
    .FL_rollback_idx  (FL_rollback_idx),
    .decoder_FL_out   (decoder_FL_out),
    .ROB_FL_out       (ROB_FL_out),
`ifdef DEBUG
    .FL_table         (pipeline_FL),
    .next_FL_table    (next_FL_table),
    .head             (FL_head),
    .next_head        (next_head),
    .tail             (FL_tail),
    .next_tail        (next_tail),
`endif
    .FL_valid         (FL_valid),
    .FL_idx           (FL_idx),
    .FL_ROB_out       (FL_ROB_out),
    .FL_RS_out        (FL_RS_out),
    .FL_Map_Table_out (FL_Map_Table_out)
  );

  FU fu_0 (
    // Input
    .clock            (clock),
    .reset            (reset),
    .en               (en),
    .rollback_en      (rollback_en),
    .ROB_rollback_idx (ROB_rollback_idx),
    .diff_ROB         (diff_ROB),
    .CDB_valid        (CDB_valid),
    .LQ_valid         (LQ_valid),
    .RS_FU_out        (RS_FU_out),
    .PR_FU_out        (PR_FU_out),
    .SQ_FU_out        (SQ_FU_out),
    .LQ_FU_out        (LQ_FU_out),
    // Output
    .FU_valid         (FU_valid),
    .FU_CDB_out       (FU_CDB_out),
    .FU_SQ_out        (FU_SQ_out),
    .FU_LQ_out        (FU_LQ_out),
    .FU_BP_out        (FU_BP_out)
  );

  LSQ lsq_0 (
    // Input
    .clock            (clock),
    .reset            (reset),
    .en               (en),
    .dispatch_en      (dispatch_en),
    .rollback_en      (rollback_en),
    .retire_en        (retire_en),
    .ROB_idx          (ROB_idx),
    .FL_idx           (FL_idx),
    .CDB_SQ_valid     (CDB_SQ_valid),        // TODO
    .CDB_LQ_valid     (CDB_LQ_valid),        // TODO
    .SQ_rollback_idx  (SQ_rollback_idx),
    .LQ_rollback_idx  (LQ_rollback_idx),
    .ROB_rollback_idx (ROB_rollback_idx),
    .diff_ROB         (diff_ROB),
    .decoder_SQ_out   (decoder_SQ_out),
    .decoder_LQ_out   (decoder_LQ_out),
    .D_cache_SQ_out   (D_cache_SQ_out),    // To be modified
    .D_cache_LQ_out   (D_cache_LQ_out),    // To be modified
    .FU_SQ_out        (FU_SQ_out),              // TODO
    .FU_LQ_out        (FU_LQ_out),              // TODO
    .ROB_SQ_out       (ROB_SQ_out),            // TODO
    .ROB_LQ_out       (ROB_LQ_out),            // TODO
    // Output
`ifdef DEBUG
    .SQ_table         (pipeline_SQ),
    .SQ_head          (SQ_head),
    .SQ_tail          (SQ_tail),
    .LQ_table         (pipeline_LQ),
    .LQ_head          (LQ_head),
    .LQ_tail          (LQ_tail),
`endif
    .LSQ_valid        (LSQ_valid),
    .LQ_valid         (LQ_valid),                // TODO
    .SQ_idx           (SQ_idx),
    .LQ_idx           (LQ_idx),
    .SQ_ROB_out       (SQ_ROB_out),            // TODO
    .SQ_FU_out        (SQ_FU_out),              // TODO
    .LQ_FU_out        (LQ_FU_out),              // TODO
    .SQ_D_cache_out   (SQ_D_cache_out),
    .LQ_D_cache_out   (LQ_D_cache_out),
    .LQ_BP_out        (LQ_BP_out)
  );

  Map_Table map_table_0 (
    // Input
    .clock                  (clock),
    .reset                  (reset),
    .en                     (en),
    .dispatch_en            (dispatch_en),
    .rollback_en            (rollback_en),
    .complete_en            (complete_en),
    .ROB_rollback_idx       (ROB_rollback_idx),
    .ROB_idx                (ROB_idx),
    .decoder_Map_Table_out  (decoder_Map_Table_out),
    .FL_Map_Table_out       (FL_Map_Table_out),
    .CDB_Map_Table_out      (CDB_Map_Table_out),
    .ARCH_MAP_MAP_Table_out (ARCH_MAP_MAP_Table_out),
    .ROB_MAP_Table_out      (ROB_MAP_Table_out),
`ifdef DEBUG
    .map_table_out          (pipeline_MAPTABLE),
`endif
    .Map_Table_ROB_out      (Map_Table_ROB_out),
    .Map_Table_RS_out       (Map_Table_RS_out)
  );

  PR pr_0 (
    .clock      (clock),
    .reset      (reset),
    .en         (en),
    .write_en   (write_en),
    .CDB_PR_out (CDB_PR_out),
    .RS_PR_out  (RS_PR_out),
`ifdef DEBUG
    .pr_data    (pipeline_PR),
`endif
    .PR_FU_out  (PR_FU_out)
  );

  ROB rob_0 (
    .clock             (clock),
    .reset             (reset),
    .en                (en),
    .dispatch_en       (dispatch_en),
    .complete_en       (complete_en),
    .rollback_en       (rollback_en),
    .ROB_rollback_idx  (ROB_rollback_idx),
    .decoder_ROB_out   (decoder_ROB_out),
    .FL_ROB_out        (FL_ROB_out),
    .Map_Table_ROB_out (Map_Table_ROB_out),
    .CDB_ROB_out       (CDB_ROB_out),
    .SQ_ROB_out        (SQ_ROB_out),
`ifdef DEBUG
    .rob               (pipeline_ROB),
    .retire_NPC        (retire_NPC),
`endif
    .ROB_valid         (ROB_valid),
    .retire_en         (retire_en),
    .halt_out          (halt_out),
    .illegal_out       (illegal_out),
    .ROB_idx           (ROB_idx),
    .ROB_Arch_Map_out  (ROB_Arch_Map_out),
    .ROB_MAP_Table_out (ROB_MAP_Table_out),
    .ROB_FL_out        (ROB_FL_out),
    .ROB_SQ_out        (ROB_SQ_out),
    .ROB_LQ_out        (ROB_LQ_out)
  );

  RS rs_0 (
    // Input
    .clock            (clock),
    .reset            (reset),
    .en               (en),
    .dispatch_en      (dispatch_en),
    .rollback_en      (rollback_en),
    .complete_en      (complete_en),
    .FU_valid         (FU_valid),
    .ROB_rollback_idx (ROB_rollback_idx),
    .diff_ROB         (diff_ROB),
    .ROB_idx          (ROB_idx),
    .FL_idx           (FL_idx),
    .SQ_idx           (SQ_idx),
    .LQ_idx           (LQ_idx),
    .decoder_RS_out   (decoder_RS_out),
    .FL_RS_out        (FL_RS_out),
    .Map_Table_RS_out (Map_Table_RS_out),
    .CDB_RS_out       (CDB_RS_out),
    // Output
`ifdef DEBUG
    .RS_out           (pipeline_RS),
    .RS_match_hit     (RS_match_hit),   // If a RS entry is ready
    .RS_match_idx     (RS_match_idx),
`endif
    .RS_valid         (RS_valid),
    .RS_FU_out        (RS_FU_out),
    .RS_PR_out        (RS_PR_out)
  );
endmodule  // module verisimple
