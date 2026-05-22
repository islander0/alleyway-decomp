#pragma once

#include <stdint.h>

extern const uint8_t paddle_0_angle_steepness_data[16];
extern const uint8_t paddle_1_angle_steepness_data[12];

extern const uint8_t paddle_hit_max_value_table[10];

extern void update_paddle_oam_buffer(void);
extern void shift_paddle_left(void);