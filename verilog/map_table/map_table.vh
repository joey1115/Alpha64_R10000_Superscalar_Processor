`ifndef __MAP_TABLE_VH__
`define __MAP_TABLE_VH__

`include "../../sys_config.vh"

typedef struct packed {
  logic [4:0] reg_idx;
  T_t         T_plus;
} MAP_TABLE_t;

`endif
