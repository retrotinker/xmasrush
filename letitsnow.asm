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

VBASE	equ	$0e00
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

	clr	$ffc7		set video base to $0e00
	clr	$ffc9
	clr	$ffcb
	clr	$ffcc
	clr	$ffce
	clr	$ffd0
	clr	$ffd2

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

	ldx	#$618		point to offset for xmas tree
	ldu	#xmstree	point to data for xmas tree
	jsr	tiledrw

	ldx	#$018		point to offset for bare tree
	ldu	#bartree	point to data for bare tree
	jsr	tiledrw

	ldx	#$033		point to offset for bare tree
	ldu	#bartree	point to data for bare tree
	jsr	tiledrw

	ldx	#$044		point to offset for bare tree
	ldu	#bartree	point to data for bare tree
	jsr	tiledrw

	ldx	#$08b		point to offset for bare tree
	ldu	#bartree	point to data for bare tree
	jsr	tiledrw

	ldx	#$0be		point to offset for bare tree
	ldu	#bartree	point to data for bare tree
	jsr	tiledrw

	ldx	#$1a5		point to offset for bare tree
	ldu	#bartree	point to data for bare tree
	jsr	tiledrw

	ldx	#$26f		point to offset for bare tree
	ldu	#bartree	point to data for bare tree
	jsr	tiledrw

	ldx	#$318		point to offset for bare tree
	ldu	#bartree	point to data for bare tree
	jsr	tiledrw

	ldx	#$350		point to offset for bare tree
	ldu	#bartree	point to data for bare tree
	jsr	tiledrw

	ldx	#$3ac		point to offset for bare tree
	ldu	#bartree	point to data for bare tree
	jsr	tiledrw

	ldx	#$567		point to offset for bare tree
	ldu	#bartree	point to data for bare tree
	jsr	tiledrw

	ldx	#$614		point to offset for bare tree
	ldu	#bartree	point to data for bare tree
	jsr	tiledrw

	ldx	#$648		point to offset for bare tree
	ldu	#bartree	point to data for bare tree
	jsr	tiledrw

	ldx	#$68e		point to offset for bare tree
	ldu	#bartree	point to data for bare tree
	jsr	tiledrw

	ldx	#$6be		point to offset for bare tree
	ldu	#bartree	point to data for bare tree
	jsr	tiledrw

	ldx	#$723		point to offset for bare tree
	ldu	#bartree	point to data for bare tree
	jsr	tiledrw

	ldx	#$86f		point to offset for bare tree
	ldu	#bartree	point to data for bare tree
	jsr	tiledrw

	ldx	#$918		point to offset for bare tree
	ldu	#bartree	point to data for bare tree
	jsr	tiledrw

	ldx	#$950		point to offset for bare tree
	ldu	#bartree	point to data for bare tree
	jsr	tiledrw

	ldx	#$9ac		point to offset for bare tree
	ldu	#bartree	point to data for bare tree
	jsr	tiledrw

	clr	erase0
	clr	erase0+1
	clr	erase1
	clr	erase1+1

	leas	-2,s
	clr	,s
	clr	1,s

vblank	tst	PIA0D1
	sync			wait for vsync interrupt

	dec	vfield		flip video field indicator
	bne	vblank1

	clr	$ffc9		reset video base to $0e00
	clr	$ffcc

	ldx	erase0		point to offset for snowman
	jsr	sprtera

	ldx	,s		point to offset for snowman
	leax	32,x
	cmpx	#$0b40
	ble	vwork1
	clr	,s
	clr	1,s
	ldx	,s

vwork1	stx	,s
	stx	erase0
	ldu	#snowman	point to data for snowman
	jsr	sprtdrw

	bra	vwork4

vblank1	lda	#$01		reset video field indicator
	sta	vfield

	clr	$ffc8		reset video base to $1a00
	clr	$ffcd

vwork2	ldx	erase1		point to offset for snowman
	jsr	sprtera

	ldx	,s		point to offset for snowman
	leax	32,x
	cmpx	#$0b40
	ble	vwork3
	clr	,s
	clr	1,s
	ldx	,s

vwork3	stx	,s
	stx	erase1
	ldu	#snowman	point to data for snowman
	jsr	sprtdrw

vwork4
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
*	D,X,Y,U clobbered
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
* sprtera -- erase sprite image on current video field
*
*	X -- offset of sprite to erase
*
*	D,X clobbered
*
sprtera	tst	vfield
	beq	sprter1
	leax	VBASE+64,x
	bra	sprter2

sprter1	leax	VBASE+VSIZE+64,x

sprter2	clra
	clrb
	std	-64,x
	std	-32,x
	std	,x
	std	32,x
	std	64,x
	std	96,x
	rts

*
* sprtdrw -- draw sprite image on current video field
*
*	X -- offset of sprite to draw
*	U -- pointer to tile data
*
*	D,X,U clobbered
*
sprtdrw	tst	vfield
	beq	sprtdr1
	leax	VBASE+64,x
	bra	sprtdr2

sprtdr1	leax	VBASE+VSIZE+64,x

sprtdr2	pulu	d
	std	-64,x
	pulu	d
	std	-32,x
	pulu	d
	std	,x
	pulu	d
	std	32,x
	pulu	d
	std	64,x
	pulu	d
	std	96,x
	pulu	d
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

erase0	rmb	2
erase1	rmb	2

	end	START
