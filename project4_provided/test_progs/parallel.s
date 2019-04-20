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
	lda     $r3,data
loop:	addq    $r2,$r2,$r5
	addq    $r2,$r2,$r8
	addq    $r2,$r2,$r7
	addq    $r2,$r2,$r4
	addq    $r4,$r5,$r6
	addq    $r7,$r8,$r9
	addq    $r6,$r9,$r10
	stq     $r10,0($r3)
	addq    $r3,0x8,$r3
	addq    $r2,0x1,$r2
	cmple   $r2,0xf,$r1
	bne     $r1,loop
	call_pal        0x555

