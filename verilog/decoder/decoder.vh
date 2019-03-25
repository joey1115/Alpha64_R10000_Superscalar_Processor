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

// typedef struct packed {
//   INST_t                inst;  // fetched instruction out
//   logic          [63:0] NPC;  // fetched instruction out
//   ALU_OPA_SELECT        opa_select;  // fetched instruction out
//   ALU_OPB_SELECT        opb_select;
//   ALU_FUNC              alu_func;
//   logic                 rd_mem, wr_mem, ldl_mem, stc_mem, cond_branch, uncond_branch;
//   logic                 halt;      // non-zero on a halt
//   logic                 cpuid;     // get CPUID instruction
//   logic                 illegal;   // non-zero on an illegal instruction
//   logic                 valid; // for counting valid instructions executed
//   logic          [4:0]  dest_idx;
//   FU_t                  FU;
//   logic          [4:0]  func;
// } DECODER_PACKET_OUT;

// `define DECODER_PACKET_OUT_DEFAULT '{ \
//   `NOOP_INST,                         \
//   64'h0,                              \
//   ALU_OPA_IS_REGA,                    \
//   ALU_OPB_IS_REGB,                    \
//   ALU_ADDQ,                           \
//   `FALSE,                             \
//   `FALSE,                             \
//   `FALSE,                             \
//   `FALSE,                             \
//   `FALSE,                             \
//   `FALSE,                             \
//   `FALSE,                             \
//   `FALSE,                             \
//   `FALSE,                             \
//   `FALSE,                             \
//   `ZERO_REG,                          \
//   FU_ALU,                             \
//   ALU_ADDQ                            \
// }

typedef struct packed {
  FU_t                  FU;
  INST_t                inst;  // fetched instruction out
  ALU_FUNC              func;
  logic          [63:0] NPC;  // fetched instruction out
  logic          [4:0]  dest_idx;
  ALU_OPA_SELECT        opa_select;  // fetched instruction out
  ALU_OPB_SELECT        opb_select;
} DECODER_RS_OUT_t;

typedef struct packed {
  logic          [4:0]  dest_idx;
} DECODER_FL_OUT_t;

`endif
