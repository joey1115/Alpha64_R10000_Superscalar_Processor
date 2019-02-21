module arch_map_m (
  input  ARCH_MAP_PACKET_IN  arch_map_packet_in,
  output ARCH_MAP_PACKET_OUT arch_map_packet_out
);

  ARCH_MAP_t [31:0] arch_map, next_arch_map;

// ROB logic
  always_ff @(posedge clock) begin
    if(reset) begin
      // arch_map <= `SD 0;
    end else if(rob_packet_in.en) begin
      arch_map <= `SD next_arch_map;
    end // if (if_id_enable)
  end // always

endmodule