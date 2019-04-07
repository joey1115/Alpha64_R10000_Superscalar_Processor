`ifndef __LSQ_VH__
`define __LSQ_VH__

`ifdef PIPELINE
`include "sys_config.vh"
`include "sys_defs.vh"
`else
`include "../../sys_config.vh"
`include "../../sys_defs.vh"
`include "../decoder/decoder.vh"
`endif

typedef struct packed {
  logic [60:0] addr;
  logic        valid;
  logic [63:0] value;
} SQ_ENTRY_t;

typedef struct packed {
  logic [`NUM_SUPER-1:0] dispatch_valid;
  logic [`NUM_SUPER-1:0] retire_valid;
} SQ_ROB_OUT_t;

typedef struct packed {
  logic [`NUM_SUPER-1:0][$clog2(NUM_LSQ)-1:0] SQ_idx;
} SQ_RS_OUT_t;

typedef struct packed {
  logic [`NUM_SUPER-1:0]       LD_valid;
  logic [`NUM_SUPER-1:0][63:0] LD_value;
} SQ_LQ_OUT_t;

typedef struct packed {
  logic [`NUM_SUPER-1:0]       wr_en;
  logic [`NUM_SUPER-1:0][60:0] addr;
  logic [`NUM_SUPER-1:0][63:0] value;
} SQ_D_CACHE_OUT_t;

typedef struct packed {
  logic [60:0] addr;
  logic        valid;
} LQ_ENTRY_t;

`define SQ_ENTRY_RESET {61'h0, `FALSE, 64'hbaadbeafdeadbeef}
`define SQ_ENTRY_RESET_PACKED '{61'h0, `FALSE, 64'hbaadbeafdeadbeef}
`define SQ_RESET '{`NUM_LSQ{`SQ_ENTRY_RESET}}

`define LQ_ENTRY_RESET {61'h0, `FALSE}
`define LQ_ENTRY_RESET_PACKED '{61'h0, `FALSE}
`define LQ_RESET '{`NUM_LSQ{`LQ_ENTRY_RESET}}

`endif
