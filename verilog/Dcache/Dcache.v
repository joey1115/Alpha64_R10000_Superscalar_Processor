// cachemem32x64

`timescale 1ns/100ps

module Dcache(
        input logic                             clock, reset,
        input logic                             wr1_en, wr2_en,
        input logic [$clog2(`NUM_IDX)-1:0]      wr1_idx, wr2_idx, rd1_idx, rd2_idx,
        input logic [$clog2(`NUM_BLOCK)-1:0]      wr1_BO, wr2_BO, rd1_BO, rd2_BO,
        input logic [`NUM_D_TAG_BITS-1:0]       wr1_tag, wr2_tag, rd1_tag, rd1_tag,
        input logic [63:0]                      wr1_data, wr2_data,
        
        output logic [63:0]                     rd1_data_out, rd2_data_out,
        output logic                            rd1_valid, rd2_valid
      );
  
  logic [`NUM_WAY-1:0] wr1_hit, wr2_hit, rd1_hit, rd2_hit;
  logic [(64*(`NUM_WAY))-1:0] rd1_data, rd2_data;
  logic [$clog2(`NUM_WAY)-1:0] rd1_hit_idx, rd2_hit_idx;
  ////////////////////////////////////////////////////////~~~~~~~~~~~~~~ need to think through the wr operations of the cache  wr1_hit | wr1_en in bank
  cache_bank bank [`NUM_WAY-1:0] (
      .clock(clock),
      .reset(reset),
      .wr1_idx(wr1_idx),
      .wr2_idx(wr2_idx),
      .rd1_idx(rd1_idx),
      .rd2_idx(rd2_idx),
      .wr1_BO(wr1_BO),
      .wr2_BO(wr2_BO),
      .rd1_BO(rd1_BO),
      .rd2_BO(rd2_BO),
      .wr1_tag(wr1_tag), 
      .wr2_tag(wr2_tag), 
      .rd1_tag(rd1_tag), 
      .rd1_tag(rd1_tag),
      .wr1_data(wr1_data), 
      .wr2_data(wr2_data),
      .wr1_hit(wr1_hit),
      .wr2_hit(wr2_hit),
      .rd1_hit(rd1_hit),
      .rd2_hit(rd2_hit),
      .rd1_data(rd1_data),
      .rd2_data(rd2_data));

      always_comb begin
        rd1_valid = 0;
        rd2_valid = 0;
        for(int i = 0 ; i <`NUM_WAY; i++) begin
          if(rd1_hit[i]) begin
            rd1_data_out = rd1_data[(64*i)+63:64*i];
            rd1_valid = 1;
          end
        end

        for(int i = 0 ; i <`NUM_WAY; i++) begin
          if(rd2_hit[i]) begin
            rd2_data_out = rd2_data[(64*i)+63:64*i];
            rd2_valid = 1;
          end
        end
      end
      

  // pe rd1_bank_sel (.gnt(rd1_hit),.enc(rd1_hit_idx));
  // pe rd2_bank_sel (.gnt(rd2_hit),.enc(rd2_hit_idx));






endmodule

module cache_bank(
        input logic                             clock, reset,
        // input logic                             wr1_en, wr2_en,
        input logic [$clog2(`NUM_IDX)-1:0]      wr1_idx, wr2_idx, rd1_idx, rd2_idx,
        input logic [$clog2(`NUM_BLOCK)-1:0]      wr1_BO, wr2_BO, rd1_BO, rd2_BO,
        input logic [`NUM_D_TAG_BITS-1:0]       wr1_tag, wr2_tag, rd1_tag, rd1_tag,
        input logic [63:0]                      wr1_data, wr2_data,

        output logic                            wr1_hit, wr2_hit, rd1_hit, rd2_hit,
        // output logic [`NUM_TAG_BITS-1:0]        wr1_tag,wr2_tag,rd1_tag,rd2_tag,
        output logic [63:0]                     rd1_data, rd2_data
    );
    
  D_CACHE_LINE_t [`NUM_IDX-1:0] cache_bank;  

  //read
  assign rd1_hit = cache_bank[rd1_idx].valid[rd1_BO] && (rd1_tag == cache_bank[rd1_idx].tag);
  assign rd1_data = cache_bank[rd1_idx].data[rd1_BO];

  assign rd2_hit = cache_bank[rd2_idx].valid[rd2_BO] && (rd2_tag == cache_bank[rd2_idx].tag);
  assign rd2_data = cache_bank[rd2_idx].data[rd2_BO];

  //write
  assign wr1_hit = cache_bank[wr1_idx].valid[wr1_BO] && (wr1_tag == cache_bank[wr1_idx].tag);
  assign wr2_hit = cache_bank[wr2_idx].valid[wr2_BO] && (wr2_tag == cache_bank[wr2_idx].tag);

  //write
  always_ff @(posedge clock) begin
    if(reset)
      for(int i=0; i < `NUM_IDX; i++) begin
        cache_bank[i].valid <= `SD 0;
      end
    else begin
      if(wr1_hit | wr1_en) begin
        cache_bank[wr1_idx].valid[wr1_BO] <= `SD 1;
        cache_bank[wr1_idx].tag <= `SD wr1_tag;
        cache_bank[wr1_idx].data[wr1_BO] <= `SD wr1_data;
      end
      if(wr2_hit | wr2_en) begin
        cache_bank[wr2_idx].valid[wr2_BO] <= `SD 1;
        cache_bank[wr2_idx].tag <= `SD wr2_tag;
        cache_bank[wr2_idx].data[wr2_BO] <= `SD wr2_data;
      end
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