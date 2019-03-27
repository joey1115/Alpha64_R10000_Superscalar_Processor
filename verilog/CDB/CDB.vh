`ifndef __CT_VH__
`define __CT_VH__

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
  logic taken;
  logic [$clog2(`NUM_PR)-1:0]  T_idx;
  logic [$clog2(`NUM_ROB)-1:0] ROB_idx;
  logic [4:0]                  dest_idx;
  logic [63:0]                 T_value;
} CDB_entry_t;

`define CDB_RENTRY_RESET {`FALSE, `ZERO_PR, {$clog2(`NUM_ROB){1'b0}}, `ZERO_REG, 64'hbaadbeefdeadbeef}
`define CDB_RENTRY_RESET_PACKED '{`FALSE, `ZERO_PR, 0, `ZERO_REG, 64'hbaadbeefdeadbeef}
`define CDB_RESET '{`NUM_FU{`CDB_RENTRY_RESET}}

typedef struct packed {
  logic [$clog2(`NUM_ROB)-1:0] ROB_idx;         // tag to PR
} CDB_ROB_OUT_t;

typedef struct packed {
  logic [$clog2(`NUM_PR)-1:0] T_idx;         // tag to PR
} CDB_RS_OUT_t;

typedef struct packed {
  logic [$clog2(`NUM_PR)-1:0] T_idx;        // broadcast from CDB
  logic [4:0]                 dest_idx;     // broadcast from CDB
} CDB_MAP_TABLE_OUT_t;

typedef struct packed {
  logic [$clog2(`NUM_PR)-1:0] T_idx;        // broadcast from CDB
  logic [63:0]                T_value;     // broadcast from CDB
} CDB_PR_OUT_t;

`endif
