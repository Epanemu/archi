;-------------------------  Constants  ------------------------------

;video buffer and memory constants
VIDEO_START        	equ		$ffb500                        ; Starting address
VIDEO_WIDTH         equ		480        					   ; Width in pixels
VIDEO_HEIGHT        equ		320							   ; Height in pixels
VIDEO_SIZE          equ		(VIDEO_WIDTH*VIDEO_HEIGHT/8)   ; Size in bytes
BYTE_PER_LINE     	equ		(VIDEO_WIDTH/8)
VIDEO_BUFFER		equ		(VIDEO_START-VIDEO_SIZE)

;constants for bitmap structures
WIDTH               equ		0
HEIGHT              equ		2
MATRIX              equ		4

;sprites
STATE				equ		0
X					equ		2
Y					equ		4
BITMAP1				equ		6
BITMAP2				equ		10

HIDE				equ		0
SHOW				equ		1
;----------------------------  Init  -------------------------------

					org		$0
vector_000          dc.l    VIDEO_BUFFER                    ; Initial value of A7
vector_001          dc.l    Main

;----------------------------  Main  -------------------------------

					org		$500
					
Main				lea		Invader,a1

					jsr		PrintSprite
					jsr		BufferToScreen
					
					illegal


;-------------------------  Subroutines  ---------------------------

FillScreen			movem.l a0/d1,-(a7)
					move.l	#VIDEO_BUFFER,a0
					move.l	#VIDEO_SIZE,d1
					
\loop				move.l	d0,(a0)+
					subq.l	#4,d1
					bne		\loop
					
					movem.l	(a7)+,a0/d1
					rts
					
					
ClearScreen			move.l	d0,-(a7)
					moveq.l	#$0,d0
					jsr     FillScreen

					move.l	(a7)+,d0
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
;<-	a1.l - address of the pixel
;<-	d0.w - offset of the pixels
PixelToAdress		movem.l	d2/d1,-(a7)
					andi.l	#$0000ffff,d1
					
					mulu.w	#BYTE_PER_LINE,d2
					divu.w	#8,d1
					add.w	d1,d2
					swap	d1
					move.w	d1,d0
					movea.l	#VIDEO_BUFFER,a1
					adda.w	d2,a1

					movem.l	(a7)+,d2/d1
					rts
					
;->	a0.l - address of the bitmap
;->	d1.w - abscissa in pixels	(x coordinate)
;->	d2.w - ordinate in pixels	(y coordinate)
PrintBitmap			jsr		PixelToAdress
					jsr		CopyBitmap
					
					rts
					
					
BufferToScreen		movem.l	a0/a1,-(a7)
					lea		VIDEO_START,a1
					lea		VIDEO_BUFFER,a0
					
\loop				move.l	(a0),(a1)+
					move.l	#0,(a0)+
					
					cmpa.l	#VIDEO_START,a0
					bne		\loop
					
					movem.l	(a7)+,a0/a1
					rts
					
;->	a1.l - address of the sprite					
PrintSprite			move.l	a1,-(a7)
					tst.w	STATE(a1)
					beq		\skip
					move.w	X(a1),d1
					move.w	Y(a1),d2
					movea.l	BITMAP1(a1),a0
					
					jsr		PrintBitmap
\skip				move.l	(a7)+,a1
					rts
					

;------------------------------ DATA -------------------------------		


Invader				dc.w	HIDE
					dc.w	0,152			;coordinates
					dc.l	InvaderA_Bitmap
					dc.l	0

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
