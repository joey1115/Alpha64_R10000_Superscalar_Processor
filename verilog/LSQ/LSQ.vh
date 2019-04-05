
typedef struct packed {
  logic [60:0] addr;
  logic        valid;
  logic [63:0] value;
} SQ_ENTRY_t;

typedef struct packed {
  logic [60:0] addr;
} LQ_ENTRY_t;

`define SQ_ENTRY_RESET {61'h0, `FALSE, 64'hbaadbeafdeadbeef}
`define SQ_ENTRY_RESET_PACKED '{61'h0, `FALSE, 64'hbaadbeafdeadbeef}
`define SQ_RESET '{`NUM_LSQ{`SQ_ENTRY_RESET}}
