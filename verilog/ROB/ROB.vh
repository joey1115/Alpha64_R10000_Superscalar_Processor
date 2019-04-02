`ifndef __ROB_VH__
`define __ROB_VH__

`ifdef PIPELINE
`include "sys_config.vh"
`include "sys_defs.vh"
`else
`include "../../sys_config.vh"
`include "../../sys_defs.vh"
`endif

typedef struct packed {
  logic valid;
  logic [$clog2(`NUM_PR)-1:0] T_idx;
  logic [$clog2(`NUM_PR)-1:0] Told_idx;
  logic [$clog2(`NUM_ARCH_TABLE)-1:0] dest_idx;
  logic complete;
  logic halt;
  logic illegal;
} ROB_ENTRY_t;

typedef struct packed {
  logic [$clog2(`NUM_ROB)-1:0] head;
  logic [$clog2(`NUM_ROB)-1:0] tail;
  ROB_ENTRY_t [`NUM_ROB-1:0] entry;
} ROB_t;

typedef struct packed {
  logic [`NUM_SUPER-1:0] [$clog2(`NUM_PR)-1:0] T_idx;            // T_idx at head to retire to archmap
  logic [`NUM_SUPER-1:0] [4:0]                 dest_idx;         // T_idx at head to retire to archmap
} ROB_ARCH_MAP_OUT_t;

typedef struct packed {
  logic [`NUM_SUPER-1:0] [$clog2(`NUM_PR)-1:0] Told_idx;            // T_idx at head to retire to archmap
} ROB_FL_OUT_t;

`endif


//SEND RETIRE signal to PR, Told to PR freeing (freelist)
//TAKE IN CDB (tag and valid) to update the complete column.
//check the head and the complete bit is set if so retire is activated.