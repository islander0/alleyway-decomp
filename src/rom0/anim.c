#include "../../include/wram.h"
#include "../hram.c"
#include "../../include/cpu.h"

#include "../../include/rom0/anim.h"
#include "../../include/rom0/audio.h"
#include "../../include/rom0/ball.h"
#include "../../include/rom0/brick.h"
#include "../../include/rom0/paddle.h"
#include "../../include/rom0/render.h"
#include "../../include/rom0/reset.h"
#include "../../include/rom0/utils.h"

#include <stdint.h>

// Take two 8-bit values and combine them into a 16-bit register
#define MAKE_U16(h, l) (((uint16_t)(h) << 8) | (uint16_t)((uint8_t)(l)))

void animate_bricks_scroll_in() {
    hram.play_area_scroll_y = hram.total_row_count - 2;

    for (uint8_t i = 10; i != 0; i--) {
        brick_collision_handler();
        wait_vblank();
        hram.play_area_scroll_y = hram.play_area_scroll_y - 2;
    }

    if (hram.lcd_y_descent_counter == 0) {
        return;
    }

    hram.play_area_scroll_y = hram.lcd_y_descent_counter - 1;
    brick_collision_handler();
}

void update_mario_walking_frame() {
    anim_timer--;

    if (anim_timer != 0) {
        return;
    }

    mario_anim_frame++ < 3
        ? mario_anim_frame++
        : (mario_anim_frame = 0);

    anim_timer = 5;
}

void copy_current_anim_xy(void) {
    copy_tiles4_oam_buffer(
        current_anim_x,
        current_anim_y,
        mario_anim_frame
    );

    wait_vblank();
}

// open animation: 0 -> 1 -> 2 | close animation: 2 -> 1 -> 0
const uint8_t paddle_open_close_anim_spr_ptr[3] = {0, 1, 2};

const uint8_t paddle_open_frame_0_tile_data[3] = {0, 4, 0};
const uint8_t paddle_open_frame_1_tile_data[3] = {0, 3, 0};
const uint8_t paddle_open_frame_2_tile_data[3] = {2, 3, 2};

// WIP
void paddle_open_close_oam_handler(CPU *cpu) {
    uint8_t index = paddle_open_close_anim_spr_ptr[cpu->a];

    uint8_t b = index;
    cpu->e = 3;

    b = multiply(b, cpu->e);

    const uint16_t *hl = paddle_open_frame_0_tile_data + b;

    OAM_PADDLE_START[2] = *hl++;
    OAM_PADDLE_START[6] = *hl++;
    OAM_PADDLE_START[10] = *hl;

    return;
}

void paddle_open_anim_handler(CPU *cpu) {
    update_paddle_oam_buffer();

    for (cpu->a = 0; cpu->a < 3; cpu->a++) {
        paddle_open_close_oam_handler(cpu);
        wait_frames(8);
    }
}

void mario_jump_velocity_handler(void) {
    uint8_t prev = mario_jump_frame_index;
    mario_jump_frame_index++;

    current_anim_y += mario_jump_y_velocity_data[prev];

    current_anim_x += (mario_jump_x_direction_flag << 1) - 1;
}

void paddle_close_anim_handler(CPU *cpu) {
    for (cpu->a = 2; cpu->a != 0xFF; cpu->a--) {
        paddle_open_close_oam_handler(cpu);
        wait_frames(0xC);
    }
}

void mario_start_handler(void) { 
    update_paddle_oam_buffer();
    load_track_start();

    current_anim_x = hram.paddle_x + 0x50;
    current_anim_y = hram.init_paddle_y - 0x10;
    anim_timer = 3;

    //update mario walk
    while (1) {
        update_mario_walking_frame();
        copy_current_anim_xy();
        current_anim_x--;

        if (current_anim_x == 0x44)
            break;
    }

    mario_anim_frame = 3;
    copy_current_anim_xy();
    set_event_mario_jump();
    paddle_open_anim_handler();
    mario_anim_frame = 4;
    mario_jump_frame_index = 0;
    mario_jump_x_direction_flag = 0;

    // update mario_jump_velocity
    while (mario_jump_frame_index < 0x18) {
        copy_current_anim_xy();
        mario_jump_velocity_handler();
    }

    // lower mario
    while (current_anim_y < 0x88) {
        copy_current_anim_xy();
        current_anim_y += 4;
    }
    
    load_anim_oam_buffer();
    wait_frames(0x10);
    paddle_close_anim_handler();
    update_paddle_oam_buffer();
}

void mario_game_over_handler(CPU *cpu) {
    shift_paddle_left();
    update_paddle_oam_buffer();
    set_event_death_no_lives();
    paddle_open_anim_handler(cpu);

    current_anim_y = 0x88;
    current_anim_x = hram.paddle_x + 4;

    if (current_anim_x >= 76) {
        mario_jump_x_direction_flag = 0;
        mario_anim_frame = 5;
    } else {
        mario_jump_x_direction_flag = 1;
        mario_anim_frame = 6;
    }

    mario_jump_frame_index = 0;

    while (mario_jump_frame_index < 0x18) {
        copy_current_anim_xy();
        mario_jump_velocity_handler();
    }

    while (current_anim_y < 0xA0) {
        copy_current_anim_xy();
        current_anim_y += 4;
    }

    load_anim_oam_buffer();
    wait_frames(0x40);
}

const int8_t mario_jump_y_velocity_data[MARIO_JUMP_VEL_LEN] = {
    0xFD, 0xFD, 0xFD,   // -3
    0xFE, 0xFE, 0xFE,   // -2
    0xFF, 0xFF, 0xFF,   // -1
    0x00,               // 0
    0xFF,               // -1
    0x00, 0x00,         // 0
    0x01,               // 1
    0x00,               // 0
    0x01, 0x01, 0x01,   // 1
    0x02, 0x02, 0x02,   // 2
    0x03, 0x03, 0x03    // 3
};

const uint8_t explosion_anim_offset_data[EXPLOSION_ANIM_OFFSET_LEN] = {
    7, 7, 7, 7, 7, 7, 7, 7,
    8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8,
    9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9
};

void explosion_oam_handler(CPU *cpu) {
    set_ball_oob();

    current_anim_x = hram.ball_x - 8;
    current_anim_y = 0x90;
    anim_timer = 0;

    // next animation frame
    do {
        uint16_t bc = MAKE_U16(current_anim_x, current_anim_y);
        cpu->a = explosion_anim_offset_data[anim_timer];

        copy_tiles4_oam_buffer(bc, cpu->a);
        wait_vblank();

        anim_timer++;

    } while (anim_timer < 0x24);

    load_anim_oam_buffer();
}

const uint8_t mario_wink_anim_offset_data[MARIO_WINK_ANIM_OFFSET_LEN] = {
    0x0A, 0x0A, 0x0A, 0x0A, 0x0A, 0x0A, 0x0A, 0x0A,
    0x0B, 0x0B, 0x0B, 0x0B, 0x0B, 0x0B,
    0x0C, 0x0C, 0x0C, 0x0C, 0x0C, 0x0C,
    0x0B, 0x0B, 0x0B, 0x0B, 0x0B, 0x0B, 0x0B, 0x0B,
    0x0A
};

void mario_wink_oam_handler(CPU *cpu) {
    anim_timer = 0;

    //next animation frame
    do {
        uint16_t bc = 0x3848;
        cpu->a = mario_wink_anim_offset_data[anim_timer];

        copy_tiles4_oam_buffer(bc, cpu);
        wait_vblank();

        anim_timer++;

    } while (anim_timer < 0x1D);

    load_anim_oam_buffer();
}

const uint8_t anim_frame_tile_data[ANIM_FRAME_TILE_LEN] = {
    0x00, 0x00, 0x06, 0x80, 0x00, 0x08, 0x07, 0x80, 0x08, 0x00, 0x08, 0x80, 0x08, 0x08, 0x09, 0x80, // mario_walk_frame_0
    0x00, 0x00, 0x0A, 0x80, 0x00, 0x08, 0x0B, 0x80, 0x08, 0x00, 0x0C, 0x80, 0x08, 0x08, 0x0D, 0x80, // mario_walk_frame_1
    0x00, 0x00, 0x0E, 0x80, 0x00, 0x08, 0x0F, 0x80, 0x08, 0x00, 0x10, 0x80, 0x08, 0x08, 0x11, 0x80, // mario_walk_frame_2
    0x00, 0x00, 0x12, 0x80, 0x00, 0x08, 0x13, 0x80, 0x08, 0x00, 0x14, 0x80, 0x08, 0x08, 0x15, 0x80, // mario_still
    0x00, 0x00, 0x16, 0x80, 0x00, 0x08, 0x17, 0x80, 0x08, 0x00, 0x18, 0x80, 0x08, 0x08, 0x19, 0x80, // mario_jump_in
    0x00, 0x00, 0x1A, 0x80, 0x00, 0x08, 0x17, 0x80, 0x08, 0x00, 0x18, 0x80, 0x08, 0x08, 0x19, 0x80, // mario_jump_out_left
    0x00, 0x00, 0x17, 0xA0, 0x00, 0x08, 0x1A, 0xA0, 0x08, 0x00, 0x19, 0xA0, 0x08, 0x08, 0x18, 0xA0, // mario_jump_out_right
    0x00, 0x00, 0xFF, 0x00, 0x00, 0x08, 0xFF, 0x00, 0x08, 0x00, 0x1B, 0x00, 0x08, 0x08, 0x1B, 0x20, // explosion_frame_0
    0x00, 0x00, 0x1C, 0x00, 0x00, 0x08, 0x1C, 0x20, 0x08, 0x00, 0x1D, 0x00, 0x08, 0x08, 0x1D, 0x20, // explosion_frame_1
    0x00, 0x00, 0x1E, 0x00, 0x00, 0x08, 0x1E, 0x20, 0x08, 0x00, 0x1F, 0x00, 0x08, 0x08, 0x1F, 0x20, // explosion_frame_2
    0x00, 0x00, 0xFF, 0x00, 0x00, 0x08, 0xFF, 0x00, 0x08, 0x00, 0xFF, 0x00, 0x08, 0x08, 0xFF, 0x00, // mario_wink_frame_0
    0x00, 0x00, 0x21, 0x00, 0x00, 0x08, 0x22, 0x00, 0x08, 0x00, 0x23, 0x00, 0x08, 0x08, 0x24, 0x00, // mario_wink_frame_1
    0x00, 0x00, 0x21, 0x00, 0x00, 0x08, 0x22, 0x00, 0x08, 0x00, 0x25, 0x00, 0x08, 0x08, 0x26, 0x00  // mario_wink_frame_2
};