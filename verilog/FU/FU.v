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
        = a[63];   // signs differ: a is smaller if neg, larger if pos
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

module FU (
  input                clock,               // system clock
  input                reset,               // system reset
  input  FU_PACKET_IN  fu_packet_in,
  output FU_PACKET_OUT fu_packet_out
);

  alu alu_0 [`NUM_ALU-1:0] (
    // Inputs
    .fu_packet(fu_packet_in.FU_packet[`NUM_FU-1:(`NUM_FU-`NUM_ALU)]),
    // Output
    .result(fu_packet_out.fu_result[`NUM_FU-1:(`NUM_FU-`NUM_ALU)])
  );

  mult mult_0 [`NUM_MULT-1:0] (
    // Inputs
    .fu_packet(fu_packet_in.FU_packet[(`NUM_FU-`NUM_ALU-1):(`NUM_FU-`NUM_ALU-`NUM_MULT)]),
    // Output
    .result(fu_packet_out.fu_result[(`NUM_FU-`NUM_ALU-1):(`NUM_FU-`NUM_ALU-`NUM_MULT)])
  );

  br br_0 [`NUM_BR-1:0] (
    // Inputs
    .fu_packet(fu_packet_in.FU_packet[(`NUM_FU-`NUM_ALU-`NUM_MULT-1):(`NUM_FU-`NUM_ALU-`NUM_MULT-`NUM_BR)]),
    // Output
    .result(fu_packet_out.fu_result[(`NUM_FU-`NUM_ALU-`NUM_MULT-1):(`NUM_FU-`NUM_ALU-`NUM_MULT-`NUM_BR)])
  );

  st st_0 (
    // Inputs
    .fu_packet(fu_packet_in.FU_packet[1]),
    // Output
    .result(fu_packet_out.fu_result[1])
  );

  ld ld_0 (
    // Inputs
    .fu_packet(fu_packet_in.FU_packet[0]),
    // Output
    .result(fu_packet_out.fu_result[0])
  );

// FU logic
  // always_ff @(posedge clock) begin
  //   if(reset) begin
  //     RS <= `SD `FU_RESET;
  //   end else if(en) begin
  //     RS <= `SD next_FU;
  //   end // else if(en) begin
  // end // always

endmodule // RS