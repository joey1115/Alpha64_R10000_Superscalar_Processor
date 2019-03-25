`ifndef __FL_VH__
`define __FL_VH__

`ifdef PIPELINE
`include "sys_config.vh"
`include "sys_defs.vh"
`include "verilog/RS/RS.vh"
`else
`include "../../sys_config.vh"
`include "../../sys_defs.vh"
`include "../RS/RS.vh"
`endif

typedef struct packed {
  logic [$clog2(`NUM_PR)-1:0] T_idx;
  logic [$clog2(`NUM_FL)-1:0] FL_idx;
} FL_RS_OUT_t;

typedef struct packed {
  logic [$clog2(`NUM_PR)-1:0] T_idx;            // tags from freelist
} FL_MAP_TABLE_OUT_t;

`endif
