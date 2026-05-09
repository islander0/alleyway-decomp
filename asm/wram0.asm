SECTION "WRAM0 Region", WRAM0[$C000]

brick_type_buffer:: ds 1024

; these values are bools offset by +$400
; $01 = brick not hit
; $00 = brick hit

w_object_state_array:: ds 1024

; OAM staging buffer (shadow OAM)
; $C800–$C83F (64 bytes)

SECTION "WRAM OAM Buffer", WRAM0[$C800]

w_oam_buffer::  ds $A0  ; $C800-$C89F

DEF OAM_BUFFER_START    EQU $C800

w_unused_c8a0:: ds $60  ; $C8A0-$C8FF

; -------------------- Views (overlapping by design) ---------------------
DEF OAM_PADDLE_START                EQU w_oam_buffer + $00 ; $C800–$C80B
DEF OAM_GAME_OVER_START             EQU w_oam_buffer + $00 ; $C800–$C81E
DEF OAM_BALL_START                  EQU w_oam_buffer + $0C ; $C80C–$C80F
DEF OAM_DEBUG_BALL_VELOCITY_START   EQU w_oam_buffer + $10 ; $C810-$C813
DEF OAM_SCORE_START                 EQU w_oam_buffer + $14 ; $C814-$C???
DEF OAM_TITLE_SCORE_START           EQU w_oam_buffer + $28 ; $C828–$C83C
DEF OAM_WALL_START                  EQU w_oam_buffer + $3C ; $C83C–$C843

DEF OAM_STAGE_NUMBER_START          EQU w_oam_buffer + $80 ; $C880–$C89F
DEF OAM_BONUS_TEXT_START            EQU w_oam_buffer + $80 ; $C880–$C887
DEF OAM_BONUS_STAGE_TIME_START      EQU w_oam_buffer + $80 ; $C880–$C89F
DEF OAM_PAUSE_START                 EQU w_oam_buffer + $80 ; $C880–$C89F
DEF OAM_SPECIAL_BONUS_POINTS_START  EQU w_oam_buffer + $88 ; $C888–$C897
DEF OAM_MARIO_WALK_START            EQU w_oam_buffer + $88 ; $C888–$C897

SECTION "WRAM BG Map Buffer", WRAM0[$C900]

w_bg_map_buffer_pad::       ds 1    ; zeroed for alignment, syncs loop counter with $C90X addresses

DEF TILE_BUFFER_START   EQU $C901

w_tile_buffer::             ds $13  ; $C901–$C913 (12 tile IDs total), $C90B-$C911 unused
w_unused_c914::             ds $EC  ; $C914-$C9FF

SECTION "WRAM Counters and LCD Control", WRAM0[$CA00]   ; $CA00-$CA4B

; value represents where an individual line's x is
; from $00 to $6F (111 px -> width of the play area's borders)
; overflows for smooth wrap around effect

DEF W_SCROLL_X_TABLE_LEN    EQU 20            ; $CA00-$CA13

w_scroll_x_table::
    ds W_SCROLL_X_TABLE_LEN

; generally set to $04 for all of the array
; affects how fast one horizontal row (4 px tall) moves

DEF W_LEVEL_SCROLL_X_MAX_TIMER_LEN  EQU 20    ; $CA14-$CA27

w_level_scroll_x_max_timer::
    ds W_LEVEL_SCROLL_X_MAX_TIMER_LEN

DEF W_LEVEL_SCROLL_X_TIMER_LEN  EQU 20        ; $CA28-$CA3B

w_level_scroll_x_timer::
    ds W_LEVEL_SCROLL_X_TIMER_LEN

; tracks the y coordinate of the LCD's viewport
; descends in intervals of 8 px during the 3rd interation of a level

w_lcd_y::   ds 1    ; $CA3C

; set to 70 on level load
; never changes

w_lcd_y_vblank::            ds 1    ; $CA3D
w_current_anim_x::          ds 1    ; $CA3E
w_current_anim_y::          ds 1    ; $CA3F
w_mario_anim_frame::        ds 1    ; $CA40
w_anim_timer::              ds 1    ; $CA41, alternates 4-1 tick pattern per frame — possibly unintentional
w_mario_jump_frame_index::  ds 1    ; $CA42, caps at $18

; $00 = Mario goes left
; $01 = Mario goes right

w_mario_jump_x_direction_flag:: ds 1    ; $CA43

; $00 - $09
; value is capped

w_life_counter::    ds 1    ; $CA44

; from $00 to $0F
; counts bonus stage
; overflows to $00 after game win

w_true_stage_number::       ds 1    ; $CA45
w_stage_number_display::    ds 1    ; $CA46
w_bonus_stage_number::      ds 1    ; $CA47   ; increments on bonus stage load, overflow at $FF

; tracks how much time is left in the bonus stage
; bonus stage max time keeps decreasing by 5 seconds each consecutive bonus stage reached,
; until it caps at 80 seconds maximum after the 4th one
; overflow after bonus stage $FF

w_bonus_stage_time::    ds 1    ; $CA48

; counts down every time game_tick = $00
; so every          256 frames ≈ 4.25 seconds
; title screen: 	$03 = 12.8 seconds
; demo: 		    $0A ≈ 42.5 seconds

w_level_demo_cycle_timer::  ds 1    ; $CA49

; set to $00 when manually booting/exiting to title screen
; increment to $04 then overflows

w_unused_ca4a::             ds 1    ; $CA4A (confirmed unused)
w_title_demo_cycle_index::  ds 1    ; $CA4B

SECTION "WRAM Audio and Game Systems", WRAM0[$DFD0]   ; $DFD0 - $DFFF

w_unknown_dfd0::   ds 1    ; $DFD0
w_unknown_dfd1::   ds 1    ; $DFD1

; ---------------------------------------------
; bool value that only is = $01 when music that
; uses the auto-pan feature plays:
; ---------------------------------------------
; - title theme
; - game over
; - bonus
; - bonus fast
; ---------------------------------------------

w_ch2_pan_active::      ds 1    ; $DFD2
w_ch2_pan_timer::       ds 1    ; $DFD3   ; switches CH2's panning to the other side once the values hits 0
w_ch2_pan_timer_max::   ds 1    ; $DFD4   ; set the max value for w_ch2_pan_timer
w_ch2_pan_direction::   ds 1    ; $DFD5   ; $00 = right, $01 = left

; write-only debug remnant, set to 1 on any track where CH2 needs the auto-pan function
; never read during normal execution

w_ch2_pan_triggered_flag::  ds 1    ; $DFD6

; $00 = ceiling collision SFX not playing
; $01 = ceiling collision SFX currently playing

w_ceiling_collision_sfx_active_flag::   ds 1    ; $DFD7

; ---------------------------------------------
; demo_flag gets written to when going in and out 
; of demo mode it only gets cleared when the player
; presses starts or when the 5th demo in a row is 
; exited
; ---------------------------------------------
; $00 = not demo
; $01 = demo
; ---------------------------------------------

w_demo_flag::   ds 1    ; $DFD8
w_unused_dfd9:: ds 7

; $00 = no event
; $01 = extra life granted
; $02 = white brick hit
; $03 = unbreakable brick hit
; $04 = ball/paddle collision
; $05 = light grey brick hit
; $06 = dark grey brick hit
; $07 = ball launched (A pressed in standby)
; $08 = bonus clear points countdown active
; $09 = mario x jump threshold reached
; $0A = death explosion complete, no lives remain
; $0B = ceiling collision (!bonus levels)
; $0C = wall collision

w_game_event::  ds 1    ; $DFE0

; $00 = in-bounds
; $01 = out of bounds

w_ball_oob::            ds 1    ; $DFE1
w_current_sfx_active::  ds 1    ; $DFE2   ; mirrors game_event value
w_music_flag::          ds 1    ; $DFE3   ; cleared by stop_music

; cleared by stop_music
; active track number, stingers write 6 on completion

w_ch1_current_track::   ds 1    ; $DFE4
w_ch3_current_track::   ds 1    ; $DFE5

; tracks volume decay progression
; increments each frame until threshold
; $FF = constant volume (no decay)

w_sfx_envelope_counter::    ds 1    ; $DFE6
w_unused_dfe7::             ds 1
; ---------------------
; $00: N/A
; $01: Title
; $02: Start
; $03: Game Over
; $04: Pause
; $05: Stage Complete
; $06: Bonus Stage
; $07: Bonus Stage Fast
; $08: Bonus Stage Start
; $09: Bonus Stage Lose
; $0A: Bonus Stage Win
; $0B: Brick Scrolldown
; $0C: Nice Play!
;-----------------------

w_track_index:: ds 1    ; $DFE8

;---------------------------------------------
; value decrements until it reaches $01, then it gets
; reset at clear_sfx, effectively giving an offset
; of +$01 to the envelope.
; ---------------------------------------------
; $04: paddle collision, ball launch
; $05: white brick, light grey brick, dark grey brick,
;      unbreakable brick, points countdown
; $07: extra life
; ---------------------------------------------

w_sfx_envelope::            ds 1    ; $DFE9
w_unused_dfea::             ds 1
w_ch2_note_length::         ds 1    ; $DFEB
w_ch2_note_length_max::     ds 1    ; $DFEC
w_ch3_note_length::         ds 1    ; $DFED
w_ch3_note_length_max::     ds 1    ; $DFEE
w_unused_dfef::             ds 1
w_ch2_pattern_ptr_hi::      ds 1    ; $DFF0
w_ch2_pattern_ptr_lo::      ds 1    ; $DFF1
w_ch3_pattern_ptr_hi::      ds 1    ; $DFF2
w_ch3_pattern_ptr_lo::      ds 1    ; $DFF3
w_debug_sfx_clear_flag::    ds 1    ; $DFF4, unused debug flag (see: debug_set_sfx_clear_flag)
w_ch2_pitch_mirror::        ds 1    ; $DFF5
w_ch3_pitch_mirror::        ds 1    ; $DFF6
w_ch3_waveform_index::      ds 1    ; $DFF7, cycles $00-$15, tracks write position into wave RAM

; write-only debug remnant, set to $01 on any track play
; never read during normal execution

w_music_triggered_flag::    ds 1    ; $DFF8
w_ch4_pan_timer::           ds 1    ; $DFF9
w_ch4_pan::                 ds 1    ; $DFFA
w_ch1_pitch::               ds 1    ; $DFFB
w_ch1_freq_hi::             ds 1    ; $DFFC, written to NR14
w_ch1_freq_lo::             ds 1    ; $DFFD, written to NR13
w_unknown_dffe::            ds 1    ; $DFFE
w_unknown_dfff::            ds 1    ; $DFFF