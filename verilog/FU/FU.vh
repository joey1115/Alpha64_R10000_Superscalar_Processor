
`ifndef __FU_VH__
`define __FU_VH__

`include "../../sys_config.vh"
`include "../../sys_defs.vh"
`include "../RS/RS.vh"

typedef struct packed {
  logic        ready;                           // is the input ready
  INST         inst;
  logic [63:0] T1_value;                        // T1 value from PR
  logic [63:0] T2_value;                        // T2 value from PR
  ALU_FUNC     func;                            // function unit type
} FU_PACKET_IN_t;

typedef struct packed {
  FU_PACKET_IN_t [`NUM_FU-1:0] fu_packet;          // there are many FU
} FU_PACKET_IN;

typedef struct packed {
  logic        done;                            // ALU result ready?
  logic [63:0] result;                          // ALU result
} ALU_RESULT_ENTRY_t;

typedef struct packed {
  ALU_RESULT_ENTRY_t [`NUM_ALU-1:0] alu_result; // ALU output
  logic             [`NUM_BR-1:0]  br_cond;     // branch condition
} FU_PACKET_OUT;


`endif
