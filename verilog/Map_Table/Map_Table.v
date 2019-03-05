/*
Input:
Dispatch rega, regb, reg_dest;
CDB.T from CDB;
T from Free list;
Registers from Arch Map;
Output:
T1 & T2 to Reservation Stations;
Told to ROB;
*/
// the size of maptable
// definition of input and output
// output T1 T2 to RS
// output Told to ROB
`timescale 1ns/100ps
module Map_Table (
  input  en, clock, reset,
  input  MAP_TABLE_PACKET_IN  map_table_packet_in,
  output MAP_TABLE_PACKET_OUT map_table_packet_out
);

  MAP_TABLE_t [`NUM_MAP_TABLE-1:0] map_table, next_map_table;
  logic i;

// ROB logic
  always_ff @(posedge clock) begin
    if(reset) begin
      for(int i=0; i < `NUM_MAP_TABLE; i++) begin
        map_table[i] <= `SD '{ i, `TRUE};                  
      end
    end else if(en) begin
      map_table <= `SD next_map_table;
    end // if (f_d_enable)
  end // always

  always_comb begin
    next_map_table = map_table;
    if (map_table_packet_in.Dispatch_enable && en) begin       // no dispatch hazard
      next_map_table[map_table_packet_in.Dispatch_reg_dest] = '{map_table_packet_in.Freelist_T, `FALSE}; 
                                                             //renew maptable from freelist but not ready yet
    end
    if (map_table_packet_in.CDB_enable && en) begin
      // genvar i;
      for ( int i=0; i< `NUM_MAP_TABLE;i++) begin  
        if (map_table[i].PR_idx == map_table_packet_in.CDB_T) begin              // if CDB_T is the same as maptable value
          next_map_table[i].T_PLUS_STATUS = `TRUE;           // The Tag in maptable change to ready
          break;
        end
      end
    end
  end

  assign map_table_packet_out.Told_to_ROB = map_table[map_table_packet_in.Dispatch_reg_dest].PR_idx;
  assign map_table_packet_out.T1_to_RS    = map_table[map_table_packet_in.Dispatch_reg_T1];
  assign map_table_packet_out.T2_to_RS    = map_table[map_table_packet_in.Dispatch_reg_T2];
endmodule