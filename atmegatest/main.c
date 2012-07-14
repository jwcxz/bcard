// hdctrlr
// reads back emf of a hard drive platter
// spits out some info
//
// http://jwcxz.com/projects/hdctrlr
// J. Colosimo -- http://jwcxz.com

#include "main.h"

#include "uart.h"

#define THRESH 5
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
        /*
        if (othr) { 
            counter++;
            othr = 0;
        } else {
            othr = 1;
        }
        */
    }

    return counter;
}

int main(void) {
    // this code is written like it should be written in assembly so that's why
    // it sucks...

    uint8_t i = 0;
    uint8_t swipe = 0;
    uint8_t othr = 0;

    uint16_t prevl = 0;
    uint16_t prevr = 0;
    uint8_t counter = 0;

    // initialize UART
    //uart_init();
    
    DDRD |= (1<<7);
    uint8_t led = 0;

    // adjust clock prescale
    //CLKPR = _BV(CLKPCE);
    //CLKPR = 0;

    // training phase (set prev)
    for ( i=0 ; i<10 ; i++ ) {

        counter = sense(PB0);
        prevl = (prevl >> 1) + (counter >> 1);

        counter = sense(PB1);
        prevr = (prevl >> 1) + (counter >> 1);
    }

    while (1) {
        counter = sense(PB0);
        //uart_tx_hex(counter);
        //uart_tx(' ');

        if ( counter > prevl + THRESH ) {
            // hit!
            
            _delay_ms(100);

            counter = sense(PB1);
            //uart_tx_hex(counter);
            //uart_tx(' ');

            if ( counter > prevr + THRESH ) {
                // hit!
                if (led) {
                    led = 0;
                    PORTD &= ~(1<<7);
                } else {
                    led = 1;
                    PORTD |= 1<<7;
                }
                
                // start PWM system
            } else {
                //prevr = (prevr >> 1) + (counter >> 1);
            }

            _delay_ms(10);

        } else {
            //prevl = (prevl >> 1) + (counter >> 1);
        }

        _delay_ms(100);

        /*
        uart_tx_hex((uint8_t) (counter >> 8));
        uart_tx_hex((uint8_t) (counter & 0xFF));
        uart_tx(' ');
        */

        /*
        uart_tx(':');
        uart_tx( (uint8_t)( counter >> 8 ) );
        uart_tx( (uint8_t)( counter & 0xFF ) );
        */


        /*
        if ( counter > prev + THRESH ) {
            uart_tx('1');
        } else {
            prev = (prev >> 1) + (counter >> 1);
            uart_tx('0');
        }
        */

    }

	return 0;
}
