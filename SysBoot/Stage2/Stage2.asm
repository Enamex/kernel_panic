
;*******************************************************
;
;	Stage2.asm
;		Stage2 Bootloader
;
;	OS Development Series
;*******************************************************

bits	16

; Remember the memory map-- 0x500 through 0x7bff is unused above the BIOS data area.
; We are loaded at 0x500 (0x50:0)

org 0x500

jmp	main				; go to start

;*******************************************************
;	Preprocessor directives
;*******************************************************

%include "stdio.inc"			; basic i/o routines
%include "Gdt.inc"			; Gdt routines
%include "A20.inc"			; A20 enabling
%include "Fat12.inc"			; FAT12 driver. Kinda :)
%include "common.inc"

;*******************************************************
;	Data Section
;*******************************************************

LoadingMsg db 0x0D, 0x0A, "Searching for Operating System...", 0x00
msgFailure db 0x0D, 0x0A, "*** FATAL: MISSING OR CURRUPT KERNEL. Press Any Key to Reboot", 0x0D, 0x0A, 0x0A, 0x00

;*******************************************************
;	STAGE 2 ENTRY POINT
;
;		-Store BIOS information
;		-Load Kernel
;		-Install GDT; go into protected mode (pmode)
;		-Jump to Stage 3
;*******************************************************

main:

	;-------------------------------;
	;   Setup segments and stack	;
	;-------------------------------;

	cli				; clear interrupts
	xor	ax, ax			; null segments
	mov	ds, ax
	mov	es, ax
	mov	ax, 0x0			; stack begins at 0x9000-0xffff
	mov	ss, ax
	mov	sp, 0xFFFF
	sti				; enable interrupts

	;-------------------------------;
	;   Install our GDT		;
	;-------------------------------;

	call	InstallGDT		; install our GDT

	;-------------------------------;
	;   Enable A20			;
	;-------------------------------;

	call	EnableA20_KKbrd_Out

	;-------------------------------;
	;   Print loading message	;
	;-------------------------------;

	mov	si, LoadingMsg
	call	Puts16

        ;-------------------------------;
        ; Initialize filesystem		;
        ;-------------------------------;

	call	LoadRoot		; Load root directory table

        ;-------------------------------;
        ; Load Kernel			;
        ;-------------------------------;

	mov	ebx, 0			; BX:BP points to buffer to load to
    mov	bp, IMAGE_RMODE_BASE
	mov	si, ImageName		; our file to load
	call	LoadFile		; load our file
	mov	dword [ImageSize], ecx	; save size of kernel
	cmp	ax, 0			; Test for success
	je	EnterStage3		; yep--onto Stage 3!
	mov	si, msgFailure		; Nope--print error
	call	Puts16
	mov	ah, 0
	int     0x16                    ; await keypress
	int     0x19                    ; warm boot computer
	cli				; If we get here, something really went wong
	hlt

	;-------------------------------;
	;   Go into pmode		;
	;-------------------------------;

EnterStage3:

	cli				; clear interrupts
	mov	eax, cr0		; set bit 0 in cr0--enter pmode
	or	eax, 1
	mov	cr0, eax

	jmp	CODE_DESC:Stage3	; far jump to fix CS. Remember that the code selector is 0x8!

	; Note: Do NOT re-enable interrupts! Doing so will triple fault!
	; We will fix this in Stage 3.

;******************************************************
;	ENTRY POINT FOR STAGE 3
;******************************************************

bits 32

BadImage db "*** FATAL: Invalid or corrupt kernel image. Halting system.", 0

Stage3:

	;-------------------------------;
	;   Set registers		;
	;-------------------------------;

	mov	ax, DATA_DESC	; set data segments to data selector (0x10)
	mov	ds, ax
	mov	ss, ax
	mov	es, ax
	mov	fs, ax
	mov	gs, ax
	mov	esp, 90000h		; stack begins from 90000h

	call	ClrScr32

	;-------------------------------;
	; Copy kernel to 1MB		;
	;-------------------------------;

parseELF:
	mov		ebx, DWORD [IMAGE_RMODE_BASE + 0x1C]	; get offset of program header
	movzx	ecx, WORD  [IMAGE_RMODE_BASE + 0x2C]	; get number of header tables
	add 	ebx, IMAGE_RMODE_BASE					; store location of program header
	.loadEntry:
		push ecx							;store number of header files present
		mov eax, DWORD [ebx]
		cmp eax, 0x001
		jne .loopEnd

		mov edi, DWORD [ebx + 0x0C]
		mov esi, DWORD [ebx + 0x04] ;source to copy from
		add esi, IMAGE_RMODE_BASE

		cld
		mov ecx, DWORD [ebx + 0x10]				;copy file
		rep movsb

		mov ecx, DWORD [ebx + 0x14]				;get mem size
		sub ecx, DWORD [ebx + 0x10]				;sub file size
		cmp ecx, 0x0							;check if zero extra area to init
		je .loopEnd							

		;setup bss area
	.bssSetup:
		mov [edi], BYTE 0x0
		inc edi
		loop .bssSetup


	.loopEnd:
		pop ecx
		movzx eax, WORD [IMAGE_RMODE_BASE + 0x2A] ; get program header entry size
		add ebx, eax ; point to next program header entry
		loop .loadEntry

TestImage:
  	  mov    ebx, IMAGE_RMODE_BASE    ; ebx now points to file sig (PE00)
  	  mov    esi, ebx
  	  mov    edi, ImageSig
  	  cmpsd
  	  je     EXECUTE
  	  mov	ebx, BadImage
  	  call	Puts32
  	  cli
  	  hlt

ImageSig db 0x7F, 0x45, 0x4c, 0x46
memLoc dd 0x101000
EXECUTE:

	;---------------------------------------;
	;   Execute Kernel
	;---------------------------------------;

 	; parse the programs header info structures to get its entry point
	; ebx points to _IMAGE_FILE_HEADER

	mov		ebx, DWORD [IMAGE_RMODE_BASE + 0x18]
	mov		ebp, ebx
	cli

	call	ebp

    cli
	hlt