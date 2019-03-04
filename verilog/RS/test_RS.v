/////////////////////////////////////////////////////////////////////////
//                                                                     //
//                                                                     //
//   Modulename :  testbench_ROB.v                                     //
//                                                                     //
//  Description :  Testbench module for ROB module;                    //
//                                                                     //
//                                                                     //
/////////////////////////////////////////////////////////////////////////

`timescale 1ns/100ps

`include "RS.vh"

module test_RS;
  // UUT input signals
  logic clock, reset, en;
  RS_PACKET_IN rs_packet_in;

  RS_ENTRY_t [`NUM_FU-1:0] RS;

  logic [`NUM_FU-1:0] RS_entry_match;
  // UUT output signals
  logic rs_hazard;
  RS_PACKET_OUT rs_packet_out, correct_packet_out;

  RS UUT(.clock(clock),
      .reset(reset),
      .en(en),
      .rs_packet_in(rs_packet_in),
      .rs_hazard(rs_hazard),
      .rs_packet_out(rs_packet_out),
      .RS_out(RS)
      .RS_entry_match(RS_entry_match));

  task printRS;
    begin
      $display("     RS#     |    inst    |  FU  |  busy | alu func | T_idx | T1 | r | T2 | r | hazard");
      for(int i = 0; i < `NUM_LD; i++) begin
        $display(" %d |  %h  |  LD  |   %d   |    %h    |  %h   | %h | %b | %h | %b | hazard",
                i,
                RS[i].inst,
                RS[i].busy,
                RS[i].func,
                RS[i].T_idx,
                RS[i].T1.idx,
                RS[i].T1.ready,
                RS[i].T2.idx,
                RS[i].T2.ready,
                RS_entry_match);
      end
      for(int i = `NUM_LD; i < (`NUM_LD + `NUM_ST); i++) begin
        $display(" %d |  %h  |  ST  |   %d   |    %h    |  %h   | %h | %b | %h | %b | hazard",
                i,
                RS[i].inst,
                RS[i].busy,
                RS[i].func,
                RS[i].T_idx,
                RS[i].T1.idx,
                RS[i].T1.ready,
                RS[i].T2.idx,
                RS[i].T2.ready,
                RS_entry_match);
      end
      for(int i = (`NUM_LD + `NUM_ST); i < (`NUM_LD + `NUM_ST + `NUM_BR); i++) begin
        $display(" %d |  %h  |  BR  |   %d   |    %h    |  %h   | %h | %b | %h | %b | hazard",
                i,
                RS[i].inst,
                RS[i].busy,
                RS[i].func,
                RS[i].T_idx,
                RS[i].T1.idx,
                RS[i].T1.ready,
                RS[i].T2.idx,
                RS[i].T2.ready,
                RS_entry_match);
      end
      for(int i = (`NUM_LD + `NUM_ST + `NUM_BR); i < (`NUM_LD + `NUM_ST + `NUM_BR + `NUM_MULT); i++) begin
        $display(" %d |  %h  | MULT |   %d   |    %h    |  %h   | %h | %b | %h | %b | hazard",
                i,
                RS[i].inst,
                RS[i].busy,
                RS[i].func,
                RS[i].T_idx,
                RS[i].T1.idx,
                RS[i].T1.ready,
                RS[i].T2.idx,
                RS[i].T2.ready,
                RS_entry_match);
      end
      for(int i = (`NUM_LD + `NUM_ST + `NUM_BR + `NUM_MULT); i < (`NUM_LD + `NUM_ST + `NUM_BR + `NUM_MULT + `NUM_ALU); i++) begin
        $display(" %d |  %h  |  ALU |   %d   |    %h    |  %h   | %h | %b | %h | %b | hazard",
                i,
                RS[i].inst,
                RS[i].busy,
                RS[i].func,
                RS[i].T_idx,
                RS[i].T1.idx,
                RS[i].T1.ready,
                RS[i].T2.idx,
                RS[i].T2.ready,
                RS_entry_match);
      end
    end
  endtask

  task setinput(logic complete_en,
                logic dispatch_en,
                INST_t inst,
                logic [$clog2(`NUM_PR)-1:0] dest_idx,
                logic [$clog2(`NUM_PR)-1:0] t1_idx,
                logic t1_ready,
                logic [$clog2(`NUM_PR)-1:0] t2_idx,
                logic t2_ready,
                FU_t FU,
                ALU_FUNC func,
                logic [$clog2(`NUM_PR)-1:0] CDB_T);
    begin
      rs_packet_in.dest_idx = dest_idx;
      rs_packet_in.T1.idx = t1_idx;
      rs_packet_in.T1.ready = t1_ready;
      rs_packet_in.T2.idx = t2_idx;
      rs_packet_in.T2.ready = t2_ready;
      rs_packet_in.complete_en = complete_en;
      rs_packet_in.dispatch_en = dispatch_en;
      rs_packet_in.FU = FU;
      rs_packet_in.func = func;
      rs_packet_in.CDB_T = CDB_T;
      rs_packet_in.inst = inst;

      @(negedge clock);
      printRS();
    end
  endtask

  always begin
    #(`VERILOG_CLOCK_PERIOD/2.0);
    clock = ~clock;
  end

// 	typedef enum logic [2:0] {
//   FU_ALU  = 3'b000,
//   FU_ST   = 3'b001,
//   FU_LD   = 3'b010,
//   FU_MULT = 3'b011,
//   FU_BR   = 3'b100
// } FU_t;

// typedef enum logic [4:0] {
//   ALU_ADDQ      = 5'h00,
//   ALU_SUBQ      = 5'h01,
//   ALU_AND       = 5'h02,
//   ALU_BIC       = 5'h03,
//   ALU_BIS       = 5'h04,
//   ALU_ORNOT     = 5'h05,
//   ALU_XOR       = 5'h06,
//   ALU_EQV       = 5'h07,
//   ALU_SRL       = 5'h08,
//   ALU_SLL       = 5'h09,
//   ALU_SRA       = 5'h0a,
//   ALU_MULQ      = 5'h0b,
//   ALU_CMPEQ     = 5'h0c,
//   ALU_CMPLT     = 5'h0d,
//   ALU_CMPLE     = 5'h0e,
//   ALU_CMPULT    = 5'h0f,
//   ALU_CMPULE    = 5'h10
// } ALU_FUNC;

  // reset
  initial begin
    en = 1'b0;
    clock = 1'b0;
    reset = 1'b1;
    @(negedge clock);
    reset = 1'b0;
    en = 1'b0;
    
    @(negedge clock);
    setinput(0,1,`NOOP_INST,1,1,0,2,0, FU_ALU, ALU_ADDQ, 0);

    setinput(0,1,`NOOP_INST,2,4,1,5,0, FU_ALU, ALU_ADDQ, 0);

    setinput(0,1,`NOOP_INST,3,4,0,5,1, FU_ALU, ALU_ADDQ, 0);
    
    $finish;
  end
endmodule  // module test_RS

