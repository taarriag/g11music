;Programa de prueba de PIC, Entrega 2, Grupo 11

	list p=16f877a  ; Tipo dispositivo

	#include <P16F877A.inc>  ; Para que reconozca los registros

	ORG H'00'
	GOTO PARTIDA  ; Ubicación de partida	

	ORG H'04'
	GOTO INT  ; Ubicación de interrupciones

; Variables a almacenar, registros
; de propósito general en el banco 0
LED EQU H'20' ; Led de uso actual
POT1   EQU H'21' ; Vin
POT2   EQU H'22' ; LED
LEVEL1  EQU H'23' ; Nivel de corte 1
LEVEL2 EQU H'30'  ;Nivel de corte 2
CONT   EQU H'24' ; Contador de overflows del timer
DIST   EQU H'26' ; Valor del Vin aceptable, entre 0 y 127


PARTIDA

	BCF STATUS,RP1
	BSF STATUS,RP0	 ; Me cambio al banco 1

	MOVLW H'FF' ; Todos los canales de A como input
	MOVWF TRISA

	MOVLW B'11000111' ; RC3, RC4 y RC5 como output para los leds, los demás como input (RC2 se usará para el switch)
	MOVWF TRISC

	BCF STATUS,RP0
	BCF STATUS,RP1	; Vuelvo al Banco 0

	CLRF CONT  
    CLRF LED
    CLRF LEVEL1
	CLRF LEVEL2
	CLRF POT1
	CLRF POT2
	CLRF DIST
	

	;INTERRUPCIONES
	MOVLW B'11000000'
	MOVWF INTCON	; Interrupciones Globales y Periféricas


	BCF STATUS,RP1
	BSF STATUS,RP0	; BANCO 1
	MOVLW B'00000001'	
	MOVWF PIE1		; Activo la interrupcion Timer1 Overflow
                    ; Aqui se puede usar la interr. del USART, etc.
	BCF STATUS,RP0
	BCF STATUS,RP1	; BANCO 0


	;CONFIGURACION TIMER 1
	CLRF TMR1L
	CLRF TMR1H	; Borro registros TMR1
	MOVLW B'00000000'  ; Uso de clock interno, prescaler 1:4, Timer1 OFF
	MOVWF T1CON	



    ;CONFIGURACION ADC
	BCF STATUS,RP1
	BSF STATUS,RP0	;BANCO 1
	MOVLW B'01000000' ; Justificado Izquierdo FOSC/2 Todos análogos
	MOVWF ADCON1

	BCF STATUS,RP0
	BCF STATUS,RP1	;BANCO 0

	MOVLW B'01000000'	;FOSC/8, CH0 por ahora, ADC=OFF
	MOVWF ADCON0

; Seteamos los niveles de corte para el potenciómetro de selección de leds

    MOVLW D'42'
    MOVWF LEVEL1

	MOVLW D'85'
    MOVWF LEVEL2
	

LOOP

    ; Leo los valores de los potenciometros
    CALL LEER_CH0

    CALL UBICAR    ; Veo en que lado de "level" estoy

    CALL LEER_CH1

	BTFSC PORTC,2  ; Si RC2 esta en 1, parpadea
    CALL BLINK
    BTFSS PORTC,2  ; Si RC2 esta en 0, lo prendo
    CALL LED_ON    

	GOTO LOOP      ; Vuelvo a hacer lo anterior

UBICAR
    BCF STATUS,C   ; Me aseguro de bajar el flag
    MOVF DIST,0    ; Vin formateado
    SUBWF LEVEL1,0  ; (LEVEL1) - (W) = (W)
    BTFSS STATUS,C ; Según el resultado, activo el led correspondiente
    BCF STATUS,C ; Borro el bit de carry y salto a UBICAR2 
	BTFSC STATUS,C	
    CALL LED_LOW ; Prendo el led LOW
	BTFSS STATUS,C
	CALL UBICAR2 
    RETURN

UBICAR2
    BCF STATUS,C   ; Me aseguro de bajar el flag
    MOVF DIST,0    ; Vin formateado
	SUBWF LEVEL2,0  ; (LEVEL2) - (W) = (W)
    BTFSS STATUS,C ; Según el resultado, activo el led correspondiente
    CALL LED_HIGH  ; Prendo el led HIGH 
	BTFSC STATUS,C	
    CALL LED_MID ; Prendo el led MID
    RETURN	

LED_HIGH  ; RC5
	MOVLW B'00100000'
    MOVWF LED
    BCF STATUS,C
    RETURN

LED_MID  ; RC4
	MOVLW B'00010000'
    MOVWF LED
	BSF STATUS,C
    RETURN

LED_LOW   ; RC3
	MOVLW B'00001000'
    MOVWF LED
    BSF STATUS,C
    RETURN

LED_ON
	MOVLW B'00000000'  ; Uso de clock interno, prescaler 1:4, Timer1 OFF
	MOVWF T1CON
	MOVLW B'11000111' 	; Borramos los bits de los leds del puerto C
	ANDWF PORTC,0	
    IORWF LED,0			; Seteamos el bit del led actual
	MOVWF PORTC
	RETURN

BLINK
	MOVLW B'00000001'  ; Uso de clock interno, prescaler 1:1 (tercer y cuarto bit), Timer1 ON
	MOVWF T1CON	
    MOVF CONT,0	; CONT en W
	XORWF POT2,0	; Comparo CONT con POT2, si son iguales (Z=1), cambio el estado del LED
	BTFSC STATUS,Z
	CALL CAMBIA_LED
	BCF STATUS,Z
	RETURN

INT
	
	BCF INTCON,GIE	;APAGO INTERRUPCIONES
	BTFSC PIR1,TMR1IF  ; Si la interrupcion es por TMR1 overflow, voy al método
	CALL CONTAR
    ; Aqui se pueden agregar otras interrupciones
	BSF INTCON,GIE ;REACTIVO INTERRUPCIONES
	RETURN

CONTAR
	BCF PIR1,TMR1IF  ; Bajo el flag de la interrupción
	MOVLW H'EE'
	MOVWF TMR1H
	MOVLW H'00'	
	MOVWF TMR1L  ;  El tiempo de parpadeo dependerá del valor de TMR1H + TMR1L 
	INCF CONT,1		;  Incremento el contador
	RETURN
	
CAMBIA_LED
    BCF STATUS,Z
	CLRF CONT
	MOVLW B'00111000' 
	ANDWF PORTC,0
    BTFSC STATUS,Z
	CALL PRENDE_LED
	BTFSS STATUS,Z
	CALL APAGA_LED
	RETURN

PRENDE_LED
	MOVLW B'11000111'  	; Apagamos los leds
	ANDWF PORTC,1	
	MOVF LED,0			; Prendemos el led correspondiente
    IORWF PORTC,1
    BSF STATUS,Z
	RETURN

APAGA_LED
	BCF PORTC,3
	BCF PORTC,4
	BCF PORTC,5
    BCF STATUS,Z
	RETURN
	
LEER_CH0 ; Revisa en que lado estoy
    MOVLW B'01000001' ; Me cambio a CH0
    MOVWF ADCON0


	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
    ;BCF ADCON0,CHS0
    BSF ADCON0,GO ; Le digo GO

PAUSA0
	BTFSC ADCON0,GO	; Si está en Clear, movemos el dato
	GOTO PAUSA0
	MOVF ADRESH,0
	MOVWF POT1
  
	;MOVLW H'00'  
    ;MOVWF ADRESH
    
    BCF STATUS,C
    BCF STATUS,DC
    BCF STATUS,Z
    RRF POT1,1 ; Maximo 127
    BCF STATUS,C

    MOVF POT1,0
    MOVWF DIST

    RETURN

LEER_CH1 ; Blink
    MOVLW B'01001001' ; Me cambio a CH1
    MOVWF ADCON0

	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
    ;BSF ADCON0,CHS0
    BSF ADCON0,GO ; Le digo GO

PAUSA1
	BTFSC ADCON0,GO	; Si está en Clear, movemos el dato
	GOTO PAUSA1
	MOVF ADRESH,0
	MOVWF POT2

	;MOVLW H'00'  
    ;MOVWF ADRESH

    RETURN

	END
