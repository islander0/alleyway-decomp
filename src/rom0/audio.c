#include "../hram.c"
#include "../wram.c"
#include "../cpu.c"
#include "../io.c"
#include "../enum.h"

#include <stdint.h>
#include <stdbool.h>

// hi/lo split necessary for 8-bit NRxx register writes
// note_freq_table [1][x] = lo
// note_freq_table [2][x] = hi

const uint8_t note_freq_table [2][67] = {
    {0x00, 0xC0, 0x80, 0x80, 0x81, 0x81, 0x81, 0x82, 0x82, 0x82, 0x83, 0x83, 0x83, 0x83, 0x84, 0x84, 0x84, 0x84, 0x84, 0x85, 0x85, 0x85, 0x85, 0x85, 0x85, 0x85, 0x86, 0x86, 0x86, 0x86, 0x86, 0x86, 0x86, 0x86, 0x86, 0x86, 0x86, 0x86, 0x87, 0x87, 0x87, 0x87, 0x87, 0x87, 0x87, 0x87, 0x87, 0x87, 0x87, 0x87, 0x87, 0x87, 0x87, 0x87, 0x87, 0x87, 0x87, 0x87, 0x87, 0x87, 0x87, 0x87, 0x87, 0x87, 0x87, 0x87, 0x87},  
    {0x00, 0x00, 0x2C, 0x9D, 0x07, 0x6B, 0xC9, 0x23, 0x77, 0xC7, 0x12, 0x58, 0x9B, 0xDA, 0x16, 0x4F, 0x83, 0xB5, 0xE5, 0x11, 0x3B, 0x63, 0x88, 0xAC, 0xCE, 0xED, 0x0B, 0x27, 0x42, 0x5B, 0x72, 0x89, 0x9E, 0xB2, 0xC4, 0xD6, 0xE7, 0xF7, 0x06, 0x14, 0x21, 0x2D, 0x39, 0x44, 0x4F, 0x59, 0x62, 0x6B, 0x73, 0x7B, 0x83, 0x8A, 0x90, 0x97, 0x9D, 0xA2, 0xA7, 0xAC, 0xB1, 0xB6, 0xBA, 0xBE, 0xC1, 0xC5, 0xC8, 0xCB, 0xCE}
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
    wram.game_event = EXTRA_LIFE;
}

void set_event_white_brick(void) {
    wram.game_event = WHITE_BRICK_HIT;
}

void set_event_unbreakable_brick(void) {
    wram.game_event = UNBREAKABLE_BRICK_HIT;
}

void set_event_paddle_collision(void) {
    wram.game_event = PADDLE_COLLISION;
}

void set_event_light_grey_brick(void) {
    wram.game_event = LIGHT_GREY_BRICK_HIT;
}

void set_event_dark_grey_brick(void) {
    wram.game_event = DARK_GREY_BRICK_HIT;
}

void set_event_ball_launched(void) {
    wram.game_event = BALL_LAUNCHED;
}

void set_event_bonus_countdown(void) {
    wram.game_event = BONUS_COUNTDOWN;
}

void set_event_mario_jump(void) {
    wram.game_event = MARIO_JUMP;
}

void set_event_death_no_lives(void) {
    wram.game_event = NO_LIVES_LEFT;
}

void set_event_ceiling(void) {
    wram.game_event = CEILING_COLLISION;
}

void set_event_wall(void) {
    wram.game_event = WALL_COLLISION;
}

// Set track

void load_track_title(void) {
    wram.track_index = TITLE_TRACK;
}

void load_track_start(void) {
    wram.track_index = START_TRACK;
}

void load_track_game_over(void) {
    wram.track_index = GAME_OVER_TRACK;
}

void load_track_pause(void) {
    wram.track_index = PAUSE_TRACK;
}

void load_track_stage_complete(void) {
    wram.track_index = STAGE_COMPLETE_TRACK;
}

void load_track_bonus_stage(void) {
    wram.track_index = BONUS_STAGE_TRACK;
}

void load_track_bonus_stage_fast(void) {
    wram.track_index = BONUS_STAGE_FAST_TRACK;
}

void load_track_bonus_stage_start(void) {
    wram.track_index = BONUS_STAGE_START_TRACK;
}

void load_track_bonus_stage_lose(void) {
    wram.track_index = BONUS_STAGE_LOSE_TRACK;
}

void load_track_bonus_stage_win(void) {
    wram.track_index = BONUS_STAGE_WIN_TRACK;
}

void load_track_brick_scrolldown(void) {
    wram.track_index = BRICK_SCROLLDOWN_SFX;
}

void load_track_nice_play(void) {
    wram.track_index = GAME_WIN_TRACK;
}

void ch1_initializer(uint8_t sfx_env_data) {
    IO_REGS->nr10 = ch1_env_data_index[sfx][0];
    IO_REGS->nr11 = ch1_env_data_index[sfx][1];
    IO_REGS->nr12 = ch1_env_data_index[sfx][2];
    IO_REGS->nr13 = ch1_env_data_index[sfx][3];
    IO_REGS->nr14 = ch1_env_data_index[sfx][4];
    
    return;
}

static inline void clear_sfx(void) {
    wram.current_sfx_active = NONE;
    IO_REGS->nr12 = 0;
    wram.sfx_envelope_counter = 0;
    wram.sfx_envelope = PADDLE_SFX_ENV_5_4;
}

void sfx_handler() {
    static uint8_t sfx;

    if (wram.current_sfx_active == EXTRA_LIFE) {
        wram.sfx_envelope_counter++;

        if (wram.sfx_envelope_counter != UNBREAKABLE_BRICK_SFX_ENV_4) {
            return;
        }

        wram.sfx_envelope_counter = 0;
        wram.sfx_envelope--;

        switch (wram.sfx_envelope) {
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

                wram.ceiling_collision_sfx_active_flag = false;

                return;

            default:
                wram.current_sfx_active = NONE;

                clear_sfx();
                return;
        }
    }
    
    switch (wram.game_event) {
        case 4: // ball/paddle collision
            if (wram.ceiling_collision_sfx_active_flag == true) {
                return;
            }

            wram.current_sfx_active = PADDLE_COLLISION;
            wram.sfx_envelope = WHITE_BRICK_SFX_ENV_3;
            
            sfx = 0;
            ch1_initializer(sfx);

            return;

        case 2: // white brick hit
            if (wram.ceiling_collision_sfx_active_flag == true) {
                return;
            }

            wram.current_sfx_active = WHITE_BRICK_HIT;
            wram.sfx_envelope = 5;
            
            sfx = 3;
            ch1_initializer(sfx);

            return;

        case 3: // unbreakable brick hit
            if (wram.ceiling_collision_sfx_active_flag == true) {
                return;
            }

            wram.current_sfx_active = UNBREAKABLE_BRICK_HIT;
            wram.sfx_envelope = 5;
            
            sfx = 6;
            ch1_initializer(sfx);

            return;

        case 1: // extra life granted
            wram.current_sfx_active = EXTRA_LIFE;
            wram.sfx_envelope = 7;
            
            sfx = 10;
            ch1_initializer(sfx);

            return;

        case 5: // light grey brick hit
            if (wram.ceiling_collision_sfx_active_flag == true) {
                return;
            }

            wram.current_sfx_active = LIGHT_GREY_BRICK_HIT;
            wram.sfx_envelope = 5;
            
            sfx = 16;
            ch1_initializer(sfx);

            return;

        case 6: // dark grey brick hit
            if (wram.ceiling_collision_sfx_active_flag == true) {
                return;
            }

            wram.current_sfx_active = DARK_GREY_BRICK_HIT;
            wram.sfx_envelope = 5;
            
            sfx = 19;
            ch1_initializer(sfx);

            return;

        case 7: // ball launched (A pressed in standby)
            wram.current_sfx_active = BALL_LAUNCHED;
            wram.sfx_envelope = 4;
            
            sfx = 22;
            ch1_initializer(sfx);

            return;

        case 8: // bonus clear points countdown active
            wram.current_sfx_active = BONUS_COUNTDOWN;
            wram.sfx_envelope = 5;
            
            sfx = 25;
            ch1_initializer(sfx);

            return;

        case 9: // mario x jump threshold reached
            wram.current_sfx_active = MARIO_JUMP;
            wram.ch1_pitch = 0x63;
            wram.ch1_freq_lo = 0x0A;
            wram.ch1_freq_hi = 0x87;
            wram.sfx_envelope_counter = 0xFF;

            return;

        case 10: // death explosion complete, no lives remain
            wram.current_sfx_active = NO_LIVES_LEFT;
            wram.ch1_pitch = 0xB;
            wram.ch1_freq_lo = 0x87;
            wram.ch1_freq_hi = 0x86;
            wram.unknown_dffe = 0x87;
            wram.sfx_envelope_counter = 0xFF;

            return;

        case 11: // ceiling collision (!bonus levels)
            wram.current_sfx_active = CEILING_COLLISION;
            wram.ch1_freq_lo = 0xA5;
            wram.unknown_dffe = 0x87;
            wram.ceiling_collision_sfx_active_flag = true;

            return;

        case 12: // wall collision
            if (wram.ceiling_collision_sfx_active_flag == true) {
                return;
            }

            wram.current_sfx_active = WALL_COLLISION;
            wram.ch1_pitch = 0xFF;
            wram.ch1_freq_lo = 0x0A;
            wram.ch1_freq_hi = 0x85;
            wram.sfx_envelope_counter = 0xFF;

            return;

        default:
            break;
        }
        
        switch (wram.current_sfx_active) {
            case 2:
                wram.sfx_envelope_counter++;

                if (wram.sfx_envelope_counter != 5) {
                    return;
                }

                wram.sfx_envelope_counter = 0;
                wram.sfx_envelope--;

                switch(wram.sfx_envelope) {
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
                wram.sfx_envelope_counter++;

                if (wram.sfx_envelope_counter != 3) {
                    return;
                }

                wram.sfx_envelope_counter = 0;
                wram.sfx_envelope--;

                switch(wram.sfx_envelope) {
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
                wram.sfx_envelope_counter++;

                if (wram.sfx_envelope_counter != 5) {
                    return;
                }

                wram.sfx_envelope_counter = 0;
                wram.sfx_envelope--;

                switch (wram.sfx_envelope) {
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
                wram.sfx_envelope_counter++;

                if (wram.sfx_envelope_counter != 5) {
                    return;
                }

                wram.sfx_envelope_counter = 0;
                wram.sfx_envelope--;

                switch (wram.sfx_envelope) {
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
                wram.sfx_envelope_counter++;

                if (wram.sfx_envelope_counter != 5) {
                    return;
                }

                wram.sfx_envelope_counter = 0;
                wram.sfx_envelope--;

                switch (wram.sfx_envelope) {
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
                wram.sfx_envelope_counter++;

                if (wram.sfx_envelope_counter != 5) {
                    return;
                }

                wram.sfx_envelope_counter = 0;
                wram.sfx_envelope--;

                switch (wram.sfx_envelope) {
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
                wram.sfx_envelope_counter++;

                if (wram.sfx_envelope_counter != 2) {
                    return;
                }

                wram.sfx_envelope_counter = 0;
                wram.sfx_envelope--;

                switch (wram.sfx_envelope) {
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
                wram.unknown_dfd0 = 5;
                wram.unknown_dfd1 = 4;

                IO_REGS->nr10 = 0;
                IO_REGS->nr11 = 0xBF;
                IO_REGS->nr12 = 0x40;

                if (wram.sfx_envelope_counter == 0) {
                    do {
                        if (wram.ch1_freq_lo - 1 == 0x10) {
                            wram.current_sfx_active = NONE;
                            IO_REGS->nr12 = 0;

                            clear_sfx();
                            return;
                        } else {
                            wram.ch1_freq_lo--;
                            wram.unknown_dfd1--;
                        }
                    } while (wram.unknown_dfd1 != 0);

                    IO_REGS->nr13 = wram.ch1_freq_lo;
                    IO_REGS->nr14 = wram.ch1_freq_hi;

                    return;
                } else {
                    do {
                        if (wram.ch1_pitch + 1 == 0x63) {
                            wram.sfx_envelope_counter = 0;
                            return;
                        } else {
                            wram.ch1_pitch++;
                            wram.unknown_dfd0--;
                        }
                    } while (wram.unknown_dfd0 != 0);

                    IO_REGS->nr13 = wram.ch1_pitch;
                    IO_REGS->nr14 = wram.ch1_freq_hi;

                    return;
                }

            case 10: // LAB_6e66
                wram.unknown_dfd0 = 9;
                wram.unknown_dfd1 = 4;

                IO_REGS->nr10 = 0;
                IO_REGS->nr11 = 0xBF;
                IO_REGS->nr12 = 0x90;

                if (wram.sfx_envelope_counter == 0) {
                    do {
                        if (wram.ch1_freq_lo - 1 == 0x1E) {
                            wram.current_sfx_active = NONE;
                            IO_REGS->nr12 = 0;

                            return;
                        } else {
                            wram.ch1_freq_lo--;
                            wram.unknown_dfd1--;
                        }
                    } while (wram.unknown_dfd1 != 0);

                    IO_REGS->nr13 = wram.ch1_freq_lo;
                    IO_REGS->nr14 = wram.unknown_dffe;

                    return;
                } else {
                    do {
                        if (wram.ch1_pitch + 1 == 0x89) {
                            wram.sfx_envelope_counter = 0;
                            return;
                        } else {
                            wram.ch1_pitch++;
                            wram.unknown_dfd0--;
                        }
                    } while (wram.unknown_dfd0 != 0);

                    IO_REGS->nr13 = wram.ch1_pitch;
                    IO_REGS->nr14 = wram.ch1_freq_hi;

                    return;
                }

            case 11: // LAB_6ed7
                wram.unknown_dfd1 = 8;

                IO_REGS->nr10 = 0;
                IO_REGS->nr11 = 0xBF;
                IO_REGS->nr12 = 0x90;

                do {
                    if (wram.ch1_freq_lo - 1 == 0x06) {
                        wram.current_sfx_active = NONE;
                        IO_REGS->nr12 = 0;
                        wram.ceiling_collision_sfx_active_flag = 0;

                        clear_sfx();
                        return;
                    } else {
                        wram.ch1_freq_lo--;
                        wram.unknown_dfd1--;
                    }
                } while (wram.unknown_dfd1 != 0);

                IO_REGS->nr13 = wram.ch1_freq_lo;
                IO_REGS->nr14 = wram.unknown_dffe;

                return;

            case 12: // LAB_6f18
                wram.unknown_dfd0 = 0x28;
                wram.unknown_dfd1 = 0x28;

                IO_REGS->nr10 = 0;
                IO_REGS->nr11 = 0xBF;
                IO_REGS->nr12 = 0x40;

                if (wram.sfx_envelope_counter == 0) {
                    do {
                        if (wram.ch1_freq_lo + 1 == 0x63) {
                            
                            // redundant code
                            wram.current_sfx_active = NONE;
                            IO_REGS->nr12 = 0;

                            clear_sfx();
                            return;
                        } else {
                            wram.ch1_freq_lo--;
                            wram.unknown_dfd1--;
                        }
                    } while (wram.unknown_dfd1 != 0);

                    IO_REGS->nr13 = wram.ch1_freq_lo;
                    IO_REGS->nr14 = wram.ch1_freq_hi;

                    return;
                } else {
                    do {
                        if (wram.ch1_pitch-- == 0x10) {
                            wram.sfx_envelope_counter = 0;
                            return;
                        } else {
                            wram.ch1_pitch--;
                            wram.unknown_dfd0--;
                        }
                    } while (wram.unknown_dfd0 != 0);

                    IO_REGS->nr13 = wram.ch1_pitch;
                    IO_REGS->nr14 = wram.ch1_freq_hi;

                    return;
                }
            default:
                return;
    }
}

void ch4_explosion_handler(void) {
    wram.ball_oob == 1 ? load_ch4_data() : init_ch4_explosion_sfx_pan();
}

void ch4_initializer(void) {
    IO_REGS->nr41 = explosion_ch4_sfx_data[0];
    IO_REGS->nr42 = explosion_ch4_sfx_data[1];
    IO_REGS->nr43 = explosion_ch4_sfx_data[2];
    IO_REGS->nr44 = explosion_ch4_sfx_data[3];
}

void load_ch4_data(void) {
    wram.ch4_pan_timer = 73;
    wram.ch4_pan = 0xF;
    wram.ch2_pan_active = false;

    ch4_initializer();
}

void init_ch4_explosion_sfx_pan() {
    switch (wram.ch4_pan_timer) {
        case 1:
            IO_REGS->nr51 = 0xFF; // // 1111 1111: pan center
        
        case 0:
            wram.ch4_pan_timer = 0;
            return;

        default:
            break;
    }

    // TODO: add Rotate Left Carry, convert to semantic meaning
    wram.ch4_pan = RLC(wram.ch4_pan);

    if (FLAG_C != 1) {
        IO_REGS->nr51 = 0xF0; //1111 0000: pan left
        return;
    } else {
        IO_REGS->nr51 = 0x0F; //0000 1111: pan right
        return;
    }
    
}

void music_track_handler() {
    switch(wram.track_index) {
        case 1: // title
            wram.ch1_current_track = 1;
            wram.ch3_current_track = 1;
            wram.ch2_note_length = 1;
            wram.ch3_note_length = 1;
            wram.music_triggered_flag = true;
            wram.ch2_pan_active = true;
            wram.ch2_pan_triggered_flag = true;
            wram.ch2_pan_direction = 1;

            wram.ch2_pan_timer = 96;
            wram.ch2_pan_timer_max = 96;
            
            wram.ch2_pattern_ptr = (uint16_t)track_01_ch2_pattern_data[0]; // TODO: wram.ch2_pattern_ptr = pointer TO (uint16_t)track_01_ch2_pattern_data[0]
            wram.ch3_pattern_ptr = (uint16_t)track_01_ch3_pattern_data[0];

            music_playback_handler(wram.ch2_pattern_ptr, wram.ch3_pattern_ptr);

            return;

        case 2: // game start
            IO_REGS->nr51 = 0xFF;
            
            wram.ch2_pan_active = false;

            wram.ch1_current_track = 2;
            wram.ch3_current_track = 2;

            wram.ch2_note_length = 1;
            wram.ch3_note_length = 1;
            wram.music_triggered_flag = true;

            wram.ch2_pattern_ptr = (uint16_t)track_02_ch2_pattern_data[0];
            wram.ch3_pattern_ptr = (uint16_t)track_02_ch3_pattern_data[0];

            music_playback_handler(wram.ch2_pattern_ptr, wram.ch3_pattern_ptr);

            return;

        case 3: // game over
            wram.ch1_current_track = 3;
            wram.ch3_current_track = 3;

            wram.ch2_note_length = 1;
            wram.ch3_note_length = 1;
            wram.music_triggered_flag = true;
            wram.ch2_pan_active = true;
            wram.ch2_pan_triggered_flag = true;
            wram.ch2_pan_direction = 1;

            wram.ch2_pan_timer = 96;
            wram.ch2_pan_timer_max = 96;

            wram.ch2_pattern_ptr = (uint16_t)track_03_ch2_pattern_data[0];
            wram.ch3_pattern_ptr = (uint16_t)track_03_ch3_pattern_data[0];

            music_playback_handler(wram.ch2_pattern_ptr, wram.ch3_pattern_ptr);

            return;

        case 4: // pause
            wram.ch2_pan_active = false;

            wram.ch1_current_track = 4;
            wram.ch3_current_track = 4;

            wram.ch2_note_length = 1;
            wram.ch3_note_length = 1;
            wram.music_triggered_flag = true;

            wram.ch2_pattern_ptr = (uint16_t)track_04_ch2_pattern_data[0];
            wram.ch3_pattern_ptr = (uint16_t)track_04_ch3_pattern_data[0];

            music_playback_handler(wram.ch2_pattern_ptr, wram.ch3_pattern_ptr);

            return;

        case 5: // level completed
            IO_REGS->nr51 = 0xFF;

            wram.ch2_pan_active = false;

            wram.ch1_current_track = 5;
            wram.ch3_current_track = 5;

            wram.ch2_note_length = 1;
            wram.ch3_note_length = 1;
            wram.music_triggered_flag = true;

            wram.ch2_pattern_ptr = (uint16_t)track_05_ch2_pattern_data[0];
            wram.ch3_pattern_ptr = (uint16_t)track_05_ch3_pattern_data[0];

            music_playback_handler(wram.ch2_pattern_ptr, wram.ch3_pattern_ptr);

            return;

        case 6: // bonus
            wram.ch1_current_track = 6;
            wram.ch3_current_track = 6;

            wram.ch2_note_length = 1;
            wram.ch3_note_length = 1;
            wram.music_triggered_flag = true;
            wram.ch2_pan_active = true;
            wram.ch2_pan_triggered_flag = true;
            wram.ch2_pan_direction = 1;

            wram.ch2_pan_timer = 40;
            wram.ch2_pan_timer_max = 40;

            wram.ch2_pattern_ptr = (uint16_t)track_06_ch2_pattern_data[0];
            wram.ch3_pattern_ptr = (uint16_t)track_06_ch3_pattern_data[0];

            music_playback_handler(wram.ch2_pattern_ptr, wram.ch3_pattern_ptr);

            return;

        case 7: // bonus fast
            wram.ch1_current_track = 7;
            wram.ch3_current_track = 7;

            wram.ch2_note_length = 1;
            wram.ch3_note_length = 1;
            wram.music_triggered_flag = true;
            wram.ch2_pan_active = true;
            wram.ch2_pan_triggered_flag = true;
            wram.ch2_pan_direction = 1;

            wram.ch2_pan_timer = 32;
            wram.ch2_pan_timer_max = 32;

            wram.ch2_pattern_ptr = (uint16_t)track_07_ch2_pattern_data[0];
            wram.ch3_pattern_ptr = (uint16_t)track_07_ch3_pattern_data[0];

            music_playback_handler(wram.ch2_pattern_ptr, wram.ch3_pattern_ptr);

            return;

        case 8: // bonus start
            wram.ch2_pan_active = false;

            wram.ch1_current_track = 6;
            wram.ch3_current_track = 6;

            wram.ch2_note_length = 1;
            wram.ch3_note_length = 1;
            wram.music_triggered_flag = true;

            wram.ch2_pattern_ptr = (uint16_t)track_08_ch2_pattern_data[0];
            wram.ch3_pattern_ptr = (uint16_t)track_08_ch3_pattern_data[0];

            music_playback_handler(wram.ch2_pattern_ptr, wram.ch3_pattern_ptr);

            return;

        case 9: // bonus fail
            wram.ch2_pan_active = false;

            IO_REGS->nr51 = 0xFF;

            wram.ch1_current_track = 6;
            wram.ch3_current_track = 6;

            wram.ch2_note_length = 1;
            wram.ch3_note_length = 1;
            wram.music_triggered_flag = true;

            wram.ch2_pattern_ptr = (uint16_t)track_09_ch2_pattern_data[0];
            wram.ch3_pattern_ptr = (uint16_t)track_09_ch3_pattern_data[0];

            music_playback_handler(wram.ch2_pattern_ptr, wram.ch3_pattern_ptr);

            return;

        case 10: // bonus win
            wram.ch2_pan_active = false;

            IO_REGS->nr51 = 0xFF;

            wram.ch1_current_track = 6;
            wram.ch3_current_track = 6;

            wram.ch2_note_length = 1;
            wram.ch3_note_length = 1;
            wram.music_triggered_flag = true;

            wram.ch2_pattern_ptr = (uint16_t)track_10_ch2_pattern_data[0];
            wram.ch3_pattern_ptr = (uint16_t)track_10_ch3_pattern_data[0];

            music_playback_handler(wram.ch2_pattern_ptr, wram.ch3_pattern_ptr);

            return;

        case 11: // brick scrolldown
            wram.ch2_pan_active = false;

            wram.ch1_current_track = 6;
            wram.ch3_current_track = 6;

            wram.ch2_note_length = 1;
            wram.ch3_note_length = 1;
            wram.music_triggered_flag = true;

            wram.ch2_pattern_ptr = (uint16_t)track_11_ch2_pattern_data[0];
            wram.ch3_pattern_ptr = (uint16_t)track_11_ch3_pattern_data[0];

            music_playback_handler(wram.ch2_pattern_ptr, wram.ch3_pattern_ptr);

            return;

        case 12: // nice play
            wram.ch2_pan_active = false;

            wram.ch1_current_track = 6;
            wram.ch3_current_track = 6;

            wram.ch2_note_length = 1;
            wram.ch3_note_length = 1;
            wram.music_triggered_flag = true;

            wram.ch2_pattern_ptr = (uint16_t)track_12_ch2_pattern_data[0];
            wram.ch3_pattern_ptr = (uint16_t)track_12_ch3_pattern_data[0];

            music_playback_handler(wram.ch2_pattern_ptr, wram.ch3_pattern_ptr);

            return;

        default:
            return;
    }
}

void music_playback_handler() {
    uint16_t ch2_bit_7 = ((wram.ch2_pattern_ptr + 1)) | (1 << 7);
    uint16_t ch3_bit_7 = ((wram.ch3_pattern_ptr + 1)) | (1 << 7);

    wram.ch2_note_length++;

    if (wram.ch2_note_length == 0) {
        //ch2_note_length_decrement:
        if (ch2_bit_7 != 0) {
            ch2_set_note_length();
        }
        
        if (ch2_bit_7 == 0) {
            pattern_loop_command_mute_ch1();
        }
        
        if (ch2_bit_7 == 0x7F) {
            pattern_loop_command();
        }

        if (ch2_bit_7 != 1) {
            //.ch2_play_note
            wram.ch2_pitch_mirror = (wram.ch2_pattern_ptr + 1);

            IO_REGS->nr21 = 0xBF;   // 1011 1111
            IO_REGS->nr22 = 0xF2;   // 1111 0010
            IO_REGS->nr23 = note_freq_hi_table[wram.ch2_pitch_mirror];
            IO_REGS->nr24 = note_freq_lo_table[wram.ch2_pitch_mirror];
        } else {
            mute_ch2();
        }

        if (wram.ch2_note_length == 0) {
            wram.ch2_note_length = wram.ch2_note_length_max;
        }
    } else {
        goto ch3_note_length_decrement;
    }
    
ch3_note_length_decrement:
    wram.ch3_note_length--;

    if (wram.ch3_note_length != 0) {
        return;
    }

    if (ch3_bit_7 != 0) {
        ch3_set_note_length();
    }
    
    if (ch3_bit_7 == 0) {
        pattern_loop_command_mute_ch3();
    }
    
    if (ch3_bit_7 == 0x7F) {
        pattern_loop_command();
    }

    if (ch3_bit_7 != 1) {
        //ch3_play_note
        wram.ch3_pitch_mirror = (wram.ch3_pattern_ptr + 1);

        IO_REGS->nr30 = 0;      // hardware quirk?
        IO_REGS->nr30 = 0x80;   // 1000 0000
        IO_REGS->nr31 = 0xFF;   // 1111 1111

        load_ch3_waveform();

        IO_REGS->nr32 = 0x20;   // 0010 0000
        IO_REGS->nr33 = note_freq_hi_table[wram.ch3_pitch_mirror];
        IO_REGS->nr34 = note_freq_lo_table[wram.ch3_pitch_mirror];
    } else {
        mute_ch3();
    }

    if (wram.ch3_note_length != 0) {
        return;
    } else {
        wram.ch3_note_length = wram.ch3_note_length_max;
        return;
    }
}

void load_ch3_waveform(void) {
    static uint8_t counter = 0;
    
    do {
        IO_REGS->wave[counter] = ch3_waveform_data[counter];
        wram.ch3_waveform_index++;
        counter++;
    } while (wram.ch3_waveform_index != 10);

    wram.ch3_waveform_index = 0;
}

void ch3_set_note_length(CPU *cpu) {
    cpu->e = cpu->a & 0x7F;

    wram.ch2_note_length = note_length_table[cpu->e];
    wram.ch2_note_length_max = note_length_table[cpu->e];

    ch2_pattern_read_loop();
    return;
}

void ch3_set_note_length(CPU *cpu) {
    cpu->e = cpu->a & 0x7F;

    wram.ch3_note_length = note_length_table[cpu->e];
    wram.ch3_note_length_max = note_length_table[cpu->e];

    ch3_pattern_read_loop();
    return;
}

void pattern_loop_command(void) {
    wram.track_index = wram.ch1_current_track;
    
    music_track_handler();
}

void ch2_pan_handler() {
    uint8_t left = 1, right = 0;

    if (wram.ch2_pan_active == false) {
        wram.ch2_pan_active = false;
        return;

    } else {
        if (wram.ch2_pan_direction == right) {
            wram.ch2_pan_timer--;

            if (wram.ch2_pan_timer == 0) {
                wram.ch2_pan_direction = left;
                wram.ch2_pan_timer = wram.ch2_pan_timer_max;
                return;
            } else {
                IO_REGS->nr51 = 0x57;
                return;
            }
        } else {    // wram.ch2_pan_direction == left
            wram.ch2_pan_timer--;

            if (wram.ch2_pan_timer == 0) {
                wram.ch2_pan_direction = right;
                wram.ch2_pan_timer = wram.ch2_pan_timer_max;
                return;
            } else {
                IO_REGS->nr51 = 0x75;
                return;
            }
        }
    }
}

void pattern_loop_command_mute_ch1(void) {
    wram.ch1_current_track = 0;
    wram.ch2_pan_active = false;
    IO_REGS->nr12 = 0;
}

void pattern_loop_command_mute_ch3(void) {
    wram.ch3_current_track = 0;
    wram.ch2_pan_active = false;
    IO_REGS->nr32 = 0;
}

void stop_music(void) {
    wram.music_flag = 0;
    wram.ch1_current_track = 0;
    wram.ch3_current_track = 0;

    IO_REGS->nr12 = 0;
    IO_REGS->nr22 = 0;
    IO_REGS->nr32 = 0;
}

void mute_ch2(void) {
    IO_REGS->nr22 = 0;
}

void mute_ch3(void) {
    IO_REGS->nr30 = 0;
}

void debug_reset_sfx_clear_flag(void) {
    wram.debug_sfx_clear_flag = true;
}

void debug_set_sfx_clear_flag(void) {
    wram.debug_sfx_clear_flag = false;
}

void audio_update(void) {
    demo_flag_handler();
    sfx_handler();
    ch4_explosion_handler();
    music_track_handler();
    ch2_pan_handler();

    wram.game_event = 0;
    wram.ball_oob = 0;
    wram.track_index = 0;
}

void audio_update_thunk(void) {
    audio_update();
}

void stop_music_wrapper(void) {
    stop_music();
}
