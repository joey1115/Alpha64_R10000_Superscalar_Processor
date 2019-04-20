        data2 = 0x0
        data3 = 0x3
        data4 = 0x5
        lda $r1,data2
        lda $r2,data3
        lda $r4,data2
loop:   addq $r4,0x1,$r4
        cmple $r4,0xf,$r5
        addq $r1,$r2,$r10
        bne     $r5,loop
        addq $r1,$r2,$r20
	call_pal        0x555