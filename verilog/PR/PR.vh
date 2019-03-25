
`ifndef __PR_VH__
`define __PR_VH__

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
  logic [`NUM_FU-1:0] [63:0] T1_value;    // (execute) T1 values to FUs
  logic [`NUM_FU-1:0] [63:0] T2_value;    // (execute) T2 values to FUs
} PR_PACKET_OUT;

`endif
