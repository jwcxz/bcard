.DEVICE attiny10
.include "regs.inc"

.equ CFG_PWMLOOPS = 0x04

; register definitions
.def lthresh = r23
.def rthresh= r24
.def state = r25
.def ZH = r31
.def ZL = r30

; configurations that change
.equ CLKMSR_8MHZ = 0x00
.equ CLKMSR_128K = 0x01

; pin definitions
;.equ PIN_LED = 0
.equ PIN_LED = 0
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
.org 0x08
    rjmp wdt_interrupt


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
    ldi   r16, (1<<PIN_LFT)
    rcall cap_sense
    mov   r20, r17

    ldi   r16, (1<<PIN_RGT)
    rcall cap_sense
    mov   r21, r17

    ldi r19, 4
    train_loop:
        ; get left pin
        ldi   r16, (1<<PIN_LFT)
        rcall cap_sense

        ; average against existing
        lsr r20
        lsr r17
        add r20, r17


        ldi   r16, (1<<PIN_RGT)
        rcall cap_sense

        ; average against existing
        lsr r21
        lsr r17
        add r21, r17


        dec  r19
        brne train_loop


    ; define threshhold as 125% off value
    mov lthresh, r20
    lsr lthresh
    add lthresh, r20
    
    mov rthresh, r21
    lsr rthresh
    add rthresh, r21


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

    ret ; }}}


cap_sense: ; {{{
    ; in : r16 - sensor to use
    ; out: r16 - pressed or unpressed
    ;      r17 - counter value
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

    ; figure out which pin's threshold to compare against
    cpi  r16, (1<<PIN_LFT)
    mov  r18, lthresh
    breq compare
    mov  r18, rthresh

    compare:
    cp   r17, r18
    brsh cap_sense_pin_on
        ldi  r16, 0
        ret

    cap_sense_pin_on:
        ldi r16, 1
        ret
    ; }}}


delay_long: ; {{{
    ldi r28, 0x10
    rjmp dly2

delay_short:
    ldi r28, 0x01
    ldi r27, 0x05
    rjmp dly1

delay_reallylong:
    ldi r28, 0xFF
    rjmp dly2

dly2:
    ldi r27, 0xFF
    dly1:
        dec r27
        brne dly1

    dec r28
    brne dly2

    ret ; }}}


int0_interrupt: ; {{{
    rcall disable_float_driver

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
                ldi  state, ST_LEFT
                rjmp int0_sense_loop_end

            sm_idle_chk_both:
                cpi  r16, SNS_BOTH
                brne int0_dn
                ldi  state, ST_BOTH
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
                ldi  state, ST_BOTH
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

                ; what follows is almost an exact copy of scott-42's branch of
                ; Adafruit's iCuffLinks (which are totally awesome, by the way)

                ldi r16, (1<<7)|(1<<6)|(1<<0) ; COM0A1, COM0A0, WGM00
                out TCCR0A, r16
                ldi r16, (1<<7)|(1<<0) ; ICN0(!?), CS00
                out TCCR0B, r16

                ldi r16, 0
                out OCR0AH, r16 ; high portion of counter should be 0xFF

                ldi r16, (1<<0) ; SE
                out SMCR, r16   ; sleep enable at idle TODO: power-down?

                sei

                ; number of loops of the pwm cycle
                ldi r17, CFG_PWMLOOPS

                pwm_loop_start:
                    ; 0x4000 (start of code) + offset(sinetbl)
                    ldi ZH, high(sinetbl*2) + 0x40
                    ldi ZL,  low(sinetbl*2)

                pwm_loop:
                    ; rant time!
                    ; avra is not quite the assembler it claims to be.  It's a
                    ; bit buggy when it comes to certain instructions.  When
                    ; trying to perform an LD instruction, it claims that the
                    ; ATtiny10 doesn't support the instruction.  But lololol it
                    ; does.  Look at the iCuffLinks code, after all.  So using
                    ; the information at this page:
                    ;   http://www.wrightflyer.co.uk/asm/Html/LD.html
                    ; I constructed the opcode 1001 0001 0000 1101 (0x910D),
                    ; which corresponds to LD R16, X+.  But that wasn't good
                    ; enough for me.  I wanted to actually see if I could use
                    ; the Z pointer instead of the X pointer.  Of course, I
                    ; could probably find the associated instruction for this
                    ; in the Atmel manuals, but instead, I decided to
                    ; investigate the iCuffLinks code.  There's only one 
                    ; CPI R16, 0 instruction and I know that corresponds to the
                    ; word 0x3000, so I looked for 0030 in the hex file and
                    ; sure enough, I found that the instruction before it was
                    ; 0x9101, which is pretty close to 0x910D, so I tried it
                    ; and it worked.  tl;dr damnit, avra!  :P
                    .dw  0x9101         ; ld r16, z+ : 1001 0001 0000 0001
                    cpi  r16, 0xFF      ; check if we have reached the end of the table
                    brne pwm_loop_do    ; if not, perform pwm

                    dec  r17            ; decrement the PWM loop
                    brne pwm_loop_start ; if we're down to 0, start back at the
                                        ; beginning of the waveform table
                    rjmp int0_dn        ; otherwise, we're done here, so finish
                                        ; up the interrupt

                pwm_loop_do:
                    out OCR0AL, r16     ; dump PWM value to timer

                    ldi r16, 0xD8       ; prepare CCP key
                    out CCP, r16        ; dump signature

                    ldi r16, (1<<6)     ; WDIE, 2k cycles
                    out WDTCSR, r16

                    wdr 
                    sleep

                    ldi r16, (1<<6)|(1<<0) ; WDIE, 4k cycles
                    out WDTCSR, r16

                    wdr
                    sleep

                    rjmp pwm_loop


            sm_both_chk_both:
                cpi  r16, SNS_BOTH
                brne sm_both_chk_left
                rjmp int0_sense_loop_end


            sm_both_chk_left:
                cpi  r16, SNS_LEFT
                brne int0_dn
                ldi  state, ST_LEFT
                rjmp int0_sense_loop_end


    int0_sense_loop_end:
        ; TODO: delay for 10 ms
        ; TODO: check if state is idle?
        rjmp int0_sense_loop

    int0_dn:

    ; re-enabe floating driver and call it a day
    rcall enable_float_driver
    reti ; }}}


wdt_interrupt: ; {{{
    ; when the wdt hits, just return
    reti ; }}}


sinetbl: ; {{{
    ; pwm table
    ; this, again, is from iCuffLinks, with the modification that I have
    ; inverted the table (i.e. 0xFF - [value in iCuffLinks table])
    ; this inversion allows me to start and end at zero brightness so that it's
    ; seamless.  The other thing is that a bug in avra doesn't like it when the
    ; .db string is long, so I had to split the table up.  There must be an
    ; even number of elements in the .db array.
    .db 254, 254, 253, 252, 250, 247, 244, 240, 235, 230, 225, 219, 212, 206, 199, 191, 183, 175, 167, 158, 150, 141, 132, 123, 114, 105, 97, 88, 80, 72, 64, 56, 49, 43, 36, 30, 25, 20, 15, 11, 8, 5, 3, 2, 1, 0, 1, 2
    .db 3, 5, 8, 11, 15, 20, 25, 30, 36, 43, 49, 56, 64, 72, 80, 88, 97, 105, 114, 123, 132, 141, 150, 158, 167, 175, 183, 191, 199, 206, 212, 219, 225, 230, 235, 240, 244, 247, 250, 252, 253, 254, 255, 255
    
    ; original values are as follows (starts and ends at high brightness)
    ;.db 1, 1, 2, 3, 5, 8, 11, 15, 20, 25, 30, 36, 43, 49, 56, 64, 72, 80, 88, 97, 105, 114, 123, 132, 141, 150, 158, 167, 175, 183, 191, 199, 206, 212, 219, 225, 230, 235, 240, 244, 247, 250, 252, 253, 254, 255, 254, 253
    ;.db 252, 250, 247, 244, 240, 235, 230, 225, 219, 212, 206, 199, 191, 183, 175, 167, 158, 150, 141, 132, 123, 114, 105, 97, 88, 80, 72, 64, 56, 49, 43, 36, 30, 25, 20, 15, 11, 8, 5, 3, 2, 1, 0, 0
    ; }}}
