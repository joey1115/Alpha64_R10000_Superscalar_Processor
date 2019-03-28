	bsr	$r26, itab
	mov	$r0, $r20	# r20 has tag of class i
	stq	$r1, 0($r0)	# return 1 if r2>r1.value, 0 otherwise (including no value)
	stq	$r2, 8($r0)	# return 1 if has a value
	stq     $r3, 16($r0)	# r1=r1.next
	stq     $r4, 24($r0)	# r0=r1.value
	stq	$r5, 32($r0)	# link r1.next=r2
 	bsr     $r26, htab
	mov	$r0, $r21	# r21 has tag of class h
        stq     $r1, 0($r0)
	stq     $r1, 8($r0)
	lda	$r22, 2048	# r22 has address of "heap"
	bsr	$r26, makeh
	mov	$r0, $r14	# r14 holds current head of linked list
	lda	$r15, 1024	# r15 holds current address in original list
	ldq	$r2, 0($r15)
	blt	$r2, print
oloop:	addq	$r15, 8, $r15
	ldq     $r6, 0($r14)
	ldq	$r5, 0($r6)
	mov	$r14, $r1
	jsr     $r26, ($r5)	# call to greaterthan function
	bne	$r0, sloop
	bsr     $r26, makei
	mov     $r0, $r14
	ldq     $r2, 0($r15)
        bge     $r2, oloop
	br	print
sloop:	mov	$r1, $r16	# r16 holds object to link to this one
	ldq     $r5, 16($r6)
	jsr     $r26, ($r5)	# call to next function
	ldq	$r6, 0($r1)
	ldq	$r5, 0($r6)	
	jsr	$r26, ($r5)	# call to greaterthan function
	bne	$r0, sloop
	bsr	$r26, makei
	mov	$r0, $r2
	mov     $r16, $r1
	ldq     $r6, 0($r1)
        ldq     $r5, 32($r6)
	jsr     $r26, ($r5)     # call to link function
	ldq     $r2, 0($r15)
	bge	$r2, oloop
print:	mov	$r14, $r1
	lda	$r15, 4096
prloop:	ldq     $r6, 0($r1)
        ldq     $r5, 8($r6)
	jsr     $r26, ($r5)     # call to cont function
	beq	$r0, stop
	ldq     $r5, 24($r6)
	jsr     $r26, ($r5)	# call to value function
	stq	$r0, 0($r15)
	ldq     $r5, 16($r6)
	jsr     $r26, ($r5)     # call to next function
	addq	$r15, 8, $r15
	br	prloop
stop:	call_pal 0x555
makeh:	mov	$r22, $r0
	stq	$r21, 0($r22)
	addq	$r22, 8, $r22
	ret
makei:	mov	$r22, $r0
	stq	$r20, 0($r22)
	stq	$r1, 16($r22)
	stq	$r2, 8($r22)
	addq	$r22, 24, $r22
	ret
igth:	ret	$r1
	lda	$r0, 0
	ret
conti:	br	$r2, nexti
	addq	$r31, 1, $r0
	ret
inti:	br	$r4, linki
	ldq	$r0, 8($r1)
	ret
nexti:	br	$r3, inti
	ldq	$r1, 16($r1)
	ret
linki:	br      $r5, igti
	stq	$r2, 16($r1)
	ret
igti:	ret	$r1
	ldq	$r3,8($r1)
	cmplt	$r3,$r2,$r0
	ret
	.align 3
	lda	$r0, 0		# filler
htab:	br 	$r0, igth
	.quad	0
	.quad	0
        lda     $r0, 0          # filler
itab:   br	$r0, conti
        .quad   0
	.quad	0
	.quad 	0


	.align 10
	.quad	  2,   8,  23,   1,  17,   6,   7,  25
        .quad	 26,  29,   6,  30,  23,  39,   3,   3 
	.quad	 10,  11,  36,  40,  63,  34,  36, 187
        .quad	  5,  96,  0,  34,  58,  86,  99,  65
	.quad	 36,  74,  34,  88,  63,  48,  59,   5
	.quad	 83,  91, 202, 143, 126, 175, 153,   0
	.quad	137, 159, 137,   9,  17,  30,  20,  19
        .quad    44,  12,  78, 148, 284, 163, 149, 145	
	.quad	-1
