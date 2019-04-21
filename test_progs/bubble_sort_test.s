/*
  Assembly code compiled from Decaf by 'decaf470', written by Doug Li.
*/

	  .set noat
	  .set noreorder
	  .set nomacro
	  data = 0x1000
	  global = 0x2000
	  lda		$r30, 0x7FF0	# set stack ptr to a sufficiently high addr
	  lda		$r15, 0x0000	# initialize frame ptr to something
	  lda		$r29, global	# initialize global ptr to 0x2000
	# Initialize Heap Management Table
	#   could be done at compile-time, but then we get a super large .mem file
	  heap_srl_3 = 0x1800
	  lda		$r28, heap_srl_3	# work-around since heap-start needs >15 bits
	  sll		$r28, 3, $r28	# using the $at as the heap-pointer
	# Do not write to heap-pointer!
	  stq		$r31, -32*8($r28)	# init heap table
	  stq		$r31, -31*8($r28)	# init heap table
	  stq		$r31, -30*8($r28)	# init heap table
	  stq		$r31, -29*8($r28)	# init heap table
	  stq		$r31, -28*8($r28)	# init heap table
	  stq		$r31, -27*8($r28)	# init heap table
	  stq		$r31, -26*8($r28)	# init heap table
	  stq		$r31, -25*8($r28)	# init heap table
	  stq		$r31, -24*8($r28)	# init heap table
	  stq		$r31, -23*8($r28)	# init heap table
	  stq		$r31, -22*8($r28)	# init heap table
	  stq		$r31, -21*8($r28)	# init heap table
	  stq		$r31, -20*8($r28)	# init heap table
	  stq		$r31, -19*8($r28)	# init heap table
	  stq		$r31, -18*8($r28)	# init heap table
	  stq		$r31, -17*8($r28)	# init heap table
	  stq		$r31, -16*8($r28)	# init heap table
	  stq		$r31, -15*8($r28)	# init heap table
	  stq		$r31, -14*8($r28)	# init heap table
	  stq		$r31, -13*8($r28)	# init heap table
	  stq		$r31, -12*8($r28)	# init heap table
	  stq		$r31, -11*8($r28)	# init heap table
	  stq		$r31, -10*8($r28)	# init heap table
	  stq		$r31, -9*8($r28)	# init heap table
	  stq		$r31, -8*8($r28)	# init heap table
	  stq		$r31, -7*8($r28)	# init heap table
	  stq		$r31, -6*8($r28)	# init heap table
	  stq		$r31, -5*8($r28)	# init heap table
	  stq		$r31, -4*8($r28)	# init heap table
	  stq		$r31, -3*8($r28)	# init heap table
	  stq		$r31, -2*8($r28)	# init heap table
	  stq		$r31, -1*8($r28)	# init heap table
	# End Initialize Heap Management Table
	  bsr		$r26, main	# branch to subroutine
	  call_pal	0x555		# (halt)
	  .data
	  L_DATA:			# this is where the locals and temps end up at run-time
	  .text
main:
	# BeginFunc 544
	  subq		$r30, 16, $r30	# decrement sp to make space to save ra, fp
	  stq		$r15, 16($r30)	# save fp
	  stq		$r26, 8($r30)	# save ra
	  addq		$r30, 16, $r15	# set up new fp
	  lda		$r2, 544	# stack frame size
	  subq		$r30, $r2, $r30	# decrement sp to make space for locals/temps
	# _tmp0 = {3,1,4,1,5,9,2,6,5,3,5,8,9,7,9,3}
	  .data
	  .quad 16		# array size for the following int array
    __int_array1:
	  .quad 3		# [0]
	  .quad 1		# [1]
	  .quad 4		# [2]
	  .quad 1		# [3]
	  .quad 5		# [4]
	  .quad 9		# [5]
	  .quad 2		# [6]
	  .quad 6		# [7]
	  .quad 5		# [8]
	  .quad 3		# [9]
	  .quad 5		# [10]
	  .quad 8		# [11]
	  .quad 9		# [12]
	  .quad 7		# [13]
	  .quad 9		# [14]
	  .quad 3		# [15]
	  .text
	  lda		$r3, __int_array1-L_DATA+data # a hack!
	  stq		$r3, -48($r15)	# spill _tmp0 from $r3 to $r15-48
	# input = _tmp0
	  ldq		$r3, -48($r15)	# fill _tmp0 to $r3 from $r15-48
	  stq		$r3, -40($r15)	# spill input from $r3 to $r15-40
	# _tmp1 = *(input + -8)
	  ldq		$r1, -40($r15)	# fill input to $r1 from $r15-40
	  ldq		$r3, -8($r1)	# load with offset
	  stq		$r3, -56($r15)	# spill _tmp1 from $r3 to $r15-56
	# _tmp2 = _tmp1 + 1
	  ldq		$r1, -56($r15)	# fill _tmp1 to $r1 from $r15-56
	  addq		$r1, 1, $r3	# perform the ALU op
	  stq		$r3, -64($r15)	# spill _tmp2 from $r3 to $r15-64
	# PushParam _tmp2
	  subq		$r30, 8, $r30	# decrement stack ptr to make space for param
	  ldq		$r1, -64($r15)	# fill _tmp2 to $r1 from $r15-64
	  stq		$r1, 8($r30)	# copy param value to stack
	# _tmp3 = LCall __Alloc
	  bsr		$r26, __Alloc	# branch to function
	  mov		$r0, $r3	# copy function return value from $v0
	  stq		$r3, -72($r15)	# spill _tmp3 from $r3 to $r15-72
	# PopParams 8
	  addq		$r30, 8, $r30	# pop params off stack
	# *(_tmp3) = _tmp1
	  ldq		$r1, -56($r15)	# fill _tmp1 to $r1 from $r15-56
	  ldq		$r3, -72($r15)	# fill _tmp3 to $r3 from $r15-72
	  stq		$r1, 0($r3)	# store with offset
	# _tmp4 = _tmp3 + 8
	  ldq		$r1, -72($r15)	# fill _tmp3 to $r1 from $r15-72
	  addq		$r1, 8, $r3	# perform the ALU op
	  stq		$r3, -80($r15)	# spill _tmp4 from $r3 to $r15-80
	# a = _tmp4
	  ldq		$r3, -80($r15)	# fill _tmp4 to $r3 from $r15-80
	  stq		$r3, 0($r29)	# spill a from $r3 to $r29+0
	# _tmp5 = 0
	  lda		$r3, 0		# load (unsigned) int constant value 0 into $r3
	  stq		$r3, -88($r15)	# spill _tmp5 from $r3 to $r15-88
	# i = _tmp5
	  ldq		$r3, -88($r15)	# fill _tmp5 to $r3 from $r15-88
	  stq		$r3, -16($r15)	# spill i from $r3 to $r15-16
__L0:
	# _tmp6 = *(input + -8)
	  ldq		$r1, -40($r15)	# fill input to $r1 from $r15-40
	  ldq		$r3, -8($r1)	# load with offset
	  stq		$r3, -96($r15)	# spill _tmp6 from $r3 to $r15-96
	# _tmp7 = i < _tmp6
	  ldq		$r1, -16($r15)	# fill i to $r1 from $r15-16
	  ldq		$r2, -96($r15)	# fill _tmp6 to $r2 from $r15-96
	  cmplt		$r1, $r2, $r3	# perform the ALU op
	  stq		$r3, -104($r15)	# spill _tmp7 from $r3 to $r15-104
	# IfZ _tmp7 Goto __L1
	  ldq		$r1, -104($r15)	# fill _tmp7 to $r1 from $r15-104
	  blbc		$r1, __L1	# branch if _tmp7 is zero
	# _tmp8 = *(a + -8)
	  ldq		$r1, 0($r29)	# fill a to $r1 from $r29+0
	  ldq		$r3, -8($r1)	# load with offset
	  stq		$r3, -112($r15)	# spill _tmp8 from $r3 to $r15-112
	# _tmp9 = _tmp8 u<= i
	  ldq		$r1, -112($r15)	# fill _tmp8 to $r1 from $r15-112
	  ldq		$r2, -16($r15)	# fill i to $r2 from $r15-16
	  cmpule	$r1, $r2, $r3	# perform the ALU op
	  stq		$r3, -120($r15)	# spill _tmp9 from $r3 to $r15-120
	# IfZ _tmp9 Goto __L2
	  ldq		$r1, -120($r15)	# fill _tmp9 to $r1 from $r15-120
	  blbc		$r1, __L2	# branch if _tmp9 is zero
	# Throw Exception: Array subscript out of bounds
	  call_pal	0xDECAF		# (exception: Array subscript out of bounds)
	  call_pal	0x555		# (halt)
__L2:
	# _tmp10 = i << 3
	  ldq		$r1, -16($r15)	# fill i to $r1 from $r15-16
	  sll		$r1, 3, $r3	# perform the ALU op
	  stq		$r3, -128($r15)	# spill _tmp10 from $r3 to $r15-128
	# _tmp11 = a + _tmp10
	  ldq		$r1, 0($r29)	# fill a to $r1 from $r29+0
	  ldq		$r2, -128($r15)	# fill _tmp10 to $r2 from $r15-128
	  addq		$r1, $r2, $r3	# perform the ALU op
	  stq		$r3, -136($r15)	# spill _tmp11 from $r3 to $r15-136
	# _tmp12 = *(input + -8)
	  ldq		$r1, -40($r15)	# fill input to $r1 from $r15-40
	  ldq		$r3, -8($r1)	# load with offset
	  stq		$r3, -144($r15)	# spill _tmp12 from $r3 to $r15-144
	# _tmp13 = _tmp12 u<= i
	  ldq		$r1, -144($r15)	# fill _tmp12 to $r1 from $r15-144
	  ldq		$r2, -16($r15)	# fill i to $r2 from $r15-16
	  cmpule	$r1, $r2, $r3	# perform the ALU op
	  stq		$r3, -152($r15)	# spill _tmp13 from $r3 to $r15-152
	# IfZ _tmp13 Goto __L3
	  ldq		$r1, -152($r15)	# fill _tmp13 to $r1 from $r15-152
	  blbc		$r1, __L3	# branch if _tmp13 is zero
	# Throw Exception: Array subscript out of bounds
	  call_pal	0xDECAF		# (exception: Array subscript out of bounds)
	  call_pal	0x555		# (halt)
__L3:
	# _tmp14 = i << 3
	  ldq		$r1, -16($r15)	# fill i to $r1 from $r15-16
	  sll		$r1, 3, $r3	# perform the ALU op
	  stq		$r3, -160($r15)	# spill _tmp14 from $r3 to $r15-160
	# _tmp15 = input + _tmp14
	  ldq		$r1, -40($r15)	# fill input to $r1 from $r15-40
	  ldq		$r2, -160($r15)	# fill _tmp14 to $r2 from $r15-160
	  addq		$r1, $r2, $r3	# perform the ALU op
	  stq		$r3, -168($r15)	# spill _tmp15 from $r3 to $r15-168
	# _tmp16 = *(_tmp15)
	  ldq		$r1, -168($r15)	# fill _tmp15 to $r1 from $r15-168
	  ldq		$r3, 0($r1)	# load with offset
	  stq		$r3, -176($r15)	# spill _tmp16 from $r3 to $r15-176
	# *(_tmp11) = _tmp16
	  ldq		$r1, -176($r15)	# fill _tmp16 to $r1 from $r15-176
	  ldq		$r3, -136($r15)	# fill _tmp11 to $r3 from $r15-136
	  stq		$r1, 0($r3)	# store with offset
	# _tmp17 = 1
	  lda		$r3, 1		# load (unsigned) int constant value 1 into $r3
	  stq		$r3, -184($r15)	# spill _tmp17 from $r3 to $r15-184
	# i += _tmp17
	  ldq		$r2, -184($r15)	# fill _tmp17 to $r2 from $r15-184
	  ldq		$r3, -16($r15)	# fill i to $r3 from $r15-16
	  addq		$r3, $r2, $r3	# perform the ALU op
	  stq		$r3, -16($r15)	# spill i from $r3 to $r15-16
	# Goto __L0
	  br		__L0		# unconditional branch
__L1:
	# _tmp18 = 0
	  lda		$r3, 0		# load (unsigned) int constant value 0 into $r3
	  stq		$r3, -192($r15)	# spill _tmp18 from $r3 to $r15-192
	# i = _tmp18
	  ldq		$r3, -192($r15)	# fill _tmp18 to $r3 from $r15-192
	  stq		$r3, -16($r15)	# spill i from $r3 to $r15-16
__L4:
	# _tmp19 = *(a + -8)
	  ldq		$r1, 0($r29)	# fill a to $r1 from $r29+0
	  ldq		$r3, -8($r1)	# load with offset
	  stq		$r3, -200($r15)	# spill _tmp19 from $r3 to $r15-200
	# _tmp20 = 1
	  lda		$r3, 1		# load (unsigned) int constant value 1 into $r3
	  stq		$r3, -208($r15)	# spill _tmp20 from $r3 to $r15-208
	# _tmp21 = _tmp19 - _tmp20
	  ldq		$r1, -200($r15)	# fill _tmp19 to $r1 from $r15-200
	  ldq		$r2, -208($r15)	# fill _tmp20 to $r2 from $r15-208
	  subq		$r1, $r2, $r3	# perform the ALU op
	  stq		$r3, -216($r15)	# spill _tmp21 from $r3 to $r15-216
	# _tmp22 = i < _tmp21
	  ldq		$r1, -16($r15)	# fill i to $r1 from $r15-16
	  ldq		$r2, -216($r15)	# fill _tmp21 to $r2 from $r15-216
	  cmplt		$r1, $r2, $r3	# perform the ALU op
	  stq		$r3, -224($r15)	# spill _tmp22 from $r3 to $r15-224
	# IfZ _tmp22 Goto __L5
	  ldq		$r1, -224($r15)	# fill _tmp22 to $r1 from $r15-224
	  blbc		$r1, __L5	# branch if _tmp22 is zero
	# _tmp23 = 0
	  lda		$r3, 0		# load (unsigned) int constant value 0 into $r3
	  stq		$r3, -232($r15)	# spill _tmp23 from $r3 to $r15-232
	# j = _tmp23
	  ldq		$r3, -232($r15)	# fill _tmp23 to $r3 from $r15-232
	  stq		$r3, -24($r15)	# spill j from $r3 to $r15-24
__L6:
	# _tmp24 = *(a + -8)
	  ldq		$r1, 0($r29)	# fill a to $r1 from $r29+0
	  ldq		$r3, -8($r1)	# load with offset
	  stq		$r3, -240($r15)	# spill _tmp24 from $r3 to $r15-240
	# _tmp25 = _tmp24 - i
	  ldq		$r1, -240($r15)	# fill _tmp24 to $r1 from $r15-240
	  ldq		$r2, -16($r15)	# fill i to $r2 from $r15-16
	  subq		$r1, $r2, $r3	# perform the ALU op
	  stq		$r3, -248($r15)	# spill _tmp25 from $r3 to $r15-248
	# _tmp26 = 1
	  lda		$r3, 1		# load (unsigned) int constant value 1 into $r3
	  stq		$r3, -256($r15)	# spill _tmp26 from $r3 to $r15-256
	# _tmp27 = _tmp25 - _tmp26
	  ldq		$r1, -248($r15)	# fill _tmp25 to $r1 from $r15-248
	  ldq		$r2, -256($r15)	# fill _tmp26 to $r2 from $r15-256
	  subq		$r1, $r2, $r3	# perform the ALU op
	  stq		$r3, -264($r15)	# spill _tmp27 from $r3 to $r15-264
	# _tmp28 = j < _tmp27
	  ldq		$r1, -24($r15)	# fill j to $r1 from $r15-24
	  ldq		$r2, -264($r15)	# fill _tmp27 to $r2 from $r15-264
	  cmplt		$r1, $r2, $r3	# perform the ALU op
	  stq		$r3, -272($r15)	# spill _tmp28 from $r3 to $r15-272
	# IfZ _tmp28 Goto __L7
	  ldq		$r1, -272($r15)	# fill _tmp28 to $r1 from $r15-272
	  blbc		$r1, __L7	# branch if _tmp28 is zero
	# _tmp29 = *(a + -8)
	  ldq		$r1, 0($r29)	# fill a to $r1 from $r29+0
	  ldq		$r3, -8($r1)	# load with offset
	  stq		$r3, -280($r15)	# spill _tmp29 from $r3 to $r15-280
	# _tmp30 = _tmp29 u<= j
	  ldq		$r1, -280($r15)	# fill _tmp29 to $r1 from $r15-280
	  ldq		$r2, -24($r15)	# fill j to $r2 from $r15-24
	  cmpule	$r1, $r2, $r3	# perform the ALU op
	  stq		$r3, -288($r15)	# spill _tmp30 from $r3 to $r15-288
	# IfZ _tmp30 Goto __L8
	  ldq		$r1, -288($r15)	# fill _tmp30 to $r1 from $r15-288
	  blbc		$r1, __L8	# branch if _tmp30 is zero
	# Throw Exception: Array subscript out of bounds
	  call_pal	0xDECAF		# (exception: Array subscript out of bounds)
	  call_pal	0x555		# (halt)
__L8:
	# _tmp31 = j << 3
	  ldq		$r1, -24($r15)	# fill j to $r1 from $r15-24
	  sll		$r1, 3, $r3	# perform the ALU op
	  stq		$r3, -296($r15)	# spill _tmp31 from $r3 to $r15-296
	# _tmp32 = a + _tmp31
	  ldq		$r1, 0($r29)	# fill a to $r1 from $r29+0
	  ldq		$r2, -296($r15)	# fill _tmp31 to $r2 from $r15-296
	  addq		$r1, $r2, $r3	# perform the ALU op
	  stq		$r3, -304($r15)	# spill _tmp32 from $r3 to $r15-304
	# _tmp33 = *(_tmp32)
	  ldq		$r1, -304($r15)	# fill _tmp32 to $r1 from $r15-304
	  ldq		$r3, 0($r1)	# load with offset
	  stq		$r3, -312($r15)	# spill _tmp33 from $r3 to $r15-312
	# _tmp34 = 1
	  lda		$r3, 1		# load (unsigned) int constant value 1 into $r3
	  stq		$r3, -320($r15)	# spill _tmp34 from $r3 to $r15-320
	# _tmp35 = j + _tmp34
	  ldq		$r1, -24($r15)	# fill j to $r1 from $r15-24
	  ldq		$r2, -320($r15)	# fill _tmp34 to $r2 from $r15-320
	  addq		$r1, $r2, $r3	# perform the ALU op
	  stq		$r3, -328($r15)	# spill _tmp35 from $r3 to $r15-328
	# _tmp36 = *(a + -8)
	  ldq		$r1, 0($r29)	# fill a to $r1 from $r29+0
	  ldq		$r3, -8($r1)	# load with offset
	  stq		$r3, -336($r15)	# spill _tmp36 from $r3 to $r15-336
	# _tmp37 = _tmp36 u<= _tmp35
	  ldq		$r1, -336($r15)	# fill _tmp36 to $r1 from $r15-336
	  ldq		$r2, -328($r15)	# fill _tmp35 to $r2 from $r15-328
	  cmpule	$r1, $r2, $r3	# perform the ALU op
	  stq		$r3, -344($r15)	# spill _tmp37 from $r3 to $r15-344
	# IfZ _tmp37 Goto __L9
	  ldq		$r1, -344($r15)	# fill _tmp37 to $r1 from $r15-344
	  blbc		$r1, __L9	# branch if _tmp37 is zero
	# Throw Exception: Array subscript out of bounds
	  call_pal	0xDECAF		# (exception: Array subscript out of bounds)
	  call_pal	0x555		# (halt)
__L9:
	# _tmp38 = _tmp35 << 3
	  ldq		$r1, -328($r15)	# fill _tmp35 to $r1 from $r15-328
	  sll		$r1, 3, $r3	# perform the ALU op
	  stq		$r3, -352($r15)	# spill _tmp38 from $r3 to $r15-352
	# _tmp39 = a + _tmp38
	  ldq		$r1, 0($r29)	# fill a to $r1 from $r29+0
	  ldq		$r2, -352($r15)	# fill _tmp38 to $r2 from $r15-352
	  addq		$r1, $r2, $r3	# perform the ALU op
	  stq		$r3, -360($r15)	# spill _tmp39 from $r3 to $r15-360
	# _tmp40 = *(_tmp39)
	  ldq		$r1, -360($r15)	# fill _tmp39 to $r1 from $r15-360
	  ldq		$r3, 0($r1)	# load with offset
	  stq		$r3, -368($r15)	# spill _tmp40 from $r3 to $r15-368
	# _tmp41 = _tmp33 < _tmp40
	  ldq		$r1, -312($r15)	# fill _tmp33 to $r1 from $r15-312
	  ldq		$r2, -368($r15)	# fill _tmp40 to $r2 from $r15-368
	  cmplt		$r1, $r2, $r3	# perform the ALU op
	  stq		$r3, -376($r15)	# spill _tmp41 from $r3 to $r15-376
	# IfZ _tmp41 Goto __L10
	  ldq		$r1, -376($r15)	# fill _tmp41 to $r1 from $r15-376
	  blbc		$r1, __L10	# branch if _tmp41 is zero
	# _tmp42 = 1
	  lda		$r3, 1		# load (unsigned) int constant value 1 into $r3
	  stq		$r3, -384($r15)	# spill _tmp42 from $r3 to $r15-384
	# _tmp43 = j + _tmp42
	  ldq		$r1, -24($r15)	# fill j to $r1 from $r15-24
	  ldq		$r2, -384($r15)	# fill _tmp42 to $r2 from $r15-384
	  addq		$r1, $r2, $r3	# perform the ALU op
	  stq		$r3, -392($r15)	# spill _tmp43 from $r3 to $r15-392
	# _tmp44 = *(a + -8)
	  ldq		$r1, 0($r29)	# fill a to $r1 from $r29+0
	  ldq		$r3, -8($r1)	# load with offset
	  stq		$r3, -400($r15)	# spill _tmp44 from $r3 to $r15-400
	# _tmp45 = _tmp44 u<= _tmp43
	  ldq		$r1, -400($r15)	# fill _tmp44 to $r1 from $r15-400
	  ldq		$r2, -392($r15)	# fill _tmp43 to $r2 from $r15-392
	  cmpule	$r1, $r2, $r3	# perform the ALU op
	  stq		$r3, -408($r15)	# spill _tmp45 from $r3 to $r15-408
	# IfZ _tmp45 Goto __L11
	  ldq		$r1, -408($r15)	# fill _tmp45 to $r1 from $r15-408
	  blbc		$r1, __L11	# branch if _tmp45 is zero
	# Throw Exception: Array subscript out of bounds
	  call_pal	0xDECAF		# (exception: Array subscript out of bounds)
	  call_pal	0x555		# (halt)
__L11:
	# _tmp46 = _tmp43 << 3
	  ldq		$r1, -392($r15)	# fill _tmp43 to $r1 from $r15-392
	  sll		$r1, 3, $r3	# perform the ALU op
	  stq		$r3, -416($r15)	# spill _tmp46 from $r3 to $r15-416
	# _tmp47 = a + _tmp46
	  ldq		$r1, 0($r29)	# fill a to $r1 from $r29+0
	  ldq		$r2, -416($r15)	# fill _tmp46 to $r2 from $r15-416
	  addq		$r1, $r2, $r3	# perform the ALU op
	  stq		$r3, -424($r15)	# spill _tmp47 from $r3 to $r15-424
	# _tmp48 = *(_tmp47)
	  ldq		$r1, -424($r15)	# fill _tmp47 to $r1 from $r15-424
	  ldq		$r3, 0($r1)	# load with offset
	  stq		$r3, -432($r15)	# spill _tmp48 from $r3 to $r15-432
	# temp = _tmp48
	  ldq		$r3, -432($r15)	# fill _tmp48 to $r3 from $r15-432
	  stq		$r3, -32($r15)	# spill temp from $r3 to $r15-32
	# _tmp49 = 1
	  lda		$r3, 1		# load (unsigned) int constant value 1 into $r3
	  stq		$r3, -440($r15)	# spill _tmp49 from $r3 to $r15-440
	# _tmp50 = j + _tmp49
	  ldq		$r1, -24($r15)	# fill j to $r1 from $r15-24
	  ldq		$r2, -440($r15)	# fill _tmp49 to $r2 from $r15-440
	  addq		$r1, $r2, $r3	# perform the ALU op
	  stq		$r3, -448($r15)	# spill _tmp50 from $r3 to $r15-448
	# _tmp51 = *(a + -8)
	  ldq		$r1, 0($r29)	# fill a to $r1 from $r29+0
	  ldq		$r3, -8($r1)	# load with offset
	  stq		$r3, -456($r15)	# spill _tmp51 from $r3 to $r15-456
	# _tmp52 = _tmp51 u<= _tmp50
	  ldq		$r1, -456($r15)	# fill _tmp51 to $r1 from $r15-456
	  ldq		$r2, -448($r15)	# fill _tmp50 to $r2 from $r15-448
	  cmpule	$r1, $r2, $r3	# perform the ALU op
	  stq		$r3, -464($r15)	# spill _tmp52 from $r3 to $r15-464
	# IfZ _tmp52 Goto __L12
	  ldq		$r1, -464($r15)	# fill _tmp52 to $r1 from $r15-464
	  blbc		$r1, __L12	# branch if _tmp52 is zero
	# Throw Exception: Array subscript out of bounds
	  call_pal	0xDECAF		# (exception: Array subscript out of bounds)
	  call_pal	0x555		# (halt)
__L12:
	# _tmp53 = _tmp50 << 3
	  ldq		$r1, -448($r15)	# fill _tmp50 to $r1 from $r15-448
	  sll		$r1, 3, $r3	# perform the ALU op
	  stq		$r3, -472($r15)	# spill _tmp53 from $r3 to $r15-472
	# _tmp54 = a + _tmp53
	  ldq		$r1, 0($r29)	# fill a to $r1 from $r29+0
	  ldq		$r2, -472($r15)	# fill _tmp53 to $r2 from $r15-472
	  addq		$r1, $r2, $r3	# perform the ALU op
	  stq		$r3, -480($r15)	# spill _tmp54 from $r3 to $r15-480
	# _tmp55 = *(a + -8)
	  ldq		$r1, 0($r29)	# fill a to $r1 from $r29+0
	  ldq		$r3, -8($r1)	# load with offset
	  stq		$r3, -488($r15)	# spill _tmp55 from $r3 to $r15-488
	# _tmp56 = _tmp55 u<= j
	  ldq		$r1, -488($r15)	# fill _tmp55 to $r1 from $r15-488
	  ldq		$r2, -24($r15)	# fill j to $r2 from $r15-24
	  cmpule	$r1, $r2, $r3	# perform the ALU op
	  stq		$r3, -496($r15)	# spill _tmp56 from $r3 to $r15-496
	# IfZ _tmp56 Goto __L13
	  ldq		$r1, -496($r15)	# fill _tmp56 to $r1 from $r15-496
	  blbc		$r1, __L13	# branch if _tmp56 is zero
	# Throw Exception: Array subscript out of bounds
	  call_pal	0xDECAF		# (exception: Array subscript out of bounds)
	  call_pal	0x555		# (halt)
__L13:
	# _tmp57 = j << 3
	  ldq		$r1, -24($r15)	# fill j to $r1 from $r15-24
	  sll		$r1, 3, $r3	# perform the ALU op
	  stq		$r3, -504($r15)	# spill _tmp57 from $r3 to $r15-504
	# _tmp58 = a + _tmp57
	  ldq		$r1, 0($r29)	# fill a to $r1 from $r29+0
	  ldq		$r2, -504($r15)	# fill _tmp57 to $r2 from $r15-504
	  addq		$r1, $r2, $r3	# perform the ALU op
	  stq		$r3, -512($r15)	# spill _tmp58 from $r3 to $r15-512
	# _tmp59 = *(_tmp58)
	  ldq		$r1, -512($r15)	# fill _tmp58 to $r1 from $r15-512
	  ldq		$r3, 0($r1)	# load with offset
	  stq		$r3, -520($r15)	# spill _tmp59 from $r3 to $r15-520
	# *(_tmp54) = _tmp59
	  ldq		$r1, -520($r15)	# fill _tmp59 to $r1 from $r15-520
	  ldq		$r3, -480($r15)	# fill _tmp54 to $r3 from $r15-480
	  stq		$r1, 0($r3)	# store with offset
	# _tmp60 = *(a + -8)
	  ldq		$r1, 0($r29)	# fill a to $r1 from $r29+0
	  ldq		$r3, -8($r1)	# load with offset
	  stq		$r3, -528($r15)	# spill _tmp60 from $r3 to $r15-528
	# _tmp61 = _tmp60 u<= j
	  ldq		$r1, -528($r15)	# fill _tmp60 to $r1 from $r15-528
	  ldq		$r2, -24($r15)	# fill j to $r2 from $r15-24
	  cmpule	$r1, $r2, $r3	# perform the ALU op
	  stq		$r3, -536($r15)	# spill _tmp61 from $r3 to $r15-536
	# IfZ _tmp61 Goto __L14
	  ldq		$r1, -536($r15)	# fill _tmp61 to $r1 from $r15-536
	  blbc		$r1, __L14	# branch if _tmp61 is zero
	# Throw Exception: Array subscript out of bounds
	  call_pal	0xDECAF		# (exception: Array subscript out of bounds)
	  call_pal	0x555		# (halt)
__L14:
	# _tmp62 = j << 3
	  ldq		$r1, -24($r15)	# fill j to $r1 from $r15-24
	  sll		$r1, 3, $r3	# perform the ALU op
	  stq		$r3, -544($r15)	# spill _tmp62 from $r3 to $r15-544
	# _tmp63 = a + _tmp62
	  ldq		$r1, 0($r29)	# fill a to $r1 from $r29+0
	  ldq		$r2, -544($r15)	# fill _tmp62 to $r2 from $r15-544
	  addq		$r1, $r2, $r3	# perform the ALU op
	  stq		$r3, -552($r15)	# spill _tmp63 from $r3 to $r15-552
	# *(_tmp63) = temp
	  ldq		$r1, -32($r15)	# fill temp to $r1 from $r15-32
	  ldq		$r3, -552($r15)	# fill _tmp63 to $r3 from $r15-552
	  stq		$r1, 0($r3)	# store with offset
__L10:
	# j += 1
	  ldq		$r3, -24($r15)	# fill j to $r3 from $r15-24
	  addq		$r3, 1, $r3	# perform the ALU op
	  stq		$r3, -24($r15)	# spill j from $r3 to $r15-24
	# Goto __L6
	  br		__L6		# unconditional branch
__L7:
	# i += 1
	  ldq		$r3, -16($r15)	# fill i to $r3 from $r15-16
	  addq		$r3, 1, $r3	# perform the ALU op
	  stq		$r3, -16($r15)	# spill i from $r3 to $r15-16
	# Goto __L4
	  br		__L4		# unconditional branch
__L5:
	# EndFunc
	# (below handles reaching end of fn body with no explicit return)
	  mov		$r15, $r30	# pop callee frame off stack
	  ldq		$r26, -8($r15)	# restore saved ra
	  ldq		$r15, 0($r15)	# restore saved fp
	  ret				# return from function
	# EndProgram
	#
	# (below is reserved for auto-appending of built-in functions)
	#
__Alloc:
	  ldq		$r16, 8($r30)	# fill arg0 to $r16 from $r30+8
	#
	# $r28 holds addr of heap-start
	# $r16 is the number of lines we want
	# $r1 holds the number of lines remaining to be allocated
	# $r2 holds the curent heap-table-entry
	# $r3 holds temp results of various comparisons
	# $r4 is used to generate various bit-masks
	# $r24 holds the current starting "bit-addr" in the heap-table
	# $r25 holds the bit-pos within the current heap-table-entry
	# $r27 holds the addr of the current heap-table-entry
	#
	  lda		$r4, 0x100
	  subq		$r28, $r4, $r27	# make addr of heap-table start
    __AllocFullReset:
	  mov		$r16, $r1	# reset goal amount
	  sll		$r27, 3, $r24	# reset bit-addr into heap-table
	  clr		$r25		# clear bit-pos marker
    __AllocSearchStart:
	  cmpult	$r27, $r28, $r3	# check if pass end of heap-table
	  blbc		$r3, __AllocReturnFail
	  ldq		$r2, 0($r27)	# dereference, to get current heap-table entry
	  cmpult	$r1, 64, $r3	# less than a page to allocate?
	  blbs		$r3, __AllocSearchStartLittle
	  blt		$r2, __AllocSearchStartSetup	# MSB set?
	  lda		$r4, -1		# for next code-block
    __AllocSearchStartShift:
	  and		$r2, $r4, $r3
	  beq		$r3, __AllocSearchStartDone
	  sll		$r4, 1, $r4
	  addq		$r24, 1, $r24
	  and		$r24, 63, $r25
	  bne		$r25, __AllocSearchStartShift
    __AllocSearchStartSetup:
	  srl		$r24, 6, $r27
	  sll		$r27, 3, $r27
	  br		__AllocSearchStart	# unconditional branch
    __AllocSearchStartLittle:
	  lda		$r4, 1
	  sll		$r4, $r1, $r4
	  subq		$r4, 1, $r4
	  br		__AllocSearchStartShift	# unconditional branch
    __AllocSearchStartDone:
	  subq		$r1, 64, $r1
	  addq		$r1, $r25, $r1
	  bgt		$r1, __AllocNotSimple
    __AllocSimpleCommit:
	  bis		$r2, $r4, $r2
	  stq		$r2, 0($r27)
	  br		__AllocReturnGood	# unconditional branch
    __AllocNotSimple:
	  srl		$r24, 6, $r27
	  sll		$r27, 3, $r27
    __AllocSearchBlock:
	  cmpult	$r1, 64, $r3
	  blbs		$r3, __AllocSearchEnd
	  addq		$r27, 8, $r27	# next heap-table entry
	  cmpult	$r27, $r28, $r3	# check if pass end of heap-table
	  blbc		$r3, __AllocReturnFail
	  ldq		$r2, 0($r27)	# dereference, to get current heap-table entry
	  bne		$r2, __AllocFullReset
	  subq		$r1, 64, $r1
	  br		__AllocSearchBlock	# unconditional branch
    __AllocSearchEnd:
	  beq		$r1,__AllocCommitStart
	  addq		$r27, 8, $r27	# next heap-table entry
	  cmpult	$r27, $r28, $r3	# check if pass end of heap-table
	  blbc		$r3, __AllocReturnFail
	  ldq		$r2, 0($r27)	# dereference, to get current heap-table entry
	  lda		$r4, 1
	  sll		$r4, $r1, $r4
	  subq		$r4, 1, $r4
	  and		$r2, $r4, $r3
	  bne		$r3, __AllocFullReset
    __AllocCommitEnd:
	  bis		$r2, $r4, $r2
	  stq		$r2, 0($r27)
	  subq		$r16, $r1, $r16
    __AllocCommitStart:
	  srl		$r24, 6, $r27
	  sll		$r27, 3, $r27
	  ldq		$r2, 0($r27)
	  lda		$r4, -1
	  sll		$r4, $r25, $r4
	  bis		$r2, $r4, $r2
	  stq		$r2, 0($r27)
	  subq		$r16, 64, $r16
	  addq		$r16, $r25, $r16
	  lda		$r4, -1		# for next code-block
    __AllocCommitBlock:
	  cmpult	$r16, 64, $r3
	  blbs		$r3, __AllocReturnCheck
	  addq		$r27, 8, $r27	# next heap-table entry
	  stq		$r4, 0($r27)	# set all bits in that entry
	  subq		$r16, 64, $r16
	  br		__AllocCommitBlock	# unconditional branch
    __AllocReturnCheck:
	  beq		$r16, __AllocReturnGood	# verify we are done
	  call_pal	0xDECAF		# (exception: this really should not happen in Malloc)
	  call_pal	0x555		# (halt)
    __AllocReturnGood:
	# magically compute address for return value
	  lda		$r0, 0x2F
	  sll		$r0, 13, $r0
	  subq		$r24, $r0, $r0
	  sll		$r0, 3, $r0
	  ret				# return to caller
    __AllocReturnFail:
	  call_pal	0xDECAF		# (exception: Malloc failed to find space in heap)
	  call_pal	0x555		# (halt)
	# EndFunc
