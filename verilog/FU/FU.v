module alu (
  input  FU_PACKET_IN_t               fu_packet,
  input  logic                        CDB_valid,
  input  logic                        rollback_en,
  input  logic [$clog2(`NUM_ROB)-1:0] ROB_rollback_idx,
  input  logic [$clog2(`NUM_ROB)-1:0] diff_ROB,
  output FU_RESULT_ENTRY_t            fu_packet_out,
  output logic                        fu_valid
);

  logic [63:0]                 regA, regB;
  logic                        rollback_valid;
  logic [$clog2(`NUM_ROB)-1:0] diff;

  assign diff           = fu_packet.ROB_idx - ROB_rollback_idx;
  assign rollback_valid = rollback_en && diff_ROB >= diff;
  assign fu_valid       = CDB_valid || !fu_packet.ready || rollback_valid;

  function signed_lt;
    input [63:0] a, b;

    if (a[63] == b[63]) 
      signed_lt = (a < b); // signs match: signed compare same as unsigned
    else
      signed_lt = a[63];   // signs differ: a is smaller if neg, larger if pos
  endfunction

  assign regA = regA;

  always_comb begin
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

    fu_packet_out.dest_idx = fu_packet.dest_idx;
    fu_packet_out.T_idx    = fu_packet.T_idx;
    fu_packet_out.FL_idx   = fu_packet.FL_idx;
    fu_packet_out.ROB_idx  = fu_packet.ROB_idx;
    fu_packet_out.done     = !rollback_valid && fu_packet.ready;

  end

endmodule // alu

module mult_stage (
  input  logic                        clock, reset, ready, valid,
  input  logic [63:0]                 product_in, mplier_in, mcand_in,
  input  logic [4:0]                  dest_idx,
  input  logic [$clog2(`NUM_PR)-1:0]  T_idx,
  input  logic [$clog2(`NUM_ROB)-1:0] ROB_idx,
  input  logic                        rollback_en,
  input  logic [$clog2(`NUM_ROB)-1:0] ROB_rollback_idx,
  input  logic [$clog2(`NUM_ROB)-1:0] diff_ROB,
  input  logic [$clog2(`NUM_FL)-1:0]  FL_idx,
`ifndef SYNTH_TEST
  input  logic [63:0]                 T1_value,
  input  logic [63:0]                 T2_value,
  output logic [63:0]                 T1_value_out,
  output logic [63:0]                 T2_value_out,
`endif
  output logic                        done, valid_out,
  output logic [63:0]                 product_out, mplier_out, mcand_out, next_product,
  output logic [4:0]                  dest_idx_out,
  output logic [$clog2(`NUM_PR)-1:0]  T_idx_out,
  output logic [$clog2(`NUM_ROB)-1:0] ROB_idx_out,
  output logic [$clog2(`NUM_FL)-1:0]  FL_idx_out
);

  logic [64/`NUM_MULT_STAGE-1:0] next_mplier_out;
  logic [64/`NUM_MULT_STAGE-1:0] next_mcand_out;
  logic [63:0]                   next_product_out;
  logic [4:0]                    next_dest_idx_out;
  logic [$clog2(`NUM_PR)-1:0]    next_T_idx_out;
  logic [$clog2(`NUM_PR)-1:0]    next_ROB_idx_out;
  logic [$clog2(`NUM_FL)-1:0]    next_FL_idx_out;
  logic [64/`NUM_MULT_STAGE-1:0] partial_product, next_mplier, next_mcand;
  logic                          rollback_valid_out, rollback_valid;
  logic                          next_done;
  logic [$clog2(`NUM_ROB)-1:0]   diff;
`ifdef MULT_FORWARDING
  logic [$clog2(`NUM_ROB)-1:0]   diff_out;
`endif
`ifndef SYNTH_TEST
  logic [63:0]                   next_T1_value_out;
  logic [63:0]                   next_T2_value_out;
`endif

`ifdef MULT_FORWARDING
  assign diff_out           = ROB_idx_out - ROB_rollback_idx;
  assign diff               = ROB_idx - ROB_rollback_idx;
  assign rollback_valid_out = rollback_en && diff_ROB >= diff_out;
  assign rollback_valid     = rollback_en && diff_ROB >= diff;
  assign valid_out          = !ready || valid;
`else
  assign diff               = next_ROB_idx_out - ROB_rollback_idx;
  assign valid_out          = ( !ready || valid ) && !rollback_valid;
  assign rollback_valid     = rollback_en && diff_ROB >= diff;
  assign next_mplier_out    = valid ? next_mplier : mplier_out;
  assign next_mcand_out     = valid ? next_mcand : mcand_out;
  assign next_product_out   = valid ? next_product : product_out;
  assign next_dest_idx_out  = valid ? dest_idx : dest_idx_out;
  assign next_T_idx_out     = valid ? T_idx : T_idx_out;
  assign next_ROB_idx_out   = valid ? ROB_idx : ROB_idx_out;
  assign next_FL_idx_out    = valid ? FL_idx : FL_idx_out;
  assign next_done          = valid ? ready : done;
`ifndef SYNTH_TEST
  assign next_T1_value_out  = valid ? T1_value : T1_value_out;
  assign next_T2_value_out  = valid ? T2_value : T2_value_out;
`endif
`endif
  assign next_product       = product_in + partial_product;
  assign partial_product    = mplier_in[64/`NUM_MULT_STAGE-1:0] * mcand_in;
  assign next_mplier        = {{64/`NUM_MULT_STAGE{1'b0}}, mplier_in[63:64/`NUM_MULT_STAGE]};
  assign next_mcand         = {mcand_in[63-64/`NUM_MULT_STAGE:0], {(64/`NUM_MULT_STAGE){1'b0}}};

`ifdef MULT_FORWARDING
  always_comb begin
    if ( !valid && !rollback_valid_out ) begin
      next_mplier_out   = mplier_out;
      next_mcand_out    = mcand_out;
      next_product_out  = product_out;
      next_dest_idx_out = dest_idx_out;
      next_T_idx_out    = T_idx_out;
      next_ROB_idx_out  = ROB_idx_out;
      next_FL_idx_out   = FL_idx_out;
      next_done         = done;
`ifndef SYNTH_TEST
      next_T1_value_out = T1_value_out;
      next_T2_value_out = T2_value_out;
`endif
    end else if ( valid && !rollback_valid ) begin
      next_mplier_out   = next_mplier;
      next_mcand_out    = next_mcand;
      next_product_out  = next_product;
      next_dest_idx_out = dest_idx;
      next_T_idx_out    = T_idx;
      next_ROB_idx_out  = ROB_idx;
      next_FL_idx_out   = FL_idx;
      next_done         = ready;
`ifndef SYNTH_TEST
      next_T1_value_out = T1_value;
      next_T2_value_out = T2_value;
`endif
    end else begin
      next_mplier_out   = {64{1'b0}};
      next_mcand_out    = {64{1'b0}};
      next_product_out  = {64{1'b0}};
      next_dest_idx_out = `ZERO_REG;
      next_T_idx_out    = `ZERO_PR;
      next_ROB_idx_out  = {`NUM_ROB{1'b0}};
      next_done         = `FALSE;
`ifndef SYNTH_TEST
      next_T1_value_out = {64{1'b0}};
      next_T2_value_out = {64{1'b0}};
`endif
    end
  end
`endif

  always_ff @(posedge clock) begin
`ifdef MULT_FORWARDING
    if ( reset ) begin
`else
    if ( reset || rollback_valid ) begin
`endif
      mplier_out   <= `SD {64{1'b0}};
      mcand_out    <= `SD {64{1'b0}};
      product_out  <= `SD {64{1'b0}};
      dest_idx_out <= `SD `ZERO_REG;
      T_idx_out    <= `SD `ZERO_PR;
      ROB_idx_out  <= `SD {`NUM_ROB{1'b0}};
      done         <= `SD `FALSE;
`ifndef SYNTH_TEST
      T1_value_out <= `SD {64{1'b0}};
      T2_value_out <= `SD {64{1'b0}};
`endif
    end else begin
      mplier_out       <= `SD next_mplier_out;
      mcand_out        <= `SD next_mcand_out;
      product_out      <= `SD next_product_out;
      T_idx_out        <= `SD next_T_idx_out;
      ROB_idx_out      <= `SD next_ROB_idx_out;
      FL_idx_out       <= `SD next_FL_idx_out;
      done             <= `SD next_done;
`ifndef SYNTH_TEST
      T1_value_out     <= `SD next_T1_value_out;
      T2_value_out     <= `SD next_T2_value_out;
`endif
    end
  end

endmodule

// This is an 8 stage (9 depending on how you look at it) pipelined 
// multiplier that multiplies 2 64-bit integers and returns the low 64 bits 
// of the result.  This is not an ideal multiplier but is sufficient to 
// allow a faster clock period than straight *
// This module instantiates 8 pipeline stages as an array of submodules.
module mult (
  input  logic                                                          clock, reset,
  input  FU_PACKET_IN_t                                                 fu_packet,
  input  logic                                                          CDB_valid,
  input  logic                                                          rollback_en,
  input  logic             [$clog2(`NUM_ROB)-1:0]                       ROB_rollback_idx,
  input  logic             [$clog2(`NUM_ROB)-1:0]                       diff_ROB,
`ifndef SYNTH_TEST
  output logic                                                          last_done,
  output logic             [63:0]                                       product_out,
  output logic             [4:0]                                        last_dest_idx,
  output logic             [$clog2(`NUM_PR)-1:0]                        last_T_idx,
  output logic             [$clog2(`NUM_ROB)-1:0]                       last_ROB_idx,
  output logic             [$clog2(`NUM_FL)-1:0]                        last_FL_idx,
  output logic             [63:0]                                       T1_value,
  output logic             [63:0]                                       T2_value,
  output logic             [((`NUM_MULT_STAGE-1)*64)-1:0]               internal_T1_values, internal_T2_values,
  output logic             [`NUM_MULT_STAGE-2:0]                        internal_valids,
  output logic             [`NUM_MULT_STAGE-3:0]                        internal_dones,
  output logic             [5*(`NUM_MULT_STAGE-2)-1:0]                  internal_dest_idx,
  output logic             [($clog2(`NUM_PR)*(`NUM_MULT_STAGE-2))-1:0]  internal_T_idx,
  output logic             [($clog2(`NUM_ROB)*(`NUM_MULT_STAGE-2))-1:0] internal_ROB_idx,
  output logic             [($clog2(`NUM_FL)*(`NUM_MULT_STAGE-2))-1:0]  internal_FL_idx,
`endif
  output FU_RESULT_ENTRY_t                                              fu_packet_out,
  output logic                                                          fu_valid
);

`ifdef SYNTH_TEST
  logic                                              last_done;
  logic [63:0]                                       product_out;
  logic [4:0]                                        last_dest_idx;
  logic [$clog2(`NUM_PR)-1:0]                        last_T_idx;
  logic [$clog2(`NUM_ROB)-1:0]                       last_ROB_idx;
  logic [$clog2(`NUM_FL)-1:0]                        last_FL_idx;
  logic [((`NUM_MULT_STAGE-1)*64)-1:0]               internal_T1_values, internal_T2_values;
  logic [`NUM_MULT_STAGE-2:0]                        internal_valids;
  logic [`NUM_MULT_STAGE-3:0]                        internal_dones;
  logic [5*(`NUM_MULT_STAGE-2)-1:0]                  internal_dest_idx;
  logic [($clog2(`NUM_PR)*(`NUM_MULT_STAGE-2))-1:0]  internal_T_idx;
  logic [($clog2(`NUM_ROB)*(`NUM_MULT_STAGE-2))-1:0] internal_ROB_idx;
  logic [($clog2(`NUM_FL)*(`NUM_MULT_STAGE-2))-1:0]  internal_FL_idx;
`endif
  logic [63:0]                                       mcand_out, mplier_out, regA, regB;
  logic [((`NUM_MULT_STAGE-1)*64)-1:0]               internal_products, internal_mcands, internal_mpliers, next_products;

  assign regA = fu_packet.T1_value;

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
    .dest_idx({fu_packet_out.dest_idx, internal_dest_idx, fu_packet.dest_idx}),
    .T_idx({fu_packet_out.T_idx, internal_T_idx, fu_packet.T_idx}),
    .ROB_idx({fu_packet_out.ROB_idx, internal_ROB_idx, fu_packet.ROB_idx}),
    .FL_idx({fu_packet_out.FL_idx, internal_FL_idx,  fu_packet.FL_idx}),
    .rollback_en({`NUM_MULT_STAGE{rollback_en}}),
    .ROB_rollback_idx({`NUM_MULT_STAGE{ROB_rollback_idx}}),
    .diff_ROB({`NUM_MULT_STAGE{diff_ROB}}),
`ifndef SYNTH_TEST
    .T1_value({internal_T1_values, regA}),
    .T2_value({internal_T2_values, regB}),
    .T1_value_out({T1_value, internal_T1_values}),
    .T2_value_out({T2_value, internal_T2_values}),
`endif
    // Ouput
    .product_out({product_out, internal_products}),
    .mplier_out({mplier_out, internal_mpliers}),
    .mcand_out({mcand_out, internal_mcands}),
    .done({last_done, fu_packet_out.done, internal_dones}),
    .valid_out({internal_valids, fu_valid}),
    .next_product({fu_packet_out.result, next_products}),
    .dest_idx_out({last_dest_idx, fu_packet_out.dest_idx, internal_dest_idx}),
    .T_idx_out({last_T_idx, fu_packet_out.T_idx, internal_T_idx}),
    .ROB_idx_out({last_ROB_idx, fu_packet_out.ROB_idx, internal_ROB_idx}),
    .FL_idx_out({last_FL_idx, fu_packet_out.FL_idx, internal_FL_idx})
  );

endmodule

module br(
  input  logic             clock, reset,
  input  FU_PACKET_IN_t    fu_packet,
  input  logic             CDB_valid,
  output FU_RESULT_ENTRY_t fu_packet_out,
  output                   fu_valid,
  output logic             take_branch
);

  logic result;
  logic [63:0] regA, regB;
  assign fu_valid = CDB_valid || !fu_packet.ready;
  assign take_branch = fu_packet.uncond_branch || (fu_packet.cond_branch && result);

  always_comb begin
    if(fu_packet.ready == `TRUE) begin
      case (fu_packet.inst.r.br_func)                                               // 'full-case'  All cases covered, no need for a default
        2'b00: result = (regA[0] == 0);                               // LBC: (lsb(opa) == 0) ?
        2'b01: result = (regA == 0);                                  // EQ: (opa == 0) ?
        2'b10: result = (regA[63] == 1);                              // LT: (signed(opa) < 0) : check sign bit
        2'b11: result = (regA[63] == 1) || (regA == 0); // LE: (signed(opa) <= 0)
      endcase
      // negate cond if func[2] is set
      if (fu_packet.inst.r.br_func[2]) begin
        result = ~result;
      end
    end
  end

  always_comb begin
    regA = 64'hbaadbeefdeadbeef;
    case (fu_packet.T1_select)
      ALU_OPA_IS_NPC:      regA = fu_packet.NPC;
      ALU_OPA_IS_NOT3:     regA = ~64'h3;
    endcase
  end

  always_comb begin
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

    fu_packet_out.dest_idx = fu_packet.dest_idx;
    fu_packet_out.T_idx    = fu_packet.T_idx;
    fu_packet_out.ROB_idx  = fu_packet.ROB_idx;
    fu_packet_out.FL_idx   = fu_packet.FL_idx;
    fu_packet_out.done     = fu_packet.ready;

  end

endmodule // brcond

module FU (
  input  logic                                  clock,               // system clock
  input  logic                                  reset,               // system reset
  input  FU_M_PACKET_IN                         fu_m_packet_in,
  input  logic           [$clog2(`NUM_ROB)-1:0] ROB_tail_idx,
  input  logic           [`NUM_FU-1:0]          CDB_valid,
  output FU_M_PACKET_OUT                        fu_m_packet_out,
  output logic           [`NUM_FU-1:0]          fu_valid,
  output logic                                  rollback_en,
  output logic           [$clog2(`NUM_ROB)-1:0] ROB_rollback_idx,
  output logic           [$clog2(`NUM_ROB)-1:0] diff_ROB
);

  FU_PACKET_IN_t [`NUM_FU-1:0] fu_packet_in;
  logic          [`NUM_BR-1:0] take_branch;

  assign rollback_en      = take_branch[0];
  assign ROB_rollback_idx = fu_m_packet_out.fu_result[`NUM_FU-`NUM_ALU-`NUM_MULT-`NUM_BR].ROB_idx;
  assign diff_ROB         = ROB_tail_idx - ROB_rollback_idx;

  // always_comb begin
    
  //   for (int i = 0; i < `NUM_FU; i++) begin
  //     fu_packet_in[i].ready     = fu_m_packet_in.fu_packet[i].ready;
  //     fu_packet_in[i].inst      = fu_m_packet_in.fu_packet[i].inst;
  //     fu_packet_in[i].func      = fu_m_packet_in.fu_packet[i].func;
  //     fu_packet_in[i].T_idx     = fu_m_packet_in.fu_packet[i].T_idx;
  //     // fu_packet_in[i].T1_value = pr_packet_out[i].T1_value;
  //     // fu_packet_in[i].T2_value = pr_packet_out[i].T2_value;
  //     fu_packet_in[i].T1_select = fu_m_packet_in.fu_packet[i].T1_select;
  //     fu_packet_in[i].T2_select = fu_m_packet_in.fu_packet[i].T2_select;
  //   end

  // end

  // always_comb begin
    
  //   for (int i = 0; i < `NUM_FU; i++) begin
  //     // pr_packet_in[i].S_X_T1 = fu_m_packet_in.fu_packet[i].T1_idx;
  //     // pr_packet_in[i].S_X_T2 = fu_m_packet_in.fu_packet[i].T2_idx;
  //   end

  // end

  // alu alu_0 [`NUM_ALU-1:0] (
  //   // Inputs
  //   .fu_packet(fu_packet_in[`NUM_FU-1:(`NUM_FU-`NUM_ALU)]),
  //   .CDB_valid(fu_m_packet_in.CDB_valid[`NUM_FU-1:(`NUM_FU-`NUM_ALU)]),
  //   // Output
  //   .fu_packet_out(fu_m_packet_out.fu_result[`NUM_FU-1:(`NUM_FU-`NUM_ALU)]),
  //   .fu_valid(fu_valid[`NUM_FU-1:(`NUM_FU-`NUM_ALU)])
  // );

`ifndef SYNTH_TEST
    logic [`NUM_MULT-1:0]                                             last_done;
    logic [`NUM_MULT-1:0][63:0]                                       product_out;
    logic [`NUM_MULT-1:0][4:0]                                        last_dest_idx;
    logic [`NUM_MULT-1:0][$clog2(`NUM_PR)-1:0]                        last_T_idx;
    logic [`NUM_MULT-1:0][$clog2(`NUM_ROB)-1:0]                       last_ROB_idx;
    logic [`NUM_MULT-1:0][$clog2(`NUM_FL)-1:0]                        last_FL_idx;
    logic [`NUM_MULT-1:0][63:0]                                       T1_value;
    logic [`NUM_MULT-1:0][63:0]                                       T2_value;
    logic [`NUM_MULT-1:0][((`NUM_MULT_STAGE-1)*64)-1:0]               internal_T1_values;
    logic [`NUM_MULT-1:0][((`NUM_MULT_STAGE-1)*64)-1:0]               internal_T2_values;
    logic [`NUM_MULT-1:0][`NUM_MULT_STAGE-2:0]                        internal_valids;
    logic [`NUM_MULT-1:0][`NUM_MULT_STAGE-3:0]                        internal_dones;
    logic [`NUM_MULT-1:0][5*(`NUM_MULT_STAGE-2)-1:0]                  internal_dest_idx;
    logic [`NUM_MULT-1:0][($clog2(`NUM_PR)*(`NUM_MULT_STAGE-2))-1:0]  internal_T_idx;
    logic [`NUM_MULT-1:0][($clog2(`NUM_ROB)*(`NUM_MULT_STAGE-2))-1:0] internal_ROB_idx;
    logic [`NUM_MULT-1:0][($clog2(`NUM_FL)*(`NUM_MULT_STAGE-2))-1:0]  internal_FL_idx;
`endif

  mult mult_0 [`NUM_MULT-1:0] (
    // Inputs
    .clock({`NUM_MULT{clock}}),
    .reset({`NUM_MULT{reset}}),
    .fu_packet(fu_packet_in[(`NUM_FU-`NUM_ALU-1):(`NUM_FU-`NUM_ALU-`NUM_MULT)]),
    .CDB_valid(CDB_valid[(`NUM_FU-`NUM_ALU-1):(`NUM_FU-`NUM_ALU-`NUM_MULT)]),
    .rollback_en({`NUM_MULT{rollback_en}}),
    .ROB_rollback_idx({`NUM_MULT{ROB_rollback_idx}}),
    .diff_ROB({`NUM_MULT{diff_ROB}}),
    // Outputs
`ifndef SYNTH_TEST
    .last_done(last_done),
    .product_out(product_out),
    .last_dest_idx(last_dest_idx),
    .last_T_idx(last_T_idx),
    .last_ROB_idx(last_ROB_idx),
    .last_FL_idx(last_FL_idx),
    .T1_value(T1_value),
    .T2_value(T2_value),
    .internal_T1_values(internal_T1_values),
    .internal_T2_values(internal_T2_values),
    .internal_valids(internal_valids),
    .internal_dones(internal_dones),
    .internal_dest_idx(internal_dest_idx),
    .internal_T_idx(internal_T_idx),
    .internal_ROB_idx(internal_ROB_idx),
    .internal_FL_idx(internal_FL_idx),
`endif
    .fu_packet_out(fu_m_packet_out.fu_result[(`NUM_FU-`NUM_ALU-1):(`NUM_FU-`NUM_ALU-`NUM_MULT)]),
    .fu_valid(fu_valid[(`NUM_FU-`NUM_ALU-1):(`NUM_FU-`NUM_ALU-`NUM_MULT)])
  );

  br br_0 [`NUM_BR-1:0] (
    // Inputs
    .clock({`NUM_BR{clock}}),
    .reset({`NUM_BR{reset}}),
    .fu_packet(fu_packet_in[(`NUM_FU-`NUM_ALU-`NUM_MULT-1):(`NUM_FU-`NUM_ALU-`NUM_MULT-`NUM_BR)]),
    .CDB_valid(CDB_valid[(`NUM_FU-`NUM_ALU-`NUM_MULT-1):(`NUM_FU-`NUM_ALU-`NUM_MULT-`NUM_BR)]),
    // Output
    .fu_packet_out(fu_m_packet_out.fu_result[(`NUM_FU-`NUM_ALU-`NUM_MULT-1):(`NUM_FU-`NUM_ALU-`NUM_MULT-`NUM_BR)]),
    .fu_valid(fu_valid[(`NUM_FU-`NUM_ALU-`NUM_MULT-1):(`NUM_FU-`NUM_ALU-`NUM_MULT-`NUM_BR)]),
    .take_branch(take_branch[`NUM_BR-1:0])
  );

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
