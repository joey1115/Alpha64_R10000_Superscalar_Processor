`ifndef __LSQ_VH__
`define __LSQ_VH__

`ifdef PIPELINE
`include "sys_config.vh"
`include "sys_defs.vh"
`else
`include "../../sys_config.vh"
`include "../../sys_defs.vh"
`include "../decoder/decoder.vh"
`include "../ROB/ROB.vh"
`include "../FU/FU.vh"
`endif

typedef struct packed {
  logic [60:0] addr;
  logic        valid;
  logic [63:0] value;
} SQ_ENTRY_t;

typedef struct packed {
  logic        wr_en;
  logic [60:0] addr;
  logic [63:0] value;
} SQ_D_CACHE_OUT_t;

typedef struct packed {
  logic [`NUM_SUPER-1:0][$clog2(`NUM_LSQ)-1:0] LQ_idx;
  logic [`NUM_SUPER-1:0]                       hit;
  logic [`NUM_SUPER-1:0][63:0]                 value;
  logic [`NUM_SUPER-1:0]                       done;
  logic [`NUM_SUPER-1:0][60:0]                 addr;
} SQ_LQ_OUT_t;

typedef struct packed {
  logic [`NUM_SUPER-1:0] retire_valid;
} SQ_ROB_OUT_t;

typedef struct packed {
  logic [`NUM_SUPER-1:0]                       done;
  logic [`NUM_SUPER-1:0][63:0]                 result;
  logic [`NUM_SUPER-1:0][4:0]                  dest_idx;
  logic [`NUM_SUPER-1:0][$clog2(`NUM_PR)-1:0]  T_idx;   // Dest idx
  logic [`NUM_SUPER-1:0][$clog2(`NUM_ROB)-1:0] ROB_idx;
} SQ_FU_OUT_t;

`define SQ_FU_OUT_RESET '{                \
  {`NUM_SUPER{`FALSE}},                   \
  {`NUM_SUPER{64'hbaadbeafdeadbeef}},     \
  {`NUM_SUPER{`ZERO_REG}},                \
  {`NUM_SUPER{`ZERO_PR}},                 \
  {`NUM_SUPER{{$clog2(`NUM_ROB){1'b0}}}}, \
  {`NUM_SUPER{{$clog2(`NUM_FL){1'b0}}}},  \
  {`NUM_SUPER{{$clog2(`NUM_LSQ){1'b0}}}}, \
  {`NUM_SUPER{{$clog2(`NUM_LSQ){1'b0}}}}, \
  {`NUM_SUPER{{64'hbaadbeafdeadbeef}}}    \
}

typedef struct packed {
  logic [60:0]                 addr;
  logic                        valid;
  logic [$clog2(`NUM_ROB)-1:0] ROB_idx;
  logic [$clog2(`NUM_FL)-1:0]  FL_idx;
  logic [$clog2(`NUM_LSQ)-1:0] SQ_idx;
  logic [63:0]                 PC;
} LQ_ENTRY_t;

typedef struct packed {
  logic [`NUM_SUPER-1:0][$clog2(`NUM_LSQ)-1:0] SQ_idx;
  logic [`NUM_SUPER-1:0][60:0]                 addr;
} LQ_SQ_OUT_t;

typedef struct packed {
  logic [`NUM_SUPER-1:0]                       done;
  logic [`NUM_SUPER-1:0][63:0]                 result;
  logic [`NUM_SUPER-1:0][4:0]                  dest_idx;
  logic [`NUM_SUPER-1:0][$clog2(`NUM_PR)-1:0]  T_idx;   // Dest idx
  logic [`NUM_SUPER-1:0][$clog2(`NUM_ROB)-1:0] ROB_idx; // Dest idx
} LQ_FU_OUT_t;

`define LQ_FU_OUT_RESET '{                \
  {`NUM_SUPER{`FALSE}},                   \
  {`NUM_SUPER{64'hbaadbeafdeadbeef}},     \
  {`NUM_SUPER{`ZERO_REG}},                \
  {`NUM_SUPER{`ZERO_PR}},                 \
  {`NUM_SUPER{{$clog2(`NUM_ROB){1'b0}}}}  \
}

typedef struct packed {
  logic        rd_en;
  logic [60:0] addr;
} LQ_D_CACHE_OUT_t;

typedef struct packed {
  logic [$clog2(`NUM_ROB)-1:0] ROB_idx;
  logic [$clog2(`NUM_FL)-1:0]  FL_idx;
  logic [$clog2(`NUM_LSQ)-1:0] SQ_idx;
  logic [$clog2(`NUM_LSQ)-1:0] LQ_idx;
  logic [63:0]                 target_PC;   // 真
  logic                        LQ_violate;
} LQ_TARGET_t;

typedef struct packed {
  LQ_TARGET_t [`NUM_SUPER-1:0] LQ_target;
} LQ_BP_OUT_t;

`define SQ_ENTRY_RESET {61'h0, `FALSE, 64'hbaadbeafdeadbeef}
`define SQ_ENTRY_RESET_PACKED '{61'h0, `FALSE, 64'hbaadbeafdeadbeef}
`define SQ_RESET '{`NUM_LSQ{`SQ_ENTRY_RESET}}

`define LQ_ENTRY_RESET {61'h0, `FALSE, {`NUM_ROB{1'b0}}, {`NUM_FL{1'b0}}, {`NUM_LSQ{1'b0}}}
`define LQ_RESET '{`NUM_LSQ{`LQ_ENTRY_RESET}}

`endif
