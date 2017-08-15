#!/bin/bash

loopbackDevice=/dev/loop2
mountDir=/media/hasebou/MY_OS/

function clean {
	#clean up
	rm build/*
	umount "$mountDir"
	losetup -d $loopbackDevice
}

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
losetup $loopbackDevice build/floppy.img

check
mkdosfs -n 'MY_OS' -F 12 $loopbackDevice 

check
dd if=build/Boot1.bin of=build/floppy.img bs=512 count=1 conv=notrunc

check
cp --no-preserve=mode  build/KRNLDR.SYS $mountDir
check
cp --no-preserve=mode  build/KRNL32.EXE $mountDir
check


sudo bochs -f bochsrc.txt -q

umount /media/hasebou/MY_OS
losetup -d /dev/loop2
