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
 * input: reg_a and reg_b from decoder
 * output: T1 and T1_r, T2 and T2_r to RS;
 * 
 ***********************************************************/

`timescale 1ns/100ps

`define DEBUG_MAP_TABLE

module Map_Table (
  input  en, clock, reset,
  input  MAP_TABLE_PACKET_IN  map_table_packet_in,

  `ifdef DEBUG_MAP_TABLE
  output MAP_TABLE_t [`NUM_MAP_TABLE-1:0] map_table_out,
  `endif
  output MAP_TABLE_PACKET_OUT map_table_packet_out
);

  MAP_TABLE_t [`NUM_MAP_TABLE-1:0]                map_table, next_map_table;
  MAP_TABLE_t [`NUM_ROB-1:0][`NUM_MAP_TABLE-1:0]  backup_map_table;
   
  `ifdef DEBUG
  assign map_table_out = map_table;
  `endif

  always_ff @(posedge clock) begin
    if(reset) begin
      for(int i=0; i < `NUM_MAP_TABLE; i++) begin
        map_table[i] <= `SD '{ i, `TRUE};
        for (int j=0; j<`NUM_ROB;j++) begin
          backup_map_table[j][i] <= `SD '{i, `TRUE};                  
        end                  
      end
    end else if(en) begin
      map_table <= `SD next_map_table;
    end // if (f_d_enable)
  end  // always


  always_comb begin
    next_map_table = map_table;
    // PR updata T_idx
    if ( map_table_packet_in.Dispatch_enable && map_table_packet_in.reg_dest != `ZERO_REG ) begin   // no dispatch hazard
      next_map_table[map_table_packet_in.reg_dest] = '{map_table_packet_in.Freelist_T, `FALSE};     //renew maptable from freelist but not ready yet
      backup_map_table[map_table_packet_in.tail_idx] = next_map_table;                              //backup the map
      for (int i=0; i<`NUM_MAP_TABLE;i++) begin
        backup_map_table[map_table_packet_in.tail_idx][i].T_plus_status = `TRUE;                        // ready all the bit
      end
    end
    // CDB_T updata ready
    if (map_table_packet_in.CDB_enable) begin
      for ( int i=0; i< `NUM_MAP_TABLE;i++) begin  
        if (map_table[i].PR_idx == map_table_packet_in.CDB_T) begin  // if CDB_T is the same as maptable value
          next_map_table[i].T_plus_status = `TRUE;                   // The Tag in maptable change to ready
          break;
        end
      end
    end
    // Rollback
    if (map_table_packet_in.rollback_en) begin
      next_map_table = backup_map_table[map_table_packet_in.br_idx];
    end
  end


  assign map_table_packet_out.Told_to_ROB = map_table[map_table_packet_in.reg_dest].PR_idx;
  assign map_table_packet_out.T1_to_RS    = map_table[map_table_packet_in.reg_a];
  assign map_table_packet_out.T2_to_RS    = map_table[map_table_packet_in.reg_b];
endmodule