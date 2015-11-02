.PHONY: all clean

CFLAGS=-Wall

TARGETS=letitsnow.s19
EXTRA=letitsnow.2k letitsnow.4k

all: $(TARGETS)

%.bin: %.asm
	lwasm -9 -l -f decb -o $@ $<

%.s19: %.asm
	lwasm -9 -l -f srec -o $@ $<

%.ccc: %.asm
	lwasm -DROM -9 -l -f raw -o $@ $<

%.wav: %.bin
	cecb bulkerase $@
	cecb copy -2 -b -g $< \
		$(@),$$(echo $< | cut -c1-8 | tr [:lower:] [:upper:])

letitsnow.dsk: letitsnow.bin COPYING
	rm -f $@
	decb dskini $@
	decb copy -2 -b $< $@,$$(echo $< | tr [:lower:] [:upper:])
	decb copy -3 -a -l COPYING $@,COPYING

letitsnow.2k: letitsnow.ccc
	rm -f $@
	dd if=/dev/zero bs=2k count=1 | \
		tr '\000' '\377' > $@
	dd if=$< of=$@ conv=notrunc

letitsnow.4k: letitsnow.2k
	cat $< > $@
	cat $< >> $@

clean:
	$(RM) $(TARGETS) $(EXTRA)
