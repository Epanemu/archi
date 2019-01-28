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

;Keyboard
SPACE_KEY			equ		$420
LEFT_KEY			equ		$46F
UP_KEY				equ		$470
RIGHT_KEY			equ		$471
DOWN_KEY			equ		$472

;----------------------------  Init  -------------------------------

					org		$0
vector_000          dc.l    VIDEO_BUFFER                    ; Initial value of A7
vector_001          dc.l    Main

;----------------------------  Main  -------------------------------

					org		$500
					
Main				lea		Invader,a1

					move.w	#1,d1
					move.w	#1,d2

\loop				jsr		PrintSprite
					jsr		BufferToScreen
					
					jsr		MoveSpriteKeyboard
					bra		\loop
					
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
PrintSprite			movem.l	a1/d1/d2,-(a7)
					tst.w	STATE(a1)
					beq		\skip
					move.w	X(a1),d1
					move.w	Y(a1),d2
					movea.l	BITMAP1(a1),a0
					
					jsr		PrintBitmap
\skip				movem.l	(a7)+,a1/d1/d2
					rts
					
;->	a0.l - address of a bitamp
;->	d1.w - X offset of a bitamp in px
;<-	Z	 - true if out of bounds
IsOutOfX			move.l	d0,-(a7)
					
					tst.w	d1
					bmi		\out_of_bounds
					
					move.w	WIDTH(a0),d0
					add.w	d1,d0
					cmp.w	#VIDEO_WIDTH,d0
					bgt		\out_of_bounds
					
\in_bounds			move.l	(a7)+,d0
					andi.b	#%11111011,ccr
					rts
					
\out_of_bounds		move.l	(a7)+,d0
					ori.b	#%00000100,ccr
					rts

;->	a0.l - address of a bitamp
;->	d2.w - Y offset of a bitamp in px
;<-	Z	 - true if out of bounds
IsOutOfY			move.l	d0,-(a7)
					
					tst.w	d2
					bmi		\out_of_bounds
					
					move.w	HEIGHT(a0),d0
					add.w	d2,d0
					cmp.w	#VIDEO_HEIGHT,d0
					bgt		\out_of_bounds
					
\in_bounds			move.l	(a7)+,d0
					andi.b	#%11111011,ccr
					rts
					
\out_of_bounds		move.l	(a7)+,d0
					ori.b	#%00000100,ccr
					rts
					
;->	a0.l - address of a bitamp
;->	d1.w - X offset of a bitamp in px
;->	d2.w - Y offset of a bitamp in px
;<-	Z	 - true if out of bounds
IsOutOfScreen		jsr		IsOutOfX
					beq		\quit
					jsr		IsOutOfY
\quit				rts

;->	a1.l - address of a sprite
;->	d1.w - relative displacement on the X axis
;->	d2.w - relative displacement on the Y axis
;<-	Z	 - false if not moved - out of bounds
MoveSprite			movem.l	d1/d2,-(a7)
					
					add.w	X(a1),d1
					add.w	Y(a1),d2
					jsr		IsOutOfScreen
					bne		\movement
					
\cant_move			andi.b	#%11111011,ccr
					bra		\quit
					
\movement			move.w	d1,X(a1)
					move.w	d2,Y(a1)
					ori.b	#%00000100,ccr
					
\quit				movem.l	(a7)+,d1/d2
					rts
					
;->	a1.l - address of a sprite	
MoveSpriteKeyboard	movem.l	d1/d2,-(a7)
					
					clr.w	d1
					clr.w	d2
					
					tst.b	(LEFT_KEY)
					beq		\skip_left
					addi.w	#-1,d1
					
\skip_left			tst.b	(RIGHT_KEY)
					beq		\skip_right
					addi.w	#1,d1
					
\skip_right			tst.b	(UP_KEY)
					beq		\skip_up
					addi.w	#-1,d2
					
\skip_up			tst.b	(DOWN_KEY)
					beq		\skip_down
					addi.w	#1,d2
					
\skip_down			jsr		MoveSprite
					
					movem.l	(a7)+,d1/d2
					rts
;------------------------------ DATA -------------------------------		


Invader				dc.w	SHOW
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
