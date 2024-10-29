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
    MOV #2, W11 
    
    MOV #0, W3
    MOV #2, W4
    MOV #7, W5
    MOV #11, W6
    MOV #22, W7
    MOV #9, W8
    MOV #700, W9
    MOV #6000, W10
    MOV #705, W12

    CP W11, #1           
    BRA Z, OrdenaAscendente 
   
    CP W11, #2           
    BRA Z, OrdenaDescendente
  
    CP W11, #3           
    BRA Z, Pares  

    CP W11, #4           
    BRA Z, Impares  
    
    BRA done

    ; ________________________Acciones__________________________
OrdenaAscendente:
    ; (Inserta tu código para esta condición)
    

OrdenaDescendente:
    ; (Inserta tu código para esta condición)
    MOV #1, W11   ;
    MOV #100, W10          ; Valor 100
    MOV #0x0800, W0        ; Dirección base de la memoria RAM
    MOV W10, [W0]          ; Almacenar 100 en 0x0800

    MOV #50, W10           ; Valor 50
    ADD #2, W0             ; Siguiente dirección de memoria
    MOV W10, [W0]          ; Almacenar 50

    MOV #30, W10           ; Valor 30
    ADD #2, W0             ; Siguiente dirección de memoria
    MOV W10, [W0]          ; Almacenar 30

    MOV #120, W10          ; Valor 120
    ADD #2, W0             ; Siguiente dirección de memoria
    MOV W10, [W0]          ; Almacenar 120

    MOV #15, W10           ; Valor 15
    ADD #2, W0             ; Siguiente dirección de memoria
    MOV W10, [W0]          ; Almacenar 15

    MOV #10, W10           ; Valor 10
    ADD #2, W0             ; Siguiente dirección de memoria
    MOV W10, [W0]          ; Almacenar 10

    ; Ordenar los valores usando burbuja
    MOV #0x0800, W0        ; Dirección base de la memoria RAM
    MOV #5, W1             ; Número de elementos a ordenar (6 elementos)
    
    sort_loop:
	CLR W2                 ; W2 como índice del ciclo externo
	
    Ciclo_externo:             ;itera n-1 cantidad de veces para la cantidad de numeros
	MOV W1, W3             ; W3 para contar las iteraciones del ciclo interno
	SUB #1, W3             ; Reducir en 1 porque el ciclo externo tiene una iteración menos
	CLR W4                 ; W4 como índice del ciclo interno

    Ciclo_interno: ;compara de 2 en 2 registros y lo hace n-1 veces
	; Calcular la dirección de los elementos a comparar
	MOV W0, W6             ; Copiar la dirección base a W6
	ADD W4, W6, W6         ; Calcular la dirección efectiva (W6 = W0 + W4)
	MOV [W6], W7           ; W7 = elemento[i]

	ADD #2, W6             ; Apuntar al siguiente elemento
	MOV [W6], W8           ; W8 = elemento[i+1]

	; Comparar los elementos
	CP W7, W8              ; Comparar elemento[i] con elemento[i+1] 30 - 50 = -20
	BRA LT, no_intercambio       ; Si elemento[i] < elemento[i+1], no hacer intercambio si w7 menor a w8 salta a no

	; si flag N es negativo indica que se debe w7 es menor a w8
	; Intercambiar los elementos si están en el orden incorrecto
	MOV W7, [W6]           ; elemento[i+1] = elemento[i]
	SUB #2, W6             ; Apuntar de nuevo a elemento[i]
	MOV W8, [W6]           ; elemento[i] = elemento[i+1]
	
    no_intercambio:
	; Incrementar el índice del ciclo interno
	ADD #2, W4             ; Incrementar W4 en 2 para apuntar al siguiente elemento
	SUB #1, W3             ; Decrementar las iteraciones restantes del ciclo interno afecta a z y n
	BRA GE, Ciclo_interno     ; Repetir mientras W3 >= 0 mayor o igual
	;banderas de z y , si z esta activado W3

	; Incrementar el índice del ciclo externo
	ADD #2, W2             ; Incrementar W2 en 2 para la siguiente iteración del ciclo externo
	SUB #1, W1             ; Decrementar las iteraciones restantes del ciclo externo
	BRA GE, Ciclo_externo     ; Repetir mientras W1 > 1
    BRA done   
    
Pares:  
    MOV W3, W0          
    AND W0, #0x0001, W1 
    CP0 W1              
    BRA Z, Next_W3    
    CLR W3              

Next_W3:
    MOV W4, W0
    AND W0, #0x0001, W1
    CP0 W1
    BRA Z, Next_W4
    CLR W4              

Next_W4:
    MOV W5, W0
    AND W0, #0x0001, W1
    CP0 W1
    BRA Z, Next_W5
    CLR W5              
Next_W5:
    
    MOV W6, W0
    AND W0, #0x0001, W1
    CP0 W1
    BRA Z, Next_W6
    CLR W6              

Next_W6: 
    MOV W7, W0
    AND W0, #0x0001, W1
    CP0 W1
    BRA Z, Next_W7
    CLR W7             

Next_W7:  
    MOV W8, W0
    AND W0, #0x0001, W1
    CP0 W1
    BRA Z, Next_W8
    CLR W8  
    
Next_W8:  
    MOV W9, W0
    AND W0, #0x0001, W1
    CP0 W1
    BRA Z, Next_W9
    CLR W9              

Next_W9:
    
    MOV W10, W0
    AND W0, #0x0001, W1
    CP0 W1
    BRA Z, Next_W10
    CLR W10             

Next_W10:  
    MOV W12, W0
    AND W0, #0x0001, W1
    CP0 W1
    BRA Z, done
    CLR W12             

Impares:
    MOV W3, W0          
    AND W0, #0x0001, W1 
    CP0 W1              
    BRA NZ, I_Next_W3     
    CLR W3            

I_Next_W3:
    MOV W4, W0
    AND W0, #0x0001, W1
    CP0 W1
    BRA NZ, I_Next_W4
    CLR W4              

I_Next_W4:
    MOV W5, W0
    AND W0, #0x0001, W1
    CP0 W1
    BRA NZ, I_Next_W5
    CLR W5             

I_Next_W5:
    MOV W6, W0
    AND W0, #0x0001, W1
    CP0 W1
    BRA NZ, I_Next_W6
    CLR W6            

I_Next_W6:
    MOV W7, W0
    AND W0, #0x0001, W1
    CP0 W1
    BRA NZ, I_Next_W7
    CLR W7             

I_Next_W7:
    MOV W8, W0
    AND W0, #0x0001, W1
    CP0 W1
    BRA NZ, I_Next_W8
    CLR W8             

I_Next_W8:
    MOV W9, W0
    AND W0, #0x0001, W1
    CP0 W1
    BRA NZ, I_Next_W9
    CLR W9             
    
I_Next_W9:
    MOV W10, W0
    AND W0, #0x0001, W1
    CP0 W1
    BRA NZ, I_Next_W10
    CLR W10            

I_Next_W10:
    MOV W12, W0
    AND W0, #0x0001, W1
    CP0 W1
    BRA NZ, done
    CLR W12            
    BRA done 
    
done:
    ; Bucle infinito para detener el programa
    BRA done

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