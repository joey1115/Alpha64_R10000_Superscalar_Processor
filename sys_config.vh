`ifndef __SYS_CONFIG_VH__
`define __SYS_CONFIG_VH__

`define NUM_SUPER      (2)
`define NUM_ROB        (8)
`define NUM_PR         (`NUM_ROB + 32)
`define NUM_FL         (`NUM_ROB)
`define NUM_ALU        (1 * `NUM_SUPER)
`define NUM_MULT       (1 * `NUM_SUPER)
`define NUM_BR         (1 * `NUM_SUPER)
`define NUM_ST         (1 * `NUM_SUPER)
`define NUM_LD         (1 * `NUM_SUPER)
`define NUM_FU         (`NUM_ALU + `NUM_ST + `NUM_LD + `NUM_MULT + `NUM_BR)
`define NUM_ARCH_TABLE (32)
`define NUM_MULT_STAGE (8)
`define NUM_BH_IDX_BITS (4)
`define NUM_FB         (8)

`define DEBUG
// `define MULT_FORWARDING

`endif
