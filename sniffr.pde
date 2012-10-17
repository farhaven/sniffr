/*
	Hardware layout:
	Pin | Name | Name | Pin
	----+------+------+----
	5V  | VCC  | GND  | GND
	8   | RST  | NC   | NC
	2   | CLK  | I/O  | 10
*/


#define READ_BITS 8192      // bits on card to be read
#define BLINK_BYTES 4       // led blink speed

// Card <==> Arduino pinning
uint8_t pin_RST = 8;
uint8_t pin_CLK = 2;
uint8_t pin_IO  = 10;
uint8_t pin_STAT = 13;      // debug LED 

void dumpCard(void);
void pulse(uint8_t);

bool printHex = true;

void
help(void) {
	Serial.println("a - dump card and print ASCII chars if possible");
	Serial.println("d - dump card in HEX");
}

void
setup() {
	Serial.begin(9600);

	pinMode(pin_STAT, OUTPUT);
	pinMode(pin_RST, OUTPUT);
	pinMode(pin_CLK, OUTPUT);
	pinMode(pin_IO, INPUT_PULLUP);
} //setup

// ask if card dump should be printed in ASCII or HEX
void
loop() {
	Serial.print("cmd> ");
	digitalWrite(pin_STAT, LOW);

	while (!Serial.available()) delay(100);
	char cmd = Serial.read();
	if (cmd != '\n')
		Serial.println(cmd);
	else
		Serial.println("");

	switch (cmd) {
		case 'a':
			printHex = false;
			/* fallthrough */
		case 'd':
			dumpCard();
			break;
		case '\n':
			break;
		default:
			help();
	}
} //loop

// generate CLK pulse (use interrupt?) 
void
pulse(uint8_t pin) {
	digitalWrite(pin, LOW);
	delay(1);
	digitalWrite(pin, HIGH);
	delay(1);
	digitalWrite(pin, LOW);
} //pulse

// read card and write output to serial console
void
dumpCard(void) {
	digitalWrite(pin_RST, HIGH);
	pulse(pin_CLK);
	digitalWrite(pin_RST, LOW);

    // (READ_BITS / 8 because: uint8_t foo[n] reserves n bytes not bit)
	uint8_t data[READ_BITS / 8];        // allocate memory for card dump 
	memset(data, 0x00, READ_BITS / 8);  // write 0x00 in every byte of the allocated memory

    // read card
	for(uint16_t bit = 0; bit < READ_BITS; bit++) {
		uint16_t byte = bit / 8;
		data[byte] |= ((digitalRead(pin_IO) == HIGH) << (bit % 8)); // read bit
		pulse(pin_CLK);                     // pulse clock every bit
		if (bit % (BLINK_BYTES * 8) == 0)   // blink led every BLINK_BYTES bytes
			digitalWrite(pin_STAT, !digitalRead(pin_STAT));
		if (bit % 8 == 7) {
			if (byte % 16 == 0) {
				Serial.print("\r\n0x");
				if (byte < 0x10)
					Serial.print("0");
				if (byte < 0x100)
					Serial.print("0");
				Serial.print(byte, HEX);
				Serial.print("  ");
			}
			if (((data[byte] < 0x20) || (data[byte] >= 0x7e)) || printHex) {
				 if (data[byte] < 0x10)
					Serial.print("0");
				Serial.print(data[byte], HEX);
			  // else: print byte as ASCII char
			} else {
				Serial.print(".");
				Serial.write(data[byte]);
			}
			Serial.print(" ");
		}
	} // loop for # of bits to be read from the chard
	Serial.println("");
} //dumpCard

// Bugfix for arduino libc
void __cxa_pure_virtual (void) {
  while(1);
} //__cxa_pure_virtual
