/*
 * File:   %<%NAME%>%.%<%EXTENSION%>%
 * Author: %<%USER%>%
 *
 * Created on %<%DATE%>%, %<%TIME%>%
 */

    .include "p33fj32mc202.inc"

    ; _____________________Configuration Bits_____________________________
    ;User program memory is not write-protected
    #pragma config __FGS, GWRP_OFF & GSS_OFF & GCP_OFF
    
    ;Internal Fast RC (FRC)
    ;Start-up device with user-selected oscillator source
    #pragma config __FOSCSEL, FNOSC_FRC & IESO_ON
    
    ;Both Clock Switching and Fail-Safe Clock Monitor are disabled
    ;XT mode is a medium-gain, medium-frequency mode that is used to work with crystal
    ;frequencies of 3.5-10 MHz
  ; #pragma config __FOSC, FCKSM_CSDCMD & POSCMD_XT
    
    ;Watchdog timer enabled/disabled by user software
    #pragma config __FWDT, FWDTEN_OFF
    
    ;POR Timer Value
    #pragma config __FPOR, FPWRT_PWR128
   
    ; Communicate on PGC1/EMUC1 and PGD1/EMUD1
    ; JTAG is Disabled
    #pragma config __FICD, ICS_PGD1 & JTAGEN_OFF

;..............................................................................
;Program Specific Constants (literals used in code)
;..............................................................................

    .equ SAMPLES, 64         ;Number of samples

;..............................................................................
;Global Declarations:
;..............................................................................

    .global _wreg_init       ;Provide global scope to _wreg_init routine
                                 ;In order to call this routine from a C file,
                                 ;place "wreg_init" in an "extern" declaration
                                 ;in the C file.

    .global __reset          ;The label for the first line of code.

;..............................................................................
;Constants stored in Program space
;..............................................................................

    .section .myconstbuffer, code
    .palign 2                ;Align next word stored in Program space to an
                                 ;address that is a multiple of 2
ps_coeff:
    .hword   0x0002, 0x0003, 0x0005, 0x000A

MESSAGE1:
.BYTE   0X01, 0X02, 0X04, 0X08, 0X10, 0X20, 0X40, 0X80, 0X00	
	;If you want to use the just 8 bits

MESSAGE2:
.WORD	0X0001, 0X0002, 0X0004, 0X0008, 0X0010, 0X0020, 0X0040, 0X0080, 0X0100,	0X0200, 0X0400, 0X0800, 0X1000, 0X0000
	;If you want to use the full word

STRING1:
    .string "Newatl niktlasotla in sentsontototl ikwikaw, newatl niktlasotla in chalchiwitl itlapalis iwan in awiakmeh"
    .string "xochimeh; san ok senka noikniwtsin in tlakatl, Newatl niktlasotla @"

;..............................................................................
;Uninitialized variables in X-space in data memory
;..............................................................................

    .section .xbss, bss, xmemory
x_input: .space 2*SAMPLES        ;Allocating space (in bytes) to variable.

;..............................................................................
;Uninitialized variables in Y-space in data memory
;..............................................................................

    .section .ybss, bss, ymemory
y_input:  .space 2*SAMPLES


;..............................................................................
;Uninitialized variables in Near data memory (Lower 8Kb of RAM)
;..............................................................................

    .section .nbss, bss, near
var1:     .space 2               ;Example of allocating 1 word of space for
                                 ;variable "var1".
				 
;..............................................................................
;Code Section in Program Memory
;..............................................................................

.text                             ;Start of Code section
__reset:
    MOV #__SP_init, W15       ;Initalize the Stack Pointer
    MOV #__SPLIM_init, W0     ;Initialize the Stack Pointer Limit Register
    MOV W0, SPLIM
    NOP                       ;Add NOP to follow SPLIM initialization

    CALL _wreg_init           ;Call _wreg_init subroutine
                                  ;Optionally use RCALL instead of CALL

;<<insert more user code here>>
;The program space address set contains 24 bits <23..0>
;TBLPAG takes the most significant byte of this set <22..16>
;the remaining is called Data Effective Address "EA" <15..0> which 
;is compatible with data space addressing.

; Setup the address pointer to program space
MOV #tblpage(MESSAGE1), W0    ; get table page value <22:16>
MOV W0, TBLPAG		     ; load TBLPAG register

A1:
    MOV #tbloffset(MESSAGE1), W1 ; load address LS word

A2:
    ; Read the program memory location
    ;TBLRDL [W1++], W4	    ; Read low word to W4 16 bits
    TBLRDL.B [W1++], W4	    ; Read low word to W4 just 8 bits
    CP0 W4
    BRA Z, A1
    MOV W4, PORTB
    NOP
    BRA A2
;..............................................................................
;Subroutine: Initialization of W registers to 0x0000
;..............................................................................

_wreg_init:
    CLR W0
    MOV W0, W14
    REPEAT #12
    MOV W0, [++W14]
    CLR W14
    RETURN

;--------End of All Code Sections ---------------------------------------------

.end                               ;End of program code in this file
