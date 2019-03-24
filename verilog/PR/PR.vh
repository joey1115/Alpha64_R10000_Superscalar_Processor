
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
  logic write_en;                                      // (complete) write enable  from CDB
  logic [$clog2(`NUM_PR)-1:0] T_idx;                   // (complete) PR index      from CDB
  logic [63:0] T_value;                                // (complete) Value         from CDB
  logic [`NUM_FU-1:0] [$clog2(`NUM_PR)-1:0] T1_idx;    // (execute)  T1 index      from S/X reg
  logic [`NUM_FU-1:0] [$clog2(`NUM_PR)-1:0] T2_idx;    // (execute)  T2 index      from S/X reg
} PR_PACKET_IN;


typedef struct packed {
  logic [`NUM_FU-1:0] [63:0] T1_value;    // (execute) T1 values to FUs
  logic [`NUM_FU-1:0] [63:0] T2_value;    // (execute) T2 values to FUs
} PR_PACKET_OUT;

`endif
