#include "../include/wram.h"

uint8_t __AT(0xC000) brick_type_buffer[1024];
uint8_t __AT(0xC400) object_state_array[1024];
uint8_t __AT(0xC800) oam_buffer[0xA0];
uint8_t __AT(0xC900) bg_map_buffer_pad;
uint8_t __AT(0xC901) tile_buffer[0x13];

// scroll x
uint8_t __AT(0xCA00) scroll_x_table[SCROLL_X_TABLE_LEN];
uint8_t __AT(0xCA14) level_scroll_x_max_timer[LEVEL_SCROLL_X_MAX_TIMER_LEN];
uint8_t __AT(0xCA28) level_scroll_x_timer[LEVEL_SCROLL_X_TIMER_LEN];

// lcd
uint8_t __AT(0xCA3C) lcd_y;
uint8_t __AT(0xCA3D) lcd_y_vblank;

// animATion
uint8_t __AT(0xCA3E) current_anim_x;
uint8_t __AT(0xCA3F) current_anim_y;
uint8_t __AT(0xCA40) mario_anim_frame;
uint8_t __AT(0xCA41) anim_timer;
uint8_t __AT(0xCA42) mario_jump_frame_index;
uint8_t __AT(0xCA43) mario_jump_x_direction_flag;

// counter
uint8_t __AT(0xCA44) life_counter;

// stage values
uint8_t __AT(0xCA45) true_stage_number;
uint8_t __AT(0xCA46) stage_number_display;
uint8_t __AT(0xCA47) bonus_stage_number;
uint8_t __AT(0xCA48) bonus_stage_time;
uint8_t __AT(0xCA49) level_demo_cycle_timer;
uint8_t __AT(0xCA4B) title_demo_cycle_index;

// Audio
uint8_t __AT(0xDFD2) ch2_pan_active;
uint8_t __AT(0xDFD3) ch2_pan_timer;
uint8_t __AT(0xDFD4) ch2_pan_timer_max;
uint8_t __AT(0xDFD5) ch2_pan_direction;
uint8_t __AT(0xDFD6) ch2_pan_triggered_flag;
uint8_t __AT(0xDFE2) current_sfx_active;
uint8_t __AT(0xDFE3) music_flag;
uint8_t __AT(0xDFE4) ch1_current_track;
uint8_t __AT(0xDFE5) ch3_current_track;
uint8_t __AT(0xDFE6) sfx_envelope_counter;
uint8_t __AT(0xDFE8) track_index;
uint8_t __AT(0xDFE9) sfx_envelope;
uint8_t __AT(0xDFEB) ch2_note_length;
uint8_t __AT(0xDFEC) ch2_note_length_max;
uint8_t __AT(0xDFED) ch3_note_length;
uint8_t __AT(0xDFEE) ch3_note_length_max;
uint8_t __AT(0xDFF0) ch2_pattern_ptr_hi;
uint8_t __AT(0xDFF1) ch2_pattern_ptr_lo;
uint8_t __AT(0xDFF2) ch3_pattern_ptr_hi;
uint8_t __AT(0xDFF3) ch3_pattern_ptr_lo;
uint8_t __AT(0xDFF4) debug_sfx_clear_flag;
uint8_t __AT(0xDFF5) ch2_pitch_mirror;
uint8_t __AT(0xDFF6) ch3_pitch_mirror;
uint8_t __AT(0xDFF7) ch3_waveform_index;
uint8_t __AT(0xDFF8) music_triggered_flag;
uint8_t __AT(0xDFF9) ch4_pan_timer;
uint8_t __AT(0xDFFA) ch4_pan;
uint8_t __AT(0xDFFB) ch1_pitch;

uint8_t __AT(0xDFFC) ch1_freq_hi;
uint8_t __AT(0xDFFD) ch1_freq_lo;

// gameplay flags
uint8_t __AT(0xDFD7) ceiling_collision_sfx_active_flag;
uint8_t __AT(0xDFD8) demo_flag;
uint8_t __AT(0xDFE0) game_event;
uint8_t __AT(0xDFE1) ball_oob;

// Unknown
uint8_t __AT(0xDFD0) unknown_dfd0;
uint8_t __AT(0xDFD1) unknown_dfd1;
uint8_t __AT(0xDFFE) unknown_dffe;
uint8_t __AT(0xDFFF) unknown_dfff;