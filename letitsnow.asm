	nam	letitsnow
	ttl	Let it snow!

PIA0D0	equ	$ff00		CoCo hardware definitions
PIA0C0	equ	$ff01
PIA0D1	equ	$ff02
PIA0C1	equ	$ff03

PIA1D0	equ	$ff20
PIA1C0	equ	$ff21
PIA1D1	equ	$ff22
PIA1C1	equ	$ff23

VBASE	equ	$0400
VSIZE	equ	$0c00
VEXTNT	equ	(2*VSIZE)

START	equ	(VBASE+VEXTNT)

	org	START

hwinit	orcc	#$50		disable IRQ and FIRQ

	clr	$ffc0		clr v0
	clr	$ffc2		clr v1
	clr	$ffc5		set v2
	lda	#$c8		g3c, css=1
	sta	$ff22		setup vdg

	jsr	clrscrn		clear video buffers

	ldb	PIA0C0		disable hsync interrupt generation
	andb	#$fc
	stb	PIA0C0
	tst	PIA0D0
	lda	PIA0C1		enable vsync interrupt generation
	ora	#$01
	sta	PIA0C1
	tst	PIA0D1
	sync			wait for vsync interrupt

	lda	#$01		init video field indicator
	sta	vfield

vblank	tst	PIA0D1
	sync			wait for vsync interrupt

	dec	vfield		flip video field indicator
	bne	vblank1

	clr	$ffc9		set video base to $0400
	clr	$ffcc

	bra	vwork

vblank1	lda	#$01		reset video field indicator
	sta	vfield

	clr	$ffc8		set video base to $1000
	clr	$ffcd

vwork

	ifdef MON09
* Check for user break (development only)
chkuart	lda	$ff69		Check for serial port activity
	bita	#$08
	beq	vloop
	lda	$ff68
	jmp	[$fffe]		Re-enter monitor
	endif

vloop	jmp	vblank

*
* clrscrn -- clear both video fields to the background color
*
*	D,X clobbered
*
clrscrn	ldx	#VBASE
	clra
	clrb
clsloop	std	,x++
	cmpx	#(VBASE+VEXTNT)
	blt	clsloop
	rts

*
* Data Declarations
*
vfield	rmb	1

	org	$0608
snowman:
	fcb	$05,$40
	org	$0628
	fcb	$19,$90
	org	$0648
	fcb	$15,$50
	org	$0668
	fcb	$56,$94
	org	$0688
	fcb	$59,$64
	org	$06a8
	fcb	$15,$50

	org	$0a18
xmastree:
	fcb	$01,$00
	org	$0a38
	fcb	$05,$40
	org	$0a58
	fcb	$15,$50
	org	$0a78
	fcb	$55,$54
	org	$0a98
	fcb	$03,$00
	org	$0ab8
	fcb	$03,$00

	org	$0798
baretree:
	fcb	$00,$80
	org	$07b8
	fcb	$83,$00
	org	$07d8
	fcb	$3B,$F8
	org	$07f8
	fcb	$0E,$00
	org	$0818
	fcb	$0B,$00
	org	$0838
	fcb	$0E,$00
