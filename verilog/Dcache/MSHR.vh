`ifndef __MSHR_VH__
`define __MSHR_VH__

`ifdef PIPELINE
`include "sys_config.vh"
`include "sys_defs.vh"
`include "verilog/Dcache/Dcache.vh"
`else
`include "../../sys_config.vh"
`include "../../sys_defs.vh"
`include "./Dcache.vh"
`endif



typedef enum logic [1:0] {
  INPROGRESS      = 2'b00,
  WAITING         = 2'b01,
  DONE            = 2'b10
} MSHR_STATE;

typedef struct packed {
  logic                               valid;
  logic [(`MEMORY_BLOCK_SIZE*8-1):0]  data;
  logic                               dirty;
  SASS_ADDR                           addr;
  MSHR_INST_TYPE                      inst_type;
  logic [1:0]                         proc2mem_command;
  logic                               complete;
  logic [3:0]                         mem_tag;
  MSHR_STATE                          state;
  logic [$clog2(`NUM_ROB)-1:0]        ROB_idx;
} MSHR_ENTRY_t;

`define MSHR_queue_reset '{ \
1'b0,                   \
64'hbaadbeefdeadbeef,   \
1'b0,                   \
64'h0,                  \
STORE,                  \
BUS_NONE,               \
1'b0,                   \
4'b0,                   \
INPROGRESS,              \
{($clog2(`NUM_ROB)){1'b0}} \
}

typedef struct packed {
  // logic [1:0]                         miss_addr_hit;
  logic                               mem_wr;
  logic                               mem_dirty;
  logic [63:0]                        mem_data;
  SASS_ADDR                           mem_addr;
  logic                               rd_wb_en;
  logic                               rd_wb_dirty;
  logic [63:0]                        rd_wb_data;
  SASS_ADDR                           rd_wb_addr;
  // logic                               wr_wb_en;
  // logic                               wr_wb_dirty;
  // logic [63:0]                        wr_wb_data;
  // SASS_ADDR                           wr_wb_addr;
} MSHR_D_CACHE_OUT_t;

`define mshr_d_cache_out_reset '{ \
1'b0,                           \
1'b0,                           \
64'hbaadbeefdeadbeef,           \
64'h0,                          \
1'b0,                           \
1'b0,                           \
64'hbaadbeefdeadbeef,           \
64'h0                           \
}



`define writeback_head_reset '{  \
  ($clog2(`MSHR_DEPTH)){1'b0}   \
}

`define head_reset '{  \
  ($clog2(`MSHR_DEPTH)){1'b0}   \
}

`define tail_reset '{  \
  ($clog2(`MSHR_DEPTH)){1'b0}   \
}

`endif