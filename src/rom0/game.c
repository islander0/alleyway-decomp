#include "../hram.c"
#include "../wram.c"
#include "../cpu.c"
#include "../io.h"
#include "../enum.h"

#include <stdint.h>

uint8_t update_frame_accumulator() {
    uint8_t update_frame_count = 5;

    do {
        update_frame_count--;
    } while (update_frame_count != 0);

    hram.frame_accumulator += 0x41;
    return hram.frame_accumulator;
}

void state_boot_init (void) {
    hram.top_score = 200;

    hram.game_state = GAME_INIT;
}

void state_game_init (void) {
    wram.title_demo_cycle_index = 4;
    hram.game_state = TITLE_SCREEN;
}

void state_title_screen() {
    lcd_disable_and_wait_vblank();
    disable_interrupts_save();

    hram.joypad_pressed &= 0xFD;

    fill_tile_map_0();
    clear_main_oam_buffer();

    // ld de, $41CD
    process_copy_table(/*de ?*/);
    load_title_screen_score_buffer_oam();

    IO_REGS->bgp = 0xE4;

    hram.lcdc_mirror &= 0xDF;

    interrupt_enable();
    lcd_ppu_enable();

    wram.title_demo_cycle_index++ != 5
        ? wram.title_demo_cycle_index++
        : (wram.title_demo_cycle_index = 0);

    wram.title_demo_cycle_index == 0
        ? clear_demo_flag(), load_track_title()
        : set_demo_flag();

    wram.level_demo_cycle_timer = 3;

    do {
        wait_vblank();

        if (hram.game_tick != 0
        && (hram.button_pressed_flag &= 8) != 0)
        {
            wram.true_stage_number = 0;
            wram.stage_number_display = 0;
            wram.bonus_stage_number = 0;
            hram.extra_life_gained_total = 0;
            hram.player_score = 0;

            wram.life_counter = 4;

            set_next_extra_life_score_threshold();
            clear_demo_flag();
            level_load_handler();

            hram.game_state = LOAD_STAGE;
            return;
        }

        wram.level_demo_cycle_timer--;

        if (wram.level_demo_cycle_timer == 0) {
            hram.game_state = LOAD_DEMO_STAGE;
            return;
        }
    } while ((hram.serial_falling_edge_latch &= 0x80) != 0);
}

// WIP
// need to know what cpu->a is before creating a value
void state_load_demo(CPU *cpu) {
    set_demo_flag();
    level_load_handler();

    do {
        update_frame_accumulator();

        cpu->a &= 0x1F;
        wram.true_stage_number = cpu->a;
    } while (stage_properties[bonus] != false);

    wram.stage_number_display = 0xFF;
    hram.player_score_lo = 0;
    hram.player_score_hi = 0;
    wram.life_counter = 0;

    state_load_stage();
    wram.level_demo_cycle_timer = 10;

    shift_paddle_left();
    init_ball();

    hram.paddle_x = hram.ball_x - 11;

    update_paddle_oam_buffer();
    wait_frames(16);

    do {
        scroll_x_handler();
        ball_update();
        update_paddle_oam_buffer();

        hram.paddle_x = hram.ball_x - 11;

        clamp_paddle_x(0x80 - hram.paddle_collision_width);
        update_frame_accumulator();
        wait_vblank();

        if ((hram.button_pressed_flag & 8) == 0 ||
        (hram.serial_falling_edge_latch & 0x80) == 0) {
            hram.game_state = GAME_INIT;
            return;
        }
    } while (
        hram.game_tick != 0 ||
        (wram.level_demo_cycle_timer--) != 0
    );
    
    wait_frames(20);
    hram.game_state = TITLE_SCREEN;
    return;
}

void state_boot_init(void);
void state_game_init(void);
void state_title(void);
void state_load_demo(void);
void state_load_stage(void);
void state_standby_play(void);
void state_normal_play(void);
void state_lose_life(void);
void state_stage_clear(void);
void state_win(void);
void state_bonus(void);
void state_game_over(void);
void state_pause(void);
void state_null(void);

void (*game_state_table[16])(void) = {
    state_boot_init,
    state_game_init,
    state_title,
    state_load_demo,
    state_load_stage,
    state_standby_play,
    state_normal_play,
    state_lose_life,
    state_stage_clear,
    state_win,
    state_bonus,
    state_game_over,
    state_pause,
    state_null,
    state_null,
    state_null
};

void game_state_dispatcher() {
    if ((hram.button_pressed_neg & 0x08) != 0 || (hram.button_pressed_flag & 4) != 0x00) {
        game_state_table[hram.game_state]();
    }

    hram.game_state = GAME_INIT;
}

void main_loop(void) {
    while (1) {
        game_state_dispatcher();
        update_frame_accumulator();
        wait_vblank();
    }
}

int main(void) {
    audio_init();
    serial_init();

    hram.game_state = BOOT_INIT;
    hram.ball_phase_through = 0;
    hram.scrolling_x_stage_flag = 0;

    main_loop();
    return 0;
}



// WIP
void state_load_stage (void) {
    clear_bonus_time_text_vram();
    clear_special_bonus_text_vram();

    hram.ball_phase_through = 0;
    hram.scrolling_x_stage_flag = 0;                      
    hram.paddle_size = 0; 

    hram.paddle_collision_width = 0x18;
    
    /* Closer to ASM:

    if ((stage_properties_table[wram.true_stage_number * 3] &= (1 << 7)) == 1) {
        bonus_ball_set();
    } else {
        increment_stage_number_display();
    }

    if ((stage_properties_table[wram.true_stage_number * 3] &= (1 << 6)) == 1) {
        init_scrolling_stage_data();
    }

    */

    stage_properties[bonus] == true
        ? bonus_ball_set()
        : increment_stage_number_display();

    if (stage_properties[scrolling_x] != false) {
        init_scrolling_stage_data();
    }

    hram.paddle_x = 0x28;
    hram.init_paddle_y = 0x90;

    load_level_brick_data(wram.true_stage_number);
    count_level_bricks();
    init_scroll_x_table();
    load_wall_oam_buffer();
    update_score_oam_buffer();
    load_lives_number_vram();
    debug_ball_velocity();

    if (wram.stage_number_display == 1) {
        mario_start_handler();
    }

    hram.ball_phase_through == 0
        ? load_stage_number_oam_buffer()
        : load_bonus_text_oam_buffer()

    update_score_oam_buffer();
    debug_ball_velocity();
    load_lives_number_vram();
    load_stage_number_display_vram();
    wait_frames(16);();
    animate_bricks_scroll_in();
    clear_main_oam_buffer();
    update_score_oam_buffer();
    debug_ball_velocity();
    load_wall_oam_buffer();

    if (hram.ball_phase_through != 0) {
        bonus_start_handler();
    }

    hram.lcd_y_offset_counter = 0;
    hram.game_state = STANDBY_PLAY;
}

void game_win_handler(void) {
    wram.true_stage_number = (wram.true_stage_number + 1) % 0x20;
}

void lose_state(void) {
    hram.game_state = LOSE_LIFE;
}