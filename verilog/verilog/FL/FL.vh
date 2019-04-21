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
  logic [`NUM_SUPER-1:0][$clog2(`NUM_PR)-1:0] T_idx;
} FL_ROB_OUT_t;

typedef struct packed {
  logic [`NUM_SUPER-1:0][$clog2(`NUM_PR)-1:0] T_idx;
} FL_RS_OUT_t;

typedef struct packed {
  logic [`NUM_SUPER-1:0][$clog2(`NUM_PR)-1:0] T_idx;            // tags from freelist
} FL_MAP_TABLE_OUT_t;

`define ZERO_PR_UNPACKED {{($clog2(`NUM_PR)-5){1'b0}}, `ZERO_REG}

`endif
