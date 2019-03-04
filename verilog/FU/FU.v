module alu(
    input  FU_PACKET_t       fu_packet,
    output FU_RESULT_ENTRY_t alu_output
  );

    // This function computes a signed less-than operation
  function signed_lt;
    input [63:0] a, b;

    if (a[63] == b[63]) 
      signed_lt = (a < b); // signs match: signed compare same as unsigned
    else
      signed_lt = a[63];   // signs differ: a is smaller if neg, larger if pos
  endfunction // function signed_lt

  always_comb begin
    if (fu_packet.ready == `TRUE) begin
      case (fu_packet.func)
        ALU_ADDQ:     alu_output.result = fu_packet.T1_value + fu_packet.T2_value;
        ALU_SUBQ:     alu_output.result = fu_packet.T1_value - fu_packet.T2_value;
        ALU_AND:      alu_output.result = fu_packet.T1_value & fu_packet.T2_value;
        ALU_BIC:      alu_output.result = fu_packet.T1_value & ~fu_packet.T2_value;
        ALU_BIS:      alu_output.result = fu_packet.T1_value | fu_packet.T2_value;
        ALU_ORNOT:    alu_output.result = fu_packet.T1_value | ~fu_packet.T2_value;
        ALU_XOR:      alu_output.result = fu_packet.T1_value ^ fu_packet.T2_value;
        ALU_EQV:      alu_output.result = fu_packet.T1_value ^ ~fu_packet.T2_value;
        ALU_SRL:      alu_output.result = fu_packet.T1_value >> fu_packet.T2_value[5:0];
        ALU_SLL:      alu_output.result = fu_packet.T1_value << fu_packet.T2_value[5:0];
        ALU_SRA:      alu_output.result = (fu_packet.T1_value >> fu_packet.T2_value[5:0]) | ({64{fu_packet.T1_value[63]}} << (64 - fu_packet.T2_value[5:0])); // arithmetic from logical shift
        ALU_MULQ:     alu_output.result = fu_packet.T1_value * fu_packet.T2_value;
        ALU_CMPULT:   alu_output.result = { 63'd0, (fu_packet.T1_value < fu_packet.T2_value) };
        ALU_CMPEQ:    alu_output.result = { 63'd0, (fu_packet.T1_value == fu_packet.T2_value) };
        ALU_CMPULE:   alu_output.result = { 63'd0, (fu_packet.T1_value <= fu_packet.T2_value) };
        ALU_CMPLT:    alu_output.result = { 63'd0, signed_lt(fu_packet.T1_value, fu_packet.T2_value) };
        ALU_CMPLE:    alu_output.result = { 63'd0, (signed_lt(fu_packet.T1_value, fu_packet.T2_value) || (fu_packet.T1_value == fu_packet.T2_value)) };
        default:      alu_output.result = 64'hdeadbeefbaadbeef;  // here only to force
                                // a combinational solution
                                // a casex would be better
      endcase //case (fu_packet.func)
      alu_output.done = `TURE;
    end       //if (fu_packet.ready == `TRUE)
  end         // always_comb begin
endmodule 

module brcond(                    
    input BR_PACKET_t br_packet,  // Inputs
    output br_output                // 0/1 condition result (False/True)
  );

  always_comb begin
    if(br_packet.ready == `TRUE)
      case (br_packet.func[1:0])                                                        // 'full-case'  All cases covered, no need for a default
        2'b00: br_output = (br_packet.T1_value[0] == 0);                                // LBC: (lsb(opa) == 0) ?
        2'b01: br_output = (br_packet.T1_value == 0);                                   // EQ: (opa == 0) ?
        2'b10: br_output = (br_packet.T1_value[63] == 1);                               // LT: (signed(opa) < 0) : check sign bit
        2'b11: br_output = (br_packet.T1_value[63] == 1) || (br_packet.T1_value == 0);  // LE: (signed(opa) <= 0)
      endcase

        // negate cond if func[2] is set
        if (br_packet.func[2])
          br_output = ~br_output;
    end // if(br_packet.ready == `TRUE)
  end // always_comb begin
endmodule // brcond

module FU (
  input                clock,               // system clock
  input                reset,               // system reset
  input  FU_PACKET_IN  fu_packet_in,
  output FU_PACKET_OUT fu_packet_out
);

  alu alu_0 [`NUM_ALU-1:0] (
    // Inputs
    .fu_packet(fu_packet_in.fu_packet[`NUM_FU-1:(`NUM_FU-`NUM_ALU)]),
    // Output
    .alu_output(fu_packet_out.alu_result[`NUM_ALU-1:0])
  );

  mult mult_0 [`NUM_MULT-1:0] (
    // Inputs
    .fu_packet(fu_packet_in.fu_packet[(`NUM_FU-`NUM_ALU-1):(`NUM_FU-`NUM_ALU-`NUM_MULT)]),
    // Output
    .result(fu_packet_out.fu_result[(`NUM_FU-`NUM_ALU-1):(`NUM_FU-`NUM_ALU-`NUM_MULT)])
  );

  br br_0 [`NUM_BR-1:0] (
    // Inputs
    .br_packet(fu_packet_in.fu_packet[(`NUM_FU-`NUM_ALU-`NUM_MULT-1):(`NUM_FU-`NUM_ALU-`NUM_MULT-`NUM_BR)]),
    // Output
    .br_output(fu_packet_out.br_cond[`NUM_BR-1:0])
  );

  st st_0 (
    // Inputs
    .fu_packet(fu_packet_in.fu_packet[1]),
    // Output
    .result(fu_packet_out.fu_result[1])
  );

  ld ld_0 (
    // Inputs
    .fu_packet(fu_packet_in.fu_packet[0]),
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