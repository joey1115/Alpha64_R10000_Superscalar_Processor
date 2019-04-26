`timescale 1ns/100ps

module Dcache_controller(
    input logic                                                                   clock, reset,
    //proc to cache            
    input SQ_D_CACHE_OUT_t                                                        sq_d_cache_out,
    input LQ_D_CACHE_OUT_t                                                        lq_d_cache_out,

    //cache to proc                                 
    output D_CACHE_LQ_OUT_t                                                       d_cache_lq_out,
    output D_CACHE_SQ_OUT_t                                                       d_cache_sq_out, // tells if a store can be moved on.

`ifdef DEBUG
    output logic [5:0]                                     count,
    output D_CACHE_LINE_t [`NUM_WAY-1:0][`NUM_IDX-1:0]     Dcache_bank,
    output logic [`NUM_IDX-1:0][`NUM_WAY-1:0]              LRU_bank_sel,
`endif

    input logic [3:0]                                                             mem2proc_response,
    input logic [63:0]                                                            mem2proc_data,     // data resulting from a load
    input logic [3:0]                                                             mem2proc_tag,       // 0 = no value, other=tag of transaction
    //cache to mshr
    output logic [63:0]                                                           proc2mem_addr,
    output logic [63:0]                                                           proc2mem_data,
    output logic [1:0]                                                            proc2mem_command,

    input  logic                                                                  write_back,
    // output logic                                                                  cache_valid,
    output logic                                                                  halt_pipeline,
    output logic                                                                  write_back_stage
);
  //logics

  `ifndef DEBUG
      logic [5:0]                   count;
  `endif

  logic [1:0] state, next_state;
  logic [2:0] mainState, next_mainState;
  logic [5:0] next_count;
  SASS_ADDR write_back_addr;
  logic wr1_strictly_from_mem;

  logic [63:0]       rd1_data;
  logic              rd1_hit, wr1_hit;
  logic              evicted_dirty;
  logic              evicted_valid;
  SASS_ADDR          evicted_addr;
  logic [63:0]       evicted_data;                     
  logic              wr1_en, wr1_dirty, wr1_from_mem, wr1_valid;
  SASS_ADDR          rd1_addr, wr1_addr;
  logic [63:0]       wr1_data;

  logic              cache_empty;

  logic request_accepted;

  logic hit_cache;

  logic evict_data;

  logic [63:0] next_rd1_addr_reg, rd1_addr_reg;
  logic [63:0] next_wr1_addr_reg, wr1_addr_reg;
  logic [63:0] next_wr1_data_reg, wr1_data_reg;
  logic [3:0]  next_in_progress_tag, in_progress_tag;
  logic [63:0] next_data_from_mem, data_from_mem;




  Dcache dcache_0 (
      .clock(clock),
      .reset(reset),
      //enable signals 
      .wr1_en(wr1_en),
      .wr1_from_mem(wr1_strictly_from_mem),
      //addr from proc
      .rd1_addr(rd1_addr),
      .wr1_addr(wr1_addr),
      .rd1_data_out(rd1_data),
      .rd1_hit_out(rd1_hit),
      .wr1_hit_out(wr1_hit),
      .wr1_data(wr1_data),
      .wr1_dirty(wr1_dirty),
      .wr1_valid(wr1_valid),
      .write_back_stage(write_back_stage),
      .cache_empty(cache_empty),
    `ifdef DEBUG
      .cache_bank(Dcache_bank),
      .LRU_bank_sel(LRU_bank_sel),
    `endif
      .evicted_dirty_out(evicted_dirty), 
      .evicted_valid_out(evicted_valid),
      .evicted_addr_out(evicted_addr),
      .evicted_data_out(evicted_data)
    );

  
  //output
  

 
  assign request_accepted = (mem2proc_response != 0);
  assign hit_cache = wr1_hit || rd1_hit;
  assign evict_data = evicted_valid && evicted_dirty;

  always_comb begin
    next_rd1_addr_reg = rd1_addr_reg;
    next_wr1_addr_reg = wr1_addr_reg;
    next_wr1_data_reg = wr1_data_reg;
    proc2mem_addr = 64'h0;
    proc2mem_data = 64'h0;
    proc2mem_command = BUS_NONE;
    next_in_progress_tag = in_progress_tag;
    next_data_from_mem = data_from_mem;
    wr1_en = 1'b0;
    wr1_valid = 1'b0;
    wr1_data = 64'hDEADBEEFDEADBEEF;
    wr1_dirty = 1'b0;
    rd1_addr = 64'hDEADBEEFDEADBEEF;
    wr1_addr = 64'hDEADBEEFDEADBEEF;
    wr1_strictly_from_mem = 1'b0;
    d_cache_sq_out.valid = 1'b0;
    d_cache_lq_out.valid = 1'b0;
    d_cache_lq_out.value = 64'hDEADBEEFDEADBEEF;

    case (mainState)
      3'b000: begin
        next_rd1_addr_reg = {lq_d_cache_out.addr,3'b000};
        next_wr1_addr_reg = {sq_d_cache_out.addr,3'b000};
        next_wr1_data_reg = sq_d_cache_out.value;

        rd1_addr = {lq_d_cache_out.addr,3'b000};
        wr1_addr = (write_back_stage) ? write_back_addr : {sq_d_cache_out.addr,3'b000};

        d_cache_lq_out.valid = rd1_hit;
        d_cache_lq_out.value = rd1_data; 
      end
      3'b001: begin
        proc2mem_addr = evicted_addr;
        proc2mem_data = evicted_data;
        proc2mem_command = BUS_STORE;
      end
      3'b010: begin
        proc2mem_addr = (sq_d_cache_out.wr_en) ? wr1_addr_reg : rd1_addr_reg;
        proc2mem_command = BUS_LOAD;
        next_in_progress_tag = mem2proc_response;
      end
      3'b011: begin
        next_data_from_mem = mem2proc_data;
      end
      3'b100: begin
        wr1_en = 1'b1;
        wr1_valid = !write_back_stage;
        wr1_data = data_from_mem;
        wr1_dirty = 1'b0;
        wr1_addr = (write_back_stage) ? write_back_addr:
                   (sq_d_cache_out.wr_en) ? wr1_addr_reg:
                   (lq_d_cache_out.rd_en) ? rd1_addr_reg: 0;
        wr1_strictly_from_mem = 1'b1;
      end
      3'b101: begin
        wr1_en = 1'b1;
        wr1_valid = 1'b1;
        wr1_data = wr1_data_reg;
        wr1_dirty = 1'b1;
        wr1_addr = (write_back_stage) ? write_back_addr : wr1_addr_reg;
        wr1_strictly_from_mem = 1'b0;
        d_cache_sq_out.valid = 1'b1;
      end
    endcase
  end


  always_comb begin
    case (mainState)
      3'b000: next_mainState = (wr1_hit && sq_d_cache_out.wr_en && !write_back_stage) ? 3'b101 : 
                               (write_back_stage) ? 3'b001 : 
                               (!hit_cache && evict_data && (sq_d_cache_out.wr_en || lq_d_cache_out.rd_en)) ? 3'b001 : 
                               (!hit_cache && !evict_data && (sq_d_cache_out.wr_en || lq_d_cache_out.rd_en)) ? 3'b010 : mainState;
      3'b001: next_mainState = (request_accepted) ? 3'b010 : mainState;
      3'b010: next_mainState = (request_accepted) ? 3'b011 : mainState;
      3'b011: next_mainState = (mem2proc_tag == in_progress_tag) ? 3'b100 : mainState;
      3'b100: next_mainState = 3'b000;
      3'b101: next_mainState = 3'b000;
      default: next_mainState = 3'b000;
    endcase
  end

  assign halt_pipeline = (state == 2);
  assign write_back_stage = state == 1;
  assign write_back_addr = count & {{61{1'b1}},3'b000};

  // synopsys sync_set_reset "reset"
  always_ff @(posedge clock) begin
    if(reset) begin
      mainState       <= `SD 2'b00; 
      state           <= `SD `state_reset;
      count           <= `SD `count_reset;
      rd1_addr_reg    <= `SD 64'hDEADBEEFDEADBEEF;
      wr1_addr_reg    <= `SD 64'hDEADBEEFDEADBEEF;
      wr1_data_reg    <= `SD 64'hDEADBEEFDEADBEEF;
      in_progress_tag <= `SD 4'b0000;
      data_from_mem   <= `SD 64'hDEADBEEFDEADBEEF;
    end
    else begin
      mainState       <= `SD next_mainState;
      state           <= `SD next_state;
      count           <= `SD next_count;
      rd1_addr_reg    <= `SD next_rd1_addr_reg;
      wr1_addr_reg    <= `SD next_wr1_addr_reg;
      wr1_data_reg    <= `SD next_wr1_data_reg;
      in_progress_tag <= `SD next_in_progress_tag;
      data_from_mem   <= `SD next_data_from_mem;
    end
  end
  
  always_comb begin
    if (write_back_stage && mainState == 3'b000)
      next_count = count + 2;
    else
      next_count = count;
  end

  always_comb begin
    if (state == 0 && write_back) 
      next_state = 1;
    else if(write_back_stage && cache_empty)
      next_state = 2;
    else
      next_state = state;
  end
  
endmodule
