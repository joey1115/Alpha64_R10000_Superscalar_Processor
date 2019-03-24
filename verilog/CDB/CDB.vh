
`ifndef __CDB_VH__
`define __CDB_VH__

`ifdef PIPELINE
`include "sys_config.vh"
`include "sys_defs.vh"
`else
`include "../../sys_config.vh"
`include "../../sys_defs.vh"
`endif

typedef struct packed {
  logic C_en;                                     // complete enable
  logic [$clog2(`NUM_PR)-1:0] C_T;                // complete tag
} CDB_PACKET_IN;


typedef struct packed {
  logic CDB_en;                                   // CDB enbale
  logic [$clog2(`NUM_PR)-1:0] CDB_T;              // CDB tag
} CDB_PACKET_OUT;

`endif
