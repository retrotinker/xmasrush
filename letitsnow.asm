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

bgsetup	jsr	clrscrn		clear video buffers

	ldx	#$208		point to offset for snowman
	ldu	#snowman	point to data for snowman
	jsr	tiledrw

	ldx	#$618		point to offset for xmas tree
	ldu	#xmstree	point to data for xmas tree
	jsr	tiledrw

	ldx	#$398		point to offset for bare tree
	ldu	#bartree	point to data for bare tree
	jsr	tiledrw

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
* tiledrw -- draw background tile on both video fields
*
*	X -- offset of tile destination
*	U -- pointer to tile data
*
*	D,X,Y clobbered
*
tiledrw	leax	VBASE+64,x
	leay	VSIZE,x
	pulu	d
	std	-64,x
	std	-64,y
	pulu	d
	std	-32,x
	std	-32,y
	pulu	d
	std	,x
	std	,y
	pulu	d
	std	32,x
	std	32,y
	pulu	d
	std	64,x
	std	64,y
	pulu	d
	std	96,x
	std	96,y
	rts

*
* Data Declarations
*
snowman	fcb	$05,$40
	fcb	$19,$90
	fcb	$15,$50
	fcb	$56,$94
	fcb	$59,$64
	fcb	$15,$50

xmstree	fcb	$01,$00
	fcb	$05,$40
	fcb	$15,$50
	fcb	$55,$54
	fcb	$03,$00
	fcb	$03,$00

bartree	fcb	$00,$80
	fcb	$83,$00
	fcb	$3B,$F8
	fcb	$0E,$00
	fcb	$0B,$00
	fcb	$0E,$00

*
* Variable Declarations
*
vfield	rmb	1
