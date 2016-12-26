#!/usr/bin/env python

import sys
import time
import serial

if len(sys.argv) < 3:
       print 'Usage: ' + sys.argv[0] + ' <recipient> <message>';
       exit();

print 'Sending "' + sys.argv[2] + '" to ' + sys.argv[1];

modem = serial.Serial(
               port='/dev/ttyUSB0',
               baudrate = 9600,
               parity=serial.PARITY_NONE,
               stopbits=serial.STOPBITS_ONE,
               bytesize=serial.EIGHTBITS,
               timeout=1
)

try:
        # Initialize
        modem.write('AT\r');
        response = modem.readall();
        if "OK" not in response:
                print 'AT did not return OK';
                exit();

        # Set modem in TEXT mode
        modem.write('AT+CMGF=1\r');
        response = modem.readall();
        if "OK" not in response:
                print 'AT+CMGF=1 did not return OK';
                exit();

        # Set recipient phone number
        modem.write('AT+CMGS="' + sys.argv[1] + '"\r');
        response = modem.readall();
        if ">" not in response:
                print 'AT+CMGS=x did not return a prompt';
                exit();

        # Sending the text
        modem.write(sys.argv[2]);
        modem.write(chr(26));
        time.sleep(1);
finally:

        modem.close();

print 'SMS should have been sent now...';
