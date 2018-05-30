ASM_FILES=bootloader.asm
BIN_FILES = $(patsubst %.asm, %.bin, $(ASM_FILES))
DISK_IMG = disk.img

%.bin: %.asm
	nasm $< -f bin -o $@

$(DISK_IMG): $(BIN_FILES) 
	dd if=/dev/zero of=disk.img bs=512 count=2880
	dd conv=notrunc if=bootloader.bin of=$(DISK_IMG) 

all: $(BIN_FILES)

run: $(DISK_IMG) 
	qemu-system-i386 -fda $(DISK_IMG)

debug: $(DISK_IMG)
	qemu-system-i386 -fda $(DISK_IMG) -gdb tcp::26000 -S &
	gdb -ex 'target remote localhost:26000' \
	    -ex 'set architecture i8086' \
	    -ex 'layout asm' \
	    -ex 'layout regs' \
	    -ex 'break *0x7c00' \
	    -ex 'continue' \
		&& killall qemu-system-i386
