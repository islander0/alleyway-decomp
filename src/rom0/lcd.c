#include "../hram.c"
#include "../wram.c"
#include "../cpu.c"
#include "../io.h"

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

void load_fade_in_data(CPU *cpu) {
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
        IO_REGS->scy = wram.lcd_y_vblank;
        IO_REGS->scx = 0;

        return;
    }

    IO_REGS->lyc = (hram.brick_scroll_flag << 2) + 11;
    IO_REGS->scx = wram.scroll_x_table[hram.brick_scroll_flag];

    if (hram.brick_scroll_flag == 0) {
        IO_REGS->scy = wram.lcd_y;
    }

    return;
}

void update_lcd_y(void) {
    uint8_t b = hram.lcd_y_descent_counter;

    wram.lcd_y = b << 2;
    wram.lcd_y_vblank = (b < 21) ? 112 : 176;
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