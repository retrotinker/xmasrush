.PHONY: all clean

CFLAGS=-Wall

TARGETS=xmasrush.bin xmasrush.wav xmasrush.dsk xmasrush.s19
EXTRA=xmasrush.4k xmasrush.8k

all: $(TARGETS)

%.bin: %.asm
	lwasm -9 -l -f decb -o $@ $<

%.s19: %.asm
	lwasm -DMON09 -9 -l -f srec -o $@ $<

%.ccc: %.asm
	lwasm -DROM -9 -l -f raw -o $@ $<

%.wav: %.bin
	cecb bulkerase $@
	cecb copy -2 -b -g $< \
		$(@),$$(echo $< | cut -c1-8 | tr [:lower:] [:upper:])

xmasrush.dsk: xmasrush.bin COPYING
	rm -f $@
	decb dskini $@
	decb copy -2 -b $< $@,$$(echo $< | tr [:lower:] [:upper:])
	decb copy -3 -a -l COPYING $@,COPYING

xmasrush.4k: xmasrush.ccc
	rm -f $@
	dd if=/dev/zero bs=2k count=1 | \
		tr '\000' '\377' > $@
	dd if=$< of=$@ conv=notrunc

xmasrush.8k: xmasrush.4k
	cat $< > $@
	cat $< >> $@

clean:
	$(RM) $(TARGETS) $(EXTRA)
