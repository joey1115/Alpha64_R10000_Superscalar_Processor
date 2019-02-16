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
    input  [63:0] ex_mem_rega,        // regA value from reg file (store data)
    input  [63:0] ex_mem_alu_result,  // incoming ALU result from EX
    input         ex_mem_rd_mem,      // read memory? (from decoder)
    input         ex_mem_wr_mem,      // write memory? (from decoder)
    input  [63:0] Dmem2proc_data,
    input   [3:0] Dmem2proc_tag, Dmem2proc_response,

    output [63:0] mem_result_out,      // outgoing instruction result (to MEM/WB)
    output        mem_stall_out,
    output [1:0] proc2Dmem_command,
    output [63:0] proc2Dmem_addr,      // Address sent to data-memory
    output [63:0] proc2Dmem_data      // Data sent to data-memory
                );

  logic [3:0] mem_waiting_tag;

  // Determine the command that must be sent to mem
  assign proc2Dmem_command =  (mem_waiting_tag != 0) ?  BUS_NONE :
                              ex_mem_wr_mem  ? BUS_STORE :
                              ex_mem_rd_mem  ? BUS_LOAD :
                              BUS_NONE;

  // The memory address is calculated by the ALU
  assign proc2Dmem_data = ex_mem_rega;

  assign proc2Dmem_addr = ex_mem_alu_result;

  // Assign the result-out for next stage
  assign mem_result_out = (ex_mem_rd_mem) ? Dmem2proc_data : ex_mem_alu_result;

  assign mem_stall_out =  (ex_mem_rd_mem && ((mem_waiting_tag!=Dmem2proc_tag) || (Dmem2proc_tag==0))) |
              (ex_mem_wr_mem && (Dmem2proc_response==0));

  wire write_enable =  ex_mem_rd_mem && 
            ((mem_waiting_tag==0) || (mem_waiting_tag==Dmem2proc_tag));

  // synopsys sync_set_reset "reset"
  always_ff @(posedge clock)
    if(reset)
      mem_waiting_tag <= `SD 0;
    else if(write_enable)
      mem_waiting_tag <= `SD Dmem2proc_response;

endmodule // module mem_stage
