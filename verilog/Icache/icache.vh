`ifndef __ICACHE_VH__
`define __ICACHE_VH__

`ifdef PIPELINE
`include "sys_config.vh"
`include "sys_defs.vh"
`else
`include "../../sys_config.vh"
`include "../../sys_defs.vh"
`endif

typedef struct packed {
  logic        valid;
  logic [5:0]  tag;
  logic [64:0] data;
} I_CACHE_ENTRY_t;

typedef struct packed {
  logic [6:0] idx;
  logic [5:0] tag;
} MEM_TAG_TABLE_t;

`endif