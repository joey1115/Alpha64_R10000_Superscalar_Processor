/*
  This test was hand written by Joel VanLaven to put pressure on ROBs
  It generates and stores in order 64 32-bit pseudo-random numbers in 
  16 passes using 64-bit arithmetic.  (i.e. it actually generates 64-bit
  values and only keeps the more random high-order 32 bits).  The constants
  are from Knuth.  To be effective in testing the ROB the mult must take
  a while to execute and the ROB must be "small enough".  Assuming that
  there is any reasonably working form of branch prediction and that the
  Icache works and is large enough, multiple passes should end up going
  into the ROB at the same time increasing the efficacy of the test.  If
  for some reason the ROB is not filling with this test is should be
  easily modifiable to fill the ROB.

  In order to properly pass this test the pseudo-random numbers must be
  the correct numbers.
  
  $r1 = 8
*/
        lda     $r1,0x8		#0	0
start:  lda     $r2,0x27bb	#4	4
        sll     $r2,16,$r2	#8	8
        lda     $r0,0x2ee6	#12	c
        bis     $r2,$r0,$r2	#16	10
        lda     $r0,0x87b	#20	14
        sll     $r2,12,$r2	#24	18
        bis     $r2,$r0,$r2	#28	1c
        lda     $r0,0x0b0	#32	20
        sll     $r2,12,$r2	#36	24
        bis     $r2,$r0,$r2	#40	28
        lda     $r0,0xfd	#44	2c
        sll     $r2,8,$r2	#48	30
        bis     $r2,$r0,$r2	#52	34
	lda     $r3,0xb50	#56	38
        sll     $r3,12,$r3	#60	3c
        lda     $r0,0x4f3	#64	40
        bis     $r3,$r0,$r3	#68	44
        lda     $r0,0x2d	#72	48
        sll     $r3,0x4,$r3	#76	4c
        bis     $r3,$r0,$r3	#80	50
        lda     $r4,0		#84	54
loop:   addq    $r4,1,$r4	#88	58
        cmple   $r4,0xf,$r5	#92	5c
        mulq    $r1,$r2,$r10	#96	60
        addq    $r10,$r3,$r10	#100	64
        mulq    $r10,$r2,$r11	#104	68
        addq    $r11,$r3,$r11	#108	6c
        mulq    $r11,$r2,$r12	#112	70
        addq    $r12,$r3,$r12	#116	74
        mulq    $r12,$r2,$r1	#120	78
        addq    $r1,$r3,$r1	#124	7c
        srl     $r10,32,$r10	#128	80
        srl     $r11,32,$r11	#132	84
        srl     $r12,32,$r12	#136	88
        srl     $r1,32,$r13	#140	8c
        addq    $r0,32,$r0	#144	90
	bne     $r5,loop	#148	94
	call_pal        0x555	#152	98
