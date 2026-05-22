#include "../hram.c"
#include "../../include/wram.h"

#include <stdint.h>

#include "../../include/rom0/audio.h"
#include "../../include/rom0/bonus.h"
#include "../../include/rom0/game.h"
#include "../../include/rom0/render.h"
#include "../../include/rom0/reset.h"
#include "../../include/rom0/score.h"
#include "../../include/rom0/utils.h"

#include "../../include/vram.h"

const uint8_t bonus_stage_max_time[4] = {
    95, 90, 85, 80
};

const uint16_t bonus_stage_points[4] = {
    500, 700, 1000, 1500
};

void load_bonus_stage_time_oam_buffer(uint8_t a, uint8_t b, uint8_t c) {
    uint8_t time = bonus_stage_time;

    binary_to_bcd(time, b, c);
    uint8_t tens = b;
    uint8_t ones = a;

    oam_buffer[OAM_BONUS_STAGE_TIME_START + 0] = 0x80; 
    oam_buffer[OAM_BONUS_STAGE_TIME_START + 1] = 0x90; 
    oam_buffer[OAM_BONUS_STAGE_TIME_START + 2] = tens + TILE_BLOCK_1_OFFSET;
    oam_buffer[OAM_BONUS_STAGE_TIME_START + 3] = 0;
    
    oam_buffer[OAM_BONUS_STAGE_TIME_START + 4] = 0x80;
    oam_buffer[OAM_BONUS_STAGE_TIME_START + 5] = 0x98;
    oam_buffer[OAM_BONUS_STAGE_TIME_START + 6] = ones + TILE_BLOCK_1_OFFSET;
    oam_buffer[OAM_BONUS_STAGE_TIME_START + 7] = 0;
}

void decrement_bonus_stage_time(void) {
    // if (hram.game_tick > 0001 1111)
    
    uint8_t a = hram.game_tick;
    a &= 0x1F;

    if (a != 0) {
        return;
    }

    bonus_stage_time--;
    a = bonus_stage_time;

    switch (bonus_stage_time) {
        case 0:
            set_lose_state();

        case 20:
            load_track_bonus_stage_fast();

        default:
            load_bonus_stage_time_oam_buffer(a, 0, 0);
    }
}

void update_bonus_stage_properties(void) {
    uint8_t bonus_stage = bonus_stage_number - 1;
    
    if (bonus_stage >= 3)
        bonus_stage = 3;
}

void bonus_start_handler(uint16_t hl) {
    update_bonus_stage_properties();
    
    uint16_t *p_hl = &hl;
    uint8_t a = *p_hl;
    bonus_stage_time = a;

    load_bonus_time_text_vram();
    load_bonus_stage_time_oam_buffer(a, 0, 0);
    load_track_bonus_stage_start();
    wait_frames(32);
}

void init_bonus_state(void) {
    uint8_t bonus_stage;

    stop_music_wrapper();

    if (hram.active_brick_count != 0) {
        load_track_bonus_stage_lose();
        wait_frames(128);
    }

    load_track_bonus_stage_win();

    wait_frames(255);
    wait_frames(64);

    // LAB_1a1a
    load_special_bonus_text_vram();
    update_bonus_stage_properties();

    uint8_t max_time = bonus_stage_max_time[bonus_stage];
    uint16_t points_left = bonus_stage_points[bonus_stage];

    load_special_bonus_points_oam_buffer();
    wait_frames(128);

    while (points_left > 0xFF) {
        points_left -= 10;

        load_special_bonus_points_oam_buffer();

        hram.player_score += 10;

        update_score_all();
        extra_life_score_handler();
        update_score_oam_buffer();
        set_event_bonus_countdown();
        wait_vblank();
    }

    if (points_left == 0)
        return;

    while (points_left != 0) {
        points_left--;

        load_special_bonus_points_oam_buffer();

        hram.player_score++;

        update_score_all();
        extra_life_score_handler();
        update_score_oam_buffer();
        set_event_bonus_countdown();
        wait_vblank();
    }
}