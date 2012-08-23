/*
	Hardware layout:
	Pin | Name | Name | Pin
	----+------+------+----
	5V  | VCC  | GND  | GND
	8   | RST  | NC   | NC
	2   | CLK  | I/O  | 10
*/

#define READ_BITS 8192
#define BLINK_BYTES 4

uint8_t pin_RST = 8;
uint8_t pin_CLK = 2;
uint8_t pin_IO  = 10;
uint8_t pin_STAT = 13;

void dumpCard(void);
void pulse(uint8_t);

bool printHex = true;

void
setup() {
	Serial.begin(9600);

	pinMode(pin_STAT, OUTPUT);
	pinMode(pin_RST, OUTPUT);
	pinMode(pin_CLK, OUTPUT);
	pinMode(pin_IO, INPUT_PULLUP);
}

void
loop() {
	Serial.println("\r\na - dump card and print ASCII chars if possible");
	Serial.println("  - dump card in HEX");
	Serial.print("cmd> ");
	digitalWrite(pin_STAT, HIGH);

	while (!Serial.available()) delay(100);
	char cmd = Serial.read();
	if (cmd != '\n')
		Serial.println(cmd);
	else
		Serial.println("");

	switch (cmd) {
		case 'a':
			printHex = false;
			break;
		default:
			printHex = true;
	}

	digitalWrite(pin_STAT, LOW);
	dumpCard();
}

void
pulse(uint8_t pin) {
	digitalWrite(pin, LOW);
	delay(1);
	digitalWrite(pin, HIGH);
	delay(1);
	digitalWrite(pin, LOW);
}

void
dumpCard(void) {
	digitalWrite(pin_RST, HIGH);
	pulse(pin_CLK);
	digitalWrite(pin_RST, LOW);

	uint8_t data[READ_BITS / 8];
	memset(data, 0x00, READ_BITS / 8);

	for(uint16_t bit = 0; bit < READ_BITS; bit++) {
		data[bit / 8] |= ((digitalRead(pin_IO) == HIGH) << (bit % 8));
		pulse(pin_CLK);
		if (bit % (BLINK_BYTES * 8) == 0)
			digitalWrite(pin_STAT, !digitalRead(pin_STAT));
	}

	for(uint16_t byte = 0; byte < READ_BITS / 8; byte++) {
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
		} else {
			Serial.print(".");
			Serial.write(data[byte]);
		}
		Serial.print(" ");
	}
	Serial.println("");
}

void __cxa_pure_virtual (void) {
  while(1);
}
