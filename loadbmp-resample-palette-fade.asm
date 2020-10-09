; load a bmp 256 indexed image that is stored upside down 
; It uses a small memory footprint between $4000 - $5FFF, this is banked in so wont affect
; any code or data that lives in normal bank 5
; Image needs to be 256*192 256 colours, palette will be converted to Next format. 
; em00k2020 / David Saphier 09/10/20

	;device zxspectrumnext 
	device zxspectrum48						; we will use a snx for the example 
	CSPECTMAP loadbmp_test.map 	
	include ".\utils\macros.asm"			; contains out nextreg macros 

mystack 	equ $7ffe						; so we know where stack is 
startoffset equ 1078+16384+16384+8192		; startpos in bmp file, read from LAST 8kb, skip header. bmp must be 256 indexed 
startbank 	equ 32
	
	org $8000								; start at $8000 / 32768

; ------------------------------------
; main program 
	
main_prog:
			di 								; di so ints dont trigger
			ld sp,mystack 					; just for saftey 						
			call clearula					; clear ula to black	
			call setregisters 				; set relevant nregs
			call setpalette 
			
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
	
			nextreg $69,%10000000		; enable layer 2 
			nextreg $52,$a				; return bank $a to slot 2
			ei 
	rept 40
			halt		
	endr	
image_loop:

			; end program 
		   
			ld b,30 : call delay
			call fade 
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
			call z,.decd					; it did do we need to dec d 
			dec bc							; dec bc for our loop 
			ld a,b							; has bc = 0 ?
			or c
			jp nz,.copyloop					; no carry on until it does 
			ret 
.decd:
			dec d 							; this decreases d to move a line up 
			ret			

setregisters:

			nextreg $8,%11111010
			nextreg $15,%00010000		; set USL layer order 
			nextreg $12,16				; set base bank for Layer 2 (in 16kb mode)
			nextreg $69,%00000000		; display control reg, 0 L2 off, set to %10000000 to show draw
			nextreg $7,3					; cpu speed 28, set to 0 to see in slow, 
			nextreg $14,0				; global transparency set to palette 0 = black 
			xor a : out ($fe),a				; border black 
			ret 

clearula:
			ld hl,22528
			ld de,22529
			ld (hl),0
			ld bc,768
			ldir
			ret 

setpalette:
			;ld a,(L2bank)					; get the first bank (32)
			;nextreg_a $52
			
			ld ix,bmpfilename
			ld hl,palettebuffer	
			ld bc,1024+54
            ld de,0
			call load
			
			ld a,5

remapcolours:
			nextreg $43,%00010000
			nextreg $40,0
			ld (palfade),a 							; number of shifts for fade def = 5
			ld c,a 									; store this in c  
			ld hl,palettebuffer+54						; get hl = start of palette, RGB format. 
			ld de,palettenext 						; where to put out next palette 
			ld b,0									; number of entries to walk through

indexloop:
			push bc 								; save our loop counter on stack 
			push de 								; save our next palette addres 

			ld a,(hl)
			; ' BLUE 
			; b9>>5
			
			ld d,0 : ld e,a : ld b,c : bsrl de,b 	; b9>>5
			ld a,e : ld (tempbytes+2),a 			; store at tempbytes+2
			
			inc hl : ld a,(hl)						; more to green byte put in a 
		
			; ' GREEN 
			; ((g9 >> 5) << 3)
		
			ld d,0 : ld e,a : ld b,c : bsrl de,b 	; g9>>5
			ld b,3 : bsla de,b : ld a,e 			; << 3
			ld (tempbytes+1),a 						; store at tempbytes+1
		
			inc hl 									; move to next bit 

			; ' RED 
			; ((r9>>5) << 6)
			ld d,0 									; make sure d = 0 
			ld e,(hl)								; get red in to hl 
			ld b,c									; shift right c times 
			bsrl de,b  								; r9>>5
			ld b,6									; and right 
			bsla de,b 								; << 6
			push de 								; result will be 16bit, store on stack 
		
			inc hl : inc hl 						; move to next rgb block 
			
			; now OR r16 g8 b8, hl = red16, de points to green/blue bytes 
			exx  									; use shadow regs 
			pop hl 									; pop back red from stack into hl  
			ld de,(tempbytes+1)						; point de to green and blue 
			ld a,l	
			or d 									; or e & l into a 
			or e									; or d & a into a 
			ld l,a 									; put result in a 
			ld (nb_pal_hl+1),hl						; store at nb_pal_hl 
		
			exx										; back to normal regs 
			pop de 									; pop back palette address 
			push hl 								; save hl as its the offset into rgb palette 
nb_pal_hl:
			ld hl,0000								; smc from above 
			ld b,l 
			srl h 									; shift hl right 
			rr l 
			ld a,l 									; result in a 
			nextreg_a $44
			;ld (de),a 								; store first byte into or nextpalette ram 
			;inc de 								; us commented out but could be used 
			; next byte 						 	; store store the new palette 
			ld a,b
			and 1 									; and 1 and store blue bit 
			;ld (de),a 
			;inc de 								; move de to next byte in memory 
			nextreg_a $44
			
			pop hl 									; get back the rgb palette address 
			pop bc									; get loop counter back 
		
			djnz indexloop		
			ret 


fade: 		ld a,(fadedirection)
			or a : jr z,fadein
			jr fadeout 
			
fadein:		ld a,(palfade)
			inc a : cp $b : jr z,fadein_done 
			ld (palfade),a : call remapcolours
			ret 

fadein_done: 
			ld a,1 : ld (fadedirection),a 
			ret 

fadeout:	ld a,(palfade)
			dec a : cp 4 : jr z,fadeo_done 
			ld (palfade),a : call remapcolours
			ret 

fadeo_done: ;ld b,255 : call delay
			xor a : ld (fadedirection),a 
			ret 


delay: 
		push bc 
	
WaitRasterLine:                                       
			ld de,192
	
waitFrame:
			ld bc,$243b
			ld a,$1e
			out (c),a
			inc b
			in a,(c)
			ld h,a
			dec b
			ld a,$1f
			out (c),a
			inc b
			in a,(c)
			ld  l,a
			and a
			sbc hl,de
			add hl,de
			jr nz,waitFrame
	
			pop bc 
		djnz delay 
	ret 
; ------------------------------------
; data / includes 

L2bank:
			db 32						; this is 16kb bank 16 we set with ref $12
L2offsetpos
			dw 1078+16384+16384+8192	; this points to the last 8kb of the bmp file 
palfade: 
			db 0 
tempbytes:
			db 0,0,0			
palettenext:							; our next palette we create 
			defs 512, 0
fadedirection:
			db 0 
palettebuffer:
			defs 1024+58,0
	
			include ".\utils\esxdos.asm" 		; this contains the load subroutines 

bmpfilename:
			db "hatgirl2.bmp",0				; image file, pick any from the folder
		
								
	//savesna "h:\bmptest\bmptest.snx",main_prog										
	savesna "bmptest.snx",main_prog										
	
	IF ((_ERRORS = 0) && (_WARNINGS = 0))
        SHELLEXEC ".\bin\cspect.exe -sound -w3 -16bit -basickeys -tv -zxnext -brk -mmc=.\data\ -map=loadbmp-resample-palette-fade.map  bmptest.snx"
    ENDIF