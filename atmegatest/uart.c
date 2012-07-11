#include "uart.h"

void uart_init(void) {
	UBRR0H = (unsigned char) (BAUD_PRESCALE>>8);
	UBRR0L = (unsigned char) (BAUD_PRESCALE&0xFF);
    UCSR0A = ( BAUD_DOUBLE << U2X0 );
	UCSR0B = ( _BV(RXEN0) | _BV(TXEN0) );
	UCSR0C = ( _BV(UCSZ01) | _BV(UCSZ00) );

    DDRD |= _BV(PD1);

    // enable even parity
    //UCSR0C |= _BV(UPM01);
}

uint8_t uart_rx(void) {
	while(!(UCSR0A & (1 << RXC0))) ;
	return UDR0;
}

void uart_tx(uint8_t data) {
	while((UCSR0A & (1 << UDRE0)) == 0) ;
	UDR0 = data;

	return;
}

void uart_tx_hex(uint8_t data) {
    uint8_t lo, hi;

    hi = (data >> 4) & 0x0F;
    lo = data & 0x0F;

    if ( hi < 0xA ) {
        hi |= 0x30;
    } else {
        hi -= 9;
        hi |= 0x40;
    }

    if ( lo < 0xA ) {
        lo |= 0x30;
    } else {
        lo -= 9;
        lo |= 0x40;
    }

	while((UCSR0A & (1 << UDRE0)) == 0) ;
	UDR0 = hi;

	while((UCSR0A & (1 << UDRE0)) == 0) ;
	UDR0 = lo;
    
    return;
}
