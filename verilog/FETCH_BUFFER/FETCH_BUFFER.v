`timescale 1ns/100ps

module FETCH_BUFFER (
  input logic                                    en, clock, reset,
  input logic             [`NUM_SUPER-1:0][63:0] if_PC_out,               // PC
  input logic             [`NUM_SUPER-1:0][63:0] if_NPC_out,              // PC of instruction after fetched (PC_plus).
  input logic             [`NUM_SUPER-1:0][31:0] if_IR_out,               // fetched instruction out
  input logic             [`NUM_SUPER-1:0][63:0] if_target_out,           // PC of the real instruction after this one (PC_plus or branch target)
  input logic             [`NUM_SUPER-1:0]       if_valid_inst_out,       // when low, instruction is garbage
  input logic                                    get_next_inst,           // high when want to get next inst
  input logic                                    rollback_en,             // if rollback
`ifdef DEBUG
  output INST_ENTRY_t     [`NUM_FB-1:0]          FB,
  output logic            [$clog2(`NUM_FB)-1:0]  head,
  output logic            [$clog2(`NUM_FB)-1:0]  tail,
`endif
  output FB_DECODER_OUT_t                        FB_decoder_out,  // output to decoder
  output logic                                   inst_out_valid,  // tells when can dispatch
  output logic                                   fetch_en         // signal to the fetch stage
);

`ifndef DEBUG
  INST_ENTRY_t  [`NUM_FB-1:0] FB;
  logic [$clog2(`NUM_FB)-1:0] head ,tail;
`endif

  INST_ENTRY_t  [`NUM_FB-1:0] nFB;
  logic [$clog2(`NUM_FB)-1:0] head_plus_one, tail_plus_one, head_plus_two, tail_plus_two;
  logic [$clog2(`NUM_FB)-1:0] next_head;
  logic [$clog2(`NUM_FB)-1:0] next_tail;
  logic head1, head2;

  assign FB_decoder_out.PC     = '{FB[tail_plus_one].PC, FB[tail].PC};
  assign FB_decoder_out.NPC    = '{FB[tail_plus_one].NPC, FB[tail].NPC};
  assign FB_decoder_out.inst   = '{FB[tail_plus_one].inst, FB[tail].inst};
  assign FB_decoder_out.target = '{FB[tail_plus_one].target, FB[tail].target};
  assign FB_decoder_out.valid  = inst_out_valid;

  assign head_plus_one = head + 1;
  assign head_plus_two = head + 2;
  assign tail_plus_one = tail + 1;
  assign tail_plus_two = tail + 2;
  assign next_tail = (get_next_inst) ? tail_plus_two : tail;

  assign fetch_en = ((head1 & !FB[head].valid) | (head2 & !FB[head].valid & !FB[head_plus_one].valid)) & !rollback_en;
  assign inst_out_valid = FB[tail].valid & FB[tail_plus_one].valid;

  always_comb begin
    head1 = `FALSE;
    head2 = `FALSE;
    case(if_valid_inst_out)
        2'b01, 2'b10: begin
          head1 = `TRUE;
        end
        2'b11: begin
          head2 = `TRUE;
        end
        default: begin
        end
    endcase
  end

  // always_comb begin
  // end

  assign next_head = (head1 & fetch_en) ? head_plus_one : 
                     (head2 & fetch_en) ? head_plus_two : head;

  always_comb begin
    nFB = FB;
    if(head1 & if_valid_inst_out[0] & fetch_en) begin
      nFB[head].PC     = if_PC_out[0];
      nFB[head].NPC    = if_NPC_out[0];
      nFB[head].inst   = if_IR_out[0];
      nFB[head].target = if_target_out[0];
      nFB[head].valid  = 1;
    end else if(head1 & if_valid_inst_out[1] & fetch_en) begin
      nFB[head].PC     = if_PC_out[1];
      nFB[head].NPC    = if_NPC_out[1];
      nFB[head].inst   = if_IR_out[1];
      nFB[head].target = if_target_out[1];
      nFB[head].valid  = 1;
    end else if (head2 & fetch_en) begin
      nFB[head].PC              = if_PC_out[0];
      nFB[head].NPC             = if_NPC_out[0];
      nFB[head].inst            = if_IR_out[0];
      nFB[head].target          = if_target_out[0];
      nFB[head].valid           = 1;
      nFB[head_plus_one].PC     = if_PC_out[1];
      nFB[head_plus_one].NPC    = if_NPC_out[1];
      nFB[head_plus_one].inst   = if_IR_out[1];
      nFB[head_plus_one].target = if_target_out[1];
      nFB[head_plus_one].valid  = 1;
    end
    if(get_next_inst)begin
      nFB[tail].valid = 0;
      nFB[tail_plus_one].valid = 0;
    end
  end

  always_ff @(posedge clock) begin
    if(reset | rollback_en) begin
      head <= `SD 0;
      tail <= `SD 0;
      for(int i=0; i < `NUM_FB; i++) begin
        FB[i].PC <= `SD 0;
        FB[i].NPC <= `SD 0;
        FB[i].inst <= `SD 0;
        FB[i].target <= `SD 0;
        FB[i].valid <= `SD 0;
      end
    end 
    else if(en) begin
      FB <= `SD nFB;
      head <= `SD next_head;
      tail <= `SD next_tail;
    end
  end
endmodule