`ifndef __ROB_VH__
`define __ROB_VH__

`include "../../sys_config.vh"

typedef struct packed {
  logic valid;
  logic [$clog2(`NUM_PR)-1:0] T;
  logic [$clog2(`NUM_PR)-1:0] T_old;
  logic complete;
} ROB_ENTRY_t;

typedef struct packed {
  logic [$clog2(`NUM_ROB)-1:0] head;
  logic [$clog2(`NUM_ROB)-1:0] tail;
  ROB_ENTRY_t [`NUM_ROB-1:0] entry;
} ROB_t;

typedef struct packed {
  //logic r;                                        //retire, increase head, invalidate entry
  logic inst_dispatch;                            //dispatch, increase tail, validate entry
  logic [$clog2(`NUM_PR)-1:0]  T_in;               //T_in data to input to T during dispatch
  logic [$clog2(`NUM_PR)-1:0]  T_old_in;           //T_onld_in data to input to T_old during dispatch
  logic [$clog2(`NUM_ROB)-1:0] flush_branch_idx;  //ROB idx of branch inst
  logic branch_mispredict;                        //set high when branch mispredicted, will invalidate entry except branch inst
} ROB_PACKET_IN;

typedef struct packed {
  logic [$clog2(`NUM_PR)-1:0] T_out;              //output tail's T
  logic [$clog2(`NUM_PR)-1:0] T_old_out;          //output tail's T_old
  logic out_correct;                              //tells whether output is valid (empty entry)
  logic struct_hazard;                            //tells whether structural hazard reached
  // logic [$clog2(`NUM_ROB)-1:0] head_idx_out;      //tells the rob idx of the head
  // logic [$clog2(`NUM_ROB)-1:0] ins_rob_idx;       //tells the rob idx of the dispatched inst
} ROB_PACKET_OUT;

typedef struct packed {
  logic [$clog2(`NUM_PR)-1:0] head_T_old_out;          //output head's T_old
  logic freePR;                                        //free the PR
} ROB_PACKET_OUT_TO_FREELIST;

typedef struct packed {
  logic                       valid;                                // valid signal to free idx
  logic [$clog2(`NUM_PR)-1:0] T;                                    // tag to PR
} ROB_PACKET_COMPLETE_IN;

`endif


//SEND RETIRE signal to PR, Told to PR freeing (freelist)
//TAKE IN CDB (tag and valid) to update the complete column.
//check the head and the complete bit is set if so retire is activated.