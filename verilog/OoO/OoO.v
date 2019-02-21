module OoO_m (
  input  ID_EX_PACKET  id_packet_out,
  input  EX_MEM_PACKET ex_packet_out,
  input  MEM_WB_PACKET mem_packet_out,
  output ID_EX_PACKET  id_packet_new,
  output EX_MEM_PACKET ex_packet_new,
  output MEM_WB_PACKET mem_packet_new
);

  // PR_t        [$clog2(`NUM_PR)-1:0]  next_PR;
  // MAP_TABLE_t [31:0]                 next_map_table;
  // ARCH_MAP_t  [31:0]                 next_arch_map;
  // RS_ENTRY_t  [$clog2(`NUM_ALU)-1:0] next_RS;
  // ROB_ENTRY_t [$clog2(`NUM_ROB)-1:0] next_ROB;

  // always_comb begin
  //   genvar i, j;
  //   for (i = 0; i <= `NUM_PR; i++) begin

  //     if ( i == `NUM_PR ) begin

  //       // No next_PR available
  //       break;

  //     end else if ( next_PR[i].free == PR_FREE ) begin

  //       // Assign to ROB

  //     end // i == (`NUM_PR-1)

  //   end // for
  // end

  // always_ff @(posedge clock) begin
  //   if(reset) begin
  //     PR        <= `SD {`NUM_PR{'{0, PR_FREE}};
  //     map_table <= `SD 0;
  //     arch_map  <= `SD 0;
  //     RS        <= `SD 0;
  //     // ROB       <= `SD {`NUM_ROB{'{HT_FREE, PR_FREE}};
  //   end else begin
  //     PR        <= `SD next_PR;
  //     map_table <= `SD next_map_table;
  //     arch_map  <= `SD next_arch_map;
  //     RS        <= `SD next_RS;
  //     ROB       <= `SD next_ROB;
  //   end // if (if_id_enable)
  // end // always

endmodule