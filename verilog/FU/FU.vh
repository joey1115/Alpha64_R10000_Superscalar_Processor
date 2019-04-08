
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
`include "../PR/PR.vh"
`endif

typedef struct packed {
  logic                                 ready;    // If an entry is ready
  INST_t                                inst;
  ALU_FUNC                              func;
  logic          [63:0]                 NPC;
  logic          [4:0]                  dest_idx;
  logic          [$clog2(`NUM_ROB)-1:0] ROB_idx;
  logic          [$clog2(`NUM_FL)-1:0]  FL_idx;
  logic          [$clog2(`NUM_LSQ)-1:0] SQ_idx;
  logic          [$clog2(`NUM_LSQ)-1:0] LQ_idx;
  logic          [$clog2(`NUM_PR)-1:0]  T_idx;    // Dest idx
  logic          [63:0]                 T1_value; // T1 idx
  logic          [63:0]                 T2_value; // T2 idx
  ALU_OPA_SELECT                        opa_select;
  ALU_OPB_SELECT                        opb_select;
  logic                                 uncond_branch;
  logic                                 cond_branch;
  logic                                 wr_mem;
  logic                                 rd_mem;
} FU_IN_t;

typedef struct packed {
  logic                        done;
  logic [63:0]                 result;
  logic [4:0]                  dest_idx;
  logic [$clog2(`NUM_PR)-1:0]  T_idx;   // Dest idx
  logic [$clog2(`NUM_ROB)-1:0] ROB_idx; // Dest idx
  logic [$clog2(`NUM_FL)-1:0]  FL_idx;  // Dest idx
  logic [$clog2(`NUM_LSQ)-1:0] SQ_idx;
  logic [$clog2(`NUM_LSQ)-1:0] LQ_idx;
} FU_OUT_t;

typedef struct packed {
  FU_OUT_t [`NUM_FU-1:0] FU_out;
} FU_CDB_OUT_t;

typedef struct packed {
  logic [`NUM_SUPER-1:0]                       done;
  logic [`NUM_SUPER-1:0][63:0]                 result;
  logic [`NUM_SUPER-1:0][4:0]                  dest_idx;
  logic [`NUM_SUPER-1:0][$clog2(`NUM_PR)-1:0]  T_idx;   // Dest idx
  logic [`NUM_SUPER-1:0][$clog2(`NUM_ROB)-1:0] ROB_idx; // Dest idx
  logic [`NUM_SUPER-1:0][$clog2(`NUM_FL)-1:0]  FL_idx;  // Dest idx
  logic [`NUM_SUPER-1:0][$clog2(`NUM_LSQ)-1:0] SQ_idx;
  logic [`NUM_SUPER-1:0][$clog2(`NUM_LSQ)-1:0] LQ_idx;
  logic [`NUM_SUPER-1:0][`NUM_SUPER-1:0][63:0] T1_value;
} FU_SQ_OUT_t;

typedef struct packed {
  logic                        done;
  logic [63:0]                 result;
  logic [4:0]                  dest_idx;
  logic [$clog2(`NUM_PR)-1:0]  T_idx;   // Dest idx
  logic [$clog2(`NUM_ROB)-1:0] ROB_idx; // Dest idx
  logic [$clog2(`NUM_FL)-1:0]  FL_idx;  // Dest idx
  logic [$clog2(`NUM_LSQ)-1:0] SQ_idx;
  logic [$clog2(`NUM_LSQ)-1:0] LQ_idx;
  logic [`NUM_SUPER-1:0][63:0] T1_value;
} ST_OUT_t;

`define ST_OUT_RESET '{     \
  `FALSE,                   \
  64'hbaadbeefdeadbeef,     \
  `ZERO_REG,                \
  `ZERO_PR,                 \
  {$clog2(`NUM_ROB){1'b0}}, \
  {$clog2(`NUM_FL){1'b0}},  \
  {$clog2(`NUM_SQ){1'b0}},  \
  {$clog2(`NUM_LQ){1'b0}},  \
  64'hbaadbeefdeadbeef      \
}

typedef struct packed {
  logic [`NUM_SUPER-1:0]                       done;
  logic [`NUM_SUPER-1:0][63:0]                 result;
  logic [`NUM_SUPER-1:0][4:0]                  dest_idx;
  logic [`NUM_SUPER-1:0][$clog2(`NUM_PR)-1:0]  T_idx;   // Dest idx
  logic [`NUM_SUPER-1:0][$clog2(`NUM_ROB)-1:0] ROB_idx; // Dest idx
  logic [`NUM_SUPER-1:0][$clog2(`NUM_FL)-1:0]  FL_idx;  // Dest idx
  logic [`NUM_SUPER-1:0][$clog2(`NUM_LSQ)-1:0] SQ_idx;
  logic [`NUM_SUPER-1:0][$clog2(`NUM_LSQ)-1:0] LQ_idx;
} FU_LQ_OUT_t;

typedef struct packed {
  logic                        done;
  logic [63:0]                 result;
  logic [4:0]                  dest_idx;
  logic [$clog2(`NUM_PR)-1:0]  T_idx;   // Dest idx
  logic [$clog2(`NUM_ROB)-1:0] ROB_idx; // Dest idx
  logic [$clog2(`NUM_FL)-1:0]  FL_idx;  // Dest idx
  logic [$clog2(`NUM_LSQ)-1:0] SQ_idx;
  logic [$clog2(`NUM_LSQ)-1:0] LQ_idx;
} LD_OUT_t;

`define LD_OUT_RESET '{     \
  `FALSE,                   \
  64'hbaadbeefdeadbeef,     \
  `ZERO_REG,                \
  `ZERO_PR,                 \
  {$clog2(`NUM_ROB){1'b0}}, \
  {$clog2(`NUM_FL){1'b0}},  \
  {$clog2(`NUM_SQ){1'b0}},  \
  {$clog2(`NUM_LQ){1'b0}}   \
}

`endif
