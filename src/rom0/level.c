#include "../wram.c"
#include "../hram.c"
#include "../cpu.c"
#include "../io.h"
#include "../enum.h"

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
        && wram.stage_number_display != 0
        && wram.true_stage_number == 0) 
    {
        process_copy_table(0x42B3);
        set_palette_data(0);
    }

    load_wall_oam_buffer();
    interrupt_enable();
    lcd_ppu_enable();
}