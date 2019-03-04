module alu(
/*     input [63:0] opa,
    input [63:0] opb,
    ALU_FUNC     func,

    output logic [63:0] result */
    input alu_input,
    output alu_output
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
    if(alu_input.ready == `TRUE) begin 
    case (alu_input.func)
      ALU_ADDQ:     alu_output.result = alu_input.T1_value + alu_input.T2_value;
      ALU_SUBQ:     alu_output.result = alu_input.T1_value - alu_input.T2_value;
      ALU_AND:      alu_output.result = alu_input.T1_value & alu_input.T2_value;
      ALU_BIC:      alu_output.result = alu_input.T1_value & ~alu_input.T2_value;
      ALU_BIS:      alu_output.result = alu_input.T1_value | alu_input.T2_value;
      ALU_ORNOT:    alu_output.result = alu_input.T1_value | ~alu_input.T2_value;
      ALU_XOR:      alu_output.result = alu_input.T1_value ^ alu_input.T2_value;
      ALU_EQV:      alu_output.result = alu_input.T1_value ^ ~alu_input.T2_value;
      ALU_SRL:      alu_output.result = alu_input.T1_value >> alu_input.T2_value[5:0];
      ALU_SLL:      alu_output.result = alu_input.T1_value << alu_input.T2_value[5:0];
      ALU_SRA:      alu_output.result = (alu_input.T1_value >> alu_input.T2_value[5:0]) | ({64{alu_input.T1_value[63]}} << (64 - fu_packet.T2_value[5:0])); // arithmetic from logical shift
      ALU_MULQ:     alu_output.result = alu_input.T1_value * alu_input.T2_value;
      ALU_CMPULT:   alu_output.result = { 63'd0, (alu_input.T1_value < alu_input.T2_value) };
      ALU_CMPEQ:    alu_output.result = { 63'd0, (alu_input.T1_value == alu_input.T2_value) };
      ALU_CMPULE:   alu_output.result = { 63'd0, (alu_input.T1_value <= alu_input.T2_value) };
      ALU_CMPLT:    alu_output.result = { 63'd0, signed_lt(alu_input.T1_value, alu_input.T2_value) };
      ALU_CMPLE:    alu_output.result = { 63'd0, (signed_lt(alu_input.T1_value, alu_input.T2_value) || (alu_input.T1_value == fu_packet.T2_value)) };
      default:      alu_output.result = 64'hdeadbeefbaadbeef;  // here only to force
                              // a combinational solution
                              // a casex would be better
    endcase
    alu_output.done = 1;
    end
  end
endmodule // alu

module brcond(// Inputs
/*     input [63:0] opa,    // Value to check against condition
    input  [2:0] func,  // Specifies which condition to check

    output logic cond    // 0/1 condition result (False/True) */
    input br_input,
    output br_output
  );

  always_comb begin
    case (fu_packet.func[1:0])                              // 'full-case'  All cases covered, no need for a default
      2'b00: cond = (fu_packet.T1_value[0] == 0);                // LBC: (lsb(opa) == 0) ?
      2'b01: cond = (fu_packet.T1_value == 0);                    // EQ: (opa == 0) ?
      2'b10: cond = (fu_packet.T1_value[63] == 1);                // LT: (signed(opa) < 0) : check sign bit
      2'b11: cond = (fu_packet.T1_value[63] == 1) || (fu_packet.T1_value == 0);  // LE: (signed(opa) <= 0)
    endcase
    
      // negate cond if func[2] is set
      if (fu_packet.func[2])
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
    .alu_input(fu_packet_in),
    // Output
    .alu_output(fu_packet_out)
  );

  mult mult_0 [`NUM_MULT-1:0] (
    // Inputs
    .fu_packet(fu_packet_in.FU_packet[(`NUM_FU-`NUM_ALU-1):(`NUM_FU-`NUM_ALU-`NUM_MULT)]),
    // Output
    .result(fu_packet_out.fu_result[(`NUM_FU-`NUM_ALU-1):(`NUM_FU-`NUM_ALU-`NUM_MULT)])
  );

  br br_0 [`NUM_BR-1:0] (
    // Inputs
    .br_input(fu_packet_in.FU_packet[(`NUM_FU-`NUM_ALU-`NUM_MULT-1):(`NUM_FU-`NUM_ALU-`NUM_MULT-`NUM_BR)]),
    // Output
    .br_output(fu_packet_out.fu_result[(`NUM_FU-`NUM_ALU-`NUM_MULT-1):(`NUM_FU-`NUM_ALU-`NUM_MULT-`NUM_BR)])
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