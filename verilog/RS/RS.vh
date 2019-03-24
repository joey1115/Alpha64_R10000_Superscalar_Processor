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
  ALU_OPA_SELECT                  T1_select;
  ALU_OPB_SELECT                  T2_select;
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
  logic          [$clog2(`NUM_PR)-1:0]  T_idx;            // Dest idx
  logic          [$clog2(`NUM_ROB)-1:0] ROB_idx;
  logic          [$clog2(`NUM_FL)-1:0]  FL_idx;
  T_t                                   T1;               // T1
  T_t                                   T2;               // T2
  logic          [$clog2(`NUM_PR)-1:0]  CDB_T_idx;        // CDB tag
  logic          [`NUM_FU-1:0]          fu_valid;         // FU done
  logic          [$clog2(`NUM_ROB)-1:0] ROB_rollback_idx; // FU done
  logic          [$clog2(`NUM_ROB)-1:0] ROB_tail_idx;     // FU done
  logic          [$clog2(`NUM_ROB)-1:0] diff_ROB;
} RS_PACKET_IN;

typedef struct packed {
  logic                                 ready;  // If an entry is ready
  INST_t                                inst;
  ALU_FUNC                              func;
  logic          [63:0]                 NPC;
  logic          [4:0]                  dest_idx;
  logic          [$clog2(`NUM_ROB)-1:0] ROB_idx;
  logic          [$clog2(`NUM_FL)-1:0]  FL_idx;
  logic          [$clog2(`NUM_PR)-1:0]  T_idx;  // Dest idx
  logic          [$clog2(`NUM_PR)-1:0]  T1_idx; // T1 idx
  logic          [$clog2(`NUM_PR)-1:0]  T2_idx; // T2 idx
  ALU_OPA_SELECT                        T1_select;
  ALU_OPB_SELECT                        T2_select;
} FU_PACKET_t;

typedef struct packed {
  FU_PACKET_t [`NUM_FU-1:0] FU_packet_out; // List of output fu
  logic                     RS_valid;
} RS_PACKET_OUT;

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
