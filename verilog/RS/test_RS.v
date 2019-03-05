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
      .RS_out(RS),
      .RS_entry_match(RS_entry_match));

  task printRS;
    begin
      $display("-----------------------------RS OUTPUT-----------------------------");
      $display("     RS#     |    inst    |  FU  |  busy | alu func | T_idx | T1 | r | T2 | r | valid");
      for(int i = 0; i < `NUM_LD; i++) begin
        $display(" %d |  %h  |  LD  |   %d   |    %h    |  %h   | %h | %b | %h | %b | %b",
                i,
                RS[i].inst,
                RS[i].busy,
                RS[i].func,
                RS[i].T_idx,
                RS[i].T1.idx,
                RS[i].T1.ready,
                RS[i].T2.idx,
                RS[i].T2.ready,
                RS_entry_match[i]);
      end
      for(int i = `NUM_LD; i < (`NUM_LD + `NUM_ST); i++) begin
        $display(" %d |  %h  |  ST  |   %d   |    %h    |  %h   | %h | %b | %h | %b | %b",
                i,
                RS[i].inst,
                RS[i].busy,
                RS[i].func,
                RS[i].T_idx,
                RS[i].T1.idx,
                RS[i].T1.ready,
                RS[i].T2.idx,
                RS[i].T2.ready,
                RS_entry_match[i]);
      end
      for(int i = (`NUM_LD + `NUM_ST); i < (`NUM_LD + `NUM_ST + `NUM_BR); i++) begin
        $display(" %d |  %h  |  BR  |   %d   |    %h    |  %h   | %h | %b | %h | %b | %b",
                i,
                RS[i].inst,
                RS[i].busy,
                RS[i].func,
                RS[i].T_idx,
                RS[i].T1.idx,
                RS[i].T1.ready,
                RS[i].T2.idx,
                RS[i].T2.ready,
                RS_entry_match[i]);
      end
      for(int i = (`NUM_LD + `NUM_ST + `NUM_BR); i < (`NUM_LD + `NUM_ST + `NUM_BR + `NUM_MULT); i++) begin
        $display(" %d |  %h  | MULT |   %d   |    %h    |  %h   | %h | %b | %h | %b | %b",
                i,
                RS[i].inst,
                RS[i].busy,
                RS[i].func,
                RS[i].T_idx,
                RS[i].T1.idx,
                RS[i].T1.ready,
                RS[i].T2.idx,
                RS[i].T2.ready,
                RS_entry_match[i]);
      end
      for(int i = (`NUM_LD + `NUM_ST + `NUM_BR + `NUM_MULT); i < (`NUM_LD + `NUM_ST + `NUM_BR + `NUM_MULT + `NUM_ALU); i++) begin
        $display(" %d |  %h  |  ALU |   %d   |    %h    |  %h   | %h | %b | %h | %b | %b",
                i,
                RS[i].inst,
                RS[i].busy,
                RS[i].func,
                RS[i].T_idx,
                RS[i].T1.idx,
                RS[i].T1.ready,
                RS[i].T2.idx,
                RS[i].T2.ready,
                RS_entry_match[i]);
      end
      $display("-----------------------------RS END--------------------------------");
    end
  endtask

  task printOut;
    begin
      $display("-----------------------------FU OUTPUT-----------------------------");
      $display("     FU#    |   inst   |  FU  | ready | alu func |  T_idx | T1 | T2");
      for(int i = 0; i < `NUM_LD; i++) begin
        $display("%d | %h |  LD  |   %b   |    %h    |   %h   | %h | %h ",
                i,
                rs_packet_out.FU_packet_out[i].inst,
                rs_packet_out.FU_packet_out[i].ready,
                rs_packet_out.FU_packet_out[i].func,
                rs_packet_out.FU_packet_out[i].T_idx,
                rs_packet_out.FU_packet_out[i].T1_idx,
                rs_packet_out.FU_packet_out[i].T2_idx);
      end
      for(int i = `NUM_LD; i < (`NUM_LD + `NUM_ST); i++) begin
        $display("%d | %h |  LD  |   %b   |    %h    |   %h   | %h | %h ",
                i,
                rs_packet_out.FU_packet_out[i].inst,
                rs_packet_out.FU_packet_out[i].ready,
                rs_packet_out.FU_packet_out[i].func,
                rs_packet_out.FU_packet_out[i].T_idx,
                rs_packet_out.FU_packet_out[i].T1_idx,
                rs_packet_out.FU_packet_out[i].T2_idx);
      end
      for(int i = (`NUM_LD + `NUM_ST); i < (`NUM_LD + `NUM_ST + `NUM_BR); i++) begin
        $display("%d | %h |  LD  |   %b   |    %h    |   %h   | %h | %h ",
                i,
                rs_packet_out.FU_packet_out[i].inst,
                rs_packet_out.FU_packet_out[i].ready,
                rs_packet_out.FU_packet_out[i].func,
                rs_packet_out.FU_packet_out[i].T_idx,
                rs_packet_out.FU_packet_out[i].T1_idx,
                rs_packet_out.FU_packet_out[i].T2_idx);
      end
      for(int i = (`NUM_LD + `NUM_ST + `NUM_BR); i < (`NUM_LD + `NUM_ST + `NUM_BR + `NUM_MULT); i++) begin
        $display("%d | %h |  LD  |   %b   |    %h    |   %h   | %h | %h ",
                i,
                rs_packet_out.FU_packet_out[i].inst,
                rs_packet_out.FU_packet_out[i].ready,
                rs_packet_out.FU_packet_out[i].func,
                rs_packet_out.FU_packet_out[i].T_idx,
                rs_packet_out.FU_packet_out[i].T1_idx,
                rs_packet_out.FU_packet_out[i].T2_idx);
      end
      for(int i = (`NUM_LD + `NUM_ST + `NUM_BR + `NUM_MULT); i < (`NUM_LD + `NUM_ST + `NUM_BR + `NUM_MULT + `NUM_ALU); i++) begin
        $display("%d | %h |  LD  |   %b   |    %h    |   %h   | %h | %h ",
                i,
                rs_packet_out.FU_packet_out[i].inst,
                rs_packet_out.FU_packet_out[i].ready,
                rs_packet_out.FU_packet_out[i].func,
                rs_packet_out.FU_packet_out[i].T_idx,
                rs_packet_out.FU_packet_out[i].T1_idx,
                rs_packet_out.FU_packet_out[i].T2_idx);
      end
      $display("-----------------------------FU END--------------------------------\n\n");
    end
  endtask

  task printInput;
    begin
      $display("---------------------------INPUT START----------------------------");
      $display(" RESET | en | dest_idx | t1_idx | t1_ready | t2_idx | t2_ready | complete en | dispatch en |   FU   |  func  | CDB_t | inst");
      $display("   %b   |  %b |    %h    |   %h   |    %b     |   %h   |    %b     |      %b      |      %b      |    %h   |   %h   |  %h   | %h",
                reset,
                en,
                rs_packet_in.dest_idx,
                rs_packet_in.T1.idx,
                rs_packet_in.T1.ready,
                rs_packet_in.T2.idx,
                rs_packet_in.T2.ready,
                rs_packet_in.complete_en,
                rs_packet_in.dispatch_en,
                rs_packet_in.FU,
                rs_packet_in.func,
                rs_packet_in.CDB_T,
                rs_packet_in.inst);
      $display("---------------------------INPUT END-----------------------------");
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

      printInput();

      $display("rs hazard: %b", rs_hazard);

      $display("-----------------------WAITING FOR CYCLE------------------------");

      @(negedge clock);
      printRS();
      printOut();
    end
  endtask

  task resetRS; 
    begin
      //reset device
      reset = 1'b1;
      @(negedge clock);
      reset = 1'b0;
      @(negedge clock);
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
    rs_packet_in = 0;
    @(negedge clock);
    reset = 1'b0;
    en = 1'b1;
    
    @(negedge clock);
    //INSERTION TEST (non ready) + FU PACKET OUT
    // test insertion for all FU non of which is ready.
    setinput(0,1,`NOOP_INST,1,11,0,21,0, FU_ALU, ALU_ADDQ, 0);
    setinput(0,1,`NOOP_INST,2,12,0,22,0, FU_MULT, ALU_ADDQ, 0);
    setinput(0,1,`NOOP_INST,3,13,0,23,0, FU_BR, ALU_ADDQ, 0);
    setinput(0,1,`NOOP_INST,4,14,0,24,0, FU_ST, ALU_ADDQ, 0);
    setinput(0,1,`NOOP_INST,5,15,0,25,0, FU_LD, ALU_ADDQ, 0);

    //reset device
    resetRS();
    //INSERTION TEST (ready) + FU PACKET OUT
    // test insertion for all FU all of which is ready.
    setinput(0,1,`NOOP_INST,1,11,1,21,1, FU_ALU, ALU_ADDQ, 0);
    setinput(0,1,`NOOP_INST,2,12,1,22,1, FU_MULT, ALU_ADDQ, 0);
    setinput(0,1,`NOOP_INST,3,13,1,23,1, FU_BR, ALU_ADDQ, 0);
    setinput(0,1,`NOOP_INST,4,14,1,24,1, FU_ST, ALU_ADDQ, 0);
    setinput(0,1,`NOOP_INST,5,15,1,25,1, FU_LD, ALU_ADDQ, 0);


    //COMPLETION TEST + FU PACKET OUT
    //reset device
    resetRS();
    // fill all entries with reg 11
    setinput(0,1,`NOOP_INST,1,11,0,11,0, FU_ALU, ALU_ADDQ, 0);
    setinput(0,1,`NOOP_INST,2,11,0,11,0, FU_MULT, ALU_ADDQ, 0);
    setinput(0,1,`NOOP_INST,3,11,0,11,0, FU_BR, ALU_ADDQ, 0);
    setinput(0,1,`NOOP_INST,4,11,0,11,0, FU_ST, ALU_ADDQ, 0);
    setinput(0,1,`NOOP_INST,5,11,0,11,0, FU_LD, ALU_ADDQ, 0);

    // complete all reg 11
    setinput(1,0,`NOOP_INST,1,11,0,21,0, FU_ALU, ALU_ADDQ, 11);
    

    //TEST multiple Insert to same entry
    //reset device
    resetRS();
    // insert all FU non of which is ready.
    setinput(0,1,`NOOP_INST,1,11,0,21,0, FU_ALU, ALU_ADDQ, 0);
    setinput(0,1,`NOOP_INST,2,12,0,22,0, FU_MULT, ALU_ADDQ, 0);
    setinput(0,1,`NOOP_INST,3,13,0,23,0, FU_BR, ALU_ADDQ, 0);
    setinput(0,1,`NOOP_INST,4,14,0,24,0, FU_ST, ALU_ADDQ, 0);
    setinput(0,1,`NOOP_INST,5,15,0,25,0, FU_LD, ALU_ADDQ, 0);

    // insert all FU non of which is ready again.
    setinput(0,1,`NOOP_INST,1,31,0,41,0, FU_ALU, ALU_ADDQ, 0);
    setinput(0,1,`NOOP_INST,2,32,0,42,0, FU_MULT, ALU_ADDQ, 0);
    setinput(0,1,`NOOP_INST,3,33,0,43,0, FU_BR, ALU_ADDQ, 0);
    setinput(0,1,`NOOP_INST,4,34,0,44,0, FU_ST, ALU_ADDQ, 0);
    setinput(0,1,`NOOP_INST,5,35,0,45,0, FU_LD, ALU_ADDQ, 0);


    //TEST complete and dispatch on the same cycle
    //reset device
    resetRS();
    // fill all entries with reg 11 and dispatch at first
    setinput(1,1,`NOOP_INST,1,11,0,11,0, FU_ALU, ALU_ADDQ, 11);
    setinput(0,1,`NOOP_INST,2,11,0,11,0, FU_MULT, ALU_ADDQ, 0);
    setinput(0,1,`NOOP_INST,3,11,0,11,0, FU_BR, ALU_ADDQ, 0);
    setinput(0,1,`NOOP_INST,4,11,0,11,0, FU_ST, ALU_ADDQ, 0);
    setinput(0,1,`NOOP_INST,5,11,0,11,0, FU_LD, ALU_ADDQ, 0);

    // fill all entries with reg 12 and dispacth at all
    setinput(0,1,`NOOP_INST,1,12,0,12,0, FU_ALU, ALU_ADDQ, 0);
    setinput(0,1,`NOOP_INST,2,12,0,12,0, FU_MULT, ALU_ADDQ, 0);
    setinput(0,1,`NOOP_INST,3,12,0,12,0, FU_BR, ALU_ADDQ, 0);
    setinput(0,1,`NOOP_INST,4,12,0,12,0, FU_ST, ALU_ADDQ, 0);
    setinput(1,1,`NOOP_INST,5,12,0,12,0, FU_LD, ALU_ADDQ, 12);


    //TEST complete nothing
    //reset device
    resetRS();
    // insert for all FU non of which is ready.
    setinput(0,1,`NOOP_INST,1,11,0,21,0, FU_ALU, ALU_ADDQ, 0);
    setinput(0,1,`NOOP_INST,2,12,0,22,0, FU_MULT, ALU_ADDQ, 0);
    setinput(0,1,`NOOP_INST,3,13,0,23,0, FU_BR, ALU_ADDQ, 0);
    setinput(0,1,`NOOP_INST,4,14,0,24,0, FU_ST, ALU_ADDQ, 0);
    setinput(0,1,`NOOP_INST,5,15,0,25,0, FU_LD, ALU_ADDQ, 0);

    // complete stage
    setinput(1,0,`NOOP_INST,3,4,0,5,1, FU_ALU, ALU_ADDQ, 45);
    

    //TEST EN off
    //reset device
    resetRS();
    //turn enable off
    en = 1'b0;

    // insert for all FU non of which is ready.
    setinput(0,1,`NOOP_INST,1,11,0,21,0, FU_ALU, ALU_ADDQ, 0);
    setinput(0,1,`NOOP_INST,2,12,0,22,0, FU_MULT, ALU_ADDQ, 0);
    setinput(0,1,`NOOP_INST,3,13,0,23,0, FU_BR, ALU_ADDQ, 0);
    setinput(0,1,`NOOP_INST,4,14,0,24,0, FU_ST, ALU_ADDQ, 0);
    setinput(0,1,`NOOP_INST,5,15,0,25,0, FU_LD, ALU_ADDQ, 0);

    //turn enable on
    en = 1'b1;

    // fill all entries with reg 11
    setinput(0,1,`NOOP_INST,1,11,0,11,0, FU_ALU, ALU_ADDQ, 0);
    setinput(0,1,`NOOP_INST,2,11,0,11,0, FU_MULT, ALU_ADDQ, 0);
    setinput(0,1,`NOOP_INST,3,11,0,11,0, FU_BR, ALU_ADDQ, 0);
    setinput(0,1,`NOOP_INST,4,11,0,11,0, FU_ST, ALU_ADDQ, 0);
    setinput(0,1,`NOOP_INST,5,11,0,11,0, FU_LD, ALU_ADDQ, 0);

    //turn enable off
    en = 1'b0;

    // complete all reg 11
    setinput(1,0,`NOOP_INST,1,11,0,21,0, FU_ALU, ALU_ADDQ, 11);

    //turn enable on
    en = 1'b1;

    // complete all reg 11
    setinput(1,0,`NOOP_INST,1,11,0,21,0, FU_ALU, ALU_ADDQ, 11);

    $finish;
  end
endmodule  // module test_RS

