
; ------------------------------------------------------------------
; Very first bootloader by Oryk
; Some of the source are from this guide:
; http://www.brokenthorn.com/Resources/OSDev0.html
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
	CLI
	; -------------------------------------------
	; Init segment registers.
	MOV AX, 07C0h
	
	MOV DS, AX
	MOV ES, AX
	MOV FS, AX
	MOV GS, AX
	
	; -------------------------------------------
	; Create stack
	MOV AX, 0000h
	MOV SS, AX
	MOV SP, 0xFFFF
	
	STI
	
	; -------------------------------------------
	; Boot process - Root dir
	
	MOV BX, 0200h						; Load after the bootloader
	CALL fat12_load_root_dir			; AX - Location [LBA], CX - Size, CF - Set if failed
	
	JC load_root_failed
	
	MOV SI, msg_started
	CALL print_string
	
	ADD CX, AX
	MOV WORD [lba_data_sector], CX
	
	; -------------------------------------------
	; Boot process - Find stage two
	
	MOV DI, 0200h
	MOV SI, stage_two_name				; Filename
	
	CALL fat12_find_file
	
	JC read_stage_failed
	
	MOV SI, msg_started
	CALL print_string
	
	MOV BX, WORD [DI + 001Ah]			; In the directory table, the 26-27 bytes represent the 
	MOV WORD [stage_two_cluster], BX	; fist cluster of the file
	
	; -------------------------------------------
	; Boot process - Load FAT
	
	MOV BX, 0200h
	
	CALL fat12_load_fat
	
	JC load_fat_failed
	
	; -------------------------------------------
	; Boot process - Load file
	
	; Load the file to 0050h:0000
	; No idea, why. The guides does this, so I won't mess around with this.
	
	MOV AX, 0050h
	MOV ES, AX
	MOV BX, 0000h
	MOV AX, WORD [stage_two_cluster]
	
	CALL fat12_load_file
	
	JC load_stage_failed
	
	MOV SI, msg_finished
	CALL print_string
	
	PUSH 0050h	; RETF : Pops IP, then CS
	PUSH 0000h	
	
	RETF

load_root_failed:
	MOV SI, msg_error_root_dir
	JMP failure
load_fat_failed:
	MOV SI, msg_error_fat
	JMP failure
read_stage_failed:
	MOV SI, msg_error_find_stage_two
	JMP failure
load_stage_failed:
	MOV SI, msg_error_stage_two
failure:
	CALL print_string
	MOV AH, 0
	INT 16h				; Wait for key
	MOV AH, 0
	INT 19h				; Reboot
	
	
; ------------------------------------------------------------------
; Console via BIOS
; ------------------------------------------------------------------

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

; ------------------------------------------------------------------
; Disk utils
; ------------------------------------------------------------------

; ------------------------------------------------------------------
; cluster_to_lba
; IN:	AX - Cluster addresss
;		BX - The first data sector
;
; OUT:	AX - LBA
;		
; Some explanation maybe useful: http://stackoverflow.com/questions/5774164/lba-and-cluster
; Still not sure though, why is it -2.
; ------------------------------------------------------------------
cluster_to_lba:
	ADD AX, 31
;	SUB AX, 2
	
;	XOR CX, CX
;	MOV CL, BYTE [sectors_per_cluster]
;	MUL CX
	
;	ADD AX, BX
	
	RET

; ------------------------------------------------------------------
; lba_to_chs
; IN:	AX - LBA addresss
; 		BX - Address to copy data to: 
;
; OUT:	BX 		- Sector
;		BX + 1	- Head
;		BX + 2	- Track
;		
; ------------------------------------------------------------------
lba_to_chs:
	PUSH DX

	XOR DX, DX
	DIV WORD [sectors_per_track]		; sector: (LBA % sectors per track) + 1
	INC DL
	MOV BYTE [BX], DL					; First byte
	
	XOR DX, DX
	DIV WORD [heads_per_cylinder]		; head (sectors/track) %  nr of heads
	MOV BYTE [BX + 1], DL				; Second byte
	
	MOV BYTE [BX + 2], AL				; Third byte
	
	POP DX
	RET

; ------------------------------------------------------------------
; fat12_load_file
;
; IN:	ES:BX - Memory location to load to
;		AX - Cluster
;		DI - FAT
;
; OUT:	CF - Set, if failed
; 
; ------------------------------------------------------------------
fat12_load_file:
	PUSH AX
	
	CALL cluster_to_lba
	
	XOR CX, CX
	MOV CL, BYTE [sectors_per_cluster]
	
	CALL read_sectors
	
	;JC load_stage_failed
	
	POP AX
	
	MOV CX, AX
	MOV DX, AX
	
	SHR DX, 1			; Division by two
	ADD CX, DX			; 3/2 of cluster val.
	
	ADD DI, CX
	MOV DX, WORD [DI]
	
	TEST AX, 1			; Test for parity
	JNZ .odd_cluster

	; Even => low 12 bits
	AND DX, 0FFFh
	JMP .next_cluster
	
.odd_cluster:
	; High 12 bits
	SHR DX, 4
.next_cluster:
	CMP AX, 0FF0h
	JB fat12_load_file
	
	RET
; ------------------------------------------------------------------
; read_sectors
;
; IN:	AX - Start position [LBA]
;		CL - Number of sectors to read
;		ES:BX - Buffer
;
; OUT:	CF - Set if failed
;
; ------------------------------------------------------------------
read_sectors:
	PUSH CX
	MOV CX, 0005h				; Try 5 times
.sector:
	; -------------------------------------------
	; Try reading 1 sector
	PUSH AX						; AX, BX, CX are used
	PUSH CX
	PUSH BX
	
	
	MOV SI, [load_fat_failed]
	CALL print_string
	
	MOV BX, chs_address			; Initialize and call
	CALL lba_to_chs

	POP BX						; Get BX
	
	MOV AH, 02h					; BIOS function
	MOV AL, 01h					; Sectors to read
	
	MOV CL, BYTE [chs_address]		; Sector
	MOV CH, BYTE [chs_address + 2]	; Track
	MOV DH, BYTE [chs_address + 1]	; Head
	MOV DL, BYTE [drive_number]		; Drive number
	
	STC
	INT 13h	
	
	MOV SI, [load_fat_failed]
	CALL print_string
	
	POP CX						; Get CX
	; -------------------------------------------
	
	JNC .success				; Test for success
	
	XOR AX, AX
	INT 13h						; Reset disk
	
	POP AX						; Get AX
	LOOP .sector
	; Finally if everything failed
	POP CX
	
	STC
	RET
.success:
	POP AX
	POP CX
	
	ADD BX, WORD [bytes_per_sector]
	INC AX
	
	LOOP read_sectors
	CLC	; Success
	RET
	
	
; ------------------------------------------------------------------
; fat12_load_root_dir
;
; IN:	BX - Memory location to load to
;
; OUT:	AX - Location [LBA]
;		CX - Size
; 		CF - Set if failed
; ------------------------------------------------------------------
fat12_load_root_dir:
	; Size of root directory
	MOV AX, 0020h				; 32 bytes / entry (244)
	MUL WORD [root_entries]		; entries * 32
	DIV WORD [bytes_per_sector]	; (244*32)/512
	
	XCHG AX, CX
	; Location of root directory
	XOR AX, AX
	MOV AL, BYTE [number_of_fats]
	MUL WORD [sectors_per_fat]
	ADD AX, WORD [reserved_sectors]
	
	MOV BX, 0200h
	CALL read_sectors ; Sets CF, if failed
	
	RET
	
; ------------------------------------------------------------------
; fat12_find_file
;
; IN:	DI - Memory location to the first entry
;		SI - Filename
;
; OUT:	CF - Set if failed
; 		DI - Memory location to the entry found
; 
; ------------------------------------------------------------------
fat12_find_file:
	PUSH AX
	MOV CX, [root_entries]
	MOV AX, SI
	
.loop:
	MOV SI, AX
	CALL print_string
	MOV SI, AX
	
	MOV CX, 000Bh		; 11 bytes
	
	REP CMPSB			; Compare CX amount of bytes
	
	JE .found
	
	ADD DI, 0020h		; Next Directory
	
	LOOP .loop
	PUSH AX
	STC					; If not found, set CF
	RET
	
.found:
	SUB DI, 11
	PUSH AX
	CLC					; Found, unset CF
	RET

; ------------------------------------------------------------------
; fat12_load_fat
;
; IN:	BX - Memory location to load to
;
; OUT:	CF - Set, if failed
; 
; ------------------------------------------------------------------
fat12_load_fat:
	PUSH AX
	PUSH CX
	; Size of FAT
	XOR AX, AX
	MOV AL, BYTE [number_of_fats]
	MUL WORD [sectors_per_fat]
	MOV CX, AX
	; Location of FAT
	MOV AX, WORD [reserved_sectors]
	
	CALL read_sectors ; Sets CF, if fails

	POP CX
	POP AX
	RET
	
; ------------------------------------------------------------------
; End of disk utils
; ------------------------------------------------------------------
	
	
chs_address 		times	3	db	0

; Important, this is the first data sector on the disk
lba_data_sector					dw	0
stage_two_name 					db	"STGTWO  BIN"
stage_two_cluster				dw	0
	
msg_started 					db	"S1", 10, 13, 0

msg_error_root_dir 				db	"E:RD", 10, 13, 0
msg_error_fat	 				db	"E:FAT", 10, 13, 0
msg_error_stage_two				db	"E:LS2", 10, 13, 0
msg_error_find_stage_two		db	"E:FS2", 10, 13, 0

msg_finished 					db	"Done", 10, 13, 0

times 510 - ($-$$) db 0

boot_end dw 0xAA55
