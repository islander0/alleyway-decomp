#pragma once

#include <stdint.h>

extern const uint8_t tilemap_patch_table[42];

extern const uint8_t tile_data_block_0[117];
extern const uint8_t tile_data_block_1[1184];
extern const uint8_t tile_data_block_2[1424];

extern const uint16_t mario_start_spr_ptr_table[5];
extern const uint16_t mario_jump_out_spr_ptr_table[2];
extern const uint16_t explosion_spr_ptr_table[3];
extern const uint16_t mario_wink_spr_ptr_table[3];

extern const uint8_t oma_dma_routine_data[12];

extern const uint8_t palette_fade_in_data[4];
extern const uint8_t palette_fade_out_data[4];

extern const uint8_t special_bonus_text_tile_data[15];
extern const uint8_t clear_special_bonus_text_tile_data[15];

extern const uint8_t pts_text_tile_data[8];
extern const uint8_t clear_pts_text_tile_data[8];

extern const uint8_t try_again_tile_vram_data[14];
extern const uint8_t clear_try_again_tile_vram_data[14];

extern void copy_tiles4_oam_buffer(uint8_t x, uint8_t y, uint8_t mario_frame);
extern void load_anim_oam_buffer(void);
extern void update_score_oam_buffer(void);

extern void load_lives_number_vram(void);
extern void load_bonus_time_text_vram(void);
extern void load_special_bonus_text_vram(void);
extern void load_special_bonus_points_oam_buffer(void);