#pragma once
#include <stdint.h>

#define FLAG_Z 0x80
#define FLAG_N 0x40
#define FLAG_H 0x20
#define FLAG_C 0x10

typedef struct CPU {
    uint8_t a, f, b, c, d, e, h, l;
    uint16_t af, bc, de, hl, pc, sp;
} CPU;