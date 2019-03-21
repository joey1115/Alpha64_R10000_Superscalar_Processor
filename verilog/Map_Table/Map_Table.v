/**********************************************************
 * MapTable Procedure
 * 
 * --- Complete ---
 * 1. Update ready bit from CDB
 * input: CDB_T; CDB_enable from CDB
 * 
 * ---- Dispatch ---
 * 1. see if there is a struct hazard
 * input: Dispatch_enable from dispatch control
 * 
 * 2. if no hazard,
 * (1) send T_old to ROB, get new T from PR
 * input: reg_dest from decoder; T from PR
 * output: T_old to ROB;
 * 
 * (2) send T1 (and ready bit) and T2 (and ready bit) to RS
 * input: reg_a_idx and reg_b_idx from decoder
 * output: T1 and T1_r, T2 and T2_r to RS;
 * 
 ***********************************************************/

`timescale 1ns/100ps

module Map_Table (
  input  logic                en, clock, reset,
  input  MAP_TABLE_PACKET_IN  map_table_packet_in,
`ifndef SYNTH_TEST
  output T_t [31:0]           map_table_out,
`endif
  output MAP_TABLE_PACKET_OUT map_table_packet_out
);

  T_t                       T1, T2;
  T_t [31:0]                map_table, next_map_table;
  T_t [`NUM_ROB-1:0][31:0]  backup_map_table, next_backup_map_table;
   
`ifndef SYNTH_TEST
  assign map_table_out                 = map_table;
`endif
  assign map_table_packet_out.Told_idx = map_table[map_table_packet_in.reg_dest].idx;
  assign T1                            = map_table[map_table_packet_in.reg_a_idx];
  assign T2                            = map_table[map_table_packet_in.reg_b_idx];
  assign map_table_packet_out.T1.idx   = T1.idx;
  assign map_table_packet_out.T1.ready = ( map_table_packet_in.CDB_en && T1.idx == map_table_packet_in.CDB_T_idx ) || T1.ready;
  assign map_table_packet_out.T2.idx   = T2.idx;
  assign map_table_packet_out.T2.ready = ( map_table_packet_in.CDB_en && T2.idx == map_table_packet_in.CDB_T_idx ) || T2.ready;

  always_comb begin
    next_map_table = map_table;
    // Rollback
    if (map_table_packet_in.rollback_en) begin
      next_map_table = backup_map_table[map_table_packet_in.ROB_rollback_idx];
    end
    // CDB_T updata ready
    if ( map_table_packet_in.CDB_en && map_table[map_table_packet_in.CDB_dest_idx].idx == map_table_packet_in.CDB_T_idx ) begin
      next_map_table[map_table_packet_in.CDB_dest_idx].ready = `TRUE;
    end
    // PR update T_idx
    if ( map_table_packet_in.Dispatch_en ) begin // no dispatch hazard
      next_map_table[map_table_packet_in.dest_idx] = '{map_table_packet_in.T_idx, `FALSE}; // renew maptable from freelist but not ready yet
      next_map_table[31].ready                     = `TRUE;                                // Force ZERO_REG to be rady
    end
  end

  always_comb begin
    next_backup_map_table = backup_map_table;
    if ( map_table_packet_in.Dispatch_en ) begin                                // no dispatch hazard
      next_backup_map_table[map_table_packet_in.ROB_tail_idx] = next_map_table; // backup the map
      for (int i=0; i<32;i++) begin
        next_backup_map_table[map_table_packet_in.tail_idx][i].ready = `TRUE;   // ready all the bit
      end
    end
  end

  always_ff @(posedge clock) begin
    if(reset) begin
      map_table        <= `SD `MAP_TABLE_RESET;
      backup_map_table <= `SD `MAP_TABLE_STACK_RESET;
    end else if(en) begin
      map_table        <= `SD next_map_table;
      backup_map_table <= `SD next_backup_map_table;
    end
  end

endmodule