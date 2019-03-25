`ifndef __MAP_TABLE_VH__
`define __MAP_TABLE_VH__

`ifdef PIPELINE
`include "sys_config.vh"
`include "sys_defs.vh"
`include "verilog/RS/RS.vh"
`else
`include "../../sys_config.vh"
`include "../../sys_defs.vh"
`include "../RS/RS.vh"
`endif

`define MAP_TABLE_RESET '{                       \
  {{{($clog2(`NUM_PR)-5){1'b0}}, 5'h1f}, `TRUE}, \
  {{{($clog2(`NUM_PR)-5){1'b0}}, 5'h1e}, `TRUE}, \
  {{{($clog2(`NUM_PR)-5){1'b0}}, 5'h1d}, `TRUE}, \
  {{{($clog2(`NUM_PR)-5){1'b0}}, 5'h1c}, `TRUE}, \
  {{{($clog2(`NUM_PR)-5){1'b0}}, 5'h1b}, `TRUE}, \
  {{{($clog2(`NUM_PR)-5){1'b0}}, 5'h1a}, `TRUE}, \
  {{{($clog2(`NUM_PR)-5){1'b0}}, 5'h19}, `TRUE}, \
  {{{($clog2(`NUM_PR)-5){1'b0}}, 5'h18}, `TRUE}, \
  {{{($clog2(`NUM_PR)-5){1'b0}}, 5'h17}, `TRUE}, \
  {{{($clog2(`NUM_PR)-5){1'b0}}, 5'h16}, `TRUE}, \
  {{{($clog2(`NUM_PR)-5){1'b0}}, 5'h15}, `TRUE}, \
  {{{($clog2(`NUM_PR)-5){1'b0}}, 5'h14}, `TRUE}, \
  {{{($clog2(`NUM_PR)-5){1'b0}}, 5'h13}, `TRUE}, \
  {{{($clog2(`NUM_PR)-5){1'b0}}, 5'h12}, `TRUE}, \
  {{{($clog2(`NUM_PR)-5){1'b0}}, 5'h11}, `TRUE}, \
  {{{($clog2(`NUM_PR)-5){1'b0}}, 5'h10}, `TRUE}, \
  {{{($clog2(`NUM_PR)-5){1'b0}}, 5'h0f}, `TRUE}, \
  {{{($clog2(`NUM_PR)-5){1'b0}}, 5'h0e}, `TRUE}, \
  {{{($clog2(`NUM_PR)-5){1'b0}}, 5'h0d}, `TRUE}, \
  {{{($clog2(`NUM_PR)-5){1'b0}}, 5'h0c}, `TRUE}, \
  {{{($clog2(`NUM_PR)-5){1'b0}}, 5'h0b}, `TRUE}, \
  {{{($clog2(`NUM_PR)-5){1'b0}}, 5'h0a}, `TRUE}, \
  {{{($clog2(`NUM_PR)-5){1'b0}}, 5'h09}, `TRUE}, \
  {{{($clog2(`NUM_PR)-5){1'b0}}, 5'h08}, `TRUE}, \
  {{{($clog2(`NUM_PR)-5){1'b0}}, 5'h07}, `TRUE}, \
  {{{($clog2(`NUM_PR)-5){1'b0}}, 5'h06}, `TRUE}, \
  {{{($clog2(`NUM_PR)-5){1'b0}}, 5'h05}, `TRUE}, \
  {{{($clog2(`NUM_PR)-5){1'b0}}, 5'h04}, `TRUE}, \
  {{{($clog2(`NUM_PR)-5){1'b0}}, 5'h03}, `TRUE}, \
  {{{($clog2(`NUM_PR)-5){1'b0}}, 5'h02}, `TRUE}, \
  {{{($clog2(`NUM_PR)-5){1'b0}}, 5'h01}, `TRUE}, \
  {{{($clog2(`NUM_PR)-5){1'b0}}, 5'h00}, `TRUE}  \
}

`define MAP_TABLE_STACK_ENTRY_RESET {            \
  {{{($clog2(`NUM_PR)-5){1'b0}}, 5'h1f}, `TRUE}, \
  {{{($clog2(`NUM_PR)-5){1'b0}}, 5'h1e}, `TRUE}, \
  {{{($clog2(`NUM_PR)-5){1'b0}}, 5'h1d}, `TRUE}, \
  {{{($clog2(`NUM_PR)-5){1'b0}}, 5'h1c}, `TRUE}, \
  {{{($clog2(`NUM_PR)-5){1'b0}}, 5'h1b}, `TRUE}, \
  {{{($clog2(`NUM_PR)-5){1'b0}}, 5'h1a}, `TRUE}, \
  {{{($clog2(`NUM_PR)-5){1'b0}}, 5'h19}, `TRUE}, \
  {{{($clog2(`NUM_PR)-5){1'b0}}, 5'h18}, `TRUE}, \
  {{{($clog2(`NUM_PR)-5){1'b0}}, 5'h17}, `TRUE}, \
  {{{($clog2(`NUM_PR)-5){1'b0}}, 5'h16}, `TRUE}, \
  {{{($clog2(`NUM_PR)-5){1'b0}}, 5'h15}, `TRUE}, \
  {{{($clog2(`NUM_PR)-5){1'b0}}, 5'h14}, `TRUE}, \
  {{{($clog2(`NUM_PR)-5){1'b0}}, 5'h13}, `TRUE}, \
  {{{($clog2(`NUM_PR)-5){1'b0}}, 5'h12}, `TRUE}, \
  {{{($clog2(`NUM_PR)-5){1'b0}}, 5'h11}, `TRUE}, \
  {{{($clog2(`NUM_PR)-5){1'b0}}, 5'h10}, `TRUE}, \
  {{{($clog2(`NUM_PR)-5){1'b0}}, 5'h0f}, `TRUE}, \
  {{{($clog2(`NUM_PR)-5){1'b0}}, 5'h0e}, `TRUE}, \
  {{{($clog2(`NUM_PR)-5){1'b0}}, 5'h0d}, `TRUE}, \
  {{{($clog2(`NUM_PR)-5){1'b0}}, 5'h0c}, `TRUE}, \
  {{{($clog2(`NUM_PR)-5){1'b0}}, 5'h0b}, `TRUE}, \
  {{{($clog2(`NUM_PR)-5){1'b0}}, 5'h0a}, `TRUE}, \
  {{{($clog2(`NUM_PR)-5){1'b0}}, 5'h09}, `TRUE}, \
  {{{($clog2(`NUM_PR)-5){1'b0}}, 5'h08}, `TRUE}, \
  {{{($clog2(`NUM_PR)-5){1'b0}}, 5'h07}, `TRUE}, \
  {{{($clog2(`NUM_PR)-5){1'b0}}, 5'h06}, `TRUE}, \
  {{{($clog2(`NUM_PR)-5){1'b0}}, 5'h05}, `TRUE}, \
  {{{($clog2(`NUM_PR)-5){1'b0}}, 5'h04}, `TRUE}, \
  {{{($clog2(`NUM_PR)-5){1'b0}}, 5'h03}, `TRUE}, \
  {{{($clog2(`NUM_PR)-5){1'b0}}, 5'h02}, `TRUE}, \
  {{{($clog2(`NUM_PR)-5){1'b0}}, 5'h01}, `TRUE}, \
  {{{($clog2(`NUM_PR)-5){1'b0}}, 5'h00}, `TRUE}  \
}

`define MAP_TABLE_STACK_RESET '{`NUM_ROB{`MAP_TABLE_STACK_ENTRY_RESET}}

typedef struct packed {
  logic [$clog2(`NUM_PR)-1:0]   T_idx;            // tags from freelist
  logic [$clog2(`NUM_PR)-1:0]   CDB_T_idx;        // broadcast from CDB
  logic [4:0]                   CDB_dest_idx;     // broadcast from CDB
  logic                         CDB_en;           // CDB enable
  logic [$clog2(`NUM_ROB)-1:0]  ROB_rollback_idx;
  logic [$clog2(`NUM_ROB)-1:0]  ROB_tail_idx;
} MAP_TABLE_PACKET_IN;

typedef struct packed {
  logic [$clog2(`NUM_PR)-1:0] Told_idx;           // output Told to ROB
  T_t                         T1;
  T_t                         T2;
} MAP_TABLE_PACKET_OUT;

typedef struct packed {
  T_t T1;
  T_t T2;
} MAP_TABLE_RS_OUT_t;

`endif
