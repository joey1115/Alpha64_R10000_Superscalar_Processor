`ifndef __SYS_CONFIG_VH__
`define __SYS_CONFIG_VH__

`define NUM_SUPER       (2)          //DO NOT CHANGE!!!!!
`define NUM_ROB         (8)
`define NUM_PR          (`NUM_ROB + 32)
`define NUM_FL          (`NUM_ROB)
`define NUM_ALU         (1 * `NUM_SUPER)
`define NUM_MULT        (1 * `NUM_SUPER)
`define NUM_BR          (1 * `NUM_SUPER)
`define NUM_ST          (1 * `NUM_SUPER)
`define NUM_LD          (1 * `NUM_SUPER)
`define NUM_FU          (`NUM_ALU + `NUM_ST + `NUM_LD + `NUM_MULT + `NUM_BR)
`define NUM_ARCH_TABLE  (32)
`define NUM_MULT_STAGE  (8)
`define NUM_LSQ         (8)
`define NUM_BH_IDX_BITS (4)
`define NUM_FB          (8)

//D cache parameters
`define MEMORY_BLOCK_SIZE (8)
`define CACHE_SIZE        (256) //cache size in bytes
`define LINE_SIZE         (16) // multiple of 8 bytes (memory blocks)
`define ADDRESS_BITS      (64) //size of an address in bits
`define NUM_WAY           (2) //num of lines in a set (NEED MORE THAN 1 !!!!!)


`define TOTAL_LINES      (`CACHE_SIZE/`LINE_SIZE)
`define NUM_IDX          (`TOTAL_LINES / `NUM_WAY) // number of IDX, sets
`define NUM_BLOCK        (`LINE_SIZE / `MEMORY_BLOCK_SIZE) // number of BLOCKS PER LINE, block offset
`define NUM_TAG_BITS     (`ADDRESS_BITS - $clog2(`NUM_IDX) - $clog2(`NUM_BLOCK))


`define DEBUG
// `define MULT_FORWARDING

`endif
