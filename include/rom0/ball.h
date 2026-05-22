#pragma once

#include <stdint.h>

extern const uint8_t byte_array_100b [16];

extern const uint16_t ball_velocity_ptr_table[25];
extern const uint16_t ball_angle_speed_table[114];

extern void set_ball_oob(void);
extern void ball_physics_and_collision_handler(void);