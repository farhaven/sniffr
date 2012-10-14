#!/usr/bin/env python
# Serial to csv. (el cheapo with a breeze of ugly)

import serial # pyserial needed
import string

import sys
sys.path.append('/usr/share/pyshared')

test=serial.Serial("/dev/ttyUSB0",9600)
fo = open("log.csv", "w")

try:
    while True:
        line = test.readline(eol='\r')
        fo.write(line[0] + "," + line[1] + "\n");
                
except KeyboardInterrupt:
    pass # do cleanup here

fo.close()
