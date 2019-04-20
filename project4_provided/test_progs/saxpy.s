/*
	TEST PROGRAM #6: integer SAXPY

	long x[] = { 3, 1, 4, 1, 5, 9, 2, 6, 5, 3, 5, 8, 9, 7, 9, 3, 2, 3 };
	long y[] = { 1, 4, 1, 4, 2, 1, 3, 5, 6, 2, 3, 7, 3, 0, 9, 5, 0, 4 };

	main(void)
	{
          long a = 9999;
	  long i;
	 
	  for (i=0; i < 18; i++)
	    {
	      y[i] = a*x[i] + y[i];
	    }
	}
*/

	br	start

	.align 3
	.quad	3, 1, 4, 1, 5, 9, 2, 6, 5, 3, 5, 8, 9, 7, 9, 3, 2, 3
	.quad   1, 4, 1, 4, 2, 1, 3, 5, 6, 2, 3, 7, 3, 0, 9, 5, 0, 4

	.align 3
start:	
	lda	$r5,0		# r5 is i (loop counter)
	lda	$r6,9999	# r6 is a
	lda	$r0,8		# r0 is x array pointer
	lda	$r1,8+(18*8)	# r1 is y array pointer

loop:	ldq	$r2,0($r0)	# r2 <- x[i]
	mulq	$r2,$r6,$r2	# r2 <- a * x[i]
	ldq	$r3,0($r1)	# r3 <- y[i]
	addq	$r3,$r2,$r2	# r2 += y[i]
	stq	$r2,0($r1)	# r2 -> y[i]

	# increment pointers
	addq	$r0,8,$r0
	addq	$r1,8,$r1

	# increment loop counter
	addq	$r5,1,$r5
	cmpult   $r5,18,$r4
	bne     $r4,loop

	# fall through: done
	call_pal        0x555
