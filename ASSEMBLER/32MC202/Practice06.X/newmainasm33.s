/*
 * File:   %<%NAME%>%.%<%EXTENSION%>%
 * Author: %<%USER%>%
 *
 * Created on %<%DATE%>%, %<%TIME%>%
 */

    .include "p33fj32mc202.inc"

    ; ____________________Configuration Bits____________________________
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
    
Poema:
 .string "   HOLA NOE@"
	
	
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

    MOV     #0xFFFF, W0       ; Configura todos los pines como digitales
    MOV     W0, AD1PCFGL      ; Desactiva el modo analógico en todos los pines de PORTB

    ; Configurar PORTB como salida
    CLR	    TRISA   ; Configurar todos los pines de LATA como salida
    CLR	    LATA    ; Inicializar los valores de LATA en 0
    CLR     TRISB              ; Configurar PORTB como salida
    CLR     LATB               ; Inicializar PORTB en 0

    ;---------------------------------------------------------
    ; Variables y registros de trabajo
    ;---------------------------------------------------------
    CLR     W1                 ; Contador de tiempo (0, 1, 2)
    CLR     W2                 ; Contador de animación (0, 1, 2)
    MOV #0x0041, W3
    MOV #32, W7
    MOV #12, W12
    CLR     W6                 ; Contador de display (0 a 3)
    CLR     W11                ; Contador de desplazamiento del arreglo (offset)

main_loop:
    ; Configurar la dirección base de "Poema" con desplazamiento
    MOV #tblpage(Poema), W0     ; Cargar la página alta de "Poema"
    MOV W0, TBLPAG              ; Cargarla en TBLPAG
    MOV #tbloffset(Poema), W5   ; Cargar la dirección base de "Poema" en W5

    ; Sumar el desplazamiento del arreglo al inicio del arreglo
    ADD W11, W5, W5             ; Desplazar la dirección base usando W11

    ; Reiniciar contador de displays
    CLR W6                      ; Reiniciar contador de displays

display_loop:
    ; Activar el display correspondiente
    MOV W6, W0                  ; Copiar el contador a W0
    CALL ActivarDisplay         ; Activar el display correspondiente

    ; Calcular la dirección del carácter en la tabla
    MOV W5, W10                 ; Copiar la dirección base a W10
    ADD W6, W10, W10            ; Sumar el desplazamiento (W6) a la dirección base

    ; Leer el carácter correspondiente
    TBLRDL.B [W10], W4          ; Leer el carácter desde la tabla usando W10

    ; Decodificar y enviar al LATB
    CALL Letra
    MOV W4, LATB                ; Escribir en LATB para mostrar el carácter

    ; Retardo breve para mantener la multiplexación estable
    CALL delay_multiplex

    ; Incrementar el contador de displays
    INC W6, W6                  ; Incrementar W6 en 1
    CP W6, #4                   ; ¿Llegó al último display?
    BRA NZ, display_loop        ; Si no, continuar con el siguiente display

    ; Desplazar el poema después de completar todos los displays
    INC W11, W11                ; Avanzar al siguiente carácter del poema
    CP W11, W12                 ; Longitud del poema
    BRA NZ, delay_scroll        ; Si no se alcanza el final, aplicar retardo
    CLR W11                     ; Reiniciar desplazamiento del arreglo

delay_scroll:
    CALL delay_very_long        ; Retardo largo para desplazamiento 
    BRA main_loop               ; Repetir ciclo
    
ActivarDisplay:
    ; Activa el display correspondiente usando LATA con intermediario
    CP W0, #0
    BRA Z, EncenderD1
    CP W0, #1
    BRA Z, EncenderD2
    CP W0, #2
    BRA Z, EncenderD3
    CP W0, #3
    BRA Z, EncenderD4
    RETURN

EncenderD1:
    MOV #1, W1     ; Coloca el valor para el primer display en W1
    MOV W1, LATA        ; Escribe en LATA
    RETURN

EncenderD2:
    MOV #2, W1     ; Coloca el valor para el segundo display en W1
    MOV W1, LATA        ; Escribe en LATA
    RETURN

EncenderD3:
    MOV #4, W1     ; Coloca el valor para el tercer display en W1
    MOV W1, LATA        ; Escribe en LATA
    RETURN

EncenderD4:
    MOV #16, W1     ; Coloca el valor para el cuarto display en W1
    MOV W1, LATA        ; Escribe en LATA
    RETURN

Letra:
    CP W4, W3 ;A
    bra z, Cambio1
    ADD W3, #1, W3
    
    CP W4, W3 ;B
    bra z, Cambio2
    ADD W3, #1, W3
    
    CP W4, W3 ;C
    bra z, Cambio3
    ADD W3, #1, W3
    
    CP W4, W3;D
    bra z, Cambio4
    ADD W3, #1, W3
    
    CP W4, W3;E
    bra z, Cambio5
    ADD W3, #1, W3
    
    CP W4, W3;F
    bra z, Cambio6
    ADD W3, #1, W3
    
    CP W4, W3;G
    bra z, Cambio7
    ADD W3, #1, W3
    
    CP W4, W3;H
    bra z, Cambio8
    ADD W3, #1, W3
    
    CP W4, W3;I
    bra z, Cambio9
    ADD W3, #1, W3
    
    CP W4, W3;J
    bra z, CambioA
    ADD W3, #1, W3
    
    CP W4, W3;K
    bra z, CambioB
    ADD W3, #1, W3
    
    CP W4, W3;L
    bra z, CambioC
    ADD W3, #1, W3
    
    CP W4, W3;M
    bra z, CambioD
    ADD W3, #1, W3
    
    CP W4, W3;N
    bra z, CambioE
    ADD W3, #1, W3
    
    CP W4, W3;O
    bra z, CambioF
    ADD W3, #1, W3
    
    CP W4, W3;P
    bra z, Cambio10
    ADD W3, #1, W3
    
    CP W4, W3;Q
    bra z, Cambio11
    ADD W3, #1, W3
    
    CP W4, W3;R
    bra z, Cambio12
    ADD W3, #1, W3
    
    CP W4, W3;S
    bra z, Cambio13
    ADD W3, #1, W3
    
    CP W4, W3;T
    bra z, Cambio14
    ADD W3, #1, W3
    
    CP W4, W3;U
    bra z, Cambio15
    ADD W3, #1, W3
    
    CP W4, W3;V
    bra z, Cambio16
    ADD W3, #1, W3
    
    CP W4, W3;W
    bra z, Cambio17
    ADD W3, #1, W3
    
    CP W4, W3;X
    bra z, Cambio18
    ADD W3, #1, W3
    
    CP W4, W3;Y
    bra z, Cambio19
    ADD W3, #1, W3
    
    CP W4, W3;Z
    bra z, Cambio1A
    
    CP W4, W7; ESPACIO
    bra z, cambioEspacio
    bra nada
    return
    
Cambio1:
    MOV #0x0041, W3
    mov #1262, w4;A
    return
Cambio2:
    MOV #0x0041, W3
    mov #239, w4;B
    return
Cambio3:
    MOV #0x0041, W3
    mov #6399, w4;C
    return
Cambio4:
    MOV #0x0041, W3
    mov #15485, w4;D
    return
Cambio5:
    MOV #0x0041, W3
    mov #6382, w4;E
    return
Cambio6:
    MOV #0x0041, W3
    mov #7406, w4;F
    return
Cambio7:
    MOV #0x0041, W3
    mov #4335, w4;G
    return
Cambio8:
    MOV #0x0041, W3
    mov #9454, w4;H
    return
Cambio9:
    MOV #0x0041, W3
    mov #7099, w4;I
    return
CambioA:
    MOV #0x0041, W3
    mov #6587, w4;J
    return
CambioB:
    MOV #0x0041, W3
    mov #15575, w4;K
    return
CambioC:
    MOV #0x0041, W3
    mov #14591, w4;L
    return
CambioD:
    MOV #0x0041, W3
    mov #9311, w4;M
    return
CambioE:
    MOV #0x0041, W3
    mov #9335, w4;N
    return    
CambioF:
    MOV #0x0041, W3
    mov #255, w4;O
    return
Cambio10:
    MOV #0x0041, W3
    mov #3310, w4;P
    return
Cambio11:
    MOV #0x0041, W3
    mov #247, w4;Q
    return
Cambio12:
    MOV #0x0041, W3
    mov #3302, w4;R
    return
Cambio13:
    MOV #0x0041, W3
    mov #4846, w4;S
    return
Cambio14:
    MOV #0x0041, W3
    mov #8123, w4;T
    return
Cambio15:
    MOV #0x0041, W3
    mov #8447, w4;U
    return
Cambio16:
    MOV #0x0041, W3
    mov #16223, w4;V
    return
Cambio17:
    MOV #0x0041, W3
    mov #9461, w4;W
    return    
Cambio18:
    MOV #0x0041, W3
    mov #16213, w4;X
    return
Cambio19:
    MOV #0x0041, W3
    mov #16219, w4;Y
    return
Cambio1A:
    MOV #0x0041, W3
    mov #7133, w4;Z
    return
cambioEspacio:
    MOV #0x0041, W3
    mov #0xFFFF, w4;ESPACIO
    return

delay_multiplex:
    MOV #15000, W4              ; Ajusta este valor para mantener la estabilidad del display
delay_multiplex_loop:
    DEC W4, W4
    CP0 W4
    BRA NZ, delay_multiplex_loop
    RETURN
    
delay_very_long:
    MOV #50000, W4             ; Incrementar este valor para que el desplazamiento sea más lento
delay_very_long_loop:
    DEC W4, W4
    CP0 W4
    BRA NZ, delay_very_long_loop
    RETURN

nada:
    MOV #0x0041, W3
    mov #0xFFFF, w4
    return
    
;Place holder for last line of executed code ;..............................................................................
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

.end                               ;End of program code in this file