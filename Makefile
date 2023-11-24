all: jz

TARGET := arm-none-eabi-
AS := $(TARGET)as
OBJCOPY := $(TARGET)objcopy

jz.o: jz.s
	$(AS) $< -c -o $@

jz: jz.o
	$(OBJCOPY) -O binary $< $@
	chmod +x $@

clean:
	rm -f jz jz.o
