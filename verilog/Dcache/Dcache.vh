`ifndef __DCACHE_VH__
`define __DCACHE_VH__

`ifdef PIPELINE
`include "sys_config.vh"
`include "sys_defs.vh"
`else
`include "../../sys_config.vh"
`include "../../sys_defs.vh"
`endif

typedef struct packed {
  logic [63:0] data;
  logic [`NUM_TAG_BITS-1:0] tag;
  logic dirty;
  logic valid;
} D_CACHE_LINE_t;

typedef struct packed {
    logic [`NUM_TAG_BITS-1:0] tag;
    logic [$clog2(`NUM_IDX)-1:0] set_index;
    // logic [$clog2(`NUM_BLOCK)-1:0] BO;
    logic [2:0] ignore;
} SASS_ADDR;

typedef struct packed {
  logic valid;
} D_CACHE_SQ_OUT_t;

typedef struct packed {
  logic        valid;
  logic [63:0] value;
} D_CACHE_LQ_OUT_t;

typedef struct packed {
  // logic                  stored_mem_wr;
      
  //storing to the MSHR      
  logic [2:0]            miss_en;
  SASS_ADDR [2:0]        miss_addr;
  logic [2:0][63:0]      miss_data_in;
  MSHR_INST_TYPE [2:0]   inst_type;
  logic [2:0][1:0]       mshr_proc2mem_command;
  logic [2:0]            miss_dirty;
  //looking up the MSHR      
  // SASS_ADDR [1:0]        search_addr; //address to search
  // MSHR_INST_TYPE [1:0]   search_type; //address search type (might not need)
  // logic [63:0]           search_wr_data;
  // logic [1:0]            search_en;
} D_CACHE_MSHR_OUT_t;

`endif


//SEND RETIRE signal to PR, Told to PR freeing (freelist)
//TAKE IN CDB (tag and valid) to update the complete column.
//check the head and the complete bit is set if so retire is activated.