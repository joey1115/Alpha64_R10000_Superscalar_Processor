// Told & T from ROB 
// Told is replaced by T
`timescale 1ns/100ps

`define DEBUG

module Arch_Map (
  `ifdef DEBUG
  output ARCH_MAP_t [31:0] next_arch_map,
  `endif
  
  input  en, clock, reset,
  input  ARCH_MAP_PACKET_IN  arch_map_packet_in
);

  `ifndef DEBUG
  ARCH_MAP_t [31:0] next_arch_map;
  `endif

  ARCH_MAP_t [31:0] arch_map;

  always_ff @(posedge clock) begin
    if(reset) begin
      for(logic [$clog2(`NUM_ARCH_TABLE):0] i=0; i < `NUM_ARCH_TABLE; i++) begin
        arch_map[i].PR_idx = i;
      end // for
    end else if(en) begin
      arch_map <= `SD next_arch_map;
    end // if (en)
  end // always

  always_comb begin
    next_arch_map = arch_map;
    if (arch_map_packet_in.r && en) begin
      for (logic [$clog2(`NUM_ARCH_TABLE):0] i=0; i< `NUM_ARCH_TABLE;i++) begin
        if (next_arch_map[i].PR_idx == arch_map_packet_in.Rob_retire_Told) begin
          next_arch_map[i].PR_idx = arch_map_packet_in.Rob_retire_T;
          break;
        end // if
      end // for
    end // if(arch_map_packet_in.r && en)
  end // always
endmodule