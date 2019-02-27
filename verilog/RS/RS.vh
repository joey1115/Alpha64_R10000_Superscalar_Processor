
`ifndef __RS_VH__
`define __RS_VH__

`include "../../sys_config.vh"
`include "../../sys_defs.vh"

`define FU_list { FU_ALU, FU_ST, FU_LD, FU_FP1, FU_FP2 }
`define RS_RESET '{ \
  {FU_ALU, `FALSE, 0, 0, 0}, \
  {FU_ST,  `FALSE, 0, 0, 0}, \
  {FU_LD,  `FALSE, 0, 0, 0}, \
  {FU_FP1, `FALSE, 0, 0, 0}, \
  {FU_FP2, `FALSE, 0, 0, 0}, \
}

typedef struct packed {
  FU_t                        FU;
  logic                       busy;
  // logic [5:0]                 op;
  logic [$clog2(`NUM_PR)-1:0] T;
  T_t                         T1;
  T_t                         T2;
} RS_ENTRY_t;

typedef struct packed {
  
} RS_PACKET_IN;

typedef struct packed {

} RS_PACKET_OUT;

`endif
