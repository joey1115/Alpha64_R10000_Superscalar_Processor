/////////////////////////////////////////////////////////////////////////
//                                                                     //
//   Modulename :  F_stage.v                                          //
//                                                                     //
//  Description :  instruction fetch (IF) stage of the pipeline;       // 
//                 fetch instruction, compute next PC location, and    //
//                 send them down the pipeline.                        //
//                                                                     //
//                                                                     //
/////////////////////////////////////////////////////////////////////////

`timescale 1ns/100ps

module F_stage(
  input         clock,                      // system clock
  input         reset,                      // system reset
  input         get_next_inst,              // only go to next instruction when true
                                            // makes pipeline behave as single-cycle
  // input         take_branch_out,            // taken-branch signal
  // input  [63:0] take_branch_target,         // target pc: use if take_branch_out is TRUE
  input  [63:0] Imem2proc_data,             // Data coming back from instruction-memory
  input         Imem_valid,
  input  BP_F_OUT_t                   BP_F_out,

  output logic [63:0] proc2Imem_addr, // Address sent to Instruction memory
  output logic [`NUM_SUPER-1:0][63:0] if_NPC_out, // PC of instruction after fetched (PC+4).
  output logic [`NUM_SUPER-1:0][31:0] if_IR_out, // fetched instruction out
  output logic [`NUM_SUPER-1:0][63:0] if_target_out,
  output logic [`NUM_SUPER-1:0]       if_valid_inst_out,    // when low, instruction is garbage
  output F_BP_OUT_t                   F_BP_out
);

  logic    [63:0] PC_reg;               // PC we are currently fetching
  // logic           ready_for_valid;

  // logic   [63:0] PC_plus_8;
  logic                    [63:0] PC_plus;               // PC after increment (plus 4 or 8 depends on PC_reg[2])
  logic                    [63:0] next_PC;
  logic                           PC_enable;
  logic                           take_branch;
  // logic          next_ready_for_valid  ;

  assign proc2Imem_addr = {PC_reg[63:3], 3'b0};

  // this mux is because the Imem gives us 64 bits not 32 bits
  assign if_IR_out[0] = BP_F_out.inst_valid[0] ? Imem2proc_data[31:0] : `NOOP_INST;
  assign if_IR_out[1] = BP_F_out.inst_valid[1] ? Imem2proc_data[63:32] : `NOOP_INST;

  // default next PC value
  assign PC_plus = (PC_reg[2]) ? (PC_reg + 4) : (PC_reg + (`NUM_SUPER*4)); // Warning: This works for only 2-way Superscalar

  // next PC is target_pc if there is a taken branch or
  // the next sequential PC (PC+4) if no branch
  // (halting is handled with the enable PC_enable;
  assign next_PC = BP_F_out.take_branch_target_out;
  assign take_branch = BP_F_out.take_branch_out[0] || BP_F_out.take_branch_out[1]; 

  // The take-branch signal must override stalling (otherwise it may be lost)
  assign PC_enable = (Imem_valid && get_next_inst) || BP_F_out.rollback_en;

  // Pass PC_plus down pipeline w/instruction
  assign if_NPC_out[0] = (PC_reg[2]) ? PC_reg : (PC_reg + 4);
  assign if_NPC_out[1] = PC_plus;

  // Determine if the instruction from Icache is valid
  assign F_BP_out.inst_valid[0] = (PC_reg[2]) ? `FALSE : Imem_valid;
  assign F_BP_out.inst_valid[1] = Imem_valid;

  // assign if_valid_inst_out = BP_F_out.inst_valid;
  assign if_valid_inst_out = {Imem_valid, Imem_valid};

  assign if_target_out[0] = BP_F_out.take_branch_out[0] ? BP_F_out.take_branch_target_out:
                            if_NPC_out[0];
  assign if_target_out[1] = BP_F_out.take_branch_out[1] ? BP_F_out.take_branch_target_out:
                            if_NPC_out[1];

  // assign next_ready_for_valid =	(ready_for_valid | get_next_inst) & 
  // !F_BP_out.inst_valid;

  // This register holds the PC value
  // synopsys sync_set_reset "reset"
  always_ff @(posedge clock)
  begin
    if(reset)
      PC_reg <= `SD 0;       // initial PC value is 0
    else if(PC_enable)
      PC_reg <= `SD next_PC; // transition to next PC
  end  // always

  // This FF controls the stall signal that artificially forces
  // fetch to stall until the previous instruction has completed
  // synopsys sync_set_reset "reset"
  // always_ff @(posedge clock)
  // begin
  // if (reset)
  // ready_for_valid <= `SD 1;  // must start with something
  // else
  // ready_for_valid <= `SD next_ready_for_valid;
  // end
  
endmodule  // module F_stage
