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
					
Main                move.w	#2,d0

\loop               jsr     WhiteSquare

					addq.w	#2,d0
					cmpi.w	#40,d0
					bls		\loop
					
					illegal
									
					move.l	#$ffffffff,d0
					jsr     FillScreen	
				
					move.l	#$f0f0f0f0,d0
					jsr     FillScreen
					
					move.l	#$fff0fff0,d0
					jsr     FillScreen
					
					moveq.l	#$0,d0
					jsr     FillScreen
					
					jsr     HLines
				
					move.l	#$0,d0
					jsr     FillScreen	
					
					jsr     WhiteSquare32
					
					jsr     WhiteSquare128
					
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
					
\lines_loop			move.l	#VIDEO_WIDTH,d0		;8 lines

\white				move.l	#$ffffffff,(a0)+
					subq.l	#4,d0
					bne		\white
					
					move.l	#VIDEO_WIDTH,d0		;8 lines

\black				move.l	#$0,(a0)+
					subq.l	#4,d0
					bne		\black
					
					subi.l	#16,d1
					bne		\lines_loop
					
					movem.l	(a7)+,a0/d1/d0
					rts	



WhiteSquare32		movem.l a0/d0,-(a7)
					
					move.l	#VIDEO_START,a0
					move.l	#8640,d0				;offset y ((320/2)-16)*60
					
\write				move.l	#$ffffffff,28(a0,d0.w)	;offset x (60/2)-2
					
					add.l	#BYTE_PER_LINE,d0
					cmp.l	#10560,d0				;end y ((320/2)+16)*60
					blt		\write
					
					movem.l	(a7)+,a0/d0
					rts	
					


WhiteSquare128		movem.l a0/d0,-(a7)
					
					move.l	#VIDEO_START,a0
					move.l	#5760,d0				;offset y ((320/2)-64)*60
					
\write				move.l	#$ffffffff,22(a0,d0.w)	;offset x (60/2)-8
					move.l	#$ffffffff,26(a0,d0.w)	;offset x (60/2)-4
					move.l	#$ffffffff,30(a0,d0.w)	;offset x (60/2)
					move.l	#$ffffffff,34(a0,d0.w)	;offset x (60/2)+4
					
					add.l	#BYTE_PER_LINE,d0
					cmp.l	#13440,d0				;end y ((320/2)+64)*60
					blt		\write
					
					movem.l	(a7)+,a0/d0
					rts	
					

WhiteSquare			movem.l a0/d1/d0,-(a7)

					move.l	#VIDEO_START,a0
					
					move.l	d0,d1
					muls	#-8,d1
					add.l	#VIDEO_HEIGHT,d1
					divu	#2,d1				;offset lines y
					mulu	#60,d1				;offset bytes y
					
					adda.l	d1,a0
					
					move.l	#60,d1
					sub.l	d0,d1
					divu	#2,d1				;offset bytes x
					
					adda.l	d1,a0
					
					move.l	d0,d1
					mulu	#8,d1
					
\lines				jsr		WhiteLine
										
					adda.l	#BYTE_PER_LINE,a0
					subq.l	#1,d1
					bne		\lines
					
					
					movem.l	(a7)+,a0/d1/d0
					rts	
					
					
					
WhiteLine			movem.l a0/d0,-(a7)	;len in d0 (in bytes) start in a0
		
\nextpart			move.b	#$ff,(a0)+
					subq.l	#1,d0
					bne		\nextpart	
					
					movem.l	(a7)+,a0/d0
					rts	
