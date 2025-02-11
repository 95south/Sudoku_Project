#define STDOUT 0xd0580000

.section .text
.global _start
_start:
    
la s1, board
la s5, transposed

li s2, 64 #size
li s3, 1 #for boolean check

#jal convertToTranspose
jal solveBoard
j exit

solveBoard:

	addi sp, sp, -16
    sw a3, 12(sp)
    sw a2, 8(sp)
    sw a1, 4(sp)
    sw ra, 0(sp)
    jal saveTempRegisters
    
    #Intialize Vector Registers
	addi a4, zero, 32 
	vsetvli t0, a4, e8, m1
    
	li t0, 0
	CheckEmpty:
		bge t0, s2, solved
		
		mul t1, t0, s2
		add t1, s1, t1
		vle8.v v0, (t1)
		vmseq.vx v1, v0, zero
		vfirst.m t2, v1
		bgez t2, processEmpty
		
		addi t1, t1, 32
		vle8.v v0, (t1)
		vmseq.vx v1, v0, zero
		vfirst.m t2, v1
		bgez t2, processEmpty
		
		addi t0, t0, 1
	j CheckEmpty
	
	processEmpty:
	
		add a1, zero, t0
		add a2, zero, t2
		
		li a3, 1
		checkFill:
		
			bgt a3, s2, reject
			jal isSafe
			bne a0, s3, nope
			
			mul t4, a1, s2
			add t4, t4, a2
			add t4, t4, s1
			sb a3, 0(t4)
			
			mul t5, a2, s2
			add t5, t5, a1
			add t5, t5, s5
			sb a3, 0(t5)
			
			jal solveBoard
			
			beq a0, s3, solved
			
			sb zero, 0(t4)
			sb zero, 0(t5)
			
		nope:
			addi a3, a3, 1
			j checkFill
	reject:
        jal restoreTempRegisters
        lw ra, 0(sp)
        lw a1, 4(sp)
        lw a2, 8(sp)
        lw a3, 12(sp)
        addi sp, sp, 16
        li a0, 0
        jr ra
		
	solved:
        jal restoreTempRegisters
        lw ra, 0(sp)
        lw a1, 4(sp)
        lw a2, 8(sp)
        lw a3, 12(sp)
        addi sp, sp, 16
        li a0, 1
        jr ra			
	
	
	
	
isSafe:
    addi sp, sp, -8
    sw s4, 4(sp)
    sw ra, 0(sp)
    jal saveTempRegisters

    
    #Row check with vector registers
	mul t1, a1, s2
    add t1, s1, t1 
    vle8.v v2, (t1) 
    vmseq.vx v3, v2, a3
    vpopc.m t2, v3
    bnez t2, notSafe
    
    addi t1, t1, 32
    vle8.v v2, (t1) 
    vmseq.vx v3, v2, a3
    vpopc.m t2, v3
    bnez t2, notSafe
    
    #Col Check with vector registers
    mul t1, a2, s2 
    add t1, s5, t1 
    vle8.v v2, (t1) 
    vmseq.vx v3, v2, a3
    vpopc.m t2, v3
    bnez t2, notSafe
    
    addi t1, t1, 32
    vle8.v v2, (t1) 
    vmseq.vx v3, v2, a3
    vpopc.m t2, v3
    bnez t2, notSafe
    
 
    addi a4, zero, 8
    vsetvli t0, a4, e8, m1
    addi t1, zero, 8 
    
    rem t2, a1, t1 
    sub t2, a1, t2 
    addi t3, zero, 0
    
    rem t5, a2, t1
    sub t5, a2, t5
    
    boxCheckLoop:
    	bge t3, t1, safe
    	add t2, t2, t3
	    mul t2, s2, t2
	    add t2, t2, t5
	    add t2, s1, t2
	    vle8.v v4, (t2)
	    vmseq.vx v5, v4, a3
	    vpopc.m t4, v5
	    bnez t4, notSafe
	    addi t3, t3, 1
	    rem t2, a1, t1 
    	sub t2, a1, t2
	j boxCheckLoop	    
    
          
    notSafe:
        li a0, 0
        jal restoreTempRegisters
        lw ra, 0(sp)
        lw s4, 4(sp)
        addi sp, sp, 8
        jr ra
    safe:
        li a0, 1
        jal restoreTempRegisters
        lw ra, 0(sp)
        lw s4, 4(sp)
        addi sp, sp, 8
        jr ra

saveTempRegisters:
    addi sp, sp, -28
    sw t6, 24(sp)
    sw t5, 20(sp)
    sw t4, 16(sp)
    sw t3, 12(sp)
    sw t2, 8(sp)
    sw t1, 4(sp)
    sw t0, 0(sp)    
    jr ra

restoreTempRegisters:
    lw t0, 0(sp)
    lw t1, 4(sp)
    lw t2, 8(sp)
    lw t3, 12(sp)
    lw t4, 16(sp)
    lw t5, 20(sp)
    lw t6, 24(sp)
    addi sp, sp, 28
    jr ra
    
convertToTranspose:
      
		li t2, 0           # t2 = row index

	outer_loop:
	    beq t2, s2, end_outer_loop  # If t2 == size, exit the outer loop

	    li t3, 0           # t3 = column index

	inner_loop:
	    beq t3, s2, end_inner_loop  # If t3 == size, exit the inner loop

	    # Calculate source index: t2 * size + t3
	    mul t4, t2, s2     # t4 = t2 * size
	    add t4, t4, t3     # t4 = t4 + t3
	    add t4, s1, t4
	    
	    # Load byte from board[t4]
	    lb t5, 0(t4)       # t5 = board[t4]

	    # Calculate destination index: t3 * size + t2
	    mul t6, t3, s2     # t6 = t3 * size
	    add t6, t6, t2     # t6 = t6 + t2
	    add t6, s5, t6

	    # Store byte in transpose[t6]
	    sb t5, 0(t6)       # transpose[t6] = t5
	    
	    addi t3, t3, 1     # t3++
	    j inner_loop       # Repeat inner loop

	end_inner_loop:
	    addi t2, t2, 1     # t2++
	    j outer_loop       # Repeat outer loop

	end_outer_loop:
		jr ra    

exit:
	  addi t0, zero, 0
	  mul t1, s2, s2
	  
	  loop:
	  	beq t0, t1, exit2
	  	add t2, s1, t0
	  	lb t3, 0(t2)
	  	addi t0, t0, 1
	  	j loop
	  exit2:
	  
	  
	    
    # Finish section
    
_finish:
    li x3, 0xd0580000
    addi x5, x0, 0xff
    sb x5, 0(x3)
    beq x0, x0, _finish
.rept 100
    nop
.endr

.data
board: .byte 0,  0,  3,  4,  5,  6,  0,  8,  9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64,   9, 10, 11, 12, 13, 14, 15, 16,  1,  2,  3,  0,  5,  6,  7,  8, 25, 26, 27, 28, 29, 30, 31, 32, 17, 18, 19, 20, 21, 22, 23, 24, 41, 42, 43, 44, 45, 46, 47, 48, 33, 34, 35, 36, 37, 38, 39, 40, 57, 58, 59, 60, 61, 62, 63, 64, 49, 50, 51, 52, 53, 54, 55, 56,  17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14, 15, 16, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48,  25, 26, 27, 28, 29, 30, 31, 32, 17, 18, 19, 20, 21, 22, 23, 24,  9, 10, 11, 12, 13, 14, 15, 16,  1,  2,  3,  4,  5,  6,  7,  8, 57, 58, 59, 60, 61, 62, 63, 64, 49, 50, 51, 52, 53, 54, 55, 56, 41, 42, 43, 44, 45, 46, 47, 48, 33, 34, 35, 36, 37, 38, 39, 40,  33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32,  41, 42, 43, 44, 45, 46, 47, 48, 33, 34, 35, 36, 37, 38, 39, 40, 57, 58, 59, 60, 61, 62, 63, 64, 49, 50, 51, 52, 53, 54, 55, 56,  9, 10, 11, 12, 13, 14, 15, 16,  1,  2,  3,  4,  5,  6,  7,  8, 25, 26, 27, 28, 29, 30, 31, 32, 17, 18, 19, 20, 21, 22, 23, 24,  49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14, 15, 16,  57, 58, 59, 60, 61, 62, 63, 64, 49, 50, 51, 52, 53, 54, 55, 56, 41, 42, 43, 44, 45, 46, 47, 48, 33, 34, 35, 36, 37, 38, 39, 40, 25, 26, 27, 28, 29, 30, 31, 32, 17, 18, 19, 20, 21, 22, 23, 24,  9, 10, 11, 12, 13, 14, 15, 16,  1,  2,  3,  4,  5,  6,  7,  8,   2,  1,  4,  3,  6,  5,  8,  7, 10,  9, 12, 11, 14, 13, 16, 15, 18, 17, 20, 19, 22, 21, 24, 23, 26, 25, 28, 27, 30, 29, 32, 31, 34, 33, 36, 35, 38, 37, 40, 39, 42, 41, 44, 43, 46, 45, 48, 47, 50, 49, 52, 51, 54, 53, 56, 55, 58, 57, 60, 59, 62, 61, 64, 63,  10,  9, 12, 11, 14, 13, 16, 15,  2,  1,  4,  3,  6,  5,  8,  7, 26, 25, 28, 27, 30, 29, 32, 31, 18, 17, 20, 19, 22, 21, 24, 23, 42, 41, 44, 43, 46, 45, 48, 47, 34, 33, 36, 35, 38, 37, 40, 39, 58, 57, 60, 59, 62, 61, 64, 63, 50, 49, 52, 51, 54, 53, 56, 55,  18, 17, 20, 19, 22, 21, 24, 23, 26, 25, 28, 27, 30, 29, 32, 31,  2,  1,  4,  3,  6,  5,  8,  7, 10,  9, 12, 11, 14, 13, 16, 15, 50, 49, 52, 51, 54, 53, 56, 55, 58, 57, 60, 59, 62, 61, 64, 63, 34, 33, 36, 35, 38, 37, 40, 39, 42, 41, 44, 43, 46, 45, 48, 47,  26, 25, 28, 27, 30, 29, 32, 31, 18, 17, 20, 19, 22, 21, 24, 23, 10,  9, 12, 11, 14, 13, 16, 15,  2,  1,  4,  3,  6,  5,  8,  7, 58, 57, 60, 59, 62, 61, 64, 63, 50, 49, 52, 51, 54, 53, 56, 55, 42, 41, 44, 43, 46, 45, 48, 47, 34, 33, 36, 35, 38, 37, 40, 39,  34, 33, 36, 35, 38, 37, 40, 39, 42, 41, 44, 43, 46, 45, 48, 47, 50, 49, 52, 51, 54, 53, 56, 55, 58, 57, 60, 59, 62, 61, 64, 63,  2,  1,  4,  3,  6,  5,  8,  7, 10,  9, 12, 11, 14, 13, 16, 15, 18, 17, 20, 19, 22, 21, 24, 23, 26, 25, 28, 27, 30, 29, 32, 31,  42, 41, 44, 43, 46, 45, 48, 47, 34, 33, 36, 35, 38, 37, 40, 39, 58, 57, 60, 59, 62, 61, 64, 63, 50, 49, 52, 51, 54, 53, 56, 55, 10,  9, 12, 11, 14, 13, 16, 15,  2,  1,  4,  3,  6,  5,  8,  7, 26, 25, 28, 27, 30, 29, 32, 31, 18, 17, 20, 19, 22, 21, 24, 23,  50, 49, 52, 51, 54, 53, 56, 55, 58, 57, 60, 59, 62, 61, 64, 63, 34, 33, 36, 35, 38, 37, 40, 39, 42, 41, 44, 43, 46, 45, 48, 47, 18, 17, 20, 19, 22, 21, 24, 23, 26, 25, 28, 27, 30, 29, 32, 31,  2,  1,  4,  3,  6,  5,  8,  7, 10,  9, 12, 11, 14, 13, 16, 15,  58, 57, 60, 59, 62, 61, 64, 63, 50, 49, 52, 51, 54, 53, 56, 55, 42, 41, 44, 43, 46, 45, 48, 47, 34, 33, 36, 35, 38, 37, 40, 39, 26, 25, 28, 27, 30, 29, 32, 31, 18, 17, 20, 19, 22, 21, 24, 23, 10,  9, 12, 11, 14, 13, 16, 15,  2,  1,  4,  3,  6,  5,  8,  7,   3,  4,  1,  2,  7,  8,  5,  6, 11, 12,  9, 10, 15, 16, 13, 14, 19, 20, 17, 18, 23, 24, 21, 22, 27, 28, 25, 26, 31, 32, 29, 30, 35, 36, 33, 34, 39, 40, 37, 38, 43, 44, 41, 42, 47, 48, 45, 46, 51, 52, 49, 50, 55, 56, 53, 54, 59, 60, 57, 58, 63, 64, 61, 62,  11, 12,  9, 10, 15, 16, 13, 14,  3,  4,  1,  2,  7,  8,  5,  6, 27, 28, 25, 26, 31, 32, 29, 30, 19, 20, 17, 18, 23, 24, 21, 22, 43, 44, 41, 42, 47, 48, 45, 46, 35, 36, 33, 34, 39, 40, 37, 38, 59, 60, 57, 58, 63, 64, 61, 62, 51, 52, 49, 50, 55, 56, 53, 54,  19, 20, 17, 18, 23, 24, 21, 22, 27, 28, 25, 26, 31, 32, 29, 30,  3,  4,  1,  2,  7,  8,  5,  6, 11, 12,  9, 10, 15, 16, 13, 14, 51, 52, 49, 50, 55, 56, 53, 54, 59, 60, 57, 58, 63, 64, 61, 62, 35, 36, 33, 34, 39, 40, 37, 38, 43, 44, 41, 42, 47, 48, 45, 46,  27, 28, 25, 26, 31, 32, 29, 30, 19, 20, 17, 18, 23, 24, 21, 22, 11, 12,  9, 10, 15, 16, 13, 14,  3,  4,  1,  2,  7,  8,  5,  6, 59, 60, 57, 58, 63, 64, 61, 62, 51, 52, 49, 50, 55, 56, 53, 54, 43, 44, 41, 42, 47, 48, 45, 46, 35, 36, 33, 34, 39, 40, 37, 38,  35, 36, 33, 34, 39, 40, 37, 38, 43, 44, 41, 42, 47, 48, 45, 46, 51, 52, 49, 50, 55, 56, 53, 54, 59, 60, 57, 58, 63, 64, 61, 62,  3,  4,  1,  2,  7,  8,  5,  6, 11, 12,  9, 10, 15, 16, 13, 14, 19, 20, 17, 18, 23, 24, 21, 22, 27, 28, 25, 26, 31, 32, 29, 30,  43, 44, 41, 42, 47, 48, 45, 46, 35, 36, 33, 34, 39, 40, 37, 38, 59, 60, 57, 58, 63, 64, 61, 62, 51, 52, 49, 50, 55, 56, 53, 54, 11, 12,  9, 10, 15, 16, 13, 14,  3,  4,  1,  2,  7,  8,  5,  6, 27, 28, 25, 26, 31, 32, 29, 30, 19, 20, 17, 18, 23, 24, 21, 22,  51, 52, 49, 50, 55, 56, 53, 54, 59, 60, 57, 58, 63, 64, 61, 62, 35, 36, 33, 34, 39, 40, 37, 38, 43, 44, 41, 42, 47, 48, 45, 46, 19, 20, 17, 18, 23, 24, 21, 22, 27, 28, 25, 26, 31, 32, 29, 30,  3,  4,  1,  2,  7,  8,  5,  6, 11, 12,  9, 10, 15, 16, 13, 14,  59, 60, 57, 58, 63, 64, 61, 62, 51, 52, 49, 50, 55, 56, 53, 54, 43, 44, 41, 42, 47, 48, 45, 46, 35, 36, 33, 34, 39, 40, 37, 38, 27, 28, 25, 26, 31, 32, 29, 30, 19, 20, 17, 18, 23, 24, 21, 22, 11, 12,  9, 10, 15, 16, 13, 14,  3,  4,  1,  2,  7,  8,  5,  6,   4,  3,  2,  1,  8,  7,  6,  5, 12, 11, 10,  9, 16, 15, 14, 13, 20, 19, 18, 17, 24, 23, 22, 21, 28, 27, 26, 25, 32, 31, 30, 29, 36, 35, 34, 33, 40, 39, 38, 37, 44, 43, 42, 41, 48, 47, 46, 45, 52, 51, 50, 49, 56, 55, 54, 53, 60, 59, 58, 57, 64, 63, 62, 61,  12, 11, 10,  9, 16, 15, 14, 13,  4,  3,  2,  1,  8,  7,  6,  5, 28, 27, 26, 25, 32, 31, 30, 29, 20, 19, 18, 17, 24, 23, 22, 21, 44, 43, 42, 41, 48, 47, 46, 45, 36, 35, 34, 33, 40, 39, 38, 37, 60, 59, 58, 57, 64, 63, 62, 61, 52, 51, 50, 49, 56, 55, 54, 53,  20, 19, 18, 17, 24, 23, 22, 21, 28, 27, 26, 25, 32, 31, 30, 29,  4,  3,  2,  1,  8,  7,  6,  5, 12, 11, 10,  9, 16, 15, 14, 13, 52, 51, 50, 49, 56, 55, 54, 53, 60, 59, 58, 57, 64, 63, 62, 61, 36, 35, 34, 33, 40, 39, 38, 37, 44, 43, 42, 41, 48, 47, 46, 45,  28, 27, 26, 25, 32, 31, 30, 29, 20, 19, 18, 17, 24, 23, 22, 21, 12, 11, 10,  9, 16, 15, 14, 13,  4,  3,  2,  1,  8,  7,  6,  5, 60, 59, 58, 57, 64, 63, 62, 61, 52, 51, 50, 49, 56, 55, 54, 53, 44, 43, 42, 41, 48, 47, 46, 45, 36, 35, 34, 33, 40, 39, 38, 37,  36, 35, 34, 33, 40, 39, 38, 37, 44, 43, 42, 41, 48, 47, 46, 45, 52, 51, 50, 49, 56, 55, 54, 53, 60, 59, 58, 57, 64, 63, 62, 61,  4,  3,  2,  1,  8,  7,  6,  5, 12, 11, 10,  9, 16, 15, 14, 13, 20, 19, 18, 17, 24, 23, 22, 21, 28, 27, 26, 25, 32, 31, 30, 29,  44, 43, 42, 41, 48, 47, 46, 45, 36, 35, 34, 33, 40, 39, 38, 37, 60, 59, 58, 57, 64, 63, 62, 61, 52, 51, 50, 49, 56, 55, 54, 53, 12, 11, 10,  9, 16, 15, 14, 13,  4,  3,  2,  1,  8,  7,  6,  5, 28, 27, 26, 25, 32, 31, 30, 29, 20, 19, 18, 17, 24, 23, 22, 21,  52, 51, 50, 49, 56, 55, 54, 53, 60, 59, 58, 57, 64, 63, 62, 61, 36, 35, 34, 33, 40, 39, 38, 37, 44, 43, 42, 41, 48, 47, 46, 45, 20, 19, 18, 17, 24, 23, 22, 21, 28, 27, 26, 25, 32, 31, 30, 29,  4,  3,  2,  1,  8,  7,  6,  5, 12, 11, 10,  9, 16, 15, 14, 13,  60, 59, 58, 57, 64, 63, 62, 61, 52, 51, 50, 49, 56, 55, 54, 53, 44, 43, 42, 41, 48, 47, 46, 45, 36, 35, 34, 33, 40, 39, 38, 37, 28, 27, 26, 25, 32, 31, 30, 29, 20, 19, 18, 17, 24, 23, 22, 21, 12, 11, 10,  9, 16, 15, 14, 13,  4,  3,  2,  1,  8,  7,  6,  5,   5,  6,  7,  8,  1,  2,  3,  4, 13, 14, 15, 16,  9, 10, 11, 12, 21, 22, 23, 24, 17, 18, 19, 20, 29, 30, 31, 32, 25, 26, 27, 28, 37, 38, 39, 40, 33, 34, 35, 36, 45, 46, 47, 48, 41, 42, 43, 44, 53, 54, 55, 56, 49, 50, 51, 52, 61, 62, 63, 64, 57, 58, 59, 60,  13, 14, 15, 16,  9, 10, 11, 12,  5,  6,  7,  8,  1,  2,  3,  4, 29, 30, 31, 32, 25, 26, 27, 28, 21, 22, 23, 24, 17, 18, 19, 20, 45, 46, 47, 48, 41, 42, 43, 44, 37, 38, 39, 40, 33, 34, 35, 36, 61, 62, 63, 64, 57, 58, 59, 60, 53, 54, 55, 56, 49, 50, 51, 52,  21, 22, 23, 24, 17, 18, 19, 20, 29, 30, 31, 32, 25, 26, 27, 28,  5,  6,  7,  8,  1,  2,  3,  4, 13, 14, 15, 16,  9, 10, 11, 12, 53, 54, 55, 56, 49, 50, 51, 52, 61, 62, 63, 64, 57, 58, 59, 60, 37, 38, 39, 40, 33, 34, 35, 36, 45, 46, 47, 48, 41, 42, 43, 44,  29, 30, 31, 32, 25, 26, 27, 28, 21, 22, 23, 24, 17, 18, 19, 20, 13, 14, 15, 16,  9, 10, 11, 12,  5,  6,  7,  8,  1,  2,  3,  4, 61, 62, 63, 64, 57, 58, 59, 60, 53, 54, 55, 56, 49, 50, 51, 52, 45, 46, 47, 48, 41, 42, 43, 44, 37, 38, 39, 40, 33, 34, 35, 36,  37, 38, 39, 40, 33, 34, 35, 36, 45, 46, 47, 48, 41, 42, 43, 44, 53, 54, 55, 56, 49, 50, 51, 52, 61, 62, 63, 64, 57, 58, 59, 60,  5,  6,  7,  8,  1,  2,  3,  4, 13, 14, 15, 16,  9, 10, 11, 12, 21, 22, 23, 24, 17, 18, 19, 20, 29, 30, 31, 32, 25, 26, 27, 28,  45, 46, 47, 48, 41, 42, 43, 44, 37, 38, 39, 40, 33, 34, 35, 36, 61, 62, 63, 64, 57, 58, 59, 60, 53, 54, 55, 56, 49, 50, 51, 52, 13, 14, 15, 16,  9, 10, 11, 12,  5,  6,  7,  8,  1,  2,  3,  4, 29, 30, 31, 32, 25, 26, 27, 28, 21, 22, 23, 24, 17, 18, 19, 20,  53, 54, 55, 56, 49, 50, 51, 52, 61, 62, 63, 64, 57, 58, 59, 60, 37, 38, 39, 40, 33, 34, 35, 36, 45, 46, 47, 48, 41, 42, 43, 44, 21, 22, 23, 24, 17, 18, 19, 20, 29, 30, 31, 32, 25, 26, 27, 28,  5,  6,  7,  8,  1,  2,  3,  4, 13, 14, 15, 16,  9, 10, 11, 12,  61, 62, 63, 64, 57, 58, 59, 60, 53, 54, 55, 56, 49, 50, 51, 52, 45, 46, 47, 48, 41, 42, 43, 44, 37, 38, 39, 40, 33, 34, 35, 36, 29, 30, 31, 32, 25, 26, 27, 28, 21, 22, 23, 24, 17, 18, 19, 20, 13, 14, 15, 16,  9, 10, 11, 12,  5,  6,  7,  8,  1,  2,  3,  4,   6,  5,  8,  7,  2,  1,  4,  3, 14, 13, 16, 15, 10,  9, 12, 11, 22, 21, 24, 23, 18, 17, 20, 19, 30, 29, 32, 31, 26, 25, 28, 27, 38, 37, 40, 39, 34, 33, 36, 35, 46, 45, 48, 47, 42, 41, 44, 43, 54, 53, 56, 55, 50, 49, 52, 51, 62, 61, 64, 63, 58, 57, 60, 59,  14, 13, 16, 15, 10,  9, 12, 11,  6,  5,  8,  7,  2,  1,  4,  3, 30, 29, 32, 31, 26, 25, 28, 27, 22, 21, 24, 23, 18, 17, 20, 19, 46, 45, 48, 47, 42, 41, 44, 43, 38, 37, 40, 39, 34, 33, 36, 35, 62, 61, 64, 63, 58, 57, 60, 59, 54, 53, 56, 55, 50, 49, 52, 51,  22, 21, 24, 23, 18, 17, 20, 19, 30, 29, 32, 31, 26, 25, 28, 27,  6,  5,  8,  7,  2,  1,  4,  3, 14, 13, 16, 15, 10,  9, 12, 11, 54, 53, 56, 55, 50, 49, 52, 51, 62, 61, 64, 63, 58, 57, 60, 59, 38, 37, 40, 39, 34, 33, 36, 35, 46, 45, 48, 47, 42, 41, 44, 43,  30, 29, 32, 31, 26, 25, 28, 27, 22, 21, 24, 23, 18, 17, 20, 19, 14, 13, 16, 15, 10,  9, 12, 11,  6,  5,  8,  7,  2,  1,  4,  3, 62, 61, 64, 63, 58, 57, 60, 59, 54, 53, 56, 55, 50, 49, 52, 51, 46, 45, 48, 47, 42, 41, 44, 43, 38, 37, 40, 39, 34, 33, 36, 35,  38, 37, 40, 39, 34, 33, 36, 35, 46, 45, 48, 47, 42, 41, 44, 43, 54, 53, 56, 55, 50, 49, 52, 51, 62, 61, 64, 63, 58, 57, 60, 59,  6,  5,  8,  7,  2,  1,  4,  3, 14, 13, 16, 15, 10,  9, 12, 11, 22, 21, 24, 23, 18, 17, 20, 19, 30, 29, 32, 31, 26, 25, 28, 27,  46, 45, 48, 47, 42, 41, 44, 43, 38, 37, 40, 39, 34, 33, 36, 35, 62, 61, 64, 63, 58, 57, 60, 59, 54, 53, 56, 55, 50, 49, 52, 51, 14, 13, 16, 15, 10,  9, 12, 11,  6,  5,  8,  7,  2,  1,  4,  3, 30, 29, 32, 31, 26, 25, 28, 27, 22, 21, 24, 23, 18, 17, 20, 19,  54, 53, 56, 55, 50, 49, 52, 51, 62, 61, 64, 63, 58, 57, 60, 59, 38, 37, 40, 39, 34, 33, 36, 35, 46, 45, 48, 47, 42, 41, 44, 43, 22, 21, 24, 23, 18, 17, 20, 19, 30, 29, 32, 31, 26, 25, 28, 27,  6,  5,  8,  7,  2,  1,  4,  3, 14, 13, 16, 15, 10,  9, 12, 11,  62, 61, 64, 63, 58, 57, 60, 59, 54, 53, 56, 55, 50, 49, 52, 51, 46, 45, 48, 47, 42, 41, 44, 43, 38, 37, 40, 39, 34, 33, 36, 35, 30, 29, 32, 31, 26, 25, 28, 27, 22, 21, 24, 23, 18, 17, 20, 19, 14, 13, 16, 15, 10,  9, 12, 11,  6,  5,  8,  7,  2,  1,  4,  3,   7,  8,  5,  6,  3,  4,  1,  2, 15, 16, 13, 14, 11, 12,  9, 10, 23, 24, 21, 22, 19, 20, 17, 18, 31, 32, 29, 30, 27, 28, 25, 26, 39, 40, 37, 38, 35, 36, 33, 34, 47, 48, 45, 46, 43, 44, 41, 42, 55, 56, 53, 54, 51, 52, 49, 50, 63, 64, 61, 62, 59, 60, 57, 58,  15, 16, 13, 14, 11, 12,  9, 10,  7,  8,  5,  6,  3,  4,  1,  2, 31, 32, 29, 30, 27, 28, 25, 26, 23, 24, 21, 22, 19, 20, 17, 18, 47, 48, 45, 46, 43, 44, 41, 42, 39, 40, 37, 38, 35, 36, 33, 34, 63, 64, 61, 62, 59, 60, 57, 58, 55, 56, 53, 54, 51, 52, 49, 50,  23, 24, 21, 22, 19, 20, 17, 18, 31, 32, 29, 30, 27, 28, 25, 26,  7,  8,  5,  6,  3,  4,  1,  2, 15, 16, 13, 14, 11, 12,  9, 10, 55, 56, 53, 54, 51, 52, 49, 50, 63, 64, 61, 62, 59, 60, 57, 58, 39, 40, 37, 38, 35, 36, 33, 34, 47, 48, 45, 46, 43, 44, 41, 42,  31, 32, 29, 30, 27, 28, 25, 26, 23, 24, 21, 22, 19, 20, 17, 18, 15, 16, 13, 14, 11, 12,  9, 10,  7,  8,  5,  6,  3,  4,  1,  2, 63, 64, 61, 62, 59, 60, 57, 58, 55, 56, 53, 54, 51, 52, 49, 50, 47, 48, 45, 46, 43, 44, 41, 42, 39, 40, 37, 38, 35, 36, 33, 34,  39, 40, 37, 38, 35, 36, 33, 34, 47, 48, 45, 46, 43, 44, 41, 42, 55, 56, 53, 54, 51, 52, 49, 50, 63, 64, 61, 62, 59, 60, 57, 58,  7,  8,  5,  6,  3,  4,  1,  2, 15, 16, 13, 14, 11, 12,  9, 10, 23, 24, 21, 22, 19, 20, 17, 18, 31, 32, 29, 30, 27, 28, 25, 26,  47, 48, 45, 46, 43, 44, 41, 42, 39, 40, 37, 38, 35, 36, 33, 34, 63, 64, 61, 62, 59, 60, 57, 58, 55, 56, 53, 54, 51, 52, 49, 50, 15, 16, 13, 14, 11, 12,  9, 10,  7,  8,  5,  6,  3,  4,  1,  2, 31, 32, 29, 30, 27, 28, 25, 26, 23, 24, 21, 22, 19, 20, 17, 18,  55, 56, 53, 54, 51, 52, 49, 50, 63, 64, 61, 62, 59, 60, 57, 58, 39, 40, 37, 38, 35, 36, 33, 34, 47, 48, 45, 46, 43, 44, 41, 42, 23, 24, 21, 22, 19, 20, 17, 18, 31, 32, 29, 30, 27, 28, 25, 26,  7,  8,  5,  6,  3,  4,  1,  2, 15, 16, 13, 14, 11, 12,  9, 10,  63, 64, 61, 62, 59, 60, 57, 58, 55, 56, 53, 54, 51, 52, 49, 50, 47, 48, 45, 46, 43, 44, 41, 42, 39, 40, 37, 38, 35, 36, 33, 34, 31, 32, 29, 30, 27, 28, 25, 26, 23, 24, 21, 22, 19, 20, 17, 18, 15, 16, 13, 14, 11, 12,  9, 10,  7,  8,  5,  6,  3,  4,  1,  2,   8,  7,  6,  5,  4,  3,  2,  1, 16, 15, 14, 13, 12, 11, 10,  9, 24, 23, 22, 21, 20, 19, 18, 17, 32, 31, 30, 29, 28, 27, 26, 25, 40, 39, 38, 37, 36, 35, 34, 33, 48, 47, 46, 45, 44, 43, 42, 41, 56, 55, 54, 53, 52, 51, 50, 49, 64, 63, 62, 61, 60, 59, 58, 57,  16, 15, 14, 13, 12, 11, 10,  9,  8,  7,  6,  5,  4,  3,  2,  1, 32, 31, 30, 29, 28, 27, 26, 25, 24, 23, 22, 21, 20, 19, 18, 17, 48, 47, 46, 45, 44, 43, 42, 41, 40, 39, 38, 37, 36, 35, 34, 33, 64, 63, 62, 61, 60, 59, 58, 57, 56, 55, 54, 53, 52, 51, 50, 49,  24, 23, 22, 21, 20, 19, 18, 17, 32, 31, 30, 29, 28, 27, 26, 25,  8,  7,  6,  5,  4,  3,  2,  1, 16, 15, 14, 13, 12, 11, 10,  9, 56, 55, 54, 53, 52, 51, 50, 49, 64, 63, 62, 61, 60, 59, 58, 57, 40, 39, 38, 37, 36, 35, 34, 33, 48, 47, 46, 45, 44, 43, 42, 41,  32, 31, 30, 29, 28, 27, 26, 25, 24, 23, 22, 21, 20, 19, 18, 17, 16, 15, 14, 13, 12, 11, 10,  9,  8,  7,  6,  5,  4,  3,  2,  1, 64, 63, 62, 61, 60, 59, 58, 57, 56, 55, 54, 53, 52, 51, 50, 49, 48, 47, 46, 45, 44, 43, 42, 41, 40, 39, 38, 37, 36, 35, 34, 33,  40, 39, 38, 37, 36, 35, 34, 33, 48, 47, 46, 45, 44, 43, 42, 41, 56, 55, 54, 53, 52, 51, 50, 49, 64, 63, 62, 61, 60, 59, 58, 57,  8,  7,  6,  5,  4,  3,  2,  1, 16, 15, 14, 13, 12, 11, 10,  9, 24, 23, 22, 21, 20, 19, 18, 17, 32, 31, 30, 29, 28, 27, 26, 25,  48, 47, 46, 45, 44, 43, 42, 41, 40, 39, 38, 37, 36, 35, 34, 33, 64, 63, 62, 61, 60, 59, 58, 57, 56, 55, 54, 53, 52, 51, 50, 49, 16, 15, 14, 13, 12, 11, 10,  9,  8,  7,  6,  5,  4,  3,  2,  1, 32, 31, 30, 29, 28, 27, 26, 25, 24, 23, 22, 21, 20, 19, 18, 17,  56, 55, 54, 53, 52, 51, 50, 49, 64, 63, 62, 61, 60, 59, 58, 57, 40, 39, 38, 37, 36, 35, 34, 33, 48, 47, 46, 45, 44, 43, 42, 41, 24, 23, 22, 21, 20, 19, 18, 17, 32, 31, 30, 29, 28, 27, 26, 25,  8,  7,  6,  5,  4,  3,  2,  1, 16, 15, 14, 13, 12, 11, 10,  9,  64, 63, 62, 61, 60, 59, 58, 57, 56, 55, 54, 53, 52, 51, 50, 49, 48, 47, 46, 45, 44, 43, 42, 41, 40, 39, 38, 37, 36, 35, 34, 33, 32, 31, 30, 29, 28, 27, 26, 25, 24, 23, 22, 21, 20, 19, 18, 17, 16, 15, 14, 13, 12, 11, 10,  9,  8,  7,  6,  5,  4,  3,  2,  1
transposed: .byte 0, 9, 17, 25, 33, 41, 49, 57, 2, 10, 18, 26, 34, 42, 50, 58, 3, 11, 19, 27, 35, 43, 51, 59, 4, 12, 20, 28, 36, 44, 52, 60, 5, 13, 21, 29, 37, 45, 53, 61, 6, 14, 22, 30, 38, 46, 54, 62, 7, 15, 23, 31, 39, 47, 55, 63, 8, 16, 24, 32, 40, 48, 56, 64, 0, 10, 18, 26, 34, 42, 50, 58, 1, 9, 17, 25, 33, 41, 49, 57, 4, 12, 20, 28, 36, 44, 52, 60, 3, 11, 19, 27, 35, 43, 51, 59, 6, 14, 22, 30, 38, 46, 54, 62, 5, 13, 21, 29, 37, 45, 53, 61, 8, 16, 24, 32, 40, 48, 56, 64, 7, 15, 23, 31, 39, 47, 55, 63, 3, 11, 19, 27, 35, 43, 51, 59, 4, 12, 20, 28, 36, 44, 52, 60, 1, 9, 17, 25, 33, 41, 49, 57, 2, 10, 18, 26, 34, 42, 50, 58, 7, 15, 23, 31, 39, 47, 55, 63, 8, 16, 24, 32, 40, 48, 56, 64, 5, 13, 21, 29, 37, 45, 53, 61, 6, 14, 22, 30, 38, 46, 54, 62, 4, 12, 20, 28, 36, 44, 52, 60, 3, 11, 19, 27, 35, 43, 51, 59, 2, 10, 18, 26, 34, 42, 50, 58, 1, 9, 17, 25, 33, 41, 49, 57, 8, 16, 24, 32, 40, 48, 56, 64, 7, 15, 23, 31, 39, 47, 55, 63, 6, 14, 22, 30, 38, 46, 54, 62, 5, 13, 21, 29, 37, 45, 53, 61, 5, 13, 21, 29, 37, 45, 53, 61, 6, 14, 22, 30, 38, 46, 54, 62, 7, 15, 23, 31, 39, 47, 55, 63, 8, 16, 24, 32, 40, 48, 56, 64, 1, 9, 17, 25, 33, 41, 49, 57, 2, 10, 18, 26, 34, 42, 50, 58, 3, 11, 19, 27, 35, 43, 51, 59, 4, 12, 20, 28, 36, 44, 52, 60, 6, 14, 22, 30, 38, 46, 54, 62, 5, 13, 21, 29, 37, 45, 53, 61, 8, 16, 24, 32, 40, 48, 56, 64, 7, 15, 23, 31, 39, 47, 55, 63, 2, 10, 18, 26, 34, 42, 50, 58, 1, 9, 17, 25, 33, 41, 49, 57, 4, 12, 20, 28, 36, 44, 52, 60, 3, 11, 19, 27, 35, 43, 51, 59, 0, 15, 23, 31, 39, 47, 55, 63, 8, 16, 24, 32, 40, 48, 56, 64, 5, 13, 21, 29, 37, 45, 53, 61, 6, 14, 22, 30, 38, 46, 54, 62, 3, 11, 19, 27, 35, 43, 51, 59, 4, 12, 20, 28, 36, 44, 52, 60, 1, 9, 17, 25, 33, 41, 49, 57, 2, 10, 18, 26, 34, 42, 50, 58, 8, 16, 24, 32, 40, 48, 56, 64, 7, 15, 23, 31, 39, 47, 55, 63, 6, 14, 22, 30, 38, 46, 54, 62, 5, 13, 21, 29, 37, 45, 53, 61, 4, 12, 20, 28, 36, 44, 52, 60, 3, 11, 19, 27, 35, 43, 51, 59, 2, 10, 18, 26, 34, 42, 50, 58, 1, 9, 17, 25, 33, 41, 49, 57, 9, 1, 25, 17, 41, 33, 57, 49, 10, 2, 26, 18, 42, 34, 58, 50, 11, 3, 27, 19, 43, 35, 59, 51, 12, 4, 28, 20, 44, 36, 60, 52, 13, 5, 29, 21, 45, 37, 61, 53, 14, 6, 30, 22, 46, 38, 62, 54, 15, 7, 31, 23, 47, 39, 63, 55, 16, 8, 32, 24, 48, 40, 64, 56, 10, 2, 26, 18, 42, 34, 58, 50, 9, 1, 25, 17, 41, 33, 57, 49, 12, 4, 28, 20, 44, 36, 60, 52, 11, 3, 27, 19, 43, 35, 59, 51, 14, 6, 30, 22, 46, 38, 62, 54, 13, 5, 29, 21, 45, 37, 61, 53, 16, 8, 32, 24, 48, 40, 64, 56, 15, 7, 31, 23, 47, 39, 63, 55, 11, 3, 27, 19, 43, 35, 59, 51, 12, 4, 28, 20, 44, 36, 60, 52, 9, 1, 25, 17, 41, 33, 57, 49, 10, 2, 26, 18, 42, 34, 58, 50, 15, 7, 31, 23, 47, 39, 63, 55, 16, 8, 32, 24, 48, 40, 64, 56, 13, 5, 29, 21, 45, 37, 61, 53, 14, 6, 30, 22, 46, 38, 62, 54, 12, 0, 28, 20, 44, 36, 60, 52, 11, 3, 27, 19, 43, 35, 59, 51, 10, 2, 26, 18, 42, 34, 58, 50, 9, 1, 25, 17, 41, 33, 57, 49, 16, 8, 32, 24, 48, 40, 64, 56, 15, 7, 31, 23, 47, 39, 63, 55, 14, 6, 30, 22, 46, 38, 62, 54, 13, 5, 29, 21, 45, 37, 61, 53, 13, 5, 29, 21, 45, 37, 61, 53, 14, 6, 30, 22, 46, 38, 62, 54, 15, 7, 31, 23, 47, 39, 63, 55, 16, 8, 32, 24, 48, 40, 64, 56, 9, 1, 25, 17, 41, 33, 57, 49, 10, 2, 26, 18, 42, 34, 58, 50, 11, 3, 27, 19, 43, 35, 59, 51, 12, 4, 28, 20, 44, 36, 60, 52, 14, 6, 30, 22, 46, 38, 62, 54, 13, 5, 29, 21, 45, 37, 61, 53, 16, 8, 32, 24, 48, 40, 64, 56, 15, 7, 31, 23, 47, 39, 63, 55, 10, 2, 26, 18, 42, 34, 58, 50, 9, 1, 25, 17, 41, 33, 57, 49, 12, 4, 28, 20, 44, 36, 60, 52, 11, 3, 27, 19, 43, 35, 59, 51, 15, 7, 31, 23, 47, 39, 63, 55, 16, 8, 32, 24, 48, 40, 64, 56, 13, 5, 29, 21, 45, 37, 61, 53, 14, 6, 30, 22, 46, 38, 62, 54, 11, 3, 27, 19, 43, 35, 59, 51, 12, 4, 28, 20, 44, 36, 60, 52, 9, 1, 25, 17, 41, 33, 57, 49, 10, 2, 26, 18, 42, 34, 58, 50, 16, 8, 32, 24, 48, 40, 64, 56, 15, 7, 31, 23, 47, 39, 63, 55, 14, 6, 30, 22, 46, 38, 62, 54, 13, 5, 29, 21, 45, 37, 61, 53, 12, 4, 28, 20, 44, 36, 60, 52, 11, 3, 27, 19, 43, 35, 59, 51, 10, 2, 26, 18, 42, 34, 58, 50, 9, 1, 25, 17, 41, 33, 57, 49, 17, 25, 1, 9, 49, 57, 33, 41, 18, 26, 2, 10, 50, 58, 34, 42, 19, 27, 3, 11, 51, 59, 35, 43, 20, 28, 4, 12, 52, 60, 36, 44, 21, 29, 5, 13, 53, 61, 37, 45, 22, 30, 6, 14, 54, 62, 38, 46, 23, 31, 7, 15, 55, 63, 39, 47, 24, 32, 8, 16, 56, 64, 40, 48, 18, 26, 2, 10, 50, 58, 34, 42, 17, 25, 1, 9, 49, 57, 33, 41, 20, 28, 4, 12, 52, 60, 36, 44, 19, 27, 3, 11, 51, 59, 35, 43, 22, 30, 6, 14, 54, 62, 38, 46, 21, 29, 5, 13, 53, 61, 37, 45, 24, 32, 8, 16, 56, 64, 40, 48, 23, 31, 7, 15, 55, 63, 39, 47, 19, 27, 3, 11, 51, 59, 35, 43, 20, 28, 4, 12, 52, 60, 36, 44, 17, 25, 1, 9, 49, 57, 33, 41, 18, 26, 2, 10, 50, 58, 34, 42, 23, 31, 7, 15, 55, 63, 39, 47, 24, 32, 8, 16, 56, 64, 40, 48, 21, 29, 5, 13, 53, 61, 37, 45, 22, 30, 6, 14, 54, 62, 38, 46, 20, 28, 4, 12, 52, 60, 36, 44, 19, 27, 3, 11, 51, 59, 35, 43, 18, 26, 2, 10, 50, 58, 34, 42, 17, 25, 1, 9, 49, 57, 33, 41, 24, 32, 8, 16, 56, 64, 40, 48, 23, 31, 7, 15, 55, 63, 39, 47, 22, 30, 6, 14, 54, 62, 38, 46, 21, 29, 5, 13, 53, 61, 37, 45, 21, 29, 5, 13, 53, 61, 37, 45, 22, 30, 6, 14, 54, 62, 38, 46, 23, 31, 7, 15, 55, 63, 39, 47, 24, 32, 8, 16, 56, 64, 40, 48, 17, 25, 1, 9, 49, 57, 33, 41, 18, 26, 2, 10, 50, 58, 34, 42, 19, 27, 3, 11, 51, 59, 35, 43, 20, 28, 4, 12, 52, 60, 36, 44, 22, 30, 6, 14, 54, 62, 38, 46, 21, 29, 5, 13, 53, 61, 37, 45, 24, 32, 8, 16, 56, 64, 40, 48, 23, 31, 7, 15, 55, 63, 39, 47, 18, 26, 2, 10, 50, 58, 34, 42, 17, 25, 1, 9, 49, 57, 33, 41, 20, 28, 4, 12, 52, 60, 36, 44, 19, 27, 3, 11, 51, 59, 35, 43, 23, 31, 7, 15, 55, 63, 39, 47, 24, 32, 8, 16, 56, 64, 40, 48, 21, 29, 5, 13, 53, 61, 37, 45, 22, 30, 6, 14, 54, 62, 38, 46, 19, 27, 3, 11, 51, 59, 35, 43, 20, 28, 4, 12, 52, 60, 36, 44, 17, 25, 1, 9, 49, 57, 33, 41, 18, 26, 2, 10, 50, 58, 34, 42, 24, 32, 8, 16, 56, 64, 40, 48, 23, 31, 7, 15, 55, 63, 39, 47, 22, 30, 6, 14, 54, 62, 38, 46, 21, 29, 5, 13, 53, 61, 37, 45, 20, 28, 4, 12, 52, 60, 36, 44, 19, 27, 3, 11, 51, 59, 35, 43, 18, 26, 2, 10, 50, 58, 34, 42, 17, 25, 1, 9, 49, 57, 33, 41, 25, 17, 9, 1, 57, 49, 41, 33, 26, 18, 10, 2, 58, 50, 42, 34, 27, 19, 11, 3, 59, 51, 43, 35, 28, 20, 12, 4, 60, 52, 44, 36, 29, 21, 13, 5, 61, 53, 45, 37, 30, 22, 14, 6, 62, 54, 46, 38, 31, 23, 15, 7, 63, 55, 47, 39, 32, 24, 16, 8, 64, 56, 48, 40, 26, 18, 10, 2, 58, 50, 42, 34, 25, 17, 9, 1, 57, 49, 41, 33, 28, 20, 12, 4, 60, 52, 44, 36, 27, 19, 11, 3, 59, 51, 43, 35, 30, 22, 14, 6, 62, 54, 46, 38, 29, 21, 13, 5, 61, 53, 45, 37, 32, 24, 16, 8, 64, 56, 48, 40, 31, 23, 15, 7, 63, 55, 47, 39, 27, 19, 11, 3, 59, 51, 43, 35, 28, 20, 12, 4, 60, 52, 44, 36, 25, 17, 9, 1, 57, 49, 41, 33, 26, 18, 10, 2, 58, 50, 42, 34, 31, 23, 15, 7, 63, 55, 47, 39, 32, 24, 16, 8, 64, 56, 48, 40, 29, 21, 13, 5, 61, 53, 45, 37, 30, 22, 14, 6, 62, 54, 46, 38, 28, 20, 12, 4, 60, 52, 44, 36, 27, 19, 11, 3, 59, 51, 43, 35, 26, 18, 10, 2, 58, 50, 42, 34, 25, 17, 9, 1, 57, 49, 41, 33, 32, 24, 16, 8, 64, 56, 48, 40, 31, 23, 15, 7, 63, 55, 47, 39, 30, 22, 14, 6, 62, 54, 46, 38, 29, 21, 13, 5, 61, 53, 45, 37, 29, 21, 13, 5, 61, 53, 45, 37, 30, 22, 14, 6, 62, 54, 46, 38, 31, 23, 15, 7, 63, 55, 47, 39, 32, 24, 16, 8, 64, 56, 48, 40, 25, 17, 9, 1, 57, 49, 41, 33, 26, 18, 10, 2, 58, 50, 42, 34, 27, 19, 11, 3, 59, 51, 43, 35, 28, 20, 12, 4, 60, 52, 44, 36, 30, 22, 14, 6, 62, 54, 46, 38, 29, 21, 13, 5, 61, 53, 45, 37, 32, 24, 16, 8, 64, 56, 48, 40, 31, 23, 15, 7, 63, 55, 47, 39, 26, 18, 10, 2, 58, 50, 42, 34, 25, 17, 9, 1, 57, 49, 41, 33, 28, 20, 12, 4, 60, 52, 44, 36, 27, 19, 11, 3, 59, 51, 43, 35, 31, 23, 15, 7, 63, 55, 47, 39, 32, 24, 16, 8, 64, 56, 48, 40, 29, 21, 13, 5, 61, 53, 45, 37, 30, 22, 14, 6, 62, 54, 46, 38, 27, 19, 11, 3, 59, 51, 43, 35, 28, 20, 12, 4, 60, 52, 44, 36, 25, 17, 9, 1, 57, 49, 41, 33, 26, 18, 10, 2, 58, 50, 42, 34, 32, 24, 16, 8, 64, 56, 48, 40, 31, 23, 15, 7, 63, 55, 47, 39, 30, 22, 14, 6, 62, 54, 46, 38, 29, 21, 13, 5, 61, 53, 45, 37, 28, 20, 12, 4, 60, 52, 44, 36, 27, 19, 11, 3, 59, 51, 43, 35, 26, 18, 10, 2, 58, 50, 42, 34, 25, 17, 9, 1, 57, 49, 41, 33, 33, 41, 49, 57, 1, 9, 17, 25, 34, 42, 50, 58, 2, 10, 18, 26, 35, 43, 51, 59, 3, 11, 19, 27, 36, 44, 52, 60, 4, 12, 20, 28, 37, 45, 53, 61, 5, 13, 21, 29, 38, 46, 54, 62, 6, 14, 22, 30, 39, 47, 55, 63, 7, 15, 23, 31, 40, 48, 56, 64, 8, 16, 24, 32, 34, 42, 50, 58, 2, 10, 18, 26, 33, 41, 49, 57, 1, 9, 17, 25, 36, 44, 52, 60, 4, 12, 20, 28, 35, 43, 51, 59, 3, 11, 19, 27, 38, 46, 54, 62, 6, 14, 22, 30, 37, 45, 53, 61, 5, 13, 21, 29, 40, 48, 56, 64, 8, 16, 24, 32, 39, 47, 55, 63, 7, 15, 23, 31, 35, 43, 51, 59, 3, 11, 19, 27, 36, 44, 52, 60, 4, 12, 20, 28, 33, 41, 49, 57, 1, 9, 17, 25, 34, 42, 50, 58, 2, 10, 18, 26, 39, 47, 55, 63, 7, 15, 23, 31, 40, 48, 56, 64, 8, 16, 24, 32, 37, 45, 53, 61, 5, 13, 21, 29, 38, 46, 54, 62, 6, 14, 22, 30, 36, 44, 52, 60, 4, 12, 20, 28, 35, 43, 51, 59, 3, 11, 19, 27, 34, 42, 50, 58, 2, 10, 18, 26, 33, 41, 49, 57, 1, 9, 17, 25, 40, 48, 56, 64, 8, 16, 24, 32, 39, 47, 55, 63, 7, 15, 23, 31, 38, 46, 54, 62, 6, 14, 22, 30, 37, 45, 53, 61, 5, 13, 21, 29, 37, 45, 53, 61, 5, 13, 21, 29, 38, 46, 54, 62, 6, 14, 22, 30, 39, 47, 55, 63, 7, 15, 23, 31, 40, 48, 56, 64, 8, 16, 24, 32, 33, 41, 49, 57, 1, 9, 17, 25, 34, 42, 50, 58, 2, 10, 18, 26, 35, 43, 51, 59, 3, 11, 19, 27, 36, 44, 52, 60, 4, 12, 20, 28, 38, 46, 54, 62, 6, 14, 22, 30, 37, 45, 53, 61, 5, 13, 21, 29, 40, 48, 56, 64, 8, 16, 24, 32, 39, 47, 55, 63, 7, 15, 23, 31, 34, 42, 50, 58, 2, 10, 18, 26, 33, 41, 49, 57, 1, 9, 17, 25, 36, 44, 52, 60, 4, 12, 20, 28, 35, 43, 51, 59, 3, 11, 19, 27, 39, 47, 55, 63, 7, 15, 23, 31, 40, 48, 56, 64, 8, 16, 24, 32, 37, 45, 53, 61, 5, 13, 21, 29, 38, 46, 54, 62, 6, 14, 22, 30, 35, 43, 51, 59, 3, 11, 19, 27, 36, 44, 52, 60, 4, 12, 20, 28, 33, 41, 49, 57, 1, 9, 17, 25, 34, 42, 50, 58, 2, 10, 18, 26, 40, 48, 56, 64, 8, 16, 24, 32, 39, 47, 55, 63, 7, 15, 23, 31, 38, 46, 54, 62, 6, 14, 22, 30, 37, 45, 53, 61, 5, 13, 21, 29, 36, 44, 52, 60, 4, 12, 20, 28, 35, 43, 51, 59, 3, 11, 19, 27, 34, 42, 50, 58, 2, 10, 18, 26, 33, 41, 49, 57, 1, 9, 17, 25, 41, 33, 57, 49, 9, 1, 25, 17, 42, 34, 58, 50, 10, 2, 26, 18, 43, 35, 59, 51, 11, 3, 27, 19, 44, 36, 60, 52, 12, 4, 28, 20, 45, 37, 61, 53, 13, 5, 29, 21, 46, 38, 62, 54, 14, 6, 30, 22, 47, 39, 63, 55, 15, 7, 31, 23, 48, 40, 64, 56, 16, 8, 32, 24, 42, 34, 58, 50, 10, 2, 26, 18, 41, 33, 57, 49, 9, 1, 25, 17, 44, 36, 60, 52, 12, 4, 28, 20, 43, 35, 59, 51, 11, 3, 27, 19, 46, 38, 62, 54, 14, 6, 30, 22, 45, 37, 61, 53, 13, 5, 29, 21, 48, 40, 64, 56, 16, 8, 32, 24, 47, 39, 63, 55, 15, 7, 31, 23, 43, 35, 59, 51, 11, 3, 27, 19, 44, 36, 60, 52, 12, 4, 28, 20, 41, 33, 57, 49, 9, 1, 25, 17, 42, 34, 58, 50, 10, 2, 26, 18, 47, 39, 63, 55, 15, 7, 31, 23, 48, 40, 64, 56, 16, 8, 32, 24, 45, 37, 61, 53, 13, 5, 29, 21, 46, 38, 62, 54, 14, 6, 30, 22, 44, 36, 60, 52, 12, 4, 28, 20, 43, 35, 59, 51, 11, 3, 27, 19, 42, 34, 58, 50, 10, 2, 26, 18, 41, 33, 57, 49, 9, 1, 25, 17, 48, 40, 64, 56, 16, 8, 32, 24, 47, 39, 63, 55, 15, 7, 31, 23, 46, 38, 62, 54, 14, 6, 30, 22, 45, 37, 61, 53, 13, 5, 29, 21, 45, 37, 61, 53, 13, 5, 29, 21, 46, 38, 62, 54, 14, 6, 30, 22, 47, 39, 63, 55, 15, 7, 31, 23, 48, 40, 64, 56, 16, 8, 32, 24, 41, 33, 57, 49, 9, 1, 25, 17, 42, 34, 58, 50, 10, 2, 26, 18, 43, 35, 59, 51, 11, 3, 27, 19, 44, 36, 60, 52, 12, 4, 28, 20, 46, 38, 62, 54, 14, 6, 30, 22, 45, 37, 61, 53, 13, 5, 29, 21, 48, 40, 64, 56, 16, 8, 32, 24, 47, 39, 63, 55, 15, 7, 31, 23, 42, 34, 58, 50, 10, 2, 26, 18, 41, 33, 57, 49, 9, 1, 25, 17, 44, 36, 60, 52, 12, 4, 28, 20, 43, 35, 59, 51, 11, 3, 27, 19, 47, 39, 63, 55, 15, 7, 31, 23, 48, 40, 64, 56, 16, 8, 32, 24, 45, 37, 61, 53, 13, 5, 29, 21, 46, 38, 62, 54, 14, 6, 30, 22, 43, 35, 59, 51, 11, 3, 27, 19, 44, 36, 60, 52, 12, 4, 28, 20, 41, 33, 57, 49, 9, 1, 25, 17, 42, 34, 58, 50, 10, 2, 26, 18, 48, 40, 64, 56, 16, 8, 32, 24, 47, 39, 63, 55, 15, 7, 31, 23, 46, 38, 62, 54, 14, 6, 30, 22, 45, 37, 61, 53, 13, 5, 29, 21, 44, 36, 60, 52, 12, 4, 28, 20, 43, 35, 59, 51, 11, 3, 27, 19, 42, 34, 58, 50, 10, 2, 26, 18, 41, 33, 57, 49, 9, 1, 25, 17, 49, 57, 33, 41, 17, 25, 1, 9, 50, 58, 34, 42, 18, 26, 2, 10, 51, 59, 35, 43, 19, 27, 3, 11, 52, 60, 36, 44, 20, 28, 4, 12, 53, 61, 37, 45, 21, 29, 5, 13, 54, 62, 38, 46, 22, 30, 6, 14, 55, 63, 39, 47, 23, 31, 7, 15, 56, 64, 40, 48, 24, 32, 8, 16, 50, 58, 34, 42, 18, 26, 2, 10, 49, 57, 33, 41, 17, 25, 1, 9, 52, 60, 36, 44, 20, 28, 4, 12, 51, 59, 35, 43, 19, 27, 3, 11, 54, 62, 38, 46, 22, 30, 6, 14, 53, 61, 37, 45, 21, 29, 5, 13, 56, 64, 40, 48, 24, 32, 8, 16, 55, 63, 39, 47, 23, 31, 7, 15, 51, 59, 35, 43, 19, 27, 3, 11, 52, 60, 36, 44, 20, 28, 4, 12, 49, 57, 33, 41, 17, 25, 1, 9, 50, 58, 34, 42, 18, 26, 2, 10, 55, 63, 39, 47, 23, 31, 7, 15, 56, 64, 40, 48, 24, 32, 8, 16, 53, 61, 37, 45, 21, 29, 5, 13, 54, 62, 38, 46, 22, 30, 6, 14, 52, 60, 36, 44, 20, 28, 4, 12, 51, 59, 35, 43, 19, 27, 3, 11, 50, 58, 34, 42, 18, 26, 2, 10, 49, 57, 33, 41, 17, 25, 1, 9, 56, 64, 40, 48, 24, 32, 8, 16, 55, 63, 39, 47, 23, 31, 7, 15, 54, 62, 38, 46, 22, 30, 6, 14, 53, 61, 37, 45, 21, 29, 5, 13, 53, 61, 37, 45, 21, 29, 5, 13, 54, 62, 38, 46, 22, 30, 6, 14, 55, 63, 39, 47, 23, 31, 7, 15, 56, 64, 40, 48, 24, 32, 8, 16, 49, 57, 33, 41, 17, 25, 1, 9, 50, 58, 34, 42, 18, 26, 2, 10, 51, 59, 35, 43, 19, 27, 3, 11, 52, 60, 36, 44, 20, 28, 4, 12, 54, 62, 38, 46, 22, 30, 6, 14, 53, 61, 37, 45, 21, 29, 5, 13, 56, 64, 40, 48, 24, 32, 8, 16, 55, 63, 39, 47, 23, 31, 7, 15, 50, 58, 34, 42, 18, 26, 2, 10, 49, 57, 33, 41, 17, 25, 1, 9, 52, 60, 36, 44, 20, 28, 4, 12, 51, 59, 35, 43, 19, 27, 3, 11, 55, 63, 39, 47, 23, 31, 7, 15, 56, 64, 40, 48, 24, 32, 8, 16, 53, 61, 37, 45, 21, 29, 5, 13, 54, 62, 38, 46, 22, 30, 6, 14, 51, 59, 35, 43, 19, 27, 3, 11, 52, 60, 36, 44, 20, 28, 4, 12, 49, 57, 33, 41, 17, 25, 1, 9, 50, 58, 34, 42, 18, 26, 2, 10, 56, 64, 40, 48, 24, 32, 8, 16, 55, 63, 39, 47, 23, 31, 7, 15, 54, 62, 38, 46, 22, 30, 6, 14, 53, 61, 37, 45, 21, 29, 5, 13, 52, 60, 36, 44, 20, 28, 4, 12, 51, 59, 35, 43, 19, 27, 3, 11, 50, 58, 34, 42, 18, 26, 2, 10, 49, 57, 33, 41, 17, 25, 1, 9, 57, 49, 41, 33, 25, 17, 9, 1, 58, 50, 42, 34, 26, 18, 10, 2, 59, 51, 43, 35, 27, 19, 11, 3, 60, 52, 44, 36, 28, 20, 12, 4, 61, 53, 45, 37, 29, 21, 13, 5, 62, 54, 46, 38, 30, 22, 14, 6, 63, 55, 47, 39, 31, 23, 15, 7, 64, 56, 48, 40, 32, 24, 16, 8, 58, 50, 42, 34, 26, 18, 10, 2, 57, 49, 41, 33, 25, 17, 9, 1, 60, 52, 44, 36, 28, 20, 12, 4, 59, 51, 43, 35, 27, 19, 11, 3, 62, 54, 46, 38, 30, 22, 14, 6, 61, 53, 45, 37, 29, 21, 13, 5, 64, 56, 48, 40, 32, 24, 16, 8, 63, 55, 47, 39, 31, 23, 15, 7, 59, 51, 43, 35, 27, 19, 11, 3, 60, 52, 44, 36, 28, 20, 12, 4, 57, 49, 41, 33, 25, 17, 9, 1, 58, 50, 42, 34, 26, 18, 10, 2, 63, 55, 47, 39, 31, 23, 15, 7, 64, 56, 48, 40, 32, 24, 16, 8, 61, 53, 45, 37, 29, 21, 13, 5, 62, 54, 46, 38, 30, 22, 14, 6, 60, 52, 44, 36, 28, 20, 12, 4, 59, 51, 43, 35, 27, 19, 11, 3, 58, 50, 42, 34, 26, 18, 10, 2, 57, 49, 41, 33, 25, 17, 9, 1, 64, 56, 48, 40, 32, 24, 16, 8, 63, 55, 47, 39, 31, 23, 15, 7, 62, 54, 46, 38, 30, 22, 14, 6, 61, 53, 45, 37, 29, 21, 13, 5, 61, 53, 45, 37, 29, 21, 13, 5, 62, 54, 46, 38, 30, 22, 14, 6, 63, 55, 47, 39, 31, 23, 15, 7, 64, 56, 48, 40, 32, 24, 16, 8, 57, 49, 41, 33, 25, 17, 9, 1, 58, 50, 42, 34, 26, 18, 10, 2, 59, 51, 43, 35, 27, 19, 11, 3, 60, 52, 44, 36, 28, 20, 12, 4, 62, 54, 46, 38, 30, 22, 14, 6, 61, 53, 45, 37, 29, 21, 13, 5, 64, 56, 48, 40, 32, 24, 16, 8, 63, 55, 47, 39, 31, 23, 15, 7, 58, 50, 42, 34, 26, 18, 10, 2, 57, 49, 41, 33, 25, 17, 9, 1, 60, 52, 44, 36, 28, 20, 12, 4, 59, 51, 43, 35, 27, 19, 11, 3, 63, 55, 47, 39, 31, 23, 15, 7, 64, 56, 48, 40, 32, 24, 16, 8, 61, 53, 45, 37, 29, 21, 13, 5, 62, 54, 46, 38, 30, 22, 14, 6, 59, 51, 43, 35, 27, 19, 11, 3, 60, 52, 44, 36, 28, 20, 12, 4, 57, 49, 41, 33, 25, 17, 9, 1, 58, 50, 42, 34, 26, 18, 10, 2, 64, 56, 48, 40, 32, 24, 16, 8, 63, 55, 47, 39, 31, 23, 15, 7, 62, 54, 46, 38, 30, 22, 14, 6, 61, 53, 45, 37, 29, 21, 13, 5, 60, 52, 44, 36, 28, 20, 12, 4, 59, 51, 43, 35, 27, 19, 11, 3, 58, 50, 42, 34, 26, 18, 10, 2, 57, 49, 41, 33, 25, 17, 9, 1
