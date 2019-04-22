/*
	TEST PROGRAM #3: compute first 16 fibonacci numbers
			 with forwarding and stall conditions in the loop


	long output[16];
	
	void
	main(void)
	{
	  long i, fib;
	
	  output[0] = 1;
	  output[1] = 2;
	  for (i=2; i < 16; i++)
	    output[i] = output[i-1] + output[i-2];
	}
*/
	
	data = 0x1000
	lda     $r3,data
	nop
	nop
	nop
	nop
	lda     $r4,data+8
	nop
	nop
	nop
	nop
	lda     $r5,data+16
	nop
	nop
	nop
	nop
	lda     $r9,2
	nop
	nop
	nop
	nop
	lda     $r1,1
	nop
	nop
	nop
	nop
	stq     $r1,0($r3)
	nop
	nop
	nop
	nop
	stq	$r1,0($r4)
	nop
	nop
	nop
	nop
loop:	ldq     $r1,0($r3)
	nop
	nop
	nop
	nop
	ldq     $r2,0($r4)
	nop
	nop
	nop
	nop
	addq    $r2,$r1,$r2
	nop
	nop
	nop
	nop
	addq    $r3,0x8,$r3
	nop
	nop
	nop
	nop
	addq	$r4,0x8,$r4
	nop
	nop
	nop
	nop
	addq    $r9,0x1,$r9
	nop
	nop
	nop
	nop
	cmple   $r9,0xf,$r10
	nop
	nop
	nop
	nop
	stq     $r2,0($r5)
	addq    $r5,0x8,$r5
	nop
	nop
	nop
	nop
	bne     $r10,loop
	nop
	nop
	nop
	nop
	call_pal        0x555
	nop
	nop
	nop
	nop
