 	lda     $r0, 1024       # r0 is array base pointer
        lda     $r1, 256($r0)   # r1 is pointer to middle of array
	br	bubble
merge:	lda	$r20, 2048($r0)	# r20 is pointer to dest array base
	subq	$r1, 8, $r10	# r10 is pointer to end of first half
	lda	$r11, 256($r10)	# r11 is pointer to end of second half
	lda	$r21, 2048($r11) # r21 is pointer to end of dest array
mloop:	ldq	$r2,0($r0)
	ldq	$r3,0($r1)
	ldq	$r12,0($r10)
	ldq	$r13,0($r11)
	subq	$r3, $r2, $r4
	subq	$r13, $r12, $r14
	sra	$r4, 63, $r4
	sra	$r14, 63, $r14
	and	$r4, $r3, $r3
	and	$r14, $r12, $r12
	bic	$r2, $r4, $r2
	bic	$r13, $r14, $r13
	bis	$r2, $r3, $r2
	bis	$r12, $r13, $r12
	stq	$r2, 0($r20)
	stq	$r12, 0($r21)
	addq	$r20, 8, $r20
	lda	$r21, -8($r21)
	cmplt	$r21, $r20, $r22
	sll     $r4, 3, $r4
	sll	$r14, 3, $r14
        subq    $r1, $r4, $r1
	addq	$r10, $r14, $r10
        lda     $r4, 8($r4)
	lda	$r14, 8($r14)
        addq    $r0, $r4, $r0
	subq	$r11, $r14, $r11
	beq	$r22, mloop
	call_pal 0x555


	.align 10
	.quad	  2,   8,  23,   1,  17,   6,   7,  25 
        .quad	 26,  29,   6,  30,  23,  39,   3,   3 
	.quad	 10,  11,  36,  40,  63,  34,  36, 187
        .quad	  5,  96,  0,  34,  58,  86,  99,  65
	.quad	 36,  74,  34,  88,  63,  48,  59,   5
	.quad	 83,  91, 202, 143, 126, 175, 153,   0
	.quad	137, 159, 137,   9,  17,  30,  20,  19
        .quad    44,  12,  78, 148, 284, 163, 149, 145	

	.align 11
bubble:	subq	$r1, 8, $r2	# r2 is stopping point
oloop:  mov     $r0, $r10       # r10 is pointer /loop counter
        mov     $r1, $r20       # r20 is other pointer /loop counter
	ldq     $r11, 0($r0)
	ldq     $r21, 0($r1)
iloop:  ldq	$r12, 8($r10)
	ldq	$r22, 8($r20)
	addq	$r20, 8, $r20
	addq	$r10, 8, $r10
	cmplt	$r10, $r2, $r3
	subq	$r12, $r11, $r13
	subq	$r22, $r21, $r23
	sra	$r13, 63, $r13
	sra	$r23, 63, $r23
	xor	$r22, $r21, $r21
	xor	$r12, $r11, $r11
	bic	$r21, $r23, $r23
	bic	$r11, $r13, $r13
	xor	$r23, $r22, $r22
	xor	$r13, $r12, $r12
        stq     $r22, -8($r20)
	stq     $r12, -8($r10)
        xor     $r22, $r21, $r21
        xor     $r12, $r11, $r11
	bne	$r3, iloop
	stq     $r21, 0($r20)
        stq     $r11, 0($r10)
	subq	$r2, 8, $r2
	cmplt	$r0, $r2, $r3
	bne	$r3, oloop
	ldq     $r21, 0($r1)
	cmple	$r11, $r21, $r3
	br	merge
	beq	$r3, merge
	# fall through:	done
	call_pal 0x555
