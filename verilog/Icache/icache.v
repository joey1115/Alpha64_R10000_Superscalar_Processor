
`timescale 1ns/100ps

module icache (
  // Input
  input  logic                                           clock,
  input  logic                                           reset,
  input  logic           [3:0]                           Imem2proc_response,
  input  logic           [63:0]                          Imem2proc_data,
  input  logic           [3:0]                           Imem2proc_tag,
  input  logic           [63:0]                          proc2Icache_addr,
  // Output
  output logic  [1:0]                                    proc2Imem_command,
  output logic [63:0]                                    proc2Imem_addr,
`ifdef DEBUG
  output I_CACHE_ENTRY_t [`NUM_ICACHE_LINES-1:0]         i_cache,
  output MEM_TAG_TABLE_t [15:0]                          mem_tag_table,
  output logic           [$clog2(`NUM_ICACHE_LINES)-1:0] head,
  output logic           [$clog2(`NUM_ICACHE_LINES)-1:0] tail,
`endif
  output logic           [63:0]                          Icache_data_out,     // value is memory[proc2Icache_addr]
  output logic                                           Icache_valid_out    // when this is high
);

  logic  [1:0]                                    next_proc2Imem_command;
  logic [63:0]                                    next_proc2Imem_addr;
  I_CACHE_ENTRY_t [`NUM_ICACHE_LINES-1:0]         next_i_cache;
  MEM_TAG_TABLE_t [15:0]                          next_mem_tag_table;
  logic           [$clog2(`NUM_ICACHE_LINES)-1:0] next_head;
  logic           [$clog2(`NUM_ICACHE_LINES)-1:0] next_tail;
`ifndef DEBUG
  I_CACHE_ENTRY_t [`NUM_ICACHE_LINES-1:0]         i_cache;
  MEM_TAG_TABLE_t [15:0]                          mem_tag_table;
  logic           [$clog2(`NUM_ICACHE_LINES)-1:0] head;
  logic           [$clog2(`NUM_ICACHE_LINES)-1:0] tail;
`endif

  logic           [$clog2(`NUM_ICACHE_LINES)-1:0]    idx;       // index of the entry that f-stage requests
  logic           [15-$clog2(`NUM_ICACHE_LINES)-3:0] tag;       // tag of the address from f-stage
  logic                                              tag_match; // whether address from f-stage matches the tag in i_cache entry
  logic                                              write_en;  // write_en for i_cache

  // 1. f-stage gets inst from i_cache
  assign idx              = proc2Icache_addr[3+$clog2(`NUM_ICACHE_LINES)-1:3];
  assign Icache_data_out  = i_cache[idx].data;
  assign tag              = proc2Icache_addr[15:3+$clog2(`NUM_ICACHE_LINES)]; // Watch out for really long program
  assign tag_match        = (i_cache[idx].tag == tag);
  assign Icache_valid_out = (i_cache[idx].valid && tag_match);

  // 2. i_cache request inst from mem
  assign write_en = (Imem2proc_tag != 0) && (mem_tag_table[Imem2proc_tag].valid);
  always_comb begin
    next_i_cache = i_cache;
    next_i_cache[idx].tag = tag;
    if (~tag_match) begin
      next_i_cache[idx].valid = `FALSE;
    end
    if (write_en) begin
      next_i_cache[mem_tag_table[Imem2proc_tag].idx].valid = `TRUE;
      next_i_cache[mem_tag_table[Imem2proc_tag].idx].tag   = mem_tag_table[Imem2proc_tag].tag;
      next_i_cache[mem_tag_table[Imem2proc_tag].idx].data  = Imem2proc_data;
    end
  end

  always_comb begin
    next_mem_tag_table = mem_tag_table;
    if (write_en) begin
        next_mem_tag_table[Imem2proc_tag].valid = `FALSE;
    end
    if (tag_match) begin
      if (Imem2proc_response != 0) begin
        next_mem_tag_table[Imem2proc_response].valid = `TRUE;
        next_mem_tag_table[Imem2proc_response].idx   = tail;
        next_mem_tag_table[Imem2proc_response].tag   = tag;
      end
    end else begin
      if (Imem2proc_response != 0) begin
        next_mem_tag_table[Imem2proc_response].valid = `TRUE;
        next_mem_tag_table[Imem2proc_response].idx   = idx;
        next_mem_tag_table[Imem2proc_response].tag   = tag;
      end
    end
  end




  assign proc2Imem_addr = tag_match ? {48'h0, i_cache[tail].tag, tail, 3'h0} : proc2Icache_addr;
  // next_head
  assign next_head = idx;
  // next_tail
  always_comb begin
    if (tail > head) begin
      if (idx >= head && idx <= tail) begin
        if (tail_plus_one == head) begin
          next_tail = tail;
        end else begin
          next_tail = tail_plus_one;
        end
      end else begin
        next_tail = idx;
      end
    end else if (tail < head) begin
      if (idx >= head || idx <= tail) begin
        if (tail_plus_one == head) begin
          next_tail = tail;
        end else begin
          next_tail = tail_plus_one;
        end
      end else begin
        next_tail = idx;
      end
    end
  end
  // next_proc2Imem_addr
  always_comb begin
    if (tail_plus_one == head) begin
      next_proc2Imem_addr    = BUS_NONE;
    end else begin
      next_proc2Imem_command = BUS_LOAD;
    end
  end

  always_ff @(posedge clock) begin
    if (reset) begin
      i_cache           <= `SD 0;
      mem_tag_table     <= `SD 0;
      proc2Imem_command <= `SD BUS_NONE;
      proc2Imem_addr    <= `SD 0;
    end else begin
      icache            <= `SD next_i_cache;
      mem_tag_table     <= `SD next_mem_tag_table;
      proc2Imem_command <= `SD next_proc2Imem_command;
      proc2Imem_addr    <= `SD next_proc2Imem_addr;
    end
  end

//   logic                                              valid, match, write;
// `ifndef DEBUG
//   I_CACHE_ENTRY_t [`NUM_ICACHE_LINES-1:0]            i_cache;
//   MEM_TAG_TABLE_t [15:0]                             mem_tag_table;
//   logic           [$clog2(`NUM_ICACHE_LINES)-1:0]    head,
//   logic           [$clog2(`NUM_ICACHE_LINES)-1:0]    tail,
// `endif
//   I_CACHE_ENTRY_t [`NUM_ICACHE_LINES-1:0]            next_i_cache;
//   logic           [$clog2(`NUM_ICACHE_LINES)-1:0]    next_head, next_tail, diff1, diff2, idx, tail_plus_one;
//   logic           [15-$clog2(`NUM_ICACHE_LINES)-3:0] tag;
//   MEM_TAG_TABLE_t [15:0]                             next_mem_tag_table;
//   logic           [1:0]                              next_proc2Imem_command;

//   assign idx                    = proc2Icache_addr[3+$clog2(`NUM_ICACHE_LINES)-1:3];
//   assign tag                    = proc2Icache_addr[15:3+$clog2(`NUM_ICACHE_LINES)];
//   assign tail_plus_one          = tail + 1;
//   assign diff1                  = idx - head;
//   assign diff2                  = tail - head;
//   assign valid                  = diff1 <= diff2;
//   assign match                  = i_cache[idx].tag == tag;
//   assign Icache_data_out        = i_cache[idx].data;
//   assign Icache_valid_out       = i_cache[idx].valid && match;
//   assign next_proc2Imem_command = BUS_LOAD;
//   assign write                  = Imem2proc_tag != 0 && mem_tag_table[Imem2proc_tag].tag == i_cache[mem_tag_table[Imem2proc_tag].idx].tag && mem_tag_table[Imem2proc_tag].valid;

//   always_comb begin
//     if (match) begin
//       proc2Imem_addr = {48'h0, i_cache[tail].tag, tail, 3'h0};
//     end else begin
//       proc2Imem_addr = proc2Icache_addr;
//     end
//   end

//   always_comb begin
//     if (Icache_valid_out) begin
//       next_head = idx + 1;
//     end else begin
//       next_head = idx;
//     end
//   end

//   always_comb begin
//     if (match) begin
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
//     if (~match) begin
//       next_i_cache[idx].valid = `FALSE;
//     end
//     if (write) begin
//       next_i_cache[mem_tag_table[Imem2proc_tag].idx].valid = `TRUE;
//       // next_i_cache[mem_tag_table[Imem2proc_tag].idx].tag   = mem_tag_table[Imem2proc_tag].tag;
//       next_i_cache[mem_tag_table[Imem2proc_tag].idx].data  = Imem2proc_data;
//     end
//   end

//   always_comb begin
//     next_mem_tag_table = mem_tag_table;
//     if (write) begin
//         next_mem_tag_table[Imem2proc_tag].valid = `FALSE;
//     end
//     if (match) begin
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
