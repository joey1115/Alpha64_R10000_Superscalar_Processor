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

	lda	$r30,stack	# initialize stack pointer
	
	lda	$r16,14		# call fib(14)
	bsr	$r26,fib

	lda	$r1,data
	stq	$r0,0($r1)	# save to mem
	call_pal 0x555
	
fib:	beq	$r16,fib_ret_1	# arg is 0: return 1

	cmpeq	$r16,1,$r1	# arg is 1: return 1
	bne	$r1,fib_ret_1

	subq	$r30,32,$r30	# allocate stack frame
	stq	$r26,24($r30)	# save off return address

	stq	$r16,0($r30)	# save off arg

	subq	$r16,1,$r16	# arg = arg-1
	bsr	$r26,fib	# call fib
	stq	$r0,8($r30)	# save return value (fib(arg-1))

	ldq	$r16,0($r30)	# restore arg
	subq	$r16,2,$r16	# arg = arg-2
	bsr	$r26,fib	# call fib

	ldq	$r1,8($r30)	# restore fib(arg-1)
	addq	$r1,$r0,$r0	# fib(arg-1)+fib(arg-2)

	ldq	$r26,24($r30)	# restore return address
	addq	$r30,32,$r30	# deallocate stack frame
	ret			# return
	
fib_ret_1:
	mov	1,$r0		# set return value to 1
	ret			# return
	
