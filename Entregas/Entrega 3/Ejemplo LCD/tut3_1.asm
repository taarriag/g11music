;LCD text demo - 4 bit mode
;Nigel Goodwin 2002

	LIST	p=16F877A		;tell assembler what chip we are using
	include <P16F877A.inc>	;include the defaults for the chip
;	ERRORLEVEL	0,	-302	;suppress bank selection messages
;	__config 0x3D18			;sets the configuration settings (oscillator type etc.)




			udata						;start of general purpose registers
			count 		res 1			;used in looping routines
			count1		res 1			;used in delay routine
			counta		res 1			;used in delay routine
			countb		res 1			;used in delay routine
			tmp1		res 1			;temporary storage
			tmp2		res 1
			templcd		res 1			;temp store for 4 bit mode
			templcd2	res 1
			palabra1	res	16			;
			palabra2	res	16			;
			BIN			res	1			; Numero para conversion binario-BCD
			BCDH		res	1			; Bcd high
			BCDL		res 1			; Bcd low

LCD_PORT	Equ	PORTD
LCD_TRIS	Equ	TRISD
LCD_RS		Equ	0x04			;LCD handshake lines
LCD_RW		Equ	0x06
LCD_E		Equ	0x07

		org	0x0000
		movlw	0x07
		movwf	CMCON			;turn comparators off (make it like a 16F84)

Initialise	clrf	count
		clrf	PORTA
		clrf	PORTB



SetPorts	bsf 	STATUS,		RP0	;select bank 1
		movlw	0x00			;make all pins outputs
		movwf	LCD_TRIS
		bcf 	STATUS,		RP0	;select bank 0

		call	Delay100		;wait for LCD to settle


		call	LCD_Init		;setup LCD


		clrf	count			;set counter register to zero
		call NUMERO
Message		movf	count, w		;put counter value in W
		call	Text			;get a character from the text table
		xorlw	0x00			;is it a zero?
		btfsc	STATUS, Z
		goto	NextMessage
		call	LCD_Char
		incf	count, f
		goto	Message

NextMessage	call	LCD_Line2		;move to 2nd row, first column

		clrf	count			;set counter register to zero
Message2	movf	count, w		;put counter value in W
		call	Text2			;get a character from the text table
		xorlw	0x00			;is it a zero?
		btfsc	STATUS, Z
		goto	EndMessage
		call	LCD_Char
		incf	count, f
		goto	Message2

EndMessage	
		
Stop		goto	Stop			;endless loop




;Subroutines and text tables

;LCD routines

;Initialise LCD
LCD_Init	movlw	0x20			;Set 4 bit mode
		call	LCD_Cmd

		movlw	0x28			;Set display shift
		call	LCD_Cmd

		movlw	0x06			;Set display character mode
		call	LCD_Cmd

		movlw	0x0d			;Set display on/off and cursor command
		call	LCD_Cmd

		call	LCD_Clr			;clear display

		retlw	0x00

; command set routine
LCD_Cmd		movwf	templcd
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

LCD_CharD	addlw	0x30
LCD_Char	movwf	templcd
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

LCD_Line1	movlw	0x80			;move to 1st row, first column
		call	LCD_Cmd
		retlw	0x00

LCD_Line2	movlw	0xc0			;move to 2nd row, first column
		call	LCD_Cmd
		retlw	0x00

LCD_Line1W	addlw	0x80			;move to 1st row, column W
		call	LCD_Cmd
		retlw	0x00

LCD_Line2W	addlw	0xc0			;move to 2nd row, column W
		call	LCD_Cmd
		retlw	0x00

LCD_CurOn	movlw	0x0d			;Set display on/off and cursor command
		call	LCD_Cmd
		retlw	0x00

LCD_CurOff	movlw	0x0c			;Set display on/off and cursor command
		call	LCD_Cmd
		retlw	0x00

LCD_Clr		movlw	0x01			;Clear display
		call	LCD_Cmd
		retlw	0x00

LCD_HEX		movwf	tmp1
		swapf	tmp1,	w
		andlw	0x0f
		call	HEX_Table
		call	LCD_Char
		movf	tmp1, w
		andlw	0x0f
		call	HEX_Table
		call	LCD_Char
		retlw	0x00
Delay100	movlw	d'100'		;delay 100mS
		goto	d0
Delay50		movlw	d'50'		;delay 50mS
		goto	d0
Delay20		movlw	d'20'		;delay 20mS
		goto	d0
Delay5		movlw	0x05		;delay 5.000 ms (4 MHz clock)
d0		movwf	count1
d1		movlw	0xC7			;delay 1mS
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

Pulse_e		bsf	LCD_PORT, LCD_E
		nop
		bcf	LCD_PORT, LCD_E
		retlw	0x00

;end of LCD routines

HEX_Table  	ADDWF   PCL       , f
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


Text		addwf	PCL, f
		retlw	'H'
		retlw	'e'
		retlw	'l'
		retlw	'l'
		retlw	'o'
		retlw	0x00

Text2		ADDWF   PCL, f
            	RETLW   'W'
            	RETLW   'o'
            	RETLW   'r'
            	RETLW   'l'
            	RETLW   'd'
            	RETLW   '!'
            	RETLW   '!'
            	RETLW   '!'
            	RETLW   0x00	
BIN8_BCD3
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
BCD_LOW movlw   .10
        subwf   BIN,f
        btfss   STATUS,C
        goto    SUMA_10
        incf    BCDL
        movlw   0x0F
        iorwf   BCDL
        goto    BCD_LOW
SUMA_10 movlw   .10
        addwf   BIN,f
        movlw   0xF0
        andwf   BCDL,f
        movf    BIN,w
        iorwf   BCDL,f      
return


NUMERO
	movlw	d'123'
	movwf	BIN
	call	BIN8_BCD3
	call	LCD_Line1
	movf	BCDH,0
	call 	LCD_Num	
	swapf	BCDL,1		;Giramos los nibbles
	movlw	h'0f'		
	andwf	BCDL,0		;Botamos el nibble superior y guardamos en w
	call	LCD_Num
	swapf	BCDL,1
	movlw	h'0f'
	andwf	BCDL,0
	call	LCD_Num	
	return
LCD_Num					;Recibe un numero en BCD y lo imprime
	movwf	tmp1		;Guardamos el numero en tmp1
	bsf		tmp1,d'4'	
	bsf		tmp1,d'5'	;Seteamos los bits para el caracter
	movf	tmp1,0		;Movemos a W lo que queremos imprimir
	call	LCD_Char
	return	
end

;-------------------------------------------------------;
; Bibliografia:                                        	;
; LCD: 													;
; http://www.winpicprog.co.uk/pic_tutorial.htm    		;
; Binario a BCD:										;
; http://www.dattalo.com/technical/software/pic/bcd.txt	;
;-------------------------------------------------------;