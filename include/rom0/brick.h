#pragma once
#include <stdint.h>

extern const uint8_t brick_data_table[15][6];
extern const uint8_t stage_properties_table[33][3];

extern const uint8_t stage_0_1_brick_data[197];
extern const uint8_t stage_4_5_brick_data[197];
extern const uint8_t stage_8_9_brick_data[281];
extern const uint8_t stage_12_13_brick_data[225];
extern const uint8_t stage_16_17_brick_data[253];
extern const uint8_t stage_20_21_brick_data[281];
extern const uint8_t stage_24_25_brick_data[281];
extern const uint8_t stage_28_29_brick_data[253];
extern const uint8_t stage_2_brick_data[561];
extern const uint8_t stage_6_brick_data[561];
extern const uint8_t stage_10_brick_data[561];
extern const uint8_t stage_14_brick_data[561];
extern const uint8_t stage_18_brick_data[561];
extern const uint8_t stage_22_brick_data[561];
extern const uint8_t stage_26_brick_data[561];
extern const uint8_t stage_30_brick_data[561];
extern const uint8_t stage_3_brick_data[281];
extern const uint8_t stage_7_brick_data[281];
extern const uint8_t stage_11_brick_data[281];
extern const uint8_t stage_15_brick_data[281];
extern const uint8_t stage_19_brick_data[281];
extern const uint8_t stage_23_brick_data[281];
extern const uint8_t stage_27_brick_data[281];
extern const uint8_t stage_31_brick_data[281];
extern const uint8_t blank_stage_brick_data[561];

extern void brick_collision_handler(void);