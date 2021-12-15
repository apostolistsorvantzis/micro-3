.DSEG
_tmp_: .byte 2


.CSEG
.include "m16def.inc"

.def flag2=r20 
.def flag1=r21
.def flag=r16
.def temp=r17
.def temp1=r18 ;general purpose register1
.def flag3=r19 ;general purpose register2


.macro CHECK_IF_ZERO
;macro prokeimenou na mhn grafoume sunexeia 
;ean einai mhden oi r25,r24
	cpi r24,0x00

	brne END_NOT_EQUAL
	cpi r25,0x00

	brne END_NOT_EQUAL

	ldi temp1,0x01 ;true
	rjmp END
	
	END_NOT_EQUAL:
	ldi temp1,0x00 ;false

	END:
.endm

.macro CHECK_FOR_VALID_r24

	cpi r24,@0
	brne NOT_EQUAL

	ldi temp1,0x01 ;true
	rjmp END1

	NOT_EQUAL:
	ldi temp1,0x00 ;false

	END1:
.endm


.org 0x00
rjmp start
.org 0x10
rjmp ISR_TIMER1_OVF
.org 0x1c
rjmp ADC_ISR


; Replace with your application code
start:
	ldi r24, low(RAMEND)
		out SPL, r24
	ldi r24, high(RAMEND)
		out SPH, r24

	ser r24 ; r24 = FF
	out DDRB, r24 ; initialize  port b 
	out DDRD, r24 ; and d for output
	clr r24
	ldi r24, (1 << PC7) | (1 << PC6) | (1 << PC5) | (1 << PC4) 
	out DDRC, r24 
;========== nees arxikopoiiseis
    ldi flag3,0x01
    clr flag2
    clr flag ; flag gia welcome
    clr flag1
	ldi r24 ,(1<<TOIE1) ; ενεργοποίηση διακοπής υπερχείλισης του μετρητή TCNT1
    out TIMSK ,r24 ; για τον timer1

    ldi r24 ,(1<<CS12) | (0<<CS11) | (1<<CS10) ; CK/1024 
    out TCCR1B ,r24

    ldi r24,0xfc ; αρχικοποίηση του TCNT1
    out TCNT1H ,r24 ; για υπερχείλιση μετά από 5 sec 
    ldi r24 ,0xf3
    out TCNT1L ,r24
    rcall ADC_init
    clr r24
	clr r25
	rcall lcd_init_sim
    sei

PROGRAM:


	LOOP:
	rcall scan_keypad_rising_edge_sim

	CHECK_IF_ZERO ;check if r25 == 0 & r24 == 0
	cpi temp1,0x01
	breq LOOP

	rcall keypad_to_ascii_sim

	CHECK_FOR_VALID_r24 '0'
	cpi temp1,0x00
	breq ABORT

	LOOP1:
	rcall scan_keypad_rising_edge_sim

	CHECK_IF_ZERO ;check if r25 == 0 & r24 == 0
	cpi temp1,0x01
	breq LOOP1

	movw r26,r24 ;temporary regs for result
	rcall keypad_to_ascii_sim

	CHECK_FOR_VALID_r24 '4'
	cpi temp1,0x00
	breq ABORT
;correct
    clr r24
	clr r25
	rcall lcd_init_sim
    ldi r24,'W'
	rcall lcd_data_sim 
	ldi r24,'E'
	rcall lcd_data_sim
	ldi r24,'L'
	rcall lcd_data_sim
	ldi r24,'C'
	rcall lcd_data_sim
	ldi r24,'O'
	rcall lcd_data_sim
	ldi r24,'M'
	rcall lcd_data_sim
	ldi r24,'E'
	rcall lcd_data_sim
	
	ldi flag,0x01
	ldi r24,low(4000)
	ldi r25,high(4000)
	rcall wait_msec			; DELAY 4 SECONDS (MACRO)
    clr flag
	rjmp PROGRAM


	ABORT: ; lathos

	ldi temp,0x04 		; iterate 4 times 
	L1:
    ser flag1
	ldi r24,low(500)
	ldi r25,high(500)
	rcall wait_msec			; delay 0.5sec (MACRO)

    clr flag1
	ldi r24,low(500)
	ldi r25,high(500)
	rcall wait_msec

	dec temp			; cnt--
	cpi temp, 0x00 		; (cnt == 0) ?
	brne L1 			; if cnt != 0 goto L1
	
	rjmp PROGRAM

	scan_row_sim:
	out PORTC, r25 ; � ���������� ������ ������� ��� ������ �1�
	push r24 ; ����� ������ ��� ����������� ��� �� �����
	push r25 ; ���������� ��� ������������ ��������������
	ldi r24,low(500) 
	ldi r25,high(500)
	rcall wait_usec
	pop r25
	pop r24 ; ����� ����� ������
	nop
	nop ; ����������� ��� �� �������� �� ����� � ������ ����������
	in r24, PINC ; ����������� �� ������ (������) ��� ��������� ��� ����� ���������
	andi r24 ,0x0f ; ������������� �� 4 LSB ���� �� �1� �������� ��� ����� ���������
	ret ; �� ���������

	scan_keypad_sim:
	push r26 ; ���������� ���� ����������� r27:r26 ����� ����
	push r27 ; ��������� ���� ���� �������
	ldi r25 , 0x10 ; ������ ��� ����� ������ ��� ������������� (PC4: 1 2 3 A)
	rcall scan_row_sim
	swap r24 ; ���������� �� ����������
	mov r27, r24 ; ��� 4 msb ��� r27
	ldi r25 ,0x20 ; ������ �� ������� ������ ��� ������������� (PC5: 4 5 6 B)
	rcall scan_row_sim
	add r27, r24 ; ���������� �� ���������� ��� 4 lsb ��� r27
	ldi r25 , 0x40 ; ������ ��� ����� ������ ��� ������������� (PC6: 7 8 9 C)
	rcall scan_row_sim
	swap r24 ; ���������� �� ����������
	mov r26, r24 ; ��� 4 msb ��� r26
	ldi r25 ,0x80 ; ������ ��� ������� ������ ��� ������������� (PC7: * 0 # D)
	rcall scan_row_sim
	add r26, r24 ; ���������� �� ���������� ��� 4 lsb ��� r26
	movw r24, r26 ; �������� �� ���������� ����� ����������� r25:r24
	clr r26 ; ���������� ��� ��� ������������� ��������
	out PORTC,r26 ; ���������� ��� ��� ������������� ��������
	pop r27 ; ��������� ���� ����������� r27:r26
	pop r26
	ret

	scan_keypad_rising_edge_sim:
	push r22 ; ���������� ���� ����������� r23:r22 ��� ����
	push r23 ; r26:r27 ����� ���� ��������� ���� ���� �������
	push r26
	push r27
	rcall scan_keypad_sim ; ������ �� ������������ ��� ���������� ���������
	push r24 ; ��� ���������� �� ����������
	push r25
	ldi r24 ,15 ; ����������� 15 ms (������� ����� 10-20 msec ��� ����������� ��� ���
	ldi r25 ,0 ; ������������ ��� ������������� � ������������� ������������)
	rcall wait_msec
	rcall scan_keypad_sim ; ������ �� ������������ ���� ��� ��������
	pop r23 ; ��� ������� ���������� �����������
	pop r22
	and r24 ,r22
	and r25 ,r23
	ldi r26 ,low(_tmp_) ; ������� ��� ��������� ��� ��������� ����
	ldi r27 ,high(_tmp_) ; ����������� ����� ��� �������� ����� r27:r26
	ld r23 ,X+
	ld r22 ,X
	st X ,r24 ; ���������� ��� RAM �� ��� ���������
	st -X ,r25 ; ��� ���������
	com r23
	com r22 ; ���� ���� ��������� ��� ����� ������ �������
	and r24 ,r22
	and r25 ,r23
	pop r27 ; ��������� ���� ����������� r27:r26
	pop r26 ; ��� r23:r22
	pop r23
	pop r22
	ret 

	keypad_to_ascii_sim:
	push r26 ; ���������� ���� ����������� r27:r26 ����� ����
	push r27 ; ��������� ���� ��� �������
	movw r26 ,r24 ; ������ �1� ���� ������ ��� ���������� r26 ��������
	; �� �������� ������� ��� ��������
	ldi r24 ,'*'
	; r26
	;C 9 8 7 D # 0 *
	sbrc r26 ,0
	rjmp return_ascii
	ldi r24 ,'0'
	sbrc r26 ,1
	rjmp return_ascii
	ldi r24 ,'#'
	sbrc r26 ,2
	rjmp return_ascii
	ldi r24 ,'D'
	sbrc r26 ,3 ; �� ��� ����� �1������������ ��� ret, ������ (�� ����� �1�)
	rjmp return_ascii ; ���������� �� ��� ���������� r24 ��� ASCII ���� ��� D.
	ldi r24 ,'7'
	sbrc r26 ,4
	rjmp return_ascii
	ldi r24 ,'8'
	sbrc r26 ,5
	rjmp return_ascii
	ldi r24 ,'9'
	sbrc r26 ,6
	rjmp return_ascii ;
	ldi r24 ,'C'
	sbrc r26 ,7
	rjmp return_ascii
	ldi r24 ,'4' ; ������ �1� ���� ������ ��� ���������� r27 ��������
	sbrc r27 ,0 ; �� �������� ������� ��� ��������
	rjmp return_ascii
	ldi r24 ,'5'
	;r27
	;� 3 2 1 B 6 5 4
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
	rjmp return_ascii ;
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
	pop r27 ; ��������� ���� ����������� r27:r26
	pop r26
	ret 

	write_2_nibbles_sim:
	push r24 ; ����� ������ ��� ����������� ��� �� �����
	push r25 ; ���������� ��� ������������ ��������������
	ldi r24 ,low(6000) ; ���������
ldi r25 ,high(6000)
	rcall wait_usec
	pop r25
	pop r24 ; ����� ����� ������
	push r24 ; ������� �� 4 MSB
	in r25, PIND ; ����������� �� 4 LSB ��� �� �������������
	andi r25, 0x0f ; ��� �� ��� ��������� ��� ����� ����������� ���������
	andi r24, 0xf0 ; ������������� �� 4 MSB ���
	add r24, r25 ; ������������ �� �� ������������ 4 LSB
	out PORTD, r24 ; ��� �������� ���� �����
	sbi PORTD, PD3 ; ������������� ������ Enable ���� ��������� PD3
	cbi PORTD, PD3 ; PD3=1 ��� ���� PD3=0
	push r24 ; ����� ������ ��� ����������� ��� �� �����
	push r25 ; ���������� ��� ������������ ��������������
	ldi r24 ,low(6000) ; ���������
ldi r25 ,high(6000)
	rcall wait_usec
	pop r25
	pop r24 ; ����� ����� ������
	pop r24 ; ������� �� 4 LSB. ��������� �� byte.
	swap r24 ; ������������� �� 4 MSB �� �� 4 LSB
	andi r24 ,0xf0 ; ��� �� ��� ����� ���� �������������
	add r24, r25
	out PORTD, r24
	sbi PORTD, PD3 ; ���� ������ Enable
	cbi PORTD, PD3
	ret

	lcd_data_sim:
	push r24
	push r25
	sbi PORTD,PD2
	rcall write_2_nibbles_sim
	ldi r24,43
	ldi r25,0
	rcall wait_usec
	pop r25
	pop r24
	ret

	lcd_command_sim:
	push r24 ; ���������� ���� ����������� r25:r24 ����� ����
	push r25 ; ��������� ���� ��� �������
	cbi PORTD, PD2 ; ������� ��� ���������� ������� (PD2=0)
	rcall write_2_nibbles_sim ; �������� ��� ������� ��� ������� 39�sec
	ldi r24, 39 ; ��� ��� ���������� ��� ��������� ��� ��� ��� ������� ��� lcd.
	ldi r25, 0 ; ���.: �������� ��� �������, �� clear display ��� return home,
	rcall wait_usec ; ��� �������� ��������� ���������� ������� ��������.
	pop r25 ; ��������� ���� ����������� r25:r24
	pop r24
	ret 

	lcd_init_sim:
	push r24 ; ���������� ���� ����������� r25:r24 ����� ����
	push r25 ; ��������� ���� ��� �������

	ldi r24, 40 ; ���� � �������� ��� lcd ������������� ��
	ldi r25, 0 ; ����� ������� ��� ���� ��� ������������.
	rcall wait_msec ; ������� 40 msec ����� ���� �� �����������.
	ldi r24, 0x30 ; ������ ��������� �� 8 bit mode
	out PORTD, r24 ; ������ ��� �������� �� ������� �������
	sbi PORTD, PD3 ; ��� �� ���������� ������� ��� �������
	cbi PORTD, PD3 ; ��� ������, � ������ ������������ ��� �����
	ldi r24, 39
	ldi r25, 0 ; ��� � �������� ��� ������ ��������� �� 8-bit mode
	rcall wait_usec ; ��� �� ������ ������, ���� �� � �������� ���� ����������
	; ������� 4 bit �� ������� �� ���������� 8 bit
	push r24 ; ����� ������ ��� ����������� ��� �� �����
	push r25 ; ���������� ��� ������������ ��������������
	ldi r24,low(1000) ; ���������
ldi r25,high(1000)
	rcall wait_usec
	pop r25
	pop r24 ; ����� ����� ������
	ldi r24, 0x30
	out PORTD, r24
	sbi PORTD, PD3
	cbi PORTD, PD3
	ldi r24,39
	ldi r25,0
	rcall wait_usec 
	push r24 ; ����� ������ ��� ����������� ��� �� �����
	push r25 ; ���������� ��� ������������ ��������������
	ldi r24 ,low(1000) ; ���������
ldi r25 ,high(1000)
	rcall wait_usec
	pop r25
	pop r24 ; ����� ����� ������
	ldi r24,0x20 ; ������ �� 4-bit mode
	out PORTD, r24
	sbi PORTD, PD3
	cbi PORTD, PD3
	ldi r24,39
	ldi r25,0
	rcall wait_usec
	push r24 ; ����� ������ ��� ����������� ��� �� �����
	push r25 ; ���������� ��� ������������ ��������������
	ldi r24 ,low(1000) ; ���������
ldi r25 ,high(1000)
	rcall wait_usec
	pop r25
	pop r24 ; ����� ����� ������
	ldi r24,0x28 ; ������� ���������� �������� 5x8 ��������
	rcall lcd_command_sim ; ��� �������� ��� ������� ���� �����
	ldi r24,0x0c ; ������������ ��� ������, �������� ��� �������
	rcall lcd_command_sim
	ldi r24,0x01 ; ���������� ��� ������
	rcall lcd_command_sim
	ldi r24, low(1530)
ldi r25, high(1530)
	rcall wait_usec
	ldi r24 ,0x06 ; ������������ ��������� ������� ���� 1 ��� ����������
	rcall lcd_command_sim ; ��� ����� ������������ ���� ������� ����������� ���
	; �������������� ��� ��������� ��������� ��� ������
	pop r25 ;
	pop r24
	ret
;=======new
ADC_init:
 ldi r24,(1<<REFS0) ; Vref: Vcc
 out ADMUX,r24      ;MUX4:0 = 00000 for A0.
 ;ADC is Enabled (ADEN=1)
 ;ADC Interrupts are Enabled (ADIE=1)
 ;Set Prescaler CK/128 = 62.5Khz (ADPS2:0=111)
 ldi r24,(1<<ADEN)|(1<<ADIE)|(1<<ADPS2)|(1<<ADPS1)|(1<<ADPS0)
 out ADCSRA,r24
 ret
;=========
 CLEARLCD: ; ektiposi clear
		push r24
		push r25
		clr r24
		clr r25
		rcall lcd_init_sim
		ldi r24, 'C'
		rcall lcd_data_sim
		ldi r24, 'L'
		rcall lcd_data_sim
		ldi r24, 'E'
		rcall lcd_data_sim
		ldi r24, 'A'
		rcall lcd_data_sim
		ldi r24, 'R'
		rcall lcd_data_sim
		pop r25
		pop r24
		ret

GASLCD: ; ektiposi gas
		push r24
        push r25
        clr r24
        clr r25
		rcall lcd_init_sim
		ldi r24, 'G'
		rcall lcd_data_sim
		ldi r24, 'A'
		rcall lcd_data_sim
		ldi r24, 'S'
		rcall lcd_data_sim
		ldi r24, ' '
		rcall lcd_data_sim
		ldi r24, 'D'
		rcall lcd_data_sim
		ldi r24, 'E'
		rcall lcd_data_sim
		ldi r24, 'T'
		rcall lcd_data_sim
		ldi r24, 'E'
		rcall lcd_data_sim
		ldi r24, 'C'
		rcall lcd_data_sim
		ldi r24, 'T'
		rcall lcd_data_sim
		ldi r24, 'E'
		rcall lcd_data_sim
		ldi r24, 'D'
		rcall lcd_data_sim
		pop r25
		pop r24
		ret
;================
ISR_TIMER1_OVF:
		push r24
		in r24,ADCSRA
		ori r24,(1<<ADSC)
		out ADCSRA,r24
		ldi r24,0xfc
		out TCNT1H,r24
		ldi r24,0xf3
		out TCNT1L,r24
		pop r24
		reti

ADC_ISR:
        push r24
		push r25
		push temp
        push temp1

        clr temp
        clr temp1

        mov temp1,flag3
        in r24,ADCL
		in r25,ADCH

        cpi flag,0x00 ; elegxos welcome 
        breq level7
		ser flag3
        ldi temp,0x80
        rjmp end1

; M = 129 * 100 * 10^-6 = 129 * 10^4
; Cx = 10^4/129(Vgas - 0.1) = 77.5(ADC/204.8 - 0.1) -> ADC = 204.8(Cx/77.5 - 0.1)
level7: cpi r25,0x00 ; elegxos an einai megalyteros tou 90 ppm
		breq level6
        cpi flag2,0x00 ; gia na anavosvinei
        brne offpb
        ldi temp,0x7F
        ser flag2
        ldi flag3,0x01
        rjmp prnt

offpb: ldi temp,0x00 ; to svisimo
        clr flag2
        ldi flag3,0x01
        rjmp prnt

level6: cpi r24,0xE6 ;elegxos gia 80<=ppm<=90
		brlo level5
        cpi flag2,0x00
        brne offpb
        ldi temp,0x3F
        ser flag2
        ldi flag3,0x01
        rjmp prnt

level5: cpi r24,0xCD ;elegxos gia 70<=ppm<80
		brlo level4
        cpi flag2,0x00
        brne offpb
        ldi temp,0x1F
        ser flag2
        ldi flag3,0x01
        rjmp prnt

level4: cpi r24,0xB3 ;elegxos gia 60<=ppm<70
		brlo level3
        ldi temp,0x0F
        clr flag3
        rjmp prnt

level3: cpi r24,0x7E ;elegxos gia 40<=ppm<60
		brlo level2
        ldi temp,0x07
        clr flag3
        rjmp prnt

level2: cpi r24,0x49 ;elegxos gia 20<=ppm<40
		brlo level1
        ldi temp,0x03
        clr flag3
        rjmp prnt

level1: ldi temp,0x01 ; 0 <= ppm < 20
        clr flag3
    
prnt:   cp temp1,flag3
        breq end2
        cpi flag3,0x00
        breq cllcd
        rcall GASLCD
        rjmp end2
cllcd:  rcall CLEARLCD
end2:   cpi flag1,0x00  ; elegxos gia lathos kwdiko
        breq end1
        ori temp,0x80 
end1:   out PORTB,temp
        pop temp1
        pop temp
        pop r25
        pop r24
        reti
;========
wait_msec:
	push r24				; 2 ������ (0.250 �sec)
	push r25				; 2 ������
	ldi r24 , low(998)		; ������� ��� �����. r25:r24 �� 998 (1 ������ - 0.125 �sec)
	ldi r25 , high(998)		; 1 ������ (0.125 �sec)
	rcall wait_usec			; 3 ������ (0.375 �sec), �������� �������� ����������� 998.375 �sec
	pop r25					; 2 ������ (0.250 �sec)
	pop r24					; 2 ������
	sbiw r24 , 1			; 2 ������
	brne wait_msec			
	ret						




wait_usec:
	sbiw r24 ,1			
	nop				
	nop					
	nop					
	nop					
	brne wait_usec		
	ret					


	