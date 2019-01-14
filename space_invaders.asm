;-------------------------  Constants  ------------------------------

VIDEO_START        	equ		$ffb500                        ; Starting address
VIDEO_WIDTH         equ		480        					   ; Width in pixels
VIDEO_HEIGHT        equ		320							   ; Height in pixels
VIDEO_SIZE          equ		(VIDEO_WIDTH*VIDEO_HEIGHT/8)   ; Size in bytes
BYTE_PER_LINE     	equ		(VIDEO_WIDTH/8)

WIDTH               equ		0
HEIGHT              equ		2
MATRIX              equ		4
;----------------------------  Init  -------------------------------

					org		$0
vector_000          dc.l    VIDEO_START                    ; Initial value of A7
vector_001          dc.l    Main

;----------------------------  Main  -------------------------------

					org		$500
					
Main				move.l	#$88888888,d0
					jsr		FillScreen

					lea     InvaderA_Bitmap,a0
					move.w	#112,d1
					move.w	#100,d2
					jsr     PrintBitmap
					
					lea     InvaderB_Bitmap,a0
					move.w	#224,d1
					jsr     PrintBitmap
					
					lea     InvaderC_Bitmap,a0
					move.w	#336,d1
					jsr     PrintBitmap
					
					lea     Ship_Bitmap,a0
					move.w	#223,d1
					move.w	#200,d2
					jsr     PrintBitmap
					
					illegal
					

					move.l	#VIDEO_START,a1
					
					move.l	#InvaderA_Bitmap,a0
					
					jsr		CopyBitmap
					
					moveq.l	#$0,d0
					jsr     FillScreen
					
					move.l	#InvaderB_Bitmap,a0
					
					jsr		CopyBitmap
					
					moveq.l	#$0,d0
					jsr     FillScreen
					
					move.l	#InvaderC_Bitmap,a0
					
					jsr		CopyBitmap
					
					moveq.l	#$0,d0
					jsr     FillScreen
					
					move.l	#Ship_Bitmap,a0
					
					jsr		CopyBitmap
					
					illegal
					
					move.b	#16,d1
\rows				clr		d0
\columns			move.b	(a1)+,0(a0,d0.l)
					addi.b	#1,d0
					cmp.b	#3,d0
					bne		\columns
					adda.l	#BYTE_PER_LINE,a0
					subi.b	#1,d1
					bne		\rows
					
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

PixelToByte			move.l	d2,-(a7)
					move.l	d3,d2
					clr		d3
\loop				subi.w	#8,d2
					addi.w	#1,d3
					tst.w	d2
					bgt		\loop
					
					move.l	(a7)+,d2
					rts
					

;->	a0.l - address of the bitmap
;->	a1.l - address of the destination
;->	d0.w - offset in pixels
;->	d3.w - width of the line in bytes
;<-	a0.l - address od the next line
CopyLine			movem.l	a1/d0/d1/d3,-(a7)
\loop				clr.l	d1
					move.b	(a0)+,d1
					ror.w	d0,d1
					or.b	d1,(a1)+
					tst.w	d3
					beq		\endofloop
					clr.b	d1
					rol.w	#8,d1
					or.b	d1,(a1)
					
\endofloop			subi.w	#1,d3
					bne		\loop
					
					movem.l	(a7)+,a1/d0/d1/d3
					rts

;->	a0.l - address of the bitmap
;->	a1.l - address of the destination
;->	d0.w - offset in pixels
CopyBitmap			movem.l	a0/a1/d1/d3,-(a7)
					move.w	WIDTH(a0),d3
					move.w	HEIGHT(a0),d1
					adda.l	#MATRIX,a0
					jsr		PixelToByte
\loop				jsr		CopyLine
					adda.l	#BYTE_PER_LINE,a1
					subi.w	#1,d1
					bne		\loop
					
					movem.l	(a7)+,a0/a1/d1/d3
					rts
			
;->	d1.w - abscissa in pixels	(x coordinate)
;->	d2.w - ordinate in pixels	(y coordinate)
;->	a1.l - address of the pixel
;->	d0.w - offset of the pixels
PixelToAdress		movem.l	d2/d1,-(a7)
					andi.l	#$0000ffff,d1
					
					mulu.w	#BYTE_PER_LINE,d2
					divu.w	#8,d1
					add.w	d1,d2
					swap	d1
					move.w	d1,d0
					movea.l	#VIDEO_START,a1
					adda.w	d2,a1

					movem.l	(a7)+,d2/d1
					rts
					
;->	a0.l - address of the bitmap
;->	d1.w - abscissa in pixels	(x coordinate)
;->	d2.w - ordinate in pixels	(y coordinate)
PrintBitmap			jsr		PixelToAdress
					jsr		CopyBitmap
					
					rts
					
					
;------------------------------ DATA -------------------------------		

InvaderA_Bitmap 	dc.w	24,16
					dc.b    %00000000,%11111111,%00000000
					dc.b    %00000000,%11111111,%00000000
					dc.b    %00111111,%11111111,%11111100
					dc.b    %00111111,%11111111,%11111100
					dc.b    %11111111,%11111111,%11111111
					dc.b    %11111111,%11111111,%11111111
					dc.b    %11111100,%00111100,%00111111
					dc.b    %11111100,%00111100,%00111111
					dc.b    %11111111,%11111111,%11111111
					dc.b    %11111111,%11111111,%11111111
					dc.b    %00000011,%11000011,%11000000
					dc.b    %00001111,%11000011,%11000000
					dc.b    %00001111,%00111100,%11110000
					dc.b    %00001111,%00111100,%11110000
					dc.b    %11110000,%00000000,%00001111
					dc.b    %11110000,%00000000,%00001111

InvaderB_Bitmap 	dc.w	22,16
					dc.b    %00001100,%00000000,%11000000
					dc.b    %00001100,%00000000,%11000000
					dc.b    %00000011,%00000011,%00000000
					dc.b    %00000011,%00000011,%00000000
					dc.b    %00001111,%11111111,%11000000
					dc.b    %00001111,%11111111,%11000000
					dc.b    %00001100,%11111100,%11000000
					dc.b    %00001100,%11111100,%11000000
					dc.b    %00111111,%11111111,%11110000
					dc.b    %00111111,%11111111,%11110000
					dc.b    %11001111,%11111111,%11001100
					dc.b    %11001111,%11111111,%11001100
					dc.b    %11001100,%00000000,%11001100
					dc.b    %11001100,%00000000,%11001100
					dc.b    %00000011,%11001111,%00000000
					dc.b    %00000011,%11001111,%00000000

InvaderC_Bitmap 	dc.w	16,16
					dc.b    %00000011,%11000000
					dc.b    %00000011,%11000000
					dc.b    %00001111,%11110000
					dc.b    %00001111,%11110000
					dc.b    %00111111,%11111100
					dc.b    %00111111,%11111100
					dc.b    %11110011,%11001111
					dc.b    %11110011,%11001111
					dc.b    %11111111,%11111111
					dc.b    %11111111,%11111111
					dc.b    %00110011,%11001100
					dc.b    %00110011,%11001100
					dc.b    %11000000,%00000011
					dc.b    %11000000,%00000011
					dc.b    %00110000,%00001100
					dc.b    %00110000,%00001100
					
Ship_Bitmap		 	dc.w	24,14
					dc.b    %00000000,%00011000,%00000000
					dc.b    %00000000,%00011000,%00000000
					dc.b    %00000000,%01111110,%00000000
					dc.b    %00000000,%01111110,%00000000
					dc.b    %00000000,%01111110,%00000000
					dc.b    %00000000,%01111110,%00000000
					dc.b    %00111111,%11111111,%11111100
					dc.b    %00111111,%11111111,%11111100
					dc.b    %11111111,%11111111,%11111111
					dc.b    %11111111,%11111111,%11111111
					dc.b    %11111111,%11111111,%11111111
					dc.b    %11111111,%11111111,%11111111
					dc.b    %11111111,%11111111,%11111111
					dc.b    %11111111,%11111111,%11111111
