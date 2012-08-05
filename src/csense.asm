.DEVICE attiny10
.include "regs.inc"

; register definitions
.def state = r31

; configurations that change
.equ CLKMSR_8MHZ = 0x00
.equ CLKMSR_128K = 0x01

; pin definitions
;.equ PIN_LED = 0
.equ PIN_LED = 2
.equ PIN_LFT = 1
.equ PIN_RGT = 0

; capacitive touch sensor states
.equ ST_IDLE = 0
.equ ST_LEFT = 1
.equ ST_BOTH = 2

; sensor pressed values
.equ SNS_LEFT = 2   ; 10
.equ SNS_RGHT = 1   ; 01
.equ SNS_BOTH = 3   ; 11
.equ SNS_NONE = 0   ; 00

;-------------------------------------------------------

.cseg
.org 0x00
    rjmp reset


reset: ; {{{
    ; clock setting: 
    ldi r16, CLKMSR_8MHZ

    ; apply clock settings
    ldi r17, 0xD8
    out CCP, r17
    out CLKMSR, r16

    ; set LED pin to be output
    sbi DDRB,  PIN_LED
    cbi PORTB, PIN_LED

    loop:
        ldi   r16, (1<<PIN_LFT)
        rcall cap_sense

        cpi r17, 1
        brne loop

        sbi PINB, PIN_LED
        rjmp loop
    ; }}}


cap_sense: ; {{{
    ; in : r16 - sensor to use
    ; out: r17 - pressed or unpressed
    ;      r16 - counter value
    ; f-u: r18

    mov r17, r16
    ori r17, (1<<PIN_LED)   ; DDR needs LED output on too

    ; drive sensor
    out DDRB, r17       ; DDR: outputs are (LED | sensor)
    out PORTB, r16      ; drive sensor

    ; TODO: delay?
    rcall delay_short

    ldi r17, (1<<PIN_LED)   ; switch to sensor input
    out DDRB, r17
    ldi r17, 0              ; shut sensor driver off
    out PORTB, r17
    ; TODO: anything needed for PUEB?

    ; now, loop, waiting for the sensor to fall

    cap_sense_check_loop:
        ; mask against pin
        in  r18, PINB
        and r18, r16

        ; if pin is 0, then break out of the loop
        breq cap_sense_check_loop_dn

        ; else add 1 to the counter
        inc r17

        ; check if we've hit the max
        ; if so, get out of the loop
        cpi r17, 0xFF
        brne cap_sense_check_loop

    cap_sense_check_loop_dn:
    ; check r17 against counter and figure out if the sensor was pressed

    ; TODO
    cpi  r17, 0xD0
    brsh cap_sense_pin_on
        ldi  r16, 0
        ret

    cap_sense_pin_on:
        ldi r16, 1
        ret

    ret ; }}}


delay_long:
    ldi r28, 0xFF
    rjmp dly2

delay_short:
    ldi r28, 0x01
    ldi r27, 0x05
    rjmp dly1


dly2:
    ldi r27, 0xFF
    dly1:
        dec r27
        brne dly1

    dec r28
    brne dly2

    ret
