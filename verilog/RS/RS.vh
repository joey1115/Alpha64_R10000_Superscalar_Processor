`ifndef __RS_VH__
`define __RS_VH__

`ifdef PIPELINE
`include "sys_config.vh"
`include "sys_defs.vh"
`else
`include "../../sys_config.vh"
`include "../../sys_defs.vh"
`endif

typedef struct packed {
  logic [$clog2(`NUM_PR)-1:0] idx;   // T idx
  logic                       ready; // T plus
} T_t;

typedef struct packed {
  logic                           busy;      // RS entry busy
  INST_t                          inst;
  ALU_FUNC                        func;
  logic    [63:0]                 NPC;
  logic    [4:0]                  dest_idx;
  logic    [$clog2(`NUM_ROB)-1:0] ROB_idx;
  logic    [$clog2(`NUM_FL)-1:0]  FL_idx;
  logic    [$clog2(`NUM_PR)-1:0]  T_idx;     // Dest idx
  T_t                             T1;        // T1
  T_t                             T2;        // T2
  ALU_OPA_SELECT                  opa_select;
  ALU_OPB_SELECT                  opb_select;
  logic                           uncond_branch;
  logic                           cond_branch;
} RS_ENTRY_t;

`define FU_LIST '{      \
  {`NUM_ALU{FU_ALU}},   \
  {`NUM_MULT{FU_MULT}}, \
  {`NUM_BR{FU_BR}},     \
  {`NUM_ST{FU_ST}},     \
  {`NUM_LD{FU_LD}}      \
}

`define ZERO_PR {{($clog2(`NUM_PR)-5){1'b0}}, `ZERO_REG}
`define T_RESET {`ZERO_PR, `FALSE} // T reset
`define RS_ENTRY_RESET  { \
  `FALSE,                 \
  `NOOP_INST,             \
  ALU_ADDQ,               \
  {64{1'b0}},             \
  `ZERO_REG,              \
  {`NUM_ROB{1'b0}},       \
  {`NUM_FL{1'b0}},        \
  `ZERO_PR,               \
  `T_RESET,               \
  `T_RESET,               \
  ALU_OPA_IS_REGA,        \
  ALU_OPB_IS_REGB         \
} // RS entry reset
`define RS_RESET '{`NUM_FU{`RS_ENTRY_RESET}} // RS reset

typedef struct packed {
  logic                                 ready;  // If an entry is ready
  INST_t                                inst;
  ALU_FUNC                              func;
  logic          [63:0]                 NPC;
  logic          [4:0]                  dest_idx;
  logic          [$clog2(`NUM_ROB)-1:0] ROB_idx;
  logic          [$clog2(`NUM_FL)-1:0]  FL_idx;
  logic          [$clog2(`NUM_PR)-1:0]  T_idx;  // Dest idx
  ALU_OPA_SELECT                        opa_select;
  ALU_OPB_SELECT                        opb_select;
  logic                                 uncond_branch;
  logic                                 cond_branch;
} FU_PACKET_t;

typedef struct packed {
  FU_PACKET_t [`NUM_FU-1:0] FU_packet; // List of output fu
} RS_FU_OUT_t;

typedef struct packed {
  logic [$clog2(`NUM_PR)-1:0] T1_idx;    // (execute)  T1 index      from S/X reg
  logic [$clog2(`NUM_PR)-1:0] T2_idx;    // (execute)  T2 index      from S/X reg
} FU_IDX_ENTRY_t;

typedef struct packed {
  FU_IDX_ENTRY_t [`NUM_FU-1:0] FU_T_idx;
} RS_PR_OUT_t;

  logic          [$clog2(`NUM_PR)-1:0]  T1_idx; // T1 idx
  logic          [$clog2(`NUM_PR)-1:0]  T2_idx; // T2 idx
`define FU_PACKET_ENTRY_RESET '{ \
  `FALSE,                        \
  `NOOP_INST,                    \
  ALU_ADDQ,                      \
  {64{1'b0}},                    \
  `ZERO_REG,                     \
  {`NUM_ROB{1'b0}},              \
  {`NUM_FL{1'b0}},               \
  `ZERO_PR,                      \
  `ZERO_PR,                      \
  `ZERO_PR,                      \
  ALU_OPA_IS_REGA,               \
  ALU_OPB_IS_REGB                \
}

`endif
