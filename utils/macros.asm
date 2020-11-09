

	macro ESXDOS command
		rst 8
		db command
	endm

	macro loadfile name, dest, size, offset 
		ld ix,name 
		ld hl,dest	
		ld bc,size
		ld de,offset
		call load
	endm 

	macro nextreg_a reg
		dw $92ed
		db reg
	endm
	
	macro mirror_a: dw $24ed: endm
	
	macro nextreg_nn reg, value
		dw $91ed
		db reg
		db value
	endm
	
	macro break
		dw $01dd
	endm
