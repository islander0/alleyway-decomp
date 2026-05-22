#include "../hram.c"
#include "../../include/wram.h"
#include "../../include/io.h"

#include "../../include/rom0/anim.h"
#include "../../include/rom0/audio.h"
#include "../../include/rom0/ball.h"
#include "../../include/rom0/bonus.h"
#include "../../include/rom0/brick.h"
#include "../../include/rom0/game.h"
#include "../../include/rom0/init.h"
#include "../../include/rom0/lcd.h"
#include "../../include/rom0/level.h"
#include "../../include/rom0/paddle.h"
#include "../../include/rom0/render.h"
#include "../../include/rom0/reset.h"
#include "../../include/rom0/score.h"
#include "../../include/rom0/utils.h"

#include <stdint.h>

void lcd_ppu_enable(void) {
    hram.lcdc_mirror |= 0b10000000; // set bit 7
    IO_REGS->lcdc = hram.lcdc_mirror;
}

void lcd_disable_and_wait_vblank(void) {
    hram.lcdc_mirror &= 0b01111111; // clear bit 7
    wait_vblank(hram.lcdc_mirror);
}

uint8_t set_palette_data(uint8_t a) {
    IO_REGS->bgp = a;
    IO_REGS->obp0 = a;
    IO_REGS->obp1 = a;
    return 0;
}

void load_fade_in_data(void) {
    uint8_t *p_fade = palette_fade_data[0];
    
    goto set_counter;

game_win_fade_handler:
    *p_fade = palette_fade_data[4];

set_counter:
    uint8_t counter = 4;

    do {
        set_palette_data(*p_fade++);

        wait_frames(16);

        counter--;
    } while (counter != 0);

    return;
}

void lcd_stat_work() {
    if (hram.brick_scroll_flag++ >= 21) {
        hram.brick_scroll_flag = 0;

        IO_REGS->lyc = 7;
        IO_REGS->scy = lcd_y_vblank;
        IO_REGS->scx = 0;

        return;
    }

    IO_REGS->lyc = (hram.brick_scroll_flag << 2) + 11;
    IO_REGS->scx = scroll_x_table[hram.brick_scroll_flag];

    if (hram.brick_scroll_flag == 0) {
        IO_REGS->scy = lcd_y;
    }

    return;
}

void update_lcd_y(void) {
    uint8_t b = hram.lcd_y_descent_counter;

    lcd_y = b << 2;
    lcd_y_vblank = (b < 21) ? 112 : 176;
}

void lcd_y_handler () {
    if (hram.lcd_y_descent_counter == 0) {
        return;
    }

    hram.lcd_y_descent_counter--;

    load_track_brick_scrolldown();
    update_lcd_y();
    load_next_brick_line_obj();

    if (hram.lcd_y_descent_counter <= 1
    || (hram.lcd_y_descent_counter & 1) == 1) { // if value is odd
        return;
    }

    hram.play_area_scroll_y = hram.lcd_y_descent_counter - 1;
    brick_collision_handler();

    hram.play_area_scroll_y += 22;

    brick_collision_handler();
}