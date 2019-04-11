`timescale 1ns/100ps

module MSHR(
  input logic                                                    clock,
  input logic                                                    reset,
      
  //stored to cache input      
  input logic                                                    stored,
      
  //storing to the MSHR      
  input logic [3:0]                                              miss_en,
  input SASS_ADDR [3:0]                                          miss_addr,
  input logic [2:0][`NUM_BLOCK-1:0][(MEMORY_BLOCK_SIZE*8-1):0]   miss_data_in,
  input logic [`NUM_BLOCK-1:0][(MEMORY_BLOCK_SIZE*8-1):0]        evict_data_in,
  input MSHR_INST_TYPE [3:0]                                     inst_type,
  input logic [3:0][1:0]                                         mshr_proc2mem_command,
      
  //looking up the MSHR      
  input SASS_ADDR [2:0]                                          search_addr, //address to search
  input MSHR_INST_TYPE [2:0]                                     search_type, //address search type (might not need)
      
  output logic [1:0][63:0]                                       miss_data, //data returned
  output logic [1:0]                                             miss_data_valid, //if data returned is correct
  output logic [2:0]                                             addr_hit, // if address search in the MSHR
      
  output logic                                                   mem_wr,
  output logic                                                   mem_dirty,
  output logic [63:0]                                            mem_data,
  output SASS_ADDR                                               mem_addr,
      
  //mshr to cache      
  output logic                                                   mshr_valid,

  //mem to mshr
  input logic [3:0]                           mem2proc_response,
  input logic [63:0]                          mem2proc_data,     // data resulting from a load
  input logic [3:0]                           mem2proc_tag,       // 0 = no value, other=tag of transaction

  //cache to mshr
  output logic [63:0]                         proc2mem_addr,
  output logic [63:0]                         proc2mem_data,
  output logic [1:0]                          proc2mem_command
);

//need to be able to extend the addrs automatically to whole cache line

//cannot be gone from queus until it has finish sending inst to cache
//need to have logic to tell if the request is in progress, only delete when not in progress (like rob)

//need fucntionality that either updates data of the load_bus cmmd from st or set as a new entry.
//same mechanism for evicted BUS_STORE inst.

//for BUS transactions, need to have it be size of cache lines. use BO to set the data

  parameter ONE_LINE_ADD = 1*`NUM_BLOCK;
  parameter TWO_LINE_ADD = 2*`NUM_BLOCK;
  parameter THREE_LINE_ADD = 3*`NUM_BLOCK;
  parameter FOUR_LINE_ADD = 4*`NUM_BLOCK;
  parameter FIVE_LINE_ADD = 5*`NUM_BLOCK;
  parameter SIX_LINE_ADD = 6*`NUM_BLOCK;
  parameter SEVEN_LINE_ADD = 7*`NUM_BLOCK;

  //MSHR queue
  MSHR_ENTRY_t [MSHR_DEPTH-1:0] MSHR_queue, next_MSHR_queue;

  //head and tail pointer
  logic [$clog2(MSHR_DEPTH)-1:0] writeback_head, head, tail, next_writeback_head, next_head, next_tail;
  logic [3:0]                    tail_move;
  logic [3:0][1:0]               data_idx;
  logic [3:0]                    internal_miss_en1,internal_miss_en2,internal_miss_en3;
  logic [3:0]                    internal_miss_en2_mask,internal_miss_en3_mask,internal_miss_en4_mask;

  logic [$clog2(MSHR_DEPTH)-1:0] tail_plus_one, tail_plus_two, tail_plus_three, head_plus_one;
  //how many entries to allocate
  assign tail_move = miss_en[0] + miss_en[1] + miss_en[2] + miss_en[3];

  assign tail_plus_one = tail + 1;
  assign tail_plus_two = tail + 2;
  assign tail_plus_three = tail + 3;
  assign head_plus_one = head + 1;
  assign writeback_head_plus_one = writeback_head + 1;
  
  //mshr valid logic
  assign mshr_valid = MSHR_queue[tail].valid && MSHR_queue[tail_plus_one].valid && MSHR_queue[tail_plus_two].valid && MSHR_queue[tail_plus_three].valid;

  //priority logic
  always_comb begin
    internal_miss_en1 = miss_en & ~(internal_miss_en1_mask); //everything except the last bit
    internal_miss_en2 = internal_miss_en1 & ~(internal_miss_en2_mask); //everything except the 2 last bit
    internal_miss_en3 = internal_miss_en2 & ~(internal_miss_en3_mask); //everything except the 3 last bit
    // internal_miss_en4 = internal_miss_en3 & ~(internal_miss_en2_mask); //everything except the 4 last bit
  end

  ps priority1 (.req(miss_en), 1, .gnt(internal_miss_en1_mask));
  ps priority2 (.req(internal_miss_en1), 1, .gnt(internal_miss_en2_mask));
  ps priority3 (.req(internal_miss_en2), 1, .gnt(internal_miss_en3_mask));
  ps priority4 (.req(internal_miss_en3), 1, .gnt(internal_miss_en4_mask));

  pe idx_select1 (miss_en, data_idx[0]);
  pe idx_select2 (internal_miss_en1, data_idx[1]);
  pe idx_select3 (internal_miss_en2, data_idx[2]);
  pe idx_select4 (internal_miss_en3, data_idx[3]);

  //allocation logic
  always_comb begin
    next_MSHR_queue = MSHR_queue;
    next_tail = tail;
    case(tail_move)
      1: begin
        next_tail = tail + ONE_LINE_ADD; 
        for(int i = 0; i < ONE_LINE_ADD; i++) begin
          next_MSHR_queue[tail+i].valid = 1;
          next_MSHR_queue[tail+i].data = miss_data_in[data_idx[0]][i];
          next_MSHR_queue[tail+i].addr.tag = miss_addr[data_idx[0]].tag;
          next_MSHR_queue[tail+i].addr.set_index = miss_addr[data_idx[0]].set_index;
          next_MSHR_queue[tail+i].addr.BO = i;
          next_MSHR_queue[tail+i].inst_type = inst_type[data_idx[0]];
          next_MSHR_queue[tail+i].proc2mem_command = mshr_proc2mem_command[data_idx[0]];
          next_MSHR_queue[tail+i].complete = 0;
          next_MSHR_queue[tail+i].mem_tag = 0;
          next_MSHR_queue[tail+i].state = WAITING;
          next_MSHR_queue[tail+i].dirty = 0;
        end
      end
      2: begin
        next_tail = tail + TWO_LINE_ADD;
        for(int j = 0; j < 2; j++) begin
          for(int i = 0; i < TWO_LINE_ADD; i++) begin
            next_MSHR_queue[tail+i].valid = 1;
            next_MSHR_queue[tail+i].data = miss_data_in[data_idx[j]][i];
            next_MSHR_queue[tail+i].addr.tag = miss_addr[data_idx[j]].tag;
            next_MSHR_queue[tail+i].addr.set_index = miss_addr[data_idx[j]].set_index;
            next_MSHR_queue[tail+i].addr.BO = i;
            next_MSHR_queue[tail+i].inst_type = inst_type[data_idx[j]];
            next_MSHR_queue[tail+i].proc2mem_command = mshr_proc2mem_command[data_idx[j]];
            next_MSHR_queue[tail+i].complete = 0;
            next_MSHR_queue[tail+i].mem_tag = 0;
            next_MSHR_queue[tail+i].state = WAITING;
            next_MSHR_queue[tail+i].dirty = 0;
          end
        end
      end
      3: begin
        next_tail = tail + THREE_LINE_ADD; 
        for(int j = 0; j < 3; j++) begin
          for(int i = 0; i < THREE_LINE_ADD; i++) begin
            next_MSHR_queue[tail+i].valid = 1;
            next_MSHR_queue[tail+i].data = miss_data_in[data_idx[j]][i];
            next_MSHR_queue[tail+i].addr.tag = miss_addr[data_idx[j]].tag;
            next_MSHR_queue[tail+i].addr.set_index = miss_addr[data_idx[j]].set_index;
            next_MSHR_queue[tail+i].addr.BO = i;
            next_MSHR_queue[tail+i].inst_type = inst_type[data_idx[j]];
            next_MSHR_queue[tail+i].proc2mem_command = mshr_proc2mem_command[data_idx[j]];
            next_MSHR_queue[tail+i].complete = 0;
            next_MSHR_queue[tail+i].mem_tag = 0;
            next_MSHR_queue[tail+i].state = WAITING;
            next_MSHR_queue[tail+i].dirty = 0;
          end
        end
      end
      4: begin
        next_tail = tail + FOUR_LINE_ADD;
        for(int j = 0; j < 4; j++) begin
          for(int i = 0; i < FOUR_LINE_ADD; i++) begin
            next_MSHR_queue[tail+i].valid = 1;
            next_MSHR_queue[tail+i].data = miss_data_in[data_idx[j]][i];
            next_MSHR_queue[tail+i].addr.tag = miss_addr[data_idx[j]].tag;
            next_MSHR_queue[tail+i].addr.set_index = miss_addr[data_idx[j]].set_index;
            next_MSHR_queue[tail+i].addr.BO = i;
            next_MSHR_queue[tail+i].inst_type = inst_type[data_idx[j]];
            next_MSHR_queue[tail+i].proc2mem_command = mshr_proc2mem_command[data_idx[j]];
            next_MSHR_queue[tail+i].complete = 0;
            next_MSHR_queue[tail+i].mem_tag = 0;
            next_MSHR_queue[tail+i].state = WAITING;
            next_MSHR_queue[tail+i].dirty = 0;
          end
        end 
      end
      default: pass;
    endcase
  end

  //send data to mem

  //send to mem logic
  assign proc2mem_command = (MSHR_queue[head].valid & !MSHR_queue[head].complete) ? MSHR_queue[head].proc2mem_command : BUS_NONE;
  assign proc2mem_addr = MSHR_queue[head].addr;
  assign proc2mem_data = MSHR_queue[head].data;
  
  assign next_MSHR_queue[head].mem_tag = mem2proc_response;

  assign request_accepted = (mem2proc_response != 0);

  assign next_head = (request_accepted) ? head_plus_one : head;

  //if data is a store command and handled, invalidate as it is handled
  assign next_MSHR_queue[head].complete = (MSHR_queue[head].proc2mem_command == BUS_STORE) ? request_accepted : MSHR_queue[head].complete;

  assign next_MSHR_queue[head].state    = (request_accepted) ? INPROGRESS : MSHR_queue[head].state;

  
  //mem complete request
  always_comb begin
    for (int = i; i < `MSHR_DEPTH;i++) begin
      if(MSHR_queue[i].state == INPROGRESS && mem2proc_tag == MSHR_queue[i].mem_tag) begin
        next_MSHR_queue[head].complete = 1;
        next_MSHR_queue[head].state    = DONE;
        next_MSHR_queue[head].data     = mem2proc_data;
        next_MSHR_queue[head].dirty    = 0;
      end
    end
  end


  //logic to move the writeback head.
  assign mem_wr = MSHR_queue[writeback_head].valid & MSHR_queue[writeback_head].complete & MSHR_queue[writeback_head].proc2mem_command == BUS_LOAD;
  assign mem_dirty = MSHR_queue[writeback_head].dirty;
  assign mem_data = MSHR_queue[writeback_head].data;
  assign mem_addr = MSHR_queue[writeback_head].addr;

  //retire logic
  assign next_writeback_head = (stored)? writeback_head_plus_one : writeback_head;
  assign next_MSHR_queue[head].valid = (stored) ? 0 : MSHR_queue[head].valid;


  //search logic
  always_comb begin
    //if type of searcher is load
    addr_hit = 0;
    miss_data_valid = 0;
    for (int i = 0; i < `MSHR_DEPTH; i++) begin
      //rd1 search
      if((search_addr[0] == MSHR_queue[i].addr) && (search_type[0] == LOAD)) begin
        if(MSHR_queue[i].proc2mem_command == BUS_STORE) begin
          rd1_data = MSHR_queue[i].data;
          miss_data_valid[0] = 1;
          forwards = 
        end
        else
          addr_hit[0] = 1; 
      end

      //rd2 search
      if((search_addr[1] == MSHR_queue[i].addr) && (search_type[1] == LOAD)) begin
        if(MSHR_queue[i].proc2mem_command == BUS_STORE) begin
          rd2_data = MSHR_queue[i].data;
          miss_data_valid[1] = 1;
        end
        else
          addr_hit[1] = 1; 
      end

      //wr1 search
      if((search_addr[2] == MSHR_queue[i].addr) && (search_type[2] == LOAD)) begin
        if(MSHR_queue[i].proc2mem_command == BUS_STORE) begin
          
        end
        else
          addr_hit[2] = 1; 
      end

    end
  end


  



  //receive data back from mem
  always_comb begin
    data
  end

  always_ff @(posedge clock) begin
    if(reset) begin
      for(int i = 0; i < MSHR_DEPTH; i++) begin
        MSHR_queue[i].valid <= `SD 0;
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

module pe(gnt,enc);
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
        if (j[i])
          assign enc[i] = gnt[j];
      end
    end
  endgenerate
endmodule

module ps (req, en, gnt, req_up);
  //synopsys template
  parameter NUM_BITS = 8;
  
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