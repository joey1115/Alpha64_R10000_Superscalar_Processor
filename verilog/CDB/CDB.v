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
  output logic               [`NUM_SUPER-1:0]       write_en,
  output logic               [`NUM_SUPER-1:0]       complete_en,
  output logic               [`NUM_FU-1:0]          CDB_valid,
  output logic               [`NUM_ST-1:0]          CDB_SQ_valid,
  output logic               [`NUM_LD-1:0]          CDB_LQ_valid,
  output CDB_ROB_OUT_t                              CDB_ROB_out,
  output CDB_RS_OUT_t                               CDB_RS_out,
  output CDB_MAP_TABLE_OUT_t                        CDB_Map_Table_out,
  output CDB_PR_OUT_t                               CDB_PR_out
);

`ifndef DEBUG
  CDB_entry_t [`NUM_FU-1:0]                       CDB;
`endif
  CDB_entry_t [`NUM_FU-1:0]                          next_CDB;
  logic       [`NUM_FU-1:0]   [$clog2(`NUM_ROB)-1:0] diff;
  logic       [`NUM_FU-1:0]                          rollback_valid;
  logic       [`NUM_FU-1:0]                          CDB_empty;
  logic       [`NUM_SUPER-1:0]                       complete_hit;
  logic       [`NUM_SUPER-1:0][$clog2(`NUM_FU)-1:0]  complete_idx;
  logic       [`NUM_SUPER-1:0][$clog2(`NUM_PR)-1:0]  T_idx;         // tag to PR
  logic       [`NUM_SUPER-1:0][4:0]                  dest_idx;      // to map_table
  logic       [`NUM_SUPER-1:0][63:0]                 T_value;       // result to PR
  logic       [`NUM_SUPER-1:0][$clog2(`NUM_ROB)-1:0] ROB_idx;

  assign CDB_ROB_out       = '{ROB_idx};
  assign CDB_RS_out        = '{T_idx};
  assign CDB_Map_Table_out = '{T_idx, dest_idx};
  assign CDB_PR_out        = '{T_idx, T_value};
  assign complete_en       = complete_hit;
  assign write_en          = complete_hit;
  assign CDB_valid         = CDB_empty;
  assign CDB_SQ_valid      = CDB_empty[`NUM_LD+`NUM_ST-1:`NUM_LD];
  assign CDB_LQ_valid      = CDB_empty[`NUM_LD-1:0];

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
        rollback_valid[i] = diff_ROB >= diff[i] && diff[i] != {$clog2(`NUM_ROB){1'b0}};
      end
    end
  end

  always_comb begin
    for (int i=0; i<`NUM_FU; i++)begin
      CDB_empty[i] = rollback_valid[i] || !CDB[i].taken;
    end
    for (int i=0; i<`NUM_SUPER; i++) begin
      if (complete_hit[i]) begin
        CDB_empty[complete_idx[i]] = `TRUE;
      end
    end
  end

  always_comb begin
    complete_hit = '{`NUM_SUPER{`FALSE}};
    complete_idx = '{`NUM_SUPER{{$clog2(`NUM_FU){{1'b0}}}}};
    for (int i = 0; i < `NUM_SUPER; i++) begin
      // broadcast one completed instruction (if one is found) for first half of FU
      for (int j=i; j<`NUM_FU; j=j+2) begin
        if (CDB[j].taken) begin
          complete_hit[i] = `TRUE;
          complete_idx[i] = j;
          break;
        end // if
      end // for
    end
  end // always_comb

  always_comb begin
    for (int i=0; i<`NUM_SUPER; i++)begin
      T_idx[i]        = `ZERO_PR;
      dest_idx[i]     = `ZERO_REG;
      T_value[i]      = 64'hbaadbeefdeadbeef;
      ROB_idx[i]      = 0;
      if (complete_hit[i]) begin
        T_idx[i]        = CDB[complete_idx[i]].T_idx;
        dest_idx[i]     = CDB[complete_idx[i]].dest_idx;
        T_value[i]      = CDB[complete_idx[i]].T_value;
        ROB_idx[i]      = CDB[complete_idx[i]].ROB_idx;
      end // if
    end
  end // always_comb

  always_ff @(posedge clock) begin
    if (reset) begin
      CDB <= `SD `CDB_RESET;
    end else if (en) begin
      CDB <= `SD next_CDB;
    end
  end // always_ff

endmodule



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
  // always_comb begin
  //   for(int i=0; i < `NUM_FU; i++)begin
  //     CDB_taken[i] = CDB[i].taken;
  //   end
  // end

  // always_comb begin
  //   T_idx        = CDB[CDB_index].T_idx;
  //   dest_idx     = CDB[CDB_index].dest_idx;
  //   T_value      = CDB[CDB_index].T_value;
  //   ROB_idx      = CDB[CDB_index].ROB_idx;
  //   complete_hit = (CDB_sel != 0);
  //   complete_idx = CDB_index;
  // end // always_comb