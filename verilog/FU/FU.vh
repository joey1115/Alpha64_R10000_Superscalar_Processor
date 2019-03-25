
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
} FU_IN_t;

typedef struct packed {
  logic                        done;
  logic [63:0]                 result;
  logic [4:0]                  dest_idx;
  logic [$clog2(`NUM_PR)-1:0]  T_idx;   // Dest idx
  logic [$clog2(`NUM_ROB)-1:0] ROB_idx; // Dest idx
  logic [$clog2(`NUM_FL)-1:0]  FL_idx;  // Dest idx
} FU_OUT_t;

typedef struct packed {
  FU_OUT_t [`NUM_FU-1:0] FU_result;
} FU_CDB_OUT_t;

typedef struct packed {
  logic [`NUM_FU-1:0][$clog2(`NUM_PR)-1:0] T1_idx;    // (execute)  T1 index      from S/X reg
  logic [`NUM_FU-1:0][$clog2(`NUM_PR)-1:0] T2_idx;    // (execute)  T2 index      from S/X reg
} FU_IDX_ENTRY_t;

typedef struct packed {
  FU_IDX_ENTRY_t [`NUM_FU-1:0] FU_idx;
} FU_PR_OUT_t;

typedef struct packed {
  logic [$clog2(`NUM_FL)-1:0] FL_rollback_idx;
} FU_FL_OUT_t;

`endif
