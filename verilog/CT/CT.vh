`ifndef __CT_VH__
`define __CT_VH__

`include "../../sys_config.vh"

typedef struct packed {
  logic taken;
  logic [$clog2(`NUM_PR)-1:0] T;
  logic [63:0] result;
} CT_entry_t;



typedef struct packed {
  logic                       [$clog2(`NUM_FU)-1:0] X_C_valid;      // valid signal from ALU
  logic [$clog2(`NUM_PR)-1:0] [$clog2(`NUM_FU)-1:0] X_C_T;          // tag from ALU
  logic [63:0]                [$clog2(`NUM_FU)-1:0] X_C_result;     // result from ALU
} CT_PACKET_IN;

typedef struct packed {
  logic [$clog2(`NUM_FU)-1:0] full_hazard;                          // full entry means hazard
  logic                       valid;                                // valid signal to WB PR
  logic [$clog2(`NUM_PR)-1:0] T;                                    // tag to PR
  logic [63:0]                result;                               // result to PR
} CT_PACKET_OUT;

`endif
