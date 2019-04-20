
`timescale 1ns/100ps

module icache (
  // Input
  input  logic                                           clock,
  input  logic                                           reset,

  input  logic           [3:0]                           Imem2proc_response, // response  from memory (0 or transaction#)
  input  logic           [3:0]                           Imem2proc_tag,      // tag       from memory (0 or transaction#)
  input  logic           [63:0]                          Imem2proc_data,     // inst data from memory

  input  logic           [63:0]                          proc2Icache_addr,   // address from f-stage

  // Output
  output logic  [1:0]                                       proc2Imem_command,  // command to memory (BUS_NONE or BUS_LOAD)
  output logic [63:0]                                       proc2Imem_addr,     // address to memory
`ifdef DEBUG
  output I_CACHE_ENTRY_t [`NUM_ICACHE_LINES-1:0]            i_cache,
  output MEM_TAG_TABLE_t [15:0]                             mem_tag_table,
  output logic           [$clog2(`NUM_ICACHE_LINES)-1:0]    head,
  output logic           [$clog2(`NUM_ICACHE_LINES)-1:0]    tail,
  output logic           [15-$clog2(`NUM_ICACHE_LINES)-3:0] prefetch_addr_tag_idx,
`endif
  output logic           [63:0]                             Icache_data_out,    // value is memory[proc2Icache_addr] // to f-stage
  output logic                                              Icache_valid_out    // when this is high // hit/miss     // to f-stage
);

`ifndef DEBUG
  I_CACHE_ENTRY_t [`NUM_ICACHE_LINES-1:0]            i_cache;
  MEM_TAG_TABLE_t [15:0]                             mem_tag_table;
  logic           [$clog2(`NUM_ICACHE_LINES)-1:0]    head;
  logic           [$clog2(`NUM_ICACHE_LINES)-1:0]    tail;
  logic           [15-$clog2(`NUM_ICACHE_LINES)-3:0] prefetch_addr_tag_idx; // {tag, index}
`endif

  logic           [1:0]                              next_proc2Imem_command;
  logic           [63:0]                             next_proc2Imem_addr;
  I_CACHE_ENTRY_t [`NUM_ICACHE_LINES-1:0]            next_i_cache;
  MEM_TAG_TABLE_t [15:0]                             next_mem_tag_table;
  logic           [$clog2(`NUM_ICACHE_LINES)-1:0]    next_head;
  logic           [$clog2(`NUM_ICACHE_LINES)-1:0]    next_tail;
  logic           [15-$clog2(`NUM_ICACHE_LINES)-3:0] next_prefetch_addr_tag_idx;

  wire [$clog2(`NUM_ICACHE_LINES)-1:0]    idx;       // index of the entry that f-stage requests
  wire [15-$clog2(`NUM_ICACHE_LINES)-3:0] tag;       // tag of the address from f-stage
  wire                                    f_stage_tag_match;  // whether address from f-stage matches the tag in i_cache entry
  wire                                    prefetch_tag_match; // whether address to prefetch matches the tag in i_cache entry
  wire                                    write_en;  // write_en for i_cache
  wire [$clog2(`NUM_ICACHE_LINES)-1:0]    tail_plus_one; // tail+1
  wire [63:0]                             prefetch_addr; // prefetching address
  wire [$clog2(`NUM_ICACHE_LINES)-1:0]    prefetch_idx;  // index of prefetching address
  wire [15-$clog2(`NUM_ICACHE_LINES)-3:0] prefetch_tag;  // tag of prefetching address

  // 1. f-stage gets inst from i_cache
  assign idx = proc2Icache_addr[3+$clog2(`NUM_ICACHE_LINES)-1:3];
  assign Icache_data_out = i_cache[idx].data;

  assign tag = proc2Icache_addr[15:3+$clog2(`NUM_ICACHE_LINES)];
  assign f_stage_tag_match = (i_cache[idx].tag == tag);
  assign Icache_valid_out = (i_cache[idx].valid && f_stage_tag_match);

  // 2. i_cache request inst from mem
  assign prefetch_addr = {48'h0, prefetch_addr_tag_idx, 3'h0};
  assign prefetch_idx  = prefetch_addr[3+$clog2(`NUM_ICACHE_LINES)-1:3];
  assign prefetch_tag  = prefetch_addr[15:3+$clog2(`NUM_ICACHE_LINES)];
  assign prefetch_tag_match = (i_cache[prefetch_idx].tag == prefetch_tag);
  
  assign tail_plus_one = tail + {($clog2(`NUM_ICACHE_LINES)-1){1'b0}, 1'b1};
  assign next_proc2Imem_command = ((f_stage_tag_match) && (!prefetch_tag_match) && (tail_plus_one == head)) ? BUS_NONE : BUS_LOAD;
  assign next_proc2Imem_addr    = (f_stage_tag_match) ? prefetch_addr : proc2Icache_addr;

  // Next prefetch_addr_tag_idx
  always_comb begin
    if (!f_stage_tag_match) begin
      next_prefetch_addr_tag_idx = {tag, idx};
    end else begin
      next_prefetch_addr_tag_idx = prefetch_addr_tag_idx + {{(15-$clog2(`NUM_ICACHE_LINES)-3){1'b0}}, 1'b1};
    end
  end

  // Next head and tail
  assign next_head = idx;
  always_comb begin
    if (!f_stage_tag_match) begin
      next_tail = idx;
    end else if ((tail_plus_one != head) && (Imem2proc_response != 4'b0)) begin
      next_tail = tail_plus_one;
    end else begin
      next_tail = tail;
    end
  end

  always_ff @(posedge clock) begin
    if (reset) begin
      proc2Imem_command <= `SD BUS_NONE;
      proc2Imem_addr    <= `SD 64'b0;
    end else begin
      proc2Imem_command <= `SD next_proc2Imem_command;
      proc2Imem_addr    <= `SD next_proc2Imem_addr;
    end
  end

  // 3. i_cache receives inst from mem
  assign write_en = (Imem2proc_tag != 0) && (mem_tag_table[Imem2proc_tag].valid);
  always_comb begin
    next_i_cache = i_cache;
    // Mem responses to the request
    if (Imem2proc_response != 4'b0) begin
      next_i_cache[idx].valid = `FALSE;
      next_i_cache[idx].tag   = tag;
    end
    // Write inst from mem to i_cache
    if (write_en) begin
      next_i_cache[mem_tag_table[Imem2proc_tag].idx].valid = `TRUE;
      next_i_cache[mem_tag_table[Imem2proc_tag].idx].data  = Imem2proc_data;
    end
  end

  always_comb begin
    next_mem_tag_table = mem_tag_table;
    // Mem responses to the request
    if (Imem2proc_response != 4'b0) begin
      next_mem_tag_table[Imem2proc_response].valid = `TRUE;
      next_mem_tag_table[Imem2proc_response].idx   = idx;
      next_mem_tag_table[Imem2proc_response].tag   = tag;
    end
    // Write inst from mem to i_cache
    if (write_en) begin
      next_mem_tag_table[Imem2proc_tag].valid = `FALSE;
    end
  end

  always_ff @(posedge clock) begin
    if (reset) begin
      i_cache <= `SD 0;
      head    <= `SD 0;
      tail    <= `SD 0;
    end else begin
      i_cache <= `SD next_i_cache;
      head    <= `SD next_head;
      tail    <= `SD next_tail;
    end
  end

  always_ff @(posedge clock) begin
    if (reset) begin
      mem_tag_table <= `SD 0;
    end else begin
      mem_tag_table <= `SD next_mem_tag_table;
    end
  end

  always_ff @(posedge clock) begin
    if (reset) begin
      prefetch_addr_tag_idx <= `SD 0;
    end else begin
      prefetch_addr_tag_idx <= `SD next_prefetch_addr_tag_idx;
    end
  end

//   logic                                              valid;
//   logic           [$clog2(`NUM_ICACHE_LINES)-1:0]    next_head, next_tail, diff1, diff2, tail_plus_one;
//   
//   logic           [1:0]                              next_proc2Imem_command;

//   assign tail_plus_one          = tail + 1;
//   assign diff1                  = idx - head;
//   assign diff2                  = tail - head;
//   assign valid                  = diff1 <= diff2;
//   assign tag_match                  = i_cache[idx].tag == tag;
//   assign next_proc2Imem_command = BUS_LOAD;

//   always_comb begin
//     if (tag_match) begin
//       proc2Imem_addr = {48'h0, i_cache[tail].tag, tail, 3'h0};
//     end else begin
//       proc2Imem_addr = proc2Icache_addr;
//     end
//   end

//   always_comb begin
//     if (tag_match) begin
//       next_head = head;
//     end else begin
//       next_head = idx;
//     end
//   end

//   always_comb begin
//     if (tag_match) begin
//       if (Imem2proc_response != 0 && tail_plus_one != head) begin
//         next_tail = tail_plus_one;
//       end else begin
//         next_tail = tail;
//       end
//     end else begin
//       if (Imem2proc_response != 0) begin
//         next_tail = idx + 1;
//       end else begin
//         next_tail = idx;
//       end
//     end
//   end

//   always_comb begin
//     next_i_cache = i_cache;
//     next_i_cache[idx].tag = tag;
//     if (~tag_match) begin
//       next_i_cache[idx].valid = `FALSE;
//     end
//     if (write_en) begin
//       next_i_cache[mem_tag_table[Imem2proc_tag].idx].valid = `TRUE;
//       next_i_cache[mem_tag_table[Imem2proc_tag].idx].data  = Imem2proc_data;
//     end
//   end

//   always_comb begin
//     next_mem_tag_table = mem_tag_table;
//     if (write_en) begin
//         next_mem_tag_table[Imem2proc_tag].valid = `FALSE;
//     end
//     if (tag_match) begin
//       if (Imem2proc_response != 0) begin
//         next_mem_tag_table[Imem2proc_response].valid = `TRUE;
//         next_mem_tag_table[Imem2proc_response].idx   = tail;
//         next_mem_tag_table[Imem2proc_response].tag   = tag;
//       end
//     end else begin
//       if (Imem2proc_response != 0) begin
//         next_mem_tag_table[Imem2proc_response].valid = `TRUE;
//         next_mem_tag_table[Imem2proc_response].idx   = idx;
//         next_mem_tag_table[Imem2proc_response].tag   = tag;
//       end
//     end
//   end

//   always_ff @(posedge clock) begin
//     if (reset) begin
//       i_cache           <= `SD 0;
//       head              <= `SD 0;
//       tail              <= `SD 0;
//       mem_tag_table     <= `SD 0;
//       proc2Imem_command <= `SD BUS_NONE;
//     end else begin
//       i_cache           <= `SD next_i_cache;
//       head              <= `SD next_head;
//       tail              <= `SD next_tail;
//       mem_tag_table     <= `SD next_mem_tag_table;
//       proc2Imem_command <= `SD next_proc2Imem_command;
//     end
//   end
endmodule
