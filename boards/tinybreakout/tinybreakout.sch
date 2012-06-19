EESchema Schematic File Version 2  date Mon 18 Jun 2012 09:23:16 PM EDT
LIBS:power
LIBS:device
LIBS:transistors
LIBS:conn
LIBS:linear
LIBS:regul
LIBS:74xx
LIBS:cmos4000
LIBS:adc-dac
LIBS:memory
LIBS:xilinx
LIBS:special
LIBS:microcontrollers
LIBS:dsp
LIBS:microchip
LIBS:analog_switches
LIBS:motorola
LIBS:texas
LIBS:intel
LIBS:audio
LIBS:interface
LIBS:digital-audio
LIBS:philips
LIBS:display
LIBS:cypress
LIBS:siliconi
LIBS:opto
LIBS:atmel
LIBS:contrib
LIBS:valves
LIBS:at42qt1012
LIBS:atmel2
LIBS:bc846a
LIBS:diy_connectors
LIBS:logo
LIBS:monomeArduino
LIBS:sn75176b
LIBS:SparkFun
LIBS:SparkFun_old
LIBS:usb-a-plug
LIBS:xo-14s
EELAYER 43  0
EELAYER END
$Descr A4 11693 8268
encoding utf-8
Sheet 1 1
Title ""
Date "19 jun 2012"
Rev ""
Comp ""
Comment1 ""
Comment2 ""
Comment3 ""
Comment4 ""
$EndDescr
$Comp
L ATTINY10-TS IC1
U 1 1 4FDFD3EF
P 5200 3600
F 0 "IC1" H 4300 4000 60  0000 C CNN
F 1 "ATTINY10-TS" H 5900 3200 60  0000 C CNN
F 2 "SOT23-6" H 4400 3200 60  0001 C CNN
	1    5200 3600
	-1   0    0    -1  
$EndComp
$Comp
L VCC #PWR?
U 1 1 4FDFD403
P 3900 3300
F 0 "#PWR?" H 3900 3400 30  0001 C CNN
F 1 "VCC" H 3900 3400 30  0000 C CNN
	1    3900 3300
	1    0    0    -1  
$EndComp
$Comp
L CONN_1 P5
U 1 1 4FDFD412
P 3650 3350
F 0 "P5" H 3730 3350 40  0000 L CNN
F 1 "CONN_1" H 3650 3405 30  0001 C CNN
	1    3650 3350
	-1   0    0    1   
$EndComp
$Comp
L CONN_1 P2
U 1 1 4FDFD41F
P 3650 3850
F 0 "P2" H 3730 3850 40  0000 L CNN
F 1 "CONN_1" H 3650 3905 30  0001 C CNN
	1    3650 3850
	-1   0    0    1   
$EndComp
$Comp
L GND #PWR?
U 1 1 4FDFD42D
P 3900 3900
F 0 "#PWR?" H 3900 3900 30  0001 C CNN
F 1 "GND" H 3900 3830 30  0001 C CNN
	1    3900 3900
	1    0    0    -1  
$EndComp
$Comp
L C C1
U 1 1 4FDFD44E
P 3900 3600
F 0 "C1" H 3950 3700 50  0000 L CNN
F 1 "C" H 3950 3500 50  0000 L CNN
	1    3900 3600
	1    0    0    -1  
$EndComp
$Comp
L CONN_1 P1
U 1 1 4FDFD47D
P 6650 3450
F 0 "P1" H 6730 3450 40  0000 L CNN
F 1 "CONN_1" H 6650 3505 30  0001 C CNN
	1    6650 3450
	1    0    0    -1  
$EndComp
Wire Wire Line
	3800 3350 4000 3350
Wire Wire Line
	3900 3300 3900 3400
Connection ~ 3900 3350
Wire Wire Line
	3800 3850 4000 3850
Wire Wire Line
	3900 3900 3900 3800
Connection ~ 3900 3850
Connection ~ 3900 3850
Wire Wire Line
	6500 3450 6400 3450
$Comp
L CONN_1 P3
U 1 1 4FDFD4BE
P 6650 3550
F 0 "P3" H 6730 3550 40  0000 L CNN
F 1 "CONN_1" H 6650 3605 30  0001 C CNN
	1    6650 3550
	1    0    0    -1  
$EndComp
Wire Wire Line
	6500 3550 6400 3550
$Comp
L CONN_1 P4
U 1 1 4FDFD4C5
P 6650 3650
F 0 "P4" H 6730 3650 40  0000 L CNN
F 1 "CONN_1" H 6650 3705 30  0001 C CNN
	1    6650 3650
	1    0    0    -1  
$EndComp
Wire Wire Line
	6500 3650 6400 3650
$Comp
L CONN_1 P6
U 1 1 4FDFD4CC
P 6650 3750
F 0 "P6" H 6730 3750 40  0000 L CNN
F 1 "CONN_1" H 6650 3805 30  0001 C CNN
	1    6650 3750
	1    0    0    -1  
$EndComp
Wire Wire Line
	6500 3750 6400 3750
$EndSCHEMATC
