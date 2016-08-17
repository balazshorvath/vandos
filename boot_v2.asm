
; ------------------------------------------------------------------
; Very first bootloader by Oryk
; Some of the source are from this guide:
; http://www.brokenthorn.com/Resources/OSDev0.html
; + MikeOS
; ------------------------------------------------------------------


ORG 0
BITS 16
start: JMP main

; ------------------------------------------------------------------
;	BIOS Parameter Block
; ------------------------------------------------------------------

oem						db	"VANDOS  "
bytes_per_sector		dw	0x0200
sectors_per_cluster		db	1
reserved_sectors		dw	1
number_of_fats			db	2
root_entries			dw	244		; Max dris inside root in fat12
total_secors			dw	2880	; 18 sector/track * 80 tracks/side = 2880 * 2 sides = 1440*2 in case of a floppy
media					db	0xF0	; Bit 0 - sides 0=1, 1=2
									; Bit 1 - sectors/FAT 0=9, 1=8
									; Bit 2 - density 0=80 tracks, 1=40 tracks
									; Bit 3 - fixed/removable disk (0/1)
									; Rest is unsused, always 1
sectors_per_fat			dw	9
sectors_per_track		dw	18
heads_per_cylinder		dw	2
hidden_sectors			dd	0
total_sectors_big		dd	0		; No idea, what this is and why is it zero
drive_number			dw	0		; Floppy's drive nr is 0
;unsused:				db	0		; I think it's just an unused byte...
ext_boot_signature		db	41		; Version of BIOS Parameter Block (4.0)
volume_id				dd	0xA0A1A2A1; This is a unique identifier, when formatted, it's generated
volume_label			db	"VANDOS     "; 11 bytes
file_system				db	"FAT12   "

main:
	;----------------------------------
	; Setup segment registers
	;						boot			stack	 		buffer, or whatever
	;	|--	07C0h	--|--	0200h	--|--	0200h	--|--	Starts at 0BC0h		--|
	MOV AX, 09C0h	; Exactly above the bootloader
	CLI

	MOV SS, AX
	MOV SP, 0200h	; 512 bytes has to be enough
	
	STI
	
	MOV AX, 07C0h	; DS should be 07C0h
	MOV DS, AX
	MOV ES, AX
	
	;----------------------------------

	;----------------------------------
	; COPIED FROM MIKEOS
	; NOTE: A few early BIOSes are reported to improperly set DL

	CMP DL, 0
	JE no_change
	MOV [bootdev], DL			; Save boot device number
	
	MOV AH, 8					; Get drive parameters
	INT 13h
	
	JC boot_failure
	
	AND CX, 3Fh					; Maximum sector number
	MOV [sectors_per_track], CX	; Sector numbers start at 1
	MOVZX DX, DH				; Maximum head number
	ADD DX, 1					; Head numbers start at 0 - add 1 for total
	MOV [heads_per_cylinder], DX

no_change:
	XOR EAX, EAX				; Needed for some older BIOSes
	
	; END OF COPY
	;----------------------------------
	
	MOV AX, 19					; Root dir starts at logical sector 19
	CALL lba_to_chs
	
	MOV BX, BUFFER
	MOV AH, 2					; Function
	MOV AL, 14					; Amount
	
	MOV CX, 5
	
read_root:
	PUSHA
	
	STC
	INT 13h
	JNC search_stage_two		; If CF not set, we're good
	
	XOR AX, AX					; Reset
	INT 13h
	
	POPA
	LOOP read_root
	JMP boot_failure
search_stage_two:
	POPA

; ------------------------------------------------------------------
; lba_to_chs
; IN:	AX		- LBA addresss
;
; OUT:	DL 		- Sector
;		DH		- Head
;		CH		- Track
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
	DIV WORD [heads_per_cylinder]		; (sectors/track) %  nr of heads
	MOV DH, DL							; Head
	MOV CH, AL							; Track

	POP AX
	
	RET
	
	
boot_failure:
	MOV AH, 0
	INT 16h				; Wait for key
	MOV AH, 0
	INT 19h				; Reboot
; ------------------------------------------------------------------
;	DATA
; ------------------------------------------------------------------

BUFFER							equ	0BC0h

boot_device						db	0
cluster							dw	0
pointerdw						dw	0

stage_two_name 					db	"STGTWO  BIN"
	
msg_started 					db	"S1", 10, 13, 0

msg_root_dir 					db	"RD", 10, 13, 0
msg_fat	 						db	"FAT", 10, 13, 0
msg_stage_two					db	"LS2", 10, 13, 0
msg_find_stage_two				db	"FS2", 10, 13, 0

msg_finished 					db	"Done", 10, 13, 0

times 510 - ($-$$) db 0

boot_end dw 0xAA55

