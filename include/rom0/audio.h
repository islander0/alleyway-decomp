#pragma once

#include <stdint.h>

extern const uint8_t note_freq_ptr_table_hi[67];
extern const uint8_t note_freq_ptr_table_lo[67];
    
extern const uint8_t note_length_table[44];

extern const uint8_t track_01_ch2_pattern_data[111];
extern const uint8_t track_01_ch3_pattern_data[113];
extern const uint8_t track_02_ch2_pattern_data[22];
extern const uint8_t track_02_ch3_pattern_data[23];
extern const uint8_t track_03_ch2_pattern_data[34];
extern const uint8_t track_03_ch3_pattern_data[33];
extern const uint8_t track_04_ch2_pattern_data[5];
extern const uint8_t track_04_ch3_pattern_data[3];
extern const uint8_t track_05_ch2_pattern_data[21];
extern const uint8_t track_05_ch3_pattern_data[21];
extern const uint8_t track_06_ch2_pattern_data[54];
extern const uint8_t track_06_ch3_pattern_data[60];
extern const uint8_t track_07_ch2_pattern_data[54];
extern const uint8_t track_07_ch3_pattern_data[60];
extern const uint8_t track_08_ch2_pattern_data[19];
extern const uint8_t track_08_ch3_pattern_data[25];
extern const uint8_t track_09_ch2_pattern_data[18];
extern const uint8_t track_09_ch3_pattern_data[21];
extern const uint8_t track_10_ch2_pattern_data[58];
extern const uint8_t track_10_ch3_pattern_data[57];
extern const uint8_t track_11_ch2_pattern_data[10];
extern const uint8_t track_11_ch3_pattern_data[6];
extern const uint8_t track_12_ch2_pattern_data[105];
extern const uint8_t track_12_ch3_pattern_data[231];

extern const uint8_t ch3_waveform_data[16];

extern const uint8_t ch1_env_data_index[32][5];

extern const uint8_t explosion_ch4_sfx_data[4];

extern void load_track_5_and_wait(void);

extern void set_event_extra_life(void);
extern void set_event_white_brick(void);
extern void set_event_unbreakable_brick(void);
extern void set_event_paddle_collision(void);
extern void set_event_light_grey_brick(void);
extern void set_event_dark_grey_brick(void);
extern void set_event_ball_launched(void);
extern void set_event_bonus_countdown(void);
extern void set_event_mario_jump(void);
extern void set_event_death_no_lives(void);
extern void set_event_ceiling(void);
extern void set_event_wall(void);

extern void load_track_title(void);
extern void load_track_start(void);
extern void load_track_game_over(void);
extern void load_track_pause(void);
extern void load_track_stage_complete(void);
extern void load_track_bonus_stage(void);
extern void load_track_bonus_stage_fast(void);
extern void load_track_bonus_stage_start(void);
extern void load_track_bonus_stage_lose(void);
extern void load_track_bonus_stage_win(void);
extern void load_track_brick_scrolldown(void);
extern void load_track_nice_play(void);

extern void music_playback_handler(void);

extern void pattern_loop_command(void);
extern void pattern_loop_command_mute_ch1(void);
extern void pattern_loop_command_mute_ch3(void);

extern void ch3_pattern_read_loop (uint16_t ch3_pattern);

extern void mute_ch2(void);
extern void ch2_set_note_length(uint16_t hl, uint8_t a);
extern void ch3_set_note_length(uint16_t hl, uint8_t a);
extern void load_ch3_waveform(void);

extern void stop_music_wrapper(void);