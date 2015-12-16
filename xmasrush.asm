	nam	letitsnow
	ttl	Let it snow!

TIMVAL	equ	$0112		Extended BASIC's free-running time counter

PIA0D0	equ	$ff00		CoCo hardware definitions
PIA0C0	equ	$ff01
PIA0D1	equ	$ff02
PIA0C1	equ	$ff03

PIA1D0	equ	$ff20
PIA1C0	equ	$ff21
PIA1D1	equ	$ff22
PIA1C1	equ	$ff23

INPUTRT	equ	$01		input bit flag definitions
INPUTLT	equ	$02
INPUTUP	equ	$04
INPUTDN	equ	$08
INPUTBT	equ	$10

INMVMSK	equ	$0f		mask of movement bits

GMFXMTR	equ	$01		game status bit flag definitions
GMFSNW1	equ	$02
GMFSNW2	equ	$04
GMFSNW3	equ	$08
GMFSNW4	equ	$10

MVDLRST	equ	$08		reset value for movement delay counter
SNMDRST	equ	$10		reset value for snowman move delay counter

TXTBASE	equ	$0400		memory map-related definitions
VBASE	equ	$0e00
VSIZE	equ	$0c00
VEXTNT	equ	(2*VSIZE)

IS1BASE	equ	(TXTBASE+5*32+3)	string display location info
IS2BASE	equ	(TXTBASE+6*32+3)
IS3BASE	equ	(TXTBASE+7*32+3)
IS4BASE	equ	(TXTBASE+10*32+10)

ATSTBAS	equ	(TXTBASE+4*32+10)
SZSTBAS	equ	(TXTBASE+6*32+10)
ESSTBAS	equ	(TXTBASE+8*32+10)
CLSTBAS	equ	(TXTBASE+13*32+6)
BRSTBAS	equ	(TXTBASE+14*32+8)

PLAYPOS	equ	(TXTBASE+(10*32)+24)

START	equ	(VBASE+VEXTNT)

	org	START

	sts	savestk		save status for return to Color BASIC
	pshs	cc
	puls	a
	sta	savecc

	orcc	#$50		disable IRQ and FIRQ

	lda	PIA1C0
	anda	#$fb
	sta	PIA1C0
	lda	PIA1D0
	anda	#$fd
	sta	PIA1D0
	lda	PIA1C0
	ora	#$04
	sta	PIA1C0

	ldb	PIA0C0		disable hsync interrupt generation
	andb	#$fc
	stb	PIA0C0
	tst	PIA0D0
	lda	PIA0C1		enable vsync interrupt generation
	ora	#$01
	sta	PIA0C1
	tst	PIA0D1
	sync			wait for vsync interrupt

	ldb	TIMVAL+1	Seed the LFSR data
	bne	lfsrini		Can't tolerate a zero-value LFSR seed...
	ldb	#$01
lfsrini	stb	TIMVAL+1

	clr	atmpcnt		clear results tallies
	clr	seizcnt
	clr	escpcnt

restart	ldd	#$0400		show intro screen
	pshs	d
	jsr	intro
	leas	2,s
	bcs	restrt1

	ldd	#$0400		show tally screen
	pshs	d
	jsr	talyscn
	leas	2,s
	bcc	restart		cycle in attract mode

restrt1	lda	atmpcnt		bump attempts counter
	adda	#$01
	daa
	sta	atmpcnt

	jsr	instscn		show istruction screen

	jsr	clrscrn		clear video buffers

	jsr	plfdraw		draw the playfield

	jsr	bgcmini		init background collision map

	ldd	#$0f1e		point to grid offset for player
	std	playpos
	std	ersary0
	std	ersary1

	ldd	#$1511		point to grid offset for xmas tree
	std	xmstpos
	std	ersary0+10
	std	ersary1+10

	ldd	#$0703		point to grid offset for snowman 1 start
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

	jsr	cg3init		setup initial CG3 video screen

	lda	#$01		init video field indicator
	sta	vfield

	lda	#$01		preset movement delay counter
	sta	mvdlcnt

	lda	#SNMDRST	reset snowman movement delay counters
	sta	sn1mcnt
	sta	sn2mcnt
	sta	sn3mcnt
	sta	sn4mcnt

	ldd	playpos		set initial target for snowman 1
	std	snw1tgt

	lda	#GMFXMTR
	ora	#GMFSNW4
	ldb	escpcnt
	cmpb	#$01
	blt	.1?
	ora	#GMFSNW1
.1?	cmpb	#$02
	blt	.2?
	ora	#GMFSNW3
.2?	cmpb	#$03
	blt	.3?
	ora	#GMFSNW2
.3?	sta	gamflgs		initialize game status flags

vblank	tst	PIA0D1		wait for vsync interrupt
	sync

	lda	#$08		restore CSS for BCMO colors
	ora	PIA1D1
	sta	PIA1D1

	jsr	vbswtch

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

vdraw	lda	#GMFXMTR	check if xmas tree already taken
	bita	gamflgs
	beq	vdraw1

	ldd	xmstpos		point to grid offset for xmas tree
	std	10,y		save xmas tree grid offset to erase pointer
	ldu	#xmstree	point to data for xmas tree
	jsr	sprtdrw

vdraw1	lda	#GMFSNW1	check if snowman 1 is active
	bita	gamflgs
	beq	vdraw2

	ldd	snw1pos		point to grid offset for snowman 1
	std	8,y		save snowman grid offset to erase pointer
	ldu	#snowman	point to data for snowman
	jsr	sprtdrw

vdraw2	lda	#GMFSNW2	check if snowman 2 is active
	bita	gamflgs
	beq	vdraw3

	ldd	snw2pos		point to grid offset for snowman 2
	std	6,y		save snowman grid offset to erase pointer
	ldu	#snowman	point to data for snowman
	jsr	sprtdrw

vdraw3	lda	#GMFSNW3	check if snowman 3 is active
	bita	gamflgs
	beq	vdraw4

	ldd	snw3pos		point to grid offset for snowman 3
	std	4,y		save snowman grid offset to erase pointer
	ldu	#snowman	point to data for snowman
	jsr	sprtdrw

vdraw4	lda	#GMFSNW4	check if snowman 4 is active
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

vcheck	ldd	playpos
	pshs	d
	lda	#GMFSNW1
	bita	gamflgs
	beq	.1?
	ldx	#snw1pos	check for player collision w/ snowman 1
	jsr	spcolck
	bcc	.1?
	leas	2,s
	lbra	loss
.1?	lda	#GMFSNW2
	bita	gamflgs
	beq	.2?
	ldx	#snw2pos	check for player ocllision w/ snowman 2
	jsr	spcolck
	bcc	.2?
	leas	2,s
	lbra	loss
.2?	lda	#GMFSNW3
	bita	gamflgs
	beq	.3?
	ldx	#snw3pos	check for player ocllision w/ snowman 3
	jsr	spcolck
	bcc	.3?
	leas	2,s
	lbra	loss
.3?	lda	#GMFSNW4
	bita	gamflgs
	beq	.4?
	ldx	#snw4pos	check for player ocllision w/ snowman 4
	jsr	spcolck
	bcc	.4?
	leas	2,s
	lbra	loss
.4?	leas	2,s

vcalc	lda	#GMFXMTR	check for player escape
	bita	gamflgs
	bne	vcalc0
	lda	playpos+1
	cmpa	#$1e
	blt	vcalc0

	lbra	win

vcalc0	jsr	inpread		read player input for next frame

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

vcalc4	equ	*

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

vcalc7	jsr	snw1mov		calculate snowman movement targets
	jsr	snw2mov
	jsr	snw3mov
	jsr	snw4mov

vcalc8	ldd	playpos		check for player collision w/ xmas tree
	pshs	d
	ldx	#xmstpos
	jsr	spcolck
	bcc	vcalc13

	lda	#GMFXMTR	if so, turn-off game flag for xmas tree
	coma
	anda	gamflgs
	sta	gamflgs

vcalc13	leas	2,s

vloop	equ	*		cycle the game loop

	ifdef MON09
	jsr	chkuart
	endif

	lbra	vblank

win	lda	seizcnt		bump seizure and escape counts
	adda	#$01
	daa
	sta	seizcnt
	lda	escpcnt
	adda	#$01
	daa
	sta	escpcnt

	jsr	vbswtch

	ldb	#$80
winwait	tst	PIA0D1		wait for vsync interrupt
	sync

	lda	PIA0D0		read from the PIA connected to the joystick buttons
	bita	#$02		test for left joystick button press
	beq	winexit

	decb
	bne	winwait

winexit	lda	PIA0D0		read from the PIA connected to the joystick buttons
	bita	#$02		test for left joystick button press
	beq	winexit

	ldd	#$0100
	pshs	d
	jsr	talyscn
	leas	2,s

	lbcs	restrt1

	lbra	restart

loss	lda	#GMFXMTR	bump seizure count, if appropriate
	bita	gamflgs
	bne	loss1

	lda	seizcnt
	adda	#$01
	daa
	sta	seizcnt

loss1	jsr	vbswtch

	ldb	#$80
losswai	tst	PIA0D1		wait for vsync interrupt
	sync

	lda	PIA0D0		read from the PIA connected to the joystick buttons
	bita	#$02		test for left joystick button press
	beq	lossext

	decb
	bne	losswai

lossext	lda	PIA0D0		read from the PIA connected to the joystick buttons
	bita	#$02		test for left joystick button press
	beq	lossext

	ldd	#$0100
	pshs	d
	jsr	talyscn
	leas	2,s

	lbcs	restrt1

	lbra	restart

*
* Move snowman 1
*
snw1mov	dec	sn1mcnt
	lbne	snw1mvx

	lda	#SNMDRST
	sta	sn1mcnt

	lda	#GMFXMTR
	bita	gamflgs
	bne	snw1mv0

	ldd	playpos
	std	snw1tgt

snw1mv0	ldd	snw1pos
	cmpa	snw1tgt
	blt	snw1mv1
	bgt	snw1mv2

	jsr	lfsrget
	anda	#$1f
	sta	snw1tgt
	lda	snw1pos
	bra	snw1mv3

snw1mv1	inca
	bra	snw1mv3

snw1mv2	deca

snw1mv3	pshs	d
	jsr	bgcolck
	bcs	snw1mv4

	ldx	#xmstpos
	jsr	spcolck
	bcs	snw1mv4

	ldd	snw2pos
	cmpd	,s
	beq	snw1mv4

	ldd	snw3pos
	cmpd	,s
	beq	snw1mv4

	ldd	snw4pos
	cmpd	,s
	bne	snw1mv5

snw1mv4	leas	2,s
	jsr	lfsrget
	anda	#$1f
	sta	snw1tgt
	ldd	snw1pos
	bra	snw1mv6

snw1mv5	puls	d
	std	snw1pos

snw1mv6	cmpb	snw1tgt+1
	blt	snw1mv7
	bgt	snw1mv8

	jsr	lfsrget
	anda	#$1f
	sta	snw1tgt+1
	lda	snw1pos
	bra	snw1mv9

snw1mv7	incb
	bra	snw1mv9

snw1mv8	decb

snw1mv9	pshs	d
	jsr	bgcolck
	bcs	snw1mva

	ldx	#xmstpos
	jsr	spcolck
	bcs	snw1mva

	ldd	snw2pos
	cmpd	,s
	beq	snw1mva

	ldd	snw3pos
	cmpd	,s
	beq	snw1mva

	ldd	snw4pos
	cmpd	,s
	bne	snw1mvb

snw1mva	leas	2,s
	jsr	lfsrget
	anda	#$1e
	sta	snw1tgt+1
	bra	snw1mvx

snw1mvb	puls	d
	std	snw1pos

snw1mvx	rts

*
* Move snowman 2
*
snw2mov	dec	sn2mcnt
	lbne	snw2mvx

	lda	#SNMDRST
	sta	sn2mcnt

	ldd	snw2pos
	cmpa	playpos
	blt	snw2mv1
	bgt	snw2mv2
	bra	snw2mv3

snw2mv1	inca
	bra	snw2mv3

snw2mv2	deca

snw2mv3	pshs	d
	jsr	bgcolck
	bcs	snw2mv4

	ldx	#xmstpos
	jsr	spcolck
	bcs	snw2mv4

	ldd	snw1pos
	cmpd	,s
	beq	snw2mv4

	ldd	snw3pos
	cmpd	,s
	beq	snw2mv4

	ldd	snw4pos
	cmpd	,s
	bne	snw2mv5

snw2mv4	leas	2,s
	ldd	snw2pos
	bra	snw2mv6

snw2mv5	puls	d
	std	snw2pos

snw2mv6	cmpb	playpos+1
	blt	snw2mv7
	bgt	snw2mv8
	bra	snw2mv9

snw2mv7	incb
	bra	snw2mv9

snw2mv8	decb

snw2mv9	pshs	d
	jsr	bgcolck
	bcs	snw2mva

	ldx	#xmstpos
	jsr	spcolck
	bcs	snw2mva

	ldd	snw1pos
	cmpd	,s
	beq	snw2mva

	ldd	snw3pos
	cmpd	,s
	beq	snw2mva

	ldd	snw4pos
	cmpd	,s
	bne	snw2mvb

snw2mva	leas	2,s
	bra	snw2mvx

snw2mvb	puls	d
	std	snw2pos

snw2mvx	rts

*
* Move snowman 3
*
snw3mov	dec	sn3mcnt
	lbne	snw3mvx

	lda	#SNMDRST
	sta	sn3mcnt

	lda	#GMFXMTR
	bita	gamflgs
	bne	snw3mv1

	ldd	playpos
	std	snw3tgt
	bra	snw3mv2

snw3mv1	ldd	playpos
	suba	xmstpos
	asra
	adda	xmstpos
	subb	xmstpos+1
	asrb
	addb	xmstpos+1
	std	snw3tgt

snw3mv2	ldd	snw3pos
	cmpa	snw3tgt
	blt	snw3mv3
	bgt	snw3mv4
	bra	snw3mv5

snw3mv3	inca
	bra	snw3mv5

snw3mv4	deca

snw3mv5	pshs	d
	jsr	bgcolck
	bcs	snw3mv6

	ldx	#xmstpos
	jsr	spcolck
	bcs	snw3mv6

	ldd	snw1pos
	cmpd	,s
	beq	snw3mv6

	ldd	snw2pos
	cmpd	,s
	beq	snw3mv6

	ldd	snw4pos
	cmpd	,s
	bne	snw3mv7

snw3mv6	leas	2,s
	ldd	snw3pos
	bra	snw3mv8

snw3mv7	puls	d
	std	snw3pos

snw3mv8	cmpb	snw3tgt+1
	blt	snw3mv9
	bgt	snw3mva
	bra	snw3mvb

snw3mv9	incb
	bra	snw3mvb

snw3mva	decb

snw3mvb	pshs	d
	jsr	bgcolck
	bcs	snw3mvc

	ldx	#xmstpos
	jsr	spcolck
	bcs	snw3mvc

	ldd	snw1pos
	cmpd	,s
	beq	snw3mvc

	ldd	snw2pos
	cmpd	,s
	beq	snw3mvc

	ldd	snw4pos
	cmpd	,s
	bne	snw3mvd

snw3mvc	leas	2,s
	bra	snw3mvx

snw3mvd	puls	d
	std	snw3pos

snw3mvx	rts

*
* Move snowman 4
*
snw4mov	dec	sn4mcnt
	lbne	snw4mvx

	lda	#SNMDRST
	sta	sn4mcnt

	lda	#GMFXMTR
	bita	gamflgs
	bne	snw4mv0

	ldd	playpos
	cmpb	#$1a
	blt	snw4mv0

	std	snw4tgt

snw4mv0	ldd	snw4pos
	cmpa	snw4tgt
	blt	snw4mv1
	bgt	snw4mv2

	jsr	lfsrget
	anda	#$07
	adda	#$0b
	sta	snw4tgt
	lda	snw4pos
	bra	snw4mv3

snw4mv1	inca
	bra	snw4mv3

snw4mv2	deca

snw4mv3	pshs	d
	jsr	bgcolck
	bcs	snw4mv4

	ldx	#xmstpos
	jsr	spcolck
	bcs	snw4mv4

	ldd	snw1pos
	cmpd	,s
	beq	snw4mv4

	ldd	snw2pos
	cmpd	,s
	beq	snw4mv4

	ldd	snw3pos
	cmpd	,s
	bne	snw4mv5

snw4mv4	leas	2,s
	jsr	lfsrget
	anda	#$07
	adda	#$0b
	sta	snw4tgt
	ldd	snw4pos
	bra	snw4mv6

snw4mv5	puls	d
	std	snw4pos

snw4mv6	cmpb	snw4tgt+1
	blt	snw4mv7
	bgt	snw4mv8

	jsr	lfsrget
	anda	#$07
	adda	#$17
	sta	snw4tgt+1
	lda	snw4pos
	bra	snw4mv9

snw4mv7	incb
	bra	snw4mv9

snw4mv8	decb

snw4mv9	pshs	d
	jsr	bgcolck
	bcs	snw4mva

	ldx	#xmstpos
	jsr	spcolck
	bcs	snw4mva

	ldd	snw1pos
	cmpd	,s
	beq	snw4mva

	ldd	snw2pos
	cmpd	,s
	beq	snw4mva

	ldd	snw3pos
	cmpd	,s
	bne	snw4mvb

snw4mva	leas	2,s
	jsr	lfsrget
	anda	#$07
	adda	#$17
	sta	snw4tgt+1
	bra	snw4mvx

snw4mvb	puls	d
	std	snw4pos

snw4mvx	rts

*
* Show intro screen
*
intro	tst	PIA0D1		wait for vsync interrupt
	sync

	ldx	#intscrn
	ldy	#TXTBASE
intsclp	lda	,x+
	sta	,y+
	cmpx	#(intscrn+512)
	blt	intsclp

	clr	$ffc0		clr v0
	clr	$ffc2		clr v1
	clr	$ffc4		clr v2
	clr	PIA1D1		setup vdg

	clr	$ffc6		set video base to $0400
	clr	$ffc9
	clr	$ffca
	clr	$ffcc
	clr	$ffce
	clr	$ffd0
	clr	$ffd2

	ldb	#$20
intstlp	lda	PIA0D0		read from the PIA connected to the joystick buttons
	bita	#$02		test for left joystick button press
	beq	intrext

	ifdef MON09
	jsr	chkuart
	endif

	tst	PIA0D1
	sync

	decb
	bne	intstl2

	ldb	#$04
	ldx	#(PLAYPOS-1)
intstl1	lda	b,x
	eora	#$40
	sta	b,x
	decb
	bne	intstl1

	ldb	#$20

intstl2	dec	3,s
	bne	intstl3
	lda	2,s
	beq	intstox
	deca
	sta	2,s

intstl3	lda	#$fd
	sta	PIA0D1
	lda	PIA0D0
	anda	#$40
	bne	intstl4

	clr	atmpcnt		clear results tallies
	clr	seizcnt
	clr	escpcnt

	bra	intstox	

intstl4	lda	#$fb
	sta	PIA0D1
	lda	PIA0D0
	anda	#$40
	bne	intstlp

	jmp	exit

intstox	andcc	#$fe
	rts

intrext	lda	PIA0D0		read from the PIA connected to the joystick buttons
	bita	#$02		test for left joystick button press
	beq	intrext

	orcc	#$01
	rts

*
* Show instructions
*
instscn	tst	PIA0D1		wait for vsync interrupt
	sync

	jsr	clrtscn

	ldx	#instrs1
	ldy	#IS1BASE
	jsr	drawstr

	ldx	#instrs2
	ldy	#IS2BASE
	jsr	drawstr

	ldx	#instrs3
	ldy	#IS3BASE
	jsr	drawstr

	ldx	#instrs4
	ldy	#IS4BASE
	jsr	drawstr

inswait	ldb	#$80
inswai2	tst	PIA0D1		wait for vsync interrupt
	sync

	lda	PIA0D0		read from the PIA connected to the joystick buttons
	bita	#$02		test for left joystick button press
	beq	insexit

	decb
	bne	inswai2

insexit	lda	PIA0D0		read from the PIA connected to the joystick buttons
	bita	#$02		test for left joystick button press
	beq	insexit

	rts

*
* Show tallies
*
talyscn	tst	PIA0D1		wait for vsync interrupt
	sync

	jsr	clrtscn

	ldx	#atmpstr
	ldy	#ATSTBAS
	jsr	drawstr

	leay	2,y
	lda	atmpcnt
	jsr	bcdshow

	ldx	#seizstr
	ldy	#SZSTBAS
	jsr	drawstr

	leay	2,y
	lda	seizcnt
	jsr	bcdshow

	ldx	#escpstr
	ldy	#ESSTBAS
	jsr	drawstr

	leay	3,y
	lda	escpcnt
	jsr	bcdshow

	ldx	#clrstr
	ldy	#CLSTBAS
	jsr	drawstr

	ldx	#brkstr
	ldy	#BRSTBAS
	jsr	drawstr

	clr	$ffc0		clr v0
	clr	$ffc2		clr v1
	clr	$ffc4		clr v2
	clr	PIA1D1		setup vdg

	clr	$ffc6		set video base to $0400
	clr	$ffc9
	clr	$ffca
	clr	$ffcc
	clr	$ffce
	clr	$ffd0
	clr	$ffd2

tlywait	tst	PIA0D1		wait for vsync interrupt
	sync

	ifdef MON09
	jsr	chkuart
	endif

	lda	PIA0D0		read from the PIA connected to the joystick buttons
	bita	#$02		test for left joystick button press
	beq	tlyexit

	dec	3,s
	bne	tlywai2
	lda	2,s
	beq	tlytmox
	deca
	sta	2,s

tlywai2	lda	#$fd
	sta	PIA0D1
	lda	PIA0D0
	anda	#$40
	bne	tlywai3

	clr	atmpcnt		clear results tallies
	clr	seizcnt
	clr	escpcnt

	lbra	talyscn

tlywai3	lda	#$fb
	sta	PIA0D1
	lda	PIA0D0
	anda	#$40
	bne	tlywait

	jmp	exit

tlytmox	andcc	#$fe
	rts

tlyexit	lda	PIA0D0		read from the PIA connected to the joystick buttons
	bita	#$02		test for left joystick button press
	beq	tlyexit

	orcc	#$01
	rts

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
* cg3init -- setup initial CG3 video mode/screen
*
cg3init	clr	$ffc0		clr v0
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

	rts

*
* vbswtch -- switch to opposite CG3 screen
*
vbswtch	lda	vfield		load previous field indicator

	deca			switch video field indicator
	bne	vbswtc1

	clr	$ffc9		reset video base to $0e00
	clr	$ffcc

	bra	vbswtcx

vbswtc1	lda	#$01		reset video field indicator

	clr	$ffc8		reset video base to $1a00
	clr	$ffcd

vbswtcx	sta	vfield		save current field indicator

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
* Clear text screen
*
clrtscn	lda	#' '
	ldy	#TXTBASE
clrtslp	sta	,y+
	cmpy	#(TXTBASE+512)
	blt	clrtslp

	rts

*
* Draw string
*
drawstr	lda	,x+
	beq	drawstx
	sta	,y+
	bra	drawstr

drawstx	rts

*
* Show BCD encoded number on screen
*
bcdshow	pshs	a
	anda	#$f0
	lsra
	lsra
	lsra
	lsra
	adda	#$30
	sta	,y+
	puls	a
	anda	#$0f
	adda	#$30
	sta	,y
	rts

*
* spcolck -- check for collision w/ player
*
*	2,S -- sprite position data
*	X   -- pointer to object position data
*
*	A,X clobbered
*
spcolck	lda	,x+
	deca
	cmpa	2,s
	bgt	spcolcx
	adda	#$02
	cmpa	2,s
	blt	spcolcx
	lda	,x
	deca
	cmpa	3,s
	bgt	spcolcx
	adda	#$02
	cmpa	3,s
	blt	spcolcx

	orcc	#$01
	rts

spcolcx	andcc	#$fe
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
	eora	-64,x
	eorb	-63,x
	std	-64,x
	pulu	d
	eora	-32,x
	eorb	-31,x
	std	-32,x
	pulu	d
	eora	,x
	eorb	1,x
	std	,x
	pulu	d
	eora	32,x
	eorb	33,x
	std	32,x
	pulu	d
	eora	64,x
	eorb	65,x
	std	64,x
	pulu	d
	eora	96,x
	eorb	97,x
	std	96,x
	pulu	d
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
* Advance the LFSR value and return pseudo-random value
*
*	A returns pseudo-random value
*	B gets clobbered
*
* 	Wikipedia article on LFSR cites this polynomial for a maximal 8-bit LFSR:
*
*		x8 + x6 + x5 + x4 + 1
*
*	http://en.wikipedia.org/wiki/Linear_feedback_shift_register
*
lfsrget	lda	TIMVAL+1	Get MSB of LFSR data
	anda	#$80		Capture x8 of LFSR polynomial
	lsra
	lsra
	eora	TIMVAL+1	Capture X6 of LFSR polynomial
	lsra
	eora	TIMVAL+1	Capture X5 of LFSR polynomial
	lsra
	eora	TIMVAL+1	Capture X4 of LFSR polynomial
	lsra			Move result to Carry bit of CC
	lsra
	lsra
	lsra
	lda	TIMVAL+1	Get all of LFSR data
	rola			Shift result into 8-bit LFSR
	sta	TIMVAL+1	Store the result
	rts

	ifdef MON09
*
* Check for user break (development only)
*
chkuart	lda	$ff69		Check for serial port activity
	bita	#$08
	beq	chkurex
	lda	$ff68
	jmp	[$fffe]		Re-enter monitor
chkurex	rts
	endif

*
* Exit the game
*
exit 	equ	*
	ifdef MON09
	jmp	[$fffe]		Reset!
	else
	lds	savestk		restore stack pointer
	lda	savecc		reenable any interrupts
	pshs	a
	puls	cc
	jsr	clrtscn		clear text screen
	rts			return to RSDOS
	endif

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
* Intro screen data
*
* 	generated @ http://cocobotomy.roust-it.dk/sgedit/
*
intscrn	fcb	$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80
	fcb	$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$9f,$9a,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80
	fcb	$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$87,$8f,$8f,$82,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80
	fcb	$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$87,$8f,$bf,$8f,$8f,$82,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80
	fcb	$80,$80,$80,$80,$80,$80,$80,$80,$80,$87,$8f,$8f,$8f,$8f,$ff,$8f,$82,$80,$80,$80,$80,$80,$80,$80,$4c,$45,$46,$54,$80,$80,$80,$80
	fcb	$80,$80,$80,$80,$80,$80,$80,$80,$87,$8f,$af,$8f,$8f,$8f,$8f,$8f,$8f,$82,$80,$80,$80,$80,$4a,$4f,$59,$53,$54,$49,$43,$4b,$80,$80
	fcb	$80,$80,$80,$80,$80,$80,$80,$87,$ff,$8f,$8f,$8f,$18,$0d,$01,$13,$8f,$8f,$82,$80,$80,$80,$80,$42,$55,$54,$54,$4f,$4e,$80,$80,$80
	fcb	$80,$80,$80,$80,$80,$80,$87,$8f,$8f,$8f,$8f,$8f,$8f,$12,$15,$13,$08,$8f,$8f,$82,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80
	fcb	$80,$80,$80,$80,$80,$87,$8f,$8f,$af,$8f,$8f,$bf,$8f,$8f,$8f,$8f,$8f,$8f,$ef,$8f,$82,$80,$80,$80,$80,$54,$4f,$80,$80,$80,$80,$80
	fcb	$80,$80,$80,$80,$87,$ff,$8f,$8f,$8f,$8f,$8f,$8f,$8f,$8f,$8f,$02,$19,$8f,$8f,$8f,$8f,$82,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80
	fcb	$80,$80,$80,$84,$8f,$8f,$8f,$8f,$ef,$8f,$8f,$8f,$ff,$8f,$0a,$0f,$08,$0e,$8f,$8f,$af,$8e,$80,$80,$50,$4c,$41,$59,$80,$80,$80,$80
	fcb	$80,$80,$80,$80,$84,$8f,$bf,$8f,$8f,$8f,$af,$8f,$0c,$09,$0e,$16,$09,$0c,$0c,$05,$8e,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80
	fcb	$80,$80,$80,$80,$80,$84,$8f,$8f,$8f,$8f,$8f,$8f,$8f,$8f,$8f,$8f,$8f,$8f,$8f,$8e,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80
	fcb	$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$f5,$ff,$ff,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80
	fcb	$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$f5,$ff,$ff,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80
	fcb	$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80

*
* Instruction screen data
*
instrs1	fcb	$05,$0e,$14,$05,$12,$20,$14,$08,$05,$20,$06,$0f,$12,$05,$13,$14
	fcb	$2c,$00

instrs2	fcb	$14,$01,$0b,$05,$20,$14,$08,$05,$20,$0c,$01,$13,$14,$20,$18,$0d
	fcb	$01,$13,$20,$14,$12,$05,$05,$2c,$00

instrs3	fcb	$05,$13,$03,$01,$10,$05,$20,$14,$08,$05,$20,$05,$16,$09,$0c,$20
	fcb	$13,$0e,$0f,$17,$0d,$05,$0e,$2e,$2e,$2e,$00

instrs4	fcb	$03,$01,$12,$10,$05,$20,$01,$12,$02,$0f,$12,$05,$13,$21,$00

*
* Tally screen data
*
atmpstr	fcb	$01,$14,$14,$05,$0d,$10,$14,$13,$00

seizstr	fcb	$13,$05,$09,$1a,$15,$12,$05,$13,$00

escpstr	fcb	$05,$13,$03,$01,$10,$05,$13,$00

clrstr	fcb	$43,$4c,$45,$41,$52,$20,$06,$0f,$12,$20,$0e,$05,$17,$20,$10,$0c
	fcb	$01,$19,$05,$12,$00

brkstr	fcb	$42,$52,$45,$41,$4b,$20,$14,$0f,$20,$05,$0e,$04,$20,$07,$01,$0d
	fcb	$05,$00

*
* Variable Declarations
*
savestk	rmb	2
savecc	rmb	1

vfield	rmb	1

inpflgs	rmb	1
gamflgs	rmb	1

ersary0	rmb	12
ersary1	rmb	12

mvdlcnt	rmb	1

bgclmap	rmb	plyfmsz

playpos	rmb	2
xmstpos	rmb	2
snw1tgt	rmb	2
snw3tgt	rmb	2
snw4tgt	rmb	2

snw1pos	rmb	2
snw2pos	rmb	2
snw3pos	rmb	2
snw4pos	rmb	2

sn1mcnt	rmb	1
sn2mcnt	rmb	1
sn3mcnt	rmb	1
sn4mcnt	rmb	1

atmpcnt	rmb	1
seizcnt	rmb	1
escpcnt	rmb	1

	end	START
