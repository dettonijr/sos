MBR_ASM=mbr.asm
MBR_BIN=mbr.bin
BOOT_C=boot.cpp
BOOT_O=boot.o

SRCS=
OBJS=$(patsubst %.c, %.o, $(SRCS))

BOOT_BIN=boot.bin

DISK_IMG = disk.img

%.bin: %.asm
	nasm $< -f bin -o $@

%.o: %.asm
	nasm $< -f elf32 -o $@

%.o: %.cpp
	g++ -std=c++11 -O0 -g -ffreestanding -m16 -fno-pie -c $< -o $@

all: $(DISK_IMG)

clean:
	rm $(DISK_IMG) $(OBJS) $(BOOT_O) $(BOOT_BIN) $(MBR_BIN)

$(OBJS): $(SRCS)

$(BOOT_BIN): $(BOOT_O) $(OBJS)
	ld -o $(BOOT_BIN) -nostdlib -static -m elf_i386 -Ttext 0x7e00 $(BOOT_O) $(OBJS) --oformat binary

$(DISK_IMG): $(MBR_BIN) $(BOOT_BIN)
	dd if=/dev/zero of=disk.img bs=512 count=2880
	dd conv=notrunc if=$(MBR_BIN) of=$(DISK_IMG) seek=0 
	dd conv=notrunc if=$(BOOT_BIN)       of=$(DISK_IMG) seek=1

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
