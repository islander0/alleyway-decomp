#pragma once
#include <stdint.h>

#ifdef __SDCC
    #define __AT(addr) __at(addr)
#else
    #define __AT(addr)  // IntelliSense sees nothing
#endif

#define OAM_BUFFER_START 0x00

#define OAM_PADDLE_START 0x00
#define OAM_GAME_OVER_START 0x00
#define OAM_BALL_START 0x0C
#define OAM_DEBUG_BALL_VELOCITY_START 0x10
#define OAM_SCORE_START 0x14
#define OAM_TITLE_SCORE_START 0x28
#define OAM_WALL_START 0x3C

#define OAM_STAGE_NUMBER_START 0x80
#define OAM_BONUS_TEXT_START 0x80
#define OAM_BONUS_STAGE_TIME_START 0x80
#define OAM_PAUSE_START 0x80
#define OAM_SPECIAL_BONUS_POINTS_START 0x88
#define OAM_MARIO_WALK_START 0x88

#define SCROLL_X_TABLE_LEN 20
#define LEVEL_SCROLL_X_MAX_TIMER_LEN 20
#define LEVEL_SCROLL_X_TIMER_LEN 20

// wram buffers
extern uint8_t brick_type_buffer[1024];
extern uint8_t object_state_array[1024];
extern uint8_t oam_buffer[0xA0];
extern uint8_t bg_map_buffer_pad;
extern uint8_t tile_buffer[0x13];

// scroll x
extern uint8_t scroll_x_table[SCROLL_X_TABLE_LEN];
extern uint8_t level_scroll_x_max_timer[LEVEL_SCROLL_X_MAX_TIMER_LEN];
extern uint8_t level_scroll_x_timer[LEVEL_SCROLL_X_TIMER_LEN];

// lcd
extern uint8_t lcd_y;
extern uint8_t lcd_y_vblank;

// animation
extern uint8_t current_anim_x;
extern uint8_t current_anim_y;
extern uint8_t mario_anim_frame;
extern uint8_t anim_timer;
extern uint8_t mario_jump_frame_index;
extern uint8_t mario_jump_x_direction_flag;

// counter
extern uint8_t life_counter;

// stage values
extern uint8_t true_stage_number;
extern uint8_t stage_number_display;
extern uint8_t bonus_stage_number;
extern uint8_t bonus_stage_time;
extern uint8_t level_demo_cycle_timer;
extern uint8_t title_demo_cycle_index;

// Audio
extern uint8_t ch2_pan_active;
extern uint8_t ch2_pan_timer;
extern uint8_t ch2_pan_timer_max;
extern uint8_t ch2_pan_direction;
extern uint8_t ch2_pan_triggered_flag;
extern uint8_t current_sfx_active;
extern uint8_t music_flag;
extern uint8_t ch1_current_track;
extern uint8_t ch3_current_track;
extern uint8_t sfx_envelope_counter;
extern uint8_t track_index;
extern uint8_t sfx_envelope;
extern uint8_t ch2_note_length;
extern uint8_t ch2_note_length_max;
extern uint8_t ch3_note_length;
extern uint8_t ch3_note_length_max;
extern uint8_t ch2_pattern_ptr_hi;
extern uint8_t ch2_pattern_ptr_lo;
extern uint8_t ch3_pattern_ptr_hi;
extern uint8_t ch3_pattern_ptr_lo;
extern uint8_t debug_sfx_clear_flag;
extern uint8_t ch2_pitch_mirror;
extern uint8_t ch3_pitch_mirror;
extern uint8_t ch3_waveform_index;
extern uint8_t music_triggered_flag;
extern uint8_t ch4_pan_timer;
extern uint8_t ch4_pan;
extern uint8_t ch1_pitch;

extern uint8_t ch1_freq_hi;
extern uint8_t ch1_freq_lo;

// gameplay flags
extern uint8_t ceiling_collision_sfx_active_flag;
extern uint8_t demo_flag;
extern uint8_t game_event;
extern uint8_t ball_oob;

// Unknown
extern uint8_t unknown_dfd0;
extern uint8_t unknown_dfd1;
extern uint8_t unknown_dffe;
extern uint8_t unknown_dfff;