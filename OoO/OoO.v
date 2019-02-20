module OoO(
  input                clock,                // system clock
  input                reset,                // system reset
  input  WB_REG_PACKET wb_reg_packet_in,
  input  IF_ID_PACKET  if_id_packet_in,
  output ID_EX_PACKET  id_packet_out
);

  PR_t        [$clog2(`NUM_PR)-1:0]  PR;
  MAP_TABLE_t [31:0]                 map_table;
  ARCH_MAP_t  [31:0]                 arch_map;
  RS_ENTRY_t  [$clog2(`NUM_ALU)-1:0] RS;
  ROB_ENTRY_t [$clog2(`NUM_ROB)-1:0] ROB;

endmodule