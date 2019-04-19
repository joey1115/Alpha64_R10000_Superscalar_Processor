`timescale 1ns/100ps

module MSHR(
  input logic                                                    clock,
  input logic                                                    reset,
  input D_CACHE_MSHR_OUT_t                                       d_cache_mshr_out,
  // input logic                                                    stored_rd_wb,
  input logic                                                    stored_mem_wr,
      
`ifdef DEBUG
  output MSHR_ENTRY_t [`MSHR_DEPTH-1:0]                          MSHR_queue,
  output logic [$clog2(`MSHR_DEPTH)-1:0]                         writeback_head, head, tail,
`endif
  // //mshr to cache      
  output logic                                                   mshr_valid,
  output logic                                                   mshr_empty,
  output MSHR_D_CACHE_OUT_t                                      mshr_d_cache_out,
  //mem to mshr
  input logic [3:0]                                              mem2proc_response,
  input logic [63:0]                                             mem2proc_data,     // data resulting from a load
  input logic [3:0]                                              mem2proc_tag,       // 0 = no value, other=tag of transaction

  //cache to mshr
  output logic [63:0]                                            proc2mem_addr,
  output logic [63:0]                                            proc2mem_data,
  output logic [1:0]                                             proc2mem_command
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
`ifndef DEBUG
  logic [$clog2(`MSHR_DEPTH)-1:0] writeback_head, head, tail;
`endif
  logic [$clog2(`MSHR_DEPTH)-1:0] next_writeback_head, next_head, next_tail, writeback_head_plus_one;
  // logic [2:0][1:0]               data_idx;
  // logic [3:0]                    internal_miss_en1,internal_miss_en2;
  // logic [3:0]                    internal_miss_en1_mask, internal_miss_en2_mask, internal_miss_en3_mask;
  logic [`MSHR_DEPTH-1:0]        dummywire;
  logic                          request_accepted;

  logic [$clog2(`MSHR_DEPTH)-1:0] tail_plus_one, tail_plus_two, tail_plus_three, tail_plus_four, head_plus_one;
  logic [$clog2(`MSHR_DEPTH)-1:0] index_rd_search, index_wr_search;
  logic [`MSHR_DEPTH-1:0][$clog2(`MSHR_DEPTH)-1:0]index;

  logic rd_search_hit, wr_search_hit;

  logic pending_rd_bus_load, pending_wr_bus_load, pending_bus_load;
  
  logic changed_rd_input, changed_wr_input, prev_changed_wr_input;

  SASS_ADDR current_rd_addr, last_rd_addr;
  SASS_ADDR current_wr_addr, last_wr_addr;


  //how many entries to allocate
  // assign tail_move = d_cache_mshr_out.miss_en[0] + d_cache_mshr_out.miss_en[1] + d_cache_mshr_out.miss_en[2];

  assign tail_plus_one = tail + 1;
  assign tail_plus_two = tail + 2;
  assign tail_plus_three = tail + 3;
  assign tail_plus_four = tail + 4;
  assign head_plus_one = head + 1;
  assign writeback_head_plus_one = writeback_head + 1;
  
  //mshr valid logic
  assign mshr_valid = !MSHR_queue[tail].valid && !MSHR_queue[tail_plus_one].valid && !MSHR_queue[tail_plus_two].valid && !MSHR_queue[tail_plus_three].valid;

  //mshr is empty
  always_comb begin
    for(int i = 0; i < `MSHR_DEPTH; i++) begin
      dummywire[i] = MSHR_queue[i].valid;
    end
    mshr_empty = ~(|dummywire);
  end

  //search
  always_comb begin
    for(int i= 0; i < `MSHR_DEPTH; i++) begin
      index[i] = head + i;
    end
  end

  always_comb begin
    index_rd_search = 0;
    rd_search_hit = 0;
    if (d_cache_mshr_out.inst_type[0] == LOAD & d_cache_mshr_out.miss_en[0]) begin
      for(int i = 0; i < `MSHR_DEPTH; i++) begin
        if((d_cache_mshr_out.miss_addr[0] == MSHR_queue[index[i]].addr) && MSHR_queue[index[i]].valid) begin
          index_rd_search = i;
          rd_search_hit = 1;
          break;
        end
      end
    end
  end

  always_comb begin
    index_wr_search = 0;
    wr_search_hit = 0;
    if (d_cache_mshr_out.inst_type[1] == STORE & d_cache_mshr_out.miss_en[1]) begin
      for(int i = 0; i < `MSHR_DEPTH; i++) begin
        if((d_cache_mshr_out.miss_addr[1] == MSHR_queue[index[i]].addr) && MSHR_queue[index[i]].valid) begin
          //overwrite condition
          index_wr_search = i;
          wr_search_hit = 1;
          break;
        end
      end
    end
  end

  //load
  always_comb begin
    mshr_d_cache_out.rd_wb_en = 0;
    mshr_d_cache_out.rd_wb_dirty = 0;
    mshr_d_cache_out.rd_wb_data = 0;
    mshr_d_cache_out.rd_wb_addr = 0;
    if(MSHR_queue[index[index_rd_search]].proc2mem_command == BUS_STORE && rd_search_hit && MSHR_queue[index[index_rd_search]].valid) begin
      mshr_d_cache_out.rd_wb_en = 1;
      mshr_d_cache_out.rd_wb_dirty = 0;
      mshr_d_cache_out.rd_wb_data = MSHR_queue[index[index_rd_search]].data;
      mshr_d_cache_out.rd_wb_addr = MSHR_queue[index[index_rd_search]].addr;
    end
  end

  // always_comb begin
  //   case(tail_move)
  //     2'b00: begin
  //       next_tail = tail;
  //     end
  //     2'b01: begin
  //       next_tail = tail_plus_one;
  //     end
  //     2'b10: begin
  //       next_tail = tail_plus_two;
  //     end
  //     2'b11: begin
  //       next_tail = tail_plus_three;
  //     end
  //   endcase
  // end

  //retire logic
  assign next_writeback_head = ((stored_mem_wr || MSHR_queue[writeback_head].proc2mem_command == BUS_STORE) && MSHR_queue[writeback_head].complete && MSHR_queue[writeback_head].valid) ? writeback_head_plus_one : writeback_head;

  assign request_accepted = (mem2proc_response != 0);

  assign next_head = (request_accepted) ? head_plus_one : head;

  //change logic
  assign current_rd_addr = d_cache_mshr_out.miss_addr[0];
  assign changed_rd_input = current_rd_addr != last_rd_addr;

  assign current_wr_addr = d_cache_mshr_out.miss_addr[1];
  assign changed_wr_input = current_wr_addr != last_wr_addr;
  


  //allocation logic
  always_comb begin
    next_MSHR_queue = MSHR_queue;
    
    //store
    pending_bus_load = 0;
    if(wr_search_hit & MSHR_queue[index[index_wr_search]].valid) begin
      if(MSHR_queue[index[index_wr_search]].inst_type == STORE && MSHR_queue[index[index_wr_search]].proc2mem_command == BUS_LOAD) begin
        next_MSHR_queue[index[index_wr_search]].data = d_cache_mshr_out.miss_data_in[1];
        next_MSHR_queue[index[index_wr_search]].dirty = 1;
      end
      else begin
        pending_bus_load = 1;
      end
    end

    //retire logic
    // MSHR_queue change
    next_MSHR_queue[writeback_head].valid = ((stored_mem_wr || MSHR_queue[writeback_head].proc2mem_command == BUS_STORE) && MSHR_queue[writeback_head].complete && MSHR_queue[writeback_head].valid) ? 0 : MSHR_queue[writeback_head].valid;

    //mem complete request
    for (int i = 0; i < `MSHR_DEPTH;i++) begin
      if(MSHR_queue[i].state == INPROGRESS && mem2proc_tag == MSHR_queue[i].mem_tag && MSHR_queue[i].valid) begin
        next_MSHR_queue[i].complete = 1;
        next_MSHR_queue[i].state    = DONE;
        next_MSHR_queue[i].data     = (MSHR_queue[i].inst_type == LOAD) ? mem2proc_data : MSHR_queue[i].data;
        next_MSHR_queue[i].dirty    = (MSHR_queue[i].inst_type == LOAD) ? 0 : MSHR_queue[i].dirty;
      end
    end

    //if data is a store command and handled, invalidate as it is handled
    next_MSHR_queue[head].complete = (MSHR_queue[head].proc2mem_command == BUS_STORE & request_accepted) ? 1 : MSHR_queue[head].complete;

    next_MSHR_queue[head].state    = (request_accepted) ? INPROGRESS : MSHR_queue[head].state;

    next_MSHR_queue[head].mem_tag = mem2proc_response;

    pending_rd_bus_load = d_cache_mshr_out.miss_en[0] && !rd_search_hit && changed_rd_input;
    pending_wr_bus_load = d_cache_mshr_out.miss_en[1] && !wr_search_hit;// && prev_changed_wr_input;

    next_tail = tail;
    if(pending_rd_bus_load & !pending_wr_bus_load & !pending_bus_load & !d_cache_mshr_out.miss_en[2]) begin
      next_MSHR_queue[tail].valid = 1;
      next_MSHR_queue[tail].data = d_cache_mshr_out.miss_data_in[0];
      next_MSHR_queue[tail].addr = d_cache_mshr_out.miss_addr[0];
      next_MSHR_queue[tail].inst_type = d_cache_mshr_out.inst_type[0];
      next_MSHR_queue[tail].proc2mem_command = d_cache_mshr_out.mshr_proc2mem_command[0];
      next_MSHR_queue[tail].complete = 0;
      next_MSHR_queue[tail].mem_tag = 0;
      next_MSHR_queue[tail].state = WAITING;
      next_MSHR_queue[tail].dirty = d_cache_mshr_out.miss_dirty[0];

      next_tail = tail_plus_one;
    end
    else if(!pending_rd_bus_load & pending_wr_bus_load & !pending_bus_load & !d_cache_mshr_out.miss_en[2]) begin
      next_MSHR_queue[tail].valid = 1;
      next_MSHR_queue[tail].data = d_cache_mshr_out.miss_data_in[1];
      next_MSHR_queue[tail].addr = d_cache_mshr_out.miss_addr[1];
      next_MSHR_queue[tail].inst_type = d_cache_mshr_out.inst_type[1];
      next_MSHR_queue[tail].proc2mem_command = d_cache_mshr_out.mshr_proc2mem_command[1];
      next_MSHR_queue[tail].complete = 0;
      next_MSHR_queue[tail].mem_tag = 0;
      next_MSHR_queue[tail].state = WAITING;
      next_MSHR_queue[tail].dirty = d_cache_mshr_out.miss_dirty[1];

      next_tail = tail_plus_one;
    end
    else if(!pending_rd_bus_load & !pending_wr_bus_load & pending_bus_load & !d_cache_mshr_out.miss_en[2]) begin
      next_MSHR_queue[tail].valid = 1;
      next_MSHR_queue[tail].data = d_cache_mshr_out.miss_data_in[1];
      next_MSHR_queue[tail].addr = d_cache_mshr_out.miss_addr[1];
      next_MSHR_queue[tail].inst_type = d_cache_mshr_out.inst_type[1];
      next_MSHR_queue[tail].proc2mem_command = BUS_LOAD;
      next_MSHR_queue[tail].complete = 0;
      next_MSHR_queue[tail].mem_tag = 0;
      next_MSHR_queue[tail].state = WAITING;
      next_MSHR_queue[tail].dirty = d_cache_mshr_out.miss_dirty[1];

      next_tail = tail_plus_one;
    end
    else if(!pending_rd_bus_load & !pending_wr_bus_load & !pending_bus_load & d_cache_mshr_out.miss_en[2]) begin
      next_MSHR_queue[tail].valid = 1;
      next_MSHR_queue[tail].data = d_cache_mshr_out.miss_data_in[2];
      next_MSHR_queue[tail].addr = d_cache_mshr_out.miss_addr[2];
      next_MSHR_queue[tail].inst_type = d_cache_mshr_out.inst_type[2];
      next_MSHR_queue[tail].proc2mem_command = d_cache_mshr_out.mshr_proc2mem_command[2];
      next_MSHR_queue[tail].complete = 0;
      next_MSHR_queue[tail].mem_tag = 0;
      next_MSHR_queue[tail].state = WAITING;
      next_MSHR_queue[tail].dirty = d_cache_mshr_out.miss_dirty[2];

      next_tail = tail_plus_one;
    end
    else if(pending_rd_bus_load & pending_wr_bus_load & !pending_bus_load & !d_cache_mshr_out.miss_en[2]) begin
      next_MSHR_queue[tail].valid = 1;
      next_MSHR_queue[tail].data = d_cache_mshr_out.miss_data_in[0];
      next_MSHR_queue[tail].addr = d_cache_mshr_out.miss_addr[0];
      next_MSHR_queue[tail].inst_type = d_cache_mshr_out.inst_type[0];
      next_MSHR_queue[tail].proc2mem_command = d_cache_mshr_out.mshr_proc2mem_command[0];
      next_MSHR_queue[tail].complete = 0;
      next_MSHR_queue[tail].mem_tag = 0;
      next_MSHR_queue[tail].state = WAITING;
      next_MSHR_queue[tail].dirty = d_cache_mshr_out.miss_dirty[0];

      next_MSHR_queue[tail_plus_one].valid = 1;
      next_MSHR_queue[tail_plus_one].data = d_cache_mshr_out.miss_data_in[1];
      next_MSHR_queue[tail_plus_one].addr = d_cache_mshr_out.miss_addr[1];
      next_MSHR_queue[tail_plus_one].inst_type = d_cache_mshr_out.inst_type[1];
      next_MSHR_queue[tail_plus_one].proc2mem_command = d_cache_mshr_out.mshr_proc2mem_command[1];
      next_MSHR_queue[tail_plus_one].complete = 0;
      next_MSHR_queue[tail_plus_one].mem_tag = 0;
      next_MSHR_queue[tail_plus_one].state = WAITING;
      next_MSHR_queue[tail_plus_one].dirty = d_cache_mshr_out.miss_dirty[1];

      next_tail = tail_plus_two;
    end
    else if(pending_rd_bus_load & !pending_wr_bus_load & pending_bus_load & !d_cache_mshr_out.miss_en[2]) begin
      next_MSHR_queue[tail].valid = 1;
      next_MSHR_queue[tail].data = d_cache_mshr_out.miss_data_in[0];
      next_MSHR_queue[tail].addr = d_cache_mshr_out.miss_addr[0];
      next_MSHR_queue[tail].inst_type = d_cache_mshr_out.inst_type[0];
      next_MSHR_queue[tail].proc2mem_command = d_cache_mshr_out.mshr_proc2mem_command[0];
      next_MSHR_queue[tail].complete = 0;
      next_MSHR_queue[tail].mem_tag = 0;
      next_MSHR_queue[tail].state = WAITING;
      next_MSHR_queue[tail].dirty = d_cache_mshr_out.miss_dirty[0];

      next_MSHR_queue[tail_plus_one].valid = 1;
      next_MSHR_queue[tail_plus_one].data = d_cache_mshr_out.miss_data_in[1];
      next_MSHR_queue[tail_plus_one].addr = d_cache_mshr_out.miss_addr[1];
      next_MSHR_queue[tail_plus_one].inst_type = d_cache_mshr_out.inst_type[1];
      next_MSHR_queue[tail_plus_one].proc2mem_command = BUS_LOAD;
      next_MSHR_queue[tail_plus_one].complete = 0;
      next_MSHR_queue[tail_plus_one].mem_tag = 0;
      next_MSHR_queue[tail_plus_one].state = WAITING;
      next_MSHR_queue[tail_plus_one].dirty = d_cache_mshr_out.miss_dirty[1];

      next_tail = tail_plus_two;
    end
    else if(pending_rd_bus_load & !pending_wr_bus_load & !pending_bus_load & d_cache_mshr_out.miss_en[2]) begin
      next_MSHR_queue[tail].valid = 1;
      next_MSHR_queue[tail].data = d_cache_mshr_out.miss_data_in[0];
      next_MSHR_queue[tail].addr = d_cache_mshr_out.miss_addr[0];
      next_MSHR_queue[tail].inst_type = d_cache_mshr_out.inst_type[0];
      next_MSHR_queue[tail].proc2mem_command = d_cache_mshr_out.mshr_proc2mem_command[0];
      next_MSHR_queue[tail].complete = 0;
      next_MSHR_queue[tail].mem_tag = 0;
      next_MSHR_queue[tail].state = WAITING;
      next_MSHR_queue[tail].dirty = d_cache_mshr_out.miss_dirty[0];

      next_MSHR_queue[tail_plus_one].valid = 1;
      next_MSHR_queue[tail_plus_one].data = d_cache_mshr_out.miss_data_in[2];
      next_MSHR_queue[tail_plus_one].addr = d_cache_mshr_out.miss_addr[2];
      next_MSHR_queue[tail_plus_one].inst_type = d_cache_mshr_out.inst_type[2];
      next_MSHR_queue[tail_plus_one].proc2mem_command = d_cache_mshr_out.mshr_proc2mem_command[2];
      next_MSHR_queue[tail_plus_one].complete = 0;
      next_MSHR_queue[tail_plus_one].mem_tag = 0;
      next_MSHR_queue[tail_plus_one].state = WAITING;
      next_MSHR_queue[tail_plus_one].dirty = d_cache_mshr_out.miss_dirty[2];

      next_tail = tail_plus_two;
    end
    else if(!pending_rd_bus_load & pending_wr_bus_load & pending_bus_load & !d_cache_mshr_out.miss_en[2]) begin
      next_MSHR_queue[tail].valid = 1;
      next_MSHR_queue[tail].data = d_cache_mshr_out.miss_data_in[1];
      next_MSHR_queue[tail].addr = d_cache_mshr_out.miss_addr[1];
      next_MSHR_queue[tail].inst_type = d_cache_mshr_out.inst_type[1];
      next_MSHR_queue[tail].proc2mem_command = d_cache_mshr_out.mshr_proc2mem_command[1];
      next_MSHR_queue[tail].complete = 0;
      next_MSHR_queue[tail].mem_tag = 0;
      next_MSHR_queue[tail].state = WAITING;
      next_MSHR_queue[tail].dirty = d_cache_mshr_out.miss_dirty[0];

      next_MSHR_queue[tail_plus_one].valid = 1;
      next_MSHR_queue[tail_plus_one].data = d_cache_mshr_out.miss_data_in[1];
      next_MSHR_queue[tail_plus_one].addr = d_cache_mshr_out.miss_addr[1];
      next_MSHR_queue[tail_plus_one].inst_type = d_cache_mshr_out.inst_type[1];
      next_MSHR_queue[tail_plus_one].proc2mem_command = BUS_LOAD;
      next_MSHR_queue[tail_plus_one].complete = 0;
      next_MSHR_queue[tail_plus_one].mem_tag = 0;
      next_MSHR_queue[tail_plus_one].state = WAITING;
      next_MSHR_queue[tail_plus_one].dirty = d_cache_mshr_out.miss_dirty[1];

      next_tail = tail_plus_two;
    end
    else if(!pending_rd_bus_load & pending_wr_bus_load & !pending_bus_load & d_cache_mshr_out.miss_en[2]) begin
      next_MSHR_queue[tail].valid = 1;
      next_MSHR_queue[tail].data = d_cache_mshr_out.miss_data_in[1];
      next_MSHR_queue[tail].addr = d_cache_mshr_out.miss_addr[1];
      next_MSHR_queue[tail].inst_type = d_cache_mshr_out.inst_type[1];
      next_MSHR_queue[tail].proc2mem_command = d_cache_mshr_out.mshr_proc2mem_command[1];
      next_MSHR_queue[tail].complete = 0;
      next_MSHR_queue[tail].mem_tag = 0;
      next_MSHR_queue[tail].state = WAITING;
      next_MSHR_queue[tail].dirty = d_cache_mshr_out.miss_dirty[0];

      next_MSHR_queue[tail_plus_one].valid = 1;
      next_MSHR_queue[tail_plus_one].data = d_cache_mshr_out.miss_data_in[2];
      next_MSHR_queue[tail_plus_one].addr = d_cache_mshr_out.miss_addr[2];
      next_MSHR_queue[tail_plus_one].inst_type = d_cache_mshr_out.inst_type[2];
      next_MSHR_queue[tail_plus_one].proc2mem_command = d_cache_mshr_out.mshr_proc2mem_command[2];
      next_MSHR_queue[tail_plus_one].complete = 0;
      next_MSHR_queue[tail_plus_one].mem_tag = 0;
      next_MSHR_queue[tail_plus_one].state = WAITING;
      next_MSHR_queue[tail_plus_one].dirty = d_cache_mshr_out.miss_dirty[2];

      next_tail = tail_plus_two;
    end
    else if(!pending_rd_bus_load & !pending_wr_bus_load & pending_bus_load & d_cache_mshr_out.miss_en[2]) begin
      next_MSHR_queue[tail].valid = 1;
      next_MSHR_queue[tail].data = d_cache_mshr_out.miss_data_in[1];
      next_MSHR_queue[tail].addr = d_cache_mshr_out.miss_addr[1];
      next_MSHR_queue[tail].inst_type = d_cache_mshr_out.inst_type[1];
      next_MSHR_queue[tail].proc2mem_command = BUS_LOAD;
      next_MSHR_queue[tail].complete = 0;
      next_MSHR_queue[tail].mem_tag = 0;
      next_MSHR_queue[tail].state = WAITING;
      next_MSHR_queue[tail].dirty = d_cache_mshr_out.miss_dirty[0];

      next_MSHR_queue[tail_plus_one].valid = 1;
      next_MSHR_queue[tail_plus_one].data = d_cache_mshr_out.miss_data_in[2];
      next_MSHR_queue[tail_plus_one].addr = d_cache_mshr_out.miss_addr[2];
      next_MSHR_queue[tail_plus_one].inst_type = d_cache_mshr_out.inst_type[2];
      next_MSHR_queue[tail_plus_one].proc2mem_command = d_cache_mshr_out.mshr_proc2mem_command[2];
      next_MSHR_queue[tail_plus_one].complete = 0;
      next_MSHR_queue[tail_plus_one].mem_tag = 0;
      next_MSHR_queue[tail_plus_one].state = WAITING;
      next_MSHR_queue[tail_plus_one].dirty = d_cache_mshr_out.miss_dirty[2];

      next_tail = tail_plus_two;
    end
    else if(pending_rd_bus_load & pending_wr_bus_load & pending_bus_load & !d_cache_mshr_out.miss_en[2]) begin
      next_MSHR_queue[tail].valid = 1;
      next_MSHR_queue[tail].data = d_cache_mshr_out.miss_data_in[0];
      next_MSHR_queue[tail].addr = d_cache_mshr_out.miss_addr[0];
      next_MSHR_queue[tail].inst_type = d_cache_mshr_out.inst_type[0];
      next_MSHR_queue[tail].proc2mem_command = d_cache_mshr_out.mshr_proc2mem_command[0];
      next_MSHR_queue[tail].complete = 0;
      next_MSHR_queue[tail].mem_tag = 0;
      next_MSHR_queue[tail].state = WAITING;
      next_MSHR_queue[tail].dirty = d_cache_mshr_out.miss_dirty[0];

      next_MSHR_queue[tail_plus_one].valid = 1;
      next_MSHR_queue[tail_plus_one].data = d_cache_mshr_out.miss_data_in[1];
      next_MSHR_queue[tail_plus_one].addr = d_cache_mshr_out.miss_addr[1];
      next_MSHR_queue[tail_plus_one].inst_type = d_cache_mshr_out.inst_type[1];
      next_MSHR_queue[tail_plus_one].proc2mem_command = d_cache_mshr_out.mshr_proc2mem_command[1];
      next_MSHR_queue[tail_plus_one].complete = 0;
      next_MSHR_queue[tail_plus_one].mem_tag = 0;
      next_MSHR_queue[tail_plus_one].state = WAITING;
      next_MSHR_queue[tail_plus_one].dirty =  d_cache_mshr_out.miss_dirty[1];

      next_MSHR_queue[tail_plus_two].valid = 1;
      next_MSHR_queue[tail_plus_two].data = d_cache_mshr_out.miss_data_in[1];
      next_MSHR_queue[tail_plus_two].addr = d_cache_mshr_out.miss_addr[1];
      next_MSHR_queue[tail_plus_two].inst_type = d_cache_mshr_out.inst_type[1];
      next_MSHR_queue[tail_plus_two].proc2mem_command = BUS_LOAD;
      next_MSHR_queue[tail_plus_two].complete = 0;
      next_MSHR_queue[tail_plus_two].mem_tag = 0;
      next_MSHR_queue[tail_plus_two].state = WAITING;
      next_MSHR_queue[tail_plus_two].dirty =  d_cache_mshr_out.miss_dirty[1];

      next_tail = tail_plus_three;
    end
    else if(pending_rd_bus_load & pending_wr_bus_load & !pending_bus_load & d_cache_mshr_out.miss_en[2]) begin
      next_MSHR_queue[tail].valid = 1;
      next_MSHR_queue[tail].data = d_cache_mshr_out.miss_data_in[0];
      next_MSHR_queue[tail].addr = d_cache_mshr_out.miss_addr[0];
      next_MSHR_queue[tail].inst_type = d_cache_mshr_out.inst_type[0];
      next_MSHR_queue[tail].proc2mem_command = d_cache_mshr_out.mshr_proc2mem_command[0];
      next_MSHR_queue[tail].complete = 0;
      next_MSHR_queue[tail].mem_tag = 0;
      next_MSHR_queue[tail].state = WAITING;
      next_MSHR_queue[tail].dirty = d_cache_mshr_out.miss_dirty[0];

      next_MSHR_queue[tail_plus_one].valid = 1;
      next_MSHR_queue[tail_plus_one].data = d_cache_mshr_out.miss_data_in[1];
      next_MSHR_queue[tail_plus_one].addr = d_cache_mshr_out.miss_addr[1];
      next_MSHR_queue[tail_plus_one].inst_type = d_cache_mshr_out.inst_type[1];
      next_MSHR_queue[tail_plus_one].proc2mem_command = d_cache_mshr_out.mshr_proc2mem_command[1];
      next_MSHR_queue[tail_plus_one].complete = 0;
      next_MSHR_queue[tail_plus_one].mem_tag = 0;
      next_MSHR_queue[tail_plus_one].state = WAITING;
      next_MSHR_queue[tail_plus_one].dirty =  d_cache_mshr_out.miss_dirty[1];

      next_MSHR_queue[tail_plus_two].valid = 1;
      next_MSHR_queue[tail_plus_two].data = d_cache_mshr_out.miss_data_in[2];
      next_MSHR_queue[tail_plus_two].addr = d_cache_mshr_out.miss_addr[2];
      next_MSHR_queue[tail_plus_two].inst_type = d_cache_mshr_out.inst_type[2];
      next_MSHR_queue[tail_plus_two].proc2mem_command = d_cache_mshr_out.mshr_proc2mem_command[2];
      next_MSHR_queue[tail_plus_two].complete = 0;
      next_MSHR_queue[tail_plus_two].mem_tag = 0;
      next_MSHR_queue[tail_plus_two].state = WAITING;
      next_MSHR_queue[tail_plus_two].dirty =  d_cache_mshr_out.miss_dirty[2];

      next_tail = tail_plus_three;
    end
    else if(pending_rd_bus_load & !pending_wr_bus_load & pending_bus_load & d_cache_mshr_out.miss_en[2]) begin
      next_MSHR_queue[tail].valid = 1;
      next_MSHR_queue[tail].data = d_cache_mshr_out.miss_data_in[0];
      next_MSHR_queue[tail].addr = d_cache_mshr_out.miss_addr[0];
      next_MSHR_queue[tail].inst_type = d_cache_mshr_out.inst_type[0];
      next_MSHR_queue[tail].proc2mem_command = d_cache_mshr_out.mshr_proc2mem_command[0];
      next_MSHR_queue[tail].complete = 0;
      next_MSHR_queue[tail].mem_tag = 0;
      next_MSHR_queue[tail].state = WAITING;
      next_MSHR_queue[tail].dirty = d_cache_mshr_out.miss_dirty[0];

      next_MSHR_queue[tail_plus_one].valid = 1;
      next_MSHR_queue[tail_plus_one].data = d_cache_mshr_out.miss_data_in[1];
      next_MSHR_queue[tail_plus_one].addr = d_cache_mshr_out.miss_addr[1];
      next_MSHR_queue[tail_plus_one].inst_type = d_cache_mshr_out.inst_type[1];
      next_MSHR_queue[tail_plus_one].proc2mem_command = BUS_LOAD;
      next_MSHR_queue[tail_plus_one].complete = 0;
      next_MSHR_queue[tail_plus_one].mem_tag = 0;
      next_MSHR_queue[tail_plus_one].state = WAITING;
      next_MSHR_queue[tail_plus_one].dirty =  d_cache_mshr_out.miss_dirty[1];

      next_MSHR_queue[tail_plus_two].valid = 1;
      next_MSHR_queue[tail_plus_two].data = d_cache_mshr_out.miss_data_in[2];
      next_MSHR_queue[tail_plus_two].addr = d_cache_mshr_out.miss_addr[2];
      next_MSHR_queue[tail_plus_two].inst_type = d_cache_mshr_out.inst_type[2];
      next_MSHR_queue[tail_plus_two].proc2mem_command = d_cache_mshr_out.mshr_proc2mem_command[2];
      next_MSHR_queue[tail_plus_two].complete = 0;
      next_MSHR_queue[tail_plus_two].mem_tag = 0;
      next_MSHR_queue[tail_plus_two].state = WAITING;
      next_MSHR_queue[tail_plus_two].dirty =  d_cache_mshr_out.miss_dirty[2];

      next_tail = tail_plus_three;
    end
    else if(!pending_rd_bus_load & pending_wr_bus_load & pending_bus_load & d_cache_mshr_out.miss_en[2]) begin
      next_MSHR_queue[tail].valid = 1;
      next_MSHR_queue[tail].data = d_cache_mshr_out.miss_data_in[1];
      next_MSHR_queue[tail].addr = d_cache_mshr_out.miss_addr[1];
      next_MSHR_queue[tail].inst_type = d_cache_mshr_out.inst_type[1];
      next_MSHR_queue[tail].proc2mem_command = d_cache_mshr_out.mshr_proc2mem_command[1];
      next_MSHR_queue[tail].complete = 0;
      next_MSHR_queue[tail].mem_tag = 0;
      next_MSHR_queue[tail].state = WAITING;
      next_MSHR_queue[tail].dirty = d_cache_mshr_out.miss_dirty[1];

      next_MSHR_queue[tail_plus_one].valid = 1;
      next_MSHR_queue[tail_plus_one].data = d_cache_mshr_out.miss_data_in[1];
      next_MSHR_queue[tail_plus_one].addr = d_cache_mshr_out.miss_addr[1];
      next_MSHR_queue[tail_plus_one].inst_type = d_cache_mshr_out.inst_type[1];
      next_MSHR_queue[tail_plus_one].proc2mem_command = BUS_LOAD;
      next_MSHR_queue[tail_plus_one].complete = 0;
      next_MSHR_queue[tail_plus_one].mem_tag = 0;
      next_MSHR_queue[tail_plus_one].state = WAITING;
      next_MSHR_queue[tail_plus_one].dirty =  d_cache_mshr_out.miss_dirty[1];

      next_MSHR_queue[tail_plus_two].valid = 1;
      next_MSHR_queue[tail_plus_two].data = d_cache_mshr_out.miss_data_in[2];
      next_MSHR_queue[tail_plus_two].addr = d_cache_mshr_out.miss_addr[2];
      next_MSHR_queue[tail_plus_two].inst_type = d_cache_mshr_out.inst_type[2];
      next_MSHR_queue[tail_plus_two].proc2mem_command = d_cache_mshr_out.mshr_proc2mem_command[2];
      next_MSHR_queue[tail_plus_two].complete = 0;
      next_MSHR_queue[tail_plus_two].mem_tag = 0;
      next_MSHR_queue[tail_plus_two].state = WAITING;
      next_MSHR_queue[tail_plus_two].dirty =  d_cache_mshr_out.miss_dirty[2];

      next_tail = tail_plus_three;
    end
    else if(pending_rd_bus_load & pending_wr_bus_load & pending_bus_load & d_cache_mshr_out.miss_en[2]) begin
      next_MSHR_queue[tail].valid = 1;
      next_MSHR_queue[tail].data = d_cache_mshr_out.miss_data_in[0];
      next_MSHR_queue[tail].addr = d_cache_mshr_out.miss_addr[0];
      next_MSHR_queue[tail].inst_type = d_cache_mshr_out.inst_type[0];
      next_MSHR_queue[tail].proc2mem_command = d_cache_mshr_out.mshr_proc2mem_command[0];
      next_MSHR_queue[tail].complete = 0;
      next_MSHR_queue[tail].mem_tag = 0;
      next_MSHR_queue[tail].state = WAITING;
      next_MSHR_queue[tail].dirty = d_cache_mshr_out.miss_dirty[0];

      next_MSHR_queue[tail_plus_one].valid = 1;
      next_MSHR_queue[tail_plus_one].data = d_cache_mshr_out.miss_data_in[1];
      next_MSHR_queue[tail_plus_one].addr = d_cache_mshr_out.miss_addr[1];
      next_MSHR_queue[tail_plus_one].inst_type = d_cache_mshr_out.inst_type[1];
      next_MSHR_queue[tail_plus_one].proc2mem_command = d_cache_mshr_out.mshr_proc2mem_command[1];
      next_MSHR_queue[tail_plus_one].complete = 0;
      next_MSHR_queue[tail_plus_one].mem_tag = 0;
      next_MSHR_queue[tail_plus_one].state = WAITING;
      next_MSHR_queue[tail_plus_one].dirty =  d_cache_mshr_out.miss_dirty[1];

      next_MSHR_queue[tail_plus_two].valid = 1;
      next_MSHR_queue[tail_plus_two].data = d_cache_mshr_out.miss_data_in[1];
      next_MSHR_queue[tail_plus_two].addr = d_cache_mshr_out.miss_addr[1];
      next_MSHR_queue[tail_plus_two].inst_type = d_cache_mshr_out.inst_type[1];
      next_MSHR_queue[tail_plus_two].proc2mem_command = BUS_LOAD;
      next_MSHR_queue[tail_plus_two].complete = 0;
      next_MSHR_queue[tail_plus_two].mem_tag = 0;
      next_MSHR_queue[tail_plus_two].state = WAITING;
      next_MSHR_queue[tail_plus_two].dirty =  d_cache_mshr_out.miss_dirty[1];

      next_MSHR_queue[tail_plus_three].valid = 1;
      next_MSHR_queue[tail_plus_three].data = d_cache_mshr_out.miss_data_in[2];
      next_MSHR_queue[tail_plus_three].addr = d_cache_mshr_out.miss_addr[2];
      next_MSHR_queue[tail_plus_three].inst_type = d_cache_mshr_out.inst_type[2];
      next_MSHR_queue[tail_plus_three].proc2mem_command = d_cache_mshr_out.mshr_proc2mem_command[2];
      next_MSHR_queue[tail_plus_three].complete = 0;
      next_MSHR_queue[tail_plus_three].mem_tag = 0;
      next_MSHR_queue[tail_plus_three].state = WAITING;
      next_MSHR_queue[tail_plus_three].dirty =  d_cache_mshr_out.miss_dirty[2];

      next_tail = tail_plus_four;
    end
  end

  //send data to mem

  //send to mem logic

  assign proc2mem_command = (MSHR_queue[head].valid & !MSHR_queue[head].complete) ? MSHR_queue[head].proc2mem_command : BUS_NONE;
  assign proc2mem_addr = MSHR_queue[head].addr;
  assign proc2mem_data = MSHR_queue[head].data;
  
  //logic to move the writeback head.
  assign mshr_d_cache_out.mem_wr = MSHR_queue[writeback_head].valid & MSHR_queue[writeback_head].complete & MSHR_queue[writeback_head].proc2mem_command == BUS_LOAD;
  assign mshr_d_cache_out.mem_dirty = MSHR_queue[writeback_head].dirty;
  assign mshr_d_cache_out.mem_data = MSHR_queue[writeback_head].data;
  assign mshr_d_cache_out.mem_addr = MSHR_queue[writeback_head].addr;


  always_ff @(posedge clock) begin
    if(reset) begin
      for(int i = 0; i < `MSHR_DEPTH; i++) begin
        MSHR_queue[i].valid <= `SD 0;
        MSHR_queue[i].data <= `SD 0;
        MSHR_queue[i].dirty <= `SD 0;
        MSHR_queue[i].addr <= `SD 0;
        MSHR_queue[i].inst_type <= `SD LOAD;
        MSHR_queue[i].proc2mem_command <= `SD BUS_NONE;
        MSHR_queue[i].complete <= `SD 0;
        MSHR_queue[i].mem_tag <= `SD 0;
        MSHR_queue[i].state <= `SD WAITING;
      end
      writeback_head    <= `SD 0;
      head              <= `SD 0;
      tail              <= `SD 0;
      last_rd_addr      <= `SD -1;
      last_wr_addr      <= `SD -1;
      prev_changed_wr_input <= `SD 0;
    end
    else begin
      MSHR_queue        <= `SD next_MSHR_queue;
      writeback_head    <= `SD next_writeback_head;
      head              <= `SD next_head;
      tail              <= `SD next_tail;
      last_rd_addr      <= `SD current_rd_addr;
      last_wr_addr      <= `SD current_wr_addr;
      prev_changed_wr_input <= `SD changed_wr_input;
    end
  end
endmodule