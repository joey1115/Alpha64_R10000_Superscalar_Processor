`timescale 1ns/100ps

module MSHR(
  input logic                                             clock,
  input logic                                             reset,

  //stored to cache input
  input logic                                             stored,

  //storing to the MSHR                     
  input logic [3:0]                                       miss_en,
  input SASS_ADDR [3:0]                                   miss_addr,
  input logic [2:0][63:0]                                 miss_data_in,
  input logic [`NUM_BLOCK-1:0][(MEMORY_BLOCK_SIZE*8-1):0] evict_data_in,
  input MSHR_INST_TYPE [3:0]                              inst_type,
  input logic [3:0][1:0]                                  mshr_proc2mem_command,

  //looking up the MSHR                     
  input SASS_ADDR [2:0]                                   search_addr, //address to search
  input MSHR_INST_TYPE [2:0]                              search_type, //address search type (might not need)

  output logic [1:0][63:0]                                miss_data, //data returned
  output logic [1:0]                                      miss_data_valid, //if data returned is correct
  output logic [2:0]                                      addr_hit, // if address search in the MSHR

  output logic                                            mem_wr,
  output logic                                            mem_dirty,
  output logic [63:0]                                     mem_data,
  output SASS_ADDR                                        mem_addr,

  //mshr to cache
  output logic                                            mshr_valid,

  //mem to mshr
  input logic [3:0]                           mem2proc_response,
  input logic [63:0]                          mem2proc_data,     // data resulting from a load
  input logic [3:0]                           mem2proc_tag,       // 0 = no value, other=tag of transaction

  //cache to mshr
  output logic [63:0]                         proc2mem_addr,
  output logic [63:0]                         proc2mem_data,
  output logic [1:0]                          proc2mem_command
);

//need to be able to extend the addrs automatically to whole cache line

//cannot be gone from queus until it has finish sending inst to cache
//need to have logic to tell if the request is in progress, only delete when not in progress (like rob)

//need fucntionality that either updates data of the load_bus cmmd from st or set as a new entry. 
//same mechanism for evicted BUS_STORE inst.

//for BUS transactions, need to have it be size of cache lines. use BO to set the data