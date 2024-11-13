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
		
SETM    AD1PCFGL	;PORTB AS DIGITAL
CLR	TRISB		;PORTB AS OUTPUTS
SETM	PORTB		;PORTB = 0XFFFF
MOV	#0X4087, W0				  				  
MOV	W0, 0X0800	;Example of store in a specific address
	
MOV	#0X0800, W1	;W1 as a pointer of the address 0x0800
MOV	[W1++], W2	;Get data from specific address using a pointer

Tiempo:
    MOV #20000, W7
    
    LOOP1:
	CP0 W7		    ;(1 Cycle)
	BRA Z, END_DELAY    ;(1 Cycle if not jump)
	DEC W7, W7	    ;(1 Cycle)
	MOV #10, W8	    ;(1 Cycle)
	
    LOOP2:
	DEC W8, W8	    ;(1 Cycle)
	CP0 W8		    ;(1 Cycle)
	BRA Z, LOOP1	    ;(1 Cycle if not jump)
	BRA LOOP2	    ;(2 Cycle if jump)
   
    END_DELAY:
	NOP
	CALL Tiempo
        
    done:		    ;INFINITE LOOP    
	COM PORTB
	NOP
	BRA done            ;Place holder for last line of executed code

/* Exercise 1 */
/* 
MOV     #0X0800, W1    ; Inicializar W1 con la direcci�n base 0x0800
CLR     W0             ; Inicializar W0 con el valor 0 (valor a almacenar)

LOOP:
    MOV     W0, [W1]       ; Almacenar el valor de W0 en la direcci�n apuntada por W1
    ADD     #2, W1         ; Incrementar W1 para apuntar a la siguiente direcci�n (0x0802, 0x0804, etc.)
    ADD     #1, W0         ; Incrementar el valor en W0 (para almacenar 1, 2, 3, etc.)
    CP      W0, #10        ; Comparar el valor de W0 con 10 (l�mite para este ejemplo)
    BRA     LT, LOOP       ; Si W0 es menor que 10, repetir el ciclo
				  			  
MOV	#0X4087,    W0
*/
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
