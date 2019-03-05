`define NUM_MAP_TABLE            32
`define NUM_PR                 64

typedef struct packed {
  logic [$clog2(`NUM_PR)-1:0] PR_idx;            //PR index
  logic                       T_PLUS_STATUS;     //Tag plus state
} MAP_TABLE_t;

typedef struct packed {
  logic                       Dispatch_enable;    // no Dispatch hazard
  logic [4:0]                 Dispatch_reg_dest;  // reg from dispatch
  logic [4:0]                 Dispatch_reg_T1;
  logic [4:0]                 Dispatch_reg_T2;
  logic [$clog2(`NUM_PR)-1:0] Freelist_T;         // tags from freelist
  logic [$clog2(`NUM_PR)-1:0] CDB_T;              // broadcast from CDB
  logic                       CDB_enable;         //CDB enable
} MAP_TABLE_PACKET_IN;

typedef struct packed {
  logic [$clog2(`NUM_PR)-1:0] Told_to_ROB;       // output Told to ROB
  MAP_TABLE_t                 T1_to_RS;
  MAP_TABLE_t                 T2_to_RS;
} MAP_TABLE_PACKET_OUT;


