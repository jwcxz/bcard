// bcard -- atmega test platform
// http://jwcxz.com/projects/hdctrlr
// this code is written like it should be written in assembly so that's why
// it sucks...

// J. Colosimo -- http://jwcxz.com

#include "main.h"

#include "uart.h"

#define ONGUESS 100
#define PINONDELAY 1

#define LGDECAY 4
#define DECAY   ( (1<<LGDECAY) - 1 )


#define SNSPORT PORTB
#define SNSPIN  PINB
#define SNSDDR  DDRB
#define SNSLEFT PB1
#define SNSRGHT PB0

#define LEDPORT PORTD
#define LEDDDR  DDRD
#define LEDPIN  PIND
#define LED     PD3

#define FLTPORT PORTD
#define FLTDDR  DDRD
#define FLT     PD2

#define FLTDRVPORT PORTB
#define FLTDRVPIN  PINB
#define FLTDRVDDR  DDRB
#define FLTDRV     PB1


uint8_t on[2] = {0, 0};
uint8_t off[2] = {0, 0};

uint8_t inthit = 0;


uint8_t sense(uint8_t pin) {
    uint8_t counter = 0;

    SNSDDR  |=  _BV(pin);
    SNSPORT |=  _BV(pin);
    _delay_ms(PINONDELAY);
    SNSDDR  &= ~_BV(pin);
    SNSPORT &= ~_BV(pin);

    while ( SNSPIN&(1<<pin) && counter <= 255 ) {
        counter++;
    }

    return counter;
}

uint8_t is_on(uint8_t count, uint8_t idx) {
    return ( count >= (off[idx] >> 1) + (on[idx] >> 1) );
}

void ewma(uint8_t *val, uint8_t new) {
    // *val = DECAY*( (*val) >> LGDECAY ) + ( new >> LGDECAY ) + 1;
    return;
}

void enable_float_driver(void) {
    // Set up floating pins
    FLTDDR  &= ~_BV(FLT);   // float sense input
    FLTPORT &= ~_BV(FLT);   // don't you dare pull that shit up
    FLTDRVDDR |= _BV(FLTDRV);

    OCR1A = 0x0800;
    TCCR1A = _BV(COM1A0) | _BV(WGM11) | _BV(WGM10);
    TCCR1B = _BV(WGM13) | _BV(WGM12) | _BV(CS12) | _BV(CS10);

    // interrupt mask
    // enable INT0 pin
    EIMSK = _BV(INT0);
    EICRA = _BV(ISC01);

    return;
}

void disable_float_driver(void) {
    // interrupt mask
    EIMSK = 0;
    EICRA = 0;

    // shut off float driver
    TCCR1A = 0;
    TCCR1B = 0;
    FLTDRVDDR &= ~_BV(FLTDRV);

    return;
}

void int_method_2(void) {
    uint8_t cl, cr;
    uint8_t ol, or;
    uint8_t i, tmp;
    enum state st = idle;

    // just got a potential touch
    do {
        cl = 0;
        cr = 0;
        for ( i=0 ; i<5 ; i++ ) {
            tmp = sense(SNSLEFT);
            if ( tmp > cl ) {
                cl = tmp;
            }

            tmp = sense(SNSRGHT);
            if ( tmp > cr ) {
                cr = tmp;
            }
        }
        ol = is_on(cl, 0);
        or = is_on(cr, 1);

        //*
        // TODO: this can now be folded into the switch statement
        if ( st == idle ) {
            if ( !ol && !or ) {
                // nope!
                st = idle;
                return;
            } else if ( ol && !or ) {
                st = left;
            } else if ( ol && or ) {
                st = both;
            } else {
                st = idle;
            }
        }

        //* DEBUG
        // cl:on? cr:on? state
        //uart_tx_hex(cl);
        //uart_tx(':');
        uart_tx_hex(ol);
        uart_tx(' ');

        //uart_tx_hex(cr);
        //uart_tx(':');
        uart_tx_hex(or);
        uart_tx(' ');

        uart_tx_hex(st);
        // */

        switch(st) {
            case idle:
                break;

            case left:
                if ( is_on(cl, 0) && is_on(cr, 1) ) {
                    st = both;
                } else if ( is_on(cl, 0) ) {
                    st = left;
                } else {
                    st = idle;
                }

                break;

            case both:
                if ( is_on(cr, 1) && !is_on(cl, 0) ) {
                    LEDPIN |= _BV(LED);
                    st = idle;
                } else if ( is_on(cl, 0) && is_on(cr, 1) ) {
                    st = both;
                } else if ( is_on(cl, 0) && !is_on(cr, 1) ) {
                    st = left;
                } else {
                    st = idle;
                }

                break;
        }

        //*
        uart_tx(' ');

        uart_tx_hex(st);
        uart_tx('\n');
        // */

        _delay_ms(10);
    } while ( st != idle );

    return;
}


void int_method_1(void) {
    uint8_t cl, cr;
    uint8_t i, tmp;
    enum state st = idle;

    // just got a potential touch
    // check left sensor once to see if we're probably hitting it
    cl = 0;
    for ( i=0 ; i<5 ; i++ ) {
        tmp = sense(SNSLEFT);
        if ( tmp > cl ) {
            cl = tmp;
        }
    }

    if ( !is_on(cl, 0) && !is_on(cr, 1) ) {
        // nope!
        return;
    }

    // so, the sensor was on, which puts us in the first state
    st = left;

    while ( st != idle ) {
        cl = 0;
        for ( i=0 ; i<5 ; i++ ) {
            tmp = sense(SNSLEFT);
            if ( tmp > cl ) {
                cl = tmp;
            }
        }

        cr = 0;
        for ( i=0 ; i<5 ; i++ ) {
            tmp = sense(SNSRGHT);
            if ( tmp > cr ) {
                cr = tmp;
            }
        }

        //*
        // cl:on? cr:on? state
        uart_tx_hex(cl);
        uart_tx(':');
        uart_tx_hex(is_on(cl,0));
        uart_tx(' ');

        uart_tx_hex(cr);
        uart_tx(':');
        uart_tx_hex(is_on(cr,1));
        uart_tx(' ');

        uart_tx_hex(st);
        // */

        switch(st) {
            case idle:
                break;

            case left:
                if ( is_on(cl, 0) && is_on(cr, 1) ) {
                    st = both;
                } else if ( is_on(cl, 0) ) {
                    st = left;
                } else {
                    st = idle;
                }

                break;

            case both:
                if ( is_on(cr, 1) && !is_on(cl, 0) ) {
                    LEDPIN |= _BV(LED);
                    st = idle;
                } else if ( is_on(cl, 0) && is_on(cr, 1) ) {
                    st = both;
                } else if ( is_on(cl, 0) && !is_on(cr, 1) ) {
                    st = left;
                } else {
                    st = idle;
                }

                break;
        }

        //*
        uart_tx(' ');

        uart_tx_hex(st);
        uart_tx('\n');
        // */

        //_delay_ms(10);
    }

    return;
}

/* dumb methods
void method_3(void) {
    uint8_t cl, cr;
    uint8_t i, tmp;
    enum state st = idle;

    while (1) {
        cl = 0;
        for ( i=0 ; i<5 ; i++ ) {
            tmp = sense(SNSLEFT);
            if ( tmp > cl ) {
                cl = tmp;
            }
        }

        cr = 0;
        for ( i=0 ; i<5 ; i++ ) {
            tmp = sense(SNSRGHT);
            if ( tmp > cr ) {
                cr = tmp;
            }
        }

        if ( is_on(cl, 0) ) {
            ewma(&(on[0]), cl);
        } else {
            ewma(&(off[0]), cl);
        }

        if ( is_on(cr, 1) ) {
            ewma(&(on[1]), cr);
        } else {
            ewma(&(off[1]), cr);
        }

        switch(st) {
            case idle:
                if ( is_on(cl, 0) && !is_on(cr, 1) ) {
                    st = left;
                } else {
                    st = idle;
                }
                break;

            case left:
                if ( is_on(cr, 1) && is_on(cl, 1) ) {
                    st = right;
                } 
                break;

            case right:
                if ( is_on(cr, 1) && !is_on(cl, 0) ) {
                    LEDPIN |= _BV(LED);
                    st = idle;
                }
                break;
        }

        _delay_ms(10);

        uart_tx_hex(st); uart_tx(' ');
        uart_tx_hex(cl); uart_tx(' ');
        uart_tx_hex(cr); uart_tx(' ');
        uart_tx_hex(is_on(cl,0)); uart_tx(' ');
        uart_tx_hex(is_on(cr,1)); uart_tx(' ');
        uart_tx_hex(off[0]); uart_tx('/'); uart_tx_hex(on[0]);
        uart_tx(' ');
        uart_tx_hex(off[1]); uart_tx('/'); uart_tx_hex(on[1]);
        uart_tx('\n');
    }
}

void method_2(void) {
    uint8_t counter;
    enum state st;

    while (1) {
        switch(st) {
            case idle:
                counter = sense(SNSLEFT);
                uart_tx_hex(counter); uart_tx(' ');

                if ( is_on(counter, 0) ) {
                    ewma(&(on[0]), counter);
                    st = left;
                    _delay_ms(50);
                } else {
                    ewma(&(off[0]), counter);
                }
                
                break;

            case left:
                counter = sense(SNSRGHT);
                uart_tx_hex(counter); uart_tx(' ');

                if ( is_on(counter, 1) ) {
                    //on[1] = DECAY*(on[1] >> LGDECAY) + (counter >> LGDECAY);
                    st = right;;
                } else {
                    //off[1] = DECAY*(off[1] >> LGDECAY) + (counter >> LGDECAY);
                }
                
                break;

            case right:
                LEDPIN |= _BV(LED);    // toggle pin
                st = idle;
        }

        uart_tx_hex(st); uart_tx(' ');
        uart_tx_hex(off[0]); uart_tx('/'); uart_tx_hex(on[0]);
        uart_tx(' ');
        uart_tx_hex(off[1]); uart_tx('/'); uart_tx_hex(on[1]);
        uart_tx('\n');

    }
}

void method_1(void) {
    uint8_t counter, swipe;

    while (1) {
        counter = sense(SNSLEFT);
        uart_tx_hex(counter);
        uart_tx(' ');

        if ( counter > (off[0] >> 1) + (on[0] >> 1) ) {
            // hit!
            uart_tx('L');

            // update on
            on[0] = DECAY*(on[0] >> LGDECAY) + (counter >> LGDECAY);
            
            counter = sense(SNSRGHT);
            //uart_tx_hex(counter);
            //uart_tx(' ');

            if ( counter > (off[1] >> 1) + (on[1] >> 1) ) {
                // hit!
                uart_tx('R');

                // update on
                on[1] = DECAY*(on[1] >> LGDECAY) + (counter >> LGDECAY);

                swipe = 1;
            } else {
                uart_tx(' ');
                off[1] = DECAY*(off[1] >> LGDECAY) + (counter >> LGDECAY);
            }

            _delay_ms(10);

        } else {
            uart_tx(' ');
            off[0] = DECAY*(off[0] >> LGDECAY) + (counter >> LGDECAY);
        }


        if (swipe) {
            LEDPIN |= _BV(LED);    // toggle pin
            swipe = 0;
            
            // start PWM system
        }

        _delay_ms(20);

        uart_tx_hex(off[0]);
        uart_tx('/');
        uart_tx_hex(on[0]);
        uart_tx(' ');
        uart_tx_hex(off[1]);
        uart_tx('/');
        uart_tx_hex(on[1]);
        uart_tx('\n');

    }
}
*/

int main(void) {
    uint8_t i=0, counter=0;

    // adjust clock prescale
    //CLKPR = _BV(CLKPCE);
    //CLKPR = 0;

    // initialize UART
    uart_init();

    // LED output
    LEDDDR |= _BV(LED);

    // training phase (set "off" value)
    off[0] = sense(SNSLEFT);
    off[1] = sense(SNSRGHT);
    for ( i=0 ; i<10 ; i++ ) {
        counter = sense(SNSLEFT);
        off[0] = DECAY*(off[0] >> LGDECAY) + (counter >> LGDECAY);

        counter = sense(SNSRGHT);
        off[1] = DECAY*(off[1] >> LGDECAY) + (counter >> LGDECAY);
    }

    on[0] = off[0] + ONGUESS;
    on[1] = off[1] + ONGUESS;

    uart_tx('\n');
    uart_tx_hex(off[0]);
    uart_tx('/');
    uart_tx_hex(on[0]);
    uart_tx(' ');
    uart_tx_hex(off[1]);
    uart_tx('/');
    uart_tx_hex(on[1]);
    uart_tx('\n');

    // enable the float driver to oscillate slowly
    enable_float_driver();

    // start resistive component
    sei();

    while (1);

	return 0;
}

ISR(INT0_vect) {
    disable_float_driver();

    uart_tx('*');

    // resistive touch phase fired
    int_method_2();

    //_delay_ms(10);

    enable_float_driver();
}
