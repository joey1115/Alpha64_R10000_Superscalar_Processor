    data2 = 0x2
    data3 = 0x3
    lda $r1,data2
    lda $r2,data3
    mulq $r1,$r1,$r5
    addq $r1,$r2,$r4
    addq $r1,$r2,$r6
	call_pal        0x555
