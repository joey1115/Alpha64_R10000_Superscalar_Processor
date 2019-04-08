`ifndef __BP_VH__
`define __BP_VH__

`ifdef PIPELINE
`include "sys_config.vh"
`include "sys_defs.vh"
`else
`include "../../sys_config.vh"
`include "../../sys_defs.vh"
`endif

typedef struct packed {
  logic [`NUM_SUPER-1:0]       inst_valid;
} F_BP_OUT_t;

typedef struct packed {
  // logic [`NUM_SUPER-1:0]       branch;                    // branch or not
  logic [`NUM_SUPER-1:0]       inst_valid;
  logic [`NUM_SUPER-1:0]       take_branch_out;           // taken or not taken
  logic [63:0]                 take_branch_target_out;    // if taken, target
  logic                        rollback_en;
} BP_F_OUT_t;

`define BHT_RESET {2**`NUM_BH_IDX_BITS{2'b00}}
`define BTB_RESET {2**`NUM_BH_IDX_BITS{64'b0}}

// `define BHT_RESET { \
//   {2'b00}, \
//   {2'b00}, \
//   {2'b00}, \
//   {2'b00}, \
//   {2'b00}, \
//   {2'b00}, \
//   {2'b00}, \
//   {2'b00}, \
//   {2'b00}, \
//   {2'b00}, \
//   {2'b00}, \
//   {2'b00}, \
//   {2'b00}, \
//   {2'b00}, \
//   {2'b00}, \
//   {2'b00}  \
// }

// `define BTB_RESET { \
//   {64'b0}, \
//   {64'b0}, \
//   {64'b0}, \
//   {64'b0}, \
//   {64'b0}, \
//   {64'b0}, \
//   {64'b0}, \
//   {64'b0}, \
//   {64'b0}, \
//   {64'b0}, \
//   {64'b0}, \
//   {64'b0}, \
//   {64'b0}, \
//   {64'b0}, \
//   {64'b0}, \
//   {64'b0}  \
// }

`endif