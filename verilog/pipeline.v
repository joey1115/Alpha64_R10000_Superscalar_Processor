/////////////////////////////////////////////////////////////////////////
//                                                                     //
//   Modulename :  pipeline.v                                          //
//                                                                     //
//  Description :  Top-level module of the verisimple pipeline;        //
//                 This instantiates and connects the 5 stages of the  //
//                 Verisimple pipeline togeather.                      //
//                                                                     //
//                                                                     //
/////////////////////////////////////////////////////////////////////////

`timescale 1ns/100ps

module pipeline (
  input         clock,                    // System clock
  input         reset,                    // System reset
  input [3:0]   mem2proc_response,        // Tag from memory about current request
  input [63:0]  mem2proc_data,            // Data coming back from memory
  input [3:0]   mem2proc_tag,              // Tag from memory about current reply
  output logic [1:0]  proc2mem_command,    // command sent to memory
  output logic [63:0] proc2mem_addr,      // Address sent to memory
  output logic [63:0] proc2mem_data,      // Data sent to memory
  output logic [3:0]  pipeline_completed_insts,
  output ERROR_CODE   pipeline_error_status,
  output logic [4:0]  pipeline_commit_wr_idx,
  output logic [63:0] pipeline_commit_wr_data,
  output logic        pipeline_commit_wr_en,
  output logic [63:0] pipeline_commit_NPC
);
  logic                                          en;
  logic                                          write_en;
  logic                                          complete_en;
  logic                   [`NUM_FU-1:0]          CDB_valid;
  CDB_ROB_OUT_t                                  CDB_ROB_out;
  CDB_RS_OUT_t                                   CDB_RS_out;
  CDB_MAP_TABLE_OUT_t                            CDB_Map_Table_out;
  CDB_PR_OUT_t                                   CDB_PR_out;
  DECODER_ROB_OUT_t                              decoder_ROB_out;
  DECODER_RS_OUT_t                               decoder_RS_out;
  DECODER_FL_OUT_t                               decoder_FL_out;
  DECODER_MAP_TABLE_OUT_t                        decoder_Map_Table_out;
  logic                                          FL_valid;
  FL_ROB_OUT_t                                   FL_ROB_out;
  FL_RS_OUT_t                                    FL_RS_out;
  FL_MAP_TABLE_OUT_t                             FL_Map_Table_out;
  logic                   [`NUM_FU-1:0]          FU_valid;
  logic                                          rollback_en;
  logic                   [$clog2(`NUM_FL)-1:0]  FL_rollback_idx;
  logic                   [$clog2(`NUM_ROB)-1:0] ROB_rollback_idx;
  logic                   [$clog2(`NUM_ROB)-1:0] diff_ROB;
  FU_CDB_OUT_t                                   FU_CDB_out;
  MAP_TABLE_ROB_OUT_t                            Map_Table_ROB_out;
  MAP_TABLE_RS_OUT_t                             Map_Table_RS_out;
  PR_FU_OUT_t                                    PR_FU_out;
  logic                                          ROB_valid;
  logic                                          retire_en;
  logic                                          halt_out;
  logic                   [$clog2(`NUM_ROB)-1:0] ROB_idx;
  ROB_ARCH_MAP_OUT_t                             ROB_Arch_Map_out;
  ROB_FL_OUT_t                                   ROB_FL_out;
  logic                                          RS_valid;
  RS_FU_OUT_t                                    RS_FU_out;
  RS_PR_OUT_t                                    RS_PR_out;
`ifndef SYNTH_TEST
  logic       [31:0][$clog2(`NUM_PR)-1:0]                                 next_arch_map;
  CDB_entry_t [`NUM_FU-1:0]                                               CDB;
  logic       [`NUM_FL-1:0][$clog2(`NUM_PR)-1:0]                          FL_table, next_FL_table;
  logic       [$clog2(`NUM_FL)-1:0]                                       head, next_head;
  logic       [$clog2(`NUM_FL)-1:0]                                       tail, next_tail;
  logic       [`NUM_MULT-1:0]                                             last_done;
  logic       [`NUM_MULT-1:0][63:0]                                       product_out;
  logic       [`NUM_MULT-1:0][4:0]                                        last_dest_idx;
  logic       [`NUM_MULT-1:0][$clog2(`NUM_PR)-1:0]                        last_T_idx;
  logic       [`NUM_MULT-1:0][$clog2(`NUM_ROB)-1:0]                       last_ROB_idx;
  logic       [`NUM_MULT-1:0][$clog2(`NUM_FL)-1:0]                        last_FL_idx;
  logic       [`NUM_MULT-1:0][63:0]                                       T1_value;
  logic       [`NUM_MULT-1:0][63:0]                                       T2_value;
  logic       [`NUM_MULT-1:0][((`NUM_MULT_STAGE-1)*64)-1:0]               internal_T1_values;
  logic       [`NUM_MULT-1:0][((`NUM_MULT_STAGE-1)*64)-1:0]               internal_T2_values;
  logic       [`NUM_MULT-1:0][`NUM_MULT_STAGE-2:0]                        internal_valids;
  logic       [`NUM_MULT-1:0][`NUM_MULT_STAGE-3:0]                        internal_dones;
  logic       [`NUM_MULT-1:0][5*(`NUM_MULT_STAGE-2)-1:0]                  internal_dest_idx;
  logic       [`NUM_MULT-1:0][($clog2(`NUM_PR)*(`NUM_MULT_STAGE-2))-1:0]  internal_T_idx;
  logic       [`NUM_MULT-1:0][($clog2(`NUM_ROB)*(`NUM_MULT_STAGE-2))-1:0] internal_ROB_idx;
  logic       [`NUM_MULT-1:0][($clog2(`NUM_FL)*(`NUM_MULT_STAGE-2))-1:0]  internal_FL_idx;
  T_t         [31:0]                                                      map_table_out;
  logic       [`NUM_PR-1:0][63:0]                                         pr_data;
  ROB_t                                                                   rob;
  RS_ENTRY_t  [`NUM_FU-1:0]                                               RS_out;
  logic       [`NUM_FU-1:0]                                               RS_match_hit;
  logic       [$clog2(`NUM_FU)-1:0]                                       RS_match_idx;
`endif
  assign en = `TRUE;
  
  Arch_Map arch_map_0 (
    .en(en),
    .clock(clock),
    .reset(reset),
    .retire_en(retire_en),
`ifdef SYNTH_TEST
    .ROB_Arch_Map_out(ROB_Arch_Map_out)
`else
    .ROB_Arch_Map_out(ROB_Arch_Map_out),
    .next_arch_map(next_arch_map)
`endif
  );

  CDB cdb_0 (
    .en(en),
    .clock(clock),
    .reset(reset),
    .rollback_en(rollback_en),
    .ROB_rollback_idx(ROB_rollback_idx),
    .diff_ROB(diff_ROB),
    .FU_CDB_out(FU_CDB_out),
`ifndef SYNTH_TEST
    .CDB(CDB),
`endif
    .write_en(write_en),
    .complete_en(complete_en),
    .CDB_valid(CDB_valid),
    .CDB_ROB_out(CDB_ROB_out),
    .CDB_RS_out(CDB_RS_out),
    .CDB_Map_Table_out(CDB_Map_Table_out),
    .CDB_PR_out(CDB_PR_out)
  );

  decoder decoder_0 (
    .decoder_packet_in(decoder_packet_in),
    .decoder_ROB_out(decoder_ROB_out),
    .decoder_RS_out(decoder_RS_out),
    .decoder_FL_out(decoder_FL_out),
    .decoder_Map_Table_out(decoder_Map_Table_out)
  );

  FL fl_0 (
    .clock(clock),
    .reset(reset),
    .dispatch_en(dispatch_en),
    .rollback_en(rollback_en),
    .retire_en(retire_en),
    .FL_rollback_idx(FL_rollback_idx),
    .decoder_FL_out(decoder_FL_out),
    .ROB_FL_out(ROB_FL_out),
`ifndef SYNTH_TEST
    .FL_table(FL_table),
    .next_FL_table(next_FL_table),
    .head(head),
    .next_head(next_head),
    .tail(tail),
    .next_tail(next_tail),
`endif
    .FL_valid(FL_valid),
    .FL_ROB_out(FL_ROB_out),
    .FL_RS_out(FL_RS_out),
    .FL_Map_Table_out(FL_Map_Table_out)
  );

  FU fu_0 (
    .clock(clock),
    .reset(reset),
    .ROB_idx(ROB_idx),
    .CDB_valid(CDB_valid),
    .RS_FU_out(RS_FU_out),
    .PR_FU_out(PR_FU_out),
`ifndef SYNTH_TEST
    .last_done(last_done),
    .product_out(product_out),
    .last_dest_idx(last_dest_idx),
    .last_T_idx(last_T_idx),
    .last_ROB_idx(last_ROB_idx),
    .last_FL_idx(last_FL_idx),
    .T1_value(T1_value),
    .T2_value(T2_value),
    .internal_T1_values(internal_T1_values),
    .internal_T2_values(internal_T2_values),
    .internal_valids(internal_valids),
    .internal_dones(internal_dones),
    .internal_dest_idx(internal_dest_idx),
    .internal_T_idx(internal_T_idx),
    .internal_ROB_idx(internal_ROB_idx),
    .internal_FL_idx(internal_FL_idx),
`endif
    .FU_valid(FU_valid),
    .rollback_en(rollback_en),
    .ROB_rollback_idx(ROB_rollback_idx),
    .FL_rollback_idx(FL_rollback_idx),
    .diff_ROB(diff_ROB),
    .FU_CDB_out(FU_CDB_out)
  );

  Map_Table map_table_0 (
    .en(en),
    .clock(clock),
    .reset(reset),
    .dispatch_en(dispatch_en),
    .rollback_en(rollback_en),
    .complete_en(complete_en),
    .ROB_rollback_idx(ROB_rollback_idx),
    .ROB_idx(ROB_idx),
    .decoder_Map_Table_out(decoder_Map_Table_out),
    .FL_Map_Table_out(FL_Map_Table_out),
    .CDB_Map_Table_out(CDB_Map_Table_out),
`ifndef SYNTH_TEST
    .map_table_out(map_table_out),
`endif
    .Map_Table_ROB_out(Map_Table_ROB_out),
    .Map_Table_RS_out(Map_Table_RS_out)
  );

  PR pr_0 (
    .en(en),
    .clock(clock),
    .reset(reset),
    .write_en(write_en),
    .CDB_PR_out(CDB_PR_out),
    .RS_PR_out(RS_PR_out),
`ifndef SYNTH_TEST
    .pr_data(pr_data),
`endif
    .PR_FU_out(PR_FU_out)
  );

  ROB rob_0 (
    .en(en),
    .clock(clock),
    .reset(reset),
    .dispatch_en(dispatch_en),
    .complete_en(complete_en),
    .rollback_en(rollback_en),
    .ROB_rollback_idx(ROB_rollback_idx),
    .decoder_ROB_out(decoder_ROB_out),
    .FL_ROB_out(FL_ROB_out),
    .Map_Table_ROB_out(Map_Table_ROB_out),
    .CDB_ROB_out(CDB_ROB_out),
`ifndef SYNTH_TEST
    .rob(rob),
`endif
    .ROB_valid(ROB_valid),
    .retire_en(retire_en),
    .halt_out(halt_out),
    .ROB_idx(ROB_idx),
    .ROB_Arch_Map_out(ROB_Arch_Map_out),
    .ROB_FL_out(ROB_FL_out)
  );

  RS rs_0 (
    .clock(clock),
    .reset(reset),
    .en(en),
    .complete_en(complete_en),
    .dispatch_en(dispatch_en),
    .rollback_en(rollback_en),
    .FU_valid(FU_valid),
    .ROB_rollback_idx(ROB_rollback_idx),
    .diff_ROB(diff_ROB),
    .ROB_idx(ROB_idx),
    .decoder_RS_out(decoder_RS_out),
    .FL_RS_out(FL_RS_out),
    .Map_Table_RS_out(Map_Table_RS_out),
    .CDB_RS_out(CDB_RS_out),
`ifndef SYNTH_TEST
    .RS_out(RS_out),
    .RS_match_hit(RS_match_hit),   // If a RS entry is ready
    .RS_match_idx(RS_match_idx),
`endif
    .RS_valid(RS_valid),
    .RS_FU_out(RS_FU_out),
    .RS_PR_out(RS_PR_out)
  );

  //////////////////////////////////////////////////
  //                                              //
  //            F/D Pipeline Register             //
  //                                              //
  //////////////////////////////////////////////////
  // assign f_d_enable = `TRUE; // always enabled
  // // synopsys sync_set_reset "reset"
  // always_ff @(posedge clock) begin
  //   if(reset) begin
  //     decoder_packet_in <= `SD `DECODER_PACKET_IN_RESET;
  //   end else if (f_d_enable) begin
  //     decoder_packet_in <= `SD f_d_packet_out;
  //   end // if (f_d_enable)
  // end // always
endmodule  // module verisimple
