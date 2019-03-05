// Told & T from ROB 
// Told is replaced by T
module Arch_Map (
  input  en, clock, reset,
  input  ARCH_MAP_PACKET_IN  arch_map_packet_in,
  output ARCH_MAP_PACKET_OUT arch_map_packet_out
);

  ARCH_MAP_t [31:0] arch_map, next_arch_map;

// ROB logic
  always_ff @(posedge clock) begin
    if(reset) begin
      for(logic [$clog2(`NUM_ARCH_MAP):0] i=0; i < `NUM_ARCH_MAP; i++) begin
        arch_map[i].PR_idx = i;
      end
    end else if(en) begin
      arch_map <= `SD next_arch_map;
    end // if (f_d_enable)
  end // always

  always_comb begin
    next_arch_map = arch_map;
    if (arch_map_packet_in.r && en) begin
     genvar i;
      for (i=0; i< `NUM_ARCH_TABLE;i++) begin
        if (arch_map[i].PR_idx == arch_map_packet_in.Rob_retire_Told) begin
          next_arch_map[i].PR_idx =arch_map_packet_in.Rob_retire_T;
          break;
        end
    end
  end
endmodule