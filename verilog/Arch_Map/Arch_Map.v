// Told & T from ROB 
// Told is replaced by T
`timescale 1ns/100ps

module Arch_Map (
  input  logic                     en, clock, reset,
  input  logic                     retire_en,
  input  ROB_ARCHMAP_PACKET        rob_archmap_packet,
`ifndef SYNTH_TEST
  output ARCH_MAP_t         [31:0] next_arch_map
`endif
);

  ARCH_MAP_t [31:0] arch_map;
`ifdef SYNTH_TEST
  ARCH_MAP_t [31:0] next_arch_map;
`endif

  always_comb begin
    next_arch_map = arch_map;
    if (retire_en && en) begin
      // for (logic [$clog2(`NUM_ARCH_TABLE):0] i=0; i< `NUM_ARCH_TABLE;i++) begin
      //   if (next_arch_map[i].T_idx == rob_archmap_packet.Told_idx) begin
      //     next_arch_map[i].T_idx = rob_archmap_packet.T_idx;
      //     break;
      //   end // if
      // end // for
      next_arch_map[rob_archmap_packet.dest_idx].T_idx = rob_archmap_packet.T_idx;
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