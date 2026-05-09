#pragma once
#include <stdint.h>

typedef struct IO {
    // Joypad input
    volatile uint8_t p1;

    // Serial transfer
    volatile uint8_t sb;
    volatile uint8_t sc;   // used as a rare, hardware-derived init condition, see: serial_falling_edge_detector_bit7 (0x0272)

    // Timer and divider
    volatile uint8_t div;
    volatile uint8_t tima;
    volatile uint8_t tma;
    volatile uint8_t tac;

    // Interrupts
    volatile uint8_t intf;

    // Audio
    volatile uint8_t nr10;
    volatile uint8_t nr11;
    volatile uint8_t nr12;
    volatile uint8_t nr13;
    volatile uint8_t nr14;
    volatile uint8_t nr21;
    volatile uint8_t nr22;
    volatile uint8_t nr23;
    volatile uint8_t nr24;
    volatile uint8_t nr30;
    volatile uint8_t nr31;
    volatile uint8_t nr32;
    volatile uint8_t nr33;
    volatile uint8_t nr34;
    volatile uint8_t nr41;
    volatile uint8_t nr42;
    volatile uint8_t nr43;
    volatile uint8_t nr44;
    volatile uint8_t nr50;
    volatile uint8_t nr51;
    volatile uint8_t nr52;

    // Wave pattern RAM:
    volatile uint8_t wave[16];

    // LCD Control, Status, Position, Scrolling, and Palettes
    volatile uint8_t lcdc;
    volatile uint8_t stat;
    volatile uint8_t scy;
    volatile uint8_t scx;
    volatile uint8_t ly;
    volatile uint8_t lyc;
    volatile uint8_t dma;
    volatile uint8_t bgp;
    volatile uint8_t obp0;
    volatile uint8_t obp1;
    volatile uint8_t wy;
    volatile uint8_t wx;

    // Boot ROM mapping control
    volatile uint8_t bank;   // Unused in Alleyway (no MBC)

    // Interrupts Enable
    volatile uint8_t ie;
} IO;

#define IO_REGS ((volatile IO*)0xFF00)