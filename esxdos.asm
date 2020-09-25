	
load:
	
	push hl  					; save destination 
	push bc 					; save size 
	ld a, '*' 					; use current drive
	ld b, FA_READ 				; set mode
	;ld ix, fname 				; ix = filename pointer 

	ESXDOS F_OPEN
	jp c,failedtoload    		; jp to failed if failed to open 
	
	ld (handle), a 				; store handle
	
	ld l, 0 					; seek from start of file
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

	ld hl,failedtoloadtext : call printrstfailed
	push ix : pop hl : call printrstfailed
	di : halt 
	
printrstfailed;
	ld a,(hl) : or a : ret z : rst 16 : inc hl : jp printrstfailed

failedtoloadtext:
	db "Failed to load : ",0
	

handle: db 0
	
	