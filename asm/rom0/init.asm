SECTION "Game Init", ROM0[$0150]

; Hardware initialization: clears VRAM/WRAM, loads tile data,
; sets up DMA routine, configures all I/O registers, then jumps to main.

game_init:
    ldh a, [rLY]
    cp $91
    jr c, game_init
    ld a, $0
    ldh [rLCDC], a 
    ld sp, $CFFF
    call disable_interrupts_save
    ld hl, $9FFF
    ld c, $1F
    xor a
    ld b, $0

.clear_vram
    ld [hl-], a ;=>[tile_map_1]
    dec b
    jr nz, .clear_vram
    dec c
    jr nz, .clear_vram
    ld hl, $DFFF    ; [hl] = w_unknown_dfff
    ld c, $3F
    xor a
    ld b, $0

.clear_wram
    ld [hl-], a    ; =>w_unknown_dfff, a
    dec b
    jr nz, .clear_wram
    dec c
    jr nz, .clear_wram
    ld hl, $FFFE
    ld b, $7F

.clear_hram
    ld [hl-], a
    dec b
    jr nz, .clear_hram
    ld hl, $FEFF
    ld b, $FF

.clear_oam
    ld [hl-], a     ; [hl] = DAT_FEff
    dec b
    jr nz, .clear_oam
    call load_tile_data
    call load_tile_map_0                         
    call load_tile_map_1
    ld c, $80
    ld b, $C
    ld hl, $3b5

.load_hram
    ld a, [hl+] ; =>[oma_dma_routine_data]
    ldh [c], a  ; =>[h_oam_dma_routine], a
    inc c
    dec b
    jr nz, .load_hram
    ld a, $1    ; Initialize hardware registers to default state
    ldh [rIF], a  
    ldh [h_joypad_pressed], a    
    ld a, $40
    ldh [rSTAT], a 
    xor a
    ldh [rSCY], a
    ldh [rSCX], a
    ld a, $0
    ldh [rLCDC], a 
    ld a, $E4    ; Color palette write
    ldh [rBGP], a
    ldh [rOBP0], a 
    ldh [rOBP1], a
    ld a, $FF
    ldh [h_button_pressed_neg], a
    ld a, $0
    ldh [rLYC], a
    ld a, $0
    ldh [rTAC], a 
    ld a, $0
    ldh [rTMA], a 
    ld a, $20
    ldh [h_init_hardware_flag_debug], a                    
    xor a
    ldh [rIF], a  
    xor a
    ldh [h_lcdc_negative], a     
    ldh [h_debug_scroll_x_init], a  
    ldh [h_game_state], a
    ldh [h_ball_phase_through], a
    ldh [h_scrolling_x_stage_flag], a                      
    ld a, $83
    ldh [h_lcdc_mirror], a 
    ldh [rLCDC], a 
    call interrupt_enable
    jp main

; set if the stage number displayed's value's bit 6 is se... *

SECTION "Stage Init", ROM0[$074C]

init_scrolling_stage_data:
    and $3F
    sla a
    ld c, a
    ld b, $0
    ld hl, $4075
    add hl, bc
    ld a, [hl+] ; BYTE_4075
    ld h, [hl]  ; BYTE_4076
    ld l, a
    ld bc, $CA14
    ld de, $CA28
    ld a, $14

.Lab_0762
    push af
    ld a, [hl+]
    ld [bc], a  ; =>[w_level_scroll_x_max_timer]
    and $7F
    ld [de], a      ; =>[w_level_scroll_x_timer]
    inc bc
    inc de
    pop af
    dec a
    jr nz, .Lab_0762
    ld a, $1
    ldh [h_scrolling_x_stage_flag], a                      
    ret

init_standby_play:
    call scroll_x_handler
    call paddle_update
    ldh a, [h_button_pressed_flag]          
    and $1
    jr z, init_ball
    ldh a, [h_serial_falling_edge_latch]    
    and $80
    ret nz

init_ball:
    xor a
    ldh [h_unused_brick_collision_count], a                
    ldh [h_unbreakable_brick_collision_counter], a         
    call update_brick_scrolldown_threshold
    call ball_spawn_handler
    call debug_ball_velocity
    call load_lives_number_vram
    call set_event_ball_launched
    ldh a, [h_ball_phase_through]           
    cp $0

.bonus_level_playing
    call nz, load_track_bonus_stage
    ld a, $6
    ldh [h_game_state], a
    ret

init_normal_play:
    ldh a, [h_ball_phase_through]           
    cp $0
    call nz, decrement_bonus_stage_time
    call scroll_x_handler
    call ball_update
    call paddle_update
    ldh a, [h_button_pressed_flag]          
    and $8
    jr z, .Lab_07c3
    ldh a, [h_serial_falling_edge_latch]    
    and $80
    ret nz
    ld a, $FF
    ldh [h_serial_falling_edge_latch], a                   

.Lab_07c3 
    ldh a, [h_ball_phase_through]           
    cp $0
    ret nz
    call load_pause_text_oam_buffer
    call load_track_pause
    ld a, $C
    ldh [h_game_state], a
    ret

init_lose_life:
    call stop_music_wrapper
    call explosion_oam_handler
    ld a, $40
    call wait_frames
    ldh a, [h_ball_phase_through]           
    cp $0
    jr nz, init_stage_clear
    ld a, $B
    ldh [h_game_state], a
    ld a, [w_life_counter]   ; =>[w_life_counter]        
    cp $0
    ret z
    dec a
    ld [w_life_counter], a    ; =>[w_life_counter], a 
    call load_lives_number_vram
    xor a
    ldh [h_paddle_size], a 
    ld a, $18
    ldh [h_paddle_collision_width], a                      
    ld a, $2
    ldh [h_lcd_y_offset_counter], a 
    ld a, $5
    ldh [h_game_state], a
    ret

init_stage_clear:
    ldh a, [h_ball_phase_through]           
    cp $0
    push af
    call z, load_track_5_and_wait
    pop af
    call nz, init_bonus_state
    call game_win_handler
    ld b, $4
    ld a, [w_true_stage_number]
    cp $0
    jr nz, .Lab_081f
    ld b, $9

.Lab_081f
    ld a, b
    ldh [h_game_state], a
    ret

SECTION "Win Sequence", ROM0[$0839]

init_win:
    call game_win_fade_handler  ; if stage number = 32
    ldh a, [h_joypad_pressed]               
    and $FD
    ldh [h_joypad_pressed], a    
    call level_load_handler
    ldh a, [h_joypad_pressed]               
    and $FD
    ldh [h_joypad_pressed], a    
    ldh [rIE], a
    call load_wall_oam_buffer
    call update_score_oam_buffer
    call load_lives_number_vram
    call debug_ball_velocity
    call load_stage_number_display_vram
    call load_track_nice_play
    call load_fade_in_data
    ld a, $0
    call wait_frames
    ld a, $0
    call wait_frames
    ld a, $A0
    call wait_frames
    ld a, $1
    call wait_frames    ; 161 frames
    call mario_wink_oam_handler
    ld a, $0
    call wait_frames
    ld a, $1
    call wait_frames    ; 1 frame
    call load_try_again_vram
    ld a, $C0
    call wait_frames    ; 192 frames
    call clear_try_again_vram
    call game_win_fade_handler
    ldh a, [h_joypad_pressed]               
    or $2
    ldh [h_joypad_pressed], a    
    ldh [rIE], a
    call clear_objects_wram0
    call bricks_slide_in_from_top
    call load_fade_in_data
    ld a, $4
    ldh [h_game_state], a   ; gameplay standby
    ret

SECTION "Game Over", ROM0[$08D1]

; when the players wins the game, the screens fades out and in to show the "win" screen.
; shifts bitwise data for the color indices in BGP, OBP0 and OBP1 at the same time.

init_game_over:
    call mario_game_over_handler
    ld a, $40
    call wait_frames    ; 64 frames
    call lcd_disable_and_wait_vblank
    call disable_interrupts_save
    call load_tile_map_0
    call load_main_oam_buffer
    ldh a, [h_lcdc_mirror] 
    and $DF
    ldh [h_lcdc_mirror], a 
    ldh a, [h_joypad_pressed]               
    and $FD
    ldh [h_joypad_pressed], a    
    call load_track_game_over
    call load_game_over_text_oam_buffer
    call interrupt_enable
    call lcd_ppu_enable
    ld a, $C0
    call wait_frames    ; 192 frames
    ld a, $1
    ldh [h_game_state], a   ; game init
    ret

init_pause:    
    ldh a, [h_button_pressed_flag]          
    and $8
    jr z, .Lab_0916
    ldh a, [h_serial_falling_edge_latch]    
    and $80
    ret nz
    ld a, $FF
    ldh [h_serial_falling_edge_latch], a                   

.Lab_0916
    call load_main_oam_buffer
    call update_score_oam_buffer
    call debug_ball_velocity
    call load_wall_oam_buffer
    call load_track_pause
    ld a, $6
    ldh [h_game_state], a   
    ret

SECTION "Audio Init", ROM0[$6375]

; Audio systems on
audio_init:
    ld a, $80
    ldh [rNR52], a 
    ld a, $77
    ldh [rNR50], a 
    ld a, $FF
    ldh [rNR51], a 
    ret