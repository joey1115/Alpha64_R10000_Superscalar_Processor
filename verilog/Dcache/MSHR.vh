`ifndef __MSHR_VH__
`define __MSHR_VH__

`ifdef PIPELINE
`include "sys_config.vh"
`include "sys_defs.vh"
`include "verilog/Dcache/Dcache.vh"
`else
`include "../../sys_config.vh"
`include "../../sys_defs.vh"
`include "./Dcache.vh"
`endif

typedef enum logic {
  STORE        = 2'b00,
  LOAD         = 2'b01,
  EVICT        = 2'b10
} MSHR_INST_TYPE;

typedef enum logic {
  INPROGRESS      = 2'b00,
  WAITING         = 2'b01,
  DONE            = 2'b10
} MSHR_STATE;

typedef struct packed {
  logic                             valid;
  logic [(`MEMORY_BLOCK_SIZE*8-1):0] data;
  logic                             dirty;
  SASS_ADDR                         addr;
  MSHR_INST_TYPE                    inst_type;
  logic [1:0]                       proc2mem_command;
  logic                             complete;
  logic [3:0]                       mem_tag;
  MSHR_STATE                        state;
} MSHR_ENTRY_t;

`endif