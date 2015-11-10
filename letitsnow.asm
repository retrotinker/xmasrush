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

	jsr	plfdraw		draw the playfield

	ldx	#$675		point to offset for xmas tree
	ldu	#xmstree	point to data for xmas tree
	jsr	tiledrw

	ldx	#$1e5		point to offset for temporary snowman
	ldu	#snowman	point to data for temporary snowman
	jsr	tiledrw

	ldx	#$42e		point to offset for temporary snowman
	ldu	#snowman	point to data for temporary snowman
	jsr	tiledrw

	ldx	#$4f9		point to offset for temporary snowman
	ldu	#snowman	point to data for temporary snowman
	jsr	tiledrw

	ldx	#$90b		point to offset for temporary snowman
	ldu	#snowman	point to data for temporary snowman
	jsr	tiledrw

	clra
	clrb
	std	ersptrs
	std	ersptrs+2

	leas	-2,s
	clr	,s
	clr	1,s

vblank	tst	PIA0D1		wait for vsync interrupt
	sync

	lda	vfield		load previous field indicator

	deca			switch video field indicator
	bne	vblank1

	clr	$ffc9		reset video base to $0e00
	clr	$ffcc

	bra	vblnkex

vblank1	lda	#$01		reset video field indicator

	clr	$ffc8		reset video base to $1a00
	clr	$ffcd

vblnkex	sta	vfield		save current field indicator

*verase	lsla			convert to pointer offset
*	ldx	#ersptrs	use as offset into erase pointer array
*	ldx	a,x		retrieve erase pointer
*	jsr	sprtera		erase sprite
*
*vcalc	ldx	,s		point to offset for snowman
*	leax	32,x		advance by one line
*	cmpx	#$0b40		check for lowest offset
*	ble	vcalcex		continue if not
*	clra			otherwise, reset offset
*	clrb
*	tfr	d,x
*vcalcex	stx	,s		save current snowman offset
*
*vdraw	lda	vfield		retrieve current field indicator
*	lsla			convert to pointer offset
*	ldy	#ersptrs	use as offset into erase pointer array
*	leay	a,y		retrieve erase pointer
*	stx	,y		save snowman offset to erase pointer
*
*	ldu	#snowman	point to data for snowman
*	jsr	sprtdrw		draw snowman sprite

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
* plfdraw -- draw playfield based on plyfmap data
*
*	D,X,Y,U clobbered
*
plfdraw	ldx	#$0000		init tile offset value
	ldy	#plyfmap	init map pointer value
	lda	#$04		init map byte width counter
	pshs	a
	lda	#plyfmsz	init map size counter
	pshs	a

plfloop	lda	,y+		load next byte of map data
	ldb	#$08		init bit counter for current byte

plfloo1	asla			check for tile indicator
	bcc	plftskp

	pshs	d,x,y		save important data
	ldu	#bartree	point to data for bare tree
	jsr	tiledrw		draw bare tree tile
	puls	d,x,y		restore important data

plftskp	leax	1,x		advance tile offset

	decb			decrement bit counter
	bne	plfloo1		process data for next bit

	dec	1,s		check for end of map row
	bne	plflxck		if not move along

	lda	#$04		reset map byte widt counter
	sta	1,s

	leax	64,x		advance tile offset value two rows

plflxck	dec	,s		check for end of map data
	bne	plfloop		if not, loop

	leas	2,s		clean-up stack
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

plyfmap	fcb	10101010b,10101010b,10101010b,10101010b
	fcb	00000000b,00000000b,00000000b,00000000b
	fcb	01010100b,00000000b,00000000b,01010100b
	fcb	00000000b,00000000b,00000000b,00000000b

	fcb	10100000b,00000000b,01000000b,00001010b
	fcb	00000000b,00000000b,00000000b,00000000b
	fcb	01000000b,00100001b,00010000b,00000100b
	fcb	00000000b,10000000b,01000100b,00000000b

	fcb	10000000b,00000000b,00010001b,01000010b
	fcb	00000001b,01000000b,01000100b,00000000b
	fcb	01000100b,00010000b,00010000b,00000100b
	fcb	00000001b,01000000b,00000000b,00000000b

	fcb	10000000b,00010000b,00000000b,00000010b
	fcb	00000000b,01000000b,00000000b,00000000b
	fcb	01000000b,00000000b,00000000b,00000100b
	fcb	00000000b,00000000b,00000000b,00000000b

	fcb	10000000b,00000000b,00000000b,00000010b
	fcb	00000000b,00000000b,00000000b,00000000b
	fcb	01000000b,10000000b,00100000b,10000100b
	fcb	00000010b,00100000b,00000000b,00000000b

	fcb	10000000b,10001000b,00001000b,10000010b
	fcb	00000010b,00100000b,00000000b,00000000b
	fcb	01000000b,10000100b,00000101b,00000100b
	fcb	00000010b,00000000b,00000000b,00000000b

	fcb	10000000b,10000000b,00000010b,00000010b
	fcb	00000000b,00000000b,00000000b,00000000b
	fcb	01000000b,00000000b,00000000b,00010100b
	fcb	00000000b,00000000b,00000000b,00000000b

	fcb	10100000b,00000000b,00000000b,00101010b
	fcb	00000000b,00000000b,00000000b,00000000b
	fcb	01010101b,01000000b,00000101b,01010100b
	fcb	00000000b,00000000b,00000000b,00000000b
plyfmsz	equ	(*-plyfmap)

*
* Variable Declarations
*
vfield	rmb	1

ersptrs	rmb	4

	end	START
