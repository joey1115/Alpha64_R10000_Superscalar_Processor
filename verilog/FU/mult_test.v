`timescale 1ns/100ps

`include "FU.vh"

module testbench();

  logic quit, clock, reset, full_hazard;
  FU_PACKET_IN_t fu_packet_in;
  FU_RESULT_ENTRY_t fu_packet_out;
  logic fu_valid;

  logic [63:0] cres;
  logic [$clog2(`NUM_PR)-1:0] T_idx;
  
  assign cres = fu_packet_in.T1_value*fu_packet_in.T2_value;
  assign T_idx = fu_packet_in.T_idx;

  // always_ff @(negedge clock) begin
  //   cres <=  #(`NUM_MULT_STAGE) fu_packet_in.T1_value*fu_packet_in.T2_value;
  //   T_idx <= #(`NUM_MULT_STAGE) fu_packet_in.T_idx;
  // end

  //wire correct = ((cres===fu_packet_out.result) && (T_idx === fu_packet_out.T_idx))|~fu_packet_out.done;
  wire correct = ((cres===fu_packet_out.result))|~fu_packet_out.done;


  mult m0(	.clock(clock),
            .reset(reset),
            .full_hazard(full_hazard),
            .fu_packet(fu_packet_in),
            .fu_packet_out(fu_packet_out),
            .fu_valid(fu_valid));

  always @(posedge clock)
    #2 if(!correct) begin 
        $display("Incorrect at time %4.0f",$time);
        $display("cres = %h fu_packet_out.result = %h",cres,fu_packet_out.result);
        //$finish;
    end

  always begin
    #5;
    clock=~clock;
  end

  // Some students have had problems just using "@(posedge fu_valid)" because their
  // "fu_valid" signals glitch (even though they are the output of a register). This
  // prevents that by making sure "fu_valid" is high at the clock edge.
  task wait_until_fu_valid;
    forever begin : wait_loop
      $display("wait at time %4.0f",$time);
      @(posedge fu_valid);
      @(negedge clock);
      if(fu_valid) disable wait_until_fu_valid;
    end
  endtask



  initial begin

    //$vcdpluson;
    $monitor("Time:%4.0f fu_valid:%b fu_packet_in.T1_value:%h fu_packet_in.T2_value:%h product:%h fu_packet_out.result:%h fu_packet_out.T_idx:%h fu_packet_out.done",$time,fu_valid,fu_packet_in.T1_value,fu_packet_in.T2_value,cres,fu_packet_out.result, fu_packet_out.T_idx, fu_packet_out.done);
    fu_packet_in.T1_value=2;
    fu_packet_in.T2_value=3;
    fu_packet_in.T_idx=4;
    full_hazard = 0;

    fu_packet_in.T2_select=ALU_OPB_IS_REGB;

    reset=1;
    clock=0;
    fu_packet_in.ready=1;

    @(negedge clock);
    reset=0;

    fu_packet_in.ready=1;
    fu_packet_in.T1_value=4;
    fu_packet_in.T2_value=5;
    fu_packet_in.T_idx=fu_packet_in.T_idx + 1;
    @(negedge clock);
    fu_packet_in.ready=0;
    //wait_until_fu_valid();


    fu_packet_in.ready=1;
    fu_packet_in.T1_value=6;
    fu_packet_in.T2_value=7;
    fu_packet_in.T_idx=fu_packet_in.T_idx + 1;
    @(negedge clock);
    fu_packet_in.ready=0;
    //wait_until_fu_valid();


    fu_packet_in.ready=1;
    fu_packet_in.T1_value=8;
    fu_packet_in.T2_value=9;
    fu_packet_in.T_idx=fu_packet_in.T_idx + 1;
    @(negedge clock);
    fu_packet_in.ready=0;
    //wait_until_fu_valid();


    fu_packet_in.ready=1;
    fu_packet_in.T1_value=10;
    fu_packet_in.T2_value=11;
    fu_packet_in.T_idx=fu_packet_in.T_idx + 1;
    @(negedge clock);
    fu_packet_in.ready=0;
    //wait_until_fu_valid();


    fu_packet_in.ready=1;
    fu_packet_in.T1_value=12;
    fu_packet_in.T2_value=13;
    fu_packet_in.T_idx=fu_packet_in.T_idx + 1;
    @(negedge clock);
    fu_packet_in.ready=0;
    //wait_until_fu_valid();


    fu_packet_in.ready=1;
    fu_packet_in.T1_value=14;
    fu_packet_in.T2_value=15;
    fu_packet_in.T_idx=fu_packet_in.T_idx + 1;
    @(negedge clock);
    fu_packet_in.ready=0;
    //wait_until_fu_valid();


    fu_packet_in.ready=1;
    fu_packet_in.T1_value=16;
    fu_packet_in.T2_value=17;
    fu_packet_in.T_idx=fu_packet_in.T_idx + 1;
    @(negedge clock);
    fu_packet_in.ready=0;
    //wait_until_fu_valid();


    fu_packet_in.ready=1;
    fu_packet_in.T1_value=18;
    fu_packet_in.T2_value=19;
    fu_packet_in.T_idx=fu_packet_in.T_idx + 1;
    @(negedge clock);
    fu_packet_in.ready=0;
    //wait_until_fu_valid();

    fu_packet_in.ready=1;
    fu_packet_in.T1_value=20;
    fu_packet_in.T2_value=21;
    fu_packet_in.T_idx=fu_packet_in.T_idx + 1;
    @(negedge clock);
    fu_packet_in.ready=0;
    //wait_until_fu_valid();

    full_hazard = 1;

    fu_packet_in.ready=1;
    fu_packet_in.T1_value=20;
    fu_packet_in.T2_value=21;
    fu_packet_in.T_idx=fu_packet_in.T_idx + 1;
    @(negedge clock);
    fu_packet_in.ready=0;
    //wait_until_fu_valid();
 


    quit = 0;
    quit <= #10000 1;
    while(~quit) begin
      fu_packet_in.ready=1;
      fu_packet_in.T1_value={$random,$random};
      fu_packet_in.T2_value={$random,$random};
      fu_packet_in.T_idx=fu_packet_in.T_idx + 1;
      @(negedge clock);
      fu_packet_in.ready=0;
      //wait_until_fu_valid();
    end
    $finish;
  end

endmodule



  
  