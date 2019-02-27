`ifndef __ARCH_MAP_VH__
`define __ARCH_MAP_VH__

typedef struct packed {
  T_t                         T_PLUS;
  logic [$clog2(`NUM_PR)-1:0] PR_idx;
} ARCH_MAP_t;

`endif
