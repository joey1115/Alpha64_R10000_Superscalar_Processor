`ifndef __DECODER_VH__
`define __DECODER_VH__

`ifdef PIPELINE
`include "sys_config.vh"
`include "sys_defs.vh"
`else
`include "../../sys_config.vh"
`include "../../sys_defs.vh"
`endif

`define DECODER_PACKET_IN_RESET '{`NOOP_INST, `FALSE}

typedef struct packed {
  INST_t        inst;  // fetched instruction out
  logic  [63:0] NPC;  // fetched instruction out
  logic         valid; // PC + 4 
} DECODER_PACKET_IN;

typedef struct packed {
  logic        halt;
  logic [4:0]  dest_idx;
} DECODER_ROB_OUT_t;

typedef struct packed {
  FU_t                  FU;
  INST_t                inst;  // fetched instruction out
  ALU_FUNC              func;
  logic          [63:0] NPC;  // fetched instruction out
  logic          [4:0]  dest_idx;
  ALU_OPA_SELECT        opa_select;  // fetched instruction out
  ALU_OPB_SELECT        opb_select;
  logic                 cond_branch;
  logic                 uncond_branch;
} DECODER_RS_OUT_t;

typedef struct packed {
  logic          [4:0]  dest_idx;
} DECODER_FL_OUT_t;

typedef struct packed {
  logic [4:0] dest_idx;
  logic [4:0] rega_idx;
  logic [4:0] regb_idx;
} DECODER_MAP_TABLE_OUT_t;

`endif
