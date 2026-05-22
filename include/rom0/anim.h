#pragma once

#include <stdint.h>

#define MARIO_JUMP_VEL_LEN 23
#define EXPLOSION_ANIM_OFFSET_LEN 36
#define MARIO_WINK_ANIM_OFFSET_LEN 29
#define ANIM_FRAME_TILE_LEN 208

extern const uint8_t paddle_open_close_anim_spr_ptr[3];

extern const uint8_t paddle_open_frame_0_tile_data[3];
extern const uint8_t paddle_open_frame_1_tile_data[3];
extern const uint8_t paddle_open_frame_2_tile_data[3];

extern const int8_t mario_jump_y_velocity_data[MARIO_JUMP_VEL_LEN];

extern const uint8_t explosion_anim_offset_data[EXPLOSION_ANIM_OFFSET_LEN];
extern const uint8_t mario_wink_anim_offset_data[MARIO_WINK_ANIM_OFFSET_LEN];

extern const uint8_t anim_frame_tile_data[ANIM_FRAME_TILE_LEN];