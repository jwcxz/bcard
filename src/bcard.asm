.DEVICE attiny10
.include "regs.inc"

; register definitions
.def state = r25

; configurations that change
.equ CLKMSR_8MHZ = 0x00
.equ CLKMSR_128K = 0x01

; pin definitions
;.equ PIN_LED = 0
.equ PIN_LED = 2
.equ PIN_LFT = 1
.equ PIN_FDR = 1
.equ PIN_FLT = 2
.equ PIN_RGT = 0
;.equ PIN_RGT = 3

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
.org 0x01
    rjmp int0_interrupt


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


    ; training phase

    ; guess at on threshhold


    ; enable float driver to oscillate slowly
    rcall enable_float_driver

    ; start resistive sensing component
    sei

    ; TODO: sleep
    loop:
        rjmp loop
    ; }}}


enable_float_driver: ; {{{
    ; set floating input to 0
    cbi PUEB,  PIN_FLT
    cbi DDRB,  PIN_FLT
    cbi PORTB, PIN_FLT  ; TODO: not necessary

    ; enable floating driver
    sbi DDRB,  PIN_FDR

    ; ICR0 = 0x8000
    ldi r16, 0xFF
    ldi r17, 0xFF
    out ICR0H, r16
    out ICR0L, r17

    ; OCR0B = 0x4000
    ldi r16, 0x80
    ldi r17, 0x00
    out OCR0BH, r16
    out OCR0BL, r17

    ; set FAST PWM mode with ICR0 as TOP
    
    ; TCCR0A = COM0B0 | WGM01
    ldi r16, (1<<5) | (1<<1)
    out TCCR0A, r16

    ; TCCR0B = WGM03 | WGM02 | CS00
    ldi r16, (1<<4) | (1<<3) | (1<<0)
    out TCCR0B, r16

    ; enable interrupt mask
    sbi EIMSK, 0    ; INT0 on
    sbi EICRA, 0    ; ICS00 -- any change

    ret ; }}}


disable_float_driver: ; {{{
    ; shut off interrupt masks
    cbi EIMSK, 0

    ; shut off float driver and set as input
    ldi r16, 0
    out TCCR0A, r16
    out TCCR0B, r16
    cbi DDRB, PIN_FDR

    ret
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

        ; else add 1 to the counter and check if it is going to overflow
        ldi r16, 1
        add r17, r16

        ; check if we've hit the max
        ; if so, get out of the loop
        cpi r17, 0xFF
        breq cap_sense_check_loop_dn

        ; otherwise go back to the top of the loop
        rjmp cap_sense_check_loop
        ; TODO: above code can be optimized by switching breq to brne back to
        ; cap_sense_check_loop

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
    
int0_interrupt: ; {{{
    rcall disable_float_driver

    sbi PINB, PIN_LED
    ; now that we've hit an interrupt, it's time to detect a swipe

    ldi state, ST_IDLE

    int0_sense_loop:
        ldi r16, (1<<PIN_LFT)
        rcall cap_sense

        ; copy left sensor state to r19,20
        mov r19, r16
        mov r20, r17

        ldi r16, (1<<PIN_RGT)
        rcall cap_sense

        lsl r19         ; shift left is_on over
        or  r16, r19    ; or it with right
        ; so, r16 contains one of SNS_LEFT, SNS_RGHT, SNS_BOTH, or SNS_NONE

        ; the state machine looks at the is_on values (stored in bits 1 and 0
        ; of r16 ; for left and right sensors respectively) and determines the
        ; swipe status from there
        ; based on the current algorithm, it could really just be boiled down
        ; to like just a latch, but whatever
        sm_chk_idle:
            cpi  state, ST_IDLE
            brne sm_chk_left
            ; if we're in the idle state, that means that we haven't done anything yet

            ; XXX: I'm pretty sure this can be folded into ST_LEFT; the
            ;      original idea was for it to only be able to occur once

            ; transition mappings
            ; sns | new_state
            ; ----|----------
            ;  00 | *halt*
            ;  01 | ST_LEFT
            ;  10 | *halt*
            ;  11 | ST_BOTH

            sm_idle_chk_left:
                cpi  r16, SNS_LEFT
                brne sm_idle_chk_both
                ldi state, ST_LEFT
                rjmp int0_sense_loop_end

            sm_idle_chk_both:
                cpi  r16, SNS_BOTH
                brne int0_dn
                ldi state, ST_BOTH
                rjmp int0_sense_loop_end


        sm_chk_left:
            cpi  state, ST_LEFT
            brne sm_chk_both

            ; transition mappings
            ; sns | new_state
            ; ----|----------
            ;  00 | *halt*
            ;  01 | ST_LEFT
            ;  10 | *halt*
            ;  11 | ST_BOTH

            sm_left_chk_both:
                cpi  r16, SNS_BOTH
                brne sm_left_chk_left
                ldi state, ST_BOTH
                rjmp int0_sense_loop_end

            sm_left_chk_left:
                cpi  r16, SNS_LEFT
                brne int0_dn
                rjmp int0_sense_loop_end


        sm_chk_both:
            cpi state, ST_BOTH
            brne int0_dn        ; wtf!?!?!?!?

            ; transition mappings
            ; sns | new_state
            ; ----|----------
            ;  00 | *halt*
            ;  01 | ST_LEFT
            ;  10 | *do shit and halt!*
            ;  11 | ST_BOTH
            
            sm_both_chk_rght:
                cpi  r16, SNS_RGHT
                brne sm_both_chk_both
                ;
                ; TODO: pwm shit!
                ;
                ldi r17, (1<<PIN_LED)
                out PINB, r17
                rjmp int0_dn

            sm_both_chk_both:
                cpi  r16, SNS_BOTH
                brne sm_both_chk_left
                rjmp int0_sense_loop_end


            sm_both_chk_left:
                cpi  r16, SNS_LEFT
                brne int0_dn
                ldi state, ST_LEFT
                rjmp int0_sense_loop_end


    int0_sense_loop_end:
        ; TODO: delay for 10 ms
        ; TODO: check if state is idle?
        rjmp int0_sense_loop

    int0_dn:

    ; re-enabe floating driver and call it a day
    rcall enable_float_driver
    reti ; }}}
