#!/usr/bin/env python
# Serial to file. (el cheapo with a breeze of ugly)

import serial # pyserial needed
import string

def main():
    sin=serial.Serial("/dev/ttyUSB0",9600)
    fo = open("log.csv", "w")

    try:
        while True:
            line = sin.readline()
            print line
            fo.write(line + "\n");
                
    except KeyboardInterrupt:
        fo.close()
        return 0;

if __name__ == "__main__":
    main()
