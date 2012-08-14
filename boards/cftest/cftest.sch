EESchema Schematic File Version 2  date Mon 13 Aug 2012 09:07:05 PM EDT
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
EELAYER 43  0
EELAYER END
$Descr A4 11693 8268
encoding utf-8
Sheet 1 1
Title ""
Date "14 aug 2012"
Rev ""
Comp ""
Comment1 ""
Comment2 ""
Comment3 ""
Comment4 ""
$EndDescr
$Comp
L CONN_1 PVCC1
U 1 1 5029A469
P 3150 2550
F 0 "PVCC1" H 3230 2550 40  0000 L CNN
F 1 "CONN_1" H 3150 2605 30  0001 C CNN
	1    3150 2550
	-1   0    0    1   
$EndComp
$Comp
L LED D1
U 1 1 5029A489
P 3850 2350
F 0 "D1" H 3850 2450 50  0000 C CNN
F 1 "LED" H 3850 2250 50  0000 C CNN
	1    3850 2350
	1    0    0    -1  
$EndComp
$Comp
L LED D2
U 1 1 5029A496
P 3850 2600
F 0 "D2" H 3850 2700 50  0000 C CNN
F 1 "LED" H 3850 2500 50  0000 C CNN
	1    3850 2600
	1    0    0    -1  
$EndComp
$Comp
L LED D3
U 1 1 5029A49C
P 3850 2800
F 0 "D3" H 3850 2900 50  0000 C CNN
F 1 "LED" H 3850 2700 50  0000 C CNN
	1    3850 2800
	1    0    0    -1  
$EndComp
$Comp
L LED D4
U 1 1 5029A4A2
P 3850 3000
F 0 "D4" H 3850 3100 50  0000 C CNN
F 1 "LED" H 3850 2900 50  0000 C CNN
	1    3850 3000
	1    0    0    -1  
$EndComp
$Comp
L CONN_1 PGND1
U 1 1 5029A4CB
P 3150 2750
F 0 "PGND1" H 3230 2750 40  0000 L CNN
F 1 "CONN_1" H 3150 2805 30  0001 C CNN
	1    3150 2750
	-1   0    0    1   
$EndComp
Wire Wire Line
	3300 2550 3650 2550
Wire Wire Line
	3650 2350 3650 3000
Connection ~ 3650 2550
Connection ~ 3650 2550
Connection ~ 3650 2600
Connection ~ 3650 2600
Connection ~ 3650 2800
Connection ~ 3650 2800
Wire Wire Line
	4050 2350 4050 3200
Connection ~ 4050 2600
Connection ~ 4050 2600
Connection ~ 4050 2800
Connection ~ 4050 2800
Wire Wire Line
	4050 3200 3300 3200
Wire Wire Line
	3300 3200 3300 2750
Connection ~ 4050 3000
$EndSCHEMATC
