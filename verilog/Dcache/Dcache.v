// cachemem32x64

`timescale 1ns/100ps

// read basically reads and tells if cache is miss or not
// write basically edit data to cache
// controller is incharge of dealing with the sequence
// module Dcache(
//         input logic                             clock, reset,
//         input logic                             wr1_en, wr2_en,
//         input logic [$clog2(`NUM_IDX)-1:0]      wr1_idx, wr2_idx, rd1_idx, rd2_idx,
//         input logic [$clog2(`NUM_BLOCK)-1:0]    wr1_BO, wr2_BO, rd1_BO, rd2_BO,
//         input logic [`NUM_D_TAG_BITS-1:0]       wr1_tag, wr2_tag, rd1_tag, rd1_tag,
//         input logic [63:0]                      wr1_data, wr2_data,
        
//         output logic [63:0]                     rd1_data_out, rd2_data_out,
//         output logic                            rd1_hit_out, rd2_hit_out
//       );
module Dcache(
  input logic                             clock, reset,

  //enable signals
  // input logic                                                    rd1_en, rd2_en, 
  input logic                                                       wr1_en, wr2_en,
  input logic                                                       rd1_wb_en, rd2_wb_en,
  input logic                                                       wr1_wb_en, wr2_wb_en,
  input logic                                                       mem_wr_en,

  //addr from proc
  input SASS_ADDR                                                   rd1_addr, rd2_addr, wr1_addr, wr2_addr,
  output logic [63:0]                                               rd1_data_out, rd2_data_out,
  output logic                                                      rd1_hit_out, rd2_hit_out, wr1_hit_out, wr2_hit_out,
  //addr from fwd path of mshr
  input SASS_ADDR                                                   rd1_wb_addr_BO_1, rd1_wb_addr_BO_2, rd2_wb_addr_BO_1, rd2_wb_addr_BO_2,
  input SASS_ADDR                                                   wr1_wb_addr_BO_1, wr1_wb_addr_BO_2, wr2_wb_addr_BO_1, wr2_wb_addr_BO_2,
  //addr from wb of mshr                          
  input SASS_ADDR                                                   mem_wr_addr_BO_1, mem_wr_addr_BO_2,

  
  input logic [63:0]                                                wr1_data, wr2_data,  
  input logic [63:0]                                                rd1_wb_data_BO_1, rd1_wb_data_BO_2, rd2_wb_data_BO_1, rd2_wb_data_BO_2,
  input logic [63:0]                                                wr1_wb_data_BO_1, wr1_wb_data_BO_2, wr2_wb_data_BO_1, wr2_wb_data_BO_2,
  input logic [63:0]                                                mem_wr_data_BO_1, mem_wr_data_BO_2,
  input logic                                                       mem_wr_dirty,
  

  output logic [6:0]                                                evicted_dirty_out, 
  output logic [6:0]                                                evicted_valid_out,
  output SASS_ADDR [6:0]                                            evicted_addr,
  output logic [6:0][`NUM_BLOCK-1:0][(MEMORY_BLOCK_SIZE*8-1):0]     evicted_data_out
);
  // logic [`NUM_WAY-1:0] rd3_hit, rd1_hit, rd2_hit, wr1_en_bus, wr1_dirty, evicted_dirty, evicted_valid;
  // logic [(64*(`NUM_WAY))-1:0] rd1_data, rd2_data;
  // logic [(MEMORY_BLOCK_SIZE*8*NUM_BLOCK)-1:0] evicted_data;
  // logic [(`NUM_TAG_BITS*(`NUM_WAY))-1:0]      evicted_tag_out
  // logic [$clog2(`NUM_WAY)-1:0] rd1_hit_idx, rd2_hit_idx, wr1_hit_idx;
  logic [`NUM_IDX-1:0][`NUM_WAY-1:0] LRU_sel, next_LRU_sel;
  logic [$clog2(`NUM_WAY)-1:0] other_rd1_way, other_rd2_way, other_wr1_way, other_wr2_way, other_rd1_wb_way, other_rd2_wb_way, other_wr1_wb_way, other_wr2_wb_way, other_mem_wr_way;
  logic [`NUM_IDX-1:0] LRU_bank_idx, next_LRU_bank_idx;

  //logic for bank interface
  logic [`NUM_WAY-1:0]                                                   wr1_en_sel;
  logic [`NUM_WAY-1:0]                                                   wr2_en_sel;
  logic [`NUM_WAY-1:0]                                                   rd1_wb_en_sel;
  logic [`NUM_WAY-1:0]                                                   rd2_wb_en_sel;
  logic [`NUM_WAY-1:0]                                                   wr1_wb_en_sel;
  logic [`NUM_WAY-1:0]                                                   wr2_wb_en_sel;
  logic [`NUM_WAY-1:0]                                                   mem_wr_en_sel;
  logic [`NUM_WAY-1:0][63:0]                                             rd1_data;
  logic [`NUM_WAY-1:0][63:0]                                             rd2_data;
  logic [`NUM_WAY-1:0]                                                   rd1_hit;
  logic [`NUM_WAY-1:0]                                                   rd2_hit;
  logic [`NUM_WAY-1:0]                                                   wr1_hit;
  logic [`NUM_WAY-1:0]                                                   wr2_hit;
  logic [`NUM_WAY-1:0][63:0]                                             rd1_wb_data_BO_1;
  logic [`NUM_WAY-1:0][63:0]                                             rd1_wb_data_BO_2;
  logic [`NUM_WAY-1:0][63:0]                                             rd2_wb_data_BO_1;
  logic [`NUM_WAY-1:0][63:0]                                             rd2_wb_data_BO_2;
  logic [`NUM_WAY-1:0][63:0]                                             wr1_wb_data_BO_1;
  logic [`NUM_WAY-1:0][63:0]                                             wr1_wb_data_BO_2;
  logic [`NUM_WAY-1:0][63:0]                                             wr2_wb_data_BO_1;
  logic [`NUM_WAY-1:0][63:0]                                             wr2_wb_data_BO_2;
  logic [`NUM_WAY-1:0][63:0]                                             mem_wr_data_BO_1;
  logic [`NUM_WAY-1:0][63:0]                                             mem_wr_data_BO_2;
  logic [`NUM_WAY-1:0]                                                   dirty;
  logic [`NUM_WAY-1:0][$clog2(`NUM_IDX)-1:0]                             evicted_idx1;
  logic [`NUM_WAY-1:0][$clog2(`NUM_IDX)-1:0]                             evicted_idx2;
  logic [`NUM_WAY-1:0][$clog2(`NUM_IDX)-1:0]                             evicted_idx3;
  logic [`NUM_WAY-1:0][$clog2(`NUM_IDX)-1:0]                             evicted_idx4;
  logic [`NUM_WAY-1:0][$clog2(`NUM_IDX)-1:0]                             evicted_idx5;
  logic [`NUM_WAY-1:0][$clog2(`NUM_IDX)-1:0]                             evicted_idx6;
  logic [`NUM_WAY-1:0][$clog2(`NUM_IDX)-1:0]                             evicted_idx7;
  logic [`NUM_WAY-1:0][`NUM_TAG_BITS-1:0]                                evicted_tag1;
  logic [`NUM_WAY-1:0][`NUM_TAG_BITS-1:0]                                evicted_tag2;
  logic [`NUM_WAY-1:0][`NUM_TAG_BITS-1:0]                                evicted_tag3;
  logic [`NUM_WAY-1:0][`NUM_TAG_BITS-1:0]                                evicted_tag4;
  logic [`NUM_WAY-1:0][`NUM_TAG_BITS-1:0]                                evicted_tag5;
  logic [`NUM_WAY-1:0][`NUM_TAG_BITS-1:0]                                evicted_tag6;
  logic [`NUM_WAY-1:0][`NUM_TAG_BITS-1:0]                                evicted_tag7;
  logic [`NUM_WAY-1:0]                                                   evicted_dirty1;
  logic [`NUM_WAY-1:0]                                                   evicted_dirty2;
  logic [`NUM_WAY-1:0]                                                   evicted_dirty3;
  logic [`NUM_WAY-1:0]                                                   evicted_dirty4;
  logic [`NUM_WAY-1:0]                                                   evicted_dirty5;
  logic [`NUM_WAY-1:0]                                                   evicted_dirty6;
  logic [`NUM_WAY-1:0]                                                   evicted_dirty7;
  logic [`NUM_WAY-1:0]                                                   evicted_valid1;
  logic [`NUM_WAY-1:0]                                                   evicted_valid2;
  logic [`NUM_WAY-1:0]                                                   evicted_valid3;
  logic [`NUM_WAY-1:0]                                                   evicted_valid4;
  logic [`NUM_WAY-1:0]                                                   evicted_valid5;
  logic [`NUM_WAY-1:0]                                                   evicted_valid6;
  logic [`NUM_WAY-1:0]                                                   evicted_valid7;
  logic [`NUM_WAY-1:0][`NUM_BLOCK-1:0][(MEMORY_BLOCK_SIZE*8-1):0]        evicted_data1;
  logic [`NUM_WAY-1:0][`NUM_BLOCK-1:0][(MEMORY_BLOCK_SIZE*8-1):0]        evicted_data2;
  logic [`NUM_WAY-1:0][`NUM_BLOCK-1:0][(MEMORY_BLOCK_SIZE*8-1):0]        evicted_data3;
  logic [`NUM_WAY-1:0][`NUM_BLOCK-1:0][(MEMORY_BLOCK_SIZE*8-1):0]        evicted_data4;
  logic [`NUM_WAY-1:0][`NUM_BLOCK-1:0][(MEMORY_BLOCK_SIZE*8-1):0]        evicted_data5;
  logic [`NUM_WAY-1:0][`NUM_BLOCK-1:0][(MEMORY_BLOCK_SIZE*8-1):0]        evicted_data6;
  logic [`NUM_WAY-1:0][`NUM_BLOCK-1:0][(MEMORY_BLOCK_SIZE*8-1):0]        evicted_data7;





  // assign evicted_idx_out = wr1_idx;//the index thst is being eviceted

  assign other_rd1_way = rd1_hit_idx + 1;
  assign other_rd2_way = rd2_hit_idx + 1;
  assign other_wr1_way = wr1_hit_idx + 1;
  assign other_wr2_way = wr2_hit_idx + 1;
  assign other_rd1_wb_way = LRU_bank_idx[rd1_wb_addr_BO_1.set_index] + 1;
  assign other_rd2_wb_way = LRU_bank_idx[rd2_wb_addr_BO_1.set_index] + 1;
  assign other_wr1_wb_way = LRU_bank_idx[wr1_wb_addr_BO_1.set_index] + 1;
  assign other_wr2_wb_way = LRU_bank_idx[wr2_wb_addr_BO_1.set_index] + 1;
  assign other_mem_wr_way = LRU_bank_idx[mem_wr_addr_BO_1.set_index] + 1;

  //2 way LRU logic
  always_comb begin
    next_LRU_sel = LRU_sel;
    next_LRU_bank_idx = LRU_bank_idx;

    if (mem_wr_en) begin
      next_LRU_sel[mem_wr_addr_BO_1.set_index][next_LRU_bank_idx[mem_wr_addr_BO_1.set_index]] = 0;
      next_LRU_sel[mem_wr_addr_BO_1.set_index][other_mem_wr_way] = 1;
      next_LRU_bank_idx[mem_wr_addr_BO_1.set_index] = next_LRU_bank_idx[mem_wr_addr_BO_1.set_index];
    end

    if (wr2_wb_en) begin
      next_LRU_sel[wr2_wb_addr_BO_1.set_index][next_LRU_bank_idx[wr2_wb_addr_BO_1.set_index]] = 0;
      next_LRU_sel[wr2_wb_addr_BO_1.set_index][other_wr2_wb_way] = 1;
      next_LRU_bank_idx[wr2_wb_addr_BO_1.set_index] = next_LRU_bank_idx[wr2_wb_addr_BO_1.set_index];
    end

    if (wr1_wb_en) begin
      next_LRU_sel[wr1_wb_addr_BO_1.set_index][next_LRU_bank_idx[wr1_wb_addr_BO_1.set_index]] = 0;
      next_LRU_sel[wr1_wb_addr_BO_1.set_index][other_wr1_wb_way] = 1;
      next_LRU_bank_idx[wr1_wb_addr_BO_1.set_index] = next_LRU_bank_idx[wr1_wb_addr_BO_1.set_index];
    end
    
    if (rd2_wb_en) begin
      next_LRU_sel[rd2_wb_addr_BO_1.set_index][next_LRU_bank_idx[rd2_wb_addr_BO_1.set_index]] = 0;
      next_LRU_sel[rd2_wb_addr_BO_1.set_index][other_rd2_wb_way] = 1;
      next_LRU_bank_idx[rd2_wb_addr_BO_1.set_index] = next_LRU_bank_idx[rd2_wb_addr_BO_1.set_index];
    end

    if (rd1_wb_en) begin
      next_LRU_sel[rd1_wb_addr_BO_1.set_index][next_LRU_bank_idx[rd1_wb_addr_BO_1.set_index]] = 0;
      next_LRU_sel[rd1_wb_addr_BO_1.set_index][other_rd1_wb_way] = 1;
      next_LRU_bank_idx[rd1_wb_addr_BO_1.set_index] = next_LRU_bank_idx[rd1_wb_addr_BO_1.set_index];
    end

    if (wr2_en & wr2_hit_out) begin
      next_LRU_sel[wr2_addr.set_index][wr2_hit_idx] = 0;
      next_LRU_sel[wr2_addr.set_index][other_wr2_way] = 1;
      next_LRU_bank_idx[wr2_addr.set_index] = other_wr2_way;
    end

    if (wr1_en & wr1_hit_out) begin
      next_LRU_sel[wr1_addr.set_index][wr1_hit_idx] = 0;
      next_LRU_sel[wr1_addr.set_index][other_wr1_way] = 1;
      next_LRU_bank_idx[wr1_addr.set_index] = other_wr1_way;
    end

    if (rd2_hit_out) begin
      next_LRU_sel[rd2_addr.set_index][rd2_hit_idx] = 0;
      next_LRU_sel[rd2_addr.set_index][other_rd2_way] = 1;
      next_LRU_bank_idx[rd2_addr.set_index] = other_rd2_way;
    end

    if(rd1_hit_out) begin
      next_LRU_sel[rd1_addr.set_index][rd1_hit_idx] = 0;
      next_LRU_sel[rd1_addr.set_index][other_rd1_way] = 1;
      next_LRU_bank_idx[rd1_addr.set_index] = other_rd1_way;
    end
  end

  always_ff @(posedge clock) begin
    if(reset)
      LRU_sel <= `SD 2'b01;
    else
      LRU_sel <= `SD next_LRU_sel;
      LRU_bank_idx <= `SD next_LRU_bank_idx;
  end
  
  assign wr1_en_sel = (wr1_en & wr1_hit_out) ? wr1_hit : (1 << LRU_bank_idx[wr1_addr.set_index]);
  assign wr2_en_sel = (wr2_en & wr2_hit_out) ? wr2_hit : (1 << LRU_bank_idx[wr2_addr.set_index]);
  assign rd1_wb_en_sel = (rd1_wb_en) ? (1 << LRU_bank_idx[rd1_wb_addr_BO_1.set_index]) : 0;
  assign rd2_wb_en_sel = (rd2_wb_en) ? (1 << LRU_bank_idx[rd2_wb_addr_BO_1.set_index]) : 0;
  assign wr1_wb_en_sel = (wr1_wb_en) ? (1 << LRU_bank_idx[wr1_wb_addr_BO_1.set_index]) : 0;
  assign wr2_wb_en_sel = (wr2_wb_en) ? (1 << LRU_bank_idx[wr2_wb_addr_BO_1.set_index]) : 0;
  assign mem_wr_en_sel = (mem_wr_en) ? (1 << LRU_bank_idx[mem_wr_addr_BO_1.set_index]) : 0;


  
  
  assign wr1_en_bus = (wr1_en & wr1_hit_out)? wr1_hit : //if data to store in cache, write to where it is hit
                      (wr1_en & wr1_from_mem)? LRU_bank_sel : 0; //if data from mem and line not in cache, write to the LRU bank
  ////////////////////////////////////////////////////////~~~~~~~~~~~~~~ need to think through the wr operations of the cache  wr1_hit | wr1_en in bank
  cache_bank bank [`NUM_WAY-1:0] (
      .clock(clock),
      .reset(reset),

      .wr1_en(wr1_en_sel),
      .wr2_en(wr2_en_sel),
      .rd1_wb_en(rd1_wb_en_sel),
      .rd2_wb_en(rd2_wb_en_sel),
      .wr1_wb_en(wr1_wb_en_sel),
      .wr2_wb_en(wr2_wb_en_sel),
      .mem_wr_en(mem_wr_en_sel),

      .rd1_addr(rd1_addr),
      .rd2_addr(rd2_addr),
      .wr1_addr(wr1_addr),
      .wr2_addr(wr2_addr),

      .rd1_data(rd1_data),
      .rd2_data(rd2_data),

      .rd1_hit(rd1_hit),
      .rd2_hit(rd2_hit),
      .wr1_hit(wr1_hit),
      .wr2_hit(wr2_hit),

      .rd1_wb_addr_BO_1(rd1_wb_addr_BO_1),
      .rd1_wb_addr_BO_2(rd1_wb_addr_BO_2),
      .rd2_wb_addr_BO_1(rd2_wb_addr_BO_1),
      .rd2_wb_addr_BO_2(rd2_wb_addr_BO_2),
      .wr1_wb_addr_BO_1(wr1_wb_addr_BO_1),
      .wr1_wb_addr_BO_2(wr1_wb_addr_BO_2),
      .wr2_wb_addr_BO_1(wr2_wb_addr_BO_1),
      .wr2_wb_addr_BO_2(wr2_wb_addr_BO_2),
      .mem_wr_addr_BO_1(mem_wr_addr_BO_1),
      .mem_wr_addr_BO_2(mem_wr_addr_BO_2),

      .wr1_data(wr1_data),
      .wr2_data(wr2_data),

      .rd1_wb_data_BO_1(rd1_wb_data_BO_1),
      .rd1_wb_data_BO_2(rd1_wb_data_BO_2),
      .rd2_wb_data_BO_1(rd2_wb_data_BO_1),
      .rd2_wb_data_BO_2(rd2_wb_data_BO_2),
      .wr1_wb_data_BO_1(wr1_wb_data_BO_1),
      .wr1_wb_data_BO_2(wr1_wb_data_BO_2),
      .wr2_wb_data_BO_1(wr2_wb_data_BO_1),
      .wr2_wb_data_BO_2(wr2_wb_data_BO_2),
      .mem_wr_data_BO_1(mem_wr_data_BO_1), 
      .mem_wr_data_BO_2(mem_wr_data_BO_2),

      .mem_wr_dirty(dirty),
  
      .evicted_idx1(evicted_idx1),
      .evicted_idx2(evicted_idx2),
      .evicted_idx3(evicted_idx3),
      .evicted_idx4(evicted_idx4),
      .evicted_idx5(evicted_idx5),
      .evicted_idx6(evicted_idx6),
      .evicted_idx7(evicted_idx7),
     
      .evicted_tag1(evicted_tag1),
      .evicted_tag2(evicted_tag2),
      .evicted_tag3(evicted_tag3),
      .evicted_tag4(evicted_tag4),
      .evicted_tag5(evicted_tag5),
      .evicted_tag6(evicted_tag6),
      .evicted_tag7(evicted_tag7),
  
      .evicted_dirty1(evicted_dirty1),
      .evicted_dirty2(evicted_dirty2),
      .evicted_dirty3(evicted_dirty3),
      .evicted_dirty4(evicted_dirty4),
      .evicted_dirty5(evicted_dirty5),
      .evicted_dirty6(evicted_dirty6),
      .evicted_dirty7(evicted_dirty7),
  
      .evicted_valid1(evicted_valid1),
      .evicted_valid2(evicted_valid2),
      .evicted_valid3(evicted_valid3),
      .evicted_valid4(evicted_valid4),
      .evicted_valid5(evicted_valid5),
      .evicted_valid6(evicted_valid6),
      .evicted_valid7(evicted_valid7),
  
      .evicted_data1(evicted_data1),
      .evicted_data2(evicted_data2),
      .evicted_data3(evicted_data3),
      .evicted_data4(evicted_data4),
      .evicted_data5(evicted_data5),
      .evicted_data6(evicted_data6),
      .evicted_data7(evicted_data7));

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
        rd2_hit_out = 0;
        for(int i = 0 ; i <`NUM_WAY; i++) begin
          if(rd2_hit[i]) begin
            rd2_data_out = rd2_data[(64*i)+63:64*i];
            rd2_hit_out = 1;
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
      always_comb begin
        rd3_hit_out = 0;
        for(int i = 0 ; i <`NUM_WAY; i++) begin
          if(rd3_hit[i]) begin
            rd3_data_out = rd3_data[(64*i)+63:64*i];
            rd3_hit_out = 1;
          end
        end
      end
      always_comb begin
        evicted_valid_out = 0;
        for(int i = 0 ; i <`NUM_WAY; i++) begin
          if(evicted_valid[i]) begin
            evicted_data_out = evicted_data[((MEMORY_BLOCK_SIZE*8*NUM_BLOCK)*i) + ((MEMORY_BLOCK_SIZE*8*NUM_BLOCK)-1):(MEMORY_BLOCK_SIZE*8*NUM_BLOCK)*i];
            evicted_tag_out = evicted_tag[(64*i)+63:64*i];
            evicted_dirty_out = evicted_dirty[i];
            evicted_valid_out = 1;
          end
        end
      end
      // always_comb begin
      //   wr1_dirty_out = 0;
      //   for(int i = 0 ; i <`NUM_WAY; i++) begin
      //     if(wr1_dirty[i]) begin
      //       wr1_dirty_out = 1;
      //     end
      //   end
      // end
      

  pe rd1_bank_sel (.gnt(rd1_hit),.enc(rd1_hit_idx));
  pe rd2_bank_sel (.gnt(rd2_hit),.enc(rd2_hit_idx));
  pe wr1_bank_sel (.gnt(wr1_hit),.enc(wr1_hit_idx));
  // pe wr2_bank_sel (.gnt(wr2_hit),.enc(wr2_hit_idx));

endmodule


module cache_bank(
  input logic                                                       clock, reset,

  //enable signals                          
  input logic                                                       wr1_en, wr2_en,
  input logic                                                       rd1_wb_en, rd2_wb_en,
  input logic                                                       wr1_wb_en, wr2_wb_en,
  input logic                                                       mem_wr_en,

  //addr from proc                          
  input SASS_ADDR                                                   rd1_addr, rd2_addr, wr1_addr, wr2_addr,
  output logic [63:0]                                               rd1_data, rd2_data,
  output logic                                                      rd1_hit, rd2_hit, wr1_hit, wr2_hit, 
  //addr from fwd path of mshr                          
  input SASS_ADDR                                                   rd1_wb_addr_BO_1, rd1_wb_addr_BO_2, rd2_wb_addr_BO_1, rd2_wb_addr_BO_2,
  input SASS_ADDR                                                   wr1_wb_addr_BO_1, wr1_wb_addr_BO_2, wr2_wb_addr_BO_1, wr2_wb_addr_BO_2,
  //addr from wb of mshr                          
  input SASS_ADDR                                                   mem_wr_addr_BO_1, mem_wr_addr_BO_2,

  input logic [63:0]                                                wr1_data, wr2_data,  
  input logic [63:0]                                                rd1_wb_data_BO_1, rd1_wb_data_BO_2, rd2_wb_data_BO_1, rd2_wb_data_BO_2,
  input logic [63:0]                                                wr1_wb_data_BO_1, wr1_wb_data_BO_2, wr2_wb_data_BO_1, wr2_wb_data_BO_2,
  input logic [63:0]                                                mem_wr_data_BO_1, mem_wr_data_BO_2,
  input logic                                                       mem_wr_dirty,

  //evicted index to output the address(TAG of the evicted line)
  input logic [$clog2(`NUM_IDX)-1:0]                                evicted_idx1, evicted_idx2, evicted_idx3, evicted_idx4, evicted_idx5, evicted_idx6, evicted_idx7,
  output logic [`NUM_TAG_BITS-1:0]                                  evicted_tag1, evicted_tag2, evicted_tag3, evicted_tag4, evicted_tag5, evicted_tag6, evicted_tag7, 
  output logic                                                      evicted_dirty1, evicted_dirty2, evicted_dirty3, evicted_dirty4, evicted_dirty5, evicted_dirty6, evicted_dirty7,
  output logic                                                      evicted_valid1, evicted_valid2, evicted_valid3, evicted_valid4, evicted_valid5, evicted_valid6, evicted_valid7,
  output logic [`NUM_BLOCK-1:0][(MEMORY_BLOCK_SIZE*8-1):0]          evicted_data1, evicted_data2, evicted_data3, evicted_data4, evicted_data5, evicted_data6, evicted_data7 
);
    
  D_CACHE_LINE_t [`NUM_IDX-1:0] cache_bank, next_cache_bank;

  //check read hit
  assign rd1_hit = cache_bank[rd1_addr.set_index].valid[rd1_addr.BO] && (rd1_addr.tag == cache_bank[rd1_addr.set_index].tag);
  assign rd1_data = cache_bank[rd1_addr.set_index].data[rd1_addr.BO];

  assign rd2_hit = cache_bank[rd2_addr.set_index].valid[rd2_addr.BO] && (rd2_addr.tag == cache_bank[rd2_addr.set_index].tag);
  assign rd2_data = cache_bank[rd2_addr.set_index].data[rd2_addr.BO];

  //check write hit
  assign wr1_hit = cache_bank[wr1_addr.set_index].valid[wr1_addr.BO] && (wr1_addr.tag == cache_bank[wr1_addr.set_index].tag);
  assign wr2_hit = cache_bank[wr2_addr.set_index].valid[wr2_addr.BO] && (wr2_addr.tag == cache_bank[wr2_addr.set_index].tag);

  //evicted
  assign evicted_valid = (cache_bank[evicted_idx].valid == ({`NUM_BLOCK{1'b1}}));
  assign evicted_dirty = cache_bank[evicted_idx].dirty;
  assign evicted_tag = cache_bank[evicted_idx].tag;
  assign evicted_data = cache_bank[evicted_idx].data;

  always_comb begin
    next_cache_bank = cache_bank;

    if(mem_wr_en) begin
      next_cache_bank[mem_wr_addr_BO_1.set_index].valid[mem_wr_addr_BO_1.BO] = 1;
      next_cache_bank[mem_wr_addr_BO_1.set_index].data[mem_wr_addr_BO_1.BO] = mem_wr_data_BO_1;
      next_cache_bank[mem_wr_addr_BO_2.set_index].valid[mem_wr_addr_BO_2.BO] = 1;
      next_cache_bank[mem_wr_addr_BO_2.set_index].data[mem_wr_addr_BO_2.BO] = mem_wr_data_BO_2;
      next_cache_bank[mem_wr_addr_BO_1.set_index].tag = mem_wr_addr_BO_1.tag;
      next_cache_bank[mem_wr_addr_BO_1.set_index_idx].dirty = mem_wr_dirty;
    end

    if(wr2_wb_en) begin
      next_cache_bank[wr2_wb_addr_BO_1.set_index].valid[wr2_wb_addr_BO_1.BO] = 1;
      next_cache_bank[wr2_wb_addr_BO_1.set_index].data[wr2_wb_addr_BO_1.BO] = wr2_wb_data_BO_1;
      next_cache_bank[wr2_wb_addr_BO_2.set_index].valid[wr2_wb_addr_BO_2.BO] = 1;
      next_cache_bank[wr2_wb_addr_BO_2.set_index].data[wr2_wb_addr_BO_2.BO] = wr2_wb_data_BO_2;
      next_cache_bank[wr2_wb_addr_BO_1.set_index].tag = wr2_wb_addr_BO_1.tag;
      next_cache_bank[wr2_wb_addr_BO_1.set_index_idx].dirty = 0;
    end

    if(wr1_wb_en) begin
      next_cache_bank[wr1_wb_addr_BO_1.set_index].valid[wr1_wb_addr_BO_1.BO] = 1;
      next_cache_bank[wr1_wb_addr_BO_1.set_index].data[wr1_wb_addr_BO_1.BO] = wr1_wb_data_BO_1;
      next_cache_bank[wr1_wb_addr_BO_2.set_index].valid[wr1_wb_addr_BO_2.BO] = 1;
      next_cache_bank[wr1_wb_addr_BO_2.set_index].data[wr1_wb_addr_BO_2.BO] = wr1_wb_data_BO_2;
      next_cache_bank[wr1_wb_addr_BO_1.set_index].tag = wr1_wb_addr_BO_1.tag;
      next_cache_bank[wr1_wb_addr_BO_1.set_index_idx].dirty = 0;
    end

    if(rd2_wb_en) begin
      next_cache_bank[rd2_wb_addr_BO_1.set_index].valid[rd2_wb_addr_BO_1.BO] = 1;
      next_cache_bank[rd2_wb_addr_BO_1.set_index].data[rd2_wb_addr_BO_1.BO] = rd2_wb_data_BO_1;
      next_cache_bank[rd2_wb_addr_BO_2.set_index].valid[rd2_wb_addr_BO_2.BO] = 1;
      next_cache_bank[rd2_wb_addr_BO_2.set_index].data[rd2_wb_addr_BO_2.BO] = rd2_wb_data_BO_2;
      next_cache_bank[rd2_wb_addr_BO_1.set_index].tag = rd2_wb_addr_BO_1.tag;
      next_cache_bank[rd2_wb_addr_BO_1.set_index_idx].dirty = 0;
    end

    if(rd1_wb_en) begin
      next_cache_bank[rd1_wb_addr_BO_1.set_index].valid[rd1_wb_addr_BO_1.BO] = 1;
      next_cache_bank[rd1_wb_addr_BO_1.set_index].data[rd1_wb_addr_BO_1.BO] = rd1_wb_data_BO_1;
      next_cache_bank[rd1_wb_addr_BO_2.set_index].valid[rd1_wb_addr_BO_2.BO] = 1;
      next_cache_bank[rd1_wb_addr_BO_2.set_index].data[rd1_wb_addr_BO_2.BO] = rd1_wb_data_BO_2;
      next_cache_bank[rd1_wb_addr_BO_1.set_index].tag = rd1_wb_addr_BO_1.tag;
      next_cache_bank[rd1_wb_addr_BO_1.set_index_idx].dirty = 0;
    end
    
    if(wr2_en) begin
      next_cache_bank[wr2_addr.set_index].valid[wr2_addr.BO] = 1;
      next_cache_bank[wr2_addr.set_index].tag = wr2_addr.tag;
      next_cache_bank[wr2_addr.set_index].data[wr2_addr.BO] = wr2_data;
      next_cache_bank[wr2_addr.set_index_idx].dirty = 1;
    end

    if(wr1_en) begin
      next_cache_bank[wr1_addr.set_index].valid[wr1_addr.BO] = 1;
      next_cache_bank[wr1_addr.set_index].tag = wr1_addr.tag;
      next_cache_bank[wr1_addr.set_index].data[wr1_addr.BO] = wr1_data;
      next_cache_bank[wr1_addr.set_index_idx].dirty = 1;
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

// module LRU_logic (
//   input logic clock, reset,
//   input logic [$clog2(`NUM_WAY)-1:0] reset_bank_idx,
//   input logic select_prev,
//   input logic [$clog2(`NUM_WAY)-1:0] prev_bank_idx,
  
//   output logic [$clog2(`NUM_WAY)-1:0] bank_idx
// );

//   logic [$clog2(`NUM_WAY)-1:0] next_bank_idx;

//   assign next_bank_idx = (select_prev) ? prev_bank_idx : bank_idx;

//   always_ff @(posedge clock) begin
//     if(reset)
//       bank_idx <= `SD reset_bank_idx;
//     else
//       bank_idx <= `SD next_bank_idx;
//   end
  
// endmodule

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