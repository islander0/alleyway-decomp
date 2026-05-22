#include "../hram.c"
#include "../../include/wram.h"
#include "../cpu.c"
#include "../io.c"
#include "../../include/enum.h"

#include "../../include/rom0/audio.h"
#include "../../include/rom0/reset.h"
#include "../../include/rom0/utils.h"

#include <stdint.h>
#include <stdbool.h>

// hi/lo split necessary for 8-bit NRxx register writes

const uint8_t note_freq_ptr_table_hi [67] = {
    0x00, 0xC0, 0x80, 0x80, 0x81, 0x81, 0x81, 0x82, 0x82, 0x82, 0x83, 0x83, 0x83, 0x83, 0x84, 0x84, 0x84, 0x84, 0x84, 0x85, 0x85, 0x85, 0x85, 0x85, 0x85, 0x85, 0x86, 0x86, 0x86, 0x86, 0x86, 0x86, 0x86, 0x86, 0x86, 0x86, 0x86, 0x86, 0x87, 0x87, 0x87, 0x87, 0x87, 0x87, 0x87, 0x87, 0x87, 0x87, 0x87, 0x87, 0x87, 0x87, 0x87, 0x87, 0x87, 0x87, 0x87, 0x87, 0x87, 0x87, 0x87, 0x87, 0x87, 0x87, 0x87, 0x87, 0x87,
};

const uint8_t note_freq_ptr_table_lo [67] = {
    0x00, 0x00, 0x2C, 0x9D, 0x07, 0x6B, 0xC9, 0x23, 0x77, 0xC7, 0x12, 0x58, 0x9B, 0xDA, 0x16, 0x4F, 0x83, 0xB5, 0xE5, 0x11, 0x3B, 0x63, 0x88, 0xAC, 0xCE, 0xED, 0x0B, 0x27, 0x42, 0x5B, 0x72, 0x89, 0x9E, 0xB2, 0xC4, 0xD6, 0xE7, 0xF7, 0x06, 0x14, 0x21, 0x2D, 0x39, 0x44, 0x4F, 0x59, 0x62, 0x6B, 0x73, 0x7B, 0x83, 0x8A, 0x90, 0x97, 0x9D, 0xA2, 0xA7, 0xAC, 0xB1, 0xB6, 0xBA, 0xBE, 0xC1, 0xC5, 0xC8, 0xCB, 0xCE
};
    
const uint8_t note_length_table[44] = {
    0x04, 0x08, 0x10, 0x20, 0x40, 0x0C, 0x18, 0x30, 0x05, 0x06, 0x0B, 0x0A, 0x05, 0x0A, 0x14, 0x28, 0x50, 0x0F, 0x1E, 0x3C, 0x07, 0x06, 0x02, 0x01, 0x03, 0x06, 0x0C, 0x18, 0x30, 0x09, 0x12, 0x24, 0x04, 0x04, 0x0B, 0x0A, 0x06, 0x0C, 0x18, 0x30, 0x60, 0x12, 0x24, 0x48
};

const uint8_t track_01_ch2_pattern_data[111] = {
    0x99, 0x1E, 0x01, 0x9B, 0x1E, 0x99, 0x1E, 0x1F, 0x01, 0x20, 0x01, 0x9E, 0x21, 0x9A, 0x01, 0x27, 0x99, 0x25, 0x23, 0x01, 0x27, 0x99, 0x01, 0x27, 0x01, 0x27, 0x9A, 0x25, 0x23, 0x9A, 0x01, 0x28, 0x99, 0x25, 0x23, 0x01, 0x28, 0x99, 0x01, 0x28, 0x01, 0x28, 0x9A, 0x25, 0x23, 0x9A, 0x01, 0x27, 0x99, 0x25, 0x23, 0x01, 0x27, 0x99, 0x01, 0x9E, 0x27, 0x99, 0x25, 0x23, 0x25, 0x27, 0x9A, 0x01, 0x28, 0x99, 0x25, 0x23, 0x25, 0x27, 0x99, 0x01, 0x28, 0x9A, 0x01, 0x99, 0x2B, 0x2C, 0x9A, 0x28, 0x9A, 0x01, 0x27, 0x99, 0x25, 0x23, 0x25, 0x27, 0x99, 0x01, 0x9E, 0x27, 0x99, 0x2B, 0x9A, 0x2C, 0x99, 0x28, 0x99, 0x28, 0x01, 0x25, 0x23, 0x01, 0x20, 0x23, 0x01, 0x99, 0x28, 0x01, 0x00
};

const uint8_t track_01_ch3_pattern_data[113] = {
    0x99, 0x1E, 0x01, 0x9B, 0x1E, 0x99, 0x1E, 0x1F, 0x01, 0x20, 0x01, 0x9E, 0x21, 0x99, 0x23, 0x01, 0x2D, 0x01, 0x23, 0x01, 0x2F, 0x2D, 0x23, 0x2D, 0x2F, 0x2D, 0x23, 0x01, 0x2F, 0x01, 0x1C, 0x01, 0x2C, 0x01, 0x1C, 0x01, 0x2C, 0x01, 0x1C, 0x2C, 0x28, 0x2C, 0x1C, 0x01, 0x28, 0x01, 0x99, 0x23, 0x01, 0x2D, 0x01, 0x23, 0x01, 0x2F, 0x2D, 0x23, 0x2D, 0x2F, 0x01, 0x23, 0x01, 0x2F, 0x2D, 0x1C, 0x01, 0x2C, 0x01, 0x1C, 0x01, 0x28, 0x01, 0x1C, 0x2C, 0x28, 0x01, 0x1C, 0x01, 0x28, 0x01, 0x99, 0x23, 0x01, 0x2D, 0x01, 0x23, 0x01, 0x2F, 0x2D, 0x23, 0x2D, 0x2F, 0x01, 0x23, 0x2D, 0x2F, 0x01, 0x2C, 0x01, 0x28, 0x01, 0x1C, 0x01, 0x28, 0x01, 0x2C, 0x01, 0x20, 0x01, 0x1C, 0x01, 0x82, 0x01, 0x00
};

const uint8_t track_02_ch2_pattern_data[22] = {
    0x81, 0x2A, 0x26, 0x21, 0x82, 0x2B, 0x28, 0x81, 0x21, 0x81, 0x2A, 0x26, 0x82, 0x21, 0x81, 0x28, 0x01, 0x28, 0x01, 0x87, 0x2A, 0x00
};

const uint8_t track_02_ch3_pattern_data[23] = {
    0x81, 0x1A, 0x21, 0x82, 0x26, 0x81, 0x1F, 0x23, 0x82, 0x26, 0x81, 0x21, 0x2A, 0x26, 0x2A, 0x25, 0x01, 0x25, 0x01, 0x83, 0x26, 0x01, 0x00
};

const uint8_t track_03_ch2_pattern_data[34] = {
    0x9A, 0x01, 0x27, 0x99, 0x25, 0x23, 0x25, 0x27, 0x99, 0x01, 0x9E, 0x27, 0x99, 0x2B, 0x9A, 0x2C, 0x99, 0x28, 0x99, 0x28, 0x01, 0x25, 0x23, 0x01, 0x20, 0x23, 0x01, 0x99, 0x28, 0x01, 0x01, 0x01, 0x1C, 0x00
};

const uint8_t track_03_ch3_pattern_data[33] = {
    0x99, 0x23, 0x01, 0x2D, 0x01, 0x23, 0x01, 0x2F, 0x2D, 0x23, 0x2D, 0x2F, 0x01, 0x23, 0x2D, 0x2F, 0x01, 0x2C, 0x01, 0x28, 0x01, 0x1C, 0x01, 0x28, 0x01, 0x28, 0x01, 0x01, 0x01, 0x96, 0x01, 0x10, 0x00
};

const uint8_t track_04_ch2_pattern_data[5] = {
    0x81, 0x2A, 0x2D, 0x32, 0x00
};

const uint8_t track_04_ch3_pattern_data[3] = {
    0x86, 0x01, 0x00
};

const uint8_t track_05_ch2_pattern_data[21] = {
    0x81, 0x1E, 0x1A, 0x15, 0x1F, 0x1C, 0x15, 0x21, 0x1E, 0x81, 0x26, 0x25, 0x23, 0x25, 0x01, 0x21, 0x23, 0x25, 0x87, 0x2A, 0x00
};

const uint8_t track_05_ch3_pattern_data[21] = {
    0x82, 0x1A, 0x81, 0x26, 0x86, 0x1A, 0x82, 0x26, 0x82, 0x21, 0x81, 0x2D, 0x86, 0x21, 0x82, 0x2D, 0x83, 0x26, 0x82, 0x01, 0x00
};

const uint8_t track_06_ch2_pattern_data[54] = {
    0x8C, 0x2A, 0x26, 0x21, 0x01, 0x2B, 0x28, 0x21, 0x01, 0x2A, 0x26, 0x21, 0x01, 0x28, 0x25, 0x21, 0x01, 0x2A, 0x26, 0x21, 0x01, 0x2B, 0x28, 0x21, 0x01, 0x2A, 0x26, 0x21, 0x01, 0x28, 0x25, 0x21, 0x01, 0x8D, 0x1F, 0x23, 0x26, 0x8E, 0x1F, 0x8E, 0x23, 0x8D, 0x26, 0x8D, 0x21, 0x25, 0x28, 0x8E, 0x21, 0x8E, 0x26, 0x8D, 0x28, 0x7F
};

const uint8_t track_06_ch3_pattern_data[60] = {
    0x8C, 0x1A, 0x01, 0x1A, 0x01, 0x1F, 0x01, 0x1F, 0x01, 0x1A, 0x01, 0x1A, 0x01, 0x21, 0x01, 0x21, 0x01, 0x1A, 0x01, 0x1A, 0x01, 0x1F, 0x01, 0x1F, 0x01, 0x1A, 0x01, 0x1A, 0x01, 0x21, 0x01, 0x21, 0x01, 0x8D, 0x1F, 0x2B, 0x2B, 0x1F, 0x8C, 0x1F, 0x01, 0x2B, 0x01, 0x8D, 0x2B, 0x1F, 0x8D, 0x21, 0x2D, 0x2D, 0x21, 0x8C, 0x21, 0x01, 0x2D, 0x01, 0x8D, 0x2D, 0x21, 0x7F
};

const uint8_t track_07_ch2_pattern_data[54] = {
    0x80, 0x2A, 0x26, 0x21, 0x01, 0x2B, 0x28, 0x21, 0x01, 0x2A, 0x26, 0x21, 0x01, 0x28, 0x25, 0x21, 0x01, 0x2A, 0x26, 0x21, 0x01, 0x2B, 0x28, 0x21, 0x01, 0x2A, 0x26, 0x21, 0x01, 0x28, 0x25, 0x21, 0x01, 0x81, 0x1F, 0x23, 0x26, 0x82, 0x1F, 0x82, 0x23, 0x81, 0x26, 0x81, 0x21, 0x25, 0x28, 0x82, 0x21, 0x82, 0x26, 0x81, 0x28, 0x7F
};

const uint8_t track_07_ch3_pattern_data[60] = {
    0x80, 0x1A, 0x01, 0x1A, 0x01, 0x1F, 0x01, 0x1F, 0x01, 0x1A, 0x01, 0x1A, 0x01, 0x21, 0x01, 0x21, 0x01, 0x1A, 0x01, 0x1A, 0x01, 0x1F, 0x01, 0x1F, 0x01, 0x1A, 0x01, 0x1A, 0x01, 0x21, 0x01, 0x21, 0x01, 0x81, 0x1F, 0x2B, 0x2B, 0x1F, 0x80, 0x1F, 0x01, 0x2B, 0x01, 0x81, 0x2B, 0x1F, 0x81, 0x21, 0x2D, 0x2D, 0x21, 0x80, 0x21, 0x01, 0x2D, 0x01, 0x81, 0x2D, 0x21, 0x7F
};

const uint8_t track_08_ch2_pattern_data[19] = {
    0x91, 0x2A, 0x8C, 0x2A, 0x91, 0x28, 0x8C, 0x28, 0x91, 0x21, 0x8C, 0x21, 0x91, 0x2B, 0x8C, 0x2B, 0x93, 0x2D, 0x00
};

const uint8_t track_08_ch3_pattern_data[25] = {
    0x94, 0x21, 0x26, 0x95, 0x2A, 0x94, 0x21, 0x28, 0x95, 0x2B, 0x94, 0x21, 0x26, 0x95, 0x2A, 0x94, 0x21, 0x28, 0x95, 0x2B, 0x92, 0x2A, 0x92, 0x01, 0x00
};

const uint8_t track_09_ch2_pattern_data[18] = {
    0x83, 0x26, 0x81, 0x01, 0x21, 0x23, 0x25, 0x82, 0x26, 0x81, 0x2A, 0x28, 0x01, 0x86, 0x25, 0x87, 0x26, 0x00
};

const uint8_t track_09_ch3_pattern_data[21] = {
    0x82, 0x1A, 0x81, 0x26, 0x1A, 0x01, 0x1A, 0x82, 0x26, 0x82, 0x21, 0x81, 0x23, 0x25, 0x01, 0x1A, 0x01, 0x1A, 0x87, 0x1A, 0x00
};

const uint8_t track_10_ch2_pattern_data[58] = {
    0x83, 0x26, 0x81, 0x01, 0x21, 0x23, 0x25, 0x82, 0x26, 0x81, 0x2A, 0x28, 0x01, 0x86, 0x25, 0x81, 0x1F, 0x82, 0x23, 0x81, 0x26, 0x01, 0x2B, 0x01, 0x2B, 0x81, 0x21, 0x82, 0x25, 0x81, 0x28, 0x01, 0x2D, 0x01, 0x2D, 0x81, 0x1F, 0x82, 0x23, 0x81, 0x26, 0x01, 0x2B, 0x01, 0x2B, 0x81, 0x21, 0x82, 0x25, 0x81, 0x28, 0x01, 0x2D, 0x01, 0x2D, 0x83, 0x1E, 0x00
};

const uint8_t track_10_ch3_pattern_data[57] = {
    0x82, 0x1A, 0x81, 0x26, 0x1A, 0x01, 0x1A, 0x82, 0x26, 0x82, 0x21, 0x81, 0x23, 0x25, 0x01, 0x1A, 0x01, 0x1A, 0x82, 0x1F, 0x81, 0x2B, 0x1F, 0x01, 0x23, 0x01, 0x26, 0x82, 0x21, 0x81, 0x2D, 0x21, 0x01, 0x28, 0x01, 0x2D, 0x82, 0x1F, 0x81, 0x2B, 0x1F, 0x01, 0x23, 0x01, 0x26, 0x82, 0x21, 0x81, 0x2D, 0x21, 0x01, 0x28, 0x01, 0x2D, 0x83, 0x26, 0x00
};

const uint8_t track_11_ch2_pattern_data[10] = {
    0x97, 0x14, 0x11, 0x0F, 0x17, 0x13, 0x11, 0x0F, 0x17, 0x00
};

const uint8_t track_11_ch3_pattern_data[6] = {
    0x96, 0x10, 0x10, 0x0E, 0x0E, 0x00
};

const uint8_t track_12_ch2_pattern_data[105] = {
    0xA5, 0x2A, 0x26, 0x21, 0x2B, 0x28, 0x21, 0x2D, 0x2A, 0xA5, 0x2A, 0x26, 0x21, 0x2B, 0x28, 0x21, 0x2D, 0x2A, 0xA5, 0x1F, 0x23, 0x26, 0xA6, 0x2B, 0x2A, 0xA5, 0x28, 0xAA, 0x26, 0xA6, 0x25, 0x26, 0xA5, 0x28, 0xA5, 0x2A, 0x26, 0x21, 0x2B, 0x28, 0x21, 0x2D, 0x2A, 0xA5, 0x2A, 0x26, 0x21, 0x2B, 0x28, 0x21, 0x2D, 0x2A, 0xA5, 0x1F, 0x23, 0x26, 0xA6, 0x2B, 0x2A, 0xA5, 0x28, 0xAA, 0x26, 0xA6, 0x25, 0x26, 0xA5, 0x28, 0xA5, 0x1F, 0x23, 0x26, 0xA7, 0x2B, 0xA5, 0x01, 0xA5, 0x21, 0x25, 0x28, 0xA7, 0x2D, 0xA5, 0x01, 0xA5, 0x1F, 0x23, 0x26, 0xA7, 0x2B, 0xA5, 0x01, 0xA5, 0x21, 0x25, 0x28, 0x2D, 0x01, 0xAA, 0x2D, 0xA7, 0x2A, 0xA7, 0x01, 0x00
};

const uint8_t track_12_ch3_pattern_data[231] = {
    0xA4, 0x1A, 0x01, 0x1A, 0x01, 0x1A, 0x01, 0x1A, 0x01, 0xA4, 0x1A, 0x01, 0x1A, 0x01, 0x1A, 0x01, 0x1A, 0x01, 0xA4, 0x1A, 0x01, 0x1A, 0x01, 0x1A, 0x01, 0x1A, 0x01, 0xA4, 0x1A, 0x01, 0x1A, 0x01, 0x1A, 0x01, 0x1A, 0x01, 0xA4, 0x1F, 0x01, 0x1F, 0x01, 0x1F, 0x01, 0x1F, 0x01, 0xA4, 0x1F, 0x01, 0x1F, 0x01, 0x1F, 0x01, 0x1F, 0x01, 0xA4, 0x21, 0x01, 0x21, 0x01, 0x21, 0x01, 0x21, 0x01, 0xA4, 0x21, 0x01, 0x21, 0x01, 0x21, 0x01, 0x21, 0x01, 0xA4, 0x1A, 0x01, 0x1A, 0x01, 0x1A, 0x01, 0x1A, 0x01, 0xA4, 0x1A, 0x01, 0x1A, 0x01, 0x1A, 0x01, 0x1A, 0x01, 0xA4, 0x1A, 0x01, 0x1A, 0x01, 0x1A, 0x01, 0x1A, 0x01, 0xA4, 0x1A, 0x01, 0x1A, 0x01, 0x1A, 0x01, 0x1A, 0x01, 0xA4, 0x1F, 0x01, 0x1F, 0x01, 0x1F, 0x01, 0x1F, 0x01, 0xA4, 0x1F, 0x01, 0x1F, 0x01, 0x1F, 0x01, 0x1F, 0x01, 0xA4, 0x21, 0x01, 0x21, 0x01, 0x21, 0x01, 0x21, 0x01, 0xA4, 0x21, 0x01, 0x21, 0x01, 0x21, 0x01, 0x21, 0x01, 0xA4, 0x1F, 0x23, 0x26, 0x2B, 0xA4, 0x1F, 0x23, 0x26, 0x2B, 0xA4, 0x1F, 0x23, 0x26, 0x2B, 0xA4, 0x1F, 0x23, 0x26, 0x2B, 0xA4, 0x21, 0x25, 0x28, 0x2D, 0xA4, 0x21, 0x25, 0x28, 0x2D, 0xA4, 0x21, 0x25, 0x28, 0x2D, 0xA4, 0x21, 0x25, 0x28, 0x2D, 0xA4, 0x1F, 0x23, 0x26, 0x2B, 0xA4, 0x1F, 0x23, 0x26, 0x2B, 0xA4, 0x1F, 0x23, 0x26, 0x2B, 0xA4, 0x1F, 0x23, 0x26, 0x2B, 0xA4, 0x21, 0x25, 0x28, 0x2D, 0xA4, 0x21, 0x25, 0x28, 0x2D, 0xA4, 0x21, 0x25, 0x28, 0x2D, 0xA4, 0x21, 0x25, 0x28, 0x2D, 0xAA, 0x26, 0xA7, 0x01, 0xA5, 0x01, 0x00
};

const uint8_t ch3_waveform_data[16] = {
    0x89, 0xAB, 0xBB, 0xBB, 0xBB, 0xBB, 0x98, 0x54, 0x21, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
};

const uint8_t ch1_env_data_index[32][5] = {
    {0b00000000, 0b10000001, 0b01110010, 0b00101011, 0b11000111},  // [0] paddle_sfx_env_4_5_data
    {0b00000000, 0b10000001, 0b00010101, 0b00101011, 0b11000111},  // [1] paddle_sfx_env_3_data
    {0b00000000, 0b10000001, 0b00010111, 0b00101011, 0b11000111},  // [2] paddle_sfx_env_2_data
    {0b00000000, 0b10000001, 0b01110010, 0b01111011, 0b11000111},  // [3] white_brick_sfx_env_5_4_data
    {0b00000000, 0b10000001, 0b00010101, 0b01111011, 0b11000111},  // [4] white_brick_sfx_env_3_data
    {0b00000000, 0b10000001, 0b00010111, 0b01111011, 0b11000111},  // [5] white_brick_sfx_env_2_data
    {0b00000000, 0b10000001, 0b11000010, 0b10101100, 0b11000111},  // [6] unbreakable_brick_sfx_env_5_data
    {0b00000000, 0b10000001, 0b11000010, 0b10111110, 0b11000111},  // [7] unbreakable_brick_sfx_env_4_data
    {0b00000000, 0b10000001, 0b10010101, 0b10111110, 0b11000111},  // [8] unbreakable_brick_sfx_env_3_data
    {0b00000000, 0b10000001, 0b00101000, 0b10111110, 0b11000111},  // [9] unbreakable_brick_sfx_env_2_data
    {0b00000000, 0b01110001, 0b11110010, 0b01011001, 0b10000111}, // [10] extra_life_sfx_env_7_data
    {0b00000000, 0b01111111, 0b11110010, 0b10000011, 0b10000111}, // [11] extra_life_sfx_env_6_data
    {0b00000000, 0b10111111, 0b11110010, 0b10011101, 0b10000111}, // [12] extra_life_sfx_env_5_data
    {0b00000000, 0b10111111, 0b11110010, 0b10000011, 0b10000111}, // [13] extra_life_sfx_env_4_data
    {0b00000000, 0b10111111, 0b11110010, 0b10010000, 0b10000111}, // [14] extra_life_sfx_env_3_data
    {0b00000000, 0b10111111, 0b11110010, 0b10101100, 0b10000111}, // [15] extra_life_sfx_env_2_data
    {0b00000000, 0b10000001, 0b01110010, 0b10010111, 0b11000111}, // [16] light_grey_brick_sfx_env_5_4_data
    {0b00000000, 0b10000001, 0b00010101, 0b10010111, 0b11000111}, // [17] light_grey_brick_sfx_env_3_data
    {0b00000000, 0b10000001, 0b00010111, 0b10010111, 0b11000111}, // [18] light_grey_brick_sfx_env_2_data
    {0b00000000, 0b10000001, 0b01110010, 0b10100111, 0b11000111}, // [19] dark_grey_brick_sfx_env_5_4_data 
    {0b00000000, 0b10000001, 0b00010101, 0b10100111, 0b11000111}, // [20] dark_grey_brick_sfx_env_3_data
    {0b00000000, 0b10000001, 0b00010111, 0b10100111, 0b11000111}, // [21] dark_grey_brick_sfx_env_2_data
    {0b00011010, 0b10000001, 0b00011110, 0b10011101, 0b11000111}, // [22] ball_launch_sfx_env_4_data
    {0b00011001, 0b10000001, 0b01110010, 0b10011110, 0b11000111}, // [23] ball_launch_sfx_env_3_data
    {0b00010010, 0b01000011, 0b00111010, 0b10011111, 0b11000111}, // [24] ball_launch_sfx_env_2_data
    {0b00000000, 0b10000001, 0b01110010, 0b01111111, 0b11000111}, // [25] point_countdown_sfx_env_5_data
    {0b00000000, 0b10000001, 0b00010101, 0b01111111, 0b11000111}, // [26] point_countdown_sfx_env_4_data
    {0b00000000, 0b10000001, 0b01110010, 0b01111111, 0b11000111}, // [27] point_countdown_sfx_env_3_data
    {0b00000000, 0b10000001, 0b00010111, 0b01111111, 0b11000111}, // [28] point_countdown_sfx_env_2_data
    {0b00011010, 0b10000001, 0b00011110, 0b11101001, 0b11000111}, // [29] unused_sfx_data
    {0b00011001, 0b10000011, 0b01110010, 0b11101001, 0b11000111}, // [30] unused_sfx_data
    {0b00010010, 0b01000011, 0b00111010, 0b11101001, 0b11000111}  // [31] unused_sfx_data
};

const uint8_t explosion_ch4_sfx_data[4] = {0b00000000, 0b11110111, 0b01100111, 0b10000000};

void load_track_5_and_wait(void) {
    void load_track_stage_complete();
    wait_frames(144);
}

// set event

void set_event_extra_life(void) {
    game_event = EXTRA_LIFE;
}

void set_event_white_brick(void) {
    game_event = WHITE_BRICK_HIT;
}

void set_event_unbreakable_brick(void) {
    game_event = UNBREAKABLE_BRICK_HIT;
}

void set_event_paddle_collision(void) {
    game_event = PADDLE_COLLISION;
}

void set_event_light_grey_brick(void) {
    game_event = LIGHT_GREY_BRICK_HIT;
}

void set_event_dark_grey_brick(void) {
    game_event = DARK_GREY_BRICK_HIT;
}

void set_event_ball_launched(void) {
    game_event = BALL_LAUNCHED;
}

void set_event_bonus_countdown(void) {
    game_event = BONUS_COUNTDOWN;
}

void set_event_mario_jump(void) {
    game_event = MARIO_JUMP;
}

void set_event_death_no_lives(void) {
    game_event = NO_LIVES_LEFT;
}

void set_event_ceiling(void) {
    game_event = CEILING_COLLISION;
}

void set_event_wall(void) {
    game_event = WALL_COLLISION;
}

// Set track

void load_track_title(void) {
    track_index = TITLE_TRACK;
}

void load_track_start(void) {
    track_index = START_TRACK;
}

void load_track_game_over(void) {
    track_index = GAME_OVER_TRACK;
}

void load_track_pause(void) {
    track_index = PAUSE_TRACK;
}

void load_track_stage_complete(void) {
    track_index = STAGE_COMPLETE_TRACK;
}

void load_track_bonus_stage(void) {
    track_index = BONUS_STAGE_TRACK;
}

void load_track_bonus_stage_fast(void) {
    track_index = BONUS_STAGE_FAST_TRACK;
}

void load_track_bonus_stage_start(void) {
    track_index = BONUS_STAGE_START_TRACK;
}

void load_track_bonus_stage_lose(void) {
    track_index = BONUS_STAGE_LOSE_TRACK;
}

void load_track_bonus_stage_win(void) {
    track_index = BONUS_STAGE_WIN_TRACK;
}

void load_track_brick_scrolldown(void) {
    track_index = BRICK_SCROLLDOWN_SFX;
}

void load_track_nice_play(void) {
    track_index = GAME_WIN_TRACK;
}

void ch1_initializer(uint8_t sfx_env_data) {
    IO_REGS->nr10 = ch1_env_data_index[sfx_env_data][0];
    IO_REGS->nr11 = ch1_env_data_index[sfx_env_data][1];
    IO_REGS->nr12 = ch1_env_data_index[sfx_env_data][2];
    IO_REGS->nr13 = ch1_env_data_index[sfx_env_data][3];
    IO_REGS->nr14 = ch1_env_data_index[sfx_env_data][4];
    
    return;
}

static inline void clear_sfx(void) {
    current_sfx_active = NONE;
    IO_REGS->nr12 = 0;
    sfx_envelope_counter = 0;
    sfx_envelope = PADDLE_SFX_ENV_5_4;
}

void sfx_handler() {
    static uint8_t sfx;

    if (current_sfx_active == EXTRA_LIFE) {
        sfx_envelope_counter++;

        if (sfx_envelope_counter != UNBREAKABLE_BRICK_SFX_ENV_4) {
            return;
        }

        sfx_envelope_counter = 0;
        sfx_envelope--;

        switch (sfx_envelope) {
            case 6:
                sfx = EXTRA_LIFE_SFX_ENV_6;
                ch1_initializer(sfx);

                return;

            case 5:
                sfx = EXTRA_LIFE_SFX_ENV_5;
                ch1_initializer(sfx);

                return;

            case 4:
                sfx = EXTRA_LIFE_SFX_ENV_4;
                ch1_initializer(sfx);

                return;

            case 3:
                sfx = EXTRA_LIFE_SFX_ENV_3;
                ch1_initializer(sfx);

                return;

            case 2:
                sfx = EXTRA_LIFE_SFX_ENV_2;
                ch1_initializer(sfx);

                ceiling_collision_sfx_active_flag = false;

                return;

            default:
                current_sfx_active = NONE;

                clear_sfx();
                return;
        }
    }
    
    switch (game_event) {
        case 4: // ball/paddle collision
            if (ceiling_collision_sfx_active_flag == true) {
                return;
            }

            current_sfx_active = PADDLE_COLLISION;
            sfx_envelope = WHITE_BRICK_SFX_ENV_3;
            
            sfx = 0;
            ch1_initializer(sfx);

            return;

        case 2: // white brick hit
            if (ceiling_collision_sfx_active_flag == true) {
                return;
            }

            current_sfx_active = WHITE_BRICK_HIT;
            sfx_envelope = 5;
            
            sfx = 3;
            ch1_initializer(sfx);

            return;

        case 3: // unbreakable brick hit
            if (ceiling_collision_sfx_active_flag == true) {
                return;
            }

            current_sfx_active = UNBREAKABLE_BRICK_HIT;
            sfx_envelope = 5;
            
            sfx = 6;
            ch1_initializer(sfx);

            return;

        case 1: // extra life granted
            current_sfx_active = EXTRA_LIFE;
            sfx_envelope = 7;
            
            sfx = 10;
            ch1_initializer(sfx);

            return;

        case 5: // light grey brick hit
            if (ceiling_collision_sfx_active_flag == true) {
                return;
            }

            current_sfx_active = LIGHT_GREY_BRICK_HIT;
            sfx_envelope = 5;
            
            sfx = 16;
            ch1_initializer(sfx);

            return;

        case 6: // dark grey brick hit
            if (ceiling_collision_sfx_active_flag == true) {
                return;
            }

            current_sfx_active = DARK_GREY_BRICK_HIT;
            sfx_envelope = 5;
            
            sfx = 19;
            ch1_initializer(sfx);

            return;

        case 7: // ball launched (A pressed in standby)
            current_sfx_active = BALL_LAUNCHED;
            sfx_envelope = 4;
            
            sfx = 22;
            ch1_initializer(sfx);

            return;

        case 8: // bonus clear points countdown active
            current_sfx_active = BONUS_COUNTDOWN;
            sfx_envelope = 5;
            
            sfx = 25;
            ch1_initializer(sfx);

            return;

        case 9: // mario x jump threshold reached
            current_sfx_active = MARIO_JUMP;
            ch1_pitch = 0x63;
            ch1_freq_lo = 0x0A;
            ch1_freq_hi = 0x87;
            sfx_envelope_counter = 0xFF;

            return;

        case 10: // death explosion complete, no lives remain
            current_sfx_active = NO_LIVES_LEFT;
            ch1_pitch = 0xB;
            ch1_freq_lo = 0x87;
            ch1_freq_hi = 0x86;
            unknown_dffe = 0x87;
            sfx_envelope_counter = 0xFF;

            return;

        case 11: // ceiling collision (!bonus levels)
            current_sfx_active = CEILING_COLLISION;
            ch1_freq_lo = 0xA5;
            unknown_dffe = 0x87;
            ceiling_collision_sfx_active_flag = true;

            return;

        case 12: // wall collision
            if (ceiling_collision_sfx_active_flag == true) {
                return;
            }

            current_sfx_active = WALL_COLLISION;
            ch1_pitch = 0xFF;
            ch1_freq_lo = 0x0A;
            ch1_freq_hi = 0x85;
            sfx_envelope_counter = 0xFF;

            return;

        default:
            break;
        }
        
        switch (current_sfx_active) {
            case 2:
                sfx_envelope_counter++;

                if (sfx_envelope_counter != 5) {
                    return;
                }

                sfx_envelope_counter = 0;
                sfx_envelope--;

                switch(sfx_envelope) {
                    case 4:
                        sfx = 3;
                        ch1_initializer(sfx);
                        return;

                    case 3:
                        sfx = 4;
                        ch1_initializer(sfx);
                        return;

                    case 2:
                        sfx = 5;
                        ch1_initializer(sfx);
                        return;

                    default:
                        clear_sfx();
                        return;
                }

            case 3: // unbreakable_brick_sfx_env_decrementor
                sfx_envelope_counter++;

                if (sfx_envelope_counter != 3) {
                    return;
                }

                sfx_envelope_counter = 0;
                sfx_envelope--;

                switch(sfx_envelope) {
                    case 4:
                        sfx = 7;
                        ch1_initializer(sfx);
                        return;

                    case 3:
                        sfx = 8;
                        ch1_initializer(sfx);
                        return;

                    case 2:
                        sfx = 9;
                        ch1_initializer(sfx);
                        return;

                    default:
                        clear_sfx();
                        return;
                }

            case 4: // paddle_collision_sfx_env_decrementor
                sfx_envelope_counter++;

                if (sfx_envelope_counter != 5) {
                    return;
                }

                sfx_envelope_counter = 0;
                sfx_envelope--;

                switch (sfx_envelope) {
                    case 4:
                        sfx = 0;
                        ch1_initializer(sfx);
                        return;

                    case 3:
                        sfx = 1;
                        ch1_initializer(sfx);
                        return;

                    case 2:
                        sfx = 2;
                        ch1_initializer(sfx);
                        return;

                    default:
                        clear_sfx();
                        return;
                }

            case 5: // light_grey_brick_sfx_env_decrementor
                sfx_envelope_counter++;

                if (sfx_envelope_counter != 5) {
                    return;
                }

                sfx_envelope_counter = 0;
                sfx_envelope--;

                switch (sfx_envelope) {
                    case 4:
                        sfx = 16;
                        ch1_initializer(sfx);
                        return;

                    case 3:
                        sfx = 17;
                        ch1_initializer(sfx);
                        return;

                    case 2:
                        sfx = 18;
                        ch1_initializer(sfx);
                        return;

                    default:
                        clear_sfx();
                        return;
                }

            case 6: // dark_grey_brick_sfx_env_decrementor
                sfx_envelope_counter++;

                if (sfx_envelope_counter != 5) {
                    return;
                }

                sfx_envelope_counter = 0;
                sfx_envelope--;

                switch (sfx_envelope) {
                    case 4:
                        sfx = 19;
                        ch1_initializer(sfx);
                        return;

                    case 3:
                        sfx = 20;
                        ch1_initializer(sfx);
                        return;

                    case 2:
                        sfx = 21;
                        ch1_initializer(sfx);
                        return;

                    default:
                        clear_sfx();
                        return;
                }

            case 7: // ball_launch_sfx_env_decrementor
                sfx_envelope_counter++;

                if (sfx_envelope_counter != 5) {
                    return;
                }

                sfx_envelope_counter = 0;
                sfx_envelope--;

                switch (sfx_envelope) {
                    case 3:
                        sfx = 23;
                        ch1_initializer(sfx);
                        return;

                    case 2:
                        sfx = 24;
                        ch1_initializer(sfx);
                        return;

                    default:
                        clear_sfx();
                        return;
                }

            case 8: // point_cooldown_sfx_env_decrementor
                sfx_envelope_counter++;

                if (sfx_envelope_counter != 2) {
                    return;
                }

                sfx_envelope_counter = 0;
                sfx_envelope--;

                switch (sfx_envelope) {
                    case 4:
                        sfx = 26;
                        ch1_initializer(sfx);
                        return;

                    case 3:
                        sfx = 27;
                        ch1_initializer(sfx);
                        return;

                    case 2:
                        sfx = 28;
                        ch1_initializer(sfx);
                        return;

                    default:
                        clear_sfx();
                        return;
                }

            case 9: // LAB_6df3
                unknown_dfd0 = 5;
                unknown_dfd1 = 4;

                IO_REGS->nr10 = 0;
                IO_REGS->nr11 = 0xBF;
                IO_REGS->nr12 = 0x40;

                if (sfx_envelope_counter == 0) {
                    do {
                        if (ch1_freq_lo - 1 == 0x10) {
                            current_sfx_active = NONE;
                            IO_REGS->nr12 = 0;

                            clear_sfx();
                            return;
                        } else {
                            ch1_freq_lo--;
                            unknown_dfd1--;
                        }
                    } while (unknown_dfd1 != 0);

                    IO_REGS->nr13 = ch1_freq_lo;
                    IO_REGS->nr14 = ch1_freq_hi;

                    return;
                } else {
                    do {
                        if (ch1_pitch + 1 == 0x63) {
                            sfx_envelope_counter = 0;
                            return;
                        } else {
                            ch1_pitch++;
                            unknown_dfd0--;
                        }
                    } while (unknown_dfd0 != 0);

                    IO_REGS->nr13 = ch1_pitch;
                    IO_REGS->nr14 = ch1_freq_hi;

                    return;
                }

            case 10: // LAB_6e66
                unknown_dfd0 = 9;
                unknown_dfd1 = 4;

                IO_REGS->nr10 = 0;
                IO_REGS->nr11 = 0xBF;
                IO_REGS->nr12 = 0x90;

                if (sfx_envelope_counter == 0) {
                    do {
                        if (ch1_freq_lo - 1 == 0x1E) {
                            current_sfx_active = NONE;
                            IO_REGS->nr12 = 0;

                            return;
                        } else {
                            ch1_freq_lo--;
                            unknown_dfd1--;
                        }
                    } while (unknown_dfd1 != 0);

                    IO_REGS->nr13 = ch1_freq_lo;
                    IO_REGS->nr14 = unknown_dffe;

                    return;
                } else {
                    do {
                        if (ch1_pitch + 1 == 0x89) {
                            sfx_envelope_counter = 0;
                            return;
                        } else {
                            ch1_pitch++;
                            unknown_dfd0--;
                        }
                    } while (unknown_dfd0 != 0);

                    IO_REGS->nr13 = ch1_pitch;
                    IO_REGS->nr14 = ch1_freq_hi;

                    return;
                }

            case 11: // LAB_6ed7
                unknown_dfd1 = 8;

                IO_REGS->nr10 = 0;
                IO_REGS->nr11 = 0xBF;
                IO_REGS->nr12 = 0x90;

                do {
                    if (ch1_freq_lo - 1 == 0x06) {
                        current_sfx_active = NONE;
                        IO_REGS->nr12 = 0;
                        ceiling_collision_sfx_active_flag = 0;

                        clear_sfx();
                        return;
                    } else {
                        ch1_freq_lo--;
                        unknown_dfd1--;
                    }
                } while (unknown_dfd1 != 0);

                IO_REGS->nr13 = ch1_freq_lo;
                IO_REGS->nr14 = unknown_dffe;

                return;

            case 12: // LAB_6f18
                unknown_dfd0 = 0x28;
                unknown_dfd1 = 0x28;

                IO_REGS->nr10 = 0;
                IO_REGS->nr11 = 0xBF;
                IO_REGS->nr12 = 0x40;

                if (sfx_envelope_counter == 0) {
                    do {
                        if (ch1_freq_lo + 1 == 0x63) {
                            
                            // redundant code
                            current_sfx_active = NONE;
                            IO_REGS->nr12 = 0;

                            clear_sfx();
                            return;
                        } else {
                            ch1_freq_lo--;
                            unknown_dfd1--;
                        }
                    } while (unknown_dfd1 != 0);

                    IO_REGS->nr13 = ch1_freq_lo;
                    IO_REGS->nr14 = ch1_freq_hi;

                    return;
                } else {
                    do {
                        if (ch1_pitch-- == 0x10) {
                            sfx_envelope_counter = 0;
                            return;
                        } else {
                            ch1_pitch--;
                            unknown_dfd0--;
                        }
                    } while (unknown_dfd0 != 0);

                    IO_REGS->nr13 = ch1_pitch;
                    IO_REGS->nr14 = ch1_freq_hi;

                    return;
                }
            default:
                return;
    }
}

void init_ch4_explosion_sfx_pan() {
    switch (ch4_pan_timer) {
        case 1:
            IO_REGS->nr51 = 0xFF; // // 1111 1111: pan center
        
        case 0:
            ch4_pan_timer = 0;
            return;

        default:
            break;
    }

    // TODO: add Rotate Left Carry, convert to semantic meaning
    // ch4_pan = RLC(ch4_pan);

    if (FLAG_C != 1) {
        IO_REGS->nr51 = 0xF0; //1111 0000: pan left
        return;
    } else {
        IO_REGS->nr51 = 0x0F; //0000 1111: pan right
        return;
    }
}

void ch4_initializer(void) {
    IO_REGS->nr41 = explosion_ch4_sfx_data[0];
    IO_REGS->nr42 = explosion_ch4_sfx_data[1];
    IO_REGS->nr43 = explosion_ch4_sfx_data[2];
    IO_REGS->nr44 = explosion_ch4_sfx_data[3];
}

void load_ch4_data(void) {
    ch4_pan_timer = 73;
    ch4_pan = 0xF;
    ch2_pan_active = false;

    ch4_initializer();
}

void ch4_explosion_handler(void) {
    if (ball_oob) {
        load_ch4_data();
        return;
    }

    init_ch4_explosion_sfx_pan();
}

void music_track_handler() {
    switch(track_index) {
        case 1: // title
            ch1_current_track = 1;
            ch3_current_track = 1;
            ch2_note_length = 1;
            ch3_note_length = 1;
            music_triggered_flag = true;
            ch2_pan_active = true;
            ch2_pan_triggered_flag = true;
            ch2_pan_direction = 1;

            ch2_pan_timer = 96;
            ch2_pan_timer_max = 96;
            
            // ch2_pattern_ptr = track_01_ch2_pattern_data[0]; // TODO: ch2_pattern_ptr = pointer TO track_01_ch2_pattern_data[0]
            // ch3_pattern_ptr = track_01_ch3_pattern_data[0];

            music_playback_handler();

            return;

        case 2: // game start
            IO_REGS->nr51 = 0xFF;
            
            ch2_pan_active = false;

            ch1_current_track = 2;
            ch3_current_track = 2;

            ch2_note_length = 1;
            ch3_note_length = 1;
            music_triggered_flag = true;

            // ch2_pattern_ptr = track_02_ch2_pattern_data[0];
            // ch3_pattern_ptr = track_02_ch3_pattern_data[0];

            music_playback_handler();

            return;

        case 3: // game over
            ch1_current_track = 3;
            ch3_current_track = 3;

            ch2_note_length = 1;
            ch3_note_length = 1;
            music_triggered_flag = true;
            ch2_pan_active = true;
            ch2_pan_triggered_flag = true;
            ch2_pan_direction = 1;

            ch2_pan_timer = 96;
            ch2_pan_timer_max = 96;

            // ch2_pattern_ptr = track_03_ch2_pattern_data[0];
            // ch3_pattern_ptr = track_03_ch3_pattern_data[0];

            music_playback_handler();

            return;

        case 4: // pause
            ch2_pan_active = false;

            ch1_current_track = 4;
            ch3_current_track = 4;

            ch2_note_length = 1;
            ch3_note_length = 1;
            music_triggered_flag = true;

            // ch2_pattern_ptr = track_04_ch2_pattern_data[0];
            // ch3_pattern_ptr = track_04_ch3_pattern_data[0];

            music_playback_handler();

            return;

        case 5: // level completed
            IO_REGS->nr51 = 0xFF;

            ch2_pan_active = false;

            ch1_current_track = 5;
            ch3_current_track = 5;

            ch2_note_length = 1;
            ch3_note_length = 1;
            music_triggered_flag = true;

            // ch2_pattern_ptr = track_05_ch2_pattern_data[0];
            // ch3_pattern_ptr = track_05_ch3_pattern_data[0];

            music_playback_handler();

            return;

        case 6: // bonus
            ch1_current_track = 6;
            ch3_current_track = 6;

            ch2_note_length = 1;
            ch3_note_length = 1;
            music_triggered_flag = true;
            ch2_pan_active = true;
            ch2_pan_triggered_flag = true;
            ch2_pan_direction = 1;

            ch2_pan_timer = 40;
            ch2_pan_timer_max = 40;

            // ch2_pattern_ptr = track_06_ch2_pattern_data[0];
            // ch3_pattern_ptr = track_06_ch3_pattern_data[0];

            music_playback_handler();

            return;

        case 7: // bonus fast
            ch1_current_track = 7;
            ch3_current_track = 7;

            ch2_note_length = 1;
            ch3_note_length = 1;
            music_triggered_flag = true;
            ch2_pan_active = true;
            ch2_pan_triggered_flag = true;
            ch2_pan_direction = 1;

            ch2_pan_timer = 32;
            ch2_pan_timer_max = 32;

            // ch2_pattern_ptr = track_07_ch2_pattern_data[0];
            // ch3_pattern_ptr = track_07_ch3_pattern_data[0];

            music_playback_handler();

            return;

        case 8: // bonus start
            ch2_pan_active = false;

            ch1_current_track = 6;
            ch3_current_track = 6;

            ch2_note_length = 1;
            ch3_note_length = 1;
            music_triggered_flag = true;

            // ch2_pattern_ptr = track_08_ch2_pattern_data[0];
            // ch3_pattern_ptr = track_08_ch3_pattern_data[0];

            music_playback_handler();

            return;

        case 9: // bonus fail
            ch2_pan_active = false;

            IO_REGS->nr51 = 0xFF;

            ch1_current_track = 6;
            ch3_current_track = 6;

            ch2_note_length = 1;
            ch3_note_length = 1;
            music_triggered_flag = true;

            // ch2_pattern_ptr = track_09_ch2_pattern_data[0];
            // ch3_pattern_ptr = track_09_ch3_pattern_data[0];

            music_playback_handler();

            return;

        case 10: // bonus win
            ch2_pan_active = false;

            IO_REGS->nr51 = 0xFF;

            ch1_current_track = 6;
            ch3_current_track = 6;

            ch2_note_length = 1;
            ch3_note_length = 1;
            music_triggered_flag = true;

            // ch2_pattern_ptr = track_10_ch2_pattern_data[0];
            // ch3_pattern_ptr = track_10_ch3_pattern_data[0];

            music_playback_handler();

            return;

        case 11: // brick scrolldown
            ch2_pan_active = false;

            ch1_current_track = 6;
            ch3_current_track = 6;

            ch2_note_length = 1;
            ch3_note_length = 1;
            music_triggered_flag = true;

            // ch2_pattern_ptr = track_11_ch2_pattern_data[0];
            // ch3_pattern_ptr = track_11_ch3_pattern_data[0];

            music_playback_handler();

            return;

        case 12: // nice play
            ch2_pan_active = false;

            ch1_current_track = 6;
            ch3_current_track = 6;

            ch2_note_length = 1;
            ch3_note_length = 1;
            music_triggered_flag = true;

            // ch2_pattern_ptr = track_12_ch2_pattern_data[0];
            // ch3_pattern_ptr = track_12_ch3_pattern_data[0];

            music_playback_handler();

            return;

        default:
            return;
    }
}

void mute_ch3(void) {
    IO_REGS->nr30 = 0;
}

void return_745e(void) {}

void ch3_note_length_decrement(void) {
    ch3_note_length--;

    if (ch3_note_length != 0) {
        return_745e();
    }

    uint16_t ch3_pattern = (ch3_pattern_ptr_hi << 4) + ch3_pattern_ptr_lo;

    ch3_pattern_read_loop(ch3_pattern);
}

void ch2_save_ptr(uint16_t ch2_pattern, uint8_t prev) {
    prev ^= prev;   // xor a
    
    ch2_pattern = (ch2_pattern_ptr_hi << 4) + ch2_pattern_ptr_lo;

    uint8_t note_length = ch2_note_length;
    note_length &= note_length; // Z flag manipulation
    
    if (note_length != 0) {
        ch3_note_length_decrement();
    } else {
        ch2_note_length = ch2_note_length_max;
    }
}

void ch2_play_note (uint16_t ch2_pattern, uint8_t prev) {
    ch2_pitch_mirror = prev;

    IO_REGS->nr21 = 0xBF;   // 1011 1111
    IO_REGS->nr22 = 0xF2;   // 1111 0010

    uint8_t ch2_pitch = ch2_pitch_mirror;

    uint16_t stored_ch2_pattern = ch2_pattern;

    IO_REGS->nr23 = note_freq_ptr_table_lo[ch2_pitch];
    IO_REGS->nr24 = note_freq_ptr_table_hi[ch2_pitch];

    ch2_pattern = stored_ch2_pattern;

    ch2_save_ptr(ch2_pattern, prev);
}

void ch3_save_ptr(void) {
    uint16_t ch3_pattern = (ch3_pattern_ptr_hi << 4) + ch3_pattern_ptr_lo;

    uint8_t note_length = ch3_note_length;
    note_length &= note_length; // and a: Z flag manipulation

    if (note_length != 0) {
        return_745e();
    }

    ch3_note_length = ch3_note_length_max;
    return_745e();
}

void ch3_play_note (uint16_t ch3_pattern, uint8_t prev) {
    ch3_pitch_mirror = prev;

    uint16_t stored_ch3_pattern = ch3_pattern;

    IO_REGS->nr30 = 0;      // hardware quirk?
    IO_REGS->nr30 = 0x80;   // 1000 0000
    IO_REGS->nr31 = 0xFF;   // 1111 1111

    load_ch3_waveform();

    IO_REGS->nr32 = 0x20;   // 0010 0000

    uint8_t ch3_pitch = ch3_pitch_mirror;

    IO_REGS->nr33 = note_freq_ptr_table_lo[ch3_pitch];
    IO_REGS->nr34 = note_freq_ptr_table_hi[ch3_pitch];

    ch3_pattern = stored_ch3_pattern;

    ch3_save_ptr();
}

void ch2_pattern_read_loop (uint16_t ch2_pattern) {
    uint16_t *p_ch2_pattern = &ch2_pattern;
    uint8_t prev = *p_ch2_pattern;
    ch2_pattern++;

    if ((prev & (1 << 7)) != 0) {
        ch2_set_note_length(ch2_pattern, prev);
    } else if (!prev) {
        pattern_loop_command_mute_ch1();
    } else if (prev == 0x7F) {
        pattern_loop_command();
    } else if (prev != 1) {
        ch2_play_note (ch2_pattern, prev);
    } else {
        mute_ch2();
        ch2_save_ptr(ch2_pattern, prev);
    }
}

void ch2_set_note_length(uint16_t ch2_pattern, uint8_t prev) {
    uint16_t stored_ch2_pattern = ch2_pattern;

    prev &= 0x7F;
    ch2_pattern = note_length_table[0];
    uint8_t offset = prev;

    ch2_note_length = note_length_table[offset];
    ch2_note_length_max = note_length_table[offset];

    ch2_pattern = stored_ch2_pattern;

    ch2_pattern_read_loop(ch2_pattern);
}

void music_playback_handler() {
    ch2_note_length--;

    if (ch2_note_length != 0) {
        ch3_note_length_decrement();
    }

    uint16_t ch2_pattern = (ch2_pattern_ptr_hi << 4) + ch2_pattern_ptr_lo;

    ch2_pattern_read_loop(ch2_pattern);
}

void load_ch3_waveform(void) {
    static uint8_t counter = 0;
    
    do {
        IO_REGS->wave[counter] = ch3_waveform_data[counter];
        ch3_waveform_index++;
        counter++;
    } while (ch3_waveform_index != 10);

    ch3_waveform_index = 0;
}

void ch3_pattern_read_loop (uint16_t ch3_pattern) {
    uint16_t *p_ch3_pattern = &ch3_pattern;
    uint8_t prev = *p_ch3_pattern;
    ch3_pattern++;

    if ((prev & (1 << 7)) != 0) {
        ch3_set_note_length(ch3_pattern, prev);
    } else if (prev == 0) {
        pattern_loop_command_mute_ch3();
    } else if (prev == 0x7F) {
        pattern_loop_command();
    } else if (prev != 1) {
        ch3_play_note(ch3_pattern, prev);
    } else {
        mute_ch3();
        ch3_save_ptr();
    }
}

void ch3_set_note_length(uint16_t hl, uint8_t a) {
    uint16_t stored_hl = hl;

    a &= 0x7F;
    hl = note_length_table[0];
    uint8_t offset = a;

    ch3_note_length = note_length_table[offset];
    ch3_note_length_max = note_length_table[offset];

    hl = stored_hl;

    ch3_pattern_read_loop(hl);
}

void pattern_loop_command(void) {
    track_index = ch1_current_track;
    
    music_track_handler();
}

void ch2_pan_handler() {
    uint8_t left = 1, right = 0;

    if (ch2_pan_active == false) {
        ch2_pan_active = false;
        return;

    } else {
        if (ch2_pan_direction == right) {
            ch2_pan_timer--;

            if (ch2_pan_timer == 0) {
                ch2_pan_direction = left;
                ch2_pan_timer = ch2_pan_timer_max;
                return;
            } else {
                IO_REGS->nr51 = 0x57;
                return;
            }
        } else {    // ch2_pan_direction == left
            ch2_pan_timer--;

            if (ch2_pan_timer == 0) {
                ch2_pan_direction = right;
                ch2_pan_timer = ch2_pan_timer_max;
                return;
            } else {
                IO_REGS->nr51 = 0x75;
                return;
            }
        }
    }
}

void pattern_loop_command_mute_ch1(void) {
    ch1_current_track = 0;
    ch2_pan_active = false;
    IO_REGS->nr12 = 0;
}

void pattern_loop_command_mute_ch3(void) {
    ch3_current_track = 0;
    ch2_pan_active = false;
    IO_REGS->nr32 = 0;
}

void stop_music(void) {
    music_flag = 0;
    ch1_current_track = 0;
    ch3_current_track = 0;

    IO_REGS->nr12 = 0;
    IO_REGS->nr22 = 0;
    IO_REGS->nr32 = 0;
}

void mute_ch2(void) {
    IO_REGS->nr22 = 0;
}

void debug_reset_sfx_clear_flag(void) {
    debug_sfx_clear_flag = true;
}

void debug_set_sfx_clear_flag(void) {
    debug_sfx_clear_flag = false;
}

void audio_update(void) {
    demo_flag_handler();
    sfx_handler();
    ch4_explosion_handler();
    music_track_handler();
    ch2_pan_handler();

    game_event = 0;
    ball_oob = 0;
    track_index = 0;
}

void audio_update_thunk(void) {
    audio_update();
}

void stop_music_wrapper(void) {
    stop_music();
}
