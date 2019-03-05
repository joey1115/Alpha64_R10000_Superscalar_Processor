`define NUM_ARCH_MAP            32

typedef struct packed {
  logic                       r;   // retire enable
  logic [$clog2(`NUM_PR)-1:0] Rob_retire_Told;  // Told from ROB
  logic [$clog2(`NUM_PR)-1:0] Rob_retire_T;     // T from ROB
} ARCH_MAP_PACKET_IN;

typedef struct packed {
} ARCH_MAP_PACKET_OUT;

typedef struct packed {
  logic [$clog2(`NUM_PR)-1:0] PR_idx;           // PR index
} ARCH_MAP_t;
