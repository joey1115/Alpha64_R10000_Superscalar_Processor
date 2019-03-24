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

  Arch_Map arch_map_0 (
    .en(en),
    .clock(clock),
    .reset(reset),
    .retire_en(retire_en),
    .arch_map_packet_in(arch_map_packet_in),
`ifndef SYNTH_TEST
    .next_arch_map(next_arch_map)
`endif
  );

  CDB cdb_0 (
    .en(en),
    .cdb_packet_in(cdb_packet_in),
    .cdb_packet_out(cdb_packet_out)
  );

  decoder decoder_0 (
    .decoder_packet_in(decoder_packet_in),
    .decoder_packet_out(decoder_packet_out)
  );

  FL fl_0 (
    .clock(clock),
    .reset(reset),
    .dispatch_en(dispatch_en),
    .rollback_en(rollback_en),
    .retire_en(retire_en),
    .dest_idx(decoder_packet_out.dest_idx),
    .Told_idx(Told_idx),
    .FL_rollback_idx(FL_rollback_idx),
`ifndef SYNTH_TEST
    .FL_table(FL_table),
    .next_FL_table(next_FL_table),
    .head(head),
    .next_head(next_head),
    .tail(tail),
    .next_tail(next_tail),
`endif
    .FL_valid(FL_valid),
    .T_idx(T_idx),
    .FL_idx(FL_idx)
  );

  FU fu_0 (
    .clock(clock),
    .reset(reset),
    .fu_m_packet_in(fu_m_packet_in),
    .CDB_valid(CDB_valid),
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
    .fu_m_packet_out(fu_m_packet_out),
    .fu_valid(fu_valid),
    .rollback_en(rollback_en),
    .ROB_rollback_idx(ROB_rollback_idx),
    .diff_ROB(diff_ROB)
  );

  Map_Table map_table_0 (
    .en(en),
    .clock(clock),
    .reset(reset),
    .map_table_packet_in(map_table_packet_in),
`ifndef SYNTH_TEST
    .map_table_out(map_table_out),
`endif
    .map_table_packet_out(map_table_packet_out)
  );

  PR pr_0 (
    .en(en),
    .clock(clock),
    .reset(reset),
    .pr_packet_in(pr_packet_in),
`ifndef SYNTH_TEST
    .pr_data(pr_data),
`endif
    .pr_packet_out(pr_packet_out)
  );

  ROB rob_0 (
    .en(en),
    .clock(clock),
    .reset(reset),
    .dispatch_en(dispatch_en),
    .halt(decoder_packet_out.halt),
    .dest_idx(decoder_packet_out.dest_idx),
    .T_idx(T_idx),
    .Told_idx(Told_idx),
    .ROB_rollback_idx(ROB_rollback_idx),
    .rollback_en(rollback_en),
    .rob_packet_complete_in(rob_packet_complete_in),
`ifndef SYNTH_TEST
    .rob(rob),
`endif
    .ROB_valid(ROB_valid),
    .retire_en(retire_en),
    .halt_out(halt_out),
    .rob_packet_rs_out(rob_packet_rs_out),
    .rob_packet_maptable_out(rob_packet_maptable_out),
    .rob_packet_freelist_out(rob_packet_freelist_out),
    .rob_packet_archmap_out(rob_packet_archmap_out)
  );

  RS rs_0 (
    .clock(clock),
    .reset(reset),
    .en(en),
    .decoder_packet_out(decoder_packet_out),
    .rs_packet_in(rs_packet_in),
`ifndef SYNTH_TEST
    .RS_out(RS_out),
    .RS_match_hit(RS_match_hit),   // If a RS entry is ready
    .RS_match_idx(RS_match_idx),
`ifdef RS_FORWARDING
    .FU_forward_hit(FU_forward_hit), // If a RS entry is ready
    .FU_forward_idx(FU_forward_idx), // If a RS entry is ready
`endif
`endif
    .rs_packet_out(rs_packet_out),
    .RS_valid(RS_valid)
  );

  //////////////////////////////////////////////////
  //                                              //
  //            F/D Pipeline Register             //
  //                                              //
  //////////////////////////////////////////////////
  assign f_d_enable = `TRUE; // always enabled
  // synopsys sync_set_reset "reset"
  always_ff @(posedge clock) begin
    if(reset) begin
      decoder_packet_in <= `SD DECODER_PACKET_IN_RESET;
    end else if (f_d_enable) begin
      decoder_packet_in <= `SD f_d_packet_out;
    end // if (f_d_enable)
  end // always
  //////////////////////////////////////////////////
  //                                              //
  //            D/S Pipeline Register             //
  //                                              //
  //////////////////////////////////////////////////
  assign s_x_enable = `TRUE; // always enabled
  // synopsys sync_set_reset "reset"
  always_ff @(posedge clock) begin
    if (reset) begin
      s_x_packet <= `SD `S_X_PACKET_RESET; 
    end else if (s_x_enable) begin
      s_x_packet <= `SD s_packet_out;
    end // else: !if(reset)
  end // always
  //////////////////////////////////////////////////
  //                                              //
  //              S/X Pipeline Register           //
  //                                              //
  //////////////////////////////////////////////////
  assign s_x_enable = `TRUE; // always enabled
  // synopsys sync_set_reset "reset"
  always_ff @(posedge clock) begin
    if (reset) begin
      s_x_packet <= `SD `S_X_PACKET_RESET; 
    end else if (s_x_enable) begin
      s_x_packet <= `SD s_packet_out;
    end // else: !if(reset)
  end // always
  //////////////////////////////////////////////////
  //                                              //
  //           X/C Pipeline Register              //
  //                                              //
  //////////////////////////////////////////////////
  assign x_c_enable = `TRUE;
  // synopsys sync_set_reset "reset"
  always_ff @(posedge clock) begin
    if (reset) begin
      x_c_packet <= `SD `X_C_PACKET_RESET;
    end else if (x_c_enable) begin
      // these are forwarded directly from ID/EX latches
      x_c_packet <= `SD x_packet_out;
    end // else: !if(reset)
  end // always
  //////////////////////////////////////////////////
  //                                              //
  //           C/R Pipeline Register              //
  //                                              //
  //////////////////////////////////////////////////
  assign c_r_enable = `TRUE; // always enabled
  // synopsys sync_set_reset "reset"
  always_ff @(posedge clock) begin
    if (reset) begin
      c_r_packet <= `SD `C_R_PACKET_RESET;
    end else if (c_r_enable) begin
      // these are forwarded directly from EX/MEM latches
      c_r_packet <= `SD c_packet_out;
    end // else: !if(reset)
  end // always
endmodule  // module verisimple
