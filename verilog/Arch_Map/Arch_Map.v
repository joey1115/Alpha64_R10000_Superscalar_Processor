// Told & T from ROB 
// Told is replaced by T
`timescale 1ns/100ps

module Arch_Map (
  input  logic                                          en, clock, reset,
  input  logic              [`NUM_SUPER-1:0]            retire_en,    // retire signal from ROB
`ifndef DEBUG
  input  ROB_ARCH_MAP_OUT_t                             ROB_Arch_Map_out
`else
  input  ROB_ARCH_MAP_OUT_t                             ROB_Arch_Map_out,
  output logic              [31:0][$clog2(`NUM_PR)-1:0] next_arch_map,
`endif
  output ARCH_MAP_MAP_TABLE_OUT_t                           ARCH_MAP_MAP_Table_out
);

  logic [31:0][$clog2(`NUM_PR)-1:0] arch_map;
`ifndef DEBUG
  logic [31:0][$clog2(`NUM_PR)-1:0] next_arch_map;
`endif

  assign ARCH_MAP_MAP_Table_out.arch_map = arch_map;

  always_comb begin
    next_arch_map = arch_map;
    for(int i = 0; i < `NUM_SUPER; i++) begin
      if (retire_en[i]) begin
        next_arch_map[ROB_Arch_Map_out.dest_idx[i]] = ROB_Arch_Map_out.T_idx[i];
      end
    end
  end // always

  always_ff @(posedge clock) begin
    if(reset) begin
      arch_map <= `SD `ARCH_MAP_RESET;
    end else if(en) begin
      arch_map <= `SD next_arch_map;
    end // if (en)
  end // always

endmodule