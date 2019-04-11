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
  logic [`NUM_BLOCK-1:0][(MEMORY_BLOCK_SIZE*8-1):0] data;
  logic [`NUM_TAG_BITS-1:0] tag;
  logic dirty;
  logic [`NUM_BLOCK-1:0] valid;
} D_CACHE_LINE_t;

typedef struct packed {
    logic [`NUM_TAG_BITS-1:0] tag;
    logic [$clog2(`NUM_IDX)-1:0] set_index;
    logic [$clog2(`NUM_BLOCK)-1:0] BO;
} SASS_ADDR;

typedef enum logic {
  STORE        = 2'b00,
  LOAD         = 2'b01,
  EVICT        = 2'b10,
} MSHR_INST_TYPE;

`endif


//SEND RETIRE signal to PR, Told to PR freeing (freelist)
//TAKE IN CDB (tag and valid) to update the complete column.
//check the head and the complete bit is set if so retire is activated.