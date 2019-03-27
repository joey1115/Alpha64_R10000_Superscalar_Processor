/**********************************************************
 * MapTable Procedure
 * 
 * --- Complete ---
 * 1. Update ready bit from CDB
 * input: CDB_T; complete_en from CDB
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
  input  logic                                          en, clock, reset, dispatch_en, rollback_en, complete_en,
  input  logic                   [$clog2(`NUM_ROB)-1:0] ROB_rollback_idx,
  input  logic                   [$clog2(`NUM_ROB)-1:0] ROB_idx,
  input  DECODER_MAP_TABLE_OUT_t                        decoder_Map_Table_out,
  input  FL_MAP_TABLE_OUT_t                             FL_Map_Table_out,
  input  CDB_MAP_TABLE_OUT_t                            CDB_Map_Table_out,
`ifndef SYNTH_TEST
  output T_t                     [31:0]                 map_table_out,
`endif
  output MAP_TABLE_ROB_OUT_t                            Map_Table_ROB_out,
  output MAP_TABLE_RS_OUT_t                             Map_Table_RS_out
);

  T_t                         T1, T2;
  T_t [31:0]                  map_table, next_map_table;
  T_t [`NUM_ROB-1:0][31:0]    backup_map_table, next_backup_map_table;
  logic [$clog2(`NUM_PR)-1:0] Told_idx;       // output Told to ROB

  assign Map_Table_ROB_out = '{Told_idx};
  assign Map_Table_RS_out  = '{T1, T2};

`ifndef SYNTH_TEST
  assign map_table_out = map_table;
`endif
  assign Told_idx = map_table[decoder_Map_Table_out.dest_idx].idx;
  assign T1.idx   = map_table[decoder_Map_Table_out.rega_idx].idx;
  assign T2.idx   = map_table[decoder_Map_Table_out.regb_idx].idx;
  assign T1.ready = ( complete_en && T1.idx == CDB_Map_Table_out.T_idx ) || map_table[decoder_Map_Table_out.rega_idx].ready;
  assign T2.ready = ( complete_en && T2.idx == CDB_Map_Table_out.T_idx ) || map_table[decoder_Map_Table_out.rega_idx].ready;

  always_comb begin
    next_map_table = map_table;
    // Rollback
    if (rollback_en) begin
      next_map_table = backup_map_table[ROB_rollback_idx];
    end
    // if (map_table_packet_in.rollback_en) begin
    //   for (logic [$clog2(`NUM_ROB)-1:0] i = ROB_idx; i != ROB_rollback_idx; i--) begin
    //     next_map_table[decoder_Map_Table_out.dest_idx[i]] = {Told_idx[i], `TRUE};
    //   end
    //   for (logic [$clog2(`NUM_ROB)-1:0] i = ROB_head_idx; i != ROB_rollback_idx - 1; i++) begin
    //     if (next_map_table[decoder_Map_Table_out.dest_idx[i]] == T_idx[i] && !Complete) begin
    //       next_map_table[decoder_Map_Table_out.dest_idx[i]].ready = `FALSE;
    //     end
    //   end
    // end
    // CDB_T updata ready
    // if ( complete_en ) begin
    //   for (int i = 0; i < 32; i++) begin
    //     if ( map_table[i].idx == CDB_Map_Table_out.T_idx ) begin
    //       map_table[i].ready = `TRUE;
    //     end
    //   end
    // end
    if ( complete_en && map_table[CDB_Map_Table_out.dest_idx].idx == CDB_Map_Table_out.T_idx ) begin
      next_map_table[CDB_Map_Table_out.dest_idx].ready = `TRUE;
    end
    // PR update T_idx
    if ( dispatch_en ) begin // no dispatch hazard
      next_map_table[decoder_Map_Table_out.dest_idx] = '{FL_Map_Table_out.T_idx, `FALSE}; // renew maptable from freelist but not ready yet
      next_map_table[31].ready                       = `TRUE;                                // Force ZERO_REG to be rady
    end
  end

  always_comb begin
    next_backup_map_table = backup_map_table;
    if ( dispatch_en ) begin                                // no dispatch hazard
      next_backup_map_table[ROB_idx] = next_map_table; // backup the map
      for (int i=0; i<32;i++) begin
        next_backup_map_table[ROB_idx][i].ready = `TRUE;   // ready all the bit
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
