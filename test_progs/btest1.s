/*
   btest1.s: Hammer on the branch prediction logic somewhat.
             This test is a series of 64 code-blocks that check a register
             and update a bit-vector by or'ing with 2^block#.  The resulting
             bit-vector sequence is 0xbeefbeefbaadbaad stored in mem line 2000

             Do not expect a decent prediction rate on this test.  No branches
             are re-visited (though a global predictor _may_ do reasonably well)
             The intent of this benchmark is to test control flow.

             Note: 'call_pal 0x000' is an instruction that is not decoded by
                   simplescalar3.  It is being used in this instance as a way
                   to pad the space between (almost) basic blocks with invalid
                   opcodes.
 */
data = 0x3E80
	lda $r29, 0
	lda $r0, 0
	lda $r1, 1
B0:	sll $r1, 0, $r20
	or $r20, $r29, $r29
	beq  $r0, B32
	br   bad
	call_pal 0x000
	call_pal 0x000
B1:	sll $r0, 1, $r20
	or $r20, $r29, $r29
	beq  $r0, B33
	br   bad
	call_pal 0x000
	call_pal 0x000
B2:	sll $r1, 2, $r20
	or $r20, $r29, $r29
	beq  $r0, B34
	br   bad
	call_pal 0x000
	call_pal 0x000
B3:	sll $r1, 3, $r20
	or $r20, $r29, $r29
	beq  $r0, B35
	br   bad
	call_pal 0x000
	call_pal 0x000
B4:	sll $r0, 4, $r20
	or $r20, $r29, $r29
	beq  $r0, B36
	br   bad
	call_pal 0x000
	call_pal 0x000
B5:	sll $r1, 5, $r20
	or $r20, $r29, $r29
	beq  $r0, B37
	br   bad
	call_pal 0x000
	call_pal 0x000
B6:	sll $r0, 6, $r20
	or $r20, $r29, $r29
	beq  $r0, B38
	br   bad
	call_pal 0x000
	call_pal 0x000
B7:	sll $r1, 7, $r20
	or $r20, $r29, $r29
	beq  $r0, B39
	br   bad
	call_pal 0x000
	call_pal 0x000
B8:	sll $r0, 8, $r20
	or $r20, $r29, $r29
	beq  $r0, B40
	br   bad
	call_pal 0x000
	call_pal 0x000
B9:	sll $r1, 9, $r20
	or $r20, $r29, $r29
	beq  $r0, B41
	br   bad
	call_pal 0x000
	call_pal 0x000
B10:	sll $r0, 10, $r20
	or $r20, $r29, $r29
	beq  $r0, B42
	br   bad
	call_pal 0x000
	call_pal 0x000
B11:	sll $r1, 11, $r20
	or $r20, $r29, $r29
	beq  $r0, B43
	br   bad
	call_pal 0x000
	call_pal 0x000
B12:	sll $r1, 12, $r20
	or $r20, $r29, $r29
	beq  $r0, B44
	br   bad
	call_pal 0x000
	call_pal 0x000
B13:	sll $r1, 13, $r20
	or $r20, $r29, $r29
	beq  $r0, B45
	br   bad
	call_pal 0x000
	call_pal 0x000
B14:	sll $r0, 14, $r20
	or $r20, $r29, $r29
	beq  $r0, B46
	br   bad
	call_pal 0x000
	call_pal 0x000
B15:	sll $r1, 15, $r20
	or $r20, $r29, $r29
	beq  $r0, B47
	br   bad
	call_pal 0x000
	call_pal 0x000
B16:	sll $r1, 16, $r20
	or $r20, $r29, $r29
	beq  $r0, B48
	br   bad
	call_pal 0x000
	call_pal 0x000
B17:	sll $r0, 17, $r20
	or $r20, $r29, $r29
	beq  $r0, B49
	br   bad
	call_pal 0x000
	call_pal 0x000
B18:	sll $r1, 18, $r20
	or $r20, $r29, $r29
	beq  $r0, B50
	br   bad
	call_pal 0x000
	call_pal 0x000
B19:	sll $r1, 19, $r20
	or $r20, $r29, $r29
	beq  $r0, B51
	br   bad
	call_pal 0x000
	call_pal 0x000
B20:	sll $r0, 20, $r20
	or $r20, $r29, $r29
	beq  $r0, B52
	br   bad
	call_pal 0x000
	call_pal 0x000
B21:	sll $r1, 21, $r20
	or $r20, $r29, $r29
	beq  $r0, B53
	br   bad
	call_pal 0x000
	call_pal 0x000
B22:	sll $r0, 22, $r20
	or $r20, $r29, $r29
	beq  $r0, B54
	br   bad
	call_pal 0x000
	call_pal 0x000
B23:	sll $r1, 23, $r20
	or $r20, $r29, $r29
	beq  $r0, B55
	br   bad
	call_pal 0x000
	call_pal 0x000
B24:	sll $r0, 24, $r20
	or $r20, $r29, $r29
	beq  $r0, B56
	br   bad
	call_pal 0x000
	call_pal 0x000
B25:	sll $r1, 25, $r20
	or $r20, $r29, $r29
	beq  $r0, B57
	br   bad
	call_pal 0x000
	call_pal 0x000
B26:	sll $r0, 26, $r20
	or $r20, $r29, $r29
	beq  $r0, B58
	br   bad
	call_pal 0x000
	call_pal 0x000
B27:	sll $r1, 27, $r20
	or $r20, $r29, $r29
	beq  $r0, B59
	br   bad
	call_pal 0x000
	call_pal 0x000
B28:	sll $r1, 28, $r20
	or $r20, $r29, $r29
	beq  $r0, B60
	br   bad
	call_pal 0x000
	call_pal 0x000
B29:	sll $r1, 29, $r20
	or $r20, $r29, $r29
	beq  $r0, B61
	br   bad
	call_pal 0x000
	call_pal 0x000
B30:	sll $r0, 30, $r20
	or $r20, $r29, $r29
	beq  $r0, B62
	br   bad
	call_pal 0x000
	call_pal 0x000
B31:	sll $r1, 31, $r20
	or $r20, $r29, $r29
	beq  $r0, B63
	br   bad
	call_pal 0x000
	call_pal 0x000
B32:	sll $r1, 32, $r20
	or $r20, $r29, $r29
	beq  $r1, bad
	br   B1
	call_pal 0x000
	call_pal 0x000
B33:	sll $r1, 33, $r20
	or $r20, $r29, $r29
	beq  $r1, bad
	br   B2
	call_pal 0x000
	call_pal 0x000
B34:	sll $r1, 34, $r20
	or $r20, $r29, $r29
	beq  $r1, bad
	br   B3
	call_pal 0x000
	call_pal 0x000
B35:	sll $r1, 35, $r20
	or $r20, $r29, $r29
	beq  $r1, bad
	br   B4
	call_pal 0x000
	call_pal 0x000
B36:	sll $r0, 36, $r20
	or $r20, $r29, $r29
	beq  $r1, bad
	br   B5
	call_pal 0x000
	call_pal 0x000
B37:	sll $r1, 37, $r20
	or $r20, $r29, $r29
	beq  $r1, bad
	br   B6
	call_pal 0x000
	call_pal 0x000
B38:	sll $r1, 38, $r20
	or $r20, $r29, $r29
	beq  $r1, bad
	br   B7
	call_pal 0x000
	call_pal 0x000
B39:	sll $r1, 39, $r20
	or $r20, $r29, $r29
	beq  $r1, bad
	br   B8
	call_pal 0x000
	call_pal 0x000
B40:	sll $r0, 40, $r20
	or $r20, $r29, $r29
	beq  $r1, bad
	br   B9
	call_pal 0x000
	call_pal 0x000
B41:	sll $r1, 41, $r20
	or $r20, $r29, $r29
	beq  $r1, bad
	br   B10
	call_pal 0x000
	call_pal 0x000
B42:	sll $r1, 42, $r20
	or $r20, $r29, $r29
	beq  $r1, bad
	br   B11
	call_pal 0x000
	call_pal 0x000
B43:	sll $r1, 43, $r20
	or $r20, $r29, $r29
	beq  $r1, bad
	br   B12
	call_pal 0x000
	call_pal 0x000
B44:	sll $r1, 44, $r20
	or $r20, $r29, $r29
	beq  $r1, bad
	br   B13
	call_pal 0x000
	call_pal 0x000
B45:	sll $r1, 45, $r20
	or $r20, $r29, $r29
	beq  $r1, bad
	br   B14
	call_pal 0x000
	call_pal 0x000
B46:	sll $r0, 46, $r20
	or $r20, $r29, $r29
	beq  $r1, bad
	br   B15
	call_pal 0x000
	call_pal 0x000
B47:	sll $r1, 47, $r20
	or $r20, $r29, $r29
	beq  $r1, bad
	br   B16
	call_pal 0x000
	call_pal 0x000
B48:	sll $r1, 48, $r20
	or $r20, $r29, $r29
	beq  $r1, bad
	br   B17
	call_pal 0x000
	call_pal 0x000
B49:	sll $r1, 49, $r20
	or $r20, $r29, $r29
	beq  $r1, bad
	br   B18
	call_pal 0x000
	call_pal 0x000
B50:	sll $r1, 50, $r20
	or $r20, $r29, $r29
	beq  $r1, bad
	br   B19
	call_pal 0x000
	call_pal 0x000
B51:	sll $r1, 51, $r20
	or $r20, $r29, $r29
	beq  $r1, bad
	br   B20
	call_pal 0x000
	call_pal 0x000
B52:	sll $r0, 52, $r20
	or $r20, $r29, $r29
	beq  $r1, bad
	br   B21
	call_pal 0x000
	call_pal 0x000
B53:	sll $r1, 53, $r20
	or $r20, $r29, $r29
	beq  $r1, bad
	br   B22
	call_pal 0x000
	call_pal 0x000
B54:	sll $r1, 54, $r20
	or $r20, $r29, $r29
	beq  $r1, bad
	br   B23
	call_pal 0x000
	call_pal 0x000
B55:	sll $r1, 55, $r20
	or $r20, $r29, $r29
	beq  $r1, bad
	br   B24
	call_pal 0x000
	call_pal 0x000
B56:	sll $r0, 56, $r20
	or $r20, $r29, $r29
	beq  $r1, bad
	br   B25
	call_pal 0x000
	call_pal 0x000
B57:	sll $r1, 57, $r20
	or $r20, $r29, $r29
	beq  $r1, bad
	br   B26
	call_pal 0x000
	call_pal 0x000
B58:	sll $r1, 58, $r20
	or $r20, $r29, $r29
	beq  $r1, bad
	br   B27
	call_pal 0x000
	call_pal 0x000
B59:	sll $r1, 59, $r20
	or $r20, $r29, $r29
	beq  $r1, bad
	br   B28
	call_pal 0x000
	call_pal 0x000
B60:	sll $r1, 60, $r20
	or $r20, $r29, $r29
	beq  $r1, bad
	br   B29
	call_pal 0x000
	call_pal 0x000
B61:	sll $r1, 61, $r20
	or $r20, $r29, $r29
	beq  $r1, bad
	br   B30
	call_pal 0x000
	call_pal 0x000
B62:	sll $r0, 62, $r20
	or $r20, $r29, $r29
	beq  $r1, bad
	br   B31
	call_pal 0x000
	call_pal 0x000
B63:	sll $r1, 63, $r20
	or $r20, $r29, $r29
	beq  $r1, bad
	br   end
	call_pal 0x000
	call_pal 0x000
end:	lda $r20, data
	stq $r29, 0($r20)
	call_pal 0x555 # this is where we should exit
bad:	call_pal 0x000
