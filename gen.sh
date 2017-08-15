#!/bin/bash

function check {
	if [ $? -ne 0 ]
	then
		exit 0
	fi
}


nasm SysBoot/Stage1/Boot1.asm   -o build/Boot1.bin

check

nasm -I SysBoot/Stage2/ SysBoot/Stage2/Stage2.asm -o build/KRNLDR.SYS

check

gcc -g -O -c SysCore/Kernel/main.c -m32 -nostdlib -nostdinc -fno-builtin -fno-stack-protector -nostartfiles -nodefaultlibs -O0
ld -T SysCore/Kernel/link.ld -melf_i386 main.o -o build/KRNL32.EXE

check
dd if=/dev/zero of=build/floppy.img bs=512 count=2880

check
mkdosfs -F 12 build/floppy.img

check
dd if=build/Boot1.bin of=build/floppy.img bs=512 count=1 conv=notrunc

check
mcopy -i build/floppy.img build/KRNLDR.SYS ::/KRNLDR.SYS
check
mcopy -i build/floppy.img build/KRNL32.EXE ::/KRNL32.EXE
check


sudo bochs -f bochsrc.txt -q