/*
 *  pipe_print.c - Print instructions as they pass through the verisimple
 *                 pipeline.  Must compile with the '+vc' vcs flag.
 *
 *  Doug MacKay <dmackay@umich.edu> Fall 2003
 */

#include <stdio.h>
#include "DirectC.h"

#define NOOP_INST 0x47ff041f

static int cycle_count = 0;
static FILE* ppfile = NULL;


void print_open()
{
  if (ppfile == NULL)
    ppfile = fopen("pipeline.out", "w");

  fprintf(ppfile, "START!!\n");
}

void print_cycles()
{
  /* we'll enforce the printing of a header */
  if (ppfile != NULL)
    fprintf(ppfile, "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\ncycle: %5d\n", cycle_count++);
}

void print_ROB_ht(int head, int tail)
{
  if (ppfile != NULL){
    fprintf(ppfile, "---------------------------------------ROB----------------------------------- ");
    fprintf(ppfile, "head:%d   tail:%d\n", head, tail);
  }

    
}

void print_ROB_entry(int valid, int T, int T_old, int dest_idx, int complete, int halt){
  if (ppfile != NULL)
    fprintf(ppfile, "valid: %1d | T: %3d | T_old: %3d | dest_idx: %3d | complete: %1d | halt: %1d|\n", valid, T, T_old, dest_idx, complete, halt);
}

void print_RS_head(){
  if (ppfile != NULL)
    fprintf(ppfile, "----------------------------------------------------------------------------------------------------------------RS--------------------------------------------------------------------------------------------------------------\n");
}

void print_RS_entry(char* funcType, int busy, int inst, int func, int NPC_hi, int NPC_lo, int dest_idx, int ROB_idx, int FL_idx, int T_idx, int T1, int T1_ready, int T2, int T2_ready, int T1_select, int T2_select){

  char *T1_str;
  char *T2_str;
  char *ALU_func;
  char *str;

  int opcode, check;

  switch (func)
  {
    case 0:  ALU_func = "ALU_ADDQ  "; break;
    case 1:  ALU_func = "ALU_SUBQ  "; break;
    case 2:  ALU_func = "ALU_AND   "; break;
    case 3:  ALU_func = "ALU_BIC   "; break;
    case 4:  ALU_func = "ALU_BIS   "; break;
    case 5:  ALU_func = "ALU_ORNOT "; break;
    case 6:  ALU_func = "ALU_XOR   "; break;
    case 7:  ALU_func = "ALU_EQV   "; break;
    case 8:  ALU_func = "ALU_SRL   "; break;
    case 9:  ALU_func = "ALU_SLL   "; break;
    case 10: ALU_func = "ALU_SRA   "; break;
    case 11: ALU_func = "ALU_MULQ  "; break;
    case 12: ALU_func = "ALU_CMPEQ "; break;
    case 13: ALU_func = "ALU_CMPLT "; break;
    case 14: ALU_func = "ALU_CMPLE "; break;
    case 15: ALU_func = "ALU_CMPULT"; break;
    case 16: ALU_func = "ALU_CMPULE"; break;
  
    default: ALU_func = "ALU_ERROR "; break;
  }

  opcode = (inst >> 26) & 0x0000003f;
    check = (inst>>5) & 0x0000007f;
    switch(opcode)
    {
      case 0x00: str = (inst == 0x555) ? "halt" : "call_pal"; break;
      case 0x08: str = "lda"; break;
      case 0x09: str = "ldah"; break;
      case 0x0a: str = "ldbu"; break;
      case 0x0b: str = "ldqu"; break;
      case 0x0c: str = "ldwu"; break;
      case 0x0d: str = "stw"; break;
      case 0x0e: str = "stb"; break;
      case 0x0f: str = "stqu"; break;
      case 0x10: // INTA_GRP
         switch(check)
         {
           case 0x00: str = "addl"; break;
           case 0x02: str = "s4addl"; break;
           case 0x09: str = "subl"; break;
           case 0x0b: str = "s4subl"; break;
           case 0x0f: str = "cmpbge"; break;
           case 0x12: str = "s8addl"; break;
           case 0x1b: str = "s8subl"; break;
           case 0x1d: str = "cmpult"; break;
           case 0x20: str = "addq"; break;
           case 0x22: str = "s4addq"; break;
           case 0x29: str = "subq"; break;
           case 0x2b: str = "s4subq"; break;
           case 0x2d: str = "cmpeq"; break;
           case 0x32: str = "s8addq"; break;
           case 0x3b: str = "s8subq"; break;
           case 0x3d: str = "cmpule"; break;
           case 0x40: str = "addlv"; break;
           case 0x49: str = "sublv"; break;
           case 0x4d: str = "cmplt"; break;
           case 0x60: str = "addqv"; break;
           case 0x69: str = "subqv"; break;
           case 0x6d: str = "cmple"; break;
           default: str = "invalid"; break;
         }
         break;
      case 0x11: // INTL_GRP
         switch(check)
         {
           case 0x00: str = "and"; break;
           case 0x08: str = "bic"; break;
           case 0x14: str = "cmovlbs"; break;
           case 0x16: str = "cmovlbc"; break;
           case 0x20: str = "bis"; break;
           case 0x24: str = "cmoveq"; break;
           case 0x26: str = "cmovne"; break;
           case 0x28: str = "ornot"; break;
           case 0x40: str = "xor"; break;
           case 0x44: str = "cmovlt"; break;
           case 0x46: str = "cmovge"; break;
           case 0x48: str = "eqv"; break;
           case 0x61: str = "amask"; break;
           case 0x64: str = "cmovle"; break;
           case 0x66: str = "cmovgt"; break;
           case 0x6c: str = "implver"; break;
           default: str = "invalid"; break;
         }
         break;
      case 0x12: // INTS_GRP
         switch(check)
         {
           case 0x02: str = "mskbl"; break;
           case 0x06: str = "extbl"; break;
           case 0x0b: str = "insbl"; break;
           case 0x12: str = "mskwl"; break;
           case 0x16: str = "extwl"; break;
           case 0x1b: str = "inswl"; break;
           case 0x22: str = "mskll"; break;
           case 0x26: str = "extll"; break;
           case 0x2b: str = "insll"; break;
           case 0x30: str = "zap"; break;
           case 0x31: str = "zapnot"; break;
           case 0x32: str = "mskql"; break;
           case 0x34: str = "srl"; break;
           case 0x36: str = "extql"; break;
           case 0x39: str = "sll"; break;
           case 0x3b: str = "insql"; break;
           case 0x3c: str = "sra"; break;
           case 0x52: str = "mskwh"; break;
           case 0x57: str = "inswh"; break;
           case 0x5a: str = "extwh"; break;
           case 0x62: str = "msklh"; break;
           case 0x67: str = "inslh"; break;
           case 0x6a: str = "extlh"; break;
           case 0x72: str = "mskqh"; break;
           case 0x77: str = "insqh"; break;
           case 0x7a: str = "extqh"; break;
           default: str = "invalid"; break;
         }
         break;
      case 0x13: // INTM_GRP
         switch(check)
         {
           case 0x00: str = "mull"; break;
           case 0x20: str = "mulq"; break;
           case 0x30: str = "umulh"; break;
           case 0x40: str = "mullv"; break;
           case 0x60: str = "mulqv"; break;
           default: str = "invalid"; break;
         }
         break;
      case 0x14: str = "itfp"; break; // unimplemented
      case 0x15: str = "fltv"; break; // unimplemented
      case 0x16: str = "flti"; break; // unimplemented
      case 0x17: str = "fltl"; break; // unimplemented
      case 0x1a: str = "jsr"; break;
      case 0x1c: str = "ftpi"; break;
      case 0x20: str = "ldf"; break;
      case 0x21: str = "ldg"; break;
      case 0x22: str = "lds"; break;
      case 0x23: str = "ldt"; break;
      case 0x24: str = "stf"; break;
      case 0x25: str = "stg"; break;
      case 0x26: str = "sts"; break;
      case 0x27: str = "stt"; break;
      case 0x28: str = "ldl"; break;
      case 0x29: str = "ldq"; break;
      case 0x2a: str = "ldll"; break;
      case 0x2b: str = "ldql"; break;
      case 0x2c: str = "stl"; break;
      case 0x2d: str = "stq"; break;
      case 0x2e: str = "stlc"; break;
      case 0x2f: str = "stqc"; break;
      case 0x30: str = "br"; break;
      case 0x31: str = "fbeq"; break;
      case 0x32: str = "fblt"; break;
      case 0x33: str = "fble"; break;
      case 0x34: str = "bsr"; break;
      case 0x35: str = "fbne"; break;
      case 0x36: str = "fbge"; break;
      case 0x37: str = "fbgt"; break;
      case 0x38: str = "blbc"; break;
      case 0x39: str = "beq"; break;
      case 0x3a: str = "blt"; break;
      case 0x3b: str = "ble"; break;
      case 0x3c: str = "blbs"; break;
      case 0x3d: str = "bne"; break;
      case 0x3e: str = "bge"; break;
      case 0x3f: str = "bgt"; break;
      default: str = "invalid"; break;
    }


  switch(T1_select)
  {
    case 0x00: T1_str = "ALU_OPA_IS_REGA    "; break;
    case 0x01: T1_str = "ALU_OPA_IS_MEM_DISP"; break;
    case 0x02: T1_str = "ALU_OPA_IS_NPC     "; break;
    case 0x03: T1_str = "ALU_OPA_IS_NOT3    "; break;
    default:   T1_str = "invalid            "; break;
  }
  switch(T2_select)
  {
    case 0x00: T2_str = "ALU_OPB_IS_REGB    "; break;
    case 0x01: T2_str = "ALU_OPB_IS_ALU_IMM "; break;
    case 0x02: T2_str = "ALU_OPB_IS_BR_DISP "; break;
    default:   T2_str = "invalid            "; break;
  }

  if (ppfile != NULL)
    fprintf(ppfile, "Function: %-8s | busy: %1d |  inst: %-8s | func: %-8s | NPC: %x%x | dest_idx: %3d | ROB_idx: %2d | FL_idx: %2d | T_idx: %3d | T1: %3d | T1_ready: %1d | T2: %3d | T2_ready: %1d | ALU_OPA_SELECT: %-10s | ALU_OPB_SELECT: %-10s\n",\
     funcType, busy, str, ALU_func, NPC_hi, NPC_lo, dest_idx, ROB_idx, FL_idx, T_idx, T1, T1_ready, T2, T2_ready, T1_str, T2_str);
}

void print_maptable_head(){
  if (ppfile != NULL){
    fprintf(ppfile, " MAP_TABLE \n");
    fprintf(ppfile, " reg |  T  \n");
  }
}
void print_maptable_entries(int reg_idx, int T, int ready){
  char *ready_bit;
  if(ready){
    ready_bit = "+";
  }
  else{
    ready_bit = " ";
  }

  if (ppfile != NULL)
    fprintf(ppfile, " %3d | %3d%-8s \n", reg_idx, T, ready_bit);
}

void print_CDB_head(){
  if (ppfile != NULL){
    fprintf(ppfile, "------------------------------CDB----------------------------\n");
  }
}

void print_CDB_entries(int taken, int T_idx, int ROB_idx, int dest_idx, int T_value_HI, int T_value_LO){
  if (ppfile != NULL){
    fprintf(ppfile, "taken: %1d | T_idx: %3d | ROB_idx: %3d | T_value: %x%x |\n" , taken, T_idx, ROB_idx, dest_idx, T_value_HI, T_value_LO);
  }
}

void print_archmap_head(){
  if(ppfile != NULL){
    fprintf(ppfile, "  archmap \n");
    fprintf(ppfile, " reg | PR \n");
  }
}

void print_archmap_entries(int reg_idx, int pr){
  if(ppfile != NULL){
    fprintf(ppfile, " %3d | %3d \n", reg_idx, pr);
  }
}


void print_stage(char* div, int inst, int npc, int valid_inst)
{
  int opcode, check;
  char *str;
  
  if(!valid_inst)
    str = "-";
  else if(inst==NOOP_INST)
    str = "nop";
  else {
    opcode = (inst >> 26) & 0x0000003f;
    check = (inst>>5) & 0x0000007f;
    switch(opcode)
    {
      case 0x00: str = (inst == 0x555) ? "halt" : "call_pal"; break;
      case 0x08: str = "lda"; break;
      case 0x09: str = "ldah"; break;
      case 0x0a: str = "ldbu"; break;
      case 0x0b: str = "ldqu"; break;
      case 0x0c: str = "ldwu"; break;
      case 0x0d: str = "stw"; break;
      case 0x0e: str = "stb"; break;
      case 0x0f: str = "stqu"; break;
      case 0x10: // INTA_GRP
         switch(check)
         {
           case 0x00: str = "addl"; break;
           case 0x02: str = "s4addl"; break;
           case 0x09: str = "subl"; break;
           case 0x0b: str = "s4subl"; break;
           case 0x0f: str = "cmpbge"; break;
           case 0x12: str = "s8addl"; break;
           case 0x1b: str = "s8subl"; break;
           case 0x1d: str = "cmpult"; break;
           case 0x20: str = "addq"; break;
           case 0x22: str = "s4addq"; break;
           case 0x29: str = "subq"; break;
           case 0x2b: str = "s4subq"; break;
           case 0x2d: str = "cmpeq"; break;
           case 0x32: str = "s8addq"; break;
           case 0x3b: str = "s8subq"; break;
           case 0x3d: str = "cmpule"; break;
           case 0x40: str = "addlv"; break;
           case 0x49: str = "sublv"; break;
           case 0x4d: str = "cmplt"; break;
           case 0x60: str = "addqv"; break;
           case 0x69: str = "subqv"; break;
           case 0x6d: str = "cmple"; break;
           default: str = "invalid"; break;
         }
         break;
      case 0x11: // INTL_GRP
         switch(check)
         {
           case 0x00: str = "and"; break;
           case 0x08: str = "bic"; break;
           case 0x14: str = "cmovlbs"; break;
           case 0x16: str = "cmovlbc"; break;
           case 0x20: str = "bis"; break;
           case 0x24: str = "cmoveq"; break;
           case 0x26: str = "cmovne"; break;
           case 0x28: str = "ornot"; break;
           case 0x40: str = "xor"; break;
           case 0x44: str = "cmovlt"; break;
           case 0x46: str = "cmovge"; break;
           case 0x48: str = "eqv"; break;
           case 0x61: str = "amask"; break;
           case 0x64: str = "cmovle"; break;
           case 0x66: str = "cmovgt"; break;
           case 0x6c: str = "implver"; break;
           default: str = "invalid"; break;
         }
         break;
      case 0x12: // INTS_GRP
         switch(check)
         {
           case 0x02: str = "mskbl"; break;
           case 0x06: str = "extbl"; break;
           case 0x0b: str = "insbl"; break;
           case 0x12: str = "mskwl"; break;
           case 0x16: str = "extwl"; break;
           case 0x1b: str = "inswl"; break;
           case 0x22: str = "mskll"; break;
           case 0x26: str = "extll"; break;
           case 0x2b: str = "insll"; break;
           case 0x30: str = "zap"; break;
           case 0x31: str = "zapnot"; break;
           case 0x32: str = "mskql"; break;
           case 0x34: str = "srl"; break;
           case 0x36: str = "extql"; break;
           case 0x39: str = "sll"; break;
           case 0x3b: str = "insql"; break;
           case 0x3c: str = "sra"; break;
           case 0x52: str = "mskwh"; break;
           case 0x57: str = "inswh"; break;
           case 0x5a: str = "extwh"; break;
           case 0x62: str = "msklh"; break;
           case 0x67: str = "inslh"; break;
           case 0x6a: str = "extlh"; break;
           case 0x72: str = "mskqh"; break;
           case 0x77: str = "insqh"; break;
           case 0x7a: str = "extqh"; break;
           default: str = "invalid"; break;
         }
         break;
      case 0x13: // INTM_GRP
         switch(check)
         {
           case 0x00: str = "mull"; break;
           case 0x20: str = "mulq"; break;
           case 0x30: str = "umulh"; break;
           case 0x40: str = "mullv"; break;
           case 0x60: str = "mulqv"; break;
           default: str = "invalid"; break;
         }
         break;
      case 0x14: str = "itfp"; break; // unimplemented
      case 0x15: str = "fltv"; break; // unimplemented
      case 0x16: str = "flti"; break; // unimplemented
      case 0x17: str = "fltl"; break; // unimplemented
      case 0x1a: str = "jsr"; break;
      case 0x1c: str = "ftpi"; break;
      case 0x20: str = "ldf"; break;
      case 0x21: str = "ldg"; break;
      case 0x22: str = "lds"; break;
      case 0x23: str = "ldt"; break;
      case 0x24: str = "stf"; break;
      case 0x25: str = "stg"; break;
      case 0x26: str = "sts"; break;
      case 0x27: str = "stt"; break;
      case 0x28: str = "ldl"; break;
      case 0x29: str = "ldq"; break;
      case 0x2a: str = "ldll"; break;
      case 0x2b: str = "ldql"; break;
      case 0x2c: str = "stl"; break;
      case 0x2d: str = "stq"; break;
      case 0x2e: str = "stlc"; break;
      case 0x2f: str = "stqc"; break;
      case 0x30: str = "br"; break;
      case 0x31: str = "fbeq"; break;
      case 0x32: str = "fblt"; break;
      case 0x33: str = "fble"; break;
      case 0x34: str = "bsr"; break;
      case 0x35: str = "fbne"; break;
      case 0x36: str = "fbge"; break;
      case 0x37: str = "fbgt"; break;
      case 0x38: str = "blbc"; break;
      case 0x39: str = "beq"; break;
      case 0x3a: str = "blt"; break;
      case 0x3b: str = "ble"; break;
      case 0x3c: str = "blbs"; break;
      case 0x3d: str = "bne"; break;
      case 0x3e: str = "bge"; break;
      case 0x3f: str = "bgt"; break;
      default: str = "invalid"; break;
    }
  }

  if (ppfile != NULL)
    fprintf(ppfile, "%s%4d:%-8s", div, npc, str);
}

void print_close()
{
  fprintf(ppfile, "\n");
  fclose(ppfile);
  ppfile = NULL;
}

void print_reg(int wb_reg_wr_data_out_hi, int wb_reg_wr_data_out_lo,
                  int wb_reg_wr_idx_out, int wb_reg_wr_en_out)
{
  if (ppfile == NULL)
    return;

  if(wb_reg_wr_en_out)
    if((wb_reg_wr_data_out_hi==0)||
       ((wb_reg_wr_data_out_hi==-1)&&(wb_reg_wr_data_out_lo<0)))
      fprintf(ppfile, "r%d=%d  ",wb_reg_wr_idx_out,wb_reg_wr_data_out_lo);
    else 
      fprintf(ppfile, "r%d=0x%x%x  ",wb_reg_wr_idx_out,
              wb_reg_wr_data_out_hi,wb_reg_wr_data_out_lo);

}

void print_membus(int proc2mem_command, int mem2proc_response,
                  int proc2mem_addr_hi, int proc2mem_addr_lo,
                  int proc2mem_data_hi, int proc2mem_data_lo)
{
  if (ppfile == NULL)
    return;

  switch(proc2mem_command)
  {
    case 1: fprintf(ppfile, "BUS_LOAD  MEM["); break;
    case 2: fprintf(ppfile, "BUS_STORE MEM["); break;
    default: return; break;
  }
  
  if((proc2mem_addr_hi==0)||
     ((proc2mem_addr_hi==-1)&&(proc2mem_addr_lo<0)))
    fprintf(ppfile, "%d",proc2mem_addr_lo);
  else
    fprintf(ppfile, "0x%x%x",proc2mem_addr_hi,proc2mem_addr_lo);
  if(proc2mem_command==1)
  {
    fprintf(ppfile, "]");
  } else {
    fprintf(ppfile, "] = ");
    if((proc2mem_data_hi==0)||
       ((proc2mem_data_hi==-1)&&(proc2mem_data_lo<0)))
      fprintf(ppfile, "%d",proc2mem_data_lo);
    else
      fprintf(ppfile, "0x%x%x",proc2mem_data_hi,proc2mem_data_lo);
  }
  if(mem2proc_response) {
    fprintf(ppfile, " accepted %d",mem2proc_response);
  } else {
    fprintf(ppfile, " rejected");
  }
}
