#pragma once
#include <stdint.h>
#include <stdbool.h>

// mirros HRAM layout from hram.asm
typedef struct {
    // system
    bool vblank_flag;
    uint8_t game_tick;
    bool object_dirty_flag;
    bool button_pressed_flag;
    uint8_t game_state;
    uint8_t lcdc_mirror;
    uint8_t lcdc_negative;
    uint8_t debug_scroll_x_init;
    uint8_t frame_accumulator;
    uint8_t init_hardware_flag_debug;
    uint8_t unused_blit_width;

    // input
    uint8_t button_pressed_neg;
    uint8_t button_pressed;
    uint8_t joypad_pressed;

    // serial RNG
    // NOTE: NOT EMULATED ACCURATELY - see hram.asm for details
    uint8_t serial_phase_counter;
    uint8_t serial_sample_curr;
    uint8_t serial_prev_sample;
    uint8_t serial_falling_edge_latch;

    // score digits
    uint8_t score_digit_ones;
    uint8_t score_digit_tens;
    uint8_t score_digit_hundreds;
    uint8_t score_digit_thousands;
    uint8_t score_digit_tens_of_thousands;

    // score

    // uint8_t player_score_lo;
    // uint8_t player_score_hi;

    uint16_t player_score;

    // uint8_t top_score_lo;
    // uint8_t top_score_hi;

    uint16_t top_score;

    // counters
    uint8_t lcd_y_descent_counter;
    uint8_t lcd_y_offset_counter;
    uint8_t unbreakable_brick_collision_counter;
    uint8_t unused_brick_collision_count;

    // extra life
    uint8_t extra_life_gained_total;

    // uint8_t extra_life_score_threshold_lo;
    // uint8_t extra_life_score_threshold_hi;

    uint16_t extra_life_score_threshold;

    // gameplay flags
    uint8_t ball_phase_through;
    uint8_t brick_scroll_flag;
    bool scrolling_x_stage_flag;
    bool ball_collision_flag;

    // ball
    uint8_t prev_ball_y;
    uint8_t prev_ball_x;
    uint8_t ball_y;
    uint8_t ball_y_subpixel;
    uint8_t ball_x;
    uint8_t ball_x_subpixel;

    // uint8_t ball_y_velocity_hi;
    // uint8_t ball_y_velocity_lo;

    uint16_t ball_y_velocity;

    // uint8_t ball_x_velocity_hi;
    // uint8_t ball_x_velocity_lo;

    uint16_t ball_x_velocity;

    uint8_t ball_y_mirror;
    uint8_t ball_x_mirror;
    uint8_t ball_velocity;

    // paddle
    uint8_t paddle_x;
    uint8_t paddle_size;
    uint8_t paddle_collision_width;
    uint8_t paddle_hit_counter;
    uint8_t init_paddle_y;

    // bricks
    uint8_t total_row_count;
    uint8_t brick_probe_x;
    uint8_t brick_type_last_hit;
    
    // uint8_t brick_tilemap_offset_hi;
    // uint8_t brick_tilemap_offset_lo;

    uint16_t brick_tilemap_offset;

    // uint8_t active_brick_count_hi;
    // uint8_t active_brick_count_lo;

    uint16_t active_brick_count;

    uint8_t play_area_scroll_y;
} HRAM;

extern HRAM hram;