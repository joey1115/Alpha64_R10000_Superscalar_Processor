// Told & T from ROB 
// Told is replaced by T
`timescale 1ns/100ps

module Arch_Map (
  input  logic                                          en, clock, reset,
  input  logic                                          retire_en,    // retire signal from ROB
`ifndef DEBUG
  input  ROB_ARCH_MAP_OUT_t                             ROB_Arch_Map_out
`else
  input  ROB_ARCH_MAP_OUT_t                             ROB_Arch_Map_out,
  output logic              [31:0][$clog2(`NUM_PR)-1:0] next_arch_map
`endif
);

  logic [31:0][$clog2(`NUM_PR)-1:0] arch_map;
`ifndef DEBUG
  logic [31:0][$clog2(`NUM_PR)-1:0] next_arch_map;
`endif

  always_comb begin
    next_arch_map = arch_map;
    if (retire_en) begin
      next_arch_map[ROB_Arch_Map_out.dest_idx] = ROB_Arch_Map_out.T_idx;
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