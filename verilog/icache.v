
module icache(
    input   clock,
    input   reset,
    input   [3:0] Imem2proc_response,
    input  [63:0] Imem2proc_data,
    input   [3:0] Imem2proc_tag,

    input  [63:0] proc2Icache_addr,
    input  [63:0] cachemem_data,
    input   cachemem_valid,

    output logic  [1:0] proc2Imem_command,
    output logic [63:0] proc2Imem_addr,

    output logic [63:0] Icache_data_out, // value is memory[proc2Icache_addr]
    output logic  Icache_valid_out,      // when this is high

    output logic  [4:0] current_index,
    output logic  [7:0] current_tag,
    output logic  [4:0] last_index,
    output logic  [7:0] last_tag,
    output logic  data_write_enable
  
  );

  logic [3:0] current_mem_tag;

  logic miss_outstanding;

  assign {current_tag, current_index} = proc2Icache_addr[31:3];

  wire changed_addr = (current_index != last_index) || (current_tag != last_tag);

  wire send_request = miss_outstanding && !changed_addr;

  assign Icache_data_out = cachemem_data;

  assign Icache_valid_out = cachemem_valid; 

  assign proc2Imem_addr = {proc2Icache_addr[63:3],3'b0};
  assign proc2Imem_command = (miss_outstanding && !changed_addr) ?  BUS_LOAD :
                                                                    BUS_NONE;

  assign data_write_enable =  (current_mem_tag == Imem2proc_tag) &&
                              (current_mem_tag != 0);

  wire update_mem_tag = changed_addr || miss_outstanding || data_write_enable;

  wire unanswered_miss = changed_addr ? !Icache_valid_out :
                                        miss_outstanding && (Imem2proc_response == 0);

  // synopsys sync_set_reset "reset"
  always_ff @(posedge clock) begin
    if(reset) begin
      last_index       <= `SD -1;   // These are -1 to get ball rolling when
      last_tag         <= `SD -1;   // reset goes low because addr "changes"
      current_mem_tag  <= `SD 0;              
      miss_outstanding <= `SD 0;
    end else begin
      last_index       <= `SD current_index;
      last_tag         <= `SD current_tag;
      miss_outstanding <= `SD unanswered_miss;
      
      if(update_mem_tag)
        current_mem_tag <= `SD Imem2proc_response;
    end
  end

endmodule

