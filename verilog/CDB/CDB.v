/***********************************************
 * CDB procedure:
 * ----complete----
 * 1. put complete tag in CDB
 * input: complete enbale signal, tag
 * 
 * 2. give CDB tag to Map Table & RS
 * output: CDB enbale signal, tag
  
 ************************************************/

module CDB (
  input  en, clock, reset,
  input  CDB_PACKET_IN  cdb_packet_in,
  output CDB_PACKET_OUT cdb_packet_out
);

  always_comb begin
   if (cdb_packet_in.C_en == 1) begin
     cdb_packet_out.CDB_T = cdb_packet_in.C_T;
     cdb_packet_out.CDB_en = 1;
   end else begin
        cdb_packet_out.CDB_en = 0;
      end // else
   end // if
  end

  always_ff @(posedge clock) begin
    if (reset) begin
      cdb_packet_out.CDB_en <= `SD 0;
    end
  end // always

endmodule