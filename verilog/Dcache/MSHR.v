`timescale 1ns/100ps

module MSHR(
  input logic                                                    clock,
  input logic                                                    reset,
      
  //stored to cache input      
  input logic                                                    stored_rd_wb,
  input logic                                                    stored_wr_wb,
  input logic                                                    stored_mem_wr,
      
  //storing to the MSHR      
  input logic [2:0]                                              miss_en,
  input SASS_ADDR [2:0]                                          miss_addr,
  input logic [2:0][63:0]                                        miss_data_in,
  input MSHR_INST_TYPE [2:0]                                     inst_type,
  input logic [2:0][1:0]                                         mshr_proc2mem_command,
      
  //looking up the MSHR      
  input SASS_ADDR [1:0]                                          search_addr, //address to search
  input MSHR_INST_TYPE [1:0]                                     search_type, //address search type (might not need)
  input [63:0]                                                   search_wr_data,
      
`ifdef DEBUG
  output MSHR_ENTRY_t [`MSHR_DEPTH-1:0]                          MSHR_queue,
`endif
  output logic [1:0]                                             miss_addr_hit, // if address search in the MSHR
      
  output logic                                                   mem_wr,
  output logic                                                   mem_dirty,
  output logic [63:0]                                            mem_data,
  output SASS_ADDR                                               mem_addr,

  output logic                                                   rd_wb_en,
  output logic                                                   rd_wb_dirty,
  output logic [63:0]                                            rd_wb_data,
  output SASS_ADDR                                               rd_wb_addr,

  output logic                                                   wr_wb_en,
  output logic                                                   wr_wb_dirty,
  output logic [63:0]                                            wr_wb_data,
  output SASS_ADDR                                               wr_wb_addr,

  //mshr to cache      
  output logic                                                   mshr_valid,
  output logic                                                   mshr_empty,

  //mem to mshr
  input logic [3:0]                                             mem2proc_response,
  input logic [63:0]                                            mem2proc_data,     // data resulting from a load
  input logic [3:0]                                             mem2proc_tag,       // 0 = no value, other=tag of transaction

  //cache to mshr
  output logic [63:0]                                           proc2mem_addr,
  output logic [63:0]                                           proc2mem_data,
  output logic [1:0]                                            proc2mem_command
);

//need to be able to extend the addrs automatically to whole cache line

//cannot be gone from queus until it has finish sending inst to cache
//need to have logic to tell if the request is in progress, only delete when not in progress (like rob)

//need fucntionality that either updates data of the load_bus cmmd from st or set as a new entry.
//same mechanism for evicted BUS_STORE inst.


//for BUS transactions, need to have it be size of cache lines. use BO to set the data

//need logic to check priority

  //MSHR queue
`ifndef DEBUG
  MSHR_ENTRY_t [`MSHR_DEPTH-1:0] MSHR_queue;
`endif
  MSHR_ENTRY_t [`MSHR_DEPTH-1:0] next_MSHR_queue;

  //head and tail pointer
  logic [$clog2(`MSHR_DEPTH)-1:0] writeback_head, head, tail, next_writeback_head, next_head, next_tail, writeback_head_plus_one;
  logic [1:0]                    tail_move;
  logic [2:0][1:0]               data_idx;
  logic [3:0]                    internal_miss_en1,internal_miss_en2;
  logic [3:0]                    internal_miss_en1_mask, internal_miss_en2_mask, internal_miss_en3_mask;
  logic [`MSHR_DEPTH-1:0]        dummywire;
  logic                          request_accepted;

  logic [$clog2(`MSHR_DEPTH)-1:0] tail_plus_one, tail_plus_two, tail_plus_three, head_plus_one;
  logic [$clog2(`MSHR_DEPTH)] index_rd_search, index_wr_search, index;

  //how many entries to allocate
  assign tail_move = miss_en[0] + miss_en[1] + miss_en[2];

  assign tail_plus_one = tail + 1;
  assign tail_plus_two = tail + 2;
  assign tail_plus_three = tail + 3;
  assign head_plus_one = head + 1;
  assign writeback_head_plus_one = writeback_head + 1;
  
  //mshr valid logic
  // assign mshr_valid = MSHR_queue[tail].valid && MSHR_queue[tail_plus_one].valid && MSHR_queue[tail_plus_two].valid;
  assign mshr_valid = (tail != head) || (tail_plus_one != head) || (tail_plus_two != head);


  //mshr is empty
  always_comb begin
    for(int i = 0; i < `MSHR_DEPTH; i++) begin
      dummywire[i] = MSHR_queue[i].valid;
    end
    mshr_empty = ~(|dummywire);
  end

  //priority logic
  always_comb begin
    internal_miss_en1 = {1'b0,miss_en} & ~(internal_miss_en1_mask); //everything except the last bit
    internal_miss_en2 = internal_miss_en1 & ~(internal_miss_en2_mask); //everything except the 2 last bit
  end

  ps priority1 (.req({1'b0,miss_en}), .en(1'b1), .gnt(internal_miss_en1_mask));
  ps priority2 (.req(internal_miss_en1), .en(1'b1), .gnt(internal_miss_en2_mask));
  ps priority3 (.req(internal_miss_en2), .en(1'b1), .gnt(internal_miss_en3_mask));

  pe_mshr idx_select1 ({1'b0,miss_en}, data_idx[0]);
  pe_mshr idx_select2 (internal_miss_en1, data_idx[1]);
  pe_mshr idx_select3 (internal_miss_en2, data_idx[2]);

  //allocation logic
  always_comb begin
    next_MSHR_queue = MSHR_queue;
    next_tail = tail;
    case(tail_move)
      1: begin
        next_tail = tail_plus_one;
        next_MSHR_queue[tail].valid = 1;
        next_MSHR_queue[tail].data = miss_data_in[data_idx[0]];
        next_MSHR_queue[tail].addr = miss_addr[data_idx[0]];
        next_MSHR_queue[tail].inst_type = inst_type[data_idx[0]];
        next_MSHR_queue[tail].proc2mem_command = mshr_proc2mem_command[data_idx[0]];
        next_MSHR_queue[tail].complete = 0;
        next_MSHR_queue[tail].mem_tag = 0;
        next_MSHR_queue[tail].state = WAITING;
        next_MSHR_queue[tail].dirty = 0;
      end
      2: begin
        next_tail = tail_plus_two;
        next_MSHR_queue[tail].valid = 1;
        next_MSHR_queue[tail].data = miss_data_in[data_idx[1]];
        next_MSHR_queue[tail].addr = miss_addr[data_idx[1]];
        next_MSHR_queue[tail].inst_type = inst_type[data_idx[1]];
        next_MSHR_queue[tail].proc2mem_command = mshr_proc2mem_command[data_idx[1]];
        next_MSHR_queue[tail].complete = 0;
        next_MSHR_queue[tail].mem_tag = 0;
        next_MSHR_queue[tail].state = WAITING;
        next_MSHR_queue[tail].dirty = 0;

  
        next_MSHR_queue[tail_plus_one].valid = 1;
        next_MSHR_queue[tail_plus_one].data = miss_data_in[data_idx[0]];
        next_MSHR_queue[tail_plus_one].addr = miss_addr[data_idx[0]];
        next_MSHR_queue[tail_plus_one].inst_type = inst_type[data_idx[0]];
        next_MSHR_queue[tail_plus_one].proc2mem_command = mshr_proc2mem_command[data_idx[0]];
        next_MSHR_queue[tail_plus_one].complete = 0;
        next_MSHR_queue[tail_plus_one].mem_tag = 0;
        next_MSHR_queue[tail_plus_one].state = WAITING;
        next_MSHR_queue[tail_plus_one].dirty = 0;
      end
      3: begin
        next_tail = tail_plus_three;
        next_MSHR_queue[tail].valid = 1;
        next_MSHR_queue[tail].data = miss_data_in[data_idx[2]];
        next_MSHR_queue[tail].addr = miss_addr[data_idx[2]];
        next_MSHR_queue[tail].inst_type = inst_type[data_idx[2]];
        next_MSHR_queue[tail].proc2mem_command = mshr_proc2mem_command[data_idx[2]];
        next_MSHR_queue[tail].complete = 0;
        next_MSHR_queue[tail].mem_tag = 0;
        next_MSHR_queue[tail].state = WAITING;
        next_MSHR_queue[tail].dirty = 0;

        next_MSHR_queue[tail_plus_one].valid = 1;
        next_MSHR_queue[tail_plus_one].data = miss_data_in[data_idx[1]];
        next_MSHR_queue[tail_plus_one].addr = miss_addr[data_idx[1]];
        next_MSHR_queue[tail_plus_one].inst_type = inst_type[data_idx[1]];
        next_MSHR_queue[tail_plus_one].proc2mem_command = mshr_proc2mem_command[data_idx[1]];
        next_MSHR_queue[tail_plus_one].complete = 0;
        next_MSHR_queue[tail_plus_one].mem_tag = 0;
        next_MSHR_queue[tail_plus_one].state = WAITING;
        next_MSHR_queue[tail_plus_one].dirty = 0;

        next_MSHR_queue[tail_plus_two].valid = 1;
        next_MSHR_queue[tail_plus_two].data = miss_data_in[data_idx[0]];
        next_MSHR_queue[tail_plus_two].addr = miss_addr[data_idx[0]];
        next_MSHR_queue[tail_plus_two].inst_type = inst_type[data_idx[0]];
        next_MSHR_queue[tail_plus_two].proc2mem_command = mshr_proc2mem_command[data_idx[0]];
        next_MSHR_queue[tail_plus_two].complete = 0;
        next_MSHR_queue[tail_plus_two].mem_tag = 0;
        next_MSHR_queue[tail_plus_two].state = WAITING;
        next_MSHR_queue[tail_plus_two].dirty = 0;
      end
    endcase

    //send to mem nextqueue logic

    next_MSHR_queue[head].mem_tag = mem2proc_response;

    //if data is a store command and handled, invalidate as it is handled
    next_MSHR_queue[head].complete = (MSHR_queue[head].proc2mem_command == BUS_STORE) ? request_accepted : MSHR_queue[head].complete;

    next_MSHR_queue[head].state    = (request_accepted) ? INPROGRESS : MSHR_queue[head].state;


    //mem complete request
    for (int i = 0; i < `MSHR_DEPTH;i++) begin
      if(MSHR_queue[i].state == INPROGRESS && mem2proc_tag == MSHR_queue[i].mem_tag && MSHR_queue[i].valid) begin
        next_MSHR_queue[i].complete = 1;
        next_MSHR_queue[i].state    = DONE;
        next_MSHR_queue[i].data     = mem2proc_data;
        next_MSHR_queue[i].dirty    = 0;
      end
    end

    //retire logic
    next_MSHR_queue[writeback_head].valid = (stored_mem_wr) ? 0 : MSHR_queue[head].valid;

    //search logic
    //if type of searcher is load
    miss_addr_hit = 0;
    rd_wb_en = 0;
    wr_wb_en = 0;
    for(int i = 0; i < `MSHR_DEPTH; i++) begin
      index = head + i;
      if((search_addr[0] == MSHR_queue[index].addr) && (search_type[0] == LOAD) && MSHR_queue[index].valid) begin
        index_rd_search = index;
        miss_addr_hit[0] = 1;
      end

      if((search_addr[1] == MSHR_queue[i].addr) && (search_type[1] == STORE) && MSHR_queue[index].valid) begin
        index_wr_search = index;
      end
    end

    //load
    if(MSHR_queue[index_rd_search].proc2mem_command == BUS_STORE) begin
      rd_wb_en = 1;
      rd_wb_dirty = 0;
      rd_wb_data = MSHR_queue[index_rd_search].data;
      rd_wb_addr = MSHR_queue[index_rd_search].addr;
    end

    //store
    if(MSHR_queue[index_wr_search].proc2mem_command == BUS_STORE) begin
      miss_addr_hit[1] = 1;
      next_MSHR_queue[index_wr_search].dirty = 0;
      next_MSHR_queue[index_wr_search].data = search_wr_data;

      wr_wb_en = 1;
      wr_wb_addr = MSHR_queue[index_wr_search].addr;
      wr_wb_data = search_wr_data;
      wr_wb_dirty = 0;
    end
    else begin
      if(MSHR_queue[index_wr_search].inst_type == LOAD) begin
        miss_addr_hit[1] = 0; //make the store send to mshr
      end
      else begin
        next_MSHR_queue[index_wr_search].data = search_wr_data;
        next_MSHR_queue[index_wr_search].dirty = 1;
      end
    end
  end

  //send data to mem

  //send to mem logic
  assign proc2mem_command = (MSHR_queue[head].valid & !MSHR_queue[head].complete) ? MSHR_queue[head].proc2mem_command : BUS_NONE;
  assign proc2mem_addr = MSHR_queue[head].addr;
  assign proc2mem_data = MSHR_queue[head].data;
  
  assign request_accepted = (mem2proc_response != 0);

  assign next_head = (request_accepted) ? head_plus_one : head;

  //logic to move the writeback head.
  assign mem_wr = MSHR_queue[writeback_head].valid & MSHR_queue[writeback_head].complete & MSHR_queue[writeback_head].proc2mem_command == BUS_LOAD;
  assign mem_dirty = MSHR_queue[writeback_head].dirty;
  assign mem_data = MSHR_queue[writeback_head].data;
  assign mem_addr = MSHR_queue[writeback_head].addr;

  //retire logic
  assign next_writeback_head = (stored_mem_wr || MSHR_queue[writeback_head].proc2mem_command != BUS_LOAD) ? writeback_head_plus_one : writeback_head;
 
  always_ff @(posedge clock) begin
    if(reset) begin
      for(int i = 0; i < `MSHR_DEPTH; i++) begin
        MSHR_queue <= `SD 0;
      end
      writeback_head <= `SD 0;
      head           <= `SD 0;
      tail           <= `SD 0;
    end
    else begin
      MSHR_queue     <= `SD next_MSHR_queue;
      writeback_head <= `SD next_writeback_head;
      head           <= `SD next_head;
      tail           <= `SD next_tail;
    end
  end
endmodule

module pe_mshr(gnt,enc);
  //synopsys template
  parameter OUT_WIDTH=2;
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
        if (j[i]) begin : if1
          assign enc[i] = gnt[j];
        end
      end
    end
  endgenerate
endmodule

module ps (req, en, gnt);
  //synopsys template
  parameter NUM_BITS = 4;
  
    input  [NUM_BITS-1:0] req;
    input                 en;
  
    output [NUM_BITS-1:0] gnt;
    logic                req_up;
          
    wire   [NUM_BITS-2:0] req_ups;
    wire   [NUM_BITS-2:0] enables;
          
    assign req_up = req_ups[NUM_BITS-2];
    assign enables[NUM_BITS-2] = en;
          
    genvar i,j;
    generate
      if ( NUM_BITS == 2 )
      begin : gen1
        ps2 single (.req(req),.en(en),.gnt(gnt),.req_up(req_up));
      end
      else
      begin : gen2
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