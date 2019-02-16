/////////////////////////////////////////////////////////////////////////
//                                                                     //
//   Modulename :  if_stage.v                                          //
//                                                                     //
//  Description :  instruction fetch (IF) stage of the pipeline;       // 
//                 fetch instruction, compute next PC location, and    //
//                 send them down the pipeline.                        //
//                                                                     //
//                                                                     //
/////////////////////////////////////////////////////////////////////////

`timescale 1ns/100ps

module if_stage(
    input         clock,                  // system clock
    input         reset,                  // system reset
    input         mem_wb_valid_inst,      // only go to next instruction when true
                                          // makes pipeline behave as single-cycle
    input         ex_mem_take_branch,      // taken-branch signal
    input  [63:0] ex_mem_target_pc,        // target pc: use if take_branch is TRUE
    input  [63:0] Imem2proc_data,          // Data coming back from instruction-memory
    input         Imem_valid,

    output logic [63:0] proc2Imem_addr,    // Address sent to Instruction memory
    output logic [63:0] if_NPC_out,        // PC of instruction after fetched (PC+4).
    output logic [31:0] if_IR_out,        // fetched instruction out
    output logic        if_valid_inst_out  // when low, instruction is garbage
  );


  logic    [63:0] PC_reg;             // PC we are currently fetching
  logic           ready_for_valid;

  logic    [63:0] PC_plus_4;
  logic    [63:0] next_PC;
  logic           PC_enable;
  logic           next_ready_for_valid;

  assign proc2Imem_addr = {PC_reg[63:3], 3'b0};

  // this mux is because the Imem gives us 64 bits not 32 bits
  assign if_IR_out = PC_reg[2] ? Imem2proc_data[63:32] : Imem2proc_data[31:0];

  // default next PC value
  assign PC_plus_4 = PC_reg + 4;

  // next PC is target_pc if there is a taken branch or
  // the next sequential PC (PC+4) if no branch
  // (halting is handled with the enable PC_enable;
  assign next_PC = ex_mem_take_branch ? ex_mem_target_pc : PC_plus_4;

  // The take-branch signal must override stalling (otherwise it may be lost)
  assign PC_enable = if_valid_inst_out || ex_mem_take_branch;

  // Pass PC+4 down pipeline w/instruction
  assign if_NPC_out = PC_plus_4;

  assign if_valid_inst_out = ready_for_valid && Imem_valid;

  assign next_ready_for_valid = (ready_for_valid || mem_wb_valid_inst) && 
                                !if_valid_inst_out;

  // This register holds the PC value
  // synopsys sync_set_reset "reset"
  always_ff @(posedge clock) begin
    if(reset)
      PC_reg <= `SD 0;       // initial PC value is 0
    else if(PC_enable)
      PC_reg <= `SD next_PC; // transition to next PC
  end  // always

  // This FF controls the stall signal that artificially forces
  // fetch to stall until the previous instruction has completed
  // synopsys sync_set_reset "reset"
  always_ff @(posedge clock) begin
    if (reset)
      ready_for_valid <= `SD 1;  // must start with something
    else
      ready_for_valid <= `SD next_ready_for_valid;
  end
  
endmodule  // module if_stage
