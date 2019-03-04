`ifndef __PR_VH__
`define __PR_VH__

`include "../../sys_config.vh"

typedef enum logic {
  PR_NOT_FREE = 1'b0,
  PR_FREE     = 1'b1
} PR_FREE_t;

typedef struct packed {
  logic [63:0] data;
  PR_FREE_t    free;
} PR_t;

typedef enum logic {
  PR_NOT_READY = 1'b0,
  PR_READY     = 1'b1
} PR_STATUS_t;

typedef struct packed {
  logic [$clog2(`NUM_PR)-1:0] PR_idx;
  PR_STATUS_t                 T_PLUS_STATUS;
} T_t;

`endif
