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

Interno:
.WORD	48, 72, 132, 258, 513, 0	
    
Externo:
.WORD	513 , 258, 132, 72, 48, 0

Alternado:
.WORD	682,341, 0x0000
 
Reflejo:
.WORD	513, 258, 771, 123, 645, 390, 903, 72, 585, 338, 851, 204, 717, 462, 975, 48, 561, 306, 819, 180, 693, 438, 951, 120, 633, 378, 891, 252, 765, 510, 1023, 0x0000
   
CFibbo:
.WORD	1, 2, 3, 5, 8, 13, 21, 34, 55, 89, 144, 233, 377, 610, 987, 0x0000
    
Rider:
.WORD	1, 2, 4, 8, 16, 32, 64, 128, 256, 128, 64, 32, 16, 8, 4, 2, 1, 0x0000
    
CortinaCl:
.WORD	513, 771, 903, 975, 1023, 0x0000
    
CortinaOp:
.WORD	1023, 975, 903, 771, 513, 0x0000
	

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
    SETM    TRISA              ; Configurar PORTA como entrada
    CLR     TRISB              ; Configurar PORTB como salida
    CLR     LATB               ; Inicializar PORTB en 0

    ;---------------------------------------------------------
    ; Variables y registros de trabajo
    ;---------------------------------------------------------
    CLR     W1                 ; Contador de tiempo (0, 1, 2)
    CLR     W2                 ; Contador de animación (0, 1, 2)
    ;---------------------------------------------------------
    ; Bucle principal
    ;---------------------------------------------------------
main_loop:
        ; Leer Botón 1 (Tiempo) en RA0
       MOV     PORTA, W0         ; Leer PORTA
       AND     #0x0007, W0       ; Extraer RA0 a RA2 (animaciones)
       MOV     W0, W2            ; Guardar animación seleccionada en W2

	; Leer PORTA y determinar tiempo (RA3 a RA4)
       MOV     PORTA, W0         ; Leer PORTA
       AND     #18, W0       ; Extraer RA3 y RA4
       MOV     W0, W1            ; Guardar tiempo seleccionado en W1

        ; Realizar la animación seleccionada con el tiempo seleccionado
        ; Seleccionar la animación
      CP      W2, #0
      BRA     Z, anim_internos
      CP      W2, #1
      BRA     Z, anim_externos
      CP      W2, #2
      BRA     Z, anim_alternado
      CP      W2, #3
      BRA     Z, anim_reflejo
      CP      W2, #4
      BRA     Z, anim_cfibbo
      CP      W2, #5
      BRA     Z, anim_rider
      CP      W2, #6
      BRA     Z, anim_cortinacl
      CP      W2, #7
      BRA     Z, anim_cortinaop

      BRA     main_loop      ; Regresar al bucle principal


    ;---------------------------------------------------------
    ; Animaciones
    ;---------------------------------------------------------
anim_internos:
        ; Desplazamiento a la derecha en PORTB
       MOV     #tblpage(Interno), W0 ; Obtener página alta de MESSAGE2
       MOV     W0, TBLPAG             ; Cargar en TBLPAG
       MOV     #tbloffset(Interno), W5 ; Cargar la dirección baja en W1

internos_loop:
	TBLRDL  [W5++], W4           ; Leer una palabra de memoria (16 bits)
	CP0     W4                   ; Comparar con 0x0000 (valor final)
	BRA     Z, main_loop       ; Si es 0x0000, salir del bucle
	MOV     W4, LATB            ; Escribir el valor en PORTB
	CALL	delay
	BRA     internos_loop        ; Repetir el bucle

anim_externos:
        MOV     #tblpage(Externo), W0 ; Obtener página alta de MESSAGE2
        MOV     W0, TBLPAG             ; Cargar en TBLPAG
        MOV     #tbloffset(Externo), W5 ; Cargar la dirección baja en W1
externos_loop:
        TBLRDL  [W5++], W4           ; Leer una palabra de memoria (16 bits)
	CP0     W4                   ; Comparar con 0x0000 (valor final)
	BRA     Z, main_loop       ; Si es 0x0000, salir del bucle
	MOV     W4, LATB            ; Escribir el valor en PORTB
	CALL	delay
	BRA     externos_loop        ; Repetir el bucle
	
anim_alternado:
        MOV     #tblpage(Alternado), W0 ; Obtener página alta de MESSAGE2
        MOV     W0, TBLPAG             ; Cargar en TBLPAG
        MOV     #tbloffset(Alternado), W5 ; Cargar la dirección baja en W1
alternado_loop:
        TBLRDL  [W5++], W4           ; Leer una palabra de memoria (16 bits)
	CP0     W4                   ; Comparar con 0x0000 (valor final)
	BRA     Z, main_loop       ; Si es 0x0000, salir del bucle
	MOV     W4, LATB            ; Escribir el valor en PORTB
	CALL	delay
	BRA     alternado_loop        ; Repetir el bucle
	
anim_reflejo:
        MOV     #tblpage(Reflejo), W0 ; Obtener página alta de MESSAGE2
        MOV     W0, TBLPAG             ; Cargar en TBLPAG
        MOV     #tbloffset(Reflejo), W5 ; Cargar la dirección baja en W1
reflejo_loop:
        TBLRDL  [W5++], W4           ; Leer una palabra de memoria (16 bits)
	CP0     W4                   ; Comparar con 0x0000 (valor final)
	BRA     Z, main_loop       ; Si es 0x0000, salir del bucle
	MOV     W4, LATB            ; Escribir el valor en PORTB
	CALL	delay
	BRA     reflejo_loop        ; Repetir el bucle
	
anim_cfibbo:
        MOV     #tblpage(CFibbo), W0 ; Obtener página alta de MESSAGE2
        MOV     W0, TBLPAG             ; Cargar en TBLPAG
        MOV     #tbloffset(CFibbo), W5 ; Cargar la dirección baja en W1
cfibbo_loop:
        TBLRDL  [W5++], W4           ; Leer una palabra de memoria (16 bits)
	CP0     W4                   ; Comparar con 0x0000 (valor final)
	BRA     Z, main_loop       ; Si es 0x0000, salir del bucle
	MOV     W4, LATB            ; Escribir el valor en PORTB
	CALL	delay
	BRA     cfibbo_loop        ; Repetir el bucle

anim_rider:
        MOV     #tblpage(Rider), W0 ; Obtener página alta de MESSAGE2
        MOV     W0, TBLPAG             ; Cargar en TBLPAG
        MOV     #tbloffset(Rider), W5 ; Cargar la dirección baja en W1
rider_loop:
        TBLRDL  [W5++], W4           ; Leer una palabra de memoria (16 bits)
	CP0     W4                   ; Comparar con 0x0000 (valor final)
	BRA     Z, main_loop       ; Si es 0x0000, salir del bucle
	MOV     W4, LATB            ; Escribir el valor en PORTB
	CALL	delay
	BRA     rider_loop        ; Repetir el bucle

anim_cortinacl:
        MOV     #tblpage(CortinaCl), W0 ; Obtener página alta de MESSAGE2
        MOV     W0, TBLPAG             ; Cargar en TBLPAG
        MOV     #tbloffset(CortinaCl), W5 ; Cargar la dirección baja en W1
cortinacl_loop:
        TBLRDL  [W5++], W4           ; Leer una palabra de memoria (16 bits)
	CP0     W4                   ; Comparar con 0x0000 (valor final)
	BRA     Z, main_loop       ; Si es 0x0000, salir del bucle
	MOV     W4, LATB            ; Escribir el valor en PORTB
	CALL	delay
	BRA     cortinacl_loop        ; Repetir el bucle

anim_cortinaop:
        MOV     #tblpage(CortinaOp), W0 ; Obtener página alta de MESSAGE2
        MOV     W0, TBLPAG             ; Cargar en TBLPAG
        MOV     #tbloffset(CortinaOp), W5 ; Cargar la dirección baja en W1
cortinaop_loop:
        TBLRDL  [W5++], W4           ; Leer una palabra de memoria (16 bits)
	CP0     W4                   ; Comparar con 0x0000 (valor final)
	BRA     Z, main_loop       ; Si es 0x0000, salir del bucle
	MOV     W4, LATB            ; Escribir el valor en PORTB
	CALL	delay
	BRA     cortinaop_loop        ; Repetir el bucle

    ;---------------------------------------------------------
    ; Retardos basados en el valor de W1
    ;---------------------------------------------------------
delay:
        ; Seleccionar el tiempo de retardo según W1
        CP0     W1
	BRA     Z, delay_1s     ; RA3, RA4 = 00 -> Retardo de 100 µs
	CP      W1, #8
	BRA     Z, delay_1_5s     ; RA3, RA4 = 01 -> Retardo de 350 ms
	CP      W1, #16
	BRA     Z, delay_2s     ; RA3, RA4 = 10 -> Retardo de 500 ms
	CP      W1, #24
	BRA     Z, delay_3s        ; RA3, RA4 = 11 -> Retardo de 1 s
	RETURN
	
delay_1s:
        ; Código para un retardo de 100us (ajustar para tu reloj)
        MOV	#20000,W4       ; Ejemplo de retardo ajustado para 100us
	MOV	#100,W8		;(1 Cycle)
delay_1s_loop:
        DEC     W4, W4
        CP0     W4
        BRA     NZ, delay_1s_loop2
        RETURN
delay_1s_loop2:
	DEC	    W8,	    W8		;(1 Cycle)
	CP0	    W8			;(1 Cycle)
	BRA	    Z,	delay_1s_loop;(1 Cycle if not jump)
	BRA	    delay_1s_loop2		;(2 Cycle if jump)

delay_1_5s:
        ; Código para un retardo de 100us (ajustar para tu reloj)
        MOV	#30000,W4       ; Ejemplo de retardo ajustado para 100us
	MOV	#100,W8		;(1 Cycle)
delay_1_5s_loop:
        DEC     W4, W4
        CP0     W4
        BRA     NZ, delay_1_5s_loop2
        RETURN
delay_1_5s_loop2:
	DEC	    W8,	    W8		;(1 Cycle)
	CP0	    W8			;(1 Cycle)
	BRA	    Z,	delay_1_5s_loop;(1 Cycle if not jump)
	BRA	    delay_1_5s_loop2		;(2 Cycle if jump)


delay_2s:
        ; Código para un retardo de 100us (ajustar para tu reloj)
        MOV	#40000,W4       ; Ejemplo de retardo ajustado para 100us
	MOV	#100,W8		;(1 Cycle)
delay_2s_loop:
        DEC     W4, W4
        CP0     W4
        BRA     NZ, delay_2s_loop2
        RETURN
delay_2s_loop2:
	DEC	    W8,	    W8		;(1 Cycle)
	CP0	    W8			;(1 Cycle)
	BRA	    Z,	delay_2s_loop;(1 Cycle if not jump)
	BRA	    delay_2s_loop2		;(2 Cycle if jump)

delay_3s:
        ; Código para un retardo de 100us (ajustar para tu reloj)
        MOV	#60000,W4       ; Ejemplo de retardo ajustado para 100us
	MOV	#100,W8		;(1 Cycle)
delay_3s_loop:
        DEC     W4, W4
        CP0     W4
        BRA     NZ, delay_3s_loop2
        RETURN
delay_3s_loop2:
	DEC	    W8,	    W8		;(1 Cycle)
	CP0	    W8			;(1 Cycle)
	BRA	    Z,	delay_3s_loop;(1 Cycle if not jump)
	BRA	    delay_3s_loop2		;(2 Cycle if jump)
	
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