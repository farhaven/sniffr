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

uint8_t pin[2] = {0, 0};
uint8_t last_byte = 0;
uint8_t bit_count = 0;

void
setup() {
	Serial.begin(9600);

	pinMode(pin_RST, INPUT_PULLUP);
	pinMode(pin_CLK, INPUT_PULLUP);
	pinMode(pin_IO, INPUT_PULLUP);

	cardWaitReset();
	vomit();
} //setup

void
loop() {
	/* TODO: once vomit() is done, flash some light or the like to indicate being done */
	/* TODO: also, offer an option to dump the key bits to serial */
} //loop


void //wait for reset to finish
cardWaitReset(void) {
	while(digitalRead(pin_RST) == LOW);
	while(digitalRead(pin_CLK) == LOW);
	while(digitalRead(pin_CLK) == HIGH);
	while(digitalRead(pin_RST) == HIGH);
}

void // attempt to sniff out key bytes 1 and 2 from the communication between card and reader
vomit(void) {
	enum direction_t dir = IN;
	uint8_t data;

	while(digitalRead(pin_CLK) == LOW);

	/* RST = 0 -> data output, RST = 1 -> command entry */
	if(digitalRead(pin_RST) == LOW)
		dir = OUT;

	data = (digitalRead(pin_IO) == HIGH);

	switch (dir) {
		case IN:
			Serial.print("in");
			break;
		default:
			Serial.print("out");
	}
	Serial.print(",");
	Serial.println(data);

	last_byte = (last_byte << 1) | data;

	if (bit_count == 7) { /* complete byte read */
		switch (state) {
			case WAIT_BEGIN:
				if (last_byte == MAGIC_WRITE)
					state = WAIT_ADDR1;
				break;
			case WAIT_ADDR1:
				if (last_byte == 253) /* lowest 8 bit of address 1021 */
					state = IGN_BYTE;
				else
					state = WAIT_BEGIN;
				break;
			case IGN_BYTE:
				state = WAIT_WRITE1;
				break;
			case WAIT_WRITE1:
				if (last_byte == MAGIC_WRITE)
					state = WAIT_ADDR2;
				else
					state = WAIT_BEGIN;
				break;
			case WAIT_ADDR2:
				if (last_byte == 254) /* lowest 8 bit of address 1022 */
					state = WAIT_PIN1;
				else
					state = WAIT_BEGIN;
				break;
			case WAIT_PIN1:
				pin[0] = last_byte;
				state = WAIT_WRITE2;
				break;
			case WAIT_WRITE2:
				if (last_byte == MAGIC_WRITE)
					state = WAIT_ADDR3;
				else
					state = WAIT_BEGIN;
				break;
			case WAIT_ADDR3:
				if (last_byte == 255) /* lowest 8 bit of address 1023 */
					state = WAIT_PIN2;
				else
					state = WAIT_BEGIN;
				break;
			case WAIT_PIN2:
				pin[1] = last_byte;
			default:
				return;
		}
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
