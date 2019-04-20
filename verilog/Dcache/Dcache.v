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
  input logic                                                       rd1_search,
  input logic                                                       wr1_search,
  output logic [63:0]                                               rd1_data_out,
  output logic                                                      rd1_hit_out, wr1_hit_out,

  input logic [63:0]                                                wr1_data,
  input logic                                                       wr1_dirty,
  input logic                                                       wr1_valid,
`ifdef DEBUG
  output D_CACHE_LINE_t [`NUM_WAY-1:0][`NUM_IDX-1:0]               cache_bank,
  output logic [`NUM_IDX-1:0][`NUM_WAY-1:0]                        LRU_bank_sel,
`endif

  output logic                                                      evicted_dirty_out, 
  output logic                                                      evicted_valid_out,
  output SASS_ADDR                                                  evicted_addr_out,
  output logic [63:0]                                               evicted_data_out
);
 
  //LRU logic
  logic [`NUM_IDX-1:0]               regA, regB, regC, next_regA, next_regB, next_regC;
`ifndef DEBUG
  logic [`NUM_IDX-1:0][`NUM_WAY-1:0] LRU_bank_sel;
`endif
  logic [`NUM_IDX-1:0][`NUM_WAY-1:0] prev_LRU_bank_sel;
  // logic [$clog2(`NUM_WAY)-1:0]       LRU_bank_idx;
  

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
  always_comb begin
    next_regA = regA;
    next_regB = regB;
    next_regC = regC;
    LRU_bank_sel = prev_LRU_bank_sel;

    
    next_regA[wr1_addr.set_index] = (wr1_from_mem & wr1_en)? (~regA[wr1_addr.set_index]) : regA[wr1_addr.set_index];
    next_regB[wr1_addr.set_index] = (!regA[wr1_addr.set_index] & wr1_from_mem & wr1_en) ? (~regB[wr1_addr.set_index]) : regB[wr1_addr.set_index];
    next_regC[wr1_addr.set_index] = (regA[wr1_addr.set_index] & wr1_from_mem & wr1_en)  ? (~regC[wr1_addr.set_index]) : regC[wr1_addr.set_index];

    LRU_bank_sel[wr1_addr.set_index][0] = !regA[wr1_addr.set_index] & !regB[wr1_addr.set_index];
    LRU_bank_sel[wr1_addr.set_index][1] = !regA[wr1_addr.set_index] & regB[wr1_addr.set_index];
    LRU_bank_sel[wr1_addr.set_index][2] = regA[wr1_addr.set_index] & !regC[wr1_addr.set_index];
    LRU_bank_sel[wr1_addr.set_index][3] = regA[wr1_addr.set_index] & regC[wr1_addr.set_index];
  end

  always_ff @(posedge clock) begin
    if(reset) begin
      regA <= `SD `regA_reset;
      regB <= `SD `regB_reset;
      regC <= `SD `regC_reset;
      prev_LRU_bank_sel <= `SD '{(`NUM_IDX){4'b1000}};
    end
    else begin
      regA <= `SD next_regA;
      regB <= `SD next_regB;
      regC <= `SD next_regC;
      prev_LRU_bank_sel <= `SD LRU_bank_sel;
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
`ifdef DEBUG
      .cache_bank(cache_bank),
`endif
      // .evicted_idx(wr1_addr.set_index),
      .evicted_addr(evicted_addr),
      .evicted_dirty(evicted_dirty),
      .evicted_valid(evicted_valid),
      .evicted_data(evicted_data)
      );


  assign rd1_hit_out = rd1_hit[0] | rd1_hit[1] | rd1_hit[2] | rd1_hit[3];

  assign rd1_data_out = (rd1_search & rd1_hit[0] & !rd1_hit[1] & !rd1_hit[2] & !rd1_hit[3]) ? rd1_data[0] :
                        (rd1_search & !rd1_hit[0] & rd1_hit[1] & !rd1_hit[2] & !rd1_hit[3]) ? rd1_data[1] :
                        (rd1_search & !rd1_hit[0] & !rd1_hit[1] & rd1_hit[2] & !rd1_hit[3]) ? rd1_data[2] :
                        (rd1_search & !rd1_hit[0] & !rd1_hit[1] & !rd1_hit[2] & rd1_hit[3]) ? rd1_data[3] : 64'hDEADDEADDEADDEAD;

  assign wr1_hit_out = wr1_hit[0] | wr1_hit[1] | wr1_hit[2] | wr1_hit[3];

  // always_comb begin
  //   rd1_data_out = 0;
  //   for(int i = 0 ; i <`NUM_WAY; i++) begin
  //     if(rd1_hit[i] & rd1_search) begin
  //       rd1_data_out = rd1_data[i];
  //     end
  //   end
  // end

  // always_comb begin
  //   wr1_hit_out = 0;
  //   for(int i = 0 ; i <`NUM_WAY; i++) begin
  //     if(wr1_hit[i] & wr1_search) begin
  //       wr1_hit_out = 1;
  //     end
  //   end
  // end
  assign evicted_dirty_out = (wr1_search & LRU_bank_sel[wr1_addr.set_index] == 4'b0001) ? evicted_dirty[0] :
                             (wr1_search & LRU_bank_sel[wr1_addr.set_index] == 4'b0010) ? evicted_dirty[1] :
                             (wr1_search & LRU_bank_sel[wr1_addr.set_index] == 4'b0100) ? evicted_dirty[2] :
                             (wr1_search & LRU_bank_sel[wr1_addr.set_index] == 4'b1000) ? evicted_dirty[3] : 0;

  assign evicted_valid_out = (wr1_search & LRU_bank_sel[wr1_addr.set_index] == 4'b0001) ? evicted_valid[0] :
                             (wr1_search & LRU_bank_sel[wr1_addr.set_index] == 4'b0010) ? evicted_valid[1] :
                             (wr1_search & LRU_bank_sel[wr1_addr.set_index] == 4'b0100) ? evicted_valid[2] :
                             (wr1_search & LRU_bank_sel[wr1_addr.set_index] == 4'b1000) ? evicted_valid[3] : 0;

  assign evicted_addr_out = (wr1_search & LRU_bank_sel[wr1_addr.set_index] == 4'b0001) ? evicted_addr[0] :
                             (wr1_search & LRU_bank_sel[wr1_addr.set_index] == 4'b0010) ? evicted_addr[1] :
                             (wr1_search & LRU_bank_sel[wr1_addr.set_index] == 4'b0100) ? evicted_addr[2] :
                             (wr1_search & LRU_bank_sel[wr1_addr.set_index] == 4'b1000) ? evicted_addr[3] : 0;

  assign evicted_data_out = (wr1_search & LRU_bank_sel[wr1_addr.set_index] == 4'b0001) ? evicted_data[0] :
                             (wr1_search & LRU_bank_sel[wr1_addr.set_index] == 4'b0010) ? evicted_data[1] :
                             (wr1_search & LRU_bank_sel[wr1_addr.set_index] == 4'b0100) ? evicted_data[2] :
                             (wr1_search & LRU_bank_sel[wr1_addr.set_index] == 4'b1000) ? evicted_data[3] : 0;



  // assign evicted_dirty_out = evicted_dirty[LRU_bank_idx];
  // assign evicted_valid_out = evicted_valid[LRU_bank_idx];
  // assign evicted_addr_out = evicted_addr[LRU_bank_idx];
  // assign evicted_data_out = evicted_data[LRU_bank_idx];

  // pe_Dcache rd1_bank_sel (.gnt(rd1_hit),.enc(rd1_hit_idx));
  // pe_Dcache wr1_bank_sel (.gnt(wr1_hit),.enc(wr1_hit_idx));
  // pe_Dcache LRU_bank_sel_mod (.gnt(LRU_bank_sel[wr1_addr.set_index]),.enc(LRU_bank_idx));

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

`ifdef DEBUG
  output D_CACHE_LINE_t [`NUM_IDX-1:0]                              cache_bank,
`endif
  //evicted index to output the address(TAG of the evicted line)
  // input logic [$clog2(`NUM_IDX)-1:0]                                evicted_idx,
  output SASS_ADDR                                                  evicted_addr,
  output logic                                                      evicted_dirty,
  output logic                                                      evicted_valid,
  output logic [63:0]                                               evicted_data
);

`ifndef DEBUG
  D_CACHE_LINE_t [`NUM_IDX-1:0] cache_bank;
`endif  
  D_CACHE_LINE_t [`NUM_IDX-1:0] next_cache_bank;

  //check read hit
  assign rd1_hit = cache_bank[rd1_addr.set_index].valid && (rd1_addr.tag == cache_bank[rd1_addr.set_index].tag);
  assign rd1_data = cache_bank[rd1_addr.set_index].data;

  //check write hit
  assign wr1_hit = cache_bank[wr1_addr.set_index].valid && (wr1_addr.tag == cache_bank[wr1_addr.set_index].tag);

  //evicted
  assign evicted_valid = cache_bank[wr1_addr.set_index].valid;
  assign evicted_dirty = cache_bank[wr1_addr.set_index].dirty;
  assign evicted_addr.tag = cache_bank[wr1_addr.set_index].tag;
  assign evicted_addr.set_index = wr1_addr.set_index;
  assign evicted_addr.ignore = 3'b000;
  assign evicted_data = cache_bank[wr1_addr.set_index].data;

  always_comb begin
    next_cache_bank = cache_bank;

    if(wr1_en) begin
      next_cache_bank[wr1_addr.set_index].valid = wr1_valid;
      next_cache_bank[wr1_addr.set_index].tag = wr1_addr.tag;
      next_cache_bank[wr1_addr.set_index].data = wr1_data;
      next_cache_bank[wr1_addr.set_index].dirty = wr1_dirty;
    end
  end

  //write
  always_ff @(posedge clock) begin
    if(reset)
      for(int i=0; i < `NUM_IDX; i++) begin
        cache_bank[i].valid <= `SD 0;
        cache_bank[i].dirty <= `SD 0;
        cache_bank[i].data <= `SD 64'hbaadbeefdeadbeef;
        cache_bank[i].tag <= `SD {`NUM_TAG_BITS{1'b0}};
      end
    else begin
      cache_bank <= `SD next_cache_bank;
    end
  end
endmodule

// module pe_Dcache(gnt,enc);
//   //synopsys template
//   parameter OUT_WIDTH=$clog2(`NUM_WAY);
//   parameter IN_WIDTH=1<<OUT_WIDTH;

//   input   [IN_WIDTH-1:0] gnt;

//   output [OUT_WIDTH-1:0] enc;
//   wor    [OUT_WIDTH-1:0] enc;
  
//   genvar i,j;
//   generate
//     for(i=0;i<OUT_WIDTH;i=i+1)
//     begin : foo
//       for(j=1;j<IN_WIDTH;j=j+1)
//       begin : bar
//         if (j[i]) begin :if1
//           assign enc[i] = gnt[j];
//         end
//       end
//     end
//   endgenerate
// endmodule