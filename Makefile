objects = SysCore/Kernel/*.o SysCore/lib/*.o

CC = gcc
CFLAGS = -m32 -nostdlib -nostdinc -fno-builtin -fno-stack-protector \
             -nostartfiles -nodefaultlibs -Wall -Wextra -Werror -c

LDFLAGS = -T SysCore/Kernel/link.ld -melf_i386
AS = nasm
ASFLAGS = -f bin

run: all
	bochs -f bochsrc.txt -q

all: bootloader kernel.compile
	dd if=/dev/zero of=build/floppy.img bs=512 count=2880
	mkdosfs -F 12 build/floppy.img
	dd if=build/Boot1.bin of=build/floppy.img bs=512 count=1 conv=notrunc
	mcopy -i build/floppy.img build/KRNLDR.SYS ::/KRNLDR.SYS
	mcopy -i build/floppy.img build/KRNL32.EXE ::/KRNL32.EXE

kernel.compile: $(objects)
	ld $(LDFLAGS) $(objects) -o build/KRNL32.EXE

bootloader:
	$(AS) $(ASFLAGS) SysBoot/Stage1/Boot1.asm -o build/Boot1.bin
	$(AS) $(ASFLAGS) -I SysBoot/Stage2/ SysBoot/Stage2/Stage2.asm -o build/KRNLDR.SYS

clean:
	rm build/*

%.o: %.c
	$(CC) $(CFLAGS) -I SysCore/lib/ $< -o $@
