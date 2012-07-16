// hdctrlr
// reads back emf of a hard drive platter
// spits out some info
//
// http://jwcxz.com/projects/hdctrlr
// J. Colosimo -- http://jwcxz.com

#include "main.h"

#include "uart.h"

#define THRESH 20
#define TFACTOR 4
#define PINONDELAY 1

uint8_t sense(uint8_t pin) {
    uint8_t counter = 0;
    uint8_t othr;

    DDRB  |= (1<<pin);
    PORTB |= (1<<pin);
    _delay_ms(PINONDELAY);
    DDRB  &= ~(1<<pin);
    PORTB &= ~(1<<pin);

    while ( PINB&(1<<pin) && counter <= 255 ) {
        counter++;
    }

    return counter;
}

int main(void) {
    // this code is written like it should be written in assembly so that's why
    // it sucks...

    uint8_t i = 0;
    uint8_t swipe = 0;

    uint8_t threshl = THRESH;
    uint8_t threshr = THRESH;

    uint8_t prevl = 0;
    uint8_t prevr = 0;

    uint8_t counter = 0;

    // initialize UART
    uart_init();
    
    DDRD |= (1<<7);

    // adjust clock prescale
    //CLKPR = _BV(CLKPCE);
    //CLKPR = 0;

    // training phase (set prev)
    prevl = sense(PB0);
    prevr = sense(PB1);
    for ( i=0 ; i<10 ; i++ ) {

        counter = sense(PB0);
        prevl = 7*(prevl >> 3) + (counter >> 3);

        counter = sense(PB1);
        prevr = 7*(prevr >> 3) + (counter >> 3);
    }

    while (1) {
        counter = sense(PB0);
        //uart_tx_hex(counter);
        //uart_tx(' ');

        if ( counter > prevl + threshl ) {
            // hit!

            // update threshl
            threshl = 7*(threshl >> 3) + ( ((counter-prevl)/TFACTOR) >> 3 );
            
            _delay_ms(100);

            counter = sense(PB1);
            //uart_tx_hex(counter);
            //uart_tx(' ');

            if ( counter > prevr + threshr ) {
                // hit!

                // update threshr
                threshr = 7*(threshr >> 3) + ( ((counter-prevl)/TFACTOR) >> 3 );

                PIND |= 1<<7;    // toggle pin
                
                // start PWM system
            } else {
                //prevr = 7*(prevr >> 3) + (counter >> 3);
            }

            _delay_ms(10);

        } else {
            prevl = 7*(prevl >> 3) + (counter >> 3);
        }

        _delay_ms(20);

        uart_tx_hex(prevl);
        uart_tx(' ');
        uart_tx_hex(prevr);
        uart_tx(' ');
        uart_tx_hex(threshl);
        uart_tx(' ');
        uart_tx_hex(threshr);
        uart_tx('\n');

    }

	return 0;
}
