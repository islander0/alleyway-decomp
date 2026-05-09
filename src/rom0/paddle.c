#include "../hram.c"
#include "../wram.c"
#include "../cpu.c"

#include <stdint.h>
#include <stdbool.h>

#define NORMAL_PADDLE 0
#define SMALL_PADDLE 1

const uint8_t paddle_0_angle_steepness_data[16] = {
    3, 6, 6, 6,
    9, 9, 9, 9,
    9, 9, 9, 9,
    6, 6, 6, 3
};

const uint8_t paddle_1_angle_steepness_data[12] = {
    3, 6, 6, 9,
    9, 9, 9, 9,
    9, 6, 6, 3
};

const uint8_t paddle_hit_max_value_table[10] = {
    8, 8, 5, 5, 3, 3, 2, 2, 2, 2
};

void update_paddle_clamp_x(uint8_t paddle_clamp_offset) {
    hram.paddle_x = paddle_clamp_offset; 
};

void check_paddle_x_pos(uint8_t paddle_x, uint8_t paddle_collision_width) {
    if (paddle_x < paddle_collision_width)
        paddle_x = paddle_collision_width;

    update_paddle_clamp_x(paddle_x);
}

void set_paddle_x_15(uint8_t paddle_x) {
    paddle_x = 15;
    update_paddle_clamp_x(paddle_x);
}

void clamp_paddle_x (uint8_t paddle_x, uint8_t paddle_collision_width) {
    if (paddle_x >= 15) {
        check_paddle_x_pos(paddle_x, paddle_collision_width);
    } else {
        set_paddle_x_15(paddle_x);
    }
}

void paddle_movement_handler(void) {
    const uint8_t RIGHT_WALL = 0x7F;
    const uint8_t LEFT_WALL = 15;

    const uint8_t SLOW = 1;
    const uint8_t NORMAL = 3;
    const uint8_t FAST = 5;

    if (hram.serial_sample_curr < 0xF1) {
        uint8_t paddle_right_wall = RIGHT_WALL - hram.paddle_collision_width;

        uint8_t sample_curr = hram.serial_sample_curr;
        
        int underflow = sample_curr;
        bool carry = (underflow - 0x30) < 0;

        sample_curr -= 0x30;

        if (!carry) {
            clamp_paddle_x(sample_curr, paddle_right_wall);
        } else {
            set_paddle_x_15(sample_curr);
        }
    }

    uint8_t paddle_speed = FAST;   // A button pressed: fast
    uint8_t button = hram.button_pressed_neg;

    bool carry = (button & 0x01) == 1;
    button >>= 1;

    if (!carry)
        goto check_l_and_r;

    paddle_speed = SLOW;   // B button pressed: slow

    carry = (button & 0x01) == 1;
    button >>= 1;

    if (!carry)
        goto check_l_and_r;

    paddle_speed = NORMAL;   // No buttons pressed: normal

check_l_and_r:
    button = hram.button_pressed_neg ^ 0xFF;

    if (!(button & 0x30))
        return; // if L+R: don't move

    if (!(button & 0x20))
        goto move_paddle_right;

move_paddle_right:
    uint8_t paddle_right_wall = RIGHT_WALL - hram.paddle_collision_width;
    uint8_t next_paddle_x = hram.paddle_x + paddle_speed;

    if (next_paddle_x >= paddle_right_wall)
        next_paddle_x = paddle_right_wall;

    goto update_paddle_x;

// move_paddle_left:
    next_paddle_x = hram.paddle_x - paddle_speed;

    if (next_paddle_x < LEFT_WALL)
        next_paddle_x = LEFT_WALL;

update_paddle_x:
    hram.paddle_x = next_paddle_x;
}

void update_paddle_oam_buffer(void) {
    if (hram.paddle_size == SMALL_PADDLE) {
        wram.oam_buffer[OAM_PADDLE_START + 0] = hram.init_paddle_y;
        wram.oam_buffer[OAM_PADDLE_START + 1] = hram.paddle_x + 1;
        wram.oam_buffer[OAM_PADDLE_START + 2] = 0;
        wram.oam_buffer[OAM_PADDLE_START + 3] = 0;

        wram.oam_buffer[OAM_PADDLE_START + 4] = hram.init_paddle_y;
        wram.oam_buffer[OAM_PADDLE_START + 5] = hram.paddle_x + 9;
        wram.oam_buffer[OAM_PADDLE_START + 6] = 0;
        wram.oam_buffer[OAM_PADDLE_START + 7] = 0x20;

        wram.oam_buffer[OAM_PADDLE_START + 8] = hram.init_paddle_y;
        wram.oam_buffer[OAM_PADDLE_START + 9] = hram.paddle_x + 5;
        wram.oam_buffer[OAM_PADDLE_START + 10] = 1;
        wram.oam_buffer[OAM_PADDLE_START + 11] = 0;
    } else {    // NORMAL_PADDLE
        wram.oam_buffer[OAM_PADDLE_START + 0] = hram.init_paddle_y;
        wram.oam_buffer[OAM_PADDLE_START + 1] = hram.paddle_x + 1;
        wram.oam_buffer[OAM_PADDLE_START + 2] = 0;
        wram.oam_buffer[OAM_PADDLE_START + 3] = 0;

        wram.oam_buffer[OAM_PADDLE_START + 4] = hram.init_paddle_y;
        wram.oam_buffer[OAM_PADDLE_START + 5] = hram.paddle_x + 9;
        wram.oam_buffer[OAM_PADDLE_START + 6] = 1;
        wram.oam_buffer[OAM_PADDLE_START + 7] = 0;

        wram.oam_buffer[OAM_PADDLE_START + 8] = hram.init_paddle_y;
        wram.oam_buffer[OAM_PADDLE_START + 9] = hram.paddle_x + 17;
        wram.oam_buffer[OAM_PADDLE_START + 10] = 0;
        wram.oam_buffer[OAM_PADDLE_START + 11] = 0x20;
    }
}

void paddle_update(void) {
    paddle_movement_handler();
    update_paddle_oam_buffer();
}

void update_paddle_hit_counter(void) {
    hram.paddle_hit_counter--;

    if (hram.paddle_hit_counter != 0)
        paddle_hit_counter_set(hram.paddle_hit_counter);

    lcd_y_handler();
}

void paddle_collision_handler(uint8_t paddle_x) {
    uint8_t vel_offset = --hram.ball_velocity;
    uint16_t velocity = ball_velocity_ptr_table[vel_offset];

    uint8_t d = 0;
    uint8_t velocity_lo= ball_velocity_ptr_table[vel_offset] & 0x00FF;

    uint16_t steepness = paddle_0_angle_steepness_data[0];

    if (hram.paddle_size == SMALL_PADDLE)
        steepness = paddle_1_angle_steepness_data[0];

// LAB_1135
    uint16_t *p_steepness = &steepness;

    steepness += velocity_lo;
    steepness = (*p_steepness << 2) + velocity;

    velocity = *p_steepness;
    velocity = -velocity;

    steepness++;

    hram.ball_y_velocity = velocity;

    velocity = *p_steepness;

// LAB_115a
    if (hram.paddle_size == SMALL_PADDLE)
        d = 6;

    if (paddle_x < d)
        negate_velocity(velocity);

// LAB_1161
    hram.ball_x_velocity = velocity;

    update_paddle_hit_counter();
    set_event_paddle_collision();
}

void shift_paddle_left(void) {
    hram.paddle_size = NORMAL_PADDLE;
    hram.paddle_collision_width = 24;
    hram.paddle_x -= 4;

    uint8_t paddle_collision_width = 0x80 - hram.paddle_collision_width;

    // button = hram.paddle_x;
    clamp_paddle_x(hram.paddle_x, paddle_collision_width);
    paddle_collision_handler();
}