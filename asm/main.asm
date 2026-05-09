; ================================== TO DO ==================================
; 0. Make .bin files
; 1. Add spaces to the instructions for clearer legibility
; 2. Figure out what w_unknown_dfd1, dfd2, dffe and dfff does
; 3. Review all sublabels to see if any more need labeling
; 4. Label more extensively each function/value:
;   a. Trigger
;   b. Hardware
;   c. Effect
; 5. Label every "magic" number (any "ld r, [$xxxx]" instruction or similar)
; 6. Label the remaining bytes of data inside ROM0
; 7. Verify byte-level integrity
; 8. Make a native C port
; ===========================================================================

; --- system ---
INCLUDE "rom0/reset.asm"
INCLUDE "rom0/interrupts.asm"

; --- game ---
INCLUDE "rom0/init.asm"
INCLUDE "rom0/game_loop.asm"
INCLUDE "rom0/bonus.asm"
INCLUDE "rom0/level.asm"
INCLUDE "rom0/utils.asm"
INCLUDE "rom0/audio.asm"

; --- gameplay systems ---
INCLUDE "rom0/paddle.asm"
INCLUDE "rom0/ball.asm"
INCLUDE "rom0/brick.asm"
INCLUDE "rom0/score.asm"

; --- rendering ---
INCLUDE "rom0/render.asm"
INCLUDE "rom0/anim.asm"
INCLUDE "rom0/lcd.asm"

; --- other registers ---
INCLUDE "wram0.asm" ; Enable WRAM0 mode in linker
INCLUDE "oam.asm"
INCLUDE "io.asm"
INCLUDE "hram.asm"