// hdctrlr
// reads back emf of a hard drive platter
// spits out some info
//
// http://jwcxz.com/projects/hdctrlr
// J. Colosimo -- http://jwcxz.com

#include "main.h"

#include "uart.h"

int main(void) {
    uint8_t i = 0;

    uint16_t counter = 0;

    // initialize UART
    uart_init();

    while (1) {

        counter = 0;

        DDRB |= 1;
        PORTB |= 1;
        _delay_ms(5);
        DDRB &= ~1;
        PORTB &= ~1;

        while ( PINB&1 && counter < 16000 ) {
            counter++;
        }

        /*
        uart_tx_hex((uint8_t) (counter >> 8));
        uart_tx_hex((uint8_t) (counter & 0xFF));
        uart_tx(' ');
        */

        uart_tx(':');
        uart_tx( (uint8_t)( counter >> 8 ) );
        uart_tx( (uint8_t)( counter & 0xFF ) );

        _delay_ms(45);

    }

	return 0;
}
