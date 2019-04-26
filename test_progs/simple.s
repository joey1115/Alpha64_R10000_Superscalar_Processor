/*
  Assembly code compiled from Decaf by 'decaf470', written by Doug Li.
*/

	  .set noat
	  .set noreorder
	  .set nomacro
	  data = 0x1000
	  global = 0x2000
	  lda		$r30, 0x7FF0	# set stack ptr to a sufficiently high addr 04
	  lda		$r15, 0x0000	# initialize frame ptr to something 08
	  lda		$r29, global	# initialize global ptr to 0x2000 0c
	  bsr		$r26, main	# branch to subroutine 10
	  call_pal	0x555		# (halt) 14
	  .data
	  L_DATA:			# this is where the locals and temps end up at run-time
	  .text
main:
	# BeginFunc 40
	  subq		$r30, 16, $r30	# decrement sp to make space to save ra, fp 18
	  stq		$r15, 16($r30)	# save fp 1c
	  stq		$r26, 8($r30)	# save ra 20
	  addq		$r30, 16, $r15	# set up new fp 24
	  subq		$r30, 40, $r30	# decrement sp to make space for locals/temps 28
	# _tmp0 = "Hello World!"
	  .data				# create string constant marked with label
	  .quad 13			# for bounds checking on char access
	  __string1: .asciz "Hello World!"
	  .align 3			# force everything to start on quadword-aligned addresses
	  .text
	  lda		$r3, __string1-L_DATA+data # a hack! 2c
	  stq		$r3, -24($r15)	# spill _tmp0 from $r3 to $r15-24 30
	# str = _tmp0
	  ldq		$r3, -24($r15)	# fill _tmp0 to $r3 from $r15-24 34
	  stq		$r3, -16($r15)	# spill str from $r3 to $r15-16 38
	# _tmp1 = 0
	  lda		$r3, 0		# load (signed) int constant value 0 into $r3 3c
	  stq		$r3, -32($r15)	# spill _tmp1 from $r3 to $r15-32 40
	# i = _tmp1
	  ldq		$r3, -32($r15)	# fill _tmp1 to $r3 from $r15-32 44
	  stq		$r3, 0($r29)	# spill i from $r3 to $r29+0 48
__L0:
	# _tmp2 = 10
	  lda		$r3, 10		# load (signed) int constant value 10 into $r3 4c
	  stq		$r3, -40($r15)	# spill _tmp2 from $r3 to $r15-40 50
	# _tmp3 = i < _tmp2
	  ldq		$r1, 0($r29)	# fill i to $r1 from $r29+0 54
	  ldq		$r2, -40($r15)	# fill _tmp2 to $r2 from $r15-40 58
	  cmplt		$r1, $r2, $r3	# perform the ALU op 5c
	  stq		$r3, -48($r15)	# spill _tmp3 from $r3 to $r15-48 60
	# IfZ _tmp3 Goto __L1
	  ldq		$r1, -48($r15)	# fill _tmp3 to $r1 from $r15-48
	  blbc		$r1, __L1	# branch if _tmp3 is zero
	# PushParam i
	  subq		$r30, 8, $r30	# decrement stack ptr to make space for param
	  ldq		$r1, 0($r29)	# fill i to $r1 from $r29+0
	  stq		$r1, 8($r30)	# copy param value to stack
	# LCall _func
	  bsr		$r26, _func	# branch to function
	# PopParams 8
	  addq		$r30, 8, $r30	# pop params off stack
	# i += 1
	  ldq		$r3, 0($r29)	# fill i to $r3 from $r29+0
	  addq		$r3, 1, $r3	# perform the ALU op
	  stq		$r3, 0($r29)	# spill i from $r3 to $r29+0
	# Goto __L0
	  br		__L0		# unconditional branch
__L1:
	# EndFunc
	# (below handles reaching end of fn body with no explicit return)
	  mov		$r15, $r30	# pop callee frame off stack
	  ldq		$r26, -8($r15)	# restore saved ra
	  ldq		$r15, 0($r15)	# restore saved fp
	  ret				# return from function
_func:
	# BeginFunc 0
	  subq		$r30, 16, $r30	# decrement sp to make space to save ra, fp
	  stq		$r15, 16($r30)	# save fp
	  stq		$r26, 8($r30)	# save ra
	  addq		$r30, 16, $r15	# set up new fp
	# Return 
	  mov		$r15, $r30	# pop callee frame off stack
	  ldq		$r26, -8($r15)	# restore saved ra
	  ldq		$r15, 0($r15)	# restore saved fp
	  ret				# return from function
	# EndFunc
	# (below handles reaching end of fn body with no explicit return)
	  mov		$r15, $r30	# pop callee frame off stack
	  ldq		$r26, -8($r15)	# restore saved ra
	  ldq		$r15, 0($r15)	# restore saved fp
	  ret				# return from function
	# EndProgram
	#
	# (below is reserved for auto-appending of built-in functions)
	#
