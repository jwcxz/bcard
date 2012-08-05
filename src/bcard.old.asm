.DEVICE attiny10
.include "regs.inc"

.def tmp = r16
.def msk = r17

.def cnt = r20
.def snlavg = r21
.def snravg = r22

.equ SNL = 3 ; left sensor
.equ SNR = 0 ; right sensor
.equ LED = 2 ; LED output

.equ MSK_L = ( (1<<LED) | (1<<SNL) )
.equ MSK_R = ( (1<<LED) | (1<<SNR) )
.equ MSK_N = ( (1<<LED) )

rjmp start

start:
    ldi r16, 0x01
    ldi r17, 0xD8
    out CCP, r17
    out CLKMSR, r16

    ldi r16, 0b1111
    ldi r17, 0x00
    out DDRB, r16
    out PORTB, r16

loop:
    out PORTB, r16
    nop
    out PORTB, r17
    rjmp loop


main:
    ; TODO: enable PUEB on unused PB1

    ; left sense output
    ldi tmp, MSK_L
    out DDRB, tmp
    ldi tmp, (1<<SNL)
    out PORTB, tmp
    
    ; set left sense to high Z
    ldi tmp, MSK_N
    out DDRB, tmp

    ; loop, counting cycles until sensor's PINB is low
    ldi cnt, 0x00       ; reset counter
    ldi msk, (1<<SNL)   ; compare against left sensor pin mask
    snl_rd_loop:
        inc  cnt ; increment cycle counter

        in   tmp, PINB      ; read sensor pins
        andi tmp, (1<<SNL)  ; mask against left sensor
        cpi  tmp, (1<<SNL)  ; TODO : not necessary
        breq snl_rd_loop_dn ; if the pin went low, we're done counting
        rjmp snl_rd_loop    ; otherwise, go back to reading

    snl_rd_loop_dn:
        ; finished counting
        ; if count is significantly smaler than previous count, then we have an
        ; event, in which case we should do the next thing.  otherwise, update
        ; the current running count average.

        ;ldi tmp, 
        

    

    ; main loop
    
    ; sense 1 pin on

    ; sense 1 pin off
    ; switch 1 to high Z

    ; loop
        ; count++
        ; pin == 0 yet?

    ; compare count against previous count


    ; if count < old count by some threshold, assume that it's a press and look for the swipe
        ; otherwise, sleep and go back
    ; \
    ;  continuing: keep looping, looking for the swipe at some timeout target
    ;  if other one triggers, start the pwm sequence
    ;  if timeout, sleep and check if first one went off
