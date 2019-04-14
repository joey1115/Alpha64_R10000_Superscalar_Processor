
module Dcache_controller(
    input logic                                                                   clock, reset,
    //proc to cache            
    input SQ_D_CACHE_OUT_t                                                        sq_d_cache_out,
    input LQ_D_CACHE_OUT_t                                                        lq_d_cache_out,

    //cache to proc                                 
    output D_CACHE_LQ_OUT_t                                                       d_cache_lq_out,
    output D_CACHE_SQ_OUT_t                                                       d_cache_sq_out, // tells if a store can be moved on.

    //Dcachemem to cache                                  
    input logic [63:0]                                                            rd1_data, 
    input logic                                                                   rd1_hit, wr1_hit,
    input logic                                                                   evicted_dirty,
    input logic                                                                   evicted_valid,
    input SASS_ADDR                                                               evicted_addr,
    input logic [63:0]                                                            evicted_data,

    // cache to Dcachemem                       
    output logic                                                                  wr1_en, wr1_dirty, wr1_from_mem, wr1_valid,
    output SASS_ADDR                                                              rd1_addr, wr1_addr,
    output logic [63:0]                                                           wr1_data,

    //MSHR to cache                                 
    input logic                                                                   mshr_valid,
    input logic                                                                   mshr_empty,

    // input logic [1:0][63:0]                                                       miss_data,
    // input logic [1:0]                                                             miss_data_valid,
    input logic [1:0]                                                             miss_addr_hit,

    input logic                                                                   mem_wr,
    input logic                                                                   mem_dirty,
    input logic [63:0]                                                            mem_data,
    input SASS_ADDR                                                               mem_addr,

    input logic                                                                   rd_wb_en,
    input logic                                                                   rd_wb_dirty,
    input logic [63:0]                                                            rd_wb_data,
    input SASS_ADDR                                                               rd_wb_addr,

    input logic                                                                   wr_wb_en,
    input logic                                                                   wr_wb_dirty,
    input logic [63:0]                                                            wr_wb_data,
    input SASS_ADDR                                                               wr_wb_addr,

    //cache to MSHR (loading)                                 
    output logic [2:0]                                                            miss_en,
    output SASS_ADDR [2:0]                                                        miss_addr,
    output logic [2:0][63:0]                                                      miss_data_in,
    output MSHR_INST_TYPE [2:0]                                                   inst_type,
    output logic [2:0][1:0]                                                       mshr_proc2mem_command,
    //cache to MSHR (searching)                                 
    output SASS_ADDR [1:0]                                                        search_addr,
    output MSHR_INST_TYPE [1:0]                                                   search_type,
    output [63:0]                                                                 search_wr_data,
    //cache to MSHR (Written back)                      
    output logic                                                                  stored_rd_wb,
    output logic                                                                  stored_wr_wb,
    output logic                                                                  stored_mem_wr,


    input  logic                                                                  write_back,
    output logic                                                                  cache_valid,
    output logic                                                                  halt_pipeline,
    output logic                                                                  write_back_stage
);
//logics

logic [1:0] state, next_state;
logic [63:0] count, next_count;
SASS_ADDR write_back_addr;


//read cache outputs

//output d_cache_lq_out.value from mshr if exist otherwise from cache
assign d_cache_lq_out.value = rd1_data; 

//d_cache_lq_out.value is valid if it is read and if d_cache_lq_out.value is either in cache or mshr
assign d_cache_lq_out.valid = rd1_hit;

assign d_cache_sq_out.valid = (stored_wr_wb || miss_en[1]);


//set MSHR CMMD

//search mshr for rd1 d_cache_lq_out.value
assign search_addr[0] = rd1_addr;
assign search_type[0] = LOAD;

//search mshr for wr1 d_cache_lq_out.value
assign search_addr[1] = {sq_d_cache_out.addr,3'b000};
assign search_type[1] = STORE;
assign search_wr_data = sq_d_cache_out.value;

//if not in cache, enable to push d_cache_lq_out.value to the MSHR
assign miss_en[0] = (lq_d_cache_out.rd_en & !rd1_hit & !miss_addr_hit[0]);
//Miss from stores
assign miss_en[1] = (sq_d_cache_out.wr_en & !wr1_hit & !miss_addr_hit[1]);
//Store inst from evicts
assign miss_en[2] = (wr1_from_mem & evicted_dirty & evicted_valid);// when wr1 is from memory and it is dirty

//d_cache_lq_out.value sent to MSHR search
assign miss_addr[0] = rd1_addr;
assign miss_data_in[0] = {64'hDEADBEEFDEADBEEF};
assign inst_type[0] = LOAD;
assign mshr_proc2mem_command[0] = BUS_LOAD;

assign miss_addr[1] = wr1_addr;
assign miss_data_in[1]= sq_d_cache_out.value;
assign inst_type[1] = STORE;
assign mshr_proc2mem_command[1] = BUS_LOAD;

assign miss_addr[2] = evicted_addr;
assign miss_data_in[2] = evicted_data;
assign inst_type[2] = EVICT;
assign mshr_proc2mem_command[2] = BUS_STORE;

//d_cache_lq_out.value to cache
//assign cachemem inputs
assign rd1_addr = {lq_d_cache_out.addr,3'b000};



assign wr1_addr = (write_back_stage)              ?  write_back_addr :
                  (sq_d_cache_out.wr_en & wr1_hit)               ?  sq_d_cache_out.addr      :
                  (wr_wb_en)                      ?  wr_wb_addr      :
                  (!wr_wb_en & rd_wb_en)          ?  rd_wb_addr      : mem_addr;

assign wr1_dirty = (sq_d_cache_out.wr_en & wr1_hit)               ?  1           :
                   (wr_wb_en)                      ?  wr_wb_dirty :
                   (!wr_wb_en & rd_wb_en)          ?  rd_wb_dirty : mem_dirty;

assign wr1_data = (sq_d_cache_out.wr_en & wr1_hit)               ?  sq_d_cache_out.value    :
                  (wr_wb_en)                      ?  wr_wb_data :
                  (!wr_wb_en & rd_wb_en)          ?  rd_wb_data : mem_data;

assign wr1_valid = (write_back_stage)             ? 0 : 1;

assign wr1_from_mem = mem_wr | rd_wb_en | wr_wb_en | write_back_stage;

assign wr1_en = (wr1_hit & sq_d_cache_out.wr_en) | wr1_from_mem;

//inform MSHR that it is written
assign stored_rd_wb = !sq_d_cache_out.wr_en & rd_wb_en;
assign stored_wr_wb = !sq_d_cache_out.wr_en & !rd_wb_en & wr_wb_en;
assign stored_mem_wr = !sq_d_cache_out.wr_en & !rd_wb_en & !wr_wb_en & mem_wr;

//set the cache id valid or not
assign cache_valid = mshr_valid;

// to clear cache after prog done

always_comb begin
  if (write_back_stage && mshr_valid)
    next_count = count + 1;
  else
    next_count = count;
end

always_comb begin
  if (state == 0 && write_back) 
    next_state = 1;
  else if(write_back_stage && count >= `TOTAL_LINES)
    next_state = 2;
  else
    next_state = state;
end

assign halt_pipeline = (state == 2) && mshr_empty;
assign write_back_stage = state == 1;
assign write_back_addr = count & {{61{1'b1}},3'b000};

always_ff @(posedge clock) begin
  if(reset) begin
    state           <= `SD 0;
    count           <= `SD 0;
  end
  else begin
    state           <= `SD next_state;
    count           <= `SD next_count;
  end
end

endmodule
