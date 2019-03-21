`timescale 1ns/100ps

`include "RS.vh"

module test_RS;
  // UUT input signals
  logic clock, reset, en;
  RS_PACKET_IN rs_packet_in;


  // UUT output signals
  RS_PACKET_OUT rs_packet_out, correct_packet_out;

  RS_ENTRY_t [`NUM_FU-1:0] RS;
  logic [`NUM_FU-1:0] RS_entry_match;

  RS UUT(.clock(clock),
      .reset(reset),
      .en(en),
      .rs_packet_in(rs_packet_in),
      .rs_packet_out(rs_packet_out),
      .RS_out(RS),
      .RS_entry_match(RS_entry_match));

  task printRS;
    begin
      $display("-----------------------------RS OUTPUT-----------------------------");
      $display("     RS#     | RS_type  | busy |   inst   | func |        NPC       | ROB_idx | Fl_idx | T_idx | T1.idx | T1.ready | T2.idx | T2.ready | T1_select | T2_select | Entry ready");
      for(int i = 0; i < `NUM_LD; i++) begin
        $display(" %d |    LD    |  %b   | %h |  %h  | %h |    %d   |   %d   |   %d  |   %d   |     %b    |    %d    |     %b    |    %h     |     %h    | %d",
                i,
                RS[i].busy,
                RS[i].inst,
                RS[i].func,
                RS[i].NPC,
                RS[i].ROB_idx,
                RS[i].FL_idx,
                RS[i].T_idx,
                RS[i].T1.idx,
                RS[i].T1.ready,
                RS[i].T2.idx,
                RS[i].T2.ready,
                RS[i].T1_select,
                RS[i].T2_select,
                RS_entry_match[i]);
      end
      for(int i = `NUM_LD; i < (`NUM_LD + `NUM_ST); i++) begin
        $display(" %d |    ST    |  %b   | %h |  %h  | %h |    %d   |   %d   |   %d  |   %d   |     %b    |    %d    |     %b    |    %h     |     %h    | %d",
                i,
                RS[i].busy,
                RS[i].inst,
                RS[i].func,
                RS[i].NPC,
                RS[i].ROB_idx,
                RS[i].FL_idx,
                RS[i].T_idx,
                RS[i].T1.idx,
                RS[i].T1.ready,
                RS[i].T2.idx,
                RS[i].T2.ready,
                RS[i].T1_select,
                RS[i].T2_select,
                RS_entry_match[i]);
      end
      for(int i = (`NUM_LD + `NUM_ST); i < (`NUM_LD + `NUM_ST + `NUM_BR); i++) begin
        $display(" %d |    BR    |  %b   | %h |  %h  | %h |    %d   |   %d   |   %d  |   %d   |     %b    |    %d    |     %b    |    %h     |     %h    | %d",
                i,
                RS[i].busy,
                RS[i].inst,
                RS[i].func,
                RS[i].NPC,
                RS[i].ROB_idx,
                RS[i].FL_idx,
                RS[i].T_idx,
                RS[i].T1.idx,
                RS[i].T1.ready,
                RS[i].T2.idx,
                RS[i].T2.ready,
                RS[i].T1_select,
                RS[i].T2_select,
                RS_entry_match[i]);
      end
      for(int i = (`NUM_LD + `NUM_ST + `NUM_BR); i < (`NUM_LD + `NUM_ST + `NUM_BR + `NUM_MULT); i++) begin
        $display(" %d |   MULT   |  %b   | %h |  %h  | %h |    %d   |   %d   |   %d  |   %d   |     %b    |    %d    |     %b    |    %h     |     %h    | %d",
                i,
                RS[i].busy,
                RS[i].inst,
                RS[i].func,
                RS[i].NPC,
                RS[i].ROB_idx,
                RS[i].FL_idx,
                RS[i].T_idx,
                RS[i].T1.idx,
                RS[i].T1.ready,
                RS[i].T2.idx,
                RS[i].T2.ready,
                RS[i].T1_select,
                RS[i].T2_select,
                RS_entry_match[i]);
      end
      for(int i = (`NUM_LD + `NUM_ST + `NUM_BR + `NUM_MULT); i < (`NUM_LD + `NUM_ST + `NUM_BR + `NUM_MULT + `NUM_ALU); i++) begin
        $display(" %d |    ALU   |  %b   | %h |  %h  | %h |    %d   |   %d   |   %d  |   %d   |     %b    |    %d    |     %b    |    %h     |     %h    | %d",
                i,
                RS[i].busy,
                RS[i].inst,
                RS[i].func,
                RS[i].NPC,
                RS[i].ROB_idx,
                RS[i].FL_idx,
                RS[i].T_idx,
                RS[i].T1.idx,
                RS[i].T1.ready,
                RS[i].T2.idx,
                RS[i].T2.ready,
                RS[i].T1_select,
                RS[i].T2_select,
                RS_entry_match[i]);
      end
      $display("-----------------------------RS END--------------------------------");
    end
  endtask

  task printOut;
    begin
      $display("-----------------------------FU OUTPUT-----------------------------");
      $display("     FU#    |   IT   | ready |   inst   | func |        NPC        | ROB_idx | FL_idx | T_idx | T1_idx | T2_idx | T1_select | T2_select");
      for(int i = 0; i < `NUM_LD; i++) begin
        $display("%d |   LD   |   %b   | %h |  %h  | %h |    %d   |   %d   |   %d   |   %d   |   %d   |     %h     |     %h     |",
                i,
                rs_packet_out.FU_packet_out[i].ready,
                rs_packet_out.FU_packet_out[i].inst,
                rs_packet_out.FU_packet_out[i].func,
                rs_packet_out.FU_packet_out[i].NPC,
                rs_packet_out.FU_packet_out[i].ROB_idx,
                rs_packet_out.FU_packet_out[i].FL_idx,
                rs_packet_out.FU_packet_out[i].T_idx,
                rs_packet_out.FU_packet_out[i].T1_idx,
                rs_packet_out.FU_packet_out[i].T2_idx,
                rs_packet_out.FU_packet_out[i].T1_select,
                rs_packet_out.FU_packet_out[i].T2_select);
      end
      for(int i = `NUM_LD; i < (`NUM_LD + `NUM_ST); i++) begin
        $display("%d |   ST   |   %b   | %h |  %h  | %h |    %d   |    %d   |    %d   |    %d   |    %d   |     %h     |     %h     |",
                i,
                rs_packet_out.FU_packet_out[i].ready,
                rs_packet_out.FU_packet_out[i].inst,
                rs_packet_out.FU_packet_out[i].func,
                rs_packet_out.FU_packet_out[i].NPC,
                rs_packet_out.FU_packet_out[i].ROB_idx,
                rs_packet_out.FU_packet_out[i].FL_idx,
                rs_packet_out.FU_packet_out[i].T_idx,
                rs_packet_out.FU_packet_out[i].T1_idx,
                rs_packet_out.FU_packet_out[i].T2_idx,
                rs_packet_out.FU_packet_out[i].T1_select,
                rs_packet_out.FU_packet_out[i].T2_select);
      end
      for(int i = (`NUM_LD + `NUM_ST); i < (`NUM_LD + `NUM_ST + `NUM_BR); i++) begin
        $display("%d |   BR   |   %b   | %h |  %h  | %h |    %d   |    %d   |    %d   |    %d   |    %d   |     %h     |     %h     |",
                i,
                rs_packet_out.FU_packet_out[i].ready,
                rs_packet_out.FU_packet_out[i].inst,
                rs_packet_out.FU_packet_out[i].func,
                rs_packet_out.FU_packet_out[i].NPC,
                rs_packet_out.FU_packet_out[i].ROB_idx,
                rs_packet_out.FU_packet_out[i].FL_idx,
                rs_packet_out.FU_packet_out[i].T_idx,
                rs_packet_out.FU_packet_out[i].T1_idx,
                rs_packet_out.FU_packet_out[i].T2_idx,
                rs_packet_out.FU_packet_out[i].T1_select,
                rs_packet_out.FU_packet_out[i].T2_select);
      end
      for(int i = (`NUM_LD + `NUM_ST + `NUM_BR); i < (`NUM_LD + `NUM_ST + `NUM_BR + `NUM_MULT); i++) begin
        $display("%d |  MULT  |   %b   | %h |  %h  | %h |    %d   |    %d   |    %d   |    %d   |    %d   |     %h     |     %h     |",
                i,
                rs_packet_out.FU_packet_out[i].ready,
                rs_packet_out.FU_packet_out[i].inst,
                rs_packet_out.FU_packet_out[i].func,
                rs_packet_out.FU_packet_out[i].NPC,
                rs_packet_out.FU_packet_out[i].ROB_idx,
                rs_packet_out.FU_packet_out[i].FL_idx,
                rs_packet_out.FU_packet_out[i].T_idx,
                rs_packet_out.FU_packet_out[i].T1_idx,
                rs_packet_out.FU_packet_out[i].T2_idx,
                rs_packet_out.FU_packet_out[i].T1_select,
                rs_packet_out.FU_packet_out[i].T2_select);
      end
      for(int i = (`NUM_LD + `NUM_ST + `NUM_BR + `NUM_MULT); i < (`NUM_LD + `NUM_ST + `NUM_BR + `NUM_MULT + `NUM_ALU); i++) begin
        $display("%d |  ALU   |   %b   | %h |  %h  | %h |    %d   |    %d   |    %d   |    %d   |    %d   |     %h     |     %h     |",
                i,
                rs_packet_out.FU_packet_out[i].ready,
                rs_packet_out.FU_packet_out[i].inst,
                rs_packet_out.FU_packet_out[i].func,
                rs_packet_out.FU_packet_out[i].NPC,
                rs_packet_out.FU_packet_out[i].ROB_idx,
                rs_packet_out.FU_packet_out[i].FL_idx,
                rs_packet_out.FU_packet_out[i].T_idx,
                rs_packet_out.FU_packet_out[i].T1_idx,
                rs_packet_out.FU_packet_out[i].T2_idx,
                rs_packet_out.FU_packet_out[i].T1_select,
                rs_packet_out.FU_packet_out[i].T2_select);
      end
      $display("-----------------------------FU END--------------------------------");
    end
  endtask

  task printInput;
    begin
      $display("---------------------------INPUT START----------------------------");
      $display(" RESET | en | T_idx |   inst   |        NPC       | ROB_idx | Fl_idx | T1 | T1.ready | T2 | complete_en | dispatch_en | FU | func | T1_select | T2_select | CDB_T | fu_valid | ROB_rollback_idx | ROB_tail_idx | rollback_en");
      $display("   %b   |  %b |  %d   | %h | %h |    %d   |   %d   | %d |     %b    | %d |     %b    |      %b      |      %b      | %d  |  %h  |     %h     |     %h     |   %d  |     %b    |        %d       |    %d     | %b",
                reset,
                en,
                rs_packet_in.T_idx,
                rs_packet_in.inst,
                rs_packet_in.NPC,
                rs_packet_in.ROB_idx,
                rs_packet_in.FL_idx,
                rs_packet_in.T1.idx,
                rs_packet_in.T1.ready,
                rs_packet_in.T2.idx,
                rs_packet_in.T2.ready,
                rs_packet_in.complete_en,
                rs_packet_in.dispatch_en,
                rs_packet_in.FU,
                rs_packet_in.func,
                rs_packet_in.T1_select,
                rs_packet_in.T2_select,
                rs_packet_in.CDB_T,
                rs_packet_in.fu_valid,
                rs_packet_in.ROB_rollback_idx,
                rs_packet_in.ROB_tail_idx,
                rs_packet_in.rollback_en);
      $display("---------------------------INPUT END-----------------------------");
    end
  endtask

  task setFUDone(logic ALUdone, logic MULTdone, logic BRdone, logic STdone, logic LDdone);
    begin
      $display("---------------------------CHANGE FU-----------------------------");
      $display("ALU: %b MULT: %b BR: %b ST: %b LD: %b", ALUdone, MULTdone, BRdone, STdone, LDdone);
      rs_packet_in.fu_valid = '{
        {`NUM_ALU{ALUdone}},
        {`NUM_MULT{MULTdone}},
        {`NUM_BR{BRdone}},
        {`NUM_ST{STdone}},
        {`NUM_LD{LDdone}}
      };
    end
  endtask

  task setinput(  logic          [$clog2(`NUM_PR)-1:0]  T_idx_in,
                  INST_t                                inst_in,
                  logic          [63:0]                 NPC_in,
                  logic          [$clog2(`NUM_ROB)-1:0] ROB_idx_in,
                  logic          [$clog2(`NUM_FL)-1:0]  FL_idx_in,
                  logic          [$clog2(`NUM_PR)-1:0]  T1_idx_in,
                  logic                                 T1_ready_in,
                  logic          [$clog2(`NUM_PR)-1:0]  T2_idx_in,
                  logic                                 T2_ready_in,
                  logic                                 complete_en_in,
                  logic                                 dispatch_en_in,
                  FU_t                                  FU_in,
                  ALU_FUNC                              func_in,
                  ALU_OPA_SELECT                        T1_select_in,
                  ALU_OPB_SELECT                        T2_select_in,
                  logic          [$clog2(`NUM_PR)-1:0]  CDB_T_in,
                  logic          [`NUM_FU-1:0]          fu_valid_in,
                  logic          [$clog2(`NUM_ROB)-1:0] ROB_rollback_idx_in,
                  logic          [$clog2(`NUM_ROB)-1:0] ROB_tail_idx_in,
                  logic                                 rollback_en_in);
    begin
      rs_packet_in.T_idx = T_idx_in;
      rs_packet_in.inst = inst_in;
      rs_packet_in.NPC = NPC_in;
      rs_packet_in.ROB_idx = ROB_idx_in;
      rs_packet_in.FL_idx = FL_idx_in;
      rs_packet_in.T1.idx = T1_idx_in;
      rs_packet_in.T1.ready = T1_ready_in;
      rs_packet_in.T2.idx = T2_idx_in;
      rs_packet_in.T2.ready = T2_ready_in;
      rs_packet_in.complete_en = complete_en_in;
      rs_packet_in.dispatch_en = dispatch_en_in;
      rs_packet_in.FU = FU_in;
      rs_packet_in.func = func_in;
      rs_packet_in.T1_select = T1_select_in;
      rs_packet_in.T2_select = T2_select_in;
      rs_packet_in.CDB_T = CDB_T_in;
      rs_packet_in.fu_valid = fu_valid_in;
      rs_packet_in.ROB_rollback_idx = ROB_rollback_idx_in;
      rs_packet_in.ROB_tail_idx = ROB_tail_idx_in;
      rs_packet_in.rollback_en = rollback_en_in;

      printInput();
      printOut();

      @(negedge clock);

      printRS();
      $display("-----------------------WAITING FOR CYCLE------------------------");

      $display("\n\n\n");
    end
  endtask

  task resetRS; 
    begin
      //reset device
      reset = 1'b1;
      setinput(0,0,`NOOP_INST,1,11,0,21,0, FU_ALU, ALU_ADDQ, 0);
      @(negedge clock);
      reset = 1'b0;
      // @(negedge clock);
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
    $monitor("RS hazard: %b", rs_hazard);

    
//     en = 1'b0;
//     clock = 1'b0;
//     reset = 1'b1;
//     rs_packet_in = 0;
//     @(negedge clock);
//     reset = 1'b0;
//     en = 1'b1;
    
//     @(negedge clock);
//     $display("INSERTION TEST (non ready) + FU PACKET OUT");
//     // test insertion for all FU non of which is ready.
//     setFUDone(1,1,1,1,1);

//     setinput(0,1,`NOOP_INST,1,11,0,21,0, FU_ALU, ALU_ADDQ, 0);
//     setinput(0,1,`NOOP_INST,2,12,0,22,0, FU_MULT, ALU_ADDQ, 0);
//     setinput(0,1,`NOOP_INST,3,13,0,23,0, FU_BR, ALU_ADDQ, 0);
//     setinput(0,1,`NOOP_INST,4,14,0,24,0, FU_ST, ALU_ADDQ, 0);
//     setinput(0,1,`NOOP_INST,5,15,0,25,0, FU_LD, ALU_ADDQ, 0);

//     setFUDone(0,0,0,0,0);

//     setinput(0,1,`NOOP_INST,1,11,0,21,0, FU_ALU, ALU_ADDQ, 0);
//     setinput(0,1,`NOOP_INST,2,12,0,22,0, FU_MULT, ALU_ADDQ, 0);
//     setinput(0,1,`NOOP_INST,3,13,0,23,0, FU_BR, ALU_ADDQ, 0);
//     setinput(0,1,`NOOP_INST,4,14,0,24,0, FU_ST, ALU_ADDQ, 0);
//     setinput(0,1,`NOOP_INST,5,15,0,25,0, FU_LD, ALU_ADDQ, 0);

//     //reset device
//     resetRS();
//     $display("INSERTION TEST (ready) + FU PACKET OUT");

//     setFUDone(1,1,1,1,1);

//     // test insertion for all FU all of which is ready.
//     setinput(0,1,`NOOP_INST,1,11,1,21,1, FU_ALU, ALU_ADDQ, 0);
//     setinput(0,1,`NOOP_INST,2,12,1,22,1, FU_MULT, ALU_ADDQ, 0);
//     setinput(0,1,`NOOP_INST,3,13,1,23,1, FU_BR, ALU_ADDQ, 0);
//     setinput(0,1,`NOOP_INST,4,14,1,24,1, FU_ST, ALU_ADDQ, 0);
//     setinput(0,1,`NOOP_INST,5,15,1,25,1, FU_LD, ALU_ADDQ, 0);

//     setFUDone(0,0,0,0,0);

//     setinput(0,1,`NOOP_INST,1,11,1,21,1, FU_ALU, ALU_ADDQ, 0);
//     setinput(0,1,`NOOP_INST,2,12,1,22,1, FU_MULT, ALU_ADDQ, 0);
//     setinput(0,1,`NOOP_INST,3,13,1,23,1, FU_BR, ALU_ADDQ, 0);
//     setinput(0,1,`NOOP_INST,4,14,1,24,1, FU_ST, ALU_ADDQ, 0);
//     setinput(0,1,`NOOP_INST,5,15,1,25,1, FU_LD, ALU_ADDQ, 0);


//     $display("COMPLETION TEST + FU PACKET OUT");

//     setFUDone(0,0,0,0,0);
//     //reset device
//     resetRS();
//     // fill all entries with reg 11
//     setinput(0,1,`NOOP_INST,1,11,0,11,0, FU_ALU, ALU_ADDQ, 0);
//     setinput(0,1,`NOOP_INST,2,11,0,11,0, FU_MULT, ALU_ADDQ, 0);
//     setinput(0,1,`NOOP_INST,3,11,0,11,0, FU_BR, ALU_ADDQ, 0);
//     setinput(0,1,`NOOP_INST,4,11,0,11,0, FU_ST, ALU_ADDQ, 0);
//     setinput(0,1,`NOOP_INST,5,11,0,11,0, FU_LD, ALU_ADDQ, 0);

//     // complete all reg 11
//     setinput(1,0,`NOOP_INST,1,11,0,21,0, FU_ALU, ALU_ADDQ, 11);
    
//     setFUDone(1,1,1,1,1);

//     @(negedge clock);
//     $display("See RS after FU all available");
//     printRS(); 


//     $display("TEST multiple Insert to same entry");
//     //reset device
//     resetRS();
//     // insert all FU non of which is ready.
//     setinput(0,1,`NOOP_INST,1,11,0,21,0, FU_ALU, ALU_ADDQ, 0);
//     setinput(0,1,`NOOP_INST,2,12,0,22,0, FU_MULT, ALU_ADDQ, 0);
//     setinput(0,1,`NOOP_INST,3,13,0,23,0, FU_BR, ALU_ADDQ, 0);
//     setinput(0,1,`NOOP_INST,4,14,0,24,0, FU_ST, ALU_ADDQ, 0);
//     setinput(0,1,`NOOP_INST,5,15,0,25,0, FU_LD, ALU_ADDQ, 0);

//     // insert all FU non of which is ready again.
//     setinput(0,1,`NOOP_INST,1,31,0,41,0, FU_ALU, ALU_ADDQ, 0);
//     setinput(0,1,`NOOP_INST,2,32,0,42,0, FU_MULT, ALU_ADDQ, 0);
//     setinput(0,1,`NOOP_INST,3,33,0,43,0, FU_BR, ALU_ADDQ, 0);
//     setinput(0,1,`NOOP_INST,4,34,0,44,0, FU_ST, ALU_ADDQ, 0);
//     setinput(0,1,`NOOP_INST,5,35,0,45,0, FU_LD, ALU_ADDQ, 0);


//     $display("TEST complete and dispatch on the same cycle");
//     setFUDone(0,0,0,0,0);
//     //reset device
//     resetRS();
//     // fill all entries with reg 11 and dispatch at first
//     setinput(1,1,`NOOP_INST,1,11,0,11,0, FU_ALU, ALU_ADDQ, 11);
//     setinput(0,1,`NOOP_INST,2,11,0,11,0, FU_MULT, ALU_ADDQ, 0);
//     setinput(0,1,`NOOP_INST,3,11,0,11,0, FU_BR, ALU_ADDQ, 0);
//     setinput(0,1,`NOOP_INST,4,11,0,11,0, FU_ST, ALU_ADDQ, 0);
//     setinput(0,1,`NOOP_INST,5,11,0,11,0, FU_LD, ALU_ADDQ, 0);

//     // fill all entries with reg 12 and dispacth at all
//     setinput(0,1,`NOOP_INST,1,12,0,12,0, FU_ALU, ALU_ADDQ, 0);
//     setinput(0,1,`NOOP_INST,2,12,0,12,0, FU_MULT, ALU_ADDQ, 0);
//     setinput(0,1,`NOOP_INST,3,12,0,12,0, FU_BR, ALU_ADDQ, 0);
//     setinput(0,1,`NOOP_INST,4,12,0,12,0, FU_ST, ALU_ADDQ, 0);
//     setinput(1,1,`NOOP_INST,5,12,0,12,0, FU_LD, ALU_ADDQ, 12);


//     $display("TEST complete nothing");
//     setFUDone(0,0,0,0,0);
//     //reset device
//     resetRS();
//     // insert for all FU non of which is ready.
//     setinput(0,1,`NOOP_INST,1,11,0,21,0, FU_ALU, ALU_ADDQ, 0);
//     setinput(0,1,`NOOP_INST,2,12,0,22,0, FU_MULT, ALU_ADDQ, 0);
//     setinput(0,1,`NOOP_INST,3,13,0,23,0, FU_BR, ALU_ADDQ, 0);
//     setinput(0,1,`NOOP_INST,4,14,0,24,0, FU_ST, ALU_ADDQ, 0);
//     setinput(0,1,`NOOP_INST,5,15,0,25,0, FU_LD, ALU_ADDQ, 0);

//     // complete stage
//     setinput(1,0,`NOOP_INST,3,4,0,5,1, FU_ALU, ALU_ADDQ, 45);
    

//     $display("TEST EN off");
//     setFUDone(0,0,0,0,0);
//     //reset device
//     resetRS();
//     //turn enable off
//     en = 1'b0;

//     // insert for all FU non of which is ready.
//     setinput(0,1,`NOOP_INST,1,11,0,21,0, FU_ALU, ALU_ADDQ, 0);
//     setinput(0,1,`NOOP_INST,2,12,0,22,0, FU_MULT, ALU_ADDQ, 0);
//     setinput(0,1,`NOOP_INST,3,13,0,23,0, FU_BR, ALU_ADDQ, 0);
//     setinput(0,1,`NOOP_INST,4,14,0,24,0, FU_ST, ALU_ADDQ, 0);
//     setinput(0,1,`NOOP_INST,5,15,0,25,0, FU_LD, ALU_ADDQ, 0);

//     //turn enable on
//     en = 1'b1;

//     // fill all entries with reg 11
//     setinput(0,1,`NOOP_INST,1,11,0,11,0, FU_ALU, ALU_ADDQ, 0);
//     setinput(0,1,`NOOP_INST,2,11,0,11,0, FU_MULT, ALU_ADDQ, 0);
//     setinput(0,1,`NOOP_INST,3,11,0,11,0, FU_BR, ALU_ADDQ, 0);
//     setinput(0,1,`NOOP_INST,4,11,0,11,0, FU_ST, ALU_ADDQ, 0);
//     setinput(0,1,`NOOP_INST,5,11,0,11,0, FU_LD, ALU_ADDQ, 0);

//     //turn enable off
//     en = 1'b0;

//     // complete all reg 11
//     setinput(1,0,`NOOP_INST,1,11,0,21,0, FU_ALU, ALU_ADDQ, 11);

//     //turn enable on
//     en = 1'b1;

//     // complete all reg 11
//     setinput(1,0,`NOOP_INST,1,11,0,21,0, FU_ALU, ALU_ADDQ, 11);

//     $finish;
//   end
endmodule  // module test_RS

