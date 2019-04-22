`ifndef __FETCH_BUFFER_VH__
`define __FETCH_BUFFER_VH__

`ifdef PIPELINE
`include "sys_config.vh"
`include "sys_defs.vh"
`else
`include "../../sys_config.vh"
`include "../../sys_defs.vh"
`endif

typedef struct packed {
  logic [63:0] PC;
  logic [63:0] NPC;
  logic [31:0] inst;
  logic [63:0] target;
  logic        valid;
} INST_ENTRY_t;

typedef struct packed {
  logic [`NUM_SUPER-1:0][63:0] PC;
  logic [`NUM_SUPER-1:0][63:0] NPC;
  logic [`NUM_SUPER-1:0][31:0] inst;
  logic [`NUM_SUPER-1:0][63:0] target;
  logic                        valid;
} FB_DECODER_OUT_t;

`endif


//SEND RETIRE signal to PR, Told to PR freeing (freelist)
//TAKE IN CDB (tag and valid) to update the complete column.
//check the head and the complete bit is set if so retire is activated.