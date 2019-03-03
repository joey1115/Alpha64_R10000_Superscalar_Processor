
`ifndef __RS_VH__
`define __RS_VH__

`include "../../sys_config.vh"
`include "../../sys_defs.vh"

typedef struct packed {
  logic [$clog2(`NUM_PR)-1:0] idx;
  logic                       ready;
} T_t;

typedef struct packed {
  // FU_t                        FU;
  logic                       busy;
  // logic [5:0]                 op;
  logic [$clog2(`NUM_PR)-1:0] T_idx;
  T_t                         T1;
  T_t                         T2;
} RS_ENTRY_t;

`define FU_LIST '{ \
  {`NUM_ALU{FU_ALU}}, \
  {`NUM_MULT{FU_MULT}}, \
  {`NUM_ST{FU_ST}}, \
  {`NUM_LD{FU_LD}} \
}

`define T_RESET {`ZERO_REG, 1'b0}
`define RS_ENTRY_RESET  {`FALSE, `ZERO_REG, `T_RESET, `T_RESET}
`define RS_RESET '{`NUM_FU{`RS_ENTRY_RESET}}

typedef struct packed {
  logic [$clog2(`NUM_PR)-1:0] dest_idx;
  T_t                         T1;
  T_t                         T2;
  logic                       complete_en;
  // logic [`NUM_FU-1:0]         FU_ready_list;
  logic                       dispatch_en;
  FU_t                        FU;
  logic [$clog2(`NUM_PR)-1:0] CDB_T;
} RS_PACKET_IN;

typedef struct packed {
  logic                       ready;
  logic [$clog2(`NUM_PR)-1:0] T_idx;
  logic [$clog2(`NUM_PR)-1:0] T1_idx;
  logic [$clog2(`NUM_PR)-1:0] T2_idx;
} FU_PACKET_t;

typedef struct packed {
  logic                             valid;
  // logic       [$clog2(`NUM_FU)-1:0] FU_idx;
  FU_PACKET_t [`NUM_FU-1:0]         FU_packet_out;
  RS_ENTRY_t  [`NUM_FU-1:0]         RS;
} RS_PACKET_OUT;

`endif
