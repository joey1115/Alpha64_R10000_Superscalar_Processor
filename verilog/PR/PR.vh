
`ifndef __PR_VH__
`define __PR_VH__

`include "../../sys_config.vh"
`include "../../sys_defs.vh"

typedef enum logic {
  PR_NOT_FREE = 1'b0,
  PR_FREE     = 1'b1
} PR_FREE_t;

typedef struct packed {
  logic [63:0] value;
  PR_FREE_t    free;
} PR_entry_t;


typedef struct packed {
  logic r;
  logic [$clog2(`NUM_PR)-1:0] T_old;
  logic X_C_valid;
  logic [$clog2(`NUM_PR)-1:0] X_C_T;
  logic [63:0] X_C_result;
  logic [$clog2(`NUM_PR)-1:0] S_X_T1;
  logic [$clog2(`NUM_PR)-1:0] S_X_T2;
  logic inst_dispatch;
} PR_PACKET_IN;


typedef struct packed {
  logic [63:0] T1_value;
  logic [63:0] T2_value;
  logic struct_hazard;
  logic [$clog2(`NUM_PR)-1:0] T;
} PR_PACKET_OUT;

`endif
