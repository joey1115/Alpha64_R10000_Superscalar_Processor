`define NUM_WAY       2;    // 2 way associativity
`define NUM_SET       4;    // 4 sets/way
`define NUM_LINE      4;    // 4 lines/set
`define NUM_BLOCK     8;    // 8 bytes/block(line)
`define NUM_TOTAL_LINE    `NUM_WAY*`NUM_SET*`NUM_LINE;     // total line 32
`define NUM_TOTAL_BYTES   `NUM_WAY*`NUM_SET*`NUM_LINE*`NUM_BLOCK;  // total bytes 256
`define NUM_TAG       63-$clog2(`NUM_WAY)-$clog2(`NUM_SET)-$clog2(`NUM_LINE);      


// typedef struct packed{
// 	logic [23:0] tag;
// 	logic [4:0] block_num;
// 	logic [2:0]  block_offset;
// } DMAP_ADDR; // derect map

typedef struct packed{
	logic [$clog2(`NUM_TAG)-1:0]   tag;
	logic [$clog2(`NUM_WAY)-1:0]   way_index;
	logic [$clog2(`NUM_SET)-1:0]   set_index;
	logic [$clog2(`NUM_LINE)-1:0]  line_index;
} SASS_ADDR; // set associate

// typedef union packed{
// 	DMAP_ADDR  d;
// 	SASS_ADDR  s;
// }ADDR_t;