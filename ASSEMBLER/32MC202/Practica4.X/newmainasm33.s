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


    ; Deshabilitar entradas analógicas en PORTB
    MOV     #0xFFFF, W0       ; Configura todos los pines como digitales
    MOV     W0, AD1PCFGL      ; Desactiva el modo analógico en todos los pines de PORTB

    ; Configurar PORTB como salida
    CLR     TRISB             ; Configura todos los pines de PORTB como salida

    ; Inicializar LATB
    CLR     LATB              ; Asegurarse de que PORTB esté en 0

    SETM    TRISA              ; Configurar PORTA como entrada

    ;---------------------------------------------------------
    ; Variables y registros de trabajo
    ;---------------------------------------------------------
    CLR     W1                 ; Contador de tiempo (0, 1, 2)
    CLR     W2                 ; Contador de animación (0, 1, 2)
    MOV #2, W2

    ;---------------------------------------------------------
    ; Bucle principal
    ;---------------------------------------------------------
main_loop:
        ; Leer Botón 1 (Tiempo) en RA0
        MOV     PORTA, W0      ; Leer RA0 (botón de tiempo)
        AND     #0x0001, W0    ; Enmascarar RA0
        CP0     W0
        BRA     NZ, change_time ; Si RA0 está presionado, cambiar el tiempo

        ; Leer Botón 2 (Animación) en RA1
        MOV     PORTA, W0      ; Leer RA1 (botón de animación)
        AND     #0x0002, W0    ; Enmascarar RA1
        CP0     W0
        BRA     NZ, change_animation ; Si RA1 está presionado, cambiar animación

        ; Realizar la animación seleccionada con el tiempo seleccionado
        CP      W2, #0
        BRA     Z, anim_shift_right
        CP      W2, #1
        BRA     Z, anim_shift_left
        CP      W2, #2
        BRA     Z, anim_blink
	CP      W2, #3
        BRA     Z, ResetW2
ResetW2:
	CLR W2
        BRA     main_loop      ; Regresar al bucle principal

    ;---------------------------------------------------------
    ; Cambiar el tiempo de ejecución
    ;---------------------------------------------------------
change_time:
        INC     W1, w1             ; Incrementar el contador de tiempo
        AND     #0x0003, W1    ; Limitar el rango (0 a 2)
        BRA     main_loop

    ;---------------------------------------------------------
    ; Cambiar la animación
    ;---------------------------------------------------------
change_animation:
        INC     W2, w2             ; Incrementar el contador de animación
        AND     #0x0003, W2    ; Limitar el rango (0 a 2)
        BRA     main_loop

    ;---------------------------------------------------------
    ; Animaciones
    ;---------------------------------------------------------
anim_shift_right:
        MOV     #0x200, W3      ; Iniciar con el bit más bajo en 1
shift_right_loop:
        MOV     W3, LATB        ; Salida en PORTB
        CALL    delay            ; Llamar al retardo basado en W1

        ; Verificar el estado de los botones en cada iteración
        MOV     PORTA, W0        ; Leer RA0 (botón de tiempo)
        AND     #0x0001, W0      ; Enmascarar RA0
        CP0     W0
        BRA     NZ, change_time  ; Si RA0 está presionado, cambiar el tiempo

        MOV     PORTA, W0        ; Leer RA1 (botón de animación)
        AND     #0x0002, W0      ; Enmascarar RA1
        CP0     W0
        BRA     NZ, change_animation ; Si RA1 está presionado, cambiar animación

        ; Continuar la rotación a la derecha
        BCLR    SR, #0           ; Limpiar el bit de Carry en SR
        RRC     W3, W3           ; Rotar hacia la derecha con acarreo
        CP      W3, #0           ; Verificar si W3 es cero
        BRA     NZ, shift_right_loop ; Continuar si no es cero
        BRA     main_loop

anim_shift_left:
        MOV     #0x01, W3        ; Iniciar con el bit más bajo en 1 (0000 0000 0000 0001)
        MOV     #0x400, W6       ; Establecer el límite de desplazamiento
shift_left_loop:
        MOV     W3, PORTB        ; Salida en PORTB
        CALL    delay            ; Llamar al retardo basado en W1

        ; Verificar el estado de los botones en cada iteración
        MOV     PORTA, W0        ; Leer RA0 (botón de tiempo)
        AND     #0x0001, W0      ; Enmascarar RA0
        CP0     W0
        BRA     NZ, change_time  ; Si RA0 está presionado, cambiar el tiempo

        MOV     PORTA, W0        ; Leer RA1 (botón de animación)
        AND     #0x0002, W0      ; Enmascarar RA1
        CP0     W0
        BRA     NZ, ANIMATION_BLINK; Si RA1 está presionado, cambiar animación

        ; Continuar la rotación a la izquierda
        BCLR    SR, #0           ; Limpiar el bit de Carry en SR
        RLC     W3, W3           ; Rotar hacia la izquierda con acarreo
        CP      W3, W6           ; Verificar si W3 es 0x400 (límite)
        BRA     NZ, shift_left_loop ; Continuar si no es igual a 0x400
        BRA     main_loop
	
ANIMATION_BLINK:
    INC     W1, w1             ; Incrementar el contador de tiempo
    AND     #0x0003, W1    ; Limitar el rango (0 a 2)
    CLR	    LATB
    BRA     main_loop

anim_blink:
blink_loop:
	COM     LATB             ; Complementar los bits de LATB (alternar LEDs)
        CALL    delay            ; Llamar al retardo basado en W1
        ; Verificar el estado de los botones en cada iteración
        MOV     PORTA, W0        ; Leer RA0 (botón de tiempo)
        AND     #0x0001, W0      ; Enmascarar RA0
        CP0     W0
        BRA     NZ, change_time  ; Si RA0 está presionado, cambiar el tiempo

        MOV     PORTA, W0        ; Leer RA1 (botón de animación)
        AND     #0x0002, W0      ; Enmascarar RA1
        CP0     W0
        BRA     NZ, change_animation ; Si RA1 está presionado, cambiar animación

        BRA     main_loop        ; Regresar al bucle principal

    ;---------------------------------------------------------
    ; Retardos basados en el valor de W1
    ;---------------------------------------------------------
delay:
        ; Seleccionar el tiempo de retardo según W1
        CP0     W1
        BRA     Z, delay_100us
        CP      W1, #1
        BRA     Z, delay_350ms
        CP      W1, #2
        BRA     Z, delay_500ms
	CP      W1, #3
        BRA     Z, ResetW1
ResetW1:
	CLR W1
	BRA delay

delay_100us:
    ; Código para un retardo de 100us (ajustar para tu reloj)
    MOV     #23, W4       ; Ejemplo de retardo ajustado para 100us
delay_100us_loop:
    DEC     W4, W4
    CP0     W4
    BRA     NZ, delay_100us_loop
    RETURN
    
delay_350ms:
    MOV #1000, W7
    
    LOOP3:
	CP0 W7			;(1 Cycle)
	BRA Z, END_DELAY	;(1 Cycle if not jump)
	DEC W7, W7		;(1 Cycle)
	MOV #69, W8		;(1 Cycle)
	
    LOOP4:
	DEC W8, W8		;(1 Cycle)
	CP0 W8			;(1 Cycle)
	BRA Z, LOOP3		;(1 Cycle if not jump)
	BRA LOOP4		;(2 Cycle if jump)
    
delay_500ms:
    MOV #1000, W7
    
    LOOP1:
	CP0 W7			;(1 Cycle)
	BRA Z, END_DELAY	;(1 Cycle if not jump)
	DEC W7, W7		;(1 Cycle)
	MOV #99, W8		;(1 Cycle)
	
    LOOP2:
	DEC W8, W8		;(1 Cycle)
	CP0 W8			;(1 Cycle)
	BRA Z, LOOP1		;(1 Cycle if not jump)
	BRA LOOP2		;(2 Cycle if jump)
    
    END_DELAY:
	Return
    

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
