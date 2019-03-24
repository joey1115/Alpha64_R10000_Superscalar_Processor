
`ifndef __Arch_Map_VH__
`define __Arch_Map_VH__

`ifdef PIPELINE
`include "sys_config.vh"
`include "sys_defs.vh"
`else
`include "../../sys_config.vh"
`include "../../sys_defs.vh"
`endif

typedef struct packed {
  logic [$clog2(`NUM_PR)-1:0] Told_idx;  // Told from ROB
  logic [$clog2(`NUM_PR)-1:0] T_idx;     // T from ROB
} ARCH_MAP_PACKET_IN;

typedef struct packed {
  logic [$clog2(`NUM_PR)-1:0] T_idx;           // PR index
} ARCH_MAP_t;

`define ARCH_MAP_RESET    '{            \
  {{($clog2(`NUM_PR)-5){1'b0}}, 5'h1f}, \
  {{($clog2(`NUM_PR)-5){1'b0}}, 5'h1e}, \
  {{($clog2(`NUM_PR)-5){1'b0}}, 5'h1d}, \
  {{($clog2(`NUM_PR)-5){1'b0}}, 5'h1c}, \
  {{($clog2(`NUM_PR)-5){1'b0}}, 5'h1b}, \
  {{($clog2(`NUM_PR)-5){1'b0}}, 5'h1a}, \
  {{($clog2(`NUM_PR)-5){1'b0}}, 5'h19}, \
  {{($clog2(`NUM_PR)-5){1'b0}}, 5'h18}, \
  {{($clog2(`NUM_PR)-5){1'b0}}, 5'h17}, \
  {{($clog2(`NUM_PR)-5){1'b0}}, 5'h16}, \
  {{($clog2(`NUM_PR)-5){1'b0}}, 5'h15}, \
  {{($clog2(`NUM_PR)-5){1'b0}}, 5'h14}, \
  {{($clog2(`NUM_PR)-5){1'b0}}, 5'h13}, \
  {{($clog2(`NUM_PR)-5){1'b0}}, 5'h12}, \
  {{($clog2(`NUM_PR)-5){1'b0}}, 5'h11}, \
  {{($clog2(`NUM_PR)-5){1'b0}}, 5'h10}, \
  {{($clog2(`NUM_PR)-5){1'b0}}, 5'h0f}, \
  {{($clog2(`NUM_PR)-5){1'b0}}, 5'h0e}, \
  {{($clog2(`NUM_PR)-5){1'b0}}, 5'h0d}, \
  {{($clog2(`NUM_PR)-5){1'b0}}, 5'h0c}, \
  {{($clog2(`NUM_PR)-5){1'b0}}, 5'h0b}, \
  {{($clog2(`NUM_PR)-5){1'b0}}, 5'h0a}, \
  {{($clog2(`NUM_PR)-5){1'b0}}, 5'h09}, \
  {{($clog2(`NUM_PR)-5){1'b0}}, 5'h08}, \
  {{($clog2(`NUM_PR)-5){1'b0}}, 5'h07}, \
  {{($clog2(`NUM_PR)-5){1'b0}}, 5'h06}, \
  {{($clog2(`NUM_PR)-5){1'b0}}, 5'h05}, \
  {{($clog2(`NUM_PR)-5){1'b0}}, 5'h04}, \
  {{($clog2(`NUM_PR)-5){1'b0}}, 5'h03}, \
  {{($clog2(`NUM_PR)-5){1'b0}}, 5'h02}, \
  {{($clog2(`NUM_PR)-5){1'b0}}, 5'h01}, \
  {{($clog2(`NUM_PR)-5){1'b0}}, 5'h00}  \
}

`endif