bsr	$r26, itab                                                                           #04
	mov	$r0, $r20	# r20 has tag of class i                                     #08
	stq	$r1, 0($r0)	# return 1 if r2>r1.value, 0 otherwise (including no value)  #0c
	stq	$r2, 8($r0)	# return 1 if has a value                                    #10
	stq     $r3, 16($r0)	# r1=r1.next                                                 #14
	stq     $r4, 24($r0)	# r0=r1.value                                                #18
	stq	$r5, 32($r0)	# link r1.next=r2                                            #1c
 	bsr     $r26, htab                                                                   #20
	mov	$r0, $r21	# r21 has tag of class h                                     #24
        stq     $r1, 0($r0)                                                                  #28
	stq     $r1, 8($r0)                                                                  #2c
	lda	$r22, 2048	# r22 has address of "heap"                                  #30
	bsr	$r26, makeh                                                                  #34
	mov	$r0, $r14	# r14 holds current head of linked list                      #38
	lda	$r15, 1024	# r15 holds current address in original list                 #3c
	ldq	$r2, 0($r15)                                                                 #40
	blt	$r2, print                                                                   #44
oloop:	addq	$r15, 8, $r15                                                                #48
	ldq     $r6, 0($r14)                                                                 #4c
	ldq	$r5, 0($r6)                                                                  #50
	mov	$r14, $r1                                                                    #54
	jsr     $r26, ($r5)	# call to greaterthan function                               #58
	bne	$r0, sloop                                                                   #5C
	bsr     $r26, makei                                                                  #60
	mov     $r0, $r14                                                                    #64
	ldq     $r2, 0($r15)                                                                 #68
        bge     $r2, oloop                                                                   #6C
	br	print                                                                        #70
sloop:	mov	$r1, $r16	# r16 holds object to link to this one                       #74                                                
	ldq     $r5, 16($r6)                                                                 #78      
	jsr     $r26, ($r5)	# call to next function                                      #7C                                 
	ldq	$r6, 0($r1)                                                                  #80     
	ldq	$r5, 0($r6)	                                                             #84          
	jsr	$r26, ($r5)	# call to greaterthan function                               #88                                        
	bne	$r0, sloop                                                                   #8C    
	bsr	$r26, makei                                                                  #90     
	mov	$r0, $r2                                                                     #94  
	mov     $r16, $r1                                                                    #98   
	ldq     $r6, 0($r1)                                                                  #9C     
        ldq     $r5, 32($r6)                                                                 #A0      
	jsr     $r26, ($r5)     # call to link function                                      #A4                                 
	ldq     $r2, 0($r15)                                                                 #A8      
	bge	$r2, oloop                                                                   #AC    
print:	mov	$r14, $r1                                                                    #B0   
	lda	$r15, 4096                                                                   #B4    
prloop:	ldq     $r6, 0($r1)                                                                  #B8     
        ldq     $r5, 8($r6)                                                                  #BC     
	jsr     $r26, ($r5)     # call to cont function                                      #C0                                 
	beq	$r0, stop                                                                    #C4   
	ldq     $r5, 24($r6)                                                                 #C8      
	jsr     $r26, ($r5)	# call to value function                                     #CC                                  
	stq	$r0, 0($r15)                                                                 #D0      
	ldq     $r5, 16($r6)                                                                 #D4      
	jsr     $r26, ($r5)     # call to next function                                      #D8                                 
	addq	$r15, 8, $r15                                                                #DC       
	br	prloop                                                                       #E0
stop:	call_pal 0x555                                                                       #E4
makeh:	mov	$r22, $r0                                                                    #E8   
	stq	$r21, 0($r22)                                                                #EC       
	addq	$r22, 8, $r22                                                                #F0       
	ret                                                                                  #F4
makei:	mov	$r22, $r0                                                                    #F8   
	stq	$r20, 0($r22)                                                                #FC       
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
