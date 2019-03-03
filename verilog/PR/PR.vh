
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
  logic r;                                // retire signal from complete stage
  logic [$clog2(`NUM_PR)-1:0] T_old;      // T_old from ROB
  logic X_C_valid;                        // execute stage result_valid
  logic [$clog2(`NUM_PR)-1:0] X_C_T;      // execute stage result_T
  logic [63:0] X_C_result;                // execute stage result_valid
  logic [$clog2(`NUM_PR)-1:0] S_X_T1;     // T1&T2 reg from FU
  logic [$clog2(`NUM_PR)-1:0] S_X_T2;
  logic inst_dispatch;                    // structure_hazard
} PR_PACKET_IN;


typedef struct packed {
  logic [63:0] T1_value;                  // send T1 value to FU
  logic [63:0] T2_value;                  // send T2 value to FU
  logic struct_hazard;                    // send structure_hazard signal to dispatch control
  logic [$clog2(`NUM_PR)-1:0] T;          // send tag to ROB, RS and Map Table 
} PR_PACKET_OUT;

`endif
