/*
	Hardware layout:
	Pin | Name | Name | Pin
	----+------+------+----
	NC  | VCC  | GND  | GND
	8   | RST  | NC   | NC
	2   | CLK  | I/O  | 10
*/

// Card <==> Arduino pinning
uint8_t pin_RST = 8;
uint8_t pin_CLK = 2;
uint8_t pin_IO  = 10;

void cardReset(void);
void vomit(void);

void
setup() {
	Serial.begin(9600);

	pinMode(pin_RST, INPUT_PULLUP);
	pinMode(pin_CLK, INPUT_PULLUP);
	pinMode(pin_IO, INPUT_PULLUP);

    cardReset();
} //setup

void
loop() {
	vomit();
} //loop


void //wait for reset to finish
cardReset(void) {
    while(digitalRead(pin_RST) == LOW); 
    while(digitalRead(pin_CLK) == LOW); 
    while(digitalRead(pin_CLK) == HIGH); 
    while(digitalRead(pin_RST) == HIGH); 
} //cardReset

void // print the RST and IO state each Clock pulse to serial consol
vomit(void) {
    while(digitalRead(pin_CLK) == LOW);

    if(digitalRead(pin_RST) == LOW){
        Serial.print("0");   
    }
    else {
        Serial.print("1");
    }

    if(digitalRead(pin_IO) == LOW){
        Serial.print("0");   
    }
    else {
        Serial.print("1");
    }

    Serial.println();

    while(digitalRead(pin_CLK) == HIGH);
} //vomit

// Bugfix for arduino libc
void __cxa_pure_virtual (void) {
    while(1);
} //__cxa_pure_virtual
