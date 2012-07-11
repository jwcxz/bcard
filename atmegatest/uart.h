#ifndef _UART_H
#define _UART_H

#include "main.h"

void uart_init(void);
uint8_t uart_rx(void);
uint8_t uart_data_rdy(void);
void uart_tx(uint8_t);

#endif
