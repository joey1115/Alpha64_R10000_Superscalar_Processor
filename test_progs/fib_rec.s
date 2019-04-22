/*
	TEST PROGRAM #4: compute nth fibonacci number recursively
                                                                    
	int output;                                                                    
	                                                                    
	void                                                                    
	main(void)                                                                    
	{                                                                    
	   output = fib(14);                                                                     
	}                                                                    
                                                                    
	int                                                                    
	fib(int arg)                                                                    
	{                                                                    
	    if (arg == 0 || arg == 1)                                                                    
		return 1;                                                                    
                                                                    
	    return fib(arg-1) + fib(arg-2);                                                                    
	}
*/
	
	data = 0x400
	stack = 0x1000

	lda	$r30,stack	# initialize stack pointer    04
	
	lda	$r16,14		# call fib(14)                  08
	bsr	$r26,fib  #                               0c

	lda	$r1,data                                # 10
	stq	$r0,0($r1)	# save to mem               # 14
	call_pal 0x555                              # 18
	
fib:	beq	$r16,fib_ret_1	# arg is 0: return 1  1c

	cmpeq	$r16,1,$r1	# arg is 1: return 1        20
	bne	$r1,fib_ret_1                           # 24

	subq	$r30,32,$r30	# allocate stack frame    28
	stq	$r26,24($r30)	# save off return address   2c

	stq	$r16,0($r30)	# save off arg              30

	subq	$r16,1,$r16	# arg = arg-1               34
	bsr	$r26,fib	# call fib                      38
	stq	$r0,8($r30)	# save return value (fib(arg-1)) 3c

	ldq	$r16,0($r30)	# restore arg               40
	subq	$r16,2,$r16	# arg = arg-2               44
	bsr	$r26,fib	# call fib                      48

	ldq	$r1,8($r30)	# restore fib(arg-1)          4c
	addq	$r1,$r0,$r0	# fib(arg-1)+fib(arg-2)     50

	ldq	$r26,24($r30)	# restore return address    54
	addq	$r30,32,$r30	# deallocate stack frame  58
	ret			# return                              5c
	
fib_ret_1:
	mov	1,$r0		# set return value to 1           60
	ret			# return                              64
	
