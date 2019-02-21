/////////////////////////////////////////////////////////////////////////
//                                                                     //
//   Modulename :  mem_stage.v                                         //
//                                                                     //
//  Description :  memory access (MEM) stage of the pipeline;          //
//                 this stage accesses memory for stores and loads,    // 
//                 and selects the proper next PC value for branches   // 
//                 based on the branch condition computed in the       //
//                 previous stage.                                     // 
//                                                                     //
//                                                                     //
/////////////////////////////////////////////////////////////////////////

`timescale 1ns/100ps

module mem_stage(
  input         clock,              // system clock
  input         reset,              // system reset
  input X_C_PACKET ex_mem_packet_in,
  input  [63:0] Dmem2proc_data,
  input   [3:0] Dmem2proc_tag, Dmem2proc_response,

  output C_R_PACKET c_packet_out,
  output [1:0] proc2Dmem_command,
  output [63:0] proc2Dmem_addr,      // Address sent to data-memory
  output [63:0] proc2Dmem_data      // Data sent to data-memory
);

  logic [3:0] mem_waiting_tag;

  assign c_packet_out.NPC          = ex_mem_packet_in.NPC;
  assign c_packet_out.inst         = ex_mem_packet_in.inst;
  assign c_packet_out.halt         = ex_mem_packet_in.halt;
  assign c_packet_out.illegal      = ex_mem_packet_in.illegal;
  assign c_packet_out.take_branch  = ex_mem_packet_in.take_branch;
  
  assign c_packet_out.dest_reg_idx = c_packet_out.stall ? `ZERO_REG : ex_mem_packet_in.dest_reg_idx;
  assign c_packet_out.valid = ex_mem_packet_in.valid & ~c_packet_out.stall;

  // Determine the command that must be sent to mem
  assign proc2Dmem_command =  (mem_waiting_tag != 0) ?  BUS_NONE :
                              ex_mem_packet_in.wr_mem  ? BUS_STORE :
                              ex_mem_packet_in.rd_mem  ? BUS_LOAD :
                              BUS_NONE;

  // The memory address is calculated by the ALU
  assign proc2Dmem_data = ex_mem_packet_in.rega_value;

  assign proc2Dmem_addr = ex_mem_packet_in.alu_result;

  // Assign the result-out for next stage
  assign c_packet_out.result = (ex_mem_packet_in.rd_mem) ? Dmem2proc_data : ex_mem_packet_in.alu_result;

  assign c_packet_out.stall =  (ex_mem_packet_in.rd_mem && ((mem_waiting_tag!=Dmem2proc_tag) || (Dmem2proc_tag==0))) |
              (ex_mem_packet_in.wr_mem && (Dmem2proc_response==0));

  wire write_enable =  ex_mem_packet_in.rd_mem && 
            ((mem_waiting_tag==0) || (mem_waiting_tag==Dmem2proc_tag));

  // synopsys sync_set_reset "reset"
  always_ff @(posedge clock)
    if(reset)
      mem_waiting_tag <= `SD 0;
    else if(write_enable)
      mem_waiting_tag <= `SD Dmem2proc_response;

endmodule // module mem_stage
