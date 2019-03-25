`ifndef __CT_VH__
`define __CT_VH__

`ifdef PIPELINE
`include "sys_config.vh"
`include "sys_defs.vh"
`include "verilog/RS/RS.vh"
`else
`include "../../sys_config.vh"
`include "../../sys_defs.vh"
`include "../RS/RS.vh"
`endif

typedef struct packed {
  logic taken;
  logic [$clog2(`NUM_PR)-1:0]  T_idx;
  logic [$clog2(`NUM_ROB)-1:0] ROB_idx;
  logic [4:0]                  dest_idx;
  logic [63:0]                 T_value;
} CDB_entry_t;

typedef struct packed {
  logic                        FU_done;
  logic [63:0]                 FU_result;
  logic [4:0]                  dest_idx;
  logic [$clog2(`NUM_PR)-1:0]  T_idx;   // Dest idx
  logic [$clog2(`NUM_ROB)-1:0] ROB_idx; // Dest idx
  logic [$clog2(`NUM_FL)-1:0]  FL_idx;  // Dest idx
} FU_CDB_ENTRY_t;

typedef struct packed {
  logic [`NUM_FU-1:0]                        CDB_valid;     // valid=0, entry is free, to FU
  logic                                      complete_en;   // RS, ROB, MapTable
  logic                                      write_en;      // valid signal to PR
  logic               [$clog2(`NUM_PR)-1:0]  T_idx;         // tag to PR
  logic               [4:0]                  dest_idx;      // to map_table
  logic               [63:0]                 T_value;       // result to PR
  logic               [$clog2(`NUM_ROB)-1:0] ROB_idx;
} CDB_PACKET_OUT;

`endif
