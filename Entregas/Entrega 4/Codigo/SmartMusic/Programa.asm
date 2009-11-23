;-------------------;
; 1 Header          ;
;-------------------;
	list p=16F877A         ; Le decimos al compilador que pic usamos
	include <P16F877A.inc> ; Definicion de parametros y constantes.
	EXTERN LCDInit, LCDBusy, LCDLine_1, LCDLine_2, i_write, d_write, temp_wr
;-------------------------------------------;
; 1.1 Definicion de Registros y variables	;
;-------------------------------------------;
	udata				; Definimos que la memoria para definir simbolos no tope con los special function registers.
	EJEMPLO		res 1	; REServamos 1 byte con el nombre EJEMPLO
	ZXLDR 		res 1 	; Valor obtenido desde el ZX-LDR
	ZXSND 		res 1 	; Valor obtenido desde el ZX-SOUND
	LDR_LEVEL1	res 1
	LDR_LEVEL2	res 1
	SND_LEVEL1 	res 1 	
	SND_LEVEL2 	res 1 	 
	LDR_CURRENT_LEVEL	res 1	;Nivel actual del ZXLDR
	SND_CURRENT_LEVEL	res 1	;Nivel actual del ZXSND
	CONT 		res 1 	; Contador de overflows del timer
	DISTLDR 	res 1
	DISTSND		res 1
	;3.4
	count 		res 1			;used in looping routines
	count1		res 1			;used in delay routine
	counta		res 1			;used in delay routine
	countb		res 1			;used in delay routine
	tmp1		res 1			;temporary storage
	tmp2		res 1
	templcd		res 1			;temp store for 4 bit mode
	templcd2	res 1
	LCD_PORT	Equ	PORTD
	LCD_TRIS	Equ	TRISD
	LCD_CONFIG_PORT Equ PORTC
	LCD_CONFIG_TRIS Equ TRISC
	LCD_RS		Equ	0x00			;LCD handshake lines
	;LCD_RW		Equ	0x04
	LCD_E		Equ	0x01		;
	;3.5
	BIN			res	1			; Numero que queremos convertir de binario a BCD
	BCDH		res	1			; Bcd high
	BCDL		res 1			; Bcd low
	del0		res 1
	del1		res 1
	del2		res 1
	;3.6
	Tsec		res	1			;Segundos restantes del timer
	Tmin		res	1			;Minutos restantes del timer
	Thr			res	1			;Horas restantes del timer
	clocks		res 1			;Cuantos clocks han pasado (125*32*clocks). Se reinicia al llegar al segundo (clocks = 5).
	offset		res 1			;Numero de instrucciones ejecutadas antes de iniciar un nuevo ciclo de conteo
	offsetT		res 1			;temporal
	Tstatus		res 1			;Registro para almacenar el estado en que nos encontramos. b'00000ABC' A = quedan horas, B = quedan minutos, C= quedan segundos	
	COUNT		res 1
	;VARIABLES USADAS POR INTERRUPCION SERIAL
	temp_serial res 1
	prev_serial res 1
	serial_overflow_1 res 1
	serial_overflow_2 res 1

	;TESTS SERIAL
	test_serial	res 1

	;SETEO DE MINUTOS
	COUNTDOWN res 1				;Cantidad de minutos a transcurrir para apagar el equipo (configurados).
	
	COUNTDOWN_SEGUNDOS res 1	;Cantidad de overflows restantes para disminuir la cantidad de segundos.
	COUNTDOWN_MINUTOS res 1		;Cantidad de segundos restantes para disminuir la cantidad de minutos.
	COUNTDOWN_ACTUAL res 1		;Cantidad de minutos restantes para apagar el equipo.
	
	one	res 1
	five res 1
	nine res 1
;--------------------------------------;
; 2 Configuracion                      ;
;--------------------------------------;
	ORG	H'00'
	;movlw	0x07
	;movwf	CMCON
	GOTO	START		; Vamos al inicio del programa

	

	ORG	H'04'			
	GOTO	INT	; Vamos a la subrutina de interrupcion
	



START	

;-------------------------
;bcf                 STATUS,0       ;make sure we are in  0
;clrf                 01h               ;address of the other timer  TMR0
;bsf                 STATUS,0       ;switch to bank 1
;clrwdt                                 ;reset the WDT and prescaler
;movlw             B'1111'            ;Select the new prescaler value and assign
;movwf            OPTION_REG           ;it to WDT
;bcf                 STATUS,0       ;come back to bank 0
;-----------------------------------
	movlw d'1'
	movwf one
	movlw d'5'
	movwf five
	movlw d'9'
	movwf nine

	MOVLW d'10'
	MOVWF COUNTDOWN_SEGUNDOS
	MOVLW d'60'
	MOVWF COUNTDOWN_MINUTOS

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
	
	MOVLW 	B'00000000' ; Configuramos el puerto D como output hacia el LCD. 
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
	
	;MOVLW B'00000001'	; Activo la interrupcion Timer1 Overflow
	MOVLW B'00100001' 

	MOVWF PIE1			; Aqui se puede usar la interr. del USART, etc.
;	bsf PIE1,TMR1IE	
    
;CONFIGURACION CONEXION SERIAL
	;CONFIGURACION TX y RX
	MOVLW B'00100000'	;Asincrono y 8 bits
	MOVWF TXSTA
	MOVLW d'31'			;9600bps @ 20 MHz
	MOVWF SPBRG
	BCF STATUS,RP0
	BCF STATUS,RP1	;BANCO 0
	MOVLW B'10010000'	;Enable
	MOVWF RCSTA

	BCF STATUS,RP0
	BCF STATUS,RP1	; BANCO 0
	
	;CONFIGURACION TIMER 1
	CLRF TMR1L
	CLRF TMR1H	; Borro registros TMR1
	MOVLW B'00000000'  ; Uso de clock interno, prescaler 1:4, Timer1 OFF
	; MOVLW B'00000001'
	MOVWF T1CON	
	
	;--------------------------------------------------------------------------------------
	
	;BCF STATUS,RP0	; Vamos al banco 0
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

    MOVLW D'30'
    MOVWF LDR_LEVEL1

	MOVLW D'70'
    MOVWF LDR_LEVEL2
; Seteamos los niveles de corte para el potenciómetro de selección de leds

    MOVLW D'20'
    MOVWF SND_LEVEL1

	MOVLW D'50'
    MOVWF SND_LEVEL2
;--------------------------------------;
;2.5 Timer							   ; 
;--------------------------------------;
	bsf		STATUS,RP1		;Banco 1
	movlw	b'11000010'	
	movwf	OPTION_REG		;Clock interno, prescaler para timer, prescaler = 1:8
	bsf		INTCON,TMR0IE	;Habilitamos interrupciones por timer.
	bcf		INTCON,TMR0IF	;Por defecto no hay desbordamiento

	movlw b'00110001'
	movwf T1CON
	bsf PIE1,TMR1IE
	bcf PIE1,TMR1IF



;--------------------------------------;
;2.6 Lcd							   ;
;--------------------------------------;
	bcf	STATUS,RP1
	bcf	STATUS,RP0	;Vamos al banco 0
	
	MOVLW H'FF'
	MOVWF TMR1L
	MOVWF TMR1H


	call LCDInit
	call LCDBusy

;	CALL Delay1s 	;wait for LCD to settle
;	CALL LCD_Init	;Inicializamos el LCD
	;CALL LCD_Inter1	;Interfaz del LCD	

	movlw b'11111111'
	movwf COUNT
	movwf serial_overflow_1
	movwf serial_overflow_2
	movlw b'00001011'
	movwf prev_serial
	

	movlw 'b'
	movwf test_serial
;--------------------------------------;
;2.7 LOOP PRINCIPAL
;--------------------------------------;
	CALL TIMER_START
LOOP
	;ESPERO A ALGUNA INTERRUPCION DE RX
	MOVLW B'00110000'
	MOVWF TXREG

	CALL LEER_LDR
	CALL UBICAR_LDR
	
	CALL LEER_SND
	CALL UBICAR_SND
	
	CLRWDT

	decf COUNT,1
	btfsc STATUS,Z
	call Write_LCD

	MOVF LDR_CURRENT_LEVEL,0
	CALL MULT10

	MOVF SND_CURRENT_LEVEL,0
	addwf temp_serial,0
	
	CALL ENVIAR

	GOTO LOOP
	
Stop	
	MOVLW b'00000001'
	MOVWF temp_wr
	CALL i_write
    CALL LCDBusy
    CALL LCDBusy
    CALL LCDBusy
	
STOPLOOP clrwdt
goto	STOPLOOP			;endless loop
;--------------------------------------;
; 3 Subrutinas                         ;
;--------------------------------------;
MULT10
	movwf temp_serial
	addwf temp_serial,0
    addwf temp_serial,0
    addwf temp_serial,0
    addwf temp_serial,0
	addwf temp_serial,0
	addwf temp_serial,0
	addwf temp_serial,0
	addwf temp_serial,0
	addwf temp_serial,0
	movwf temp_serial

	return


Write_LCD
	movlw	b'00000001'		;#7   Display Clear
	movwf	temp_wr
	call	i_write
    call LCDBusy
    call LCDBusy
    call LCDBusy

	call LCDLine_1
	call LCDBusy
    call LCDBusy
    call LCDBusy

	movf test_serial,0
	movwf temp_wr
	call d_write
	call LCDBusy
    call LCDBusy
    call LCDBusy

	call LCDLine_2
	call LCDBusy
    call LCDBusy
    call LCDBusy

	movlw 'L'
	movwf temp_wr
	call d_write
	call LCDBusy
    call LCDBusy
    call LCDBusy

	movlw ':'
	movwf temp_wr
	call d_write
	call LCDBusy
    call LCDBusy
    call LCDBusy

	movlw ' '
	movwf temp_wr
	call d_write
	call LCDBusy
    call LCDBusy
    call LCDBusy

	movf LDR_CURRENT_LEVEL,0
	movwf temp_wr
	bsf temp_wr,4
	bsf temp_wr,5
	call d_write
	call LCDBusy
    call LCDBusy
    call LCDBusy

	movlw ' '
	movwf temp_wr
	call d_write
	call LCDBusy
    call LCDBusy
    call LCDBusy

	movlw 'S'
	movwf temp_wr
	call d_write
	call LCDBusy
    call LCDBusy
    call LCDBusy

	movlw ':'
	movwf temp_wr
	call d_write
	call LCDBusy
    call LCDBusy
    call LCDBusy

	movlw ' '
	movwf temp_wr
	call d_write
	call LCDBusy
    call LCDBusy
    call LCDBusy

	movf SND_CURRENT_LEVEL,0
	movwf temp_wr
	bsf temp_wr,4
	bsf temp_wr,5
	call d_write
	call LCDBusy
    call LCDBusy
    call LCDBusy

	movlw ' '
	movwf temp_wr
	call d_write
	call LCDBusy
    call LCDBusy
    call LCDBusy

	movlw 'T'
	movwf temp_wr
	call d_write
	call LCDBusy
    call LCDBusy
    call LCDBusy

	movlw ':'
	movwf temp_wr
	call d_write
	call LCDBusy
    call LCDBusy
    call LCDBusy

	movlw ' '
	movwf temp_wr
	call d_write
	call LCDBusy
    call LCDBusy
    call LCDBusy

	movf COUNTDOWN_ACTUAL,0
	movwf temp_wr
	bsf temp_wr,4
	bsf temp_wr,5
	call d_write
	call LCDBusy
    call LCDBusy
    call LCDBusy



	movlw b'11111111'
	movwf COUNT
	
	return
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

	BCF PORTD,3
	BSF	PORTD,2

	RETURN
	
LDR_MID
	MOVLW	B'00000010'
	MOVWF	LDR_CURRENT_LEVEL

	BSF	PORTD,3
	BCF	PORTD,2

	RETURN
	
LDR_HIGH
	MOVLW	B'00000011'
	MOVWF	LDR_CURRENT_LEVEL

	BSF PORTD,3
	BSF	PORTD,2

	RETURN
	
;--------------------------------------;
;3.2 SND: Lectura y asignacion de nivel;
;--------------------------------------;	

LEER_SND
	MOVLW	B'01010001'	;Apuntamos al CH1 y encendemos el modulo conversor 
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

	BCF PORTD,7
	BSF	PORTD,6	

	RETURN
	
SND_MID
	MOVLW	B'00000010'
	MOVWF	SND_CURRENT_LEVEL

	BSF PORTD,7
	BCF	PORTD,6
	
	RETURN
	
SND_HIGH
	MOVLW	B'00000011'
	MOVWF	SND_CURRENT_LEVEL

	BSF PORTD,7
	BSF	PORTD,6

	RETURN
;--------------------------------------;
;3.3 INT: Rutina de interrupcion	   ;
;--------------------------------------;

;Subrutina extraida directamente desde la ayudantia
INT
	BCF INTCON,GIE	;APAGO INTERRUPCIONES
	btfsc	INTCON,TMR0IF	;Hubo overflow en el timer?
	call	TIMER_5CLCK	
	
	BTFSC PIR1,TMR1IF  ; Si la interrupcion es por TMR1 overflow, voy al método
	GOTO DECREMENTAR_COUNTDOWN_SEGUNDOS
    
	; Hacemos polling de cada pin del puerto B (de RB4 a RB7)

;INTERRUPCIONES DESDE SERIAL
	BTFSC PIR1,RCIF
	CALL RECIBIRYCONTESTAR

;INTERRUPCIONES DE BOTON
	BTFSS PORTB,4
	GOTO PLAY_PAUSE
	BTFSS PORTB,5
	GOTO BACKWARD
	BTFSS PORTB,6
	GOTO FORWARD
	BTFSS PORTB,7
	GOTO TIMER	
	
FINALLY
	BCF STATUS,RP1
	BCF STATUS,RP0


	BCF PORTB,7
	BCF PORTB,6
	BCF PORTB,5
	BCF PORTB,4
	

	call Delay100
	call Delay100	
	;Bajo los flags de las interrupciones 
	BCF	INTCON,RBIF	
	
	;reactivo la detección de interrupciones
	BSF INTCON,RBIE
	BSF INTCON,GIE 
	RETURN

;RUTINA USADA POR LA INTERRUPCION PARA RECIBIR UN MENSAJE Y CONTESTARLO------------
RECIBIRYCONTESTAR
	;MOVF RCREG,0	;LEO EL DATO DESDE PC
	movlw 'a'
	movwf test_serial

	call LCDLine_1
	call LCDBusy
	call LCDBusy
	call LCDBusy

	movwf temp_wr
	call d_write
	call LCDBusy
	call LCDBusy
	call LCDBusy
	GOTO FINALLY

;	MOVWF TEMP
;	INCF TEMP,1		;INCREMENTO EN 1 Y GURADO EN TEMP
;	MOVF TEMP,0

;OBTENGO EL NIVEL DE LUZ

	;Envio la luz
	;MOVF LDR_CURRENT_LEVEL,0
	;MOVWF temp_serial
	;BSF temp_serial,4
	;BSF temp_serial,5
	;MOVF temp_serial
	;CALL ENVIAR		;MANDA LO QUE HAY EN W
	
	;Envio el sonido
	;MOVF LDR_CURRENT_LEVEL,0
	;MOVWF temp_serial
	;BSF temp_serial,4
	;BSF temp_serial,5
	;MOVF temp_serial
	;CALL ENVIAR

ENVIAR
	MOVWF TXREG		;MANDO DATO
	RETURN		;FIN DE ENVIAR
	
;----------------------------------Fin Serial	
PLAY_PAUSE
	;Rutina de play_pause
	;Imprimimos uno en los leds
	BCF	 PORTD,1
	BSF  PORTD,0
	
	movlw d'66'
	CALL ENVIAR

	GOTO FINALLY

BACKWARD
	;Rutina de backward
	;imprimimos dos en los leds
	BSF	 PORTD,1
	BCF  PORTD,0
	
	movlw d'77'
	CALL ENVIAR

	GOTO FINALLY

FORWARD
	;Rutina de forward
	;Imprimimos trés en los leds
	BSF  PORTD,1
	BSF  PORTD,0

	movlw d'88'
	CALL ENVIAR

	GOTO FINALLY

TIMER
	;Rutina de timer
	;Imprimimos 0 en los bits
	BCF	 PORTD,1
	BCF	 PORTD,0

	GOTO TIMER_LEVEL0
	
	GOTO FINALLY

TIMER_LEVEL0
	MOVF COUNTDOWN,0
	BTFSS STATUS,Z
	GOTO TIMER_LEVEL1
	MOVLW d'1'
	MOVWF COUNTDOWN
	MOVWF COUNTDOWN_ACTUAL
	BCF STATUS,RP1
	BSF STATUS,RP0
	BSF PIE1,TMR1IE
	GOTO FINALLY

TIMER_LEVEL1
	MOVF COUNTDOWN,0
	SUBWF one,0
	BTFSS STATUS,Z
	GOTO TIMER_LEVEL5
	MOVLW d'5'
	MOVWF COUNTDOWN
	MOVWF COUNTDOWN_ACTUAL
	BCF STATUS,RP1
	BSF STATUS,RP0
	BSF PIE1,TMR1IE
	GOTO FINALLY

TIMER_LEVEL5
	MOVF COUNTDOWN,0
	SUBWF five,0
	BTFSS STATUS,Z
	GOTO TIMER_LEVEL9
	MOVLW d'9'
	MOVWF COUNTDOWN
	MOVWF COUNTDOWN_ACTUAL
	BCF STATUS,RP1
	BSF STATUS,RP0
	BSF PIE1,TMR1IE
	GOTO FINALLY

TIMER_LEVEL9
	MOVF COUNTDOWN,0
	SUBWF nine,0
	MOVLW d'0'
	MOVWF COUNTDOWN
	MOVWF COUNTDOWN_ACTUAL
	BCF STATUS,RP1
	BSF STATUS,RP0
	BCF PIE1,TMR1IE
	GOTO FINALLY

DECREMENTAR_COUNTDOWN_SEGUNDOS
	BCF PIR1,TMR1IF
	BCF STATUS,RP1
	BCF STATUS,RP0
	MOVLW H'FF'
	MOVWF TMR1L
	MOVWF TMR1H
	MOVF COUNTDOWN_SEGUNDOS,0
	BTFSC STATUS,Z
	GOTO DECREMENTAR_COUNTDOWN_MINUTOS
	DECF COUNTDOWN_SEGUNDOS,0
	GOTO FINALLY

DECREMENTAR_COUNTDOWN_MINUTOS
	MOVLW d'10'
	MOVWF COUNTDOWN_SEGUNDOS
	MOVF COUNTDOWN_MINUTOS,0
	BTFSC STATUS,Z
	GOTO DECREMENTAR_COUNTDOWN_ACTUAL
	DECF COUNTDOWN_MINUTOS,0
	GOTO FINALLY

DECREMENTAR_COUNTDOWN_ACTUAL
	MOVLW d'60'
	MOVWF COUNTDOWN_MINUTOS
	MOVF COUNTDOWN_ACTUAL
	BTFSC STATUS,Z
	GOTO Stop
	DECF COUNTDOWN_ACTUAL,0
	GOTO FINALLY


		
;--------------------------------------;
;3.4 Rutinas de LCD					   ;
;--------------------------------------;	
LCD_Init
		movlw	b'00111000'
		movwf	LCD_PORT
		call Pulse_e
		call Delay1s

		movlw	b'00111000'
		movwf	LCD_PORT
		call Pulse_e
		call Delay1s

		movlw	b'00111000'
		movwf	LCD_PORT
		call Pulse_e
		call Delay1s

		movlw	b'00001110'
		movwf	LCD_PORT
		call Pulse_e
		call Delay1s

		movlw	b'00000110'
		movwf	LCD_PORT
		call Pulse_e
		call Delay1s

		bsf	LCD_CONFIG_PORT, LCD_RS
		movlw	b'01001000'
		movwf	LCD_PORT
		call Pulse_e
		call Delay1s

		
		movlw	b'11111111'
		movwf	LCD_PORT
;		bsf	LCD_CONFIG_PORT, LCD_RW
		bcf	LCD_CONFIG_PORT, LCD_RS
		bsf	LCD_CONFIG_PORT, LCD_E
		goto Stop

		;movlw	b'00111000'			;Set 4 bit mode
		;call	LCD_Cmd

		;movlw	0x28			;Set display shift
		;call	LCD_Cmd

		;movlw	0x06			;Set display character mode
		;call	LCD_Cmd

		;movlw	0x0e			;Set display on/off and cursor command
		;call	LCD_Cmd

		;movlw	0x06			
		;call	LCD_Cmd

;goto Stop

		;call	LCD_Clr			;clear display

		retlw	0x00

LCD_Cmd						;Rutina para configurar aspectos del LCD. Se ingresa en W el valor adecuado
	movwf	templcd
	swapf	templcd,	w	;send upper nibble
	andlw	0x0f			;clear upper 4 bits of W
	movwf	LCD_PORT
	bcf	LCD_PORT, LCD_RS	;RS line to 0
	call	Pulse_e			;Pulse the E line high

	movf	templcd,	w	;send lower nibble
	andlw	0x0f			;clear upper 4 bits of W
	movwf	LCD_PORT
	bcf	LCD_PORT, LCD_RS	;RS line to 0
	call	Pulse_e			;Pulse the E line high
	call 	Delay5
	retlw	0x00
LCD_CharD
	addlw	0x30
LCD_Char	
	movwf	templcd
	swapf	templcd,	w	;send upper nibble
	andlw	0x0f			;clear upper 4 bits of W
	movwf	LCD_PORT
	bsf	LCD_PORT, LCD_RS	;RS line to 1
	call	Pulse_e			;Pulse the E line high

	movf	templcd,	w	;send lower nibble
	andlw	0x0f			;clear upper 4 bits of W
	movwf	LCD_PORT
	bsf	LCD_PORT, LCD_RS	;RS line to 1
	call	Pulse_e			;Pulse the E line high
	call 	Delay5
	retlw	0x00
LCD_Line1						;Para moverse a fila 1, coulmna 1
	movlw	0x80			;move to 1st row, first column
	call	LCD_Cmd
	retlw	0x00
LCD_Line2						;Fila 2, coulmna 1
	movlw	0xc0			;move to 2nd row, first column
	call	LCD_Cmd
	retlw	0x00
LCD_Line1W	
	addlw	0x80			;move to 1st row, column W
	call	LCD_Cmd
	retlw	0x00
LCD_Line2W	
	addlw	0xc0			;move to 2nd row, column W
	call	LCD_Cmd
	retlw	0x00
LCD_CurOn
	movlw	0x0d			;Set display on/off and cursor command
	call	LCD_Cmd
	retlw	0x00
LCD_CurOff	
	movlw	0x0c			;Set display on/off and cursor command
	call	LCD_Cmd
	retlw	0x00
LCD_Clr		
	movlw	0x01			;Clear display
	call	LCD_Cmd
	retlw	0x00
LCD_HEX		
	movwf	tmp1
	swapf	tmp1,	w
	andlw	0x0f
	call	HEX_Table
	call	LCD_Char
	movf	tmp1, w
	andlw	0x0f
	call	HEX_Table
	call	LCD_Char
	retlw	0x00

Delay1s
			;9999995 cycles
	movlw	0x5A
	movwf	del0
	movlw	0xCD
	movwf	del1
	movlw	0x16
	movwf	del2
Delay1s_0 
	clrwdt
	decfsz	del0, f
	goto	$+2
	decfsz	del1, f
	goto	$+2
	decfsz	del2, f
	goto	Delay1s_0

			;1 cycle
	nop

			;4 cycles (including call)
	return

Delay100	
	movlw	d'100'		;delay 100mS
	goto	d0
Delay50		
	movlw	d'50'		;delay 50mS
	goto	d0
Delay20		
	movlw	d'20'		;delay 20mS
	goto	d0
Delay5		
	movlw	0x05		;delay 5.000 ms (4 MHz clock)
d0
	movwf	count1
d1
	movlw	0xC7		;delay 1mS
	movwf	counta
	movlw	0x01
	movwf	countb
Delay_0
	decfsz	counta, f
	goto	$+2
	decfsz	countb, f
	goto	Delay_0

	decfsz	count1	,f
	goto	d1
	retlw	0x00
Pulse_e		

		bcf	LCD_CONFIG_PORT, LCD_E

		call Delay100

		bsf	LCD_CONFIG_PORT, LCD_E
		
		call Delay100

		bcf	LCD_CONFIG_PORT, LCD_E

		call Delay100

		retlw	0x00

HEX_Table  	
	ADDWF   PCL , f
	RETLW   0x30
	RETLW   0x31
	RETLW   0x32
	RETLW   0x33
 	RETLW   0x34
	RETLW   0x35
	RETLW   0x36
	RETLW   0x37
   	RETLW   0x38
   	RETLW   0x39
   	RETLW   0x41
   	RETLW   0x42
  	RETLW   0x43
  	RETLW   0x44
  	RETLW   0x45
   	RETLW   0x46
; Hasta aca es el codigo extraido de la pagina

LCD_Num					;Recibe un numero en BCD (Mediante W) y lo imprime
	movwf	tmp1		;Guardamos el numero en tmp1
	bsf		tmp1,d'4'	
	bsf		tmp1,d'5'	;Seteamos los bits para el caracter
	movf	tmp1,0		;Movemos a W lo que queremos imprimir
	call	LCD_Char
	return	
LCD_Inter1				;Escribre la interfaz del LCD
	call LCD_Line1
	movlw	'L'
	call LCD_Char
	movlw	'u'
	call LCD_Char
	movlw	'z'
	call LCD_Char
	movlw	':'
	call LCD_Char
	call LCD_Line2
	movlw	'S'
	call LCD_Char
	movlw	'n'
	call LCD_Char
	movlw	'd'
	call LCD_Char
	movlw	':'
	call LCD_Char	
	return
;--------------------------------------;
;3.5 Conversor byte a BCD			   ;
;--------------------------------------;
BIN8_BCD3			;Convierte numero almacenado en BIN a bcd en BCDH:BCDL
	clrf    BCDH
	clrf    BCDL
BCD_HIGH
	movlw   .100
	subwf   BIN,f
	btfss   STATUS,C
	goto    SUMA_100
	incf    BCDH,f
	goto    BCD_HIGH
SUMA_100
	movlw   .100
	addwf   BIN,f
	movlw   0x0F
	movwf   BCDL
BCD_LOW 
	movlw   .10
	subwf   BIN,f
	btfss   STATUS,C
	goto    SUMA_10
	incf    BCDL
	movlw   0x0F
	iorwf   BCDL
	goto    BCD_LOW
SUMA_10 
	movlw   .10
	addwf   BIN,f
	movlw   0xF0
	andwf   BCDL,f
	movf    BIN,w
	iorwf   BCDL,f      
return
;--------------------------------------;
;3.6 Timer							   ;
;--------------------------------------;
TIMER_START				;Empieza a contar. Inicializa los bit de estado (Tstatus)
	movf	Thr,f
	btfsc	STATUS,d'3'
	bsf		Tstatus,d'2'
	movf	Tmin,f
	btfsc	STATUS,d'2'
	bsf		Tstatus,d'1'
	bsf		Tstatus,d'0'
	movlw	d'5'
	movwf	clocks		;Reseteamos el contador a 5
	goto	TIMER_CLCK
TIMER_HOUR
	decfsz	Thr			;decrementamos en 1 la hora. Si es 0, se acabaron las horas.
	goto	TIMER_CLCK
	bcf		Tstatus,d'2'
	goto	TIMER_CLCK
TIMER_MIN
	decfsz	Tmin		;decrementamos en 1 los minutos. Si es 0, paso una hora
	goto	TIMER_CLCK
	btfss	Tstatus,d'2';Si quedan horas, vamos a TIMER_HOUR. Si no, se acabaron los minutos
	goto	TIMER_MIN1
	movlw	d'59'
	movwf	Tmin
	goto	TIMER_HOUR
TIMER_MIN1
	bcf		Tstatus,d'1'
	goto	TIMER_CLCK
TIMER_SEC
	movlw	d'5'
	movwf	clocks		;Reseteamos el contador a 5
	decfsz	Tsec,f		;Decrementamos en 1. Si es 0, paso un minuto
	goto	TIMER_CLCK
	btfss	Tstatus,d'1';Si quedan minutos, vamos a TIMER_MIN. Si no, se acabo el tiempo
	goto	TIMER_FINISH
	movlw	d'59'
	movwf	Tsec
	goto	TIMER_MIN
TIMER_5CLCK				;Rutina que cuenta si hubieron 5 ciclos
	bcf		INTCON,TMR0IF
	decfsz	clocks,f	;Si llegamos a 0, significa que paso un segundo		
	goto	TIMER_CLCK
	goto 	TIMER_SEC
TIMER_CLCK
	;movwf	offsetT		;guardamos el offset en registro temporal
	movlw	d'0'		
	movwf	offset		;reiniciamos offset
	movlw	d'131'		;256 - 131 = 125 clocks
	addwf	offsetT,w	;Le suma el offset (cuantos ciclos han pasado) y lo guarda en W	
	movwf	TMR0		;Iniciamos la cuenta
	return
TIMER_FINISH
		
end

;-------------------------------------------------------;
; Bibliografia:                                        	;
; LCD: 													;
; http://www.winpicprog.co.uk/pic_tutorial.htm    		;
; Binario a BCD:										;
; http://www.dattalo.com/technical/software/pic/bcd.txt	;
;-------------------------------------------------------;
