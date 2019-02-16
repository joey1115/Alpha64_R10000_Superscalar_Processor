/*
	TEST PROGRAM #4: compute first 16 multiples of 8 (embarrassingly parallel)


	long output[16];
	
	void
	main(void)
	{
	  long i;
	  for (i=0; i < 16; i++,a++,b++,c++)
	    output[i] = ((i + i) + (i + i)) + ((i + i) + (i + i));
	}
*/
	data = 0x1000
	lda     $r2,0
	nop
	nop
	nop
	nop
	lda     $r3,data
	nop
	nop
	nop
	nop
loop:	addq    $r2,$r2,$r5
	nop
	nop
	nop
	nop
	addq    $r2,$r2,$r8
	nop
	nop
	nop
	nop
	addq    $r2,$r2,$r7
	nop
	nop
	nop
	nop
	addq    $r2,$r2,$r4
	nop
	nop
	nop
	nop
	addq    $r4,$r5,$r6
	nop
	nop
	nop
	nop
	addq    $r7,$r8,$r9
	nop
	nop
	nop
	nop
	addq    $r6,$r9,$r10
	nop
	nop
	nop
	nop
	stq     $r10,0($r3)
	nop
	nop
	nop
	nop
	addq    $r3,0x8,$r3
	nop
	nop
	nop
	nop
	addq    $r2,0x1,$r2
	nop
	nop
	nop
	nop
	cmple   $r2,0xf,$r1
	nop
	nop
	nop
	nop
	bne     $r1,loop
	nop
	nop
	nop
	nop
	call_pal        0x555
	nop
	nop
	nop
	nop

