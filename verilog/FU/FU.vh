
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
  BR_PACKET_t [`NUM_FU-1:0] br_packet;
} FU_PACKET_IN;

typedef struct packed {
  logic        done;
  logic [63:0] result;
} FU_RESULT_ENTRY_t;

typedef struct packed {
  FU_RESULT_ENTRY_t [`NUM_ALU-1:0] alu_result;
  logic             [`NUM_BR-1:0]  br_cond;
} FU_PACKET_OUT;




`endif
