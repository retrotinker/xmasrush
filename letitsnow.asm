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

INPUTRT	equ	$01
INPUTLT	equ	$02
INPUTUP	equ	$04
INPUTDN	equ	$08
INPUTBT	equ	$10

INMVMSK	equ	$0f		mask of movement bits

GMFXMTR	equ	$01
GMFSNW1	equ	$02
GMFSNW2	equ	$04
GMFSNW3	equ	$08
GMFSNW4	equ	$10

MVDLRST	equ	$08		reset value for movement delay counter

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
	sta	PIA1D1		setup vdg

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

	jsr	bgcmini		init background collision map

	ldd	#$0f1e
	std	playpos
	std	ersary0
	std	ersary1

	lda	#$01		preset movement delay counter
	sta	mvdlcnt

	ldd	#$1511		point to grid offset for xmas tree
	std	xmstpos
	std	ersary0+10
	std	ersary1+10

	ldd	#$0505		point to grid offset for snowman 1 start
	std	snw1pos
	std	ersary0+8
	std	ersary1+8

	ldd	#$0e0b		point to grid offset for snowman 2 start
	std	snw2pos
	std	ersary0+6
	std	ersary1+6

	ldd	#$190d		point to grid offset for snowman 3 start
	std	snw3pos
	std	ersary0+4
	std	ersary1+4

	ldd	#$0b18		point to grid offset for snowman 4 start
	std	snw4pos
	std	ersary0+2
	std	ersary1+2

	lda	#(GMFXMTR+GMFSNW1+GMFSNW2+GMFSNW3+GMFSNW4)
	sta	gamflgs

vblank	tst	PIA0D1		wait for vsync interrupt
	sync

	lda	#$08		restore CSS for BCMO colors
	ora	PIA1D1
	sta	PIA1D1

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

verase	lsla			convert to pointer offset
	ldy	#ersptrs	use as offset into erase pointer array
	ldy	a,y		retrieve pointer to base of erase offset array

	ldd	,y		retreive erase grid offset
	jsr	sprtera		erase sprite

	ldd	2,y		retreive erase grid offset
	jsr	sprtera		erase sprite

	ldd	4,y		retreive erase grid offset
	jsr	sprtera		erase sprite

	ldd	6,y		retreive erase grid offset
	jsr	sprtera		erase sprite

	ldd	8,y		retreive erase grid offset
	jsr	sprtera		erase sprite

	ldd	10,y		retreive erase grid offset
	jsr	sprtera		erase sprite

vdraw	lda	#GMFXMTR
	bita	gamflgs
	beq	vdraw1

	ldd	xmstpos		point to grid offset for xmas tree
	std	10,y		save xmas tree grid offset to erase pointer
	ldu	#xmstree	point to data for xmas tree
	jsr	sprtdrw

vdraw1	lda	#GMFSNW1
	bita	gamflgs
	beq	vdraw2

	ldd	snw1pos		point to grid offset for snowman 1
	std	8,y		save snowman grid offset to erase pointer
	ldu	#snowman	point to data for snowman
	jsr	sprtdrw

vdraw2	lda	#GMFSNW2
	bita	gamflgs
	beq	vdraw3

	ldd	snw2pos		point to grid offset for snowman 2
	std	6,y		save snowman grid offset to erase pointer
	ldu	#snowman	point to data for snowman
	jsr	sprtdrw

vdraw3	lda	#GMFSNW3
	bita	gamflgs
	beq	vdraw4

	ldd	snw3pos		point to grid offset for snowman 3
	std	4,y		save snowman grid offset to erase pointer
	ldu	#snowman	point to data for snowman
	jsr	sprtdrw

vdraw4	lda	#GMFSNW4
	bita	gamflgs
	beq	vdraw5

	ldd	snw4pos		point to grid offset for snowman 4
	std	2,y		save snowman grid offset to erase pointer
	ldu	#snowman	point to data for snowman
	jsr	sprtdrw

vdraw5	ldd	playpos		get player grid offset
	std	,y		save player grid offset to erase pointer
	ldu	#player		retrieve player graphic pointer
	jsr	sprtdrw		draw snowman sprite

vcalc	jsr	inpread		read player input for next frame

	ldd	#player		use default player graphic
	std	,s

	ldd	playpos		copy player position for movement check
	pshs	d

	ldb	inpflgs		check for any indication of movement
	andb	#INMVMSK
	beq	vcalc4

	dec	mvdlcnt		decrement movement delay counter
	bne	vcalc4

	lda	#MVDLRST	reset movement delay counter
	sta	mvdlcnt

	ldb	inpflgs		test for movement right
	andb	#INPUTRT
	beq	vcalc1
	ldb	#$1e		enforce boundaries
	cmpb	,s
	beq	vcalc1
	inc	,s		indicate right by altering position

vcalc1	ldb	inpflgs		test for movement left
	andb	#INPUTLT
	beq	vcalc2
	tst	,s		enforce boundaries
	beq	vcalc2
	dec	,s		indicate left by altering position

vcalc2	ldb	inpflgs		test for movement down
	andb	#INPUTDN
	beq	vcalc3
	ldb	#$1e		enforce boundaries
	cmpb	1,s
	beq	vcalc3
	inc	1,s		indicate down by altering position

vcalc3	ldb	inpflgs		test for movement up
	andb	#INPUTUP
	beq	vcalc4
	tst	1,s		enforce boundaries
	beq	vcalc4
	dec	1,s		indicate up by altering position

vcalc4	ldb	inpflgs		test for button push
	andb	#INPUTBT
	beq	vcalc5
	jmp	START

vcalc5	ldd	,s		check for pending collision
	jsr	bgcolck

	bcc	vcalc6		if collision, don't move
	leas	2,s

	lda	#$f7		also, flash the screen (w/ CSS change)
	anda	PIA1D1
	sta	PIA1D1

	bra	vcalc7

vcalc6	puls	d		allow movement
	std	playpos

vcalc7	equ	*

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
* inpread -- read joystick input
*
*	D clobbered
*
inpread	clrb

	lda	PIA0D0		read from the PIA connected to the joystick buttons
	bita	#$02		test for left joystick button press
	bne	inprdrl
	ldb	#INPUTBT

inprdrl	lda	#$34		read r/l axis of left joystick
	sta	PIA0C0
	lda	#$3d
	sta	PIA0C1

	lda	#$65		test for low value on selected axis
	sta	PIA1D0
	nop
	nop
	tst	PIA0D0
	bpl	inprdlt

	lda	#$98		test for high value on selected axis
	sta	PIA1D0
	nop
	nop
	tst	PIA0D0
	bpl	inprdud

inprdrt	orb	#INPUTRT	joystick points right
	bra	inprdud

inprdlt	orb	#INPUTLT	joystick points left

inprdud	lda	#$3c		read u/d axis of left joystick
	sta	PIA0C0

	lda	#$65		test for low value on selected axis
	sta	PIA1D0
	nop
	nop
	tst	PIA0D0
	bpl	inprdup

	lda	#$98		test for high value on selected axis
	sta	PIA1D0
	nop
	nop
	tst	PIA0D0
	bpl	inprdex

inprddn	orb	#INPUTDN	joystick points down
	bra	inprdex

inprdup	orb	#INPUTUP	joystick points up

inprdex	stb	inpflgs
	rts

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
* bgcmini -- init background collision map
*
*	D,X,Y clobbered
*
bgcmini	ldx	#plyfmap
	lda	#plyfmsz	init map size counter
	pshs	a

	ldy	#bgclmap
bginilp	clr	,y+
	deca
	bne	bginilp
	ldy	#bgclmap

bgcloop	pshs	a
	clrb

	lda	,x+
	pshs	a
	lsra
	rorb
	ora	,s+

	ora	,s+
	sta	4,y

	ora	,y
	sta	,y+
	tfr	b,a

	dec	,s
	bne	bgcloop

	leas	1,s
	rts

*
* bgcolck -- check for collision with background
*
*	D -- x- and y-coordinate (in A and B)
*
*	D,X clobbered
*
bgcolck	pshs	a		save x-offset

	lslb			transform x- and y-offset to pointer
	lslb
	ldx	#bgclmap
	leax	b,x
	lsra
	lsra
	lsra
	leax	a,x

	puls	a		use x-offset to build bitmask
	anda	#$07
	inca
	ldb	#$c0		two bits wide for tile/sprite size

bgclck1	deca
	beq	bgclck2
	lsrb
	bra	bgclck1

bgclck2	bitb	,x		check bitmask against collision map
	bne	bgclckx			at each relevant position
	bitb	4,x
	bne	bgclckx
	cmpb	#$01
	bne	bgclck3
	ldb	#$80
	bitb	1,x
	bne	bgclckx
	bitb	5,x
	bne	bgclckx

bgclck3	andcc	#$fe		clear carry on no collision
	rts

bgclckx	orcc	#$01		set carry on collision
	rts

*
* cvtpos -- convert grid position to screen offset
*
*	D -- x- and y-coordinate (in A and B)
*
cvtpos	pshs	a,b
	exg	a,b
	clrb
	lsra
	rorb
	adda	1,s
	lsra
	rorb
	lsra
	rorb
	orb	,s
	leas	2,s
	rts

*
* tiledrw -- draw background tile on both video fields
*
*	D -- x- and y-coordinate (in A and B)
*	U -- pointer to tile data
*
*	D,X,Y,U clobbered
*
tiledrw	jsr	cvtpos
	tfr	d,x
	leax	VBASE+64,x
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
*	D -- x- and y-coordinate (in A and B)
*
*	D,X clobbered
*
sprtera	jsr	cvtpos
	tfr	d,x
	tst	vfield
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
*	D -- x- and y-coordinate (in A and B)
*	U -- pointer to tile data
*
*	D,X,U clobbered
*
sprtdrw	jsr	cvtpos
	tfr	d,x
	tst	vfield
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
plfdraw	ldy	#plyfmap	init map pointer value
	leas	-2,s		init x- and y- coordinates
	clr	1,s
	clr	,s
	lda	#$04		init map byte width counter
	pshs	a
	lda	#plyfmsz	init map size counter
	pshs	a

plfloop	lda	,y+		load next byte of map data
	ldb	#$08		init bit counter for current byte

plfloo1	asla			check for tile indicator
	bcc	plftskp

	pshs	d,x,y		save important data
	ldd	8,s		retrieve current x- and y-pos
	ldu	#bartree	point to data for bare tree
	jsr	tiledrw		draw bare tree tile
	puls	d,x,y		restore important data

plftskp	inc	2,s		advance x-pos

	decb			decrement bit counter
	bne	plfloo1		process data for next bit

	dec	1,s		check for end of map row
	bne	plflxck		if not move along

	lda	#$04		reset map byte widt counter
	sta	1,s

	clr	2,s		reset x-pos
	inc	3,s		advance y-pos

plflxck	dec	,s		check for end of map data
	bne	plfloop		if not, loop

	leas	4,s		clean-up stack
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

player	fcb	00000010b,00000000b
	fcb	00101010b,10100000b
	fcb	00100010b,00100000b
	fcb	00000010b,00000000b
	fcb	00001000b,10000000b
	fcb	00101000b,10100000b

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

ersptrs	fdb	ersary0,ersary1

*
* Variable Declarations
*
vfield	rmb	1

inpflgs	rmb	1
gamflgs	rmb	1

ersary0	rmb	12
ersary1	rmb	12

mvdlcnt	rmb	1

bgclmap	rmb	plyfmsz

playpos	rmb	2
xmstpos	rmb	2

snw1pos	rmb	2
snw2pos	rmb	2
snw3pos	rmb	2
snw4pos	rmb	2

	end	START
