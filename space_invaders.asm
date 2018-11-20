;-------------------------  Constants  ------------------------------

VIDEO_START        	equ		$ffb500                        ; Starting address
VIDEO_WIDTH         equ		480        					   ; Width in pixels
VIDEO_HEIGHT        equ		320							   ; Height in pixels
VIDEO_SIZE          equ		(VIDEO_WIDTH*VIDEO_HEIGHT/8)   ; Size in bytes
BYTE_PER_LINE     	equ		(VIDEO_WIDTH/8)

;----------------------------  Init  -------------------------------

					org		$0
vector_000          dc.l    VIDEO_START                    ; Initial value of A7
vector_001          dc.l    Main

;----------------------------  Main  -------------------------------

					org		$500
					
Main				
					move.l	#$ffffffff,d0
					jsr     FillScreen	
				
					move.l	#$f0f0f0f0,d0
					jsr     FillScreen
					
					move.l	#$fff0fff0,d0
					jsr     FillScreen
					
					moveq.l	#$0,d0
					jsr     FillScreen
					
					jsr     HLines
				
					illegal

;-------------------------  Subroutines  ---------------------------

FillScreen			movem.l a0/d1,-(a7)
					move.l	#VIDEO_START,a0
					move.l	#VIDEO_SIZE,d1
					
\loop				move.l	d0,(a0)+
					subq.l	#4,d1
					bne		\loop
					
					movem.l	(a7)+,a0/d1
					rts
					
HLines				movem.l a0/d1/d0,-(a7)
					move.l	#VIDEO_START,a0
					move.l	#VIDEO_HEIGHT,d1
					
\lines_loop			move.l	#BYTE_PER_LINE*8,d0		;8 lines

\white				move.l	#$ffffffff,(a0)+
					subq.l	#4,d0
					bne		\white
					
					move.l	#BYTE_PER_LINE*8,d0		;8 lines

\black				move.l	#$0,(a0)+
					subq.l	#4,d0
					bne		\black
					
					subi.l	#16,d1
					bne		\lines_loop
					
					movem.l	(a7)+,a0/d1/d0
					rts	
