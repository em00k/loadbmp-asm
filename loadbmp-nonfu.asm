; load a bmp 256 indexed image that is stored upside down 
; It uses a small memory footprint between $2000 - $3FFF
; Image needs to be 256*192 256 colours with the Next uniform palette. 
; em00k2020 / David Saphier 23/09/20

	;device zxspectrumnext 
	device zxspectrum48						; we will use a sna for the example 
	CSPECTMAP loadbmp_test.map 	
	include "macros.asm"					; contains out nextreg macros 

mystack 	equ $7ffe						; so we know where stack is 
startoffset equ 1078+16384+16384+8192		; startpos in bmp file, read from LAST 8kb, skip header. bmp must be 256 indexed 
startbank 	equ 32
	
	org $8000								; start at $8000 / 32768

; ------------------------------------
; main program 
	
main_prog:
			di 								; di so ints dont trigger when we've paged out ROM 
			ld sp,mystack 					; just for saftey 						
			call clearula					; clear ula to black	
			call setregisters 				; set relevant nregs
	
			;load the bmp in 8kb chunks 

			ld b,7							; we want to loop 8 times (8kb*8 = 48kb)
			ld a,(L2bank)
			ld c,a 							; store start bank in c 
loadloop: 
			
			ld a,c							; get the bank in c and put in a 
			nextreg_a $52					; set mmu slot 2 to bank L2bank ($4000-5fff)
			inc c							; inc our bank
			push bc 						; save bc so we can use again 
							
			
			ld ix,bmpfilename				; point ix to our filename 
			ld hl,$4000						; destination address $4000 
			ld bc,$2000						; amount of data to load $2000
			ld de,(L2offsetpos)				; offset inside the bmp file we want to load, we start at the last 8kb
			call load 						; call esxdos routine to load 8kbchunk 
			call flip_layer2lines			; flip the 32 lines of layer 2

			ld hl,(L2offsetpos)				; lets decrease our offset, put offset into hl 
			ld de,$2000						; set de to 8kb 
			sbc hl,de						; subtract de from hl 
			ld (L2offsetpos),hl 			; store the value in (L2offsetpos)
			
			pop bc 							; pop back our loop in b and c our bank
					
			djnz loadloop					; if b > 0 then loop 
	
			ld hl,startoffset				; reset our offset incase we want to call this again 
			ld (L2offsetpos),hl 			; reset the l2offsetpos
	
			nextreg_nn $69,%10000000		; enable layer 2 
			nextreg_nn $51,$ff				; return ROM to slot 1 
	
image_loop:		

			; end program 
	
			jp image_loop 

flip_layer2lines:
	
			; $4000 - $5fff Layer2 BMP data loaded 
			; the data is upside down so we need to flip line 0 - 32
			; hl = top line first left pixel, de = bottom line, first left pixel 
			ld hl,$4000 : ld de,$5f00 : ld bc,$1000
	
.copyloop:	
			ld a,(hl)						; hl is the top lines, get the value into a
			ex af,af'						; swap to shadow a reg 
			ld a,(de)						; de is bottom lines, get value in a 
			ld (hl),a						; put this value into hl 
			ex af,af'						; swap back shadow reg 
			ld (de),a 						; put the value into de 
			inc hl							; inc hl to next byte 
			inc e							; only inc e as we have to go left to right then up with d 
			ld a,e							; check e has >255
			or a							
			call z,.decd						; it did do we need to dec d 
			dec bc							; dec bc for our loop 
			ld a,b							; has bc = 0 ?
			or c
			jp nz,.copyloop					; no carry on until it does 
			ret 
.decd:
			dec d 							; this decreases d to move a line up 
			ret			

setregisters:

			nextreg_nn $8,%11111010
			nextreg_nn $15,%00010000		; set USL layer order 
			nextreg_nn $12,16				; set base bank for Layer 2 (in 16kb mode)
			nextreg_nn $69,%00000000		; display control reg, 0 L2 off, set to %10000000 to show draw
			nextreg_nn $7,3					; cpu speed 28, set to 0 to see in slow, 
			nextreg_nn $14,0				; global transparency set to palette 0 = black 
			xor a : out ($fe),a				; border black 
			ret 

clearula:
			ld hl,22528
			ld de,22529
			ld (hl),0
			ld bc,768
			ldir
			ret 
	
; ------------------------------------
; data / includes 

L2bank:
			db 32						; this is 16kb bank 16 we set with ref $12
L2offsetpos
			dw 1078+16384+16384+8192	; this points to the last 8kb of the bmp file 
	
			include "esxdos.asm" 		; this contains the load subroutines 

bmpfilename:
			db "1.bmp",0				; image file 
		
								
	savesna "bmptest.snx",main_prog										
	
	