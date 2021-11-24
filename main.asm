.include "m16def.inc"
.def temp = r20
.def temp1 = r21

.DSEG ; arxi tmimatos dedomenwn
_tmp_: .byte 2
.CSEG ; telos tmimatos dedomenwn 

.org 0x00
		rjmp setup
setup: 
		ser temp
		out DDRB,temp ;PORTB OUTPUT

		ldi r24,(1<<PC7)|(1<<PC6)|(1<<PC5)|(1<<PC4) ; thetei ws ejodous ta 4 MSB kai eisodous ta 4 lsb
		out DDRC, r24;  ;tis portc gia energopoiisi pliktrologiou

		ldi r24, low(RAMEND) 
		out SPL, r24
		ldi r24, high(RAMEND) 
		out SPH, r24  ; arxikopoiisi stack pointer
		ser r24
		out DDRD, r24 ; arxikopoiisi portd gia othoni
		clr r24
start:  
first: 
		ldi r24,0xf0
		rcall scan_keypad_rising_edge_sim  ;anagnosi pliktrologiou
		cpi r24,0x00   ;elegxos an patithike kati 3i kai 4i seira
		brne ex1     ; an patithike tote vges
		cpi r25,0x00  ; elegos an patithike kati 1i kai 2i seira
		breq first   ; an oxi jana
ex1:	rcall keypad_to_ascii_sim ;vriskei ton antistoixo ascii char
		mov temp, r24 ; to kratame ston temp
second:
		ldi r24,0xf0
		rcall scan_keypad_rising_edge_sim   ; opws kai gia to first...
		cpi r24,0x00
		brne ex2
		cpi r25,0x00
		breq second
ex2:	rcall keypad_to_ascii_sim

		cpi temp,'3' ; elegxos first
		brne false
		cpi r24,'5' ; elegxos second
		breq corr ; an einai idia

false:
		rcall lcd_init_sim  ; ektipwsi mnmatos
		ldi r24, 'A'
		rcall lcd_data_sim
		ldi r24, 'L'
		rcall lcd_data_sim
		ldi r24, 'A'
		rcall lcd_data_sim
		ldi r24, 'R'
		rcall lcd_data_sim
		ldi r24, 'M'
		rcall lcd_data_sim
		ldi r24, ' '
		rcall lcd_data_sim
		ldi r24, 'O'
		rcall lcd_data_sim
		ldi r24, 'N'
		rcall lcd_data_sim

		ser temp    ; anavosvinoume ta PB0-7 4 fores gia 0,5sec
		out PORTB,temp
		rcall scan_keypad_rising_edge_sim
		rcall wait_usec
		rcall scan_keypad_rising_edge_sim
		clr temp
		out PORTB,temp
		rcall wait_usec

		ser temp
		out PORTB,temp
		rcall wait_usec
		rcall scan_keypad_rising_edge_sim
		clr temp
		out PORTB,temp
		rcall wait_usec
		rcall scan_keypad_rising_edge_sim

		ser temp
		out PORTB,temp
		rcall wait_usec
		rcall scan_keypad_rising_edge_sim
		clr temp
		out PORTB,temp
		rcall wait_usec
		rcall scan_keypad_rising_edge_sim

		ser temp
		out PORTB,temp
		rcall wait_usec
		rcall scan_keypad_rising_edge_sim
		clr temp
		out PORTB,temp
		rcall wait_usec
		rcall scan_keypad_rising_edge_sim
		rjmp start

corr:	
		rcall lcd_init_sim  ; paromoiws gia to swsto pin
		ldi r24, 'W'
		rcall lcd_data_sim
		ldi r24, 'E'
		rcall lcd_data_sim
		ldi r24, 'L'
		rcall lcd_data_sim
		ldi r24, 'C'
		rcall lcd_data_sim
		ldi r24, 'O'
		rcall lcd_data_sim
		ldi r24, 'M'
		rcall lcd_data_sim
		ldi r24, 'E'
		rcall lcd_data_sim
		ldi r24, ' '
		rcall lcd_data_sim
		ldi r24, '3'
		rcall lcd_data_sim
		ldi r24, '5'
		rcall lcd_data_sim


		ser temp
		out PORTB,temp
		rcall wait_usec
		rcall scan_keypad_rising_edge_sim
		rcall wait_usec
		rcall scan_keypad_rising_edge_sim
		rcall wait_usec
		rcall scan_keypad_rising_edge_sim
		rcall wait_usec
		rcall scan_keypad_rising_edge_sim
		rcall wait_usec
		rcall scan_keypad_rising_edge_sim
		rcall wait_usec
		rcall scan_keypad_rising_edge_sim
		rcall wait_usec
		rcall scan_keypad_rising_edge_sim
		rcall wait_usec
		rcall scan_keypad_rising_edge_sim
		clr temp
		out PORTB,temp
		rjmp start
; ==============================
scan_row_sim:
	out PORTC, r25 ; r25 deixnei tin seira pou elegxoume

	push r24 ; swsti leitourgia apomakrinsmenis prosvasis //=?
	push r25 
	ldi r24,low(500) 
	ldi r25,high(500)
	rcall wait_usec
	pop r25
	pop r24

	nop
	nop ; kathisterisi gia allagi katastasis
	in r24, PINC ; ta 4 lsb deixnoun an kapoio einai pathmeno sa auti tin seira
	andi r24 ,0x0f ; maska-apomonosi thesis bit 
	ret 

scan_keypad_sim:
	push r26 
	push r27
	ldi r25 , 0x10 ; elegxos 1is grammis
	rcall scan_row_sim
	swap r24 ; apothikeusi sta 4 msb toy r24
	mov r27, r24 
	ldi r25 ,0x20 ; elegxos 2is
	rcall scan_row_sim
	add r27, r24 ; apothikeusi 2is seiras sta lsb tou r24
	ldi r25 , 0x40 ; elegxos 3is seiras
	rcall scan_row_sim
	swap r24  
	mov r26, r24 ;msb r26
	ldi r25 ,0x80 ;4 seira
	rcall scan_row_sim 
	add r26, r24 
	movw r24, r26 ; metafora apotelesmatos sta 24:25
	clr r26 
	out PORTC,r26 
	pop r27  
	pop r26
	ret

scan_keypad_rising_edge_sim:
	push r22 
	push r23 
	push r26
	push r27
	rcall scan_keypad_sim ; elegxos pliktrologiou gia piesmenous diakoptes
	push r24  ; apothikeusi apotelesmatos stin stoiva
	push r25
	ldi r24 ,15 
	ldi r25 ,0 
	nop  ; kathisterisi
	rcall scan_keypad_sim ; diavase jana to pliktrologio kai aperipse ta pliktra pou emfanizoun spinthirismo
	pop r23 
	pop r22
	and r24 ,r22
	and r25 ,r23
	ldi r26 ,low(_tmp_) ;fortwse tin proigoumeni katastasi twn diakoptwn
	ldi r27 ,high(_tmp_) 
	ld r23 ,X+
	ld r22 ,X
	st X ,r24 ; apothikeuoume stin ram tin nea katastasi
	st -X ,r25 
	com r23
	com r22  ; vriskoume autous pou molis exoun patithei
	and r24 ,r22
	and r25 ,r23
	pop r27 
	pop r26  
	pop r23
	pop r22
	ret 

	keypad_to_ascii_sim:
	push r26 
	push r27 
	movw r26 ,r24 
	
	ldi r24 ,'*'  ; me vasi to pinaka kai ton tropo pou apothikeusame ta pliktra elegxoume gia assous kai apothikeuoume to apotelesma ston r24
	sbrc r26 ,0
	rjmp return_ascii
	ldi r24 ,'0'
	sbrc r26 ,1
	rjmp return_ascii
	ldi r24 ,'#'
	sbrc r26 ,2
	rjmp return_ascii
	ldi r24 ,'D'
	sbrc r26 ,3 ; 
	rjmp return_ascii 
	ldi r24 ,'7'
	sbrc r26 ,4
	rjmp return_ascii
	ldi r24 ,'8'
	sbrc r26 ,5
	rjmp return_ascii
	ldi r24 ,'9'
	sbrc r26 ,6
	rjmp return_ascii 
	ldi r24 ,'C'
	sbrc r26 ,7
	rjmp return_ascii
	ldi r24 ,'4' 
	sbrc r27 ,0 
	rjmp return_ascii
	ldi r24 ,'5' 
	sbrc r27 ,1
	rjmp return_ascii
	ldi r24 ,'6'
	sbrc r27 ,2
	rjmp return_ascii
	ldi r24 ,'B'
	sbrc r27 ,3
	rjmp return_ascii
	ldi r24 ,'1'
	sbrc r27 ,4
	rjmp return_ascii 
	ldi r24 ,'2'
	sbrc r27 ,5
	rjmp return_ascii
	ldi r24 ,'3' 
	sbrc r27 ,6
	rjmp return_ascii
	ldi r24 ,'A'
	sbrc r27 ,7
	rjmp return_ascii
	clr r24
	rjmp return_ascii
	return_ascii:
	pop r27 ; 
	pop r26
	ret 
;=============================
write_2_nibbles_sim:
		push r24  ; swsti leitourgia apomakrismenis prosvasis
		push r25
		ldi r24 ,low(6000) 
		ldi r25 ,high(6000) 
		rcall wait_usec 
		pop r25
		pop r24
		push r24 ; stelnei ta 4 msb
		in r25, PIND  ; diavazoume 4 lsb
		andi r25, 0x0f 
		andi r24, 0xf0 
		add r24, r25  
		out PORTD, r24 
		sbi PORTD, PD3 
		cbi PORTD, PD3
		push r24  
		push r25
		ldi r24 ,low(6000) 
		ldi r25 ,high(6000) 
		rcall wait_usec 
		pop r25
		pop r24
		pop r24
		swap r24
		andi r24 ,0xf0 
		add r24, r25
		out PORTD, r24 
		sbi PORTD, PD3 
		cbi PORTD, PD3 
		ret

;=============================
lcd_data_sim:
		push r24
		push r25
		sbi PORTD, PD2
		rcall write_2_nibbles_sim 
		ldi r24 ,43
		ldi r25 ,0
		nop
		pop r25
		pop r24
		ret

;============================
lcd_command_sim:
		push r24
		push r25
		cbi PORTD,PD2
		rcall write_2_nibbles_sim
		ldi r24,39
		ldi r25,0
		rcall wait_usec
		pop r25
		pop r24
		ret

;===========================

lcd_init_sim:
		push r24 
		push r25
		ldi r24, 40
		ldi r25, 0
		rcall wait_usec
		ldi r24, 0x30
		out PORTD, r24 
		sbi PORTD, PD3 
		cbi PORTD, PD3 
		ldi r24, 39
		ldi r25, 0
		rcall wait_usec
		push r24
		push r25
		ldi r24,low(1000) 
		ldi r25,high(1000) 
		rcall wait_usec 
		pop r25
		pop r24
		ldi r24, 0x30
		out PORTD, r24 
		sbi PORTD, PD3 
		cbi PORTD, PD3 
		ldi r24,39
		ldi r25,0
		rcall wait_usec
		push r24
		push r25
		ldi r24 ,low(1000) 
		ldi r25 ,high(1000) 
		rcall wait_usec 
		pop r25
		pop r24

		ldi r24,0x20
		out PORTD, r24 
		sbi PORTD, PD3 
		cbi PORTD, PD3 
		ldi r24,39
		ldi r25,0
		rcall wait_usec

		push r24
		push r25
		ldi r24 ,low(1000) 
		ldi r25 ,high(1000) 
		rcall wait_usec 
		pop r25
		pop r24

		ldi r24,0x28
		rcall lcd_command_sim
		ldi r24,0x0c
		rcall lcd_command_sim
		ldi r24,0x01
		rcall lcd_command_sim
		ldi r24, low(1530) 
		ldi r25, high(1530) 
		rcall wait_usec
		ldi r24 ,0x06
		rcall lcd_command_sim
		pop r25 
		pop r24 
		ret

;=======================
wait_usec:
	sbiw r24 ,1	
	nop	
	nop				
	nop					
	nop	
	nop
	nop		
	nop
	nop		
	brne wait_usec		
ret
