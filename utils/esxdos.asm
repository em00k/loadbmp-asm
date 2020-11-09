	
M_GETSETDRV 		equ $89
F_OPEN 			equ $9a
F_CLOSE 		equ $9b
F_READ 			equ $9d
F_WRITE 		equ $9e
F_SEEK 			equ $9f
F_GET_DIR 		equ $a8
F_SET_DIR 		equ $a9

FA_READ 		equ $01
FA_APPEND 		equ $06
FA_OVERWRITE 		equ $0C

load:
	
	push hl  					; save destination 
	push bc 					; save size 
	push de 
	ld a, '*' 					; use current drive
	ld b, FA_READ 				; set mode

	ESXDOS F_OPEN
	jp c,failedtoload    		; jp to failed if failed to open 
	
	ld (handle), a 				; store handle
	
	pop de 						; offset 
	
	ld ixl, 0 					; seek from start of file
	ld bc, 0

	ESXDOS F_SEEK
	
	ld a, (handle) 				; restore handle

	pop bc 						; read length 
	pop ix 						; memory dest
				
	ESXDOS F_READ

	ld a, (handle)
	ESXDOS F_CLOSE 			; close file
	
	ret

failedtoload:
	nextreg $69,0
	ld hl,failedtoloadtext : call printrstfailed
	push ix : pop hl : call printrstfailed
	di : halt 
	
printrstfailed;
	ld a,(hl) : or a : ret z : rst 16 : inc hl : jp printrstfailed

failedtoloadtext:
	db "Failed to load : ",0
	

handle: db 0
	
	
