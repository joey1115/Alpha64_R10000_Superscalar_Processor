`ifndef __ARCH_MAP_VH__
`define __ARCH_MAP_VH__

`include "../../sys_config.vh"

typedef struct packed {
  logic                       Rob_retire_enable;   // no Dispatch hazard
  logic [$clog2(`NUM_PR)-1:0] Rob_retire_Told;  // reg from dispatch
  logic [$clog2(`NUM_PR)-1:0] Rob_retire_T;
} ARCH_MAP_PACKET_IN;

typedef struct packed {
  logic [$clog2(`NUM_PR)-1:0] T1_to_RS;          // output T1 to RS
  logic [$clog2(`NUM_PR)-1:0] T2_to_RS;          // output T2 to RS
  logic [$clog2(`NUM_PR)-1:0] Told_to_ROB;       // output Told to ROB
} MAP_TABLE_PACKET_OUT;

typedef struct packed {
  logic [$clog2(`NUM_PR)-1:0] PR_idx;
  logic                       T_PLUS
} ARCH_MAP_t;


`endif
