M_GETSETDRV 	equ $89
F_OPEN 			equ $9a
F_CLOSE 		equ $9b
F_READ 			equ $9d
F_WRITE 		equ $9e
F_SEEK 			equ $9f
F_GET_DIR 		equ $a8
F_SET_DIR 		equ $a9

FA_READ 		equ $01
FA_APPEND 		equ $06
FA_OVERWRITE 	equ $0C

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