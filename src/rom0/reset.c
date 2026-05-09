#include "../hram.c"
#include "../wram.c"
#include "../cpu.c"
#include "../io.h"

#include <stdint.h>
#include <stdbool.h>

void vblank_handler(void) __interrupt {
    joypad_read();

    hram.serial_phase_counter = 2;
    IO_REGS->sc = 0b10000001;   // Transfer enable, Internal clock

    hram_oam_dma_routine();
    oam_buffer_update();

    IO_REGS->lcdc = hram.lcdc_mirror;
    IO_REGS->scx = hram.lcdc_negative;
    IO_REGS->scy = hram.debug_scroll_x_init;

    audio_update_thunk();

    hram.game_tick++;
    hram.vblank_flag = true;
}

void wait_vblank (void) {
    hram.vblank_flag = false

    while (!hram.vblank_flag) {
        __asm__("halt");
    }
}

void interrupt_enable(void) {
    IO_REGS->ie = hram.joypad_pressed;

    __asm__("ei");
}

void disable_interrupts_save(void) {
    h_joypad_pressed = IO_REGS->ie;
    IO_REGS->ie = 0;

    __asm__("di");
}

void wait_frames (uint8_t frames) {
    for (frames; frame < 0; frames--) {
        wait_vblank();
    }

    return;
}

void lcd_stat_handler(void) __interrupt {
    lcd_stat_work();
    IO_REGS->if &= 0b11111101;  // disable LCD interrupt handler
    // reti
}

void serial_falling_edge_detector_bit7(void) __interrupt {
    h_serial_phase_counter--;

    if (h_serial_phase_counter != 0) {
        h_serial_sample_curr = IO_REGS->sb;
        IO_REGS->sc = 0b10000001;   // Transfer enable, Internal clock
        return; // reti
    }
    
    uint8_t old = hram.serial_prev_sample;
    uint8_t new = IO_REGS->sb;

    hram.serial_prev_sample = new;
    hram.serial_falling_edge_latch = new | ~old;
    // reti
}

void serial_init(void) {
    IO_REGS->sb = a;
    IO_REGS->ie |= (1 << 4);
}

// Debug VBlank

static inline void update_interrupt_enable_register(uint8_t value) {
    IO_REGS->ie = value;
}

void debug_disable_vblank(void) {
    uint8_t interrupt = IO_REGS->ie & 0xFE; // clear VBlank bit
    update_interrupt_enable_register(interrupt);
}

void debug_enable_vblank(void) {
    uint8_t interrupt = IO_REGS->ie | 0x01; // set VBlank bit
    update_interrupt_enable_register(interrupt);
}

void enable_interrupts(void) __interrupt {} // reti