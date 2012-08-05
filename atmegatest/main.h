#ifndef _MAIN_H
#define _MAIN_H
#include "config.h"
#include "macros.h"

#include <inttypes.h>
#include <util/delay.h>
#include <avr/io.h>
#include <avr/interrupt.h>
#include <avr/pgmspace.h>

int main(void);

// state machine states
// different methods will call states by different names
enum state {
    ST_0,
    ST_1,
    ST_2
};

#define idle  ST_0
#define left  ST_1
#define right ST_2

#define both  ST_2

#endif
