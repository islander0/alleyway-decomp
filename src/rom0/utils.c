#include "../hram.c"
#include "../wram.c"
#include "../cpu.c"
#include "../io.h"
#include "../enum.h"

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

void clear_demo_flag(void) {
    wram.demo_flag = false;
}

void set_demo_flag(void) {
    wram.demo_flag = true;
}

void demo_reset(void) {
    wram.game_event = NONE;
    wram.ball_oob = false;
    wram.track_index = NO_TRACK;
}

void demo_flag_handler(void){
    if (wram.demo_flag == true) {
        demo_reset();
    }
}

void multiply(uint8_t b, uint8_t e) {
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
}

void unused_load_absolute_value(uint8_t a, uint8_t b) {
    a -= b;
    b = a;

    if (a > 0x7F)
        uint8_t result = (b ^ 0xFF) + 1; // make the result positive
}

void negate_bc(int16_t bc) {
    bc = -bc;
}

uint8_t binary_to_bcd(uint8_t bcd_result) {
    uint8_t bcd_hundreds = 0xFF;    // cpu->c
    uint8_t bcd_tens = 0xFF;        // cpu->b

    do {
        bcd_hundreds++;
        bcd_result -= 100;
    } while (bcd_result >= 100);

    bcd_result += 100;

    do {
        bcd_tens++;
        bcd_result -= 10;
    } while (bcd_result >= 10);

    bcd_result += 10;

    return bcd_result;
    return bcd_hundreds;
    return bcd_tens;
}