module alu(
    input  FU_PACKET_t       fu_packet,
    output FU_RESULT_ENTRY_t result
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
    if (fu_packet.ready == `TRUE) begin
      case (fu_packet.func)
        ALU_ADDQ:     result = fu_packet.T1_value + fu_packet.T2_value;
        ALU_SUBQ:     result = fu_packet.T1_value - fu_packet.T2_value;
        ALU_AND:      result = fu_packet.T1_value & fu_packet.T2_value;
        ALU_BIC:      result = fu_packet.T1_value & ~fu_packet.T2_value;
        ALU_BIS:      result = fu_packet.T1_value | fu_packet.T2_value;
        ALU_ORNOT:    result = fu_packet.T1_value | ~fu_packet.T2_value;
        ALU_XOR:      result = fu_packet.T1_value ^ fu_packet.T2_value;
        ALU_EQV:      result = fu_packet.T1_value ^ ~fu_packet.T2_value;
        ALU_SRL:      result = fu_packet.T1_value >> fu_packet.T2_value[5:0];
        ALU_SLL:      result = fu_packet.T1_value << fu_packet.T2_value[5:0];
        ALU_SRA:      result = (fu_packet.T1_value >> fu_packet.T2_value[5:0]) | ({64{fu_packet.T1_value[63]}} << (64 - fu_packet.T2_value[5:0])); // arithmetic from logical shift
        // ALU_MULQ:     result = fu_packet.T1_value * fu_packet.T2_value;
        ALU_CMPULT:   result = { 63'd0, (fu_packet.T1_value < fu_packet.T2_value) };
        ALU_CMPEQ:    result = { 63'd0, (fu_packet.T1_value == fu_packet.T2_value) };
        ALU_CMPULE:   result = { 63'd0, (fu_packet.T1_value <= fu_packet.T2_value) };
        ALU_CMPLT:    result = { 63'd0, signed_lt(fu_packet.T1_value, fu_packet.T2_value) };
        ALU_CMPLE:    result = { 63'd0, (signed_lt(fu_packet.T1_value, fu_packet.T2_value) || (fu_packet.T1_value == fu_packet.T2_value)) };
        default:      result = 64'hdeadbeefbaadbeef;  // here only to force
                                // a combinational solution
                                // a casex would be better
      endcase
    end
  end
endmodule // alu

module brcond(// Inputs
    input BR_PACKET_t br_packet,
    output result    // 0/1 condition result (False/True)
  );

  always_comb begin
    if(br_packet.ready == `TRUE)
      case (br_packet.func[1:0])                              // 'full-case'  All cases covered, no need for a default
        2'b00: result = (br_packet.T1_value[0] == 0);                // LBC: (lsb(opa) == 0) ?
        2'b01: result = (br_packet.T1_value == 0);                    // EQ: (opa == 0) ?
        2'b10: result = (br_packet.T1_value[63] == 1);                // LT: (signed(opa) < 0) : check sign bit
        2'b11: result = (br_packet.T1_value[63] == 1) || (br_packet.T1_value == 0);  // LE: (signed(opa) <= 0)
      endcase
    
        // negate cond if func[2] is set
        if (br_packet.func[2])
          result = ~result;
    end
  end
endmodule // brcond

module FU (
  input                clock,               // system clock
  input                reset,               // system reset
  input  FU_PACKET_IN  fu_packet_in,
  output FU_PACKET_OUT fu_packet_out
);

  logic [`NUM_FU-1:0] fu_first_done;

  alu alu_0 [`NUM_ALU-1:0] (
    // Inputs
    .fu_packet(fu_packet_in[`NUM_FU-1:(`NUM_FU-`NUM_ALU)]),
    // Output
    .result(fu_packet_out.fu_result[`NUM_FU-1:(`NUM_FU-`NUM_ALU)]),
    .first_done(fu_first_done[`NUM_FU-1:(`NUM_FU-`NUM_ALU)])
  );

  mult mult_0 [`NUM_MULT-1:0] (
    // Inputs
    .fu_packet(fu_packet_in[(`NUM_FU-`NUM_ALU-1):(`NUM_FU-`NUM_ALU-`NUM_MULT)]),
    // Output
    .result(fu_packet_out.fu_result[(`NUM_FU-`NUM_ALU-1):(`NUM_FU-`NUM_ALU-`NUM_MULT)]),
    .first_done(fu_first_done[(`NUM_FU-`NUM_ALU-1):(`NUM_FU-`NUM_ALU-`NUM_MULT)])
  );

  br br_0 [`NUM_BR-1:0] (
    // Inputs
    .fu_packet(fu_packet_in[(`NUM_FU-`NUM_ALU-`NUM_MULT-1):(`NUM_FU-`NUM_ALU-`NUM_MULT-`NUM_BR)]),
    // Output
    .result(fu_packet_out.fu_result[(`NUM_FU-`NUM_ALU-`NUM_MULT-1):(`NUM_FU-`NUM_ALU-`NUM_MULT-`NUM_BR)]),
    .first_done(fu_first_done[(`NUM_FU-`NUM_ALU-`NUM_MULT-1):(`NUM_FU-`NUM_ALU-`NUM_MULT-`NUM_BR)])
  );

  st st_0 [`NUM_ST-1:0] (
    // Inputs
    .fu_packet(fu_packet_in[(`NUM_FU-`NUM_ALU-`NUM_MULT-`NUM_BR-1):(`NUM_FU-`NUM_ALU-`NUM_MULT-`NUM_BR-`NUM_ST)]),
    // Output
    .result(fu_packet_out.fu_result[(`NUM_FU-`NUM_ALU-`NUM_MULT-`NUM_BR-1):(`NUM_FU-`NUM_ALU-`NUM_MULT-`NUM_BR-`NUM_ST)]),
    .first_done(fu_first_done[(`NUM_FU-`NUM_ALU-`NUM_MULT-`NUM_BR-1):(`NUM_FU-`NUM_ALU-`NUM_MULT-`NUM_BR-`NUM_ST)])
  );

  ld ld_0 [`NUM_LD-1:0] (
    // Inputs
    .fu_packet(fu_packet_in[(`NUM_FU-`NUM_ALU-`NUM_MULT-`NUM_BR`NUM_ST-1):(`NUM_FU-`NUM_ALU-`NUM_MULT-`NUM_BR-`NUM_ST-`NUM_LD)]),
    // Output
    .result(fu_packet_out.fu_result[(`NUM_FU-`NUM_ALU-`NUM_MULT-`NUM_BR`NUM_ST-1):(`NUM_FU-`NUM_ALU-`NUM_MULT-`NUM_BR-`NUM_ST-`NUM_LD)]),
    .first_done(fu_first_done[(`NUM_FU-`NUM_ALU-`NUM_MULT-`NUM_BR`NUM_ST-1):(`NUM_FU-`NUM_ALU-`NUM_MULT-`NUM_BR-`NUM_ST-`NUM_LD)])
  );

  always_comb begin
    
    for (int i = 0; i < `NUM_FU; i++) begin
      fu_packet_out.fu_valid[i] = !FU_packet[i].ready || fu_first_done[i];
      // fu_packet_in.T1_value = 
      // fu_packet_in.T2_value = 
    end

  end
// FU logic
  // always_ff @(posedge clock) begin
  //   if(reset) begin
  //     RS <= `SD `FU_RESET;
  //   end else if(en) begin
  //     RS <= `SD next_FU;
  //   end // else if(en) begin
  // end // always

endmodule // RS