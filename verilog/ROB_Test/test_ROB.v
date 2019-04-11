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

`include "../../sys_defs.vh"
`include "ROB.vh"

module test_ROB;

  // ********* UUT Setup *********
  // UUT input
  logic                                                      en, clock, reset;
  logic                                                      dispatch_en;
  logic                                                      rollback_en;
  logic               [`NUM_SUPER-1:0]                       complete_en;
  logic               [$clog2(`NUM_ROB)-1:0]                 ROB_rollback_idx;
  DECODER_ROB_OUT_t                                          decoder_ROB_out;
  FL_ROB_OUT_t                                               FL_ROB_out;
  MAP_TABLE_ROB_OUT_t                                        Map_Table_ROB_out;
  CDB_ROB_OUT_t                                              CDB_ROB_out;

  // UUT Output
  ROB_t                                                      rob;
  logic               [`NUM_SUPER-1:0][63:0]                 retire_NPC;
  logic                                                      ROB_valid;
  logic               [`NUM_SUPER-1:0]                       retire_en;
  logic                                                      halt_out;
  logic                                                      illegal_out;
  logic               [`NUM_SUPER-1:0][$clog2(`NUM_ROB)-1:0] ROB_idx;
  ROB_ARCH_MAP_OUT_t                                         ROB_Arch_Map_out;
  ROB_FL_OUT_t                                               ROB_FL_out;

  // UUT instantiation
  ROB UUT (
    // inputs
    .en(en),
    .clock(clock),
    .reset(reset),
    .dispatch_en(dispatch_en),
    .complete_en(complete_en),
    .rollback_en(rollback_en),
    .ROB_rollback_idx(ROB_rollback_idx),
    .decoder_ROB_out(decoder_ROB_out),
    .FL_ROB_out(FL_ROB_out),
    .Map_Table_ROB_out(Map_Table_ROB_out),
    .CDB_ROB_out(CDB_ROB_out),
    // outputs
    .rob(rob),
    .retire_NPC(retire_NPC),
    .ROB_valid(ROB_valid),
    .retire_en(retire_en),
    .halt_out(halt_out),
    .illegal_out(illegal_out),
    .ROB_idx(ROB_idx),
    .ROB_Arch_Map_out(ROB_Arch_Map_out),
    .ROB_FL_out(ROB_FL_out)
  );

  // ********* System Clock *********
  // Generate System Clock
  always begin
    #(`VERILOG_CLOCK_PERIOD/2.0);
    clock = ~clock;
  end

  // ********* Test Setup *********
  task printInput;
    begin
      $display("==========================INPUT START===========================");
      $display(" _____________________________________________ ");
      $display("| en | reset | rollback_en | ROB_rollback_idx |");
      $display("|  %b |   %b   |      %b      |        %2d        |\n",
                en,
                reset,
                rollback_en,
                ROB_rollback_idx);
      
      $display("dispatch_en = %1d", dispatch_en);
      $display(" ___ ____________________________________________________ ___________________ ");
      $display("|   | halt | illegal | dest_idx |           NPC          | T_idx | T_old_idx |");
      $display("| 0 |   %b  |    %b    |    %2d    | 0x %04h_%04h_%04h_%04h |   %2d  |     %2d    |",
                decoder_ROB_out.halt[0],
                decoder_ROB_out.illegal[0],
                decoder_ROB_out.dest_idx[0],
                decoder_ROB_out.NPC[0][63:48], decoder_ROB_out.NPC[0][47:32], decoder_ROB_out.NPC[0][31:16], decoder_ROB_out.NPC[0][15:0],
                FL_ROB_out.T_idx[0],
                Map_Table_ROB_out.Told_idx[0]);
      $display("| 1 |   %b  |    %b    |    %2d    | 0x %04h_%04h_%04h_%04h |   %2d  |     %2d    |\n",
                decoder_ROB_out.halt[1],
                decoder_ROB_out.illegal[1],
                decoder_ROB_out.dest_idx[1],
                decoder_ROB_out.NPC[1][63:48], decoder_ROB_out.NPC[1][47:32], decoder_ROB_out.NPC[1][31:16], decoder_ROB_out.NPC[1][15:0],
                FL_ROB_out.T_idx[1],
                Map_Table_ROB_out.Told_idx[1]);

      $display("Complete");
      $display(" ___________________________ ");
      $display("|   | complete_en | ROB_idx |");
      $display("| 0 |      %b      |    %d    |",
                complete_en[0],
                CDB_ROB_out.ROB_idx[0]);
      $display("| 1 |      %b      |    %d    |\n",
                complete_en[1],
                CDB_ROB_out.ROB_idx[1]);

      $display("---------------------------INPUT END----------------------------\n\n");
    end
  endtask

  task printOutput;
    begin
      $display("===========================OUTPUT START===========================");
      $display(" ______________________________________________________________ ");
      $display("| ROB_valid | halt_out | illegal_out | ROB_idx[0] | ROB_idx[1] |");
      $display("|     %b     |     %b    |      %b      |      %d     |      %d     |\n",
                ROB_valid,
                halt_out,
                illegal_out,
                ROB_idx[0],
                ROB_idx[1]);
      
      $display(" ______________________________________________________________________ ");
      $display("|   | retire_en | dest_idx | T_idx | Told_idx |        retire_NPC      |");
      $display("| 0 |     %b     |    %2d    |   %2d  |    %2d    | 0x %04h_%04h_%04h_%04h |",
                retire_en[0],
                ROB_Arch_Map_out.dest_idx[0],
                ROB_Arch_Map_out.T_idx[0],
                ROB_FL_out.Told_idx[0],
                retire_NPC[0][63:48], retire_NPC[0][47:32], retire_NPC[0][31:16], retire_NPC[0][15:0]);
      $display("| 1 |     %b     |    %2d    |   %2d  |    %2d    | 0x %04h_%04h_%04h_%04h |\n",
                retire_en[1],
                ROB_Arch_Map_out.dest_idx[1],
                ROB_Arch_Map_out.T_idx[1],
                ROB_FL_out.Told_idx[1],
                retire_NPC[1][63:48], retire_NPC[1][47:32], retire_NPC[1][31:16], retire_NPC[1][15:0]);
      $display("----------------------------OUTPUT END----------------------------\n\n");
    end
  endtask

  task printOut;
    begin
      $display("===========================ROB START===========================");
      $display(" head: %d", rob.head);
      $display(" tail+1: %d", rob.tail);
      $display(" _____________________________________________________________________________________________ ");
      $display("| # | valid | T_idx | Told_idx | dest_idx | complete | halt | illegal |           NPC          |");
      for(int i = 0; i < `NUM_ROB; i++) begin
        $display("| %1d |   %b   |   %d  |    %d    |    %d    |     %b    |   %b  |    %b    | 0x %04h_%04h_%04h_%04h |",
                  i,
                  rob.entry[i].valid,
                  rob.entry[i].T_idx,
                  rob.entry[i].Told_idx,
                  rob.entry[i].dest_idx,
                  rob.entry[i].complete,
                  rob.entry[i].halt,
                  rob.entry[i].illegal,
                  rob.entry[i].NPC[63:48], rob.entry[i].NPC[47:32], rob.entry[i].NPC[31:16], rob.entry[i].NPC[15:0]);
      end
      $display("\n----------------------------ROB END----------------------------\n\n");
    end
  endtask

  task setInput(
    logic en_in,
    logic reset_in,
    logic dispatch_en_in,
    logic rollback_en_in,
    logic [$clog2(`NUM_ROB)-1:0] ROB_rollback_idx_in,

    logic        decoder_halt_0_in,
    logic        decoder_illegal_0_in,
    logic  [4:0] decoder_dest_idx_0_in,
    logic [63:0] decoder_NPC_0_in,
    logic [$clog2(`NUM_PR)-1:0] FL_T_idx_0_in,
    logic [$clog2(`NUM_PR)-1:0] MapTable_Told_idx_0_in,

    logic        decoder_halt_1_in,
    logic        decoder_illegal_1_in,
    logic  [4:0] decoder_dest_idx_1_in,
    logic [63:0] decoder_NPC_1_in,
    logic [$clog2(`NUM_PR)-1:0] FL_T_idx_1_in,
    logic [$clog2(`NUM_PR)-1:0] MapTable_Told_idx_1_in,

    logic complete_en_0_in,
    logic [$clog2(`NUM_ROB)-1:0] CDB_ROB_idx_0_in,

    logic complete_en_1_in,
    logic [$clog2(`NUM_ROB)-1:0] CDB_ROB_idx_1_in
  );

    begin
      @ (posedge clock);
      $display(" output time (posedge): %d",$time);
      printOutput();
      #2;
      $display(" ROB print time: %d",$time);
      printOut();

      $display("\n\n\n\n");
       //set input at negedge
      @ (negedge clock);
      en = en_in;
      reset = reset_in;
      dispatch_en = dispatch_en_in;
      rollback_en = rollback_en_in;
      ROB_rollback_idx = ROB_rollback_idx_in;

      decoder_ROB_out.halt[1] = decoder_halt_1_in;
      decoder_ROB_out.halt[0] = decoder_halt_0_in;
      decoder_ROB_out.illegal[1] = decoder_illegal_1_in;
      decoder_ROB_out.illegal[0] = decoder_illegal_0_in;
      decoder_ROB_out.dest_idx[1] = decoder_dest_idx_1_in;
      decoder_ROB_out.dest_idx[0] = decoder_dest_idx_0_in;
      decoder_ROB_out.NPC[1] = decoder_NPC_1_in;
      decoder_ROB_out.NPC[0] = decoder_NPC_0_in;
      FL_ROB_out.T_idx[1] = FL_T_idx_1_in;
      FL_ROB_out.T_idx[0] = FL_T_idx_0_in;
      Map_Table_ROB_out.Told_idx[1] = MapTable_Told_idx_1_in;
      Map_Table_ROB_out.Told_idx[0] = MapTable_Told_idx_0_in;

      complete_en = {complete_en_1_in, complete_en_0_in};
      CDB_ROB_out.ROB_idx[1] = CDB_ROB_idx_1_in;
      CDB_ROB_out.ROB_idx[0] = CDB_ROB_idx_0_in;

      $display(" input time: %d",$time);
      printInput();
      // $display(" output time (negedge): %d",$time);
      // printOutput();
    end
  endtask


  initial begin
    
    // Reset
    en    = 1'b1;
    clock = 1'b1;
    reset = 1'b1;
    dispatch_en = 0;
    rollback_en = 0;
    complete_en = 0;

    @(negedge clock);
    // Test 1
    // Fill 0, 1
    setInput(
      .en_in(1),
      .reset_in(0),
      .dispatch_en_in(1),
      .rollback_en_in(0),
      .ROB_rollback_idx_in(3'd0),

      .decoder_halt_0_in(0),
      .decoder_illegal_0_in(0),
      .decoder_dest_idx_0_in(5'd0),
      .decoder_NPC_0_in(64'd0),
      .FL_T_idx_0_in(6'd10),
      .MapTable_Told_idx_0_in(6'd0),

      .decoder_halt_1_in(0),
      .decoder_illegal_1_in(0),
      .decoder_dest_idx_1_in(5'd1),
      .decoder_NPC_1_in(64'd1),
      .FL_T_idx_1_in(6'd11),
      .MapTable_Told_idx_1_in(6'd1),

      .complete_en_0_in(0),
      .CDB_ROB_idx_0_in(0),

      .complete_en_1_in(0),
      .CDB_ROB_idx_1_in(0)
    );

    // Fill 2, 3
    setInput(
      .en_in(1),
      .reset_in(0),
      .dispatch_en_in(1),
      .rollback_en_in(0),
      .ROB_rollback_idx_in(3'd0),

      .decoder_halt_0_in(0),
      .decoder_illegal_0_in(0),
      .decoder_dest_idx_0_in(5'd2),
      .decoder_NPC_0_in(64'd2),
      .FL_T_idx_0_in(6'd12),
      .MapTable_Told_idx_0_in(6'd2),

      .decoder_halt_1_in(0),
      .decoder_illegal_1_in(0),
      .decoder_dest_idx_1_in(5'd3),
      .decoder_NPC_1_in(64'd3),
      .FL_T_idx_1_in(6'd13),
      .MapTable_Told_idx_1_in(6'd3),

      .complete_en_0_in(0),
      .CDB_ROB_idx_0_in(0),

      .complete_en_1_in(0),
      .CDB_ROB_idx_1_in(0)
    );

    // Fill 4, 5
    setInput(
      .en_in(1),
      .reset_in(0),
      .dispatch_en_in(1),
      .rollback_en_in(0),
      .ROB_rollback_idx_in(3'd0),

      .decoder_halt_0_in(0),
      .decoder_illegal_0_in(0),
      .decoder_dest_idx_0_in(5'd4),
      .decoder_NPC_0_in(64'd4),
      .FL_T_idx_0_in(6'd14),
      .MapTable_Told_idx_0_in(6'd4),

      .decoder_halt_1_in(0),
      .decoder_illegal_1_in(0),
      .decoder_dest_idx_1_in(5'd5),
      .decoder_NPC_1_in(64'd5),
      .FL_T_idx_1_in(6'd15),
      .MapTable_Told_idx_1_in(6'd5),

      .complete_en_0_in(0),
      .CDB_ROB_idx_0_in(0),

      .complete_en_1_in(0),
      .CDB_ROB_idx_1_in(0)
    );

    // Fill 6, 7 (full!) and complete 0
    setInput(
      .en_in(1),
      .reset_in(0),
      .dispatch_en_in(1),
      .rollback_en_in(0),
      .ROB_rollback_idx_in(3'd0),

      .decoder_halt_0_in(0),
      .decoder_illegal_0_in(0),
      .decoder_dest_idx_0_in(5'd6),
      .decoder_NPC_0_in(64'd6),
      .FL_T_idx_0_in(6'd16),
      .MapTable_Told_idx_0_in(6'd6),

      .decoder_halt_1_in(0),
      .decoder_illegal_1_in(0),
      .decoder_dest_idx_1_in(5'd7),
      .decoder_NPC_1_in(64'd7),
      .FL_T_idx_1_in(6'd17),
      .MapTable_Told_idx_1_in(6'd7),

      .complete_en_0_in(0),
      .CDB_ROB_idx_0_in(0),

      .complete_en_1_in(1),
      .CDB_ROB_idx_1_in(0)
    );

    // Stop dispatch. See 0 retire
    setInput(
      .en_in(1),
      .reset_in(0),
      .dispatch_en_in(0),
      .rollback_en_in(0),
      .ROB_rollback_idx_in(3'd0),

      .decoder_halt_0_in(0),
      .decoder_illegal_0_in(0),
      .decoder_dest_idx_0_in(5'd0),
      .decoder_NPC_0_in(64'd0),
      .FL_T_idx_0_in(6'd0),
      .MapTable_Told_idx_0_in(6'd0),

      .decoder_halt_1_in(0),
      .decoder_illegal_1_in(0),
      .decoder_dest_idx_1_in(5'd0),
      .decoder_NPC_1_in(64'd0),
      .FL_T_idx_1_in(6'd0),
      .MapTable_Told_idx_1_in(6'd0),

      .complete_en_0_in(0),
      .CDB_ROB_idx_0_in(0),

      .complete_en_1_in(0),
      .CDB_ROB_idx_1_in(0)
    );

    // see if ROB_valid is still 0 when there is only one entry left in ROB
    setInput(
      .en_in(0),
      .reset_in(0),
      .dispatch_en_in(0),
      .rollback_en_in(0),
      .ROB_rollback_idx_in(3'd0),

      .decoder_halt_0_in(0),
      .decoder_illegal_0_in(0),
      .decoder_dest_idx_0_in(5'd0),
      .decoder_NPC_0_in(64'd0),
      .FL_T_idx_0_in(6'd0),
      .MapTable_Told_idx_0_in(6'd0),

      .decoder_halt_1_in(0),
      .decoder_illegal_1_in(0),
      .decoder_dest_idx_1_in(5'd0),
      .decoder_NPC_1_in(64'd0),
      .FL_T_idx_1_in(6'd0),
      .MapTable_Told_idx_1_in(6'd0),

      .complete_en_0_in(0),
      .CDB_ROB_idx_0_in(0),

      .complete_en_1_in(0),
      .CDB_ROB_idx_1_in(0)
    );

    // do nothing
    setInput(
      .en_in(0),
      .reset_in(0),
      .dispatch_en_in(0),
      .rollback_en_in(0),
      .ROB_rollback_idx_in(3'd0),

      .decoder_halt_0_in(0),
      .decoder_illegal_0_in(0),
      .decoder_dest_idx_0_in(5'd0),
      .decoder_NPC_0_in(64'd0),
      .FL_T_idx_0_in(6'd0),
      .MapTable_Told_idx_0_in(6'd0),

      .decoder_halt_1_in(0),
      .decoder_illegal_1_in(0),
      .decoder_dest_idx_1_in(5'd0),
      .decoder_NPC_1_in(64'd0),
      .FL_T_idx_1_in(6'd0),
      .MapTable_Told_idx_1_in(6'd0),

      .complete_en_0_in(0),
      .CDB_ROB_idx_0_in(0),

      .complete_en_1_in(0),
      .CDB_ROB_idx_1_in(0)
    );

    $finish;
  end
endmodule  // test_ROB
