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
*/
        data = 0x1000
	lda	$r0,data
        br	$r1,start
	.quad 	2862933555777941757
	.quad 	3037000493
start:  ldq     $r2,0($r1)
	ldq     $r3,8($r1)
        lda     $r4,0
loop:   addq    $r4,1,$r4
        cmple   $r4,0xf,$r5
        mulq    $r1,$r2,$r10
        addq    $r10,$r3,$r10
        mulq    $r10,$r2,$r11
        addq    $r11,$r3,$r11
        mulq    $r11,$r2,$r12
        addq    $r12,$r3,$r12
        mulq    $r12,$r2,$r1
        addq    $r1,$r3,$r1
        srl     $r10,32,$r10
        stq     $r10,0($r0)
        srl     $r11,32,$r11
        stq     $r11,8($r0)
        srl     $r12,32,$r12
        stq     $r12,16($r0)
        srl     $r1,32,$r13
        stq     $r13,24($r0)
        addq    $r0,32,$r0
	bne     $r5,loop
	call_pal        0x555
