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

void dumpCard(bool);
void pulse(uint8_t);

void
help(void) {
	Serial.println("a - dump card and print ASCII chars if possible");
	Serial.println("d - dump card in HEX");
} // help

void
setup() {
	Serial.begin(9600);

	pinMode(pin_STAT, OUTPUT);
	pinMode(pin_RST, OUTPUT);
	pinMode(pin_CLK, OUTPUT);
	pinMode(pin_IO, INPUT_PULLUP);
	help();
} // setup

void
loop() {
	uint8_t cmd;

	Serial.print("cmd> ");
	digitalWrite(pin_STAT, LOW);

	while (true) {
		while (!Serial.available()) delay(100);
		cmd = Serial.read();
		if ((cmd != '\n') && (cmd != '\r'))
			break;
	}
	Serial.write(cmd);
	Serial.println("");

	switch (cmd) {
		case 'a':
			dumpCard(false);
			break;
		case 'd':
			dumpCard(true);
			break;
		case '\n':
			break;
		default:
			help();
	}
} // loop

// generate CLK pulse (use interrupt?) 
void
pulse(uint8_t pin) {
	digitalWrite(pin, LOW);
	delay(1);
	digitalWrite(pin, HIGH);
	delay(1);
	digitalWrite(pin, LOW);
} // pulse

// read card and write output to serial console
void
dumpCard(bool printHex) {
	digitalWrite(pin_RST, HIGH);
	pulse(pin_CLK);
	digitalWrite(pin_RST, LOW);

	for(uint16_t addr = 0; addr < (READ_BITS / 8); addr++) {
		uint8_t data = shiftIn(pin_IO, pin_CLK, LSBFIRST);
		if (addr % BLINK_BYTES == 0)   // blink led every BLINK_BYTES bytes
			digitalWrite(pin_STAT, !digitalRead(pin_STAT));
		if (addr % 16 == 0) {
			Serial.print("\r\n0x");
			if (addr < 0x10)
				Serial.print("0");
			if (addr < 0x100)
				Serial.print("0");
			Serial.print(addr, HEX);
			Serial.print("  ");
		}
		if (((data < 0x20) || (data >= 0x7e)) || printHex) {
			 if (data < 0x10)
				Serial.print("0");
			Serial.print(data, HEX);
		} else {
			Serial.print(".");
			Serial.write(data);
		}
		Serial.print(" ");
		if (Serial.available()) {
			(void) Serial.read();
			break;
		}
	} // loop for # of bits to be read from the chard
	Serial.println("");
} // dumpCard

void __cxa_pure_virtual (void) {
  while(1);
} __cxa_pure_virtual
