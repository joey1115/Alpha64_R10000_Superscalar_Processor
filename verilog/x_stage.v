//////////////////////////////////////////////////////////////////////////
//                                                                      //
//   Modulename :  x_stage.v                                           //
//                                                                      //
//  Description :  instruction execute (EX) stage of the pipeline;      //
//                 given the instruction command code CMD, select the   //
//                 proper input A and B for the ALU, compute the result,// 
//                 and compute the condition for branches, and pass all //
//                 the results down the pipeline. MWB                   // 
//                                                                      //
//                                                                      //
//////////////////////////////////////////////////////////////////////////

`timescale 1ns/100ps

//
// The ALU
//
// given the command code CMD and proper operands A and B, compute the
// result of the instruction
//
// This module is purely combinational
//
module alu(
    input [63:0] opa,
    input [63:0] opb,
    ALU_FUNC     func,

    output logic [63:0] result
  );

    // This function computes a signed less-than operation
  function signed_lt;
    input [63:0] a, b;

    if (a[63] == b[63]) 
      signed_lt = (a < b); // signs match: signed compare same as unsigned
    else
      signed_lt = a[63];   // signs differ: a is smaller if neg, larger if pos
  endfunction

  always_comb begin
    case (func)
      ALU_ADDQ:     result = opa + opb;
      ALU_SUBQ:     result = opa - opb;
      ALU_AND:      result = opa & opb;
      ALU_BIC:      result = opa & ~opb;
      ALU_BIS:      result = opa | opb;
      ALU_ORNOT:    result = opa | ~opb;
      ALU_XOR:      result = opa ^ opb;
      ALU_EQV:      result = opa ^ ~opb;
      ALU_SRL:      result = opa >> opb[5:0];
      ALU_SLL:      result = opa << opb[5:0];
      ALU_SRA:      result = (opa >> opb[5:0]) | ({64{opa[63]}} << (64 - opb[5:0])); // arithmetic from logical shift
      ALU_MULQ:     result = opa * opb;
      ALU_CMPULT:   result = { 63'd0, (opa < opb) };
      ALU_CMPEQ:    result = { 63'd0, (opa == opb) };
      ALU_CMPULE:   result = { 63'd0, (opa <= opb) };
      ALU_CMPLT:    result = { 63'd0, signed_lt(opa, opb) };
      ALU_CMPLE:    result = { 63'd0, (signed_lt(opa, opb) || (opa == opb)) };
      default:      result = 64'hdeadbeefbaadbeef;  // here only to force
                              // a combinational solution
                              // a casex would be better
    endcase
  end
endmodule // alu

//
// BrCond module
//
// Given the instruction code, compute the proper condition for the
// instruction; for branches this condition will indicate whether the
// target is taken.
//
// This module is purely combinational
//
module brcond(// Inputs
    input [63:0] opa,    // Value to check against condition
    input  [2:0] func,  // Specifies which condition to check

    output logic cond    // 0/1 condition result (False/True)
  );

  always_comb begin
    case (func[1:0])                              // 'full-case'  All cases covered, no need for a default
      2'b00: cond = (opa[0] == 0);                // LBC: (lsb(opa) == 0) ?
      2'b01: cond = (opa == 0);                    // EQ: (opa == 0) ?
      2'b10: cond = (opa[63] == 1);                // LT: (signed(opa) < 0) : check sign bit
      2'b11: cond = (opa[63] == 1) || (opa == 0);  // LE: (signed(opa) <= 0)
    endcase
    
      // negate cond if func[2] is set
      if (func[2])
        cond = ~cond;
  end
endmodule // brcond


module x_stage(
  input                clock,               // system clock
  input                reset,               // system reset
  input  S_X_PACKET s_x_packet_in,
  output X_C_PACKET x_packet_out
);
  
  assign x_packet_out.NPC          = s_x_packet_in.NPC;
  assign x_packet_out.inst         = s_x_packet_in.inst;
  assign x_packet_out.dest_reg_idx = s_x_packet_in.dest_reg_idx;
  assign x_packet_out.rd_mem       = s_x_packet_in.rd_mem;
  assign x_packet_out.wr_mem       = s_x_packet_in.wr_mem;
  assign x_packet_out.halt         = s_x_packet_in.halt;
  assign x_packet_out.illegal      = s_x_packet_in.illegal;
  assign x_packet_out.valid        = s_x_packet_in.valid;
  assign x_packet_out.rega_value   = s_x_packet_in.rega_value;


  logic  [63:0] opa_mux_out, opb_mux_out;
  logic         brcond_result;

  // set up possible immediates:
  //   mem_disp: sign-extended 16-bit immediate for memory format
  //   br_disp: sign-extended 21-bit immediate * 4 for branch displacement
  //   alu_imm: zero-extended 8-bit immediate for ALU ops
  wire [63:0] mem_disp = { {48{s_x_packet_in.inst[15]}}, s_x_packet_in.inst.m.mem_disp };
  wire [63:0] br_disp  = { {41{s_x_packet_in.inst[20]}}, s_x_packet_in.inst.b.branch_disp, 2'b00 };
  wire [63:0] alu_imm  = { 56'b0, s_x_packet_in.inst.i.LIT };
   
  //
  // ALU opA mux
  //
  always_comb begin
    case (s_x_packet_in.opa_select)
      ALU_OPA_IS_REGA:     opa_mux_out = s_x_packet_in.rega_value;
      ALU_OPA_IS_MEM_DISP: opa_mux_out = mem_disp;
      ALU_OPA_IS_NPC:      opa_mux_out = s_x_packet_in.NPC;
      ALU_OPA_IS_NOT3:     opa_mux_out = ~64'h3;
    endcase
  end

   //
   // ALU opB mux
   //
  always_comb begin
    // Default value, Set only because the case isnt full.  If you see this
    // value on the output of the mux you have an invalid opb_select
    opb_mux_out = 64'hbaadbeefdeadbeef;
    case (s_x_packet_in.opb_select)
      ALU_OPB_IS_REGB:    opb_mux_out = s_x_packet_in.regb_value;
      ALU_OPB_IS_ALU_IMM: opb_mux_out = alu_imm;
      ALU_OPB_IS_BR_DISP: opb_mux_out = br_disp;
    endcase 
  end

  //
  // instantiate the ALU
  //
  alu alu_0 [`NUM_ALU-1:0] (// Inputs
    .opa(opa_mux_out),
    .opb(opb_mux_out),
    .func(s_x_packet_in.alu_func),
    // Output
    .result(x_packet_out.alu_result)
  );

   //
   // instantiate the branch condition tester
   //
  brcond brcond (
    // Inputs
    .opa(s_x_packet_in.rega_value),       // always check regA value
    .func(s_x_packet_in.inst[28:26]), // inst bits to determine check
    // Output
    .cond(brcond_result)
  );

   // ultimate "take branch" signal:
   //    unconditional, or conditional and the condition is true
  assign x_packet_out.take_branch = s_x_packet_in.uncond_branch | (s_x_packet_in.cond_branch & brcond_result);

endmodule // module x_stage
