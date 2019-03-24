
`ifndef __FU_VH__
`define __FU_VH__

`ifdef PIPELINE
`include "sys_config.vh"
`include "sys_defs.vh"
`include "verilog/RS/RS.vh"
`else
`include "../../sys_config.vh"
`include "../../sys_defs.vh"
`include "../RS/RS.vh"
`endif

typedef struct packed {
  FU_PACKET_t [`NUM_FU-1:0] fu_packet;
  logic       [`NUM_FU-1:0] CDB_valid;
} FU_M_PACKET_IN;

typedef struct packed {
  logic                        done;
  logic [63:0]                 result;
  logic [4:0]                  dest_idx;
  logic [$clog2(`NUM_PR)-1:0]  T_idx;   // Dest idx
  logic [$clog2(`NUM_ROB)-1:0] ROB_idx; // Dest idx
  logic [$clog2(`NUM_FL)-1:0]  FL_idx;  // Dest idx
} FU_RESULT_ENTRY_t;

typedef struct packed {
  FU_RESULT_ENTRY_t [`NUM_FU-1:0] fu_result;
} FU_M_PACKET_OUT;

typedef struct packed {
  logic                                 ready;    // If an entry is ready
  INST_t                                inst;
  ALU_FUNC                              func;
  logic          [63:0]                 NPC;
  logic          [4:0]                  dest_idx;
  logic          [$clog2(`NUM_ROB)-1:0] ROB_idx;
  logic          [$clog2(`NUM_FL)-1:0]  FL_idx;
  logic          [$clog2(`NUM_PR)-1:0]  T_idx;    // Dest idx
  logic          [63:0]                 T1_value; // T1 idx
  logic          [63:0]                 T2_value; // T2 idx
  ALU_OPA_SELECT                        T1_select;
  ALU_OPB_SELECT                        T2_select;
  logic                                 uncond_branch;
  logic                                 cond_branch;
} FU_PACKET_IN_t;

`define FU_PACKET_IN_RESET '{ \
  `FALSE,                     \
  `NOOP_INST,                 \
  ALU_ADDQ,                   \
  {64{1'b0}},                 \
  `ZERO_REG,                  \
  {`NUM_ROB{1'b0}},           \
  {`NUM_FL{1'b0}},            \
  `ZERO_PR,                   \
  {64{1'b0}},                 \
  {64{1'b0}},                 \
  ALU_OPA_IS_REGA,            \
  ALU_OPB_IS_REGB,            \
  `FALSE,                     \
  `FALSE                      \
}

`endif
