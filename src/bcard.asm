.DEVICE attiny10
.include "regs.inc"
.equ led = 2

start:
    sbi   DDRB, led  ;connect LED to PB2 (Attiny10 pin 4)

loop:
    sbi PORTB, led
    cbi PORTB, led
    rjmp loop
