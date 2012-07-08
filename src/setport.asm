.DEVICE attiny10
.include "regs.inc"

rjmp RESET  ;go and set up PORTB as an output 


;name registers (selected >r15 arbitrarily)
.def  counter1  = r16
.def  counter2  = r17
.def  counter3  = r18 


;set some variables 
;time1 and time2 set the value for the final loop in each delay
.equ  time1   = 170 ;between 0 and 255
.equ  time2   = 1
.equ  led     = 2 ;LED at PB2 

RESET: ;set PB2 as an output in the Data Direction Register for PORTB
sbi   DDRB, led  ;connect LED to PB2 (Attiny10 pin 4)

flash: ;main loop  
sbi PORTB, led
cbi PORTB, led
rjmp flash


;;cbi   PORTB, led ;LED off - cbi/sbi swapped for N-FET switching (ie.LED is OFF when FET is ON)
;ldi   r17, 170 ;load counter1 delay         
;rcall onDelay            
;;sbi   PORTB, led ;LED on           
;ldi   r18, 1 ;load counter3 delay
;rcall offDelay
;rjmp  flash  ;return to beginning of loop
;
;
;onDelay:       
;clr   r16  ;clear counter1 
;
;
;loop1: ;nested loop that decrements counter 1 (255) x counter2 (time1) times (ie. 255*time1)
;dec   r16  ;decrement counter1 
;brne  loop1     ;branch if not 0     
;dec   r17  ;decrement counter2 
;brne  loop1     ;branch if not 0     
;ret      
;
;offDelay: ;same as onDelay but with a third loop     
;clr   r16
;clr   r17 
;
;
;loop2: ;decrement counter 1(255) x counter2(255) x counter3(time2) (ie. 255*255*time2) 
;dec   r16
;brne  loop2         
;dec   r17
;brne  loop2          
;dec   r18 
;brne  loop2 
;ret     
;
;lds r15, 128
