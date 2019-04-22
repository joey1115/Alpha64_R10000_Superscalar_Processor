/*
	TEST PROGRAM #1: copy memory contents of 16 elements starting at
			 address 0x1000 over to starting address 0x1100. 
	

	long output[16];

	void
	main(void)
	{
	  long i;
	  *a = 0x1000;
          *b = 0x1100;
	 
	  for (i=0; i < 16; i++)
	    {
	      a[i] = i*10; 
	      b[i] = a[i]; 
	    }
	}
*/
	data = 0x1000
	lda	$r5,0
	nop
	nop
	nop
	nop
	lda	$r1,data
	nop
	nop
	nop
	nop
loop:	mulq	$r5,0x0a,$r2
	nop
	nop
	nop
	nop
	stq	$r2,0($r1)
	nop
	nop
	nop
	nop
	ldq	$r3,0($r1)
	nop
	nop
	nop
	nop
	stq     $r3,0x100($r1)
	nop
	nop
	nop
	nop
	addq    $r1,0x8,$r1
	nop
	nop
	nop
	nop
	addq	$r5,0x1,$r5
	nop
	nop
	nop
	nop
	cmple   $r5,0xf,$r4
	nop
	nop
	nop
	nop
	bne     $r4,loop
	nop
	nop
	nop
	nop
	call_pal        0x555
	nop
	nop
	nop
	nop

