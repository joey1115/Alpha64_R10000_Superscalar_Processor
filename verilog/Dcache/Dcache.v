// cachemem32x64

`timescale 1ns/100ps

module Dcache(
  input logic                             clock, reset,

  //enable signals
  // input logic                                                    rd1_en, rd2_en, 
  input logic                                                       wr1_en,
  input logic                                                       wr1_from_mem,
  //addr from proc
  input SASS_ADDR                                                   rd1_addr, wr1_addr,
  output logic [63:0]                                               rd1_data_out,
  output logic                                                      rd1_hit_out, wr1_hit_out,

  input logic [63:0]                                                wr1_data,
  input logic                                                       wr1_dirty,
  input logic                                                       wr1_valid,
  

  output logic                                                      evicted_dirty_out, 
  output logic                                                      evicted_valid_out,
  output SASS_ADDR                                                  evicted_addr_out,
  output logic [63:0]                                               evicted_data_out
);
 
  //LRU logic
  logic [`NUM_IDX-1:0]               regA, regB, regC, next_regA, next_regB, next_regC;
  logic [`NUM_IDX-1:0][`NUM_WAY-1:0] LRU_bank_sel;
  logic [$clog2(`NUM_WAY)-1:0]       LRU_bank_idx;
  

  //bank logic
  logic [`NUM_WAY-1:0]            wr1_en_sel;
  logic [`NUM_WAY-1:0][63:0]      rd1_data;
  logic [`NUM_WAY-1:0]            rd1_hit;
  logic [`NUM_WAY-1:0]            wr1_hit;


  //evict logic
  SASS_ADDR [`NUM_WAY-1:0]  evicted_addr;
  logic [`NUM_WAY-1:0]            evicted_dirty;
  logic [`NUM_WAY-1:0]            evicted_valid;
  logic [`NUM_WAY-1:0][63:0]      evicted_data;

  //LRU decision
  assign next_regA[wr1_addr.set_index] = (wr1_from_mem & wr1_en)                             ? ~regA[wr1_addr.set_index] : regA[wr1_addr.set_index];
  assign next_regB[wr1_addr.set_index] = (!regA[wr1_addr.set_index] & wr1_from_mem & wr1_en) ? ~regB[wr1_addr.set_index] : regB[wr1_addr.set_index];
  assign next_regC[wr1_addr.set_index] = (regA[wr1_addr.set_index] & wr1_from_mem & wr1_en)  ? ~regC[wr1_addr.set_index] : regC[wr1_addr.set_index];

 
  assign LRU_bank_sel[wr1_addr.set_index][0] = !regA[wr1_addr.set_index] & !regB[wr1_addr.set_index];
  assign LRU_bank_sel[wr1_addr.set_index][1] = !regA[wr1_addr.set_index] & regB[wr1_addr.set_index];
  assign LRU_bank_sel[wr1_addr.set_index][2] = regA[wr1_addr.set_index] & !regC[wr1_addr.set_index];
  assign LRU_bank_sel[wr1_addr.set_index][3] = regA[wr1_addr.set_index] & regC[wr1_addr.set_index];
  
  always_ff @(posedge clock) begin
    if(reset) begin
      regA <= 'SD 0;
      regB <= 'SD 0;
      regC <= 'SD 0;
    end
    else begin
      regA <= `SD next_regA;
      regB <= `SD next_regB;
      regC <= `SD next_regC;
    end
  end
  
  assign wr1_en_sel = (wr1_en & wr1_hit_out)? wr1_hit : //if data to store in cache, write to where it is hit
                      (wr1_en & wr1_from_mem & !wr1_hit_out)? LRU_bank_sel[wr1_addr.set_index] : 0; //if data from mem and line not in cache, write to the LRU bank
  ////////////////////////////////////////////////////////~~~~~~~~~~~~~~ need to think through the wr operations of the cache  wr1_hit | wr1_en in bank
  cache_bank bank [`NUM_WAY-1:0] (
      .clock(clock),
      .reset(reset),
      .wr1_en(wr1_en_sel),
      .rd1_addr(rd1_addr),
      .wr1_addr(wr1_addr),
      .rd1_data(rd1_data),
      .rd1_hit(rd1_hit),
      .wr1_hit(wr1_hit), 
      .wr1_data(wr1_data),  
      .wr1_dirty(wr1_dirty),
      .wr1_valid(wr1_valid),
      .evicted_idx(wr1_addr.set_index),
      .evicted_addr(evicted_addr),
      .evicted_dirty(evicted_dirty),
      .evicted_valid(evicted_valid),
      .evicted_data(evicted_data)
      );

  always_comb begin
    rd1_hit_out = 0;
    for(int i = 0 ; i <`NUM_WAY; i++) begin
      if(rd1_hit[i]) begin
        rd1_data_out = rd1_data[(64*i)+63:64*i];
        rd1_hit_out = 1;
      end
    end
  end

  always_comb begin
    wr1_hit_out = 0;
    for(int i = 0 ; i <`NUM_WAY; i++) begin
      if(wr1_hit[i]) begin
        wr1_hit_out = 1;
      end
    end
  end

  assign evicted_dirty_out = evicted_dirty[LRU_bank_idx];
  assign evicted_valid_out = evicted_valid[LRU_bank_idx];
  assign evicted_addr_out = evicted_addr[LRU_bank_idx];
  assign evicted_data_out = evicted_data[LRU_bank_idx];

  pe rd1_bank_sel (.gnt(rd1_hit),.enc(rd1_hit_idx));
  pe wr1_bank_sel (.gnt(wr1_hit),.enc(wr1_hit_idx));
  pe LRU_bank_sel_mod (.gnt(LRU_bank_sel[wr1_addr.set_index]),.enc(LRU_bank_idx));

endmodule


module cache_bank(
  input logic                                                       clock, reset,

  //enable signals                          
  input logic                                                       wr1_en,

  //addr from proc                          
  input SASS_ADDR                                                   rd1_addr, wr1_addr,
  output logic [63:0]                                               rd1_data,
  output logic                                                      rd1_hit, wr1_hit, 
  input logic [63:0]                                                wr1_data,
  input logic                                                       wr1_dirty,
  input logic                                                       wr1_valid,

  //evicted index to output the address(TAG of the evicted line)
  input logic [$clog2(`NUM_IDX)-1:0]                                evicted_idx,
  output SASS_ADDR                                                  evicted_addr,
  output logic                                                      evicted_dirty,
  output logic                                                      evicted_valid,
  output logic [63:0]                                               evicted_data
);
    
  D_CACHE_LINE_t [`NUM_IDX-1:0] cache_bank, next_cache_bank;

  //check read hit
  assign rd1_hit = cache_bank[rd1_addr.set_index].valid && (rd1_addr.tag == cache_bank[rd1_addr.set_index].tag);
  assign rd1_data = cache_bank[rd1_addr.set_index].data;

  //check write hit
  assign wr1_hit = cache_bank[wr1_addr.set_index].valid && (wr1_addr.tag == cache_bank[wr1_addr.set_index].tag);

  //evicted
  assign evicted_valid = cache_bank[evicted_idx].valid;
  assign evicted_dirty = cache_bank[evicted_idx].dirty;
  assign evicted_addr.tag = cache_bank[evicted_idx].tag;
  assign evicted_addr.set_index = evicted_idx;
  assign evicted_data = cache_bank[evicted_idx].data;

  always_comb begin
    next_cache_bank = cache_bank;

    if(wr1_en) begin
      next_cache_bank[wr1_addr.set_index].valid = wr1_valid;
      next_cache_bank[wr1_addr.set_index].tag = wr1_addr.tag;
      next_cache_bank[wr1_addr.set_index].data = wr1_data;
      next_cache_bank[wr1_addr.set_index_idx].dirty = wr1_dirty;
    end
  end

  //write
  always_ff @(posedge clock) begin
    if(reset)
      for(int i=0; i < `NUM_IDX; i++) begin
        cache_bank[i].valid <= `SD 0;
        cache_bank[i].dirty <= `SD 0;
      end
    else begin
      cache_bank <= next_cache_bank;
    end
  end
endmodule

module pe(gnt,enc);
  //synopsys template
  parameter OUT_WIDTH=$clog2(`NUM_WAY);
  parameter IN_WIDTH=1<<OUT_WIDTH;

  input   [IN_WIDTH-1:0] gnt;

  output [OUT_WIDTH-1:0] enc;
  wor    [OUT_WIDTH-1:0] enc;
  
  genvar i,j;
  generate
    for(i=0;i<OUT_WIDTH;i=i+1)
    begin : foo
      for(j=1;j<IN_WIDTH;j=j+1)
      begin : bar
        if (j[i])
          assign enc[i] = gnt[j];
      end
    end
  endgenerate
endmodule