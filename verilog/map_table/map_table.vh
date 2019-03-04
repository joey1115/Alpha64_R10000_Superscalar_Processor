`define NUM_MAP_TABLE            32

typedef struct packed {
  logic                       Dispatch_enable;   // no Dispatch hazard
  logic [4:0]                 Dispatch_reg_dest;  // reg from dispatch
  logic [$clog2(`NUM_PR)-1:0] CDB_T;             // broadcast from CDB
  logic 					            CDB_enable;        //CDB enable
  logic [$clog2(`NUM_PR)-1:0] Freelist_T;        // tags from freelist
} MAP_TABLE_PACKET_IN;

typedef struct packed {
  logic [$clog2(`NUM_PR)-1:0] Told_to_ROB;       // output Told to ROB
} MAP_TABLE_PACKET_OUT;

typedef struct packed {
  logic [$clog2(`NUM_PR)-1:0] PR_idx;            //PR index
  logic                       T_PLUS_STATUS;     //Tag plus state
} MAP_TABLE_t;
