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
	lda     $r3,data       # 04
	nop                    # 08
	nop                    # 0c
	nop                    # 10
	nop                    # 14
	lda     $r4,data+8     # 18
	nop                    # 1c
	nop                    # 20
	nop                    # 24
	nop                    # 28
	lda     $r5,data+16    # 2c
	nop                    # 30
	nop                    # 34
	nop                    # 38
	nop                    # 3c
	lda     $r9,2          # 40
	nop                    # 44
	nop                    # 48
	nop                    # 4c
	nop                    # 50
	lda     $r1,1          # 54
	nop                    # 58
	nop                    # 5c
	nop                    # 60
	nop                    # 64
	stq     $r1,0($r3)     # 68
	nop                    # 6c
	nop                    # 70
	nop                    # 74
	nop                    # 78
	stq	$r1,0($r4)         # 7c
	nop                    # 80
	nop                    # 84
	nop                    # 88
	nop                    # 8c
loop:	ldq     $r1,0($r3) # 90
	nop                    # 94
	nop                    # 98
	nop                    # 9c
	nop                    # a0
	ldq     $r2,0($r4)     # a4
	nop                    # a8
	nop                    # ac
	nop                    # b0
	nop                    # b4
	addq    $r2,$r1,$r2    # b8
	nop                    # bc
	nop                    # c0
	nop                    # c4
	nop                    # c8
	addq    $r3,0x8,$r3    # cc
	nop                    # d0
	nop                    # d4
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
