#!/bin/bash

loopbackDevice=/dev/loop2
mountDir=/media/hasehou/MY_OS

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

printf "(1) Build project\n(2) launch emulator\n(3) Setup looback device\n"

read option

if [ $option -eq 1 ]
then
	nasm SysBoot/Stage1/Boot1.asm   -o build/Boot1.bin

	check

	nasm -I SysBoot/Stage2/ SysBoot/Stage2/Stage2.asm -o build/KRNLDR.SYS

	check

	gcc -g -O -c SysCore/Kernel/main.c -m32 -nostdlib -nostdinc -fno-builtin -fno-stack-protector -nostartfiles -nodefaultlibs -O0
	ld -T SysCore/Kernel/link.ld -melf_i386 main.o -o build/kernel

	check
	dd if=build/Boot1.bin of=$loopbackDevice bs=512 count=1 conv=notrunc

	check
	cp --no-preserve=mode  build/KRNLDR.SYS $mountDir
	check
	cp --no-preserve=mode  build/kernel $mountDir
	check

elif [ $option -eq 3 ]
then
	check

	dd if=/dev/zero of=build/floppy.img bs=512 count=2880

	check
	losetup $loopbackDevice build/floppy.img

	check
	mkdosfs -n 'MY_OS' -F 12 $loopbackDevice 
else
	qemu-system-i386 -fda $loopbackDevice
fi

