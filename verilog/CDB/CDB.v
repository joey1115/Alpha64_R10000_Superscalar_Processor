/*****************CDB******************
*   Fetch
*   Dispatch
*   Issue
*   Execute
*     Input: rollback_en (X/C)
*     Input: ROB_rollback_idx (br module, LSQ)
*     Input: diff_ROB (FU)    // diff_ROB = ROB_tail of the current cycle - ROB_rollback idx
*   Complete
*     Input: done   (X/C)  // taken signal from FU
*     Input: T_idx     (X/C)  // tag from FU
*     Input: ROB_idx   (X/C)
*     Input: FU_out (X/C)  // result from FU
*     Input: dest_idx  (X/C)
*     Output: CDB_valid (FU)  // full entry means hazard(taken=0, entry is free)
*     Output: complete_en (RS, ROB, Map table) 
*     Output: write_en (PR)   // taken signal to PR
*     Output: T_idx    (PR)   // tag to PR
*     Output: T_value  (PR)   // result to PR
*     Output: dest_idx (Map table)
*   Retire
***************************************/

`timescale 1ns/100ps

module CDB (
  input  logic                                      en, clock, reset,
  input  logic                                      rollback_en,        // rollback_en from X/C
  input  logic               [$clog2(`NUM_ROB)-1:0] ROB_rollback_idx,   // ROB# of mispredicted branch/incorrect load from br module/LSQ
  input  logic               [$clog2(`NUM_ROB)-1:0] diff_ROB,           // diff_ROB = ROB_tail of the current cycle - ROB_rollback_idx
  input  FU_CDB_OUT_t                               FU_CDB_out,          // done,T_idx,ROB_idx,dest_idx,result from FU
`ifdef DEBUG
  output CDB_entry_t         [`NUM_FU-1:0]          CDB,
`endif
  output logic                                      write_en,
  output logic                                      complete_en,
  output logic               [`NUM_FU-1:0]          CDB_valid,
  output CDB_ROB_OUT_t                              CDB_ROB_out,
  output CDB_RS_OUT_t                               CDB_RS_out,
  output CDB_MAP_TABLE_OUT_t                        CDB_Map_Table_out,
  output CDB_PR_OUT_t                               CDB_PR_out
);

`ifndef DEBUG
  CDB_entry_t [`NUM_FU-1:0]                       CDB;
`endif
  CDB_entry_t [`NUM_FU-1:0]                       next_CDB;
  logic       [`NUM_FU-1:0][$clog2(`NUM_ROB)-1:0] diff;
  logic       [`NUM_FU-1:0]                       rollback_valid;
  logic       [`NUM_FU-1:0]                       CDB_empty;
  logic                                           complete_hit;
  logic                    [$clog2(`NUM_FU)-1:0]  complete_idx;
  logic                    [$clog2(`NUM_PR)-1:0]  T_idx;         // tag to PR
  logic                    [4:0]                  dest_idx;      // to map_table
  logic                    [63:0]                 T_value;       // result to PR
  logic                    [$clog2(`NUM_ROB)-1:0] ROB_idx;

  logic                    [$clog2(`NUM_FU)-1:0]  CDB_index;
  logic                    [`NUM_FU-1:0]          CDB_taken,CDB_sel;


  assign CDB_ROB_out       = '{ROB_idx};
  assign CDB_RS_out        = '{T_idx};
  assign CDB_Map_Table_out = '{T_idx, dest_idx};
  assign CDB_PR_out        = '{T_idx, T_value};
  assign complete_en       = complete_hit;
  assign write_en          = complete_hit;
  assign CDB_valid         = CDB_empty;

  always_comb begin
    next_CDB = CDB;
    // Update taken, T_idx & T_value for each empty entry
    // and give CDB_valid to FU, CDB_valid=1 means the entry is free
    for (int i=0; i<`NUM_FU; i++) begin
      if (CDB_empty[i]) begin
        if (FU_CDB_out.FU_out[i].done) begin
          next_CDB[i].taken    = `TRUE;
          next_CDB[i].T_idx    = FU_CDB_out.FU_out[i].T_idx;
          next_CDB[i].ROB_idx  = FU_CDB_out.FU_out[i].ROB_idx;
          next_CDB[i].dest_idx = FU_CDB_out.FU_out[i].dest_idx;
          next_CDB[i].T_value  = FU_CDB_out.FU_out[i].result;
        end else begin
          next_CDB[i] = `CDB_RENTRY_RESET_PACKED;
        end
      end
    end
  end

  always_comb begin
    rollback_valid = {`NUM_FU{`FALSE}};
    if (rollback_en) begin
      for (int i=0; i<`NUM_FU; i++)begin
        diff[i] = CDB[i].ROB_idx - ROB_rollback_idx;
        rollback_valid[i] = diff_ROB >= diff[i];
      end
    end
  end

  always_comb begin
    for (int i=0; i<`NUM_FU; i++)begin
      CDB_empty[i] = rollback_valid[i] || !CDB[i].taken;
    end
    if (complete_hit) begin
      CDB_empty[complete_idx] = `TRUE;
    end
  end

  // always_comb begin
  //   for (int i=0; i<`NUM_FU; i++)begin
  //     CDB_valid[i] = !CDB[i].taken;
  //   end
  //   if (complete_hit) begin
  //     CDB_valid[complete_idx] = `TRUE;
  //   end
  // end

  // always_comb begin
  //   T_idx        = `ZERO_PR;
  //   dest_idx     = `ZERO_REG;
  //   T_value      = 64'hbaadbeefdeadbeef;
  //   ROB_idx      = 0;
  //   complete_hit = `FALSE;
  //   complete_idx = 0;
  //   // broadcast one completed instruction (if one is found)
  //   for (int i=0; i<`NUM_FU; i++) begin
  //     // if ((next_CDB[i].taken && `FU_LIST[i] != FU_LD) || (next_CDB[i].taken && `FU_LIST[i] == FU_LD && next_CDB[i].ROB_idx == ROB_head_idx))  begin
  //     if (CDB[i].taken) begin
  //       T_idx        = CDB[i].T_idx;
  //       dest_idx     = CDB[i].dest_idx;
  //       T_value      = CDB[i].T_value;
  //       ROB_idx      = CDB[i].ROB_idx;
  //       complete_hit = `TRUE;
  //       complete_idx = i;
  //       break;
  //     end // if
  //   end // for
  // end // always_comb
  always_comb begin
    for(int i=0; i < `NUM_FU; i++)begin
      CDB_taken[i] = CDB[i].taken;
    end
  end

  always_comb begin
    T_idx        = CDB[CDB_index].T_idx;
    dest_idx     = CDB[CDB_index].dest_idx;
    T_value      = CDB[CDB_index].T_value;
    ROB_idx      = CDB[CDB_index].ROB_idx;
    complete_hit = (CDB_sel != 0);
    complete_idx = CDB_index;
  end // always_comb

  ps sel (.req(CDB_taken), .en(en), .gnt(CDB_sel));

  pe encode (.gnt(CDB_sel), .enc(CDB_index));


  // always_comb begin
  //   complete_hit = `FALSE;
  //   complete_idx = 0;
  //   // broadcast one completed instruction (if one is found)
  //   for (int i=0; i<`NUM_FU; i++) begin
  //     if (CDB[i].taken) begin
  //       complete_hit = `TRUE;
  //       complete_idx = i;
  //       break;
  //     end // if
  //   end // for
  // end // always_comb

  // always_comb begin
  //   T_idx        = `ZERO_PR;
  //   dest_idx     = `ZERO_REG;
  //   T_value      = 64'hbaadbeefdeadbeef;
  //   ROB_idx      = 0;
  //   if (complete_hit) begin
  //     T_idx        = CDB[complete_idx].T_idx;
  //     dest_idx     = CDB[complete_idx].dest_idx;
  //     T_value      = CDB[complete_idx].T_value;
  //     ROB_idx      = CDB[complete_idx].ROB_idx;
  //   end // if
  // end // always_comb

  always_ff @(posedge clock) begin
    if (reset) begin
      CDB <= `SD `CDB_RESET;
    end else if (en) begin
      CDB <= `SD next_CDB;
    end
  end // always_ff
endmodule


module ps (req, en, gnt, req_up);
  //synopsys template
  parameter NUM_BITS = `NUM_FU;
  
    input  [NUM_BITS-1:0] req;
    input                 en;
  
    output [NUM_BITS-1:0] gnt;
    output                req_up;
          
    wire   [NUM_BITS-2:0] req_ups;
    wire   [NUM_BITS-2:0] enables;
          
    assign req_up = req_ups[NUM_BITS-2];
    assign enables[NUM_BITS-2] = en;
          
    genvar i,j;
    generate
      if ( NUM_BITS == 2 )
      begin
        ps2 single (.req(req),.en(en),.gnt(gnt),.req_up(req_up));
      end
      else
      begin
        for(i=0;i<NUM_BITS/2;i=i+1)
        begin : foo
          ps2 base ( .req(req[2*i+1:2*i]),
                     .en(enables[i]),
                     .gnt(gnt[2*i+1:2*i]),
                     .req_up(req_ups[i])
          );
        end
  
        for(j=NUM_BITS/2;j<=NUM_BITS-2;j=j+1)
        begin : bar
          ps2 top ( .req(req_ups[2*j-NUM_BITS+1:2*j-NUM_BITS]),
                    .en(enables[j]),
                    .gnt(enables[2*j-NUM_BITS+1:2*j-NUM_BITS]),
                    .req_up(req_ups[j])
          );
        end
      end
    endgenerate
  endmodule
  
module ps2(req, en, gnt, req_up);

  input     [1:0] req;
  input           en;
  
  output    [1:0] gnt;
  output          req_up;
  
  assign gnt[1] = en & req[1];
  assign gnt[0] = en & req[0] & !req[1];
  
  assign req_up = req[1] | req[0];

endmodule

module pe(gnt,enc);
  //synopsys template
  parameter OUT_WIDTH=3;
  parameter IN_WIDTH=1<<OUT_WIDTH;

  input   [IN_WIDTH-1:0] gnt;

  output [OUT_WIDTH-1:0] enc;
      wor    [OUT_WIDTH-1:0] enc;
      
      genvar i,j;
      generate
        for(i=0;i<OUT_WIDTH;i=i+1)
        begin : foo
          for(j=1;j<IN_WIDTH;j=j+1)
          begin : bar
            if (j[i])
              assign enc[i] = gnt[j];
          end
        end
      endgenerate
endmodule