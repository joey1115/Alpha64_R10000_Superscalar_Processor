`ifndef __DECODER_VH__
`define __DECODER_VH__

`ifdef PIPELINE
`include "sys_config.vh"
`include "sys_defs.vh"
`else
`include "../../sys_config.vh"
`include "../../sys_defs.vh"
`endif

typedef union packed {
  logic [31:0] I;
  struct packed {
    logic [2:0] op;
    logic [2:0] br_func;
    logic [4:0] rega_idx;
    logic [4:0] regb_idx;
    logic [3:0] m;
    logic [6:0] func;
    logic [4:0] regc_idx;
  } r; //reg
  struct packed {
    logic [5:0] opcode;
    logic [4:0] rega_idx;
    logic [7:0] LIT;
    logic       IMM;
    logic [6:0] func;
    logic [4:0] regc_idx;
  } i; //IMM
  struct packed {
    logic [5:0]  opcode;
    logic [4:0]  rega_idx;
    logic [4:0]  regb_idx;
    logic [15:0] mem_disp;
  } m; //memory with displacement inst
  // struct packed {
  //   logic [5:0] opcode;
  //   logic [4:0] rega_idx;
  //   logic [4:0] regb_idx;
  //   logic [15:0] func;
  // } m_func; //memory with function inst
  struct packed {
    logic [5:0]  opcode;
    logic [4:0]  rega_idx;
    logic [20:0] branch_disp;
  } b; //Branch inst
  // struct packed {
  //   logic [5:0] opcode;
  //   logic [4:0] rega_idx;
  //   logic [4:0] regb_idx;
  //   logic [2:0] SBZ;
  //   logic       IMM;
  //   logic [6:0] func;
  //   logic [4:0] regc_idx;
  // } op; //operate inst
  // struct packed {
  //   logic [5:0] opcode;
  //   logic [4:0] rega_idx;
  //   logic [7:0] LIT;
  //   logic       IMM;
  //   logic [6:0] func;
  //   logic [4:0] regc_idx;
  // } op_imm; //operate immediate inst
// `ifdef FLOATING_POINT_INST
//   struct packed {
//     logic [5:0] opcode;
//     logic [4:0] rega_idx;
//     logic [4:0] regb_idx;
//     logic [10:0] func;
//     logic [4:0] regc_idx;
//   } opf;  //floating point inst
// `endif
  struct packed {
    logic [5:0] opcode;
    logic [25:0] func;
  } p; //pal inst
} INST_t; //instruction typedef, this should cover all types of instructions

typedef enum logic [2:0] {
  FU_ALU  = 3'b000,
  FU_ST   = 3'b001,
  FU_LD   = 3'b010,
  FU_MULT = 3'b011,
  FU_BR   = 3'b100,
  FU_NONE = 3'b101
} FU_t;

typedef struct packed {
  logic                            valid; // If low, the data in this struct is garbage
  INST_t [`NUM_SUPER-1:0]          inst;  // fetched instruction out
  logic  [`NUM_SUPER-1:0][63:0]    NPC; // PC + 4 
} F_DECODER_OUT_t;

`define F_DECODER_OUT_RESET '{ \
  `FALSE,                      \
  `NOOP_INST,                  \
  0                            \
}

typedef struct packed {
  INST_t        inst;  // fetched instruction out
  logic  [63:0] NPC;  // fetched instruction out
  logic         valid; // PC + 4 
} DECODER_PACKET_IN;

typedef struct packed {
  logic [`NUM_SUPER-1:0]       halt;
  logic [`NUM_SUPER-1:0][4:0]  dest_idx;
  logic [`NUM_SUPER-1:0]       illegal;
  logic [`NUM_SUPER-1:0][63:0] NPC;
} DECODER_ROB_OUT_t;

typedef struct packed {
  FU_t           [`NUM_SUPER-1:0]       FU;
  INST_t         [`NUM_SUPER-1:0]       inst;  // fetched instruction out
  ALU_FUNC       [`NUM_SUPER-1:0]       func;
  logic          [`NUM_SUPER-1:0][63:0] NPC;  // fetched instruction out
  logic          [`NUM_SUPER-1:0][4:0]  dest_idx;
  ALU_OPA_SELECT [`NUM_SUPER-1:0]       opa_select;  // fetched instruction out
  ALU_OPB_SELECT [`NUM_SUPER-1:0]       opb_select;
  logic          [`NUM_SUPER-1:0]       cond_branch;
  logic          [`NUM_SUPER-1:0]       uncond_branch;
} DECODER_RS_OUT_t;

typedef struct packed {
  logic          [`NUM_SUPER-1:0][4:0]  dest_idx;
} DECODER_FL_OUT_t;

typedef struct packed {
  logic [`NUM_SUPER-1:0][4:0] dest_idx;
  logic [`NUM_SUPER-1:0][4:0] rega_idx;
  logic [`NUM_SUPER-1:0][4:0] regb_idx;
} DECODER_MAP_TABLE_OUT_t;

`endif
