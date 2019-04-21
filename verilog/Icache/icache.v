
`timescale 1ns/100ps

module icache (
  // inputs
  input  logic                                           clock,
  input  logic                                           reset,
  input  logic           [63:0]                          proc2Icache_addr,   // address from f-stage
  input  logic           [3:0]                           Imem2proc_response, // response  from memory (0 or transaction#)
  input  logic           [3:0]                           Imem2proc_tag,      // tag       from memory (0 or transaction#)
  input  logic           [63:0]                          Imem2proc_data,     // inst data from memory
  // outputs
  output logic  [1:0]                                    proc2Imem_command,  // command to memory (BUS_NONE or BUS_LOAD)
  output logic [63:0]                                    proc2Imem_addr,     // address to memory
`ifdef DEBUG
  output I_CACHE_ENTRY_t [`NUM_ICACHE_LINES-1:0]         i_cache,
  output MEM_TAG_TABLE_t [15:0]                          mem_tag_table,
  // output logic           [$clog2(`NUM_ICACHE_LINES)-1:0]    head,
  // output logic           [$clog2(`NUM_ICACHE_LINES)-1:0]    tail,
`endif
  output logic           [63:0]                          Icache_data_out,    // value is memory[proc2Icache_addr] // to f-stage
  output logic                                           Icache_valid_out    // when this is high // hit/miss     // to f-stage
);


`ifndef DEBUG
  I_CACHE_ENTRY_t [`NUM_ICACHE_LINES-1:0]            i_cache;
  MEM_TAG_TABLE_t [15:0]                             mem_tag_table;
`endif
  I_CACHE_ENTRY_t [`NUM_ICACHE_LINES-1:0]            next_i_cache;
  MEM_TAG_TABLE_t [15:0]                             next_mem_tag_table;

  logic [$clog2(`NUM_ICACHE_LINES)-1:0]    idx; // index of the address from f-stage
  logic [15-$clog2(`NUM_ICACHE_LINES)-3:0] tag; // tag   of the address from f-stage
  logic [12:0]                             last_proc2Imem_addr; // proc2Imem_addr of last cycle
  logic                                    last_load_request_denied, load_request_denied;


  wire        f_stage_tag_match;    // whether address from f-stage has a tag-match in i_cache entry
  wire        prefetch_tag_match;   // whether prefetch address has a tag-match in i_cache entry
  // wire [12:0] prefetch_lower_bound; // lower bound of prefetch address range = f-stage addr
  wire [12:0] prefetch_upper_bound; // upper bound of prefetch address range

  wire [12:0] prefetch_addr; // last_proc2Imem_addr+1 (here stores only its tag and idx)
  wire [$clog2(`NUM_ICACHE_LINES)-1:0]    prefetch_idx; // index of prefetch address
  wire [15-$clog2(`NUM_ICACHE_LINES)-3:0] prefetch_tag; // tag   of prefetch address
  wire [$clog2(`NUM_ICACHE_LINES)-1:0]    proc2Imem_addr_idx; // index of address to fetch
  wire [15-$clog2(`NUM_ICACHE_LINES)-3:0] proc2Imem_addr_tag; // tag   of address to fetch

  wire can_prefetch;
  wire write_cache; // cache write enable


  // OUTPUT: Icache_data_out
  assign idx = proc2Icache_addr[3+$clog2(`NUM_ICACHE_LINES)-1:3];
  assign Icache_data_out = i_cache[idx].data;

  // OUTPUT: Icache_valid_out
  /* Note: Cache output valid only when entry valid AND tag match */
  assign tag = proc2Icache_addr[15:3+$clog2(`NUM_ICACHE_LINES)];
  assign f_stage_tag_match = (i_cache[idx].tag == tag);
  assign Icache_valid_out = (i_cache[idx].valid && f_stage_tag_match);

  // OUTPUT: proc2Imem_command
  assign load_request_denied = (proc2Imem_command==BUS_LOAD && Imem2proc_response==4'b0);
  assign prefetch_upper_bound = proc2Icache_addr[15:3] + 13'd8; // next-8-line prefetch
  assign prefetch_addr = last_proc2Imem_addr + 13'd1;
  assign prefetch_idx = prefetch_addr[$clog2(`NUM_ICACHE_LINES)-1:0];
  assign prefetch_tag = prefetch_addr[12:$clog2(`NUM_ICACHE_LINES)];
  assign prefetch_tag_match = (i_cache[prefetch_idx].tag == prefetch_tag);
  assign prefetch_hit = (i_cache[prefetch_idx].valid && prefetch_tag_match);
  assign can_prefetch = (prefetch_addr!=prefetch_upper_bound && !prefetch_hit && i_cache[prefetch_idx].requested);
  /* Note: When do we load from mem:
    1. f-stage addr miss and not requested (!hit && !i_cache[idx].requested) OR
    2. last load request denied (load request denied == BUS_LOAD && mem response ==0) OR
    3. can prefetch
      (1) prefetch addr != upperbound AND
      (2) prefetch addr miss && not requested 
  */
  always_comb begin
    if ( (!Icache_valid_out && !i_cache[idx].requested) || last_load_request_denied || can_prefetch ) begin
      proc2Imem_command = BUS_LOAD;
    end else begin
      proc2Imem_command = BUS_NONE;
    end
  end

  // Output: proc2Imem_addr
  /* Note: Which address do we load?
    if (1. f-stage addr miss and not requested)
      f-stage addr
    else if (2. last load request denied)
      last fetch addr
    else if (don't load: prefetch addr == upperbound)
      last fetch addr
    else ( don't load: prefetch addr miss && not requested OR 3. can prefetch)
      prefetch addr
   */
  always_comb begin
    if (!Icache_valid_out && !i_cache[idx].requested) begin
      proc2Imem_addr = proc2Icache_addr;
    end else if (last_load_request_denied || prefetch_addr==prefetch_upper_bound) begin
      proc2Imem_addr = {48'h0, last_proc2Imem_addr, 3'h0};
    end else begin
      proc2Imem_addr = {48'h0, prefetch_addr, 3'h0};
    end
  end

  // Register: next_mem_tag_table
  assign proc2Imem_addr_idx = proc2Imem_addr[3+$clog2(`NUM_ICACHE_LINES)-1:3];
  assign proc2Imem_addr_tag = proc2Imem_addr[15:3+$clog2(`NUM_ICACHE_LINES)];
  assign write_cache = mem_tag_table[Imem2proc_tag].valid;
  always_comb begin
    next_mem_tag_table = mem_tag_table;
    // Write inst to i_cache
    /* Note:
      Clear the entry when data arrive.
      Write inst to i_cache when entry mem_tag_table[Imem2proc_tag] is valid.
      mem_tag_table[0] is never valid, so doesn't need to check (Imem2proc_response != 4'b0).
    */
    if (write_cache) begin
      next_mem_tag_table[Imem2proc_tag].valid = `FALSE;
    end
    // Mem responses to a load request
    /* Note: When mem responses to a load request, update valid, idx, and tag in the entry specified by the mem response. */
    if (Imem2proc_response != 4'b0) begin
      next_mem_tag_table[Imem2proc_response].valid = `TRUE;
      next_mem_tag_table[Imem2proc_response].idx   = proc2Imem_addr_idx;
    end
  end

  // Register: next_i_cache
  always_comb begin
    next_i_cache = i_cache;
    // Write inst to i_cache
    /* Note:
      Write inst to i_cache when entry mem_tag_table[Imem2proc_tag] is valid.
      mem_tag_table[0] is never valid, so doesn't need to check (Imem2proc_response != 4'b0).
     */
    if (write_cache) begin
      next_i_cache[mem_tag_table[Imem2proc_tag].idx].valid = `TRUE;
      next_i_cache[mem_tag_table[Imem2proc_tag].idx].requested = `FALSE;
      next_i_cache[mem_tag_table[Imem2proc_tag].idx].data  = Imem2proc_data;
    end
    // Mem responses to a load request
    /* Note: When mem responses to a load request, evict previous entry and write in the tag. */
    if (Imem2proc_response != 4'b0) begin
      next_i_cache[idx].valid = `FALSE;
      next_i_cache[idx].requested = `TRUE;
      next_i_cache[idx].tag   = proc2Imem_addr_tag;
    end
  end


  // i_cache update
  always_ff @(posedge clock) begin
    if (reset) begin
      i_cache <= `SD 0;
    end else begin
      i_cache <= `SD next_i_cache;
    end
  end

  // mem_tag_table update
  always_ff @(posedge clock) begin
    if (reset) begin
      mem_tag_table <= `SD 0;
    end else begin
      mem_tag_table <= `SD next_mem_tag_table;
    end
  end

  // other register update
  always_ff @(posedge clock) begin
    if (reset) begin
      last_proc2Imem_addr      <= `SD 0;
      last_load_request_denied <= `SD 0;
    end else begin
      last_proc2Imem_addr      <= `SD proc2Imem_addr[15:3];
      last_load_request_denied <= `SD load_request_denied;
    end
  end

endmodule
