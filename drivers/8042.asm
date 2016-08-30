
%ifndef __VANDOS_KEYBOARD_DRIVER_8042__
%define __VANDOS_KEYBOARD_DRIVER_8042__

; ------------------------------------------------------------------
; VandOS Keyboard/Mouse Driver Version 0.1
;
; For 8042 Microcontroller
;
;	Keyboard Command	Descripton
;	0x20				Read Keyboard Controller Command Byte
;	0x60				Write Keyboard Controller Command Byte
;	0xAA				Self Test
;	0xAB				Interface Test
;	0xAD				Disable Keyboard
;	0xAE				Enable Keyboard
;	0xC0				Read Input Port
;	0xD0				Read Output Port
;	0xD1				Write Output Port
;	0xDD				Enable A20 Address Line
;	0xDF				Disable A20 Address Line
;	0xE0				Read Test Inputs
;	0xFE				System Reset
;
;	Mouse Command		Descripton
;	0xA7				Disable Mouse Port
;	0xA8				Enable Mouse Port
;	0xA9				Test Mouse Port
;	0xD4				Write to mouse
;
; NOTE: You can find the "enable A20 function" in this file,
; 		since it can be done through this controller.
;
; Help: http://wiki.osdev.org/%228042%22_PS/2_Controller
;		http://www.brokenthorn.com/Resources/OSDev9.html
;
; By Oryk
; ------------------------------------------------------------------


BITS 16

; ******************************************************************
; BASIC FUNCTIONALITIES - (WAIT IO, SEND COMMAND)
; ******************************************************************

; ------------------------------------------------------------------
; _8042_enable_a20_command
;
;	IN/OUT: NOTHING
;
; Sends command to port 64h.
; 
; ------------------------------------------------------------------
_8042_enable_a20_command:
	MOV AL, 0DDh
	OUT 64h, AL
	RET

; ------------------------------------------------------------------
; _8042_disable_a20_command
;
;	IN/OUT: NOTHING
; 
; Sends command to port 64h.
;
; ------------------------------------------------------------------
_8042_disable_a20_command:
	MOV AL, 0DFh
	OUT 64h, AL
	RET
; ------------------------------------------------------------------
; _8042_read_output
;
;	IN:		NOTHING
;	OUT:	EAX
; 
; Sends command to port 64h.
;
; ------------------------------------------------------------------
_8042_read_output:
	PUSH AX
	
	MOV AL, 0D0h
	OUT 64h, AL
	CALL _8042_wait_output_buffer
	
	IN AL, 60h
	
	POP AX
	RET

	
	

; ******************************************************************
; BASIC FUNCTIONALITIES - (WAIT IO, SEND COMMAND)
; ******************************************************************

; ------------------------------------------------------------------
; _8042_wait_input_buffer
; 
; Wait for the controller's input buffer, until it's empty.
;
; ------------------------------------------------------------------

_8042_wait_input_buffer:
	IN AL, 64h
	TEST AL, 2
	JNZ _8042_wait_input_buffer
	RET
; ------------------------------------------------------------------
; _8042_wait_output_buffer
; 
; Wait for the controller's output buffer, until it's full.
;
; ------------------------------------------------------------------

_8042_wait_output_buffer:
	IN AL, 64h
	TEST AL, 1
	JNZ _8042_wait_output_buffer
	RET
	
%endif
