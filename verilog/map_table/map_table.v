module map_table_m (
  input  MAP_TABLE_PACKET_IN  map_table_packet_in,
  output MAP_TABLE_PACKET_OUT map_table_packet_out
);

  MAP_TABLE_t [31:0] map_table, next_map_table;

// ROB logic
  always_ff @(posedge clock) begin
    if(reset) begin
      // map_table <= `SD 0;
    end else if(rob_packet_in.en) begin
      map_table <= `SD next_map_table;
    end // if (f_d_enable)
  end // always

endmodule