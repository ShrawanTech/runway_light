     list      p=10f322            ; list directive to define processor
     #include <p10f322.inc>        ; processor specific variable definitions
     __CONFIG _WRT_OFF & _BORV_LO & _LPBOR_OFF & _LVP_OFF & _MCLRE_OFF & _CP_OFF & _PWRTE_ON & _WDTE_ON & _BOREN_NSLEEP & _FOSC_INTOSC
     ;__CONFIG  .6492
; '__CONFIG' directive is used to embed configuration word within .asm file.
; The lables following the directive are located in the respective .inc file.
; See data sheet for additional information on configuration word settings.

;***** VARIABLE DEFINITIONS
w_temp        	EQU     0x40        ; variable used for context saving 
status_temp   	EQU     0x41        ; variable used for context saving
TEMP          	EQU     0X42
TEMP2         	EQU     0X43
TEMP3         	EQU     0X44
KEY          	EQU     0X45
INT_STATUS	EQU     0X46
CNT_NUM		EQU     0X47
RE_NUM1		EQU     0X48
RE_NUM2		EQU     0X49
loop_counter	EQU	0X50
loop_counter2	EQU	0X51
;**********************************************************************
START     ORG     0x000             ; processor reset vector
          GOTO    MAIN             ; go to beginning of program

ISR       ORG     0x004             ; interrupt vector location
     
;         Context saving for ISR
          ;MOVWF   w_temp            ; save off current W register contents
          ;MOVF    STATUS,w          ; move status register into W register
          ;MOVWF   status_temp       ; save off contents of STATUS register
	 ;INSERT INTERRUPT CODE HERE
		;BTFSC	INTCON,TMR0IF
		;GOTO	TMR0_ISR
		CALL	    DELAY_40US
		BTFSC	    PORTA,RA3 ; External interrupt if high Goto WORK_CY2_1
		GOTO	    WORK_CY2_1
;;         -----SAMPLE CODE----- if the interrupt came from the timer, execute the
;;         TMR0 interrupt service routine. 
;          BTFSC   INTCON, T0IF ; Uncomment this line to test sample code 
;          CALL    TMR0_ISR     ; Uncomment this line to test sample code     

;         Restore context before returning from interrupt
		
          ;MOVF    status_temp,w   ; retrieve copy of STATUS register
          ;MOVWF   STATUS          ; restore pre-isr STATUS register contents
          ;SWAPF   w_temp,f
          ;SWAPF   w_temp,w        ; restore pre-isr W register contents
          RETFIE                  ; return from interrupt
;**************************************************************
TMR0_ISR
		  MOVLW 0XFB
		  ANDWF INTCON
		  DECFSZ CNT_NUM,1
		  GOTO TMR0_ISR_RT
		  MOVLW 0XFF
		  MOVWF CNT_NUM
		  MOVLW 0X03
		  XORWF KEY,W
		  BTFSC STATUS,Z;KEY is not equal to 3 skip the next step
		  GOTO  TMRO_ISR_3	
		  MOVLW 0X02
		  XORWF KEY,W
		  BTFSC STATUS,Z;KEY is not equal to 2 skip the next step
		  GOTO  TMRO_ISR_2  
		  MOVLW 0X01
		  XORWF KEY,W
		  BTFSC STATUS,Z;KEY is not equal to 1 skip the next step
		  GOTO  TMRO_ISR_1
TMR0_ISR_RT
		  DECF  KEY
		  SWAPF status_temp,W ;Swap STATUS_TEMP register into W
		  ;(sets bank to original state)
		  MOVWF STATUS ;Move W into STATUS register
		  SWAPF w_temp,F ;Swap W_TEMP
		  SWAPF w_temp,W ;Swap W_TEMP into W
		  RETFIE
;RA2=1
TMRO_ISR_3
		  MOVLW	(1<<RA2)
		  MOVWF LATA
		  GOTO TMR0_ISR_RT	
;RA0=1
TMRO_ISR_2
		  MOVLW	(1<<RA0)
		  MOVWF LATA
		  GOTO TMR0_ISR_RT	
;RA1=1
TMRO_ISR_1
		  MOVLW	(1<<RA1)
		  MOVWF LATA
		  GOTO TMR0_ISR_RT		
;**********************************************************************
MAIN
		MOVLW   	(1<<IRCF1)|(1<<IRCF0)       						 
		MOVWF   	OSCCON	    ;set to internal frequency 1M 
		;RAM cleared
		MOVLW   	0X40        ; initialize pointer
		MOVWF   	FSR         ; to RAM


NEXT  
		CLRF    	INDF        ; clear INDF register
		INCF    	FSR, F      ; inc pointer
		BTFSS   	FSR,7       ; all done?
		GOTO    	NEXT        ; no clear next

		BANKSEL 	PORTA
		CLRW
		MOVWF   	PORTA
		MOVF    	W,OPTION_REG
		ANDLW   	0XDF
		MOVWF   	OPTION_REG
		bsf		OPTION_REG, INTEDG
		CLRW  		
		MOVWF   	WPUA	; close pull up								
		BANKSEL 	TRISA	;IO port set output mode
		MOVLW  		(1<<RA3)
		MOVWF   	TRISA									
		MOVLW   	(1<<WDTPS2)|(1<<WDTPS1)|(1<<WDTPS0)|(1<<SWDTEN)
		MOVWF		WDTCON 		;Set watchdog frequency division, open watchdog						
		BANKSEL		PORTA
		;Interrupt Enable
		MOVLW		(1<<GIE)|(1<<PEIE)|(1<<INTE);|(1<<TMR0IE)
		MOVWF		INTCON
		MOVLW		0XFF
		MOVWF		CNT_NUM
RESTART
		CLRW
		MOVWF       LATA
		CALL        DELAY_150MS
		CALL        DELAY_150MS
		CALL        DELAY_150MS
		CALL        DELAY_150MS
		BTFSS	    PORTA,RA3	;Check if the KEY is pressed or RA3 is high, press to skip the next step, BTFSS-Bit Test f, Skip if Set/High
		GOTO        WORK_ERROR_CONDITION_LOOP ; If RA3 is 0 jump to WORK_CY2

WORK_CY1
		
		MOVLW		(1<<RA2) 
		MOVWF		 LATA
		CALL		DELAY_150MS
		CALL		DELAY_150MS
		MOVLW		(1<<RA0)
		MOVWF		LATA
		CALL		DELAY_150MS
		CALL		DELAY_150MS
		MOVLW		(1<<RA1)
		MOVWF		LATA
		CALL		DELAY_150MS
		CALL		DELAY_150MS
		GOTO		WORK_CY1

WORK_CY2_1
	          MOVLW  0X1D4C	; 7500 times loop, Reason is it has to  wait for 300ms 2 cycle in each loop 40uS is lost
		  MOVWF  loop_counter2	
	WORK_CY2_1_1	
		INCFSZ		RE_NUM2	;RE_NUM2=0 skip next sentence
		DECFSZ		loop_counter2
		GOTO		FF1
		GOTO		WORK_ERROR_CONDITION  ; This has been changed from WORK_CY1 to WORK_ERROR_CONDITION 
		INCFSZ		RE_NUM1	;RE_NUM1=0 skip next sentence
		GOTO		FF1
		
FF1		
		CALL		DELAY_40US
		BTFSS 		PORTA,RA3   ;Check if RA3 is high, if low go to WORK_CY2_1 
		GOTO		WORK_CY2_1_1  ;chnaged from  WORK_CY2_1
		CALL		DELAY_40US
		BTFSS		PORTA,RA3   ;Check if the KEY is pressed or RA3 is high, if low go back to WORK_CY2_1 else next line WORK_CY2_2
		GOTO            WORK_CY2_1_1  ;anti-shake
WORK_CY2_2
		CALL		DELAY_40US
		BTFSC 		PORTA,RA3   ;Check if RA3 is high, if low go to WORK_CY2_2 again, BTFSC- Bit Test f, Skip if Clear or Low 
		GOTO		WORK_CY2_2 
		CALL		DELAY_40US
		BTFSC		PORTA,RA3   ;Check if the KEY is pressed or RA3 is high, press to skip the next step BTFSC- Bit Test f, Skip if Clear or Low 
		GOTO		WORK_CY2_2  ;
		MOVLW		(1<<RA2)
		MOVWF		 LATA
		CALL		DELAY_150MS
		CALL		DELAY_150MS
		MOVLW		(1<<RA0)
		MOVWF		LATA
		CALL		DELAY_150MS
		CALL		DELAY_150MS
		MOVLW		(1<<RA1)
		MOVWF		 LATA	
		GOTO 		WORK_CY2_1

	
WORK_ERROR_CONDITION_LOOP
		
		MOVLW		.80	; Assuming 72 is max number of strip.
		MOVWF		loop_counter
    Strip_loop	
					    ; 1 NOP added coz there is already 2 instruction added before this line
		;NOP
		MOVLW		(1<<RA2) 
		MOVWF		 LATA
		CALL		DELAY_150MS
		CALL		DELAY_150MS
		MOVLW		(1<<RA0) 
		MOVWF		 LATA
		CALL		DELAY_150MS
		CALL		DELAY_150MS
		NOP
		CALL		DELAY_150MS
		BTFSC 		PORTA,RA3; Check again if RA3 is high BTFSC Skip next instruction if Low or clear
		GOTO		WORK_CY2_1
		CALL		DELAY_150MS
		DECFSZ		loop_counter, 1 ; This insturction equivqlent timing is added to WORK_CY1
		GOTO		Strip_loop
		  	
WORK_ERROR_CONDITION ; After waiting for Max time Start Normal
		
		MOVLW		(1<<RA2) 
		MOVWF		 LATA
		CALL		DELAY_150MS
		CALL		DELAY_150MS
		MOVLW		(1<<RA0)
		MOVWF		LATA
		CALL		DELAY_150MS
		CALL		DELAY_150MS
		MOVLW		(1<<RA1)
		MOVWF		LATA
		CALL		DELAY_150MS
		BTFSC 		PORTA,RA3; Check again if RA3 is high BTFSC Skip next instruction if Low or clear
		GOTO		WORK_CY2_1
		CALL		DELAY_150MS
		GOTO		WORK_ERROR_CONDITION		

		
DELAY_40US                        ; Oscillator 1M, 10 instruction cycles Instruction Cycle Time (Tcy) = 4 / Fosc(FOSC is oscilator frequency
          CLRWDT		; 1 cycles
          NOP			; 1 cycles
          NOP			; 1 cycles
          NOP			; 1 cycles
          NOP			; 1 cycles
          NOP			; 1 cycles
          NOP			; 1 cycles
          RETURN		; 2 cycle

DELAY_150MS; this will be 165ms
          MOVLW  0X4B	; 75 times loop
          MOVWF  TEMP3
          CALL   DELAY_2MS
          DECFSZ TEMP3
          GOTO   $-2
          RETURN

	  
DELAY_2MS ; this will be 2.176ms considering insctruction ccyle except DELAY_40uS
          MOVLW  0X0A ; 10 times, i.e 2ms divide by 40us is 50 and 50 divide by 5(five time call to 40us) is 10
          MOVWF  TEMP2
DELAY_2MS_1
          CALL   DELAY_40US
	  CALL   DELAY_40US
          CALL   DELAY_40US
	  CALL   DELAY_40US
          CALL   DELAY_40US
          DECFSZ TEMP2
          GOTO   DELAY_2MS_1
          RETURN
;/////////////////////////////////////////////////////////
          END




