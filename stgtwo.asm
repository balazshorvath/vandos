
; ------------------------------------------------------------------
; Very first bootloader by Oryk
; Some of the source are from this guide:
; http://www.brokenthorn.com/Resources/OSDev0.html
; ------------------------------------------------------------------

ORG 0
BITS 16

start:
	CLI
	PUSH CS		; Data segment must be the same
	POP DS		; as the code segment.
	
	MOV SI, stage_two_welcome
	CALL print_string
	
	CLI
	HLT

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
	LODSB		; Load from SI to AL
	OR AL, AL	; 0 ? finished
	JZ .finished
	MOV AH, 0Eh
	INT 10h
	JMP print_string
	
.finished:
	RET
	
	
	
stage_two_welcome:			db	"Welcome to stage two of the booting process!! Yippie!!", 13, 10, 0