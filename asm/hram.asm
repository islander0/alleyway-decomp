SECTION "HRAM Region", HRAM[$FF80]

h_oam_dma_routine:: ds $0C ; used as a value in unused_joypad_update

; ----------------------------------------------------------------------
; oam_dma_routine is a function written at game_init from ROM0 at $03B5.
; ----------------------------------------------------------------------
; from $FF80 to $FF8B
; F3        DI
; 3E C8     LD A, $C8
; E0 46     LDH ($46)=>io_oam_dma_transfer, A
; 3E 28     LD A, $40
; 3D        DEC A
; 20 FD     JR NZ, $FD       jump back 3 bytes if not zero (loop)
; FB        EI
; C9        RET
; ----------------------------------------------------------------------
; side note: $FF81 is used by unused_joypad_press_latch,
; but never gets written to or read in regular game runtime 
; ----------------------------------------------------------------------

h_button_pressed_neg::  ds 1    ; input accumulator (inverted logic, $FF = neutral)

; --------------------------------------------------
; bit layout:
; --------------------------------------------------
; high nibble (d-pad, mutually cancelling directions)
;   bit 0: right  (-$01)
;   bit 1: left   (-$02)
;   bit 2: up     (-$04)
;   bit 3: down   (-$08)
;
; low nibble (buttons)
;   bit 0: A      (-$01)
;   bit 1: B      (-$02)
;   bit 2: Select (-$04)
;   bit 3: Start  (-$08)
; --------------------------------------------------

h_button_pressed_flag:: ds 1
h_button_pressed::      ds 1
h_ff8f_unused::         ds 1

; --------------------------------------------------
; !THE FOLLOWING 4 VALUES AREN'T EMULATED ACCURATELY!
; --------------------------------------------------
; These HRAM values implement a serial-port-based edge
; detection mechanism that depends on sampling an
; unconnected serial input line during transfer cycles.
; On real hardware this line may exhibit nondeterministic
; behavior, which is used here as a low-quality entropy
; source. Most emulators model the serial port
; deterministically (typically as constant $FF when
; idle), so the 1 -> 0 transition condition may never
; occur, making dependent code paths effectively
; unreachable.
; --------------------------------------------------

h_serial_phase_counter::            ds 1    ; $02 = set at VBlank
h_serial_sample_curr::              ds 1
h_serial_prev_sample::              ds 1
h_serial_falling_edge_latch::       ds 1    ; bit 7 = detected 1 -> 0 transition

; --------------------------------------------------

h_ff94_unused::                     ds 1
h_unused_blit_width::               ds 1    ; holds inner loop count of unused_tilemap_blit
h_score_digit_ones::                ds 1
h_score_digit_tens::                ds 1
h_score_digit_hundreds::            ds 1    ; Is set to $02 when the score isn't being updated. The appropriate hundreds' value is set after the check.
h_score_digit_thousands::           ds 1
h_score_digit_tens_of_thousands::   ds 1

; --------------------------
; 10 K Score Sprite
; --------------------------
; 0-9999:       FF Tile
; 10000-19999:	Fire Flower
; 20000-29999:	Mushroom
; 30000-65535:	Star
; --------------------------

h_init_hardware_flag_debug::    ds 1    ; unused for regular gameplay, only is set once
h_lcdc_mirror::                 ds 1
h_joypad_pressed::              ds 1    ; edge detect, buttons pressed this frame only
h_lcdc_negative::               ds 1    ; convenience copy, non-inverted (1 = pressed)
h_debug_scroll_x_init::         ds 1    ; debug value to signal that the init scroll x table has correctly reached its last instruction
h_vblank_flag::                 ds 1
h_frame_accumulator::           ds 1    ; Increments by $41 per frame.
h_game_tick::                   ds 1    ; Increments by 1 every frame. In the title screen, the timer overflows 3 times and then transitions to the demo.
h_object_dirty_flag::           ds 1    ; Set to 1 for one frame when any object is loaded/unloaded. Triggers sprite/object system refresh.
h_game_state::                  ds 1

; -------------------------------
; $00 = boot init
; $01 = game init
; $02 = title screen
; $03 = load demo
; $04 = load gameplay
; $05 = gameplay standby
; $06 = gameplay playing
; $07 = gameplay death
; $08 = level clear
; $09 = win
; $0A = bonus state handler
; $0B = game over / respawn check
; $0C = pause
; -------------------------------

h_extra_life_gained_total::         ds 1    ; tracks the number of lives gained in a single game doesn't decrement after life loss
h_extra_life_score_threshold_lo::   ds 1
h_extra_life_score_threshold_hi::   ds 1   
h_total_row_count::                 ds 1

; -------------------------------
; How many rows a level contains:
; -------------------------------
; Stage 01:	    14
; Stage 02:	    14
; Stage 03:	    40
; BONUS 03-B: 	20
; Stage 04:	    14
; Stage 05:	    14
; Stage 06:	    40
; BONUS 06-B:	20
; Stage 07:	    20
; Stage 08:	    20
; Stage 09: 	40 
; BONUS 09-B:	20
; Stage 10:	    16 
; Stage 11:	    16 
; Stage 12:     40
; BONUS 12-B: 	20
; Stage 13: 	18
; Stage 14: 	18 
; Stage 15: 	40
; BONUS 15-B: 	20
; Stage 16: 	20 
; Stage 17: 	20 
; Stage 18:	    40
; BONUS 18-B: 	20
; Stage 19: 	20
; Stage 20: 	20
; Stage 21: 	40
; BONUS 21-B: 	20
; Stage 22: 	18
; Stage 23: 	18
; Stage 24:	    40
; -------------------------------
; side note: all levels where the bricks fall down have 40 rows

h_lcd_y_descent_counter::  ds 1    ; init = $14
h_ball_phase_through::     ds 1

; $00: ball collides with bricks.
; $01: ball pierces through bricks.

h_scrolling_x_stage_flag::  ds 1

; $00: game_init, main, load_stage
; $01: set when the level's brick scroll horizontally

h_brick_scroll_flag::   ds 1

; $00: no scroll
; $01: bricks scroll

h_play_area_scroll_y::  ds 1

; Vertical scroll position of the brick play area, in 4px units.
; $3A = fully off-screen (top), $00 = fully revealed.
; 1. Level load: counts down from $3A to $00 (bricks slide in), step -2
; 2. Win sequence: counts up from $00 to $3A (bricks slide out), step +4
; 3. Used as coordinate transform in brick collision: SRL -> tile row index ($00 = ceiling row, $1C = bottom row near paddle)

h_brick_probe_x::             ds 1    ; X pixel coordinate used as input to brick collision lookup, $00 to $1C
h_prev_ball_y::             ds 1
h_prev_ball_x::             ds 1
h_brick_type_last_hit::     ds 1

; ---------------------------------------------------------------------
; tracks current and last ball collision (init = $00)
; ---------------------------------------------------------------------
; current (disappears after collision)
; $01: white brick
; $02: light grey brick
; $03: dark grey brick
; ---------------------------------------------------------------------
; also acts as an index for the most recent tile removed:
; e.g.: a brick is removed, set $FFB1 = $FF (transparent tile)
; ---------------------------------------------------------------------

h_brick_tilemap_offset_hi:: ds 1
h_brick_tilemap_offset_lo:: ds 1
h_ball_y::                  ds 1
h_ball_y_subpixel::         ds 1 ; intervals of $1E
h_ball_x::                  ds 1 ; $10 to $7C
h_ball_x_subpixel::         ds 1
h_ball_y_velocity_hi::      ds 1

; depending on the angle of the collision of the ball, it'll bounce at preset velocity values.
; $00 = down slow
; $01 = down fast
; $FE = up fast
; $FF = up slow

h_ball_y_velocity_lo::  ds 1
h_ball_x_velocity_hi::  ds 1
h_ball_x_velocity_lo::  ds 1
h_ball_y_mirror::       ds 1    ; = ball_y - 1
h_ball_x_mirror::       ds 1    ; = ball_x - 2
h_ball_velocity::       ds 1

; affects overall xy speed, updates when ball is spawned or paddle collision
; $03: init ball speed (white grey brick hit)
; $05: light grey hit
; $07: dark grey brick hit, if <= 40 bricks left to break or if ball_phase_through = 1

h_init_paddle_y::   ds 1    ; init = $90
h_paddle_x::        ds 1
h_paddle_size:      ds 1

; $00 = normal size
; $01 = reduced size after hitting ceiling

h_paddle_collision_width::  ds 1

; from the paddle's leftmost pixel to the right of it
; doesn't affect the ball's bounce direction/angle
; normal = $18
; small = $10

h_unused_brick_collision_count::    ds 1    ; $00 to $08, each 8th brick hit, the counter resets
h_paddle_hit_counter::              ds 1

; init = $08
; once this number hits 0, INC lcd_y_offset_counter and underflow the hit counter back to $08
; after lcd_y_offset_counter reaches $0A, the value only resets to 1, making it so that the bricks falls down every paddle hit (see also, paddle_hit_max_value_table)

h_lcd_y_offset_counter::                ds 1    ; tracks the number of times the LCD viewport has moved down: caps at $0A
h_unbreakable_brick_collision_counter:: ds 1    ; clear on ball launch, overflow at $10
h_ball_collision_flag::                 ds 1    ; set to 1 when collision with brick or ceiling (normal ball only)
h_active_brick_count_hi::               ds 1
h_active_brick_count_lo::               ds 1
h_player_score_lo::                     ds 1    ; ones and tens
h_player_score_hi::                     ds 1    ; hundreds and thousands
h_top_score_lo::                        ds 1    ; TOP SCORE: ones and tens
h_top_score_hi::                        ds 1    ; TOP SCORE: hundreds and thousands. = $2 on game_init, top score not saved upon game end.
h_unused_hram_block::                   ds $31  ; $FFCE-$FFFE, $FFFF is the IE register (see: ie.asm)