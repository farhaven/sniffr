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
uint8_t pin_STAT = 13;	  // debug LED

void cardWaitReset(void);
void vomit(void);

enum direction_t {
	IN, OUT
};

enum state_t {
	WAIT_BEGIN,
	WAIT_ADDR1, WAIT_ADDR2, WAIT_ADDR3,
	IGN_BYTE,
	WAIT_PIN1, WAIT_PIN2,
	WAIT_WRITE1, WAIT_WRITE2
} state = WAIT_BEGIN;

#define MAGIC_WRITE 143 /* magic for "write to anywhere with highest two bits set */

uint8_t psc[2] = {0, 0}; // 2-byte programmable security code
uint8_t data = 0;
uint8_t bit_count = 0;

void
setup() {
	Serial.begin(9600);

	pinMode(pin_STAT, OUTPUT);
	pinMode(pin_RST, INPUT_PULLUP);
	pinMode(pin_CLK, INPUT_PULLUP);
	pinMode(pin_IO, INPUT_PULLUP);

	Serial.println("setup() done, waiting for card reset");

	cardWaitReset();
} //setup

void
loop() {
	digitalWrite(pin_STAT, LOW);
	vomit();
	digitalWrite(pin_STAT, HIGH);
	Serial.println("Press any key to print psc to serial.");
	Serial.read();
	for (int i = 0; i < 2; i++) {
		Serial.print("0x");
		if (psc[i] < 0)
			Serial.print("0");
		Serial.print(psc[i], HEX);
		Serial.print(" ");
	}
	Serial.println("");
} //loop


void //wait for reset to finish
cardWaitReset(void) {
	while(digitalRead(pin_RST) == LOW);
	while(digitalRead(pin_CLK) == LOW);
	while(digitalRead(pin_CLK) == HIGH);
	while(digitalRead(pin_RST) == HIGH);
}

enum state_t
stateMachine(enum state_t current, uint8_t input) {
	switch (current) {
		case WAIT_BEGIN:
			if (input == MAGIC_WRITE)
				return WAIT_ADDR1;
			return WAIT_BEGIN;
		case WAIT_ADDR1:
			if (input == 253) /* lowest 8 bit of address 1021 */
				return IGN_BYTE;
			return WAIT_BEGIN;
		case IGN_BYTE:
			return WAIT_WRITE1;
		case WAIT_WRITE1:
			if (input == MAGIC_WRITE)
				return WAIT_ADDR2;
			return WAIT_BEGIN;
		case WAIT_ADDR2:
			if (input == 254) /* lowest 8 bit of address 1022 */
				return WAIT_PIN1;
			return WAIT_BEGIN;
		case WAIT_PIN1:
			psc[0] = input;
			return WAIT_WRITE2;
		case WAIT_WRITE2:
			if (input == MAGIC_WRITE)
				return WAIT_ADDR3;
			return WAIT_BEGIN;
		case WAIT_ADDR3:
			if (input == 255) /* lowest 8 bit of address 1023 */
				return WAIT_PIN2;
			return WAIT_BEGIN;
		case WAIT_PIN2:
			psc[1] = input;
		default:
			return WAIT_BEGIN;
	}
}

void // attempt to sniff out key bytes 1 and 2 from the communication between card and reader
vomit(void) {
	enum direction_t dir = IN;

	while(digitalRead(pin_CLK) == LOW);

	/* RST = 0 -> data output, RST = 1 -> command entry */
	if(digitalRead(pin_RST) == LOW)
		dir = OUT;


	Serial.print(" ");
	switch (dir) {
		case IN:
			Serial.print("in");
			break;
		default:
			Serial.print("out");
	}
	Serial.print(",");
	Serial.println(data);

	data = (data << 1) | (digitalRead(pin_IO) == HIGH);

	if (bit_count == 7) {
		state = stateMachine(state, data);
		data = 0;
	}

	bit_count = (bit_count + 1) % 8;

	if (dir == OUT)
		state = WAIT_BEGIN;
	while(digitalRead(pin_CLK) == HIGH);
} //vomit

// Bugfix for arduino libc
void __cxa_pure_virtual (void) {
	while(1);
} //__cxa_pure_virtual
