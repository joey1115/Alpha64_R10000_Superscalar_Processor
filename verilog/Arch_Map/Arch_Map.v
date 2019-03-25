// Told & T from ROB 
// Told is replaced by T
`timescale 1ns/100ps

module Arch_Map (
  input  logic                     en, clock, reset,
  input  logic                     retire_en,    // retire signal from ROB
`ifdef SYNTH_TEST
  input  ROB_ARCH_MAP_OUT_t        ROB_Arch_Map_out
`else
  input  ROB_ARCH_MAP_OUT_t        ROB_Arch_Map_out,
  output ARCH_MAP_t         [31:0] next_arch_map
`endif
);

  ARCH_MAP_t [31:0] arch_map;
`ifdef SYNTH_TEST
  ARCH_MAP_t [31:0] next_arch_map;
`endif

  always_comb begin
    next_arch_map = arch_map;
    if (retire_en) begin
      next_arch_map[ROB_Arch_Map_out.dest_idx].T_idx = ROB_Arch_Map_out.T_idx;
    end // if(rob_archmap_packet.retire_en && en)
  end // always

  always_ff @(posedge clock) begin
    if(reset) begin
      arch_map = `ARCH_MAP_RESET;
    end else if(en) begin
      arch_map <= `SD next_arch_map;
    end // if (en)
  end // always

endmodule