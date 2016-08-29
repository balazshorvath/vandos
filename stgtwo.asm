
; ------------------------------------------------------------------
; VandOS Stage Two Bootloader Version 0.1
;
; The current version supports FAT12. Later versions will use 
; better FSs.
;
; The program will be loaded by STGONE @ 1FC0h
;
; The goals of Stage Two:
; 		- Prepare the CPU to switch to protected mode
;
;
; These projects helped me develop the program:
; 		http://www.brokenthorn.com/Resources/OSDev0.html
;
; By Oryk
; ------------------------------------------------------------------

ORG 
BITS 16

start:

; ------------------------------------------------------------------
; print_string
; IN:	SI - string
; OUT:	NOTHING
;
;	INT 10h
;		AH - 0Eh
;		AL - Character
; ------------------------------------------------------------------
print_string:
	PUSHA
	LODSB		; Load from SI to AL
	OR AL, AL	; 0 ? finished
	JZ .finished
	MOV AH, 0Eh
	INT 10h
	JMP print_string
	
.finished:
	POPA
	RET
	
	
	
stage_two_welcome:			db	"Welcome to stage two of the booting process!! Yippie!!", 13, 10, 0