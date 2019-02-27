`include "../../sys_defs.vh"

typedef struct packed {
  logic valid;
  logic [$clog2(`NUM_PR)-1:0] T;
  logic [$clog2(`NUM_PR)-1:0] T_old;
} ROB_ENTRY_t;

typedef struct packed {
  logic [$clog2(`NUM_ROB)-1:0] head;
  logic [$clog2(`NUM_ROB)-1:0] tail;
  ROB_ENTRY_t [`NUM_ROB-1:0] entry;
} ROB_t;

typedef struct packed {
  logic r;
  logic inst_dispatch;
  logic [$clog2(`NUM_PR)-1:0] T_in;
  logic [$clog2(`NUM_PR)-1:0] T_old_in;
} ROB_PACKET_IN;

typedef struct packed {
  logic [$clog2(`NUM_PR)-1:0] T_out;
  logic [$clog2(`NUM_PR)-1:0] T_old_out;
  logic out_correct;
  logic struct_hazard;
  logic [$clog2(`NUM_ROB)-1:0] head_idx_out;
  logic [$clog2(`NUM_ROB)-1:0] ins_rob_idx;
} ROB_PACKET_OUT;
