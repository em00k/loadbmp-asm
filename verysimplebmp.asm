;
;  this will incbin a bmp into the NEX that can then be used by
;  pointing Layer2 RAM to the bmp area. 
;
	device 	zxspectrumnext
	org 	$8000

main_prog:  

	nextreg $69,%10000000				; turns on layer 2 
	xor 	a  
	out 	($fe),a					; border black 
	nextreg $12,$20				 	; set L2 Ram to start at 16kb BANK $20
	ld 	b,200 
	call 	delay 
	nextreg $12,$23				 	; set L2 Ram to start at 16kb BANK $20
	ld 	b,200
	call 	delay 
	jp 	main_prog
		
delay: 
	push 	bc 
	
WaitRasterLine:                                       
	ld de	,192
	
waitFrame:

	ld 	bc,$243b
	ld 	a,$1e
	out 	(c),a
	inc 	b
	in 	a,(c)
	ld 	h,a
	dec 	b
	ld 	a,$1f
	out 	(c),a
	inc 	b
	in 	a,(c)
	ld  	l,a
	and 	a
	sbc 	hl,de
	add 	hl,de
	jr 	nz,waitFrame
	
	pop 	bc 
	djnz 	delay 
	
	ret     
	
	; this bit places code inside the NEX that is loaded into RAM > 65536
	
	MMU 	7 n,$20*2						; $20*2 is our 8kn bank $40 
	org 	$e000 
	incbin 	"./data/1.bmp",1078				; this has been remapped and flipped 
	
	MMU 	7 n,$23*2						; $23*2 is our 8kn bank $46 
	org 	$e000 
	incbin 	"./data/al.bmp",1078				; this is without remapping and flipping
	
	SAVENEX OPEN "verysimple.nex", main_prog , $5ffe
    	SAVENEX CORE 3, 0, 0      
    	SAVENEX CFG 0, 0            
	SAVENEX AUTO 
    	SAVENEX CLOSE   	
	
	IF ((_ERRORS = 0) && (_WARNINGS = 0))
		SHELLEXEC ".\bin\cspect.exe -sound -w3 -16bit -basickeys -tv -zxnext -brk verysimple.nex"
	ENDIF
