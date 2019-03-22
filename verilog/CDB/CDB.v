/***********************************************
 * CDB procedure:
 * ----complete----
 * 1. put complete tag in CDB
 * input: complete enable signal, tag
 * 
 * 2. give CDB tag to Map Table & RS
 * output: CDB enable signal, tag
  
 ************************************************/

module CDB (
  input  en,
  input  CDB_PACKET_IN  cdb_packet_in,
  output CDB_PACKET_OUT cdb_packet_out
);

  always_comb begin
    if (cdb_packet_in.C_en == 1) begin
      cdb_packet_out.CDB_T = cdb_packet_in.C_T;
      cdb_packet_out.CDB_en = 1;
    end else begin
      cdb_packet_out.CDB_T = 0;
      cdb_packet_out.CDB_en = 0;
    end // else
  end

endmodule