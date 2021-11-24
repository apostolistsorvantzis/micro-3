#define F_CPU 8000000
#include <avr/io.h>
#include <util/delay.h>

unsigned char rkey[4],prev[4];

int scan_keypad_rising_edge_sim();

void found(){ //an vrei ton swsto arithmo anavoun ola ta fotakia gia 4 sec
	PORTB =0xFF;
	for (int i=0;i<30;i++) scan_keypad_rising_edge_sim();
	PORTB=0x00;
}

void notfound(){ // an patithoun lathos
	for (int i=0;i<4;i++){
		PORTB=0xFF;
		for (int j=0;j<4;j++) scan_keypad_rising_edge_sim();
		PORTB=0x00;
		for (int j=0;j<4;j++) scan_keypad_rising_edge_sim();
	}
}
unsigned char scan_row_sim(int r){ // pairnei ws eisodo tin seira r pou tha elegxei
	unsigned char x = (1 << r); // vazoume ton antistoixo 1 gia tin grammi pou einai na diavasoume
	PORTC = x;  // sto portc
	_delay_ms(15); //na prolavei na allajei katastasi kai gia logous xrisis prosomioti
	return PINC& 0x0F; // gyrna to apotelesma

}

unsigned char swap(unsigned char a){ // allazei ta 4 msb me ta 4 lsb
	a = ((a & 0x0F) << 4 | (a & 0xF0) >> 4);
	return a;
}
void scan_keypad_sim(){
	for (int i=0;i<4;i++)
	rkey[i] = scan_row_sim(i+4); // elegxoume kai tis 4 seires kai apothikeuoume ta apotelesmata
	PORTC =0x00;
}

int scan_keypad_rising_edge_sim(){
	unsigned char a[4]; // gia na kratisoume to prwto scan
	int f=0;
	scan_keypad_sim();
	for (int i=0;i<4;i++)a[i] = rkey[i];
	_delay_ms(15); // gia spintirismo
	scan_keypad_sim();
	for (int i=0;i<4;i++) {  // apothikeuoume to neo sto prev gia to epomeno scan kai elgxoume gia kapoio patima
		rkey[i] &= a[i];
		a[i] = prev[i];
		prev[i] =rkey[i];
		rkey[i] &= ~a[i];
		if(rkey[i]) f=1;
	}
	return f;
}
// rkey[0] = 0000A321 rkey[1] = 0000B654 rkey[2] = 0000C987 rkey[3] = *0#D
unsigned char keypad_to_ascii(){
	if (rkey[0] & 0x01) // an exoume asso sto rkey[0] sto lsb tote antistoixei sto 1
	return '1';
	if (rkey[0] & 0x02)
	return '2';
	if (rkey[0] & 0x04)
	return '3';
	if (rkey[0] & 0x08)
	return 'A';

	if (rkey[1] & 0x01)
	return '4';
	if (rkey[1] & 0x02)
	return '5';
	if (rkey[1] & 0x04)
	return '6';
	if (rkey[1] & 0x08)
	return 'B';

	if (rkey[2] & 0x01)
	return '7';
	if (rkey[2] & 0x02)
	return '8';
	if (rkey[2] & 0x04)
	return '9';
	if (rkey[2] & 0x08)
	return 'C';

	if (rkey[3] & 0x01)
	return '*';
	if (rkey[3] & 0x02)
	return '0';
	if (rkey[3] & 0x04)
	return '#';
	if (rkey[3] & 0x08)
	return 'D';
	
	return 0;
}

int main(void){
	DDRB = 0xFF; // thetoume to b ws ejodo
	DDRC = (1 << PC7) | (1 << PC6) | (1 << PC5) | (1 << PC4); //thetoume ws ejodo ta msb kai eisodo to lsb
	for (int i=0;i<4;i++)prev[i]=0; // arxikopoiisi tis "ram"
	while(1){
		unsigned char a,b;
		while(!scan_keypad_rising_edge_sim()){ //diavazei to 1o pliktro
		}
		a=keypad_to_ascii();
		while(!scan_keypad_rising_edge_sim()){// diavazei to 2o pliktro
		}
		b=keypad_to_ascii();
		if(a=='3' && b =='5') found(); // elegxos gia swsto "pin"
		else notfound();

	}
}


