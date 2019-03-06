module alu(
    input  FU_PACKET_IN_t       fu_packet,
    output FU_RESULT_ENTRY_t fu_packet_out,
    output logic first_done
  );

  logic [63:0] regA, regB;
    // This function computes a signed less-than operation
  function signed_lt;
    input [63:0] a, b;

    if (a[63] == b[63]) 
      signed_lt = (a < b); // signs match: signed compare same as unsigned
    else
      signed_lt = a[63];   // signs differ: a is smaller if neg, larger if pos
  endfunction

  // set up possible immediates:
  //   alu_imm: zero-extended 8-bit immediate for ALU ops
  wire [63:0] alu_imm  = { 56'b0, fu_packet.inst.i.LIT };

  assign first_done = fu_packet.ready;

  assign regA = fu_packet.T1_value;

  //
  // regB mux
  //
  always_comb
  begin
     // Default value, Set only because the case isnt full.  If you see this
     // value on the output of the mux you have an invalid opb_select
    regB = 64'hbaadbeefdeadbeef;
    case (fu_packet.T2_select)
      `ALU_OPB_IS_REGB:    regB = fu_packet.T2_value;
      `ALU_OPB_IS_ALU_IMM: regB = alu_imm;
    endcase 
  end

  always_comb begin
    

    fu_packet_out.T_idx = fu_packet.T_idx;

    if (fu_packet.ready == `TRUE) begin
      case (fu_packet.func)
        ALU_ADDQ:     fu_packet_out.result = regA + regB;
        ALU_SUBQ:     fu_packet_out.result = regA - regB;
        ALU_AND:      fu_packet_out.result = regA & regB;
        ALU_BIC:      fu_packet_out.result = regA & ~regB;
        ALU_BIS:      fu_packet_out.result = regA | regB;
        ALU_ORNOT:    fu_packet_out.result = regA | ~regB;
        ALU_XOR:      fu_packet_out.result = regA ^ regB;
        ALU_EQV:      fu_packet_out.result = regA ^ ~regB;
        ALU_SRL:      fu_packet_out.result = regA >> regB[5:0];
        ALU_SLL:      fu_packet_out.result = regA << regB[5:0];
        ALU_SRA:      fu_packet_out.result = (regA >> regB[5:0]) | ({64{regA[63]}} << (64 - regB[5:0])); // arithmetic from logical shift
        // ALU_MULQ:     fu_packet_out.result = regA * regB;
        ALU_CMPULT:   fu_packet_out.result = { 63'd0, (regA < regB) };
        ALU_CMPEQ:    fu_packet_out.result = { 63'd0, (regA == regB) };
        ALU_CMPULE:   fu_packet_out.result = { 63'd0, (regA <= regB) };
        ALU_CMPLT:    fu_packet_out.result = { 63'd0, signed_lt(regA, regB) };
        ALU_CMPLE:    fu_packet_out.result = { 63'd0, (signed_lt(regA, regB) || (regA == regB)) };
        default:      fu_packet_out.result = 64'hdeadbeefbaadbeef;  // here only to force
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
  input  FU_M_PACKET_IN  fu_m_packet_in,
  output FU_M_PACKET_OUT fu_m_packet_out,
  output logic [`NUM_FU-1:0] fu_valid;
);

  logic [`NUM_FU-1:0] fu_first_done;
  FU_PACKET_IN_t [`NUM_FU-1:0] fu_packet_in;

  alu alu_0 [`NUM_ALU-1:0] (
    // Inputs
    .fu_packet(fu_packet_in[`NUM_FU-1:(`NUM_FU-`NUM_ALU)]),
    // Output
    .result(fu_m_packet_out.fu_result[`NUM_FU-1:(`NUM_FU-`NUM_ALU)]),
    .first_done(fu_first_done[`NUM_FU-1:(`NUM_FU-`NUM_ALU)])
  );

  mult mult_0 [`NUM_MULT-1:0] (
    // Inputs
    .fu_packet(fu_packet_in[(`NUM_FU-`NUM_ALU-1):(`NUM_FU-`NUM_ALU-`NUM_MULT)]),
    // Output
    .result(fu_m_packet_out.fu_result[(`NUM_FU-`NUM_ALU-1):(`NUM_FU-`NUM_ALU-`NUM_MULT)]),
    .first_done(fu_first_done[(`NUM_FU-`NUM_ALU-1):(`NUM_FU-`NUM_ALU-`NUM_MULT)])
  );

  br br_0 [`NUM_BR-1:0] (
    // Inputs
    .fu_packet(fu_packet_in[(`NUM_FU-`NUM_ALU-`NUM_MULT-1):(`NUM_FU-`NUM_ALU-`NUM_MULT-`NUM_BR)]),
    // Output
    .result(fu_m_packet_out.fu_result[(`NUM_FU-`NUM_ALU-`NUM_MULT-1):(`NUM_FU-`NUM_ALU-`NUM_MULT-`NUM_BR)]),
    .first_done(fu_first_done[(`NUM_FU-`NUM_ALU-`NUM_MULT-1):(`NUM_FU-`NUM_ALU-`NUM_MULT-`NUM_BR)])
  );

  st st_0 [`NUM_ST-1:0] (
    // Inputs
    .fu_packet(fu_packet_in[(`NUM_FU-`NUM_ALU-`NUM_MULT-`NUM_BR-1):(`NUM_FU-`NUM_ALU-`NUM_MULT-`NUM_BR-`NUM_ST)]),
    // Output
    .result(fu_m_packet_out.fu_result[(`NUM_FU-`NUM_ALU-`NUM_MULT-`NUM_BR-1):(`NUM_FU-`NUM_ALU-`NUM_MULT-`NUM_BR-`NUM_ST)]),
    .first_done(fu_first_done[(`NUM_FU-`NUM_ALU-`NUM_MULT-`NUM_BR-1):(`NUM_FU-`NUM_ALU-`NUM_MULT-`NUM_BR-`NUM_ST)])
  );

  ld ld_0 [`NUM_LD-1:0] (
    // Inputs
    .fu_packet(fu_packet_in[(`NUM_FU-`NUM_ALU-`NUM_MULT-`NUM_BR`NUM_ST-1):(`NUM_FU-`NUM_ALU-`NUM_MULT-`NUM_BR-`NUM_ST-`NUM_LD)]),
    // Output
    .result(fu_m_packet_out.fu_result[(`NUM_FU-`NUM_ALU-`NUM_MULT-`NUM_BR`NUM_ST-1):(`NUM_FU-`NUM_ALU-`NUM_MULT-`NUM_BR-`NUM_ST-`NUM_LD)]),
    .first_done(fu_first_done[(`NUM_FU-`NUM_ALU-`NUM_MULT-`NUM_BR`NUM_ST-1):(`NUM_FU-`NUM_ALU-`NUM_MULT-`NUM_BR-`NUM_ST-`NUM_LD)])
  );

  always_comb begin
    
    for (int i = 0; i < `NUM_FU; i++) begin
      // pr_packet_in[i].S_X_T1 = fu_m_packet_in.fu_packet[i].T1_idx;
      // pr_packet_in[i].S_X_T2 = fu_m_packet_in.fu_packet[i].T2_idx;
      fu_packet_in[i].ready = fu_m_packet_in.fu_packet[i].ready;
      fu_packet_in[i].inst = fu_m_packet_in.fu_packet[i].inst;
      fu_packet_in[i].func = fu_m_packet_in.fu_packet[i].func;
      fu_packet_in[i].T_idx = fu_m_packet_in.fu_packet[i].T_idx;
      // fu_packet_in[i].T1_value = pr_packet_out[i].T1_value;
      // fu_packet_in[i].T2_value = pr_packet_out[i].T2_value;
      fu_packet_in[i].T1_select = fu_m_packet_in.fu_packet[i].T1_select;
      fu_packet_in[i].T2_select = fu_m_packet_in.fu_packet[i].T2_select;
    end

  end

  always_comb begin
    
    for (int i = 0; i < `NUM_FU; i++) begin
      fu_valid[i] = !fu_m_packet_in[i].ready || fu_first_done[i];
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