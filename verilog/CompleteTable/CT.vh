`ifndef __CT_VH__
`define __CT_VH__

`include "../../sys_config.vh"

typedef struct packed {
  logic valid;
  logic [$clog2(`NUM_PR)-1:0] T;
  logic [63:0] result;
} CT_entry_t;



typedef struct packed {
  logic                       X_C_valid [$clog2(`NUM_FU)-1:0];      // valid signal from ALU
  logic [$clog2(`NUM_PR)-1:0] X_C_T [$clog2(`NUM_FU)-1:0];          // tag from ALU
  logic [63:0]                X_C_result [$clog2(`NUM_FU)-1:0];     // result from ALU
} CT_PACKET_IN;

typedef struct packed {
  logic                       full_hazard [$clog2(`NUM_FU)-1:0];    // full entry means hazard
  logic                       valid;                                // valid signal to PR
  logic [$clog2(`NUM_PR)-1:0] T;                                    // tag to PR
  logic [63:0]                result;                               // result to PR
} CT_PACKET_OUT;

`endif
