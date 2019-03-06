
`ifndef __FU_VH__
`define __FU_VH__

`include "../../sys_config.vh"
`include "../../sys_defs.vh"
`include "../RS/RS.vh"

// typedef struct packed {
//   logic                       en;
//   logic [$clog2(`NUM_PR)-1:0] T_idx;
//   logic [$clog2(`NUM_PR)-1:0] T1_idx;
//   logic [$clog2(`NUM_PR)-1:0] T2_idx;
// } FU_ENTRY_t;

// typedef struct packed {
//   logic        ready;
//   logic [63:0] T1_value;
//   logic [63:0] T2_value;
//   ALU_FUNC     func;
// } FU_PACKET_t;

// typedef struct packed {
//   logic        ready;
//   logic [63:0] T1_value;
//   ALU_FUNC     func;
// } BR_PACKET_t;

typedef struct packed {
  FU_PACKET_t [`NUM_FU-1:0] fu_packet;
} FU_M_PACKET_IN;

typedef struct packed {
  logic        done;
  logic [63:0] result;
  logic [$clog2(`NUM_PR)-1:0] T_idx;  // Dest idx
} FU_RESULT_ENTRY_t;

typedef struct packed {
  FU_RESULT_ENTRY_t [`NUM_FU-1:0] fu_result;
  //logic             [`NUM_BR-1:0]  br_cond;
} FU_M_PACKET_OUT;

typedef struct packed {
  logic                       ready;    // If an entry is ready
  INST_t                      inst;
  ALU_FUNC                    func;
  logic [$clog2(`NUM_PR)-1:0] T_idx;    // Dest idx
  logic [$clog2(`NUM_PR)-1:0] T1_value; // T1 idx
  logic [$clog2(`NUM_PR)-1:0] T2_value; // T2 idx
  ALU_OPA_SELECT              T1_select;
  ALU_OPB_SELECT              T2_select;
} FU_PACKET_IN_t;

`endif
