module alu(
  input  FU_PACKET_IN_t               fu_packet,
  input  logic                        CDB_valid,
  input  logic                        ROB_rollback_en,
  input  logic [$clog2(`NUM_ROB)-1:0] ROB_rollback_idx,
  output FU_RESULT_ENTRY_t            fu_packet_out,
  output logic                        fu_valid
);

  logic [63:0] regA, regB;
  logic        rollback_en;

  assign rollback_en = ROB_rollback_en && ( fu_packet.ROB_idx == ROB_rollback_idx );
  assign fu_valid = CDB_valid || !fu_packet.ready || rollback_en;

  // This function computes a signed less-than operation
  function signed_lt;
    input [63:0] a, b;

    if (a[63] == b[63]) 
      signed_lt = (a < b); // signs match: signed compare same as unsigned
    else
      signed_lt = a[63];   // signs differ: a is smaller if neg, larger if pos
  endfunction

  assign regA = fu_packet.T1_value;

  //
  // regB mux
  //
  always_comb begin
     // Default value, Set only because the case isnt full.  If you see this
     // value on the output of the mux you have an invalid opb_select
    regB = 64'hbaadbeefdeadbeef;
    case (fu_packet.T2_select)
      ALU_OPB_IS_REGB:    regB = fu_packet.T2_value;
      ALU_OPB_IS_ALU_IMM: regB = { 56'b0, fu_packet.inst.i.LIT };
    endcase 
  end

  always_comb begin

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
      ALU_CMPULT:   fu_packet_out.result = { 63'd0, (regA < regB) };
      ALU_CMPEQ:    fu_packet_out.result = { 63'd0, (regA == regB) };
      ALU_CMPULE:   fu_packet_out.result = { 63'd0, (regA <= regB) };
      ALU_CMPLT:    fu_packet_out.result = { 63'd0, signed_lt(regA, regB) };
      ALU_CMPLE:    fu_packet_out.result = { 63'd0, (signed_lt(regA, regB) || (regA == regB)) };
      default:      fu_packet_out.result = 64'hdeadbeefbaadbeef;  // here only to force
    endcase

    fu_packet_out.T_idx   = fu_packet.T_idx;
    fu_packet_out.ROB_idx = fu_packet.ROB_idx;
    fu_packet_out.done    = !rollback_en && fu_packet.ready;

  end

endmodule // alu

// This is one stage of an 8 stage (9 depending on how you look at it)
// pipelined multiplier that multiplies 2 64-bit integers and returns
// the low 64 bits of the result.  This is not an ideal multiplier but
// is sufficient to allow a faster clock period than straight *

module mult_stage (
  input  logic                        clock, reset, ready, valid,
  input  logic [63:0]                 product_in, mplier_in, mcand_in,
  input  logic [$clog2(`NUM_PR)-1:0]  T_idx,
  input  logic [$clog2(`NUM_ROB)-1:0] ROB_idx,
  input  logic                        ROB_rollback_en,
  input  logic [$clog2(`NUM_ROB)-1:0] ROB_rollback_idx,
  output logic                        done, valid_out,
  output logic [63:0]                 product_out, mplier_out, mcand_out, next_product,
  output logic [$clog2(`NUM_PR)-1:0]  T_idx_out
);

  logic [64/`NUM_MULT_STAGE-1:0] next_mplier_out;
  logic [64/`NUM_MULT_STAGE-1:0] next_mcand_out;
  logic [63:0]                   next_product_out;
  logic [$clog2(`NUM_PR)-1:0]    next_T_idx_out;
  logic [$clog2(`NUM_PR)-1:0]    next_ROB_idx_out;
  logic [64/`NUM_MULT_STAGE-1:0] partial_product, next_mplier, next_mcand;
  logic                          rollback_en;
  logic                          next_done;

  assign next_done = !ROB_rollback_en && (ready || done);

  assign rollback_en = ROB_rollback_en && ( ROB_idx == ROB_rollback_idx );
  assign valid_out = !ready || valid || rollback_en;

  assign next_product = product_in + partial_product;

  assign partial_product = mplier_in[64/`NUM_MULT_STAGE-1:0] * mcand_in;

  assign next_mplier = {{64/`NUM_MULT_STAGE{1'b0}}, mplier_in[63:64/`NUM_MULT_STAGE]};
  assign next_mcand  = {mcand_in[63-64/`NUM_MULT_STAGE:0], {(64/`NUM_MULT_STAGE){1'b0}}};

  assign next_mplier_out  = mplier_out;
  assign next_mcand_out   = mcand_out;
  assign next_product_out = product_out;
  assign next_T_idx_out   = T_idx;
  assign next_ROB_idx_out = ROB_idx;
  //synopsys sync_set_reset "reset"
  always_ff @(posedge clock) begin
    if ( valid ) begin
      mplier_out       <= `SD next_mplier;
      mcand_out        <= `SD next_mcand;
      product_out      <= `SD next_product;
      T_idx_out        <= `SD T_idx;
      ROB_idx_out      <= `SD ROB_idx;
    end else begin
      mplier_out       <= `SD next_mplier_out;
      mcand_out        <= `SD next_mcand_out;
      product_out      <= `SD next_product_out;
      T_idx_out        <= `SD next_T_idx_out;
      ROB_idx_out      <= `SD next_ROB_idx_out;
    end
  end

  // synopsys sync_set_reset "reset"
  always_ff @(posedge clock) begin
    if( reset ) begin
      done  <= `SD `FALSE;
    end else begin
      done  <= `SD next_done;
    end
  end

endmodule

// This is an 8 stage (9 depending on how you look at it) pipelined 
// multiplier that multiplies 2 64-bit integers and returns the low 64 bits 
// of the result.  This is not an ideal multiplier but is sufficient to 
// allow a faster clock period than straight *
// This module instantiates 8 pipeline stages as an array of submodules.
module mult (
  input  logic             clock, reset,
  input  FU_PACKET_IN_t    fu_packet,
  input  logic             CDB_valid,
  output FU_RESULT_ENTRY_t fu_packet_out,

`ifdef DEBUG
    output logic                        last_done,
    output logic [63:0]                 product_out,
    output logic [$clog2(`NUM_PR)-1:0]  last_T_idx,
    output logic [$clog2(`NUM_ROB)-1:0] last_ROB_idx,
`endif


  output logic             fu_valid
);

`ifndef DEBUG
    logic                        last_done;
    logic [63:0]                 product_out;
    logic [$clog2(`NUM_PR)-1:0]  last_T_idx;
    logic [$clog2(`NUM_ROB)-1:0] last_ROB_idx;
`endif

  logic [63:0]                                       mcand_out, mplier_out, regA, regB;
  logic [((`NUM_MULT_STAGE-1)*64)-1:0]               internal_products, internal_mcands, internal_mpliers, next_products;
  logic [`NUM_MULT_STAGE-2:0]                        internal_valids;
  logic [`NUM_MULT_STAGE-3:0]                        internal_dones;
  logic [($clog2(`NUM_PR)*(`NUM_MULT_STAGE-2))-1:0]  internal_T_idx;
  logic [($clog2(`NUM_ROB)*(`NUM_MULT_STAGE-2))-1:0] internal_ROB_idx;

  assign regA = fu_packet.T1_value;

  //
  // regB mux
  //
  always_comb begin
     // Default value, Set only because the case isnt full.  If you see this
     // value on the output of the mux you have an invalid opb_select
    regB = 64'hbaadbeefdeadbeef;
    case (fu_packet.T2_select)
      ALU_OPB_IS_REGB:    regB = fu_packet.T2_value;
      ALU_OPB_IS_ALU_IMM: regB = { 56'b0, fu_packet.inst.i.LIT };
    endcase 
  end

  mult_stage mstage [`NUM_MULT_STAGE-1:0] (
    // input
    .clock(clock),
    .reset(reset),
    .product_in({internal_products, {64{1'b0}}}),
    .mplier_in({internal_mpliers, regA}),
    .mcand_in({internal_mcands, regB}),
    .ready({fu_packet_out.done, internal_dones, fu_packet.ready}),
    .valid({CDB_valid, internal_valids}),
    .T_idx({fu_packet_out.T_idx, internal_T_idx, fu_packet.T_idx}),
    .ROB_idx({fu_packet_out.ROB_idx, internal_ROB_idx, fu_packet.ROB_idx}),
    // Ouput
    .product_out({product_out, internal_products}),
    .mplier_out({mplier_out, internal_mpliers}),
    .mcand_out({mcand_out, internal_mcands}),
    .done({last_done, fu_packet_out.done, internal_dones}),
    .valid_out({internal_valids, fu_valid}),
    .next_product({fu_packet_out.result, next_products}),
    .T_idx_out({last_T_idx, fu_packet_out.T_idx, internal_T_idx},
    .ROB_idx_out({last_ROB_idx, fu_packet_out.ROB_idx, internal_ROB_idx})
  );

endmodule

module br(
  input  logic             clock, reset,
  input  FU_PACKET_IN_t    fu_packet,
  input  logic             CDB_valid,
  output FU_RESULT_ENTRY_t fu_packet_out,
  output logic             take_branch
);

  logic result;
  logic [63:0] regA, regB;
  assign fu_valid = CDB_valid || !fu_packet.ready;;

  assign take_branch = fu_packet.uncond_branch || (fu_packet.cond_branch && result);

  always_comb begin
    if(fu_packet.ready == `TRUE)
      case (fu_packet.inst.r.br_func)                                               // 'full-case'  All cases covered, no need for a default
        2'b00: result = (br_packet.T1_value[0] == 0);                               // LBC: (lsb(opa) == 0) ?
        2'b01: result = (br_packet.T1_value == 0);                                  // EQ: (opa == 0) ?
        2'b10: result = (br_packet.T1_value[63] == 1);                              // LT: (signed(opa) < 0) : check sign bit
        2'b11: result = (br_packet.T1_value[63] == 1) || (br_packet.T1_value == 0); // LE: (signed(opa) <= 0)
      endcase

      // negate cond if func[2] is set
      if (fu_packet.inst.r.br_func[2])
        result = ~result;
    end

  end

  //
  // ALU opA mux
  //
  always_comb begin
    regB = 64'hbaadbeefdeadbeef;
    case (fu_packet.T1_select)
      ALU_OPA_IS_NPC:      regA = id_ex_packet_in.NPC;
      ALU_OPA_IS_NOT3:     regA = ~64'h3;
    endcase
  end

  //
  // regB mux
  //
  always_comb begin
     // Default value, Set only because the case isnt full.  If you see this
     // value on the output of the mux you have an invalid opb_select
    regB = 64'hbaadbeefdeadbeef;
    case (fu_packet.T2_select)
      ALU_OPB_IS_REGB:    regB = fu_packet.T2_value;
      ALU_OPB_IS_BR_DISP: regB = { {41{fu_packet.inst[20]}}, fu_packet.inst[20:0], 2'b00 };
    endcase 
  end

  always_comb begin

    case (fu_packet.func)
      ALU_ADDQ:     fu_packet_out.result = regA + regB;
      ALU_AND:      fu_packet_out.result = regA & regB;
      default:      fu_packet_out.result = 64'hdeadbeefbaadbeef;  // here only to force
    endcase

    fu_packet_out.T_idx = fu_packet.T_idx;
    fu_packet_out.done  = fu_packet.ready;

  end

endmodule // brcond

module FU (
  input                               clock,               // system clock
  input                               reset,               // system reset
  input  FU_M_PACKET_IN               fu_m_packet_in,
  output FU_M_PACKET_OUT              fu_m_packet_out,
  output logic          [`NUM_FU-1:0] fu_valid
);

  FU_PACKET_IN_t [`NUM_FU-1:0] fu_packet_in;

  always_comb begin
    
    for (int i = 0; i < `NUM_FU; i++) begin
      fu_packet_in[i].ready     = fu_m_packet_in.fu_packet[i].ready;
      fu_packet_in[i].inst      = fu_m_packet_in.fu_packet[i].inst;
      fu_packet_in[i].func      = fu_m_packet_in.fu_packet[i].func;
      fu_packet_in[i].T_idx     = fu_m_packet_in.fu_packet[i].T_idx;
      // fu_packet_in[i].T1_value = pr_packet_out[i].T1_value;
      // fu_packet_in[i].T2_value = pr_packet_out[i].T2_value;
      fu_packet_in[i].T1_select = fu_m_packet_in.fu_packet[i].T1_select;
      fu_packet_in[i].T2_select = fu_m_packet_in.fu_packet[i].T2_select;
    end

  end

  always_comb begin
    
    for (int i = 0; i < `NUM_FU; i++) begin
      // pr_packet_in[i].S_X_T1 = fu_m_packet_in.fu_packet[i].T1_idx;
      // pr_packet_in[i].S_X_T2 = fu_m_packet_in.fu_packet[i].T2_idx;
    end

  end

  alu alu_0 [`NUM_ALU-1:0] (
    // Inputs
    .fu_packet(fu_packet_in[`NUM_FU-1:(`NUM_FU-`NUM_ALU)]),
    .CDB_valid(fu_m_packet_in.CDB_valid[`NUM_FU-1:(`NUM_FU-`NUM_ALU)]),
    // Output
    .fu_packet_out(fu_m_packet_out.fu_result[`NUM_FU-1:(`NUM_FU-`NUM_ALU)]),
    .fu_valid(fu_valid[`NUM_FU-1:(`NUM_FU-`NUM_ALU)])
  );

  // mult mult_0 [`NUM_MULT-1:0] (
  //   // Inputs
  //   .clock({`NUM_MULT{clock}}),
  //   .reset({`NUM_MULT{reset}}),
  //   .full_valid(fu_m_packet_in.full_valid[(`NUM_FU-`NUM_ALU-1):(`NUM_FU-`NUM_ALU-`NUM_MULT)]),
  //   .fu_packet(fu_packet_in[(`NUM_FU-`NUM_ALU-1):(`NUM_FU-`NUM_ALU-`NUM_MULT)]),
  //   // Output
  //   .fu_packet_out(fu_m_packet_out.fu_result[(`NUM_FU-`NUM_ALU-1):(`NUM_FU-`NUM_ALU-`NUM_MULT)]),
  //   .fu_valid(fu_valid[(`NUM_FU-`NUM_ALU-1):(`NUM_FU-`NUM_ALU-`NUM_MULT)])
  // );

  // br br_0 [`NUM_BR-1:0] (
  //   // Inputs
  //   .fu_packet(fu_packet_in[(`NUM_FU-`NUM_ALU-`NUM_MULT-1):(`NUM_FU-`NUM_ALU-`NUM_MULT-`NUM_BR)]),
  //   // Output
  //   .result(fu_m_packet_out.fu_result[(`NUM_FU-`NUM_ALU-`NUM_MULT-1):(`NUM_FU-`NUM_ALU-`NUM_MULT-`NUM_BR)]),
  //   .fu_valid(fu_valid[(`NUM_FU-`NUM_ALU-`NUM_MULT-1):(`NUM_FU-`NUM_ALU-`NUM_MULT-`NUM_BR)])
  // );

  // st st_0 [`NUM_ST-1:0] (
  //   // Inputs
  //   .fu_packet(fu_packet_in[(`NUM_FU-`NUM_ALU-`NUM_MULT-`NUM_BR-1):(`NUM_FU-`NUM_ALU-`NUM_MULT-`NUM_BR-`NUM_ST)]),
  //   // Output
  //   .result(fu_m_packet_out.fu_result[(`NUM_FU-`NUM_ALU-`NUM_MULT-`NUM_BR-1):(`NUM_FU-`NUM_ALU-`NUM_MULT-`NUM_BR-`NUM_ST)]),
  //   .fu_valid(fu_valid[(`NUM_FU-`NUM_ALU-`NUM_MULT-`NUM_BR-1):(`NUM_FU-`NUM_ALU-`NUM_MULT-`NUM_BR-`NUM_ST)])
  // );

  // ld ld_0 [`NUM_LD-1:0] (
  //   // Inputs
  //   .fu_packet(fu_packet_in[(`NUM_FU-`NUM_ALU-`NUM_MULT-`NUM_BR`NUM_ST-1):(`NUM_FU-`NUM_ALU-`NUM_MULT-`NUM_BR-`NUM_ST-`NUM_LD)]),
  //   // Output
  //   .result(fu_m_packet_out.fu_result[(`NUM_FU-`NUM_ALU-`NUM_MULT-`NUM_BR`NUM_ST-1):(`NUM_FU-`NUM_ALU-`NUM_MULT-`NUM_BR-`NUM_ST-`NUM_LD)]),
  //   .fu_valid(fu_valid[(`NUM_FU-`NUM_ALU-`NUM_MULT-`NUM_BR`NUM_ST-1):(`NUM_FU-`NUM_ALU-`NUM_MULT-`NUM_BR-`NUM_ST-`NUM_LD)])
  // );

endmodule // FU
