
; ------------------------------------------------------------------
; VandOS Stage Two Bootloader Version 1.0
;
; The current version supports FAT12. Later versions will use 
; better FSs.
;
; This programs loads the VandOS Kernel
; in the root directory under the name : KERNEL.BIN.
; The KERNEL.BIN will be executed at ??.
;
; Very first bootloader by Oryk
; These projects helped me develop the program:
; 		http://www.brokenthorn.com/Resources/OSDev0.html
; 		MikeOS (http://mikeos.sourceforge.net/)
; ------------------------------------------------------------------


ORG 1FC0h
BITS 16

main:
	
; ------------------------------------------------------------------
;	FUNCTIONS
; ------------------------------------------------------------------
	
; ------------------------------------------------------------------
; fat12_load_fat
; IN:	AX	- Size of FAT (sectors)
;		
; OUT:	Data @mem address
;
; ------------------------------------------------------------------
fat12_load_fat:
	PUSHA
	
	
	
	POPA
	RET
; ------------------------------------------------------------------
; fat12_load_root
; IN:	AX 	- Address to load dir to
;
; OUT:	Data @mem address
;
; ------------------------------------------------------------------
fat12_load_root:
	PUSHA

	MOV BX, AX
	
	MOV AX, 19					; Root dir starts at logical sector 19
	MOV CL, 14
	
	CALL load_floppy_sector
	
	JNC .success
	
	MOV SI, [msg_root_failure]
	CALL print_string
	POPA
	
.success:
	
	MOV SI, [msg_root_success]
	CALL print_string
	
	POPA
	RET
; ------------------------------------------------------------------
; load_floppy_sector
; IN:	AX 	- LBA
;		BX	- Address
;		CL	- Count (sectors)
; OUT:	Data @mem address
;		CF set, if failed
; ------------------------------------------------------------------
load_floppy_sector:
	PUSH AX
	PUSH BX
	PUSH CX
	PUSH DX
	
	XOR CH			; We cant use upper
	PUSH CX			; Store
	
	CALL lba_to_chs

	POP AX			; Get Count
	MOV AH, 2		; BIOS
	
	STC
	INT 13h

	PUSH DX
	PUSH CX
	PUSH BX
	PUSH AX
	
	RET

; ------------------------------------------------------------------
; lba_to_chs
; IN:	AX		- LBA
;
; OUT:	CL 		- Sector
;		CH		- Track
;		DH		- Head
;		
;		This way the registers are set up for the interrupt 13h
;
; ------------------------------------------------------------------
lba_to_chs:
	PUSH AX

	XOR DX, DX
	DIV WORD [sectors_per_track]		; (LBA % sectors per track) + 1
	INC DL
	MOV CL, DL							; Sector
	; AX contains now the (LBA / sectors per track)
	XOR DX, DX
	DIV WORD [sides]					; (sectors/track) %  nr of heads
	MOV DH, DL							; Head
	MOV CH, AL							; Track

	POP AX
	
	MOV DL, [boot_device]
	
	RET
	
; ------------------------------------------------------------------
; print_string
; IN:	SI		- String
;
; OUT:	NOTHING
;
; ------------------------------------------------------------------
print_string:
	PUSHA
	
.character:
	LODSB
	OR AL, AL
	JNZ .finished
	
	MOV AH, 0Eh
	INT 10h
	JMP .character

.finished:
	POPA
	RET
; ------------------------------------------------------------------
;	DATA
; ------------------------------------------------------------------

kernel_name 					db	"KERNEL  BIN"

msg_root_success				db	"Successfully loaded FAT12 root dir into memory.", 10, 13, 0
msg_root_failure				db	"Failed to load FAT12 root dir into memory.", 10, 13, 0


;	TODO REMOVE THIS AND LOAD THE DATA IF NEEDED (btw it's still in memory)
bytes_per_sector				dw	0x0200
sectors_per_cluster				db	1
reserved_sectors				dw	1
number_of_fats					db	2
root_entries					dw	244
sectors_per_fat					dw	9
sectors_per_track				dw	18
sides							dw	2