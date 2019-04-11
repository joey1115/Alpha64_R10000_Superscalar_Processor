
module Dcache_controller(
    //proc to cache            
    input logic [`NUM_SUPER-1:0][60:0]                                            rd_in_addr,
    input logic [`NUM_SUPER-1:0][60:0]                                            wr_in_addr,
    input logic [`NUM_SUPER-1:0]                                                  rd_en,
    input logic                                                                   wr_en,
    input logic [63:0]                                                            wr_data,

    //cache to proc                                 
    output logic [`NUM_SUPER-1:0][63:0]                                           data,
    output logic [`NUM_SUPER-1:0]                                                 valid_data,

    //Dcachemem to cache                                  
    input logic [63:0]                                                            rd1_data, rd2_data, 
    input logic                                                                   data1_hit, data2_hit, wr1_hit,
    input logic                                                                   evicted_dirty_out,
    input logic                                                                   evicted_valid_out,
    input SASS_ADDR                                                               evicted_addr,
    input logic [`NUM_BLOCK-1:0][(MEMORY_BLOCK_SIZE*8-1):0]                       evicted_data_out,

    // cache to Dcachemem                       
    output logic                                                                  wr1_en, wr1_dirty, wr1_from_mem,
    output SASS_ADDR                                                              rd1_addr, rd2_addr, wr1_addr,
    output logic [63:0]                                                           wr1_data,

    //MSHR to cache                                 
    input logic [1:0][63:0]                                                       miss_data,
    input logic [1:0]                                                             miss_data_valid,
    input logic [2:0]                                                             addr_hit,
    input logic                                                                   mem_wr,
    input logic                                                                   mem_dirty,
    input logic [63:0]                                                            mem_data,
    input SASS_ADDR                                                               mem_addr,
    input logic                                                                   mshr_valid,

    //cache to MSHR (loading)                                 
    output logic [3:0]                                                            miss_en,
    output SASS_ADDR [3:0]                                                        miss_addr,
    output logic [3:0][`NUM_BLOCK-1:0][(MEMORY_BLOCK_SIZE*8-1):0]                 miss_data_in,
    // output logic [`NUM_BLOCK-1:0][(MEMORY_BLOCK_SIZE*8-1):0]                      evict_data_in,
    output MSHR_INST_TYPE [3:0]                                                   inst_type,
    output logic [3:0][1:0]                                                       mshr_proc2mem_command,
    //cache to MSHR (searching)                                 
    output SASS_ADDR [2:0]                                                        search_addr,
    output MSHR_INST_TYPE [2:0]                                                   search_type,
    //cache to MSHR (Written back)                      
    output logic                                                                  stored,

    output logic                                                                  cache_valid
);
//read cache outputs

//output data from mshr if exist otherwise from cache
assign data[0] = (miss_data_valid[0]) ? miss_data[0] : rd1_data; 
assign data[1] = (miss_data_valid[1]) ? miss_data[1] : rd2_data;

//data is valid if it is read and if data is either in cache or mshr
assign valid_data[0] = data1_hit | miss_data_valid[0];
assign valid_data[1] = data2_hit | miss_data_valid[1];

//set MSHR CMMD

//search mshr for rd1 data
assign search_addr[0] = rd1_addr;
assign search_type[0] = LOAD;

//search mshr for rd2 data
assign search_addr[1] = rd2_addr;
assign search_type[1] = LOAD;

//search mshr for wr1 data
assign search_addr[2] = wr_in_addr;
assign search_type[2] = STORE;

//if not in cache, enable to push data to the MSHR
assign miss_en[0] = (rd_en[0] & !data1_hit & !addr_hit[0]);
assign miss_en[1] = (rd_en[1] & !data2_hit & !addr_hit[1]);
//Miss from stores
assign miss_en[2] = (!wr1_hit & wr_en);
//Store inst from evicts
assign miss_en[3] = (mem_wr & evicted_dirty_out & evicted_valid_out);// when wr1 is from memory and it is dirty

assign cannotEvict = !evicted_valid_out;

//data sent to MSHR search
assign miss_addr[0] = rd1_addr;
assign miss_data_in[0] = {`NUM_BLOCK{64'hDEADBEEFDEADBEEF}};
assign inst_type[0] = LOAD;
assign mshr_proc2mem_command[0] = BUS_LOAD;

assign miss_addr[1] = rd2_addr;
assign miss_data_in[1] = {`NUM_BLOCK{64'hDEADBEEFDEADBEEF}};
assign inst_type[1] = LOAD;
assign mshr_proc2mem_command[1] = BUS_LOAD;

assign miss_addr[2] = wr1_addr;
always_comb begin
  for(int i = 0; i < `NUM_BLOCK; i++) begin
    if(i == miss_addr[2].BO) begin
      miss_data_in[2][i]= wr_data;
    else
      miss_data_in[2][i]= 64'hDEADBEEFDEADBEEF;
  end
end
assign inst_type[2] = STORE;
assign mshr_proc2mem_command[2] = BUS_LOAD;

assign miss_addr[3] = evicted_addr;
assign miss_data_in[3] = evicted_data_out;
assign inst_type[3] = EVICT;
assign mshr_proc2mem_command[3] = BUS_STORE;


//data to cache
//assign cachemem inputs
assign rd1_addr = rd_in_addr[0];
assign rd2_addr = rd_in_addr[1];

//write from stores will have higher priority. the evicted line must be valid, if not we write from memory.
assign wr1_addr = FWD_line(wr_en & evicted_valid_out) ? wr_in_addr : mem_addr; // logic to choose wether from mshr or proc
assign wr1_dirty = (wr_en & evicted_valid_out) ? 0 : mem_dirty;
assign wr1_from_mem = mem_wr;
assign wr1_en = (wr1_hit & wr_en) | mem_wr; //will be high if I want to write either mem_wr or when proc wants to write
assign wr1_data = (wr_en & evicted_valid_out) ? wr_data : mem_data;

//inform MSHR that it is written
assign stored = !(wr_en & evicted_valid_out) & mem_wr;

//set the cache id valid or not
assign cache_valid = evicted_valid_out & mshr_valid;

endmodule
