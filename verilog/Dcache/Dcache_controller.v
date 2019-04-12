
module Dcache_controller(
    //proc to cache            
    input logic [60:0]                                                            rd_in_addr,
    input logic [60:0]                                                            wr_in_addr,
    input logic                                                                   rd_en,
    input logic                                                                   wr_en,
    input logic [63:0]                                                            wr_data,

    //cache to proc                                 
    output logic [63:0]                                                           data,
    output logic                                                                  valid_data,

    //Dcachemem to cache                                  
    input logic [63:0]                                                            rd1_data, 
    input logic                                                                   rd1_hit, wr1_hit,
    input logic                                                                   evicted_dirty,
    input logic                                                                   evicted_valid,
    input SASS_ADDR                                                               evicted_addr,
    input logic [63:0]                                                            evicted_data,

    // cache to Dcachemem                       
    output logic                                                                  wr1_en, wr_dirty, wr_from_mem,
    output SASS_ADDR                                                              rd1_addr, wr1_addr,
    output logic [63:0]                                                           wr1_data,

    //MSHR to cache                                 
    input logic                                                                   mshr_valid,

    input logic [1:0][63:0]                                                       miss_data,
    input logic [1:0]                                                             miss_data_valid,
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
    //cache to MSHR (Written back)                      
    output logic                                                                  stored_rd_wb,
    output logic                                                                  stored_wr_wb,
    output logic                                                                  stored_mem_wr,



    output logic                                                                  cache_valid
);
//read cache outputs

//output data from mshr if exist otherwise from cache
assign data = rd1_data; 

//data is valid if it is read and if data is either in cache or mshr
assign valid_data[0] = rd1_hit;


//set MSHR CMMD

//search mshr for rd1 data
assign search_addr[0] = rd1_addr;
assign search_type[0] = LOAD;

//search mshr for wr1 data
assign search_addr[1] = wr_in_addr;
assign search_type[1] = STORE;

//if not in cache, enable to push data to the MSHR
assign miss_en[0] = (rd_en & !rd1_hit & !miss_addr_hit[0]);
//Miss from stores
assign miss_en[1] = (wr_en & !wr1_hit & !miss_addr_hit[1]);
//Store inst from evicts
assign miss_en[2] = (mem_wr & !wr1_hit & evicted_dirty & evicted_valid);// when wr1 is from memory and it is dirty

//data sent to MSHR search
assign miss_addr[0] = rd1_addr;
assign miss_data_in[0] = {64'hDEADBEEFDEADBEEF};
assign inst_type[0] = LOAD;
assign mshr_proc2mem_command[0] = BUS_LOAD;

assign miss_addr[1] = wr1_addr;
assign miss_data_in[1]= wr_data;
assign inst_type[1] = STORE;
assign mshr_proc2mem_command[1] = BUS_LOAD;

assign miss_addr[2] = evicted_addr;
assign miss_data_in[2] = evicted_data;
assign inst_type[2] = EVICT;
assign mshr_proc2mem_command[2] = BUS_STORE;

//data to cache
//assign cachemem inputs
assign rd1_addr = rd_in_addr;



assign wr1_addr = (wr_en)                         ?  wr_in_addr :
                  (!wr_en & rd_wb_en)             ?  rd_wb_addr :
                  (!wr_en & !rd_wb_en & wr_wb_en) ?  wr_wb_addr : mem_addr;

assign wr1_dirty = (wr_en)                         ?  1           :
                   (!wr_en & rd_wb_en)             ?  rd_wb_dirty :
                   (!wr_en & !rd_wb_en & wr_wb_en) ?  wr_wb_dirty : mem_dirty;

assign wr1_data = (wr_en)                         ?  wr_data    :
                  (!wr_en & rd_wb_en)             ?  rd_wb_data :
                  (!wr_en & !rd_wb_en & wr_wb_en) ?  wr_wb_data : mem_data;

assign wr1_from_mem = mem_wr | rd_wb_en | wr_wb_en;

assign wr1_en = (wr1_hit & wr_en) | wr1_from_mem;

//inform MSHR that it is written
assign stored_rd_wb = !wr_en & rd_wb_en;
assign stored_wr_wb = !wr_en & !rd_wb_en & wr_wb_en;
assign stored_mem_wr = !wr_en & !rd_wb_en & !wr_wb_en & mem_wr;

//set the cache id valid or not
assign cache_valid = mshr_valid;

endmodule
