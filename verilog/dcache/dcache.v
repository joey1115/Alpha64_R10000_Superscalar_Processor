
module dcache(
			  input         clock,
			  input         reset,
			  input   [3:0] Imem2proc_response,
			  input  [63:0] Imem2proc_data,
			  input   [3:0] Imem2proc_tag,

			  input  [63:0] proc2Icache_addr,
			  input   [1:0] proc2Icache_command,   // load or store or none
			  input  [63:0] proc2Icache_data,      // stored data

			  output logic  [1:0] proc2Imem_command,  // these two will be enble when cache miss
			  output logic [63:0] proc2Imem_addr,
			  output logic [63:0] proc2Imem_data,     // stored data

			  output logic [63:0] Icache_data_out,     // value is memory[proc2Icache_addr]
			  output logic        Icache_valid_out,    // when this is high

			  output logic  [4:0] current_index,
			  output logic  [7:0] current_tag,
			  output logic  [4:0] last_index,
			  output logic  [7:0] last_tag,
			  output logic        data_write_enable
             );

	logic [`NUM_WAY*`NUM_SET*`NUM_LINE-1:0][63:0]  current_cache next_cache;
	logic [3:0] current_mem_tag;
	logic miss_outstanding;
	logic cache_hit;

	assign {current_tag, current_index} = proc2Icache_addr[31:3];

	wire changed_addr = (current_index!=last_index) || (current_tag!=last_tag);  // address changed in Fetch
																			     // when branch happens,clear ID

	wire send_request = miss_outstanding && !changed_addr;

	assign proc2Imem_addr = {proc2Icache_addr[63:3],3'b0}; // cuts off the block offset bits
	assign proc2Imem_command = (miss_outstanding && !changed_addr) ?	proc2Icache_command :  // issue a bus load or store, receive an ID from memory
																		BUS_NONE;
	assign proc2Imem_data = proc2Icache_data;

	assign data_write_enable =	(current_mem_tag==Imem2proc_tag) &&   // memory write cache when tag matches
								(current_mem_tag!=0);

	wire update_mem_tag = changed_addr | miss_outstanding | data_write_enable;

	wire unanswered_miss = changed_addr ?	!Icache_valid_out :  // cache miss, find in memory
											miss_outstanding & (Imem2proc_response==0);   

	// synopsys sync_set_reset "reset"
	always_ff @(posedge clock)
	begin
		if(reset)
		begin
			last_index       <= `SD -1;   // These are -1 to get ball rolling when
			last_tag         <= `SD -1;   // reset goes low because addr "changes"
			current_mem_tag  <= `SD 0;              
			miss_outstanding <= `SD 0;
			for(int i=0; i<`NUM_WAY*`NUM_SET*`NUM_LINE; i=i+1) begin
        	  current_cache[i] = 64'h0;
      		end
		end
		else
		begin
			last_index       <= `SD current_index;
			last_tag         <= `SD current_tag;
			miss_outstanding <= `SD unanswered_miss;
			current_cache    <= `SD next_cache;
			
			if(update_mem_tag)
				current_mem_tag <= `SD Imem2proc_response;
		end
	end

	always_comb begin
	  for(int i=0; i<`NUM_TOTAL_LINE; i=i+1) begin
        if (current_cache[i][63:64-`NUM_TAG] == proc2Icache_addr[63:64-`NUM_TAG]) begin
		  Icache_data_out  = current_cache[i];
		  Icache_valid_out = `TRUE;
		  break;
		end
		if (i == `NUM_TOTAL_LINE-1) begin
		  Icache_valid_out = `FALSE;
		  Icache_data_out = 64'b0;
		end
      end
	end


endmodule

