`define NUM_MAP_TABLE            32

typedef struct packed {
  logic                       Dispatch_enable;   // no Dispatch hazard
  logic [4:0]                 Dispatch_reg_idx;  // reg from dispatch
  logic [$clog2(`NUM_PR)-1:0] CDB_T;             // broadcast from CDB
  logic 					  CDB_enable;
  logic [$clog2(`NUM_PR)-1:0] Freelist_T;        // tags from freelist
} MAP_TABLE_PACKET_IN;

typedef struct packed {
  logic [$clog2(`NUM_PR)-1:0] T1_to_RS;          // output T1 to RS
  logic [$clog2(`NUM_PR)-1:0] T2_to_RS;          // output T2 to RS
  logic [$clog2(`NUM_PR)-1:0] Told_to_ROB;       // output Told to ROB
} MAP_TABLE_PACKET_OUT;

typedef struct packed {
  logic [$clog2(`NUM_PR)-1:0] PR_idx;
  logic                       T_PLUS_STATUS;
} MAP_TABLE_t;
