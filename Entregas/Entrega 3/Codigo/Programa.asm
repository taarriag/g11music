;-------------------;
; 1 Header          ;
;-------------------;
list p=16f877a         ; Le decimos al compilador que pic usamos
include <P16F877A.inc> ; Definicion de parametros y constantes.
;------------------------------------------;
; 1.1 Definicion de Registros y constantes ;
;------------------------------------------;
udata			; Definimos que la memoria para definir simbolos no tope con los special function registers.
EJEMPLO	res 1	; REServamos 1 byte con el nombre EJEMPLO

;--------------------------------------;
; 2 Configuracion                      ;
;--------------------------------------;
org	H'00'
goto	START		; Vamos al inicio del programa
org	H'04'			
goto	INTERRUPT	; Vamos a la subrutina de interrupcion
START
;--------------------------------------;
; 2.1 Puertos                          ;
;--------------------------------------;
bsf		STATUS,RP0	; Vamos al banco 1 
clrf	TRISD		; Configuramos puerto D como salida
movlw	h'ff'
movwf	TRISB		; Puerto B como input
movwf	TRISA		; Puerto A como input
movlw	b'00000100'	
movwf	ADCON1		; Puerto A, Pines [0,1] como entrada analoga, voltaje PIC como voltaje referencia. Hay que probar esto!
;TODO: Configuracion puerto C, serial
;--------------------------------------;
; 2.2 Interrupciones                   ;
;--------------------------------------;
bcf		STATUS,RP0	; Vamos al banco 0
movlw	b'11001000'
movwf	INTCON		; Permisos de interrupcion: Global, Perifericos y RB4-RB7.
movlw	b'01000000'
movwf	PIE1		; Permiso de interrupcion para conversion A/D
;TODO: Configuracion interrupciones puerto C, serial
;--------------------------------------;
; 3 Subrutinas                         ;
;--------------------------------------;
INTERRUPT
end
