/*
	TEST PROGRAM #7: bubble sort

	long a[] = { 3, 1, 4, 1, 5, 9, 2, 6, 5, 3, 5, 8, 9, 7, 9, 3 };

	main(void)
	{
	  for (i = 0; i < 16; ++i)
	    for (j = 0; j < (16-i); ++j)
	    {
	      if (a[j] < a[j+1])
	      {
		temp = a[j+1];
		a[j+1] = a[j];
		a[j] = temp;
	      }
	    }
	}
*/
/*
	Note that some instructions (e.g., clr, mov, negq) are standard
	Alpha assember pseudo-instructions.  See Table A-2 starting
	on p. A-14 of the Alpha Architecture Handbook.
*/
	
	br	start

	.align 3
	.quad	3, 1, 4, 1, 5, 9, 2, 6, 5, 3, 5, 8, 9, 7, 9, 3

	.align 3
start:	
	lda	$r0,8		# r0 is a array base pointer                8c
	clr	$r5		# r5 is i (loop counter)                      90

iloop:	clr	$r6		# r6 is j (inner loop counter)          94
	negq	$r5,$r7		# r7 is -i                              98
	addq	$r7,16,$r7	# r7 is now 16-i                      9c

	mov	$r0,$r1		# we'll use $r1 to index a[j] in the loop a0

jloop:	ldq	$r2,0($r1)	# r2 <- a[j]                      a4
	ldq	$r3,8($r1)	# r3 <- a[j+1]                          a8

	cmpult	$r2,$r3,$r4                                     ac
	bne	$r4,noswap	#  branch if $r2 < $r3                  b0

	# do swap
	stq	$r2,8($r1)                                          b4
	stq	$r3,0($r1)                                          b8

noswap:	# increment j (and a[j] ptr) and test
	addq	$r1,8,$r1                                         bc
	addq	$r6,1,$r6                                         c0
	cmpult	$r6,$r7,$r4                                     c4
	bne	$r4,jloop	# branch if $r6 < $r7                     c8

	# fall through: inner loop done, check outer loop (i)
	addq	$r5,1,$r5                                         cc
	cmpult	$r5,16,$r4                                      d0
	bne	$r4,iloop                                           d4

	# fall through:	done
	call_pal 0x555                                          d8
