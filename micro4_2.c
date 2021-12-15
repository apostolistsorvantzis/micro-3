#include <avr/io.h>
#define F_CPU 8000000UL		
#include <util/delay.h>
#include <avr/interrupt.h>


volatile char _tmp_ = 0x02;	// h ram pou kratame tin prohgoumenh katastash
volatile char read1 = 0;  //
volatile char output = 0; // edw tha krataw to periexomenw tvn PDleds
volatile char correct = 0; // kratame an mphke swstos o kwdikos
volatile char flag1 = 0; //
volatile char flag2 = 0; // flag pou dinoume 1 otan vazoume kwdiko
volatile char flag = 0; //


// KEYPAD DRIVERS =======================================================================
char scan_row(char line) {
	PORTC = line;
	_delay_us(500);
	char out = PINC & 0x0F;
	return out;
}

int scan_keypad() {
	char line1 = scan_row(0x10);			// scan for: 1 2 3 A
	line1 = line1 << 4;						// 4 MSBs
	char line2 = scan_row(0x20);			// scan for: 4 5 6 B
	unsigned char high = line1 | line2;		// 4 bits for line1 and 4 for line2
	char line3 = scan_row(0x40);			// scan for: 7 8 9 C
	line3 = line3 << 4;						// 4 MSBs
	char line4 = scan_row(0x80);			// scan for: * 0 # D
	unsigned char low = line3 | line4;		// 4 bits for line3 and 4 for line4
	unsigned int out = (high << 8) | low;	// 16-bit number
	PORTC = 0x00;
	return out;
}

int scan_keypad_rising_edge() {
	int keypad_first = scan_keypad();
	_delay_us(15);
	int keypad_second = scan_keypad();
	int keypad_debounced = keypad_first & keypad_second;
	int previous = ~_tmp_;			// load previous state from RAM
	_tmp_ = keypad_debounced;		// store current state in RAM
	keypad_debounced &= previous;	// filter
	return keypad_debounced;
}

char keypad_to_ascii(int input) {
	switch(input) {
		case (1 << 0):
		return '*';
		case (1 << 1):
		return '0';
		case (1 << 2):
		return '#';
		case (1 << 3):
		return 'D';
		case (1 << 4):
		return '7';
		case (1 << 5):
		return '8';
		case (1 << 6):
		return '9';
		case (1 << 7):
		return 'C';
		case (1 << 8):
		return '4';
		case (1 << 9):
		return '5';
		case (1 << 10):
		return '6';
		case (1 << 11):
		return 'B';
		case (1 << 12):
		return '1';
		case (1 << 13):
		return '2';
		case (1 << 14):
		return '3';
		case (1 << 15):
		return 'A';
	}
	return 0;
}

char read_keypad() {
	int input = 0;
	while (input == 0)
		input = scan_keypad_rising_edge();
	return keypad_to_ascii(input);
}

//     New Code

char levels (int x) {
	int res = x/100;	// 1023/7 = 146
	switch (res) {
		case 0:
		return 0x01;
		case 1:
		return 0x03;
		case 2:
		return 0x07;
		case 3:
		return 0x0F;
		case 4:
		return 0x1F; 
		case 5:
		return 0x3F;
		case 6:
		return 0x7F;
	}
	return 0;
}

void decode_input() {
	int temp = ADC; //70 p
	flag1 = (temp > 205);	// 70 ppm
	read1 = levels(temp);
	output = (output & 0b10000000) | read1;
}

ISR(TIMER1_OVF_vect) {
	flag = ~flag;
	// 65536 - 0.1*7812.5 = 64754
	TCNT1 = 64754;
	if (correct)
		scan_keypad_rising_edge();
	ADCSRA |= (1 << ADSC);// steloume sima gia diavasma apo aisthitira
}

ISR(ADC_vect) {
	decode_input();
	if (flag2){
        return;
    }
	if (flag1 && flag) {
		output &= 0b10000000;	// flip sensor display bits
		PORTB = output;
		return;
	}
	output = (output & 0b10000000) | read1;
	PORTB = output;		// else just display sensor reading in PB6:0
}

void alarmon() {
	for (int i = 0; i < 4; i++) {
		output =  output | (1 << PB7); // on to PB7 ledaki mazi me tin endeiji
		PORTB = output; 
		_delay_ms(500); 
		output =  output & 0b01111111; // midenizw to PB7 gia na anavosvinei
		PORTB = output;
		_delay_ms(500);
	}
}

int main(void) {
	DDRB = 0xFF;			// output ledakia portb
    DDRC = 0xF0;			// pliktrologio
	DDRA = 0x00;			// aisthitiras

	ADMUX = (1 << REFS0);	// ADC
	ADCSRA = (1 << ADEN) | (1 << ADIE) | (1 << ADPS2) | (1 << ADPS1) | (1 << ADPS0);
	
	TIMSK = (1 << TOIE1);	// arxikopoiisi xronisti
	TCCR1B = (1 << CS12) | (0 << CS11) | (1 << CS10); 
    // 65536 - 0.1*7812.5 = 65754
	TCNT1 = 64754;		// vazoume ton timer sta 100ms
	
	sei();		// enable interrupts

	while (1) {
		flag2 = 0; // flag2 = flag gia swsto kwdiko
		char num1 = read_keypad(); // diavase to prwto pliktro
		if (num1 == '0') {		
			char num2 = read_keypad(); // diavase to deutero
			correct = 1;
			if (num2 == '7') {	
				flag2 = 1; // flag gia anapsoume katallhla lampakia
				output =  0b10000000; //vazoume sta ledakia to prwto na anavei
				PORTB = output;
				_delay_ms(4000); 
				output = 0;	// svise ta ledakia
				PORTB = output;
			}
			else {
				alarmon();  // lathos kwdikos
			}
		}
		else {	// lathos to prwto pliktro
			read_keypad(); // diavazoume to deutero
			correct = 0xFF;
			alarmon(); // 
		}
	}
}
