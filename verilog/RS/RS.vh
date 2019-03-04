
`ifndef __RS_VH__
`define __RS_VH__

`include "../../sys_config.vh"
`include "../../sys_defs.vh"

typedef struct packed {
  logic [$clog2(`NUM_PR)-1:0] idx;   // T idx
  logic                       ready; // T plus
} T_t;

typedef struct packed {
  logic                       busy;  // RS entry busy
  INST_t                      inst;
  ALU_FUNC                    func;
  logic [$clog2(`NUM_PR)-1:0] T_idx; // Dest idx
  T_t                         T1;    // T1
  T_t                         T2;    // T2
} RS_ENTRY_t;

`define FU_LIST '{      \
  {`NUM_ALU{FU_ALU}},   \
  {`NUM_MULT{FU_MULT}}, \
  {`NUM_BR{FU_BR}},     \
  {`NUM_ST{FU_ST}},     \
  {`NUM_LD{FU_LD}}      \
}

`define ZERO_PR {$clog2(`NUM_PR){1'b0}}
`define T_RESET {`ZERO_PR, 1'b0}                                                     // T reset
`define RS_ENTRY_RESET  {`FALSE, `NOOP_INST, ALU_ADDQ, `ZERO_PR, `T_RESET, `T_RESET} // RS entry reset
`define RS_RESET '{`NUM_FU{`RS_ENTRY_RESET}}                                         // RS reset

typedef struct packed {
  logic [$clog2(`NUM_PR)-1:0] dest_idx;    // Dest idx
  INST_t                      inst;        // Inst
  T_t                         T1;          // T1
  T_t                         T2;          // T2
  logic                       complete_en; // If CDB is ready
  logic                       dispatch_en; // If can be dispatched
  FU_t                        FU;          // Required FU
  ALU_FUNC                    func;        // Required ALU operation
  logic [$clog2(`NUM_PR)-1:0] CDB_T;       // CDB tag
} RS_PACKET_IN;

typedef struct packed {
  logic                       ready;  // If an entry is ready
  INST_t                      inst;
  ALU_FUNC                    func;
  logic [$clog2(`NUM_PR)-1:0] T_idx;  // Dest idx
  logic [$clog2(`NUM_PR)-1:0] T1_idx; // T1 idx
  logic [$clog2(`NUM_PR)-1:0] T2_idx; // T2 idx
} FU_PACKET_t;

`define FU_ENTRY_RESET {`FALSE, `NOOP_INST, ALU_ADDQ, `ZERO_REG, `ZERO_REG, `ZERO_REG} // FU entry reset
`define FU_RESET '{`NUM_FU{`FU_ENTRY_RESET}}                                          // FU reset

typedef struct packed {
  FU_PACKET_t [`NUM_FU-1:0]         FU_packet_out; // List of output fu
} RS_PACKET_OUT;

`endif
