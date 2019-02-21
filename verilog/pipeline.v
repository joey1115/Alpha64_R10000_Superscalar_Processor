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
  output logic [63:0] pipeline_commit_NPC,
  // testing hooks (these must be exported so we can test
  // the synthesized version) data is tested by looking at
  // the final values in memory
  // Outputs from IF-Stage 
  output logic [63:0] if_NPC_out,
  output logic [31:0] if_IR_out,
  output logic        if_valid_inst_out,
  // Outputs from IF/ID Pipeline Register
  output logic [63:0] if_id_NPC,
  output logic [31:0] if_id_IR,
  output logic        if_id_valid_inst,
  // Outputs from ID/EX Pipeline Register
  output logic [63:0] id_ex_NPC,
  output logic [31:0] id_ex_IR,
  output logic        id_ex_valid_inst,
  // Outputs from EX/MEM Pipeline Register
  output logic [63:0] ex_mem_NPC,
  output logic [31:0] ex_mem_IR,
  output logic        ex_mem_valid_inst,
  // Outputs from MEM/WB Pipeline Register
  output logic [63:0] mem_wb_NPC,
  output logic [31:0] mem_wb_IR,
  output logic        mem_wb_valid_inst
);

  // Pipeline register enables
  logic   f_d_enable, s_x_enable, x_c_enable, c_r_enable;

  // Outputs from IF stage
  F_D_PACKET f_packet_out;
  // Outputs from ID/EX Pipeline Register
  F_D_PACKET f_d_packet;

  // Outputs from IF stage
  D_S_PACKET d_packet_out;
  // Outputs from ID/EX Pipeline Register
  D_S_PACKET d_s_packet;

  // Outputs from ID stage
  S_X_PACKET s_packet_out;
  // Outputs from ID/EX Pipeline Register
  S_X_PACKET s_x_packet;

  // Outputs from EX-Stage
  X_C_PACKET x_packet_out;
  // Outputs from EX/MEM Pipeline Register
  X_C_PACKET x_c_packet;

  // Outputs from MEM-Stage
  C_R_PACKET c_packet_out;
  // Outputs from MEM/WB Pipeline Register
  C_R_PACKET c_r_packet;

  // Outputs from WB-Stage  (These loop back to the register file in ID)
  R_REG_PACKET r_packet_out;

  // Memory interface/arbiter wires
  logic [63:0] proc2Dmem_addr, proc2Imem_addr;
  logic  [1:0] proc2Dmem_command, proc2Imem_command;
  logic  [3:0] Imem2proc_response, Dmem2proc_response;

  // Icache wires
  logic [63:0] cachemem_data;
  logic        cachemem_valid;
  logic  [4:0] Icache_rd_idx;
  logic  [7:0] Icache_rd_tag;
  logic  [4:0] Icache_wr_idx;
  logic  [7:0] Icache_wr_tag;
  logic        Icache_wr_en;
  logic [63:0] Icache_data_out, proc2Icache_addr;
  logic        Icache_valid_out;

  assign pipeline_completed_insts = {3'b0, c_r_packet.valid};
  assign pipeline_error_status    = c_r_packet.illegal  ? HALTED_ON_ILLEGAL :
                                    c_r_packet.halt     ? HALTED_ON_HALT :
                                    NO_ERROR;

  assign pipeline_commit_wr_idx  = r_packet_out.wr_idx;
  assign pipeline_commit_wr_data = r_packet_out.wr_data;
  assign pipeline_commit_wr_en   = r_packet_out.wr_en;
  assign pipeline_commit_NPC     = mem_wb_NPC;

  assign proc2mem_command   = (proc2Dmem_command == BUS_NONE) ? proc2Imem_command:proc2Dmem_command;
  assign proc2mem_addr      = (proc2Dmem_command == BUS_NONE) ? proc2Imem_addr:proc2Dmem_addr;
  assign Dmem2proc_response = (proc2Dmem_command == BUS_NONE) ? 0 : mem2proc_response;
  assign Imem2proc_response = (proc2Dmem_command == BUS_NONE) ? mem2proc_response : 0;

  // Actual cache (data and tag RAMs)
  cache cachememory (// inputs
    .clock(clock),
    .reset(reset),
    .wr1_en(Icache_wr_en),
    .wr1_idx(Icache_wr_idx),
    .wr1_tag(Icache_wr_tag),
    .wr1_data(mem2proc_data),
    .rd1_idx(Icache_rd_idx),
    .rd1_tag(Icache_rd_tag),
    // outputs
    .rd1_data(cachemem_data),
    .rd1_valid(cachemem_valid)
  );
  // Cache controller
  icache icache_0(// inputs 
    .clock(clock),
    .reset(reset),
    .Imem2proc_response(Imem2proc_response),
    .Imem2proc_data(mem2proc_data),
    .Imem2proc_tag(mem2proc_tag),
    .proc2Icache_addr(proc2Icache_addr),
    .cachemem_data(cachemem_data),
    .cachemem_valid(cachemem_valid),
    // outputs
    .proc2Imem_command(proc2Imem_command),
    .proc2Imem_addr(proc2Imem_addr),
    .Icache_data_out(Icache_data_out),
    .Icache_valid_out(Icache_valid_out),
    .current_index(Icache_rd_idx),
    .current_tag(Icache_rd_tag),
    .last_index(Icache_wr_idx),
    .last_tag(Icache_wr_tag),
    .data_write_enable(Icache_wr_en)
  );
  //////////////////////////////////////////////////
  //                                              //
  //                  F-Stage                     //
  //                                              //
  //////////////////////////////////////////////////
  assign if_NPC_out = f_packet_out.NPC;
  assign if_IR_out = f_packet_out.inst;
  assign if_valid_inst_out = f_packet_out.valid;
  if_stage if_stage_0 (
    // Inputs
    .clock (clock),
    .reset (reset),
    .c_r_packet_in(c_r_packet),
    .x_c_packet_in(x_c_packet),
    .Imem2proc_data(Icache_data_out),
    .Imem_valid(Icache_valid_out),
    // Outputs
    .proc2Imem_addr(proc2Icache_addr),
    .f_packet_out(f_packet_out)
  );
  //////////////////////////////////////////////////
  //                                              //
  //            F/D Pipeline Register             //
  //                                              //
  //////////////////////////////////////////////////
  assign if_id_NPC        = f_d_packet.NPC;
  assign if_id_IR         = f_d_packet.inst;
  assign if_id_valid_inst = f_d_packet.valid;
  assign f_d_enable = 1'b1; // always enabled
  // synopsys sync_set_reset "reset"
  always_ff @(posedge clock) begin
    if(reset) begin
      f_d_packet <= `SD `F_D_PACKET_RESET;
    end else if (f_d_enable) begin
      f_d_packet <= `SD f_packet_out; 
    end // if (f_d_enable)
  end // always
  //////////////////////////////////////////////////
  //                                              //
  //                  D-Stage                     //
  //                                              //
  //////////////////////////////////////////////////
  id_stage id_stage_0 (// Inputs
    .clock(clock),
    .reset(reset),
    .f_d_packet_in(f_d_packet),
    .r_packet_in(r_packet_out),

    // Outputs
    .s_packet_out(s_packet_out)
  );
  // Note: Decode signals for load-lock/store-conditional and "get CPU ID"
  //  instructions (id_{ldl,stc}_mem_out, id_cpuid_out) are not connected
  //  to anything because the provided EX and MEM stages do not implement
  //  these instructions.  You will have to implement these instructions
  //  if you plan to do a multicore project.
  //////////////////////////////////////////////////
  //                                              //
  //            D/S Pipeline Register             //
  //                                              //
  //////////////////////////////////////////////////
  assign id_ex_NPC        = s_x_packet.NPC;
  assign id_ex_IR         = s_x_packet.inst;
  assign id_ex_valid_inst = s_x_packet.valid;
  assign s_x_enable = 1'b1; // always enabled
  // synopsys sync_set_reset "reset"
  always_ff @(posedge clock) begin
    if (reset) begin
      s_x_packet <= `SD `ID_EX_PACKET_RESET; 
    end else if (s_x_enable) begin
      s_x_packet <= `SD s_packet_out;
    end // else: !if(reset)
  end // always
  //////////////////////////////////////////////////
  //                                              //
  //                  S-Stage                     //
  //                                              //
  //////////////////////////////////////////////////
  id_stage id_stage_0 (// Inputs
    .clock(clock),
    .reset(reset),
    .f_d_packet_in(f_d_packet),
    .r_packet_in(r_packet_out),

    // Outputs
    .s_packet_out(s_packet_out)
  );
  // Note: Decode signals for load-lock/store-conditional and "get CPU ID"
  //  instructions (id_{ldl,stc}_mem_out, id_cpuid_out) are not connected
  //  to anything because the provided EX and MEM stages do not implement
  //  these instructions.  You will have to implement these instructions
  //  if you plan to do a multicore project.
  //////////////////////////////////////////////////
  //                                              //
  //              S/X Pipeline Register           //
  //                                              //
  //////////////////////////////////////////////////
  assign id_ex_NPC        = s_x_packet.NPC;
  assign id_ex_IR         = s_x_packet.inst;
  assign id_ex_valid_inst = s_x_packet.valid;
  assign s_x_enable = 1'b1; // always enabled
  // synopsys sync_set_reset "reset"
  always_ff @(posedge clock) begin
    if (reset) begin
      s_x_packet <= `SD `ID_EX_PACKET_RESET; 
    end else if (s_x_enable) begin
      s_x_packet <= `SD s_packet_out;
    end // else: !if(reset)
  end // always
  //////////////////////////////////////////////////
  //                                              //
  //                  X-Stage                     //
  //                                              //
  //////////////////////////////////////////////////
  ex_stage ex_stage_0 (
    // Inputs
    .clock(clock),
    .reset(reset),
    .s_x_packet_in(s_x_packet),
    // Outputs
    .x_packet_out(x_packet_out)
  );
  //////////////////////////////////////////////////
  //                                              //
  //           X/MEM Pipeline Register            //
  //                                              //
  //////////////////////////////////////////////////
  assign ex_mem_NPC = x_c_packet.NPC;
  assign ex_mem_IR = x_c_packet.inst;
  assign ex_mem_valid_inst = x_c_packet.valid;
  assign x_c_enable = ~c_packet_out.stall;
  // synopsys sync_set_reset "reset"
  always_ff @(posedge clock) begin
    if (reset) begin
      x_c_packet <= `SD `EX_MEM_PACKET_RESET;
    end else if (x_c_enable) begin
      // these are forwarded directly from ID/EX latches
      x_c_packet <= `SD x_packet_out;
    end // else: !if(reset)
  end // always
  //////////////////////////////////////////////////
  //                                              //
  //                 MEM-Stage                    //
  //                                              //
  //////////////////////////////////////////////////
  mem_stage mem_stage_0 (// Inputs
    .clock(clock),
    .reset(reset),
    .x_c_packet_in(x_c_packet),
    .Dmem2proc_data(mem2proc_data),
    .Dmem2proc_tag(mem2proc_tag),
    .Dmem2proc_response(Dmem2proc_response),
     // Outputs
    .c_packet_out(c_packet_out),
    .proc2Dmem_command(proc2Dmem_command),
    .proc2Dmem_addr(proc2Dmem_addr),
    .proc2Dmem_data(proc2mem_data)
  );
  //////////////////////////////////////////////////
  //                                              //
  //           MEM/WB Pipeline Register           //
  //                                              //
  //////////////////////////////////////////////////
  assign mem_wb_NPC        = c_r_packet.NPC;
  assign mem_wb_IR         = c_r_packet.inst;
  assign mem_wb_valid_inst = c_r_packet.valid;
  assign c_r_enable = 1'b1; // always enabled
  // synopsys sync_set_reset "reset"
  always_ff @(posedge clock) begin
    if (reset) begin
      c_r_packet <= `SD `MEM_WB_PACKET_RESET;
    end else if (c_r_enable) begin
      // these are forwarded directly from EX/MEM latches
      c_r_packet <= `SD c_packet_out;
    end // else: !if(reset)
  end // always
  //////////////////////////////////////////////////
  //                                              //
  //                  WB-Stage                    //
  //                                              //
  //////////////////////////////////////////////////
  wb_stage wb_stage_0 (
    // Inputs
    .clock(clock),
    .reset(reset),
    .c_r_packet_in(c_r_packet),
    // Outputs
    .r_packet_out(r_packet_out)
  );
endmodule  // module verisimple
