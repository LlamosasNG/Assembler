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
; Configuración inicial
MOV #0xFFFF, W0       ; Configura todos los pines como digitales
MOV W0, AD1PCFGL      ; Desactivar modo analógico en todos los pines de PORTB

MOV #0xFFC0, W0       ; Configura RB0-RB9 como salida, RB10-RB15 como entrada
MOV W0, TRISB         ; Configurar las direcciones
CLR PORTB             ; Apagar todos los LEDs al inicio

; Animación que enciende secuencialmente RB0 a RB9
anim_all:
    MOV #1, W2         ; Inicia con el bit más bajo (0000 0000 0000 0001)
anim_loop:
    MOV W2, PORTB      ; Mostrar el valor de W2 en los LEDs
    CALL delay         ; Llamar al retardo
    RLC W2, W2         ; Rotar a la izquierda
    MOV #0x0400, W3    ; Límite de rotación (hasta RB9)
    CP W2, W3          ; Verificar si se alcanzó RB9
    BRA NZ, anim_loop  ; Continuar si no se ha completado el ciclo
    BRA anim_all       ; Reiniciar animación

; Subrutina de retardo
delay:
    MOV #1000, W4      ; Valor de retardo
delay_loop:
    DEC W4, W4         ; Decrementar el contador
    CP0 W4
    BRA NZ, delay_loop ; Repetir hasta que W4 sea 0
    RETURN 
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
