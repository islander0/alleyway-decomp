#include "../../include/wram.h"
#include "../hram.c"

#include "../../include/rom0/audio.h"
#include "../../include/rom0/brick.h"
#include "../../include/rom0/render.h"

#include <stdint.h>
#include <stdbool.h>

// equivalent to SWAP A in ASM
static inline uint8_t swap_u8(uint8_t a) {
    return (a << 4) | (a >> 4);
}

void increment_stage_number_display(void) {
    stage_number_display++;
}

void add_brick_score_to_player_score(void) {
    hram.brick_type_last_hit--;
    uint8_t brick_property_4 = brick_data_table[hram.brick_type_last_hit][3];

    brick_property_4 = swap_u8(brick_property_4) & 0x0F;

    bool carry;
    bool carry_out;

    uint16_t overflow_check = (hram.player_score & 0x00FF) + brick_property_4;

    overflow_check > 0xFF
        ? (carry = 1)
        : (carry = 0);

    overflow_check = ((hram.player_score & 0xFF00) >> 8) + carry;

    overflow_check > 0xFF
        ? (carry_out = 1)
        : (carry_out = 0);

    hram.player_score += brick_property_4 + (carry << 4);

    if (!carry_out)
        return;

    hram.player_score = 0xFFFF;
}

void update_score_all(void) {
    if (hram.top_score < hram.player_score) {
        hram.top_score = hram.player_score;
    }
}

const uint16_t extra_life_threshold_table[10] = {
    1000, 2000, 3000, 4000, 5000,
    6000, 7000, 8000, 9000, 0xFFFF
};

void set_next_extra_life_score_threshold(void) {
    hram.extra_life_score_threshold = extra_life_threshold_table[hram.extra_life_gained_total];
    hram.extra_life_gained_total++;
}

void extra_life_score_handler(void) {
    if(hram.player_score % 1000 == 0) {
        if (life_counter < 9) {
            life_counter++;
            set_event_extra_life();
        }

        load_lives_number_vram();
        set_next_extra_life_score_threshold();
    }
}