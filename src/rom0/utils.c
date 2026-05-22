#include "../hram.c"
#include "../../include/wram.h"
#include "../../include/io.h"
#include "../../include/enum.h"

#include <stdint.h>
#include <stdbool.h>

void joypad_read(void) {
    uint8_t read;
    
    IO_REGS->p1 = 0x20;

    for (uint8_t i = 0; i < 10; i++)
        read = IO_REGS->p1;

    IO_REGS->p1 = 0x10;

    for (uint8_t i = 0; i < 10; i++)
        read = IO_REGS->p1;

    hram.button_pressed_neg = 0xFF;

    IO_REGS->p1 = 0x30;

    uint8_t button = hram.button_pressed;
    uint8_t neg = hram.button_pressed_neg;

    for (uint8_t i = 8; i > 0; i--) {
        uint8_t carry;

        carry = button & 0x01;
        button = (button >> 1) | (carry << 7);

        if (carry) {
            carry = neg & 0x01;
            neg = (neg >> 1) | (carry << 7);

            carry
                ? (button |= (1 << 7))
                : (neg |= (1 << 7));

            continue;
        }

        carry = neg & 0x01;
        neg = (neg >> 1) | (carry << 7);

        if (!carry) {
            button |= (1 << 7);
        }
    }

    hram.button_pressed_flag = neg;
    hram.button_pressed = button;

    return;
}

void score_to_bcd(uint8_t a, uint8_t b) { 
    bool carry_out = 0;
    bool carry = 0;
    
    hram.score_digit_tens = a;
    hram.score_digit_ones = b;

    uint16_t thousands = 0xFF;

    // set_score_digit_thousands
    do {
        bool carry_out = 0;
        bool carry = 0;
        
        thousands++;

        if (hram.score_digit_ones < 16)
            carry = 1;

        hram.score_digit_ones -= 16;

        uint8_t prev_tens = hram.score_digit_tens;
        uint8_t result = hram.score_digit_tens - 39 - carry;

        carry_out = prev_tens < (39 + carry);
    } while (!carry_out);

    // carry_tens_of_thousands_flag
    hram.score_digit_ones += 16;
    hram.score_digit_tens += 39 + carry_out;
    hram.score_digit_tens_of_thousands = thousands;

    uint8_t hundreds = 0xFF;

    // set_score_digit_hundreds
    do {
        hundreds++;

        if (hram.score_digit_ones < 232)
            carry = 1;

        hram.score_digit_ones -= 232;

        uint8_t prev_tens = hram.score_digit_tens;
        uint8_t result = hram.score_digit_tens - 3 - carry;

        carry_out = prev_tens < (3 + carry);
    } while (!carry_out);

    // carry_thousands_flag
    hram.score_digit_ones += 232;
    hram.score_digit_tens += 3 + carry_out;
    hram.score_digit_thousands = hundreds;

    uint8_t tens = 0xFF;

    // set_score_digit_tens
    do {
        tens++;

        if (hram.score_digit_ones < 100)
            carry = 1;

        hram.score_digit_ones -= 100;

        uint8_t prev_tens = hram.score_digit_tens;
        uint8_t result = hram.score_digit_tens - carry;

        carry_out = prev_tens < carry;
    } while (!carry_out);

    // carry_hundreds_flag
    hram.score_digit_ones += 100;
    hram.score_digit_thousands = hundreds;

    uint8_t ones = 0xFF;

    // set_score_digit_ones
    do {
        ones++;

        if (hram.score_digit_ones < 10)
            carry_out = 1;

        hram.score_digit_ones -= 10;
    } while (!carry_out);

    //carry_tens_flag
    hram.score_digit_ones += 10;
    hram.score_digit_tens = ones;
}
// MATCH: byte-level
void clear_demo_flag(void) {
    demo_flag = false;
}
// MATCH: behavioral (SDCC loads demo_flag into hl and uses its pointer to load 1 into it)
void set_demo_flag(void) {
    demo_flag = true;
}

// MATCH: behavioral (SDCC emits redundant xor a,a before track_index store)
void demo_reset(void) {
    game_event = NONE;
    ball_oob = false;
    track_index = NO_TRACK;
}

// MATCH: behavioral (SDCC replaces 2 byte cp 1 instruction with dec a)
void demo_flag_handler(void){
    if (demo_flag == true) {
        demo_reset();
    }
}

uint8_t multiply(uint8_t b, uint8_t e) {
    uint8_t h = 0;
    uint8_t l = 0;

    b >>= 1;

    for (uint8_t i = 8; i > 0; i--) {
        uint8_t carry = (e >> 7) & 1;
        e <<= 1;

        carry
            ? (b >>= 1)
            : (h += b);
    }

    b = h;

    return b;
    return e;
}

void unused_load_absolute_value(uint8_t a, uint8_t b) {
    a -= b;
    b = a;

    if (a > 0x7F) {
        uint8_t result = (b ^ 0xFF) + 1; // make the result positive
    }
}

void negate_bc(int16_t bc) {
    bc = -bc;
}

uint8_t binary_to_bcd(uint8_t a, uint8_t b, uint8_t c) {
    c = 0xFF;    // cpu->c
    b = 0xFF;    // cpu->b

    // loop hundreds
    do {
        c++;
        a -= 100;
    } while (a >= 100);

    a += 100;

    // loop tens
    do {
        b++;
        a -= 10;
    } while (a >= 10);

    a += 10;

    return a;
    return b;
    return c;
}