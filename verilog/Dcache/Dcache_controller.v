`timescale 1ns/100ps

module Dcache_controller(
    input logic                                                                   clock, reset,
    //proc to cache            
    input SQ_D_CACHE_OUT_t                                                        sq_d_cache_out,
    input LQ_D_CACHE_OUT_t                                                        lq_d_cache_out,

    //cache to proc                                 
    output D_CACHE_LQ_OUT_t                                                       d_cache_lq_out,
    output D_CACHE_SQ_OUT_t                                                       d_cache_sq_out, // tells if a store can be moved on.

`ifdef DEBUG
    output logic [63:0]                                    count,
    output MSHR_ENTRY_t   [`MSHR_DEPTH-1:0]                MSHR_queue,
    output logic          [$clog2(`MSHR_DEPTH)-1:0]        MSHR_writeback_head,
    output logic          [$clog2(`MSHR_DEPTH)-1:0]        MSHR_head,
    output logic          [$clog2(`MSHR_DEPTH)-1:0]        MSHR_tail,
    output D_CACHE_LINE_t [`NUM_WAY-1:0][`NUM_IDX-1:0]     Dcache_bank,
    output logic [`NUM_IDX-1:0][`NUM_WAY-1:0]              LRU_bank_sel,
`endif

    input logic [3:0]                                                             mem2proc_response,
    input logic [63:0]                                                            mem2proc_data,     // data resulting from a load
    input logic [3:0]                                                             mem2proc_tag,       // 0 = no value, other=tag of transaction
    //cache to mshr
    output logic [63:0]                                                           proc2mem_addr,
    output logic [63:0]                                                           proc2mem_data,
    output logic [1:0]                                                            proc2mem_command,

    input  logic                                                                  write_back,
    // output logic                                                                  cache_valid,
    output logic                                                                  halt_pipeline,
    output logic                                                                  write_back_stage
);
//logics

`ifndef DEBUG
    logic [63:0]                   count;
`endif

logic [1:0] state, next_state;
logic [63:0] next_count;
SASS_ADDR write_back_addr;
// logic write_back_stage;
logic mshr_valid;
logic mshr_empty;
logic wr1_strictly_from_mem;

logic [63:0]       rd1_data;
logic              rd1_hit, wr1_hit;
logic              evicted_dirty;
logic              evicted_valid;
SASS_ADDR          evicted_addr;
logic [63:0]       evicted_data;                     
logic              wr1_en, wr1_dirty, wr1_from_mem, wr1_valid;
SASS_ADDR          rd1_addr, wr1_addr;
logic [63:0]       wr1_data;
logic              rd1_search;
logic              wr1_search;
logic              stored_rd_wb;
logic              stored_mem_wr;


D_CACHE_MSHR_OUT_t d_cache_mshr_out, next_d_cache_mshr_out;

MSHR_D_CACHE_OUT_t mshr_d_cache_out, next_mshr_d_cache_out;

Dcache dcache_0 (
    .clock(clock),
    .reset(reset),
    //enable signals 
    .wr1_en(wr1_en),
    .wr1_from_mem(wr1_strictly_from_mem),
    //addr from proc
    .rd1_addr(rd1_addr),
    .wr1_addr(wr1_addr),
    .rd1_data_out(rd1_data),
    .rd1_hit_out(rd1_hit),
    .wr1_hit_out(wr1_hit),
    .wr1_data(wr1_data),
    .wr1_dirty(wr1_dirty),
    .wr1_valid(wr1_valid),
    .rd1_search(rd1_search),
    .wr1_search(wr1_search),
  `ifdef DEBUG
    .cache_bank(Dcache_bank),
    .LRU_bank_sel(LRU_bank_sel),
  `endif
    .evicted_dirty_out(evicted_dirty), 
    .evicted_valid_out(evicted_valid),
    .evicted_addr_out(evicted_addr),
    .evicted_data_out(evicted_data)
  );

  MSHR mshr_0 (
    .clock(clock),
    .reset(reset),
    .d_cache_mshr_out(d_cache_mshr_out),
    // .stored_rd_wb(stored_rd_wb),
    .stored_mem_wr(stored_mem_wr),
`ifdef DEBUG
    .MSHR_queue(MSHR_queue),
    .writeback_head(MSHR_writeback_head),
    .head(MSHR_head),
    .tail(MSHR_tail),
`endif
    .mshr_d_cache_out(next_mshr_d_cache_out),
    .mshr_valid(mshr_valid),
    .mshr_empty(mshr_empty),
    //mem to mshr
    .mem2proc_response(mem2proc_response),
    .mem2proc_data(mem2proc_data),     // data resulting from a load
    .mem2proc_tag(mem2proc_tag),       // 0 = no value, other=tag of transaction
    //cache to mshr
    .proc2mem_addr(proc2mem_addr),
    .proc2mem_data(proc2mem_data),
    .proc2mem_command(proc2mem_command)
  );

//read cache outputs
//output d_cache_lq_out.value from mshr if exist otherwise from cache
assign d_cache_lq_out.value = rd1_data; 

//d_cache_lq_out.value is valid if it is read and if d_cache_lq_out.value is either in cache or mshr
assign d_cache_lq_out.valid = rd1_hit;

assign d_cache_sq_out.valid = ((wr1_hit & sq_d_cache_out.wr_en) || next_d_cache_mshr_out.miss_en[1]) & mshr_valid; // We think it is always 1

//Signals to MSHR

//if not in cache, enable to push d_cache_lq_out.value to the MSHR
assign next_d_cache_mshr_out.miss_en[0] = lq_d_cache_out.rd_en & !rd1_hit & mshr_valid;
//Miss from stores
assign next_d_cache_mshr_out.miss_en[1] = sq_d_cache_out.wr_en & !wr1_hit & mshr_valid;
//Store inst from evicts
assign next_d_cache_mshr_out.miss_en[2] = wr1_from_mem & evicted_dirty & evicted_valid;// when wr1 is from memory and it is dirty

//d_cache_lq_out.value sent to MSHR search
assign next_d_cache_mshr_out.miss_addr[0] = rd1_addr;
assign next_d_cache_mshr_out.miss_data_in[0] = {64'hDEADBEEFDEADBEEF};
assign next_d_cache_mshr_out.inst_type[0] = LOAD;
assign next_d_cache_mshr_out.mshr_proc2mem_command[0] = BUS_LOAD;
assign next_d_cache_mshr_out.miss_dirty[0] = 0;

assign next_d_cache_mshr_out.miss_addr[1] = {sq_d_cache_out.addr,3'b000};
assign next_d_cache_mshr_out.miss_data_in[1]= sq_d_cache_out.value;
assign next_d_cache_mshr_out.inst_type[1] = STORE;
assign next_d_cache_mshr_out.mshr_proc2mem_command[1] = BUS_LOAD;
assign next_d_cache_mshr_out.miss_dirty[1] = 1;

assign next_d_cache_mshr_out.miss_addr[2] = evicted_addr;
assign next_d_cache_mshr_out.miss_data_in[2] = evicted_data;
assign next_d_cache_mshr_out.inst_type[2] = EVICT;
assign next_d_cache_mshr_out.mshr_proc2mem_command[2] = BUS_STORE;
assign next_d_cache_mshr_out.miss_dirty[2] = 0;


//assign cachemem inputs
assign rd1_addr = {lq_d_cache_out.addr,3'b000};
assign rd1_search = lq_d_cache_out.rd_en;

assign wr1_search = wr1_from_mem | sq_d_cache_out.wr_en;

assign wr1_addr = (write_back_stage)                                                                      ?  write_back_addr :
                  (!write_back_stage & sq_d_cache_out.wr_en)                                              ?  {sq_d_cache_out.addr,3'b000} :
                  (!write_back_stage & !sq_d_cache_out.wr_en & mshr_d_cache_out.rd_wb_en)                 ?  mshr_d_cache_out.rd_wb_addr : mshr_d_cache_out.mem_addr;

assign wr1_dirty = (sq_d_cache_out.wr_en)                                                                 ?  1 :
                   (!(sq_d_cache_out.wr_en) & mshr_d_cache_out.rd_wb_en)                                  ?  mshr_d_cache_out.rd_wb_dirty : mshr_d_cache_out.mem_dirty;

assign wr1_data = (sq_d_cache_out.wr_en)                                                                  ?  sq_d_cache_out.value:
                  (!(sq_d_cache_out.wr_en) & mshr_d_cache_out.rd_wb_en)                                   ?  mshr_d_cache_out.rd_wb_data : mshr_d_cache_out.mem_data;

assign wr1_valid = !write_back_stage;

assign wr1_from_mem = mshr_d_cache_out.mem_wr | mshr_d_cache_out.rd_wb_en | write_back_stage;

assign wr1_strictly_from_mem = wr1_from_mem & !sq_d_cache_out.wr_en;

assign wr1_en = (wr1_hit & sq_d_cache_out.wr_en) | (!sq_d_cache_out.wr_en & wr1_from_mem);

//inform MSHR that it is written
assign stored_rd_wb = !sq_d_cache_out.wr_en & mshr_d_cache_out.rd_wb_en & wr1_en;
assign stored_mem_wr = !sq_d_cache_out.wr_en & !mshr_d_cache_out.rd_wb_en & mshr_d_cache_out.mem_wr & wr1_en;

//set the cache id valid or not
// assign cache_valid = mshr_valid;

// to clear cache after prog done

always_comb begin
  if (write_back_stage && mshr_valid)
    next_count = count + 2;
  else
    next_count = count;
end

always_comb begin
  if (state == 0 && write_back) 
    next_state = 1;
  else if (state == 1 && mshr_empty)
    next_state = 2;
  else if(write_back_stage && count > 64)
    next_state = 3;
  else
    next_state = state;
end

assign halt_pipeline = (state == 3) && mshr_empty;
assign write_back_stage = state == 2;
assign write_back_addr = count & {{61{1'b1}},3'b000};

always_ff @(posedge clock) begin
  if(reset) begin
    state           <= `SD `state_reset;
    count           <= `SD `count_reset;
  end
  else begin
    state           <= `SD next_state;
    count           <= `SD next_count;
  end
end

always_ff @(posedge clock) begin
  if(reset) begin
    d_cache_mshr_out  <= `SD `d_cache_mshr_out_reset;
    mshr_d_cache_out  <= `SD `mshr_d_cache_out_reset;
  end
  else begin
    d_cache_mshr_out  <= `SD next_d_cache_mshr_out;
    mshr_d_cache_out  <= `SD next_mshr_d_cache_out;
  end
end

endmodule
