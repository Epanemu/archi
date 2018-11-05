;---------------- VECTORS ------------------- 

					org		$0

v0					dc.l	$ffb500
v1					dc.l 	Main


;------------------ MAIN --------------------

Main				org		$500

					move.l	#$123,d1
					move.l	#$123,a1
					move.l	#$123,a2

					movea.l	#TestExpression2,A0
					jsr		GetExpr
					
					illegal
					
;-------------- SUBROUTINES -----------------

Uitoa				movem.l	A0/D0/D1,-(A7)
					
					move.l	#0,-(A7)
\loop_div			andi.l	#$ffff,D0
					divu.w	#10,D0
					swap	D0
					move.l	#'0',D1
					add.w	D0,D1
					move.w	D1,-(A7)
					swap	D0
					tst.w	D0
					bne		\loop_div
					
\write				move.w	(A7)+,D0
					move.b	D0,(A0)+
					bne		\write
					
					movem.l	(A7)+,D0/A0
					rts							



GetExpr				movem.l	A0/D2/D1,-(A7)

					clr.l	D1

\loop				jsr		GetNum
					bne		\false

					; last operation
\addition			cmpi.b	#'+',D2
					bne		\substracion
					add.l	D0,D1
					jmp 	\next
					
\substracion		cmpi.b	#'-',D2
					bne		\multiplication
					sub.l	D0,D1
					jmp 	\next
					
\multiplication		cmpi.b	#'*',D2
					bne		\division
					muls	D0,D1
					jmp 	\next
					
\division			cmpi.b	#'/',D2
					bne		\setD1		; no operation, can only happen in the begining
					tst.l	D0
					beq		\false
					divs.w	D0,D1
					ext.l	D1 
					jmp		\next
					
\setD1				move.l	D0,D1
					
\next				move.b	(A0)+,D2
					tst.b	D2			; save operator
					bne		\loop
						
					move.l	D1,D0				

\true				movem.l	(A7)+,A0/D2/D1
					ori.b	#%00000100,ccr
					rts

\false				movem.l	(A7)+,A0/D2/D1
					andi.b	#%11111011,ccr
					rts



GetNum				movem.l	A1/A2/D1,-(A7)
					move.l	A0,A1
					
					jsr		NextOp
					move.b	(A0),D1
					move.b	#0,(A0)
					move.l	A0,A2
					move.l	A1,A0

					jsr		Convert
					bne		\false

\true				move.l	A2,A0
					move.b	D1,(A2)
					movem.l	(A7)+,A1/A2/D1
					ori.b	#%00000100,ccr
					rts
					
\false				move.b	D1,(A2)
					move.l	A1,A0			;recover A0
					movem.l	(A7)+,A1/A2/D1
					andi.b	#%11111011,ccr
					rts


;				COPIED PART - to remake

Convert				tst.b	(A0)
					beq		\false
					
					jsr		IsCharError
					beq		\false

					jsr		IsMaxError
					beq		\false
					
					jsr		Atoui
					
					ori.b	#%00000100,ccr
					rts
					
\false				andi.b	#%11111011,ccr
					rts


Print				movem.l	D0/D1/A0,-(A7)

\loop				move.b	(A0)+,D0
					beq		\quit
					
					jsr		PrintChar
					
					addq.b	#1,D1
					bra 	\loop
					
\quit				movem.l	(A7)+,D0/D1/A0
					rts
					
					
PrintChar           incbin	"PrintChar.bin"
					
					
					
NextOp				tst.b	(a0)
					beq		\quit
					
					cmpi.b	#'+',(A0)
					beq		\quit
					
					cmpi.b	#'-',(A0)
					beq		\quit
					
					cmpi.b	#'*',(A0)
					beq		\quit
					
					cmpi.b	#'/',(A0)
					beq		\quit
					
					addq.l	#1,A0
					bra		NextOp
					
\quit				rts
					


Atoui				movem.l	d1/a0,-(a7)
					clr.l	d0
					clr.l	d1
					
\loop				move.b	(a0)+,d1
					beq		\quit
					subi	#'0',d1
					mulu.w	#10,d0
					add.l	d1,d0
					
					bra 	\loop

\quit				movem.l	(A7)+,d1/a0
					rts

;				END OF COPIED PART


RemoveSpace			movem.l	A0/A1,-(A7)

					move.l	A0,A1
\loop				cmpi.b	#' ',(A0)+
					beq		\loop
					move.b	-1(A0),(A1)+
					tst.b	(A1)
					bne		\loop
					
					movem.l	(A7)+,A0/A1
					rts



IsCharError			move.l	A0,-(A7)

\loop				cmpi.b	#'0',(A0)
					blo		\true
					cmpi.b	#'9',(A0)+
					bhi		\true
					tst.b	(A0)
					bne		\loop
					
\false				andi.b	#%11111011,ccr
					bra		\quit
										
\true				ori.b	#%00000100,ccr
					
\quit				move.l	(A7)+,A0
					rts



IsMaxError			move.l	D0,-(A7)

					jsr		StrLen
					cmpi.l	#5,D0
					blt		\false
					bgt		\true
					
					cmpi.b	#'3',(A0)
					bhi		\true
					cmpi.b	#'2',1(A0)
					bhi		\true
					cmpi.b	#'7',2(A0)
					bhi		\true
					cmpi.b	#'6',3(A0)
					bhi		\true
					cmpi.b	#'7',4(A0)
					bhi		\true
					
\false				move.l	(A7)+,D0					
					andi.b	#%11111011,ccr
					bra		\quit
					
\true				move.l	(A7)+,D0					
					ori.b	#%00000100,ccr

\quit				rts
					



StrLen				move.l	A0,-(A7)
					clr.l	D0

\loop				tst.b	(A0)+
					beq		\quit
					addq.l	#1,D0
					bra		\loop

\quit				movea.l	(A7)+,A0
					rts

;------------------ DATA --------------------

					org		$1000

ExpressionString	ds.b	40

TestExpression		dc.b	"213+154*4",0
TestExpression2		dc.b	"104+9*2-30/13",0

TestString			dc.b	" 5 +  12",0

TestNumber			dc.b	"512",0
TestNotNumber		dc.b	"52d12",0

TestHighNumber		dc.b	"32800",0
TestHigherNumber	dc.b	"456454",0
TestOkNumber		dc.b	"5466",0
