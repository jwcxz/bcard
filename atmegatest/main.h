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

enum state {
    idle,
    left,
    right
};

#endif
