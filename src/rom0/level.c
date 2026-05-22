#include "../../include/wram.h"
#include "../hram.c"
#include "../../include/io.h"
#include "../../include/enum.h"

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

void level_load_handler(void) {
    lcd_disable_and_wait_vblank();
    disable_interrupts_save();
    fill_tile_map_0();
    fill_tile_map_1();
    clear_main_oam_buffer();
    stop_music_wrapper();

    IO_REGS->wx = 0x7F;
    IO_REGS->wy = 0;

    hram.lcdc_mirror |= 0x60;

    IO_REGS->lyc = 8;
    IO_REGS->stat = 0x44;
    
    hram.joypad_pressed |= 0x0A;

    set_palette_data(0xE4);
    process_copy_table(tilemap_patch_table[0]);

    if (hram.game_state != LOAD_DEMO_STAGE
        && stage_number_display != 0
        && true_stage_number == 0) 
    {
        process_copy_table(0x42B3);
        set_palette_data(0);
    }

    load_wall_oam_buffer();
    interrupt_enable();
    lcd_ppu_enable();
}