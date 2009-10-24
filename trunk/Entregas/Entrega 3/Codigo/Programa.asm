;-------------------;
; 1 Header          ;
;-------------------;
	list p=16f877a         ; Le decimos al compilador que pic usamos
	include <P16F877A.inc> ; Definicion de parametros y constantes.
;------------------------------------------;
; 1.1 Definicion de Registros y variables ;
;------------------------------------------;
	udata				; Definimos que la memoria para definir simbolos no tope con los special function registers.
	EJEMPLO	res 1		; REServamos 1 byte con el nombre EJEMPLO
	ZXLDR 	res 1 	; Valor obtenido desde el ZX-LDR
	ZXSND 	res 1 	; Valor obtenido desde el ZX-SOUND
	LDR_LEVEL1	res 1
	LDR_LEVEL2	res 1
	SND_LEVEL1 	res 1 	
	SND_LEVEL2 	res 1 	 
	LDR_CURRENT_LEVEL res 1	;Nivel actual del ZXLDR
	SND_CURRENT_LEVEL	res 1	;Nivel actual del ZXSND
	CONT 	res 1 	; Contador de overflows del timer
	DISTLDR 	res 1
	DISTSND		res 1
;--------------------------------------;
; 2 Configuracion                      ;
;--------------------------------------;
	ORG	H'00'
	GOTO	START		; Vamos al inicio del programa
	ORG	H'04'			
	GOTO	INT	; Vamos a la subrutina de interrupcion
	
START	
;--------------------------------------;
; 2.1 Puertos                          ;
;--------------------------------------;
	BCF 	STATUS,RP1 	; Vamos al banco 1
	BSF		STATUS,RP0	 
	
	MOVLW 	H'FF' 		;Configuramos el puerto A como entrada.
	MOVWF 	TRISA
	
	MOVLW 	B'11110000' ; Configuramos el puerto B como entrada en RB7,RB6,RB5,RB4 (para los botones).  
	MOVWF 	TRISB	
	
	MOVLW 	B'11000000' ; Configuramos el puerto C para conexion al MAX232 (RC7 Y RC6 input) y como output en el resto de los bits.
	MOVWF 	TRISC
	
	MOVLW 	B'00000010' ; Configuramos el puerto D como output hacia el LCD y RD1 como input para recibir el flag del LCD. 
	MOVWF	TRISD
	
	BCF 	STATUS,RP0 	;Vamos al banco 0
	BCF 	STATUS,RP1
	
	CLRF 	ZXLDR 	
	CLRF 	ZXSND 	
	CLRF	LDR_LEVEL1	
	CLRF	LDR_LEVEL2	
	CLRF 	SND_LEVEL1 	 	
	CLRF 	SND_LEVEL2 	 	 
	CLRF 	LDR_CURRENT_LEVEL 
	CLRF 	SND_CURRENT_LEVEL	
	CLRF 	CONT 	
	CLRF	DISTLDR
	CLRF 	DISTSND
	CLRF 	PORTA
	CLRF	PORTB
	CLRF	PORTC
	CLRF	PORTD
	
;--------------------------------------;
; 2.2 Interrupciones         
;	Nota: REVISAR ESTA PARTE EN FUNCIÓN DE LAS INTERRUPCIONES QUE VAYAMOS A UTILIZAR
;--------------------------------------;
	MOVLW 	B'11011000' ;Activamos Interrupciones globales y perifericas, interrupciones en RB0/INT e
	MOVWF 	INTCON		;interrupciones por cambios en Puerto B.					
						;NOTA: REVISAR SI DEBEMOS ACTIVAR INTERRUPCIÓN DE TIMER0
						
	
	;NOTA: ESTA PARTE FUE COPIADA DIRECTAMENTE DEL CODIGO DE LA AYUDANTIA. REVISAR----------
	
	BCF 	STATUS,RP1 	;Vamos al banco1
	BSF 	STATUS,RP0	
	
	MOVLW B'00000001'	; Activo la interrupcion Timer1 Overflow
	MOVWF PIE1			; Aqui se puede usar la interr. del USART, etc.
    
	BCF STATUS,RP0
	BCF STATUS,RP1	; BANCO 0
	
	;CONFIGURACION TIMER 1
	CLRF TMR1L
	CLRF TMR1H	; Borro registros TMR1
	MOVLW B'00000000'  ; Uso de clock interno, prescaler 1:4, Timer1 OFF
	MOVWF T1CON	
	
	;--------------------------------------------------------------------------------------
	
	;STATUS,RP0	; Vamos al banco 0
	;movlw	b'11001000'
	;movwf	INTCON		; Permisos de interrupcion: Global, Perifericos y RB4-RB7.
	;movlw	b'01000000'
	;movwf	PIE1		; Permiso de interrupcion para conversion A/D
	;TODO: Configuracion interrupciones puerto C, serial

	
;--------------------------------------;
;2.4 ADC 
;--------------------------------------;
	BCF STATUS,RP1		;Vamos al banco 1
	BSF STATUS,RP0		
	
	;Configuramos el ADCON1
	MOVLW	B'01000000' ;Justificado, Fosc/2 , todos los AN Analogos
	MOVWF	ADCON1		
						
	BCF	STATUS,RP1		;Vamos al banco 0
	BCF	STATUS,RP0			
	
	;Configuramos el ADCON0
	MOVLW	B'01000000' ;Fosc/8,CH0,ADC = OFF
	MOVWF	ADCON0
; Seteamos los niveles de corte para el potenciómetro de selección de leds

    MOVLW D'42'
    MOVWF LDR_LEVEL1

	MOVLW D'85'
    MOVWF LDR_LEVEL2
; Seteamos los niveles de corte para el potenciómetro de selección de leds

    MOVLW D'42'
    MOVWF SND_LEVEL1

	MOVLW D'85'
    MOVWF SND_LEVEL2
;--------------------------------------;
;2.5 LOOP PRINCIPAL
;--------------------------------------;
LOOP
	CALL LEER_LDR
	
	CALL UBICAR_LDR
	
	CALL LEER_SND
	
	CALL UBICAR_SND
	
	GOTO LOOP
	
	
;--------------------------------------;
; 3 Subrutinas                         ;
;--------------------------------------;

;--------------------------------------;
;3.1 LDR: Lectura y asignacion de nivel;
;--------------------------------------;

LEER_LDR
	MOVLW	B'01001001'	;Apuntamos al CH0 y encendemos el modulo conversor 
	MOVWF	ADCON0	
	
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
	
	BSF ADCON0,GO 	;Inicio la conversion
	
PAUSA_LDR
	BTFSC 	ADCON0,GO	; Si está en Clear, movemos el dato
	GOTO 	PAUSA_LDR
	MOVF	ADRESH,0	; Obtenemos el valor capturado desde ADRESH
	MOVWF	ZXLDR		; Copiamos este valor en la variable ZXLDR	
	
	BCF 	STATUS,C		;Limpiamos los bits de estado
    BCF 	STATUS,DC
    BCF 	STATUS,Z
	
	RRF		ZXLDR,1		;Shift right del valor del LDR
	BCF 	STATUS,C	

	MOVF 	ZXLDR,0
    MOVWF 	DISTLDR

    RETURN

UBICAR_LDR
    BCF STATUS,C   ; Me aseguro de bajar el flag
    MOVF DISTLDR,0    ; Obtenemos el distLDR
    SUBWF LDR_LEVEL1,0  ; (LDR_LEVEL1) - (W) = (W)
    BTFSS STATUS,C ; Según el resultado, activo el led correspondiente
    GOTO UBICAR_LDR_UBICAR2
	CALL LDR_LOW
UBICAR_LDR_RETURN
    RETURN
UBICAR_LDR_UBICAR2
	CALL UBICAR2_LDR 
	GOTO UBICAR_LDR_RETURN




UBICAR2_LDR
    BCF STATUS,C   ; Me aseguro de bajar el flag
    MOVF DISTLDR,0    ; Vin formateado
	SUBWF LDR_LEVEL2,0  ; (LDR_LEVEL2) - (W) = (W)
    BTFSC STATUS,C ; Según el resultado, activo el led correspondiente
    GOTO UBICAR2_LDR_MID
	CALL LDR_HIGH  ; Prendo el led HIGH 
UBICAR2_LDR_RETURN
    RETURN	
UBICAR2_LDR_MID
    CALL LDR_MID ; Prendo el led MID
	GOTO UBICAR2_LDR_RETURN




LDR_LOW
	MOVLW	B'00000001'	;guardamos el dato del nivel 1
	MOVWF	LDR_CURRENT_LEVEL
	RETURN
	
LDR_MID
	MOVLW	B'00000010'
	MOVWF	LDR_CURRENT_LEVEL
	RETURN
	
LDR_HIGH
	MOVLW	B'00000011'
	MOVWF	LDR_CURRENT_LEVEL
	RETURN
	
;--------------------------------------;
;3.2 SND: Lectura y asignacion de nivel;
;--------------------------------------;	

LEER_SND
	MOVLW	B'01000001'	;Apuntamos al CH1 y encendemos el modulo conversor 
	MOVWF	ADCON0 
	
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
	
	BSF ADCON0,GO 	;Inicio la conversion
	
PAUSA_SND
	BTFSC 	ADCON0,GO	; Si está en Clear, movemos el dato
	GOTO 	PAUSA_SND
	MOVF	ADRESH,0	; Obtenemos el valor capturado desde ADRESH
	MOVWF	ZXSND		; Copiamos este valor en la variable ZXSND	
	
	BCF 	STATUS,C	;Limpiamos los bits de estado
    BCF 	STATUS,DC
    BCF 	STATUS,Z
	
	RRF		ZXSND,1		;Shift right del valor del SND
	BCF 	STATUS,C	

	MOVF 	ZXSND,0
    MOVWF 	DISTSND

    RETURN

UBICAR_SND
    BCF STATUS,C   ; Me aseguro de bajar el flag
    MOVF DISTSND,0    ; Obtenemos el distSND
    SUBWF SND_LEVEL1,0  ; (SND_LEVEL1) - (W) = (W)
    BTFSS STATUS,C ; Según el resultado, activo el led correspondiente
    GOTO UBICAR_SND_UBICAR2
	CALL SND_LOW
UBICAR_SND_RETURN
	RETURN
UBICAR_SND_UBICAR2
	CALL UBICAR2_SND 
    GOTO UBICAR_SND_RETURN


UBICAR2_SND
    BCF STATUS,C   ; Me aseguro de bajar el flag
    MOVF DISTSND,0    ; Vin formateado
	SUBWF SND_LEVEL2,0  ; (SND_LEVEL2) - (W) = (W)
    BTFSC STATUS,C ; Según el resultado, activo el led correspondiente
    GOTO UBICAR2_SND_MID
	CALL SND_HIGH  ; Prendo el led HIGH 
UBICAR2_SND_RETURN	
	RETURN
UBICAR2_SND_MID
    CALL SND_MID ; Prendo el led MID
    GOTO UBICAR2_SND_RETURN	
	
SND_LOW
	MOVLW	B'00000001'	;guardamos el dato del nivel 1
	MOVWF	SND_CURRENT_LEVEL
	RETURN
	
SND_MID
	MOVLW	B'00000010'
	MOVWF	SND_CURRENT_LEVEL
	RETURN
	
SND_HIGH
	MOVLW	B'00000011'
	MOVWF	SND_CURRENT_LEVEL
	RETURN
;--------------------------------------;
;3.3 INT: Rutina de interrupcion	   ;
;--------------------------------------;

;Subrutina extraida directamente desde la ayudantia
INT
	BCF INTCON,GIE	;APAGO INTERRUPCIONES
	BTFSC PIR1,TMR1IF  ; Si la interrupcion es por TMR1 overflow, voy al método
;	CALL CONTAR
    ; Aqui se pueden agregar otras interrupciones
	BSF INTCON,GIE ;REACTIVO INTERRUPCIONES
	RETURN
	
end
