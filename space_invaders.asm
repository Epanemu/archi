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

SIZE_OF_SPRITE		equ		14

;invaders
INVADER_PER_LINE	equ		10
INVADER_PER_COLUMN	equ		5
INVADER_COUNT		equ		INVADER_PER_LINE*INVADER_PER_COLUMN

INVADER_STEP_X		equ		4
INVADER_STEP_Y		equ		8
INVADER_X_MIN		equ		0
INVADER_X_MAX		equ		(VIDEO_WIDTH-(INVADER_PER_LINE*32))

SKIP_MOVE_LIMIT		equ		8

;speed constants
SHIP_STEP			equ		4
SHIP_SHOT_STEP		equ		4

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
					
Main				jsr		InitInvaders

\loop				jsr		PrintShip
					jsr		PrintShipShot
					jsr		PrintInvaders
					jsr		BufferToScreen
					
					jsr		MoveShip
					jsr 	MoveInvaders
					jsr		MoveShipShot
					
					jsr		NewShipShot
					
					bra		\loop


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
PrintBitmap			move.l	d0,-(a7)

					jsr		PixelToAdress
					jsr		CopyBitmap
					
					move.l	(a7)+,d0
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
					
					movea.l	BITMAP1(a1),a0
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
					
;->	a0.l - Address of the sprite
;<-	d1.w - Abscissa of the top left corner of the sprite (x)
;<-	d2.w - Ordinate of the top left corner of the sprite (y)
;<-	d3.w - Abscissa of the bottom right corner of the sprite (x)
;<-	d4.w - Ordinate of the bottom right corner of the sprite (y)
GetRectangle		move.l	a1,-(a7)

					move.w	X(a0),d1
					move.w	Y(a0),d2
					move.l	BITMAP1(a0),a1
					move.w	X(a0),d3
					move.w	Y(a0),d4
					add.w	WIDTH(a1),d3
					add.w	HEIGHT(a1),d4
					
					move.l	(a7)+,a1
					rts
					
;->	a1.l - Address of the first sprite
;->	a2.l - Address of the second sprite
;<-	Z 	 - true(1) if sprites are colliding
IsSpriteColliding	movem.l	d0-d7/a0,-(a7)
					
					cmpi.w	#HIDE,STATE(a1)
					beq		\false
					cmpi.w	#HIDE,STATE(a2)
					beq		\false
					
					movea.l	a1,a0
					jsr		GetRectangle	;1
					move.w	d1,d0		;left
					move.w	d2,d5		;top
					move.w	d3,d6		;right
					move.w	d4,d7		;bottom
					
					movea.l	a2,a0
					jsr		GetRectangle	;2
					
					cmp.w	d1,d6	;leftmost of 2 is to right of rightmost of 1
					ble		\false
					cmp.w	d2,d7	;top of 2 is bellow the bottom of 1
					ble		\false
					cmp.w	d3,d0	;rightmost of 2 is to left of leftmost of 1
					bge		\false
					cmp.w	d4,d5	;bottom of 2 is above the top of 1
					bge		\false
					
\true				ori.b	#%00000100,ccr
					jmp		\quit
					
\false				andi.b	#%11111011,ccr
\quit				movem.l	(a7)+,d0-d7/a0
					rts
				
				
PrintShip			move.l	a1,-(a7)
					lea		Ship,a1
					jsr		PrintSprite
					move.l	(a7)+,a1
					rts
					
					
MoveShip			movem.l	d1/d2/a1,-(a7)
					
					lea		Ship,a1
					clr.w	d1
					clr.w	d2
					
					tst.b	(LEFT_KEY)
					beq		\skip_left
					addi.w	#-SHIP_STEP,d1
					
\skip_left			tst.b	(RIGHT_KEY)
					beq		\skip_right
					addi.w	#SHIP_STEP,d1
					
\skip_right			jsr		MoveSprite
					
					movem.l	(a7)+,d1/d2/a1
					rts
					
					
PrintShipShot		move.l	a1,-(a7)
					lea		ShipShot,a1
					jsr		PrintSprite
					move.l	(a7)+,a1
					rts
					
					
MoveShipShot		movem.l	d1/d2/a1,-(a7)

					lea		ShipShot,a1
					cmp.w	#HIDE,STATE(a1)
					beq		\quit
					
					cmp.w	#SHIP_SHOT_STEP,Y(a1)
					bge		\continue
					move.w	#HIDE,STATE(a1)		
					jmp		\quit
				
\continue			clr.w	d1
					move.w	#-SHIP_SHOT_STEP,d2
					
					jsr		MoveSprite
					
\quit				movem.l	(a7)+,d1/d2/a1
					rts
					
					
NewShipShot			movem.l	a1/a2/d1/d2/d3,-(a7)
					
					tst.b	(SPACE_KEY)
					beq		\quit
					
					lea		ShipShot,a1
					cmp.w	#SHOW,STATE(a1)
					beq		\quit
					
					move.w	#SHOW,STATE(a1)
					
					lea		Ship,a2
					
					;width and height
					move.w	X(a2),d1
					move.w	Y(a2),d2
					
					movea.l	BITMAP1(a2),a2
					move.w	WIDTH(a2),d3
					divs.w	#2,d3
					add.w	d3,d1
					
					movea.l	BITMAP1(a1),a1
					move.w	WIDTH(a1),d3
					divs.w	#2,d3
					sub.w	d3,d1
					move.w	HEIGHT(a1),d3
					sub.w	d3,d2
					
					lea		ShipShot,a1
					move.w	d1,X(a1)
					move.w	d2,Y(a1)
					
\quit				movem.l	(a7)+,a1/a2/d1/d2/d3
					rts
					
;->	d1.w - x position of the top left corner
;->	d2.w - y position of the top left corner
;->	a0.l - address of the structure of the first invader in the line
;->	a1.l - address of the first bitmap of the invaders
;->	a2.l - address of the second bitmap of the invaders
InitInvaderLine		movem.l	a0/d0-d3,-(a7)

					move.w	#INVADER_PER_LINE,d3
					move.w	#32,d0
					sub.w	WIDTH(a1),d0
					divs.w	#2,d0
					add.w	d0,d1
					
\loop				move.w	#SHOW,STATE(a0)
					move.w	d1,X(a0)
					move.w	d2,Y(a0)
					move.l	a1,BITMAP1(a0)
					move.l	a2,BITMAP2(a0)
					
					add.w	#32,d1
					add.l	#SIZE_OF_SPRITE,a0
					
					subi.w	#1,d3
					tst.w	d3
					bne		\loop
					
					movem.l	(a7)+,a0/d0-d3
					rts
				
				
InitInvaders		movem.l	a0/d0-d2,-(a7)

					move.w	(InvaderX),d1
					move.w	(InvaderY),d2
					lea		Invaders,a0
					
					lea		InvaderC_Bitmap,a1
					lea		0,a2
					
					jsr		InitInvaderLine
					add.l	#(INVADER_PER_LINE*SIZE_OF_SPRITE),a0
					add.w	#32,d2
					
					move.w	#1,d0
					lea		InvaderB_Bitmap,a1
					lea		0,a2
					
\Bloop				jsr		InitInvaderLine
					add.l	#(INVADER_PER_LINE*SIZE_OF_SPRITE),a0
					add.w	#32,d2
					dbra	d0,\Bloop
					
					move.w	#1,d0
					lea		InvaderA_Bitmap,a1
					lea		0,a2
					
\Aloop				jsr		InitInvaderLine
					add.l	#(INVADER_PER_LINE*SIZE_OF_SPRITE),a0
					add.w	#32,d2
					dbra	d0,\Aloop
					
					movem.l	(a7)+,a0/d0-d2
					rts
					
					
PrintInvaders		movem.l	d0/a1,-(a7)
					
					move.w	#INVADER_COUNT,d0
					lea		Invaders,a1
					
\loop				jsr		PrintSprite
					add.l	#SIZE_OF_SPRITE,a1
					subi.w	#1,d0
					tst.w	d0
					bne		\loop
					
					movem.l	(a7)+,d0/a1
					rts
					
;<-	d1.w - horizontal displacement of the top left corner (change of X)
;<-	d2.w - vertical displacement of the top left corner (change of Y)
GetInvaderStep		move.w 	(InvaderX),d1
					add.w	(InvaderCurrentStep),d1
					
					cmpi.w	#INVADER_X_MAX,d1
					bgt		\out
					
					cmpi.w	#INVADER_X_MIN,d1
					blt		\out
					
					move.w	d1,(InvaderX)
					move.w	(InvaderCurrentStep),d1
					move.w	#0,d2
					bra		\quit

\out				neg.w	(InvaderCurrentStep)
					add.w	#INVADER_STEP_Y,(InvaderY)
					move.w	#0,d1
					move.w	#INVADER_STEP_Y,d2
					
\quit				rts


MoveAllInvaders		movem.l	d0-d2/a1,-(a7)
					
					jsr		GetInvaderStep
					
					move.w	#INVADER_COUNT,d0
					lea		Invaders,a1
					
\loop				cmpi.w	#SHOW,STATE(a1)
					bne		\skip
					jsr		MoveSprite
\skip				add.l	#SIZE_OF_SPRITE,a1
					subi.w	#1,d0
					tst.w	d0
					bne		\loop
					
					movem.l	(a7)+,d0-d2/a1
					rts
					

MoveInvaders		move.l	d1,-(a7)
					
					add.w	#1,(InvaderSkipMove)
					cmpi.w	#SKIP_MOVE_LIMIT,(InvaderSkipMove)
					blt		\quit
					jsr		MoveAllInvaders
					move.w	#0,(InvaderSkipMove)
					
\quit				move.l	(a7)+,d1
					rts
					

;------------------------------ DATA -------------------------------		

;Invaders

Invaders			ds.b	INVADER_COUNT*SIZE_OF_SPRITE

InvaderX			dc.w	(VIDEO_WIDTH-(INVADER_PER_LINE*32))/2
InvaderY			dc.w	32
InvaderCurrentStep	dc.w	INVADER_STEP_X

InvaderSkipMove		dc.w	SKIP_MOVE_LIMIT

;Other sprites
					
Ship				dc.w	SHOW
					dc.w	(VIDEO_WIDTH-24)/2,VIDEO_HEIGHT-32
					dc.l	Ship_Bitmap
					dc.l	0

ShipShot			dc.w	HIDE
					dc.w	0,0
					dc.l	ShipShot_Bitmap
					dc.l	0

;Bitmaps

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
					
ShipShot_Bitmap		dc.w	2,6
					dc.b    %11000000
					dc.b    %11000000
					dc.b    %11000000
					dc.b    %11000000
					dc.b    %11000000
					dc.b    %11000000
