`ifndef __PACKETS_VH__
`define __PACKETS_VH__

typedef struct packed {
    logic [$clog2(`NUM_ARCH_TABLE)-1:0] dest_idx;       // destination idx for archmap retire
    logic [$clog2(`NUM_PR)-1:0] T_idx;            // T_idx at head to retire to archmap
  } ROB_PACKET_ARCHMAP_OUT;




  `endif