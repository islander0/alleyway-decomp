#include "../hram.c"
#include "../wram.c"
#include "../cpu.c"

#include <stdint.h>

const uint8_t bonus_stage_max_time[4] = {
    95, 90, 85, 80
};

const uint16_t bonus_stage_points[4] = {
    500, 700, 1000, 1500
};

void decrement_bonus_stage_time(void) {
    // if (hram.game_tick > 0b0001 1111)
    
    if (!(hram.game_tick & 32)) {
        wram.bonus_stage_time--;

        switch (wram.bonus_stage_time) {
            case 0:
                set_lose_state();

            case 20:
                load_track_bonus_stage_fast();

            default:
                load_bonus_stage_time_oam_buffer();
        }
    }
}

void load_bonus_stage_time_oam_buffer(void) {
    uint8_t time = wram.bonus_stage_time;
    binary_to_bcd(time);

    wram.oam_buffer[OAM_BONUS_STAGE_TIME_START + 0] = 0x80;
    wram.oam_buffer[OAM_BONUS_STAGE_TIME_START + 1] = 0x90;
    wram.oam_buffer[OAM_BONUS_STAGE_TIME_START + 2] = b + 0x80; // find out what b is
    wram.oam_buffer[OAM_BONUS_STAGE_TIME_START + 3] = 0;

    wram.oam_buffer[OAM_BONUS_STAGE_TIME_START + 4] = 0x80;
    wram.oam_buffer[OAM_BONUS_STAGE_TIME_START + 5] = 0x98;
    wram.oam_buffer[OAM_BONUS_STAGE_TIME_START + 6] = time + 0x80;
    wram.oam_buffer[OAM_BONUS_STAGE_TIME_START + 7] = 0;
}

uint8_t update_bonus_stage_properties(uint8_t bonus_stage) {
    bonus_stage = wram.bonus_stage_number - 1;
    
    if (bonus_stage >= 3)
        bonus_stage = 3;

    return bonus_stage;
}

void bonus_start_handler(void) {
    update_bonus_stage_properties();

    wram.bonus_stage_time = [hl];

    load_bonus_time_text_vram();
    load_bonus_stage_time_oam_buffer();
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
    update_bonus_stage_properties(bonus_stage);

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