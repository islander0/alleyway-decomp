DEF GAME_STATE_JUMP_TABLE_START     EQU $054C
DEF STAGE_PROPERTIES_TABLE_START    EQU $1BE1

SECTION "Main", ROM0[$0505]

; Advances a hidden frame accumulator (likely debug leftover).
; Adds $41 per frame via 5 iterations of +$0D.

update_frame_accumulator:
    ld b, $5
    ldh a, [h_frame_accumulator]  ; starts at $00

.increment_frame_accumulator
    add $D
    dec b
    jr nz, .increment_frame_accumulator
    ldh [h_frame_accumulator], a; clear ffa1
    ret

; Audio and Serial registers are initialized. The main loop is contained here.

main:
    nop
    call audio_init
    call serial_init
    xor a
    ldh [h_game_state], a
    ldh [h_ball_phase_through], a
    ldh [h_scrolling_x_stage_flag], a

main_loop:
    call game_state_dispatcher
    call update_frame_accumulator
    call wait_vblank
    jp main_loop

; Reads game_state value, uses it for the jump table and JP to corresponding handler.

game_state_dispatcher:
    ldh a, [h_button_pressed_neg]
    and $8  ; 0000 1000
    jr nz, .state_dispatch

    ldh a, [h_button_pressed_flag]
    and $4
    jr nz, .state_dispatch

    ld a, $1
    ldh [h_game_state], a
    ret

.state_dispatch
    ldh a, [h_game_state]  
    sla a

    ld c, a
    ld b, $0
    ld hl, GAME_STATE_JUMP_TABLE_START
    add hl, bc

    ld a, [hl+] ; =>[game_state_jump_table_lo] -> low nibble
    ld b, a
    
    ld h, [hl]  ; =>[game_state_jump_table_hi] -> high nibble
    ld l, b

.state_dispatcher
    jp hl

; ----------------------------------------------|
; 16 x 16-bit addresses, little endian          |  
; ----------------------------------------------|
; [1] state $00    boot init               $056C|   
; [2] state $01    game init               $0578|   
; [3] state $02    title screen            $0582|   
; [4] state $03    load demo stage         $0613|   
; [5] state $04    load stage              $06A2|
; [6] state $05    standby play            $0773|  
; [7] state $06    normal play             $07A4|   
; [8] state $07    lose life               $07D3|   
; [9] state $08    stage clear             $0805|   
; [10] state $09   win                     $0839|   
; [11] state $0A   bonus state handler     $19F7|   
; [12] state $0B   game over/respawn check $08D1|   
; [13] state $0C   pause                   $0907|   
; [14-16] $0D-$0F  null handler            $022C|   
; ----------------------------------------------|
                   
game_state_jump_table:
    db $6C,$05
    db $78,$05
    db $82,$05
    db $13,$06
    db $A2,$06
    db $73,$07
    db $A4,$07
    db $D3,$07
    db $05,$08
    db $39,$08
    db $F7,$19
    db $D1,$08
    db $07,$09
    db $2C,$02
    db $2C,$02
    db $2C,$02

; set top score to 200 (no save feature)

state_boot_init:
    ld a, $C8
    ldh [h_top_score_lo], a

    xor a
    ldh [h_top_score_hi], a

    ld a, $1
    ldh [h_game_state], a
    ret

state_game_init:
    ld a, $4
    ld [w_title_demo_cycle_index], a

    ld a, $2
    ldh [h_game_state], a
    ret

state_title_screen:
    call lcd_disable_and_wait_vblank
    call disable_interrupts_save

    ldh a, [h_joypad_pressed]
    and $FD
    ldh [h_joypad_pressed], a
    
    call load_tile_map_0
    call load_main_oam_buffer 

    ld de, $41CD    ; LABEL MAGIC NUMBER
    call process_copy_table
    call load_title_screen_top_score_buffer_oam

    ld a, $E4
    ldh [rBGP], a

    ldh a, [h_lcdc_mirror]
    and $DF
    ldh [h_lcdc_mirror], a

    call interrupt_enable
    call lcd_ppu_enable

    ld a, [w_title_demo_cycle_index]
    inc a
    cp $5
    jr nz, .Lab_05b6

    xor a

.Lab_05b6
    ld [w_title_demo_cycle_index], a
    cp $0
    push af
    push af
    call z, clear_demo_flag

    pop af
    call z, load_track_title

    pop af
    call nz, set_demo_flag

    ld a, $3
    ld [w_level_demo_cycle_timer], a

.Lab_05cd
    call wait_vblank

    ldh a, [h_game_tick]
    cp $0
    jr nz, .Lab_05df

    ld a, [w_level_demo_cycle_timer]
    dec a
    ld [w_level_demo_cycle_timer], a

    jr z, .Lab_060e

.Lab_05df
    ldh a, [h_button_pressed_flag]
    and $8
    jr z, .Lab_05eb

    ldh a, [h_serial_falling_edge_latch] 
    and $80
    jr nz, .Lab_05cd

.Lab_05eb
    xor a
    ld [w_true_stage_number], a
    ld [w_stage_number_display], a
    ld [w_bonus_stage_number], a
    ldh [h_extra_life_gained_total], a
    ldh [h_player_score_lo], a
    ldh [h_player_score_hi], a

    ld a, $4
    ld [w_life_counter], a

    call set_next_extra_life_score_threshold
    call clear_demo_flag
    call level_load_handler

    ld a, $4
    ldh [h_game_state], a
    ret

.Lab_060e
    ld a, $3
    ldh [h_game_state], a
    ret

state_load_demo:
    call set_demo_flag
    call level_load_handler

.Lab_0619
    call update_frame_accumulator

    and $1F
    ld [w_true_stage_number], a

    ld b, a
    ld e, $3
    call multiply

    ld hl, STAGE_PROPERTIES_TABLE_START
    add hl, bc
    ld a, [hl]
    bit $7, a
    jr nz, .Lab_0619

    ld a, $FF
    ld [w_stage_number_display], a

    inc a
    ldh [h_player_score_lo], a 
    ldh [h_player_score_hi], a 
    ld [w_life_counter], a

    call state_load_stage

    ld a, $A
    ld [w_level_demo_cycle_timer], a

    call shift_paddle_left
    call init_ball

    ldh a, [h_ball_x]   
    sub $B
    ldh [h_paddle_x], a

    call update_paddle_oam_buffer
    
    ld a, $10
    call wait_frames

.Lab_0659 
    call scroll_x_handler
    call ball_update
    call update_paddle_oam_buffer

    ldh a, [h_paddle_collision_width]   
    ld b, a
    ld a, $80
    sub b
    ld b, a

    ldh a, [h_ball_x]   
    sub $B
    ldh [h_paddle_x], a

    call clamp_paddle_x
    call update_frame_accumulator
    call wait_vblank

    ldh a, [h_button_pressed_flag]
    and $8
    jr z, .Lab_069d

    ldh a, [h_serial_falling_edge_latch] 
    and $80
    jr z, .Lab_069d

    ldh a, [h_game_tick]
    cp $0
    jr nz, .Lab_0659

    ld a, [w_level_demo_cycle_timer]
    dec a
    ld [w_level_demo_cycle_timer], a
    jr nz, .Lab_0659

    ld a, $20
    call wait_frames
    ld a, $2
    ldh [h_game_state], a
    ret

.Lab_069d  
    ld a, $1
    ldh [h_game_state], a
    ret

state_load_stage:
    call clear_bonus_time_text_vram
    call clear_special_bonus_text_vram

    xor a
    ldh [h_ball_phase_through], a
    ldh [h_scrolling_x_stage_flag], a 
    ldh [h_paddle_size], a

    ld a, $18
    ldh [h_paddle_collision_width], a

    ld a, [w_true_stage_number]
    ld b, a
    ld e, $3
    call multiply
    ld hl, STAGE_PROPERTIES_TABLE_START
    add hl, bc

    ld a, [hl]
    bit $7, a

    push af
    push af
    call nz, bonus_ball_set

    pop af
    call z, increment_stage_number_display

    pop af
    bit $6, a
    call nz, init_scrolling_stage_data

    ld a, $28
    ldh [h_paddle_x], a

    ld a, $90
    ldh [h_init_paddle_y], a

    ld a, [w_true_stage_number]
    call load_level_brick_data
    call count_level_bricks
    call init_scroll_x_table

    xor a
    ldh a, [h_brick_scroll_flag] ; useless load, A register gets overwritten in load_wall_oam_buffer;
    call load_wall_oam_buffer
    call update_score_oam_buffer
    call load_lives_number_vram
    call debug_ball_velocity

    ld a, [w_stage_number_display]
    cp $1
    call z, mario_start_handler

    ldh a, [h_ball_phase_through]
    cp $0
    push af
    call z, load_stage_number_oam_buffer
    pop af
    call nz, load_bonus_text_oam_buffer

    call update_score_oam_buffer
    call debug_ball_velocity
    call load_lives_number_vram
    call load_stage_number_display_vram

    ld a, $10
    call wait_frames
    call animate_bricks_scroll_in
    call load_main_oam_buffer
    call update_score_oam_buffer
    call debug_ball_velocity
    call load_wall_oam_buffer

    ldh a, [h_ball_phase_through]
    cp $0
    call nz, bonus_start_handler

    xor a
    ldh [h_lcd_y_offset_counter], a

    ld a, $5
    ldh [h_game_state], a

    ret

SECTION "Game Win Handler", ROM0[$082B]

; checks if the player has reached the last level  
; if so, load the win animation/screen and set the player back to level 0

game_win_handler:
    ld a, [w_true_stage_number]
    inc a
    cp $20
    jr c, .load_next_true_stage_number
    ld a, $0

.load_next_true_stage_number
    ld [w_true_stage_number], a ; if stage number < 32
    ret

SECTION "Lose State", ROM0[$19C7]

set_lose_state:
    ld a, $7
    ldh [h_game_state], a
    ret

SECTION "Unknown Data", ROM0[$4075]

unknown_rom_data:
    db $8D,$40,$A1,$40,$B5,$40,$C9,$40,$DD,$40,$F1,$40,$05,$41,$19,$41,$2D,$41,$41,$41,$55,$41,$69,$41,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$00,$00,$04,$04,$00,$00,$84,$84,$00,$00,$04,$04,$04,$04,$00,$00,$00,$00,$00,$00,$00,$00,$08,$08,$08,$08,$04,$04,$04,$04,$04,$04,$02,$02,$02,$02,$02,$02,$02,$02,$00,$00,$84,$84,$04,$04,$84,$84,$04,$04,$84,$84,$04,$04,$84,$84,$00,$00,$00,$00,$00,$00,$8F,$8F,$8F,$8F,$8F,$04,$04,$04,$04,$04,$0F,$0F,$0F,$0F,$0F,$0F,$00,$00,$00,$00,$10,$10,$10,$10,$10,$10,$10,$10,$10,$10,$10,$10,$10,$10,$00,$00,$84,$84,$00,$00,$84,$84,$84,$84,$84,$84,$84,$84,$04,$04,$84,$84,$84,$84,$84,$84,$84,$84,$00,$00,$00,$00,$00,$00,$84,$84,$84,$84,$84,$84,$04,$04,$04,$04,$04,$04,$00,$00,$09,$09,$89,$89,$09,$09,$89,$89,$09,$09,$89,$89,$09,$09,$89,$89,$09,$09,$81,$81,$01,$01,$01,$01,$81,$01,$81,$01,$81,$01,$81,$01,$81,$01,$81,$01,$81,$01,$81,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$81,$01,$81,$01,$81,$01,$81,$01,$81,$01,$81,$01,$81,$01,$81,$01,$81,$01,$81,$01,$02,$03,$04,$05,$06,$07,$08,$09,$0A,$0B,$0C,$0D,$0E,$0F,$10,$11,$12,$13,$14,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$98,$00,$14,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$98,$20,$14,$AC,$AC,$A9,$A9,$A9,$A9,$A9,$A9,$A9,$A9,$A9,$A9,$A9,$A9,$A9,$A9,$A9,$AC,$AC,$A9,$98,$40,$10,$FF,$FF,$FF,$AB,$FF,$A8,$AB,$A8,$A8,$FF,$AB,$A8,$A8,$FF,$A8,$AB,$98,$61,$02,$0E,$01,$98,$71,$02,$9D,$96,$98,$81,$11,$02,$03,$08,$FF,$08,$FF,$00,$15,$08,$08,$08,$08,$08,$0E,$01,$08,$08,$98,$A1,$11,$02,$03,$09,$FF,$09,$FF,$02,$16,$09,$09,$09,$09,$09,$02,$03,$09,$09,$98,$C1,$11,$02,$06,$09,$FF,$09,$FF,$02,$17,$04,$07,$09,$09,$09,$02,$06,$04,$07,$98,$E1,$11,$02,$03,$0A,$0B,$0A,$0B,$02,$0B,$FF,$09,$02,$A7,$06,$02,$03,$FF,$09,$99,$01,$11,$13,$14,$0C,$0D,$0C,$0D,$10,$0D,$08,$09,$0F,$12,$11,$13,$14,$08,$09,$99,$29,$02,$04,$05,$99,$30,$02,$04,$05,$99,$63,$09,$9D,$98,$99,$FF,$9C,$8C,$98,$9B,$8E,$99,$C3,$0E,$99,$9E,$9C,$91,$FF,$9C,$9D,$8A,$9B,$9D,$FF,$94,$8E,$A2,$9A,$04,$0C,$1E,$81,$89,$88,$89,$FF,$18,$19,$1A,$1B,$1C,$1D,$00,$98,$43,$0A,$97,$92,$8C,$8E,$FF,$99,$95,$8A,$A2,$1F,$98,$84,$07,$44,$45,$FF,$FF,$FF,$44,$45,$98,$A3,$09,$44,$46,$20,$21,$22,$23,$24,$44,$45,$98,$C2,$0B,$44,$45,$25,$26,$27,$28,$29,$2A,$2B,$44,$45,$98,$E2,$0B,$44,$45,$2C,$2D,$2E,$2F,$30,$31,$32,$44,$45,$99,$02,$0B,$44,$45,$33,$A5,$34,$35,$A5,$36,$37,$44,$45,$99,$22,$0B,$44,$45,$38,$39,$3A,$3B,$3C,$3D,$3E,$44,$45,$99,$43,$09,$44,$45,$3F,$40,$41,$42,$43,$44,$45,$99,$63,$09,$47,$48,$49,$4A,$4B,$4C,$4D,$4E,$4F,$99,$83,$09,$50,$51,$52,$53,$54,$55,$56,$57,$58,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$00,$00,$00,$FF

; NEVER REACHED

SECTION "Unused Event System", ROM0[$681A]

unused_set_game_event:
    ldh a, [$FF81]  ; =>[h_unused_joypad_press_latch]
    bit $0, a
    jp nz, .LAB_6847
    bit $1, a
    jp nz, .LAB_684d
    bit $3, a
    jp nz, .LAB_6853
    bit $2, a
    jp nz, .LAB_6859
    bit $4, a
    jp nz, .LAB_685f
    bit $5, a
    jp nz, .LAB_6865
    bit $6, a
    jp nz, .LAB_686b
    bit $7, a
    jp nz, .LAB_6871
    jp LAB_6877

.LAB_6847 
    ld a, $1
    ld [w_game_event], a
    ret

.LAB_684d
    ld a, $2
    ld [w_game_event], a
    ret

.LAB_6853
    ld a, $3
    ld [w_game_event], a
    ret

.LAB_6859
    ld a, $4
    ld [w_game_event], a
    ret

.LAB_685f
    ld a, $5
    ld [w_game_event], a
    ret

.LAB_6865
    ld a, $6
    ld [w_game_event], a
    ret

.LAB_686b
    ld a, $7
    ld [w_game_event], a
    ret

.LAB_6871
    ld a, $8
    ld [w_game_event], a
    ret

LAB_6877:
    ret

unused_game_event_track_handler:
    ldh a, [$FF81]  ; [h_unused_joypad_press_latch] 
    bit $0, a
    jp nz, .LAB_68a5
    bit $1, a
    jp nz, .LAB_68ae
    bit $3, a
    jp nz, .LAB_68b7
    bit $2, a
    jp nz, .LAB_68c0
    bit $4, a
    jp nz, .LAB_68c9
    bit $5, a
    jp nz, .LAB_68d2
    bit $6, a
    jp nz, .LAB_68db
    bit $7, a
    jp nz, .LAB_68e4
    jp .LAB_68ed

.LAB_68a5
    ld a, $1
    ld [w_game_event], a
    ld [w_track_index], a
    ret

.LAB_68ae
    ld a, $2
    ld [w_game_event], a
    ld [w_track_index], a
    ret

.LAB_68b7
    ld a, $3
    ld [w_game_event], a
    ld [w_track_index], a
    ret

.LAB_68c0
    ld a, $4
    ld [w_game_event], a
    ld [w_track_index], a
    ret

.LAB_68c9
    ld a, $5
    ld [w_game_event], a
    ld [w_track_index], a
    ret

.LAB_68d2
    ld a, $6
    ld [w_game_event], a
    ld [w_track_index], a
    ret

.LAB_68db
    ld a, $7
    ld [w_game_event], a
    ld [w_track_index], a
    ret

.LAB_68e4
    ld a, $8
    ld [w_game_event], a
    ld [w_track_index], a
    ret

.LAB_68ed
    ret

; ball_oob in this function most likely used to be either the game_track or
; game_event at some point in development before getting switched

unused_event_handler:
    ldh a, [$FF81]  ; [h_unused_joypad_press_latch]
    bit $0, a
    jp nz, .LAB_691b

    bit $1, a
    jp nz, .LAB_6921

    bit $3, a
    jp nz, .LAB_6927

    bit $2, a
    jp nz, .LAB_692d

    bit $4, a
    jp nz, .LAB_6933

    bit $5, a
    jp nz, .LAB_6939

    bit $6, a
    jp nz, .LAB_693F

    bit $7, a
    jp nz, .LAB_6945
    jp LAB_6877

.LAB_691b
    ld a, $1
    ld [w_ball_oob], a
    ret

.LAB_6921
    ld a, $2
    ld [w_ball_oob], a
    ret

.LAB_6927
    ld a, $3
    ld [w_ball_oob], a
    ret

.LAB_692d
    ld a, $4
    ld [w_ball_oob], a
    ret

.LAB_6933
    ld a, $5
    ld [w_ball_oob], a
    ret

.LAB_6939
    ld a, $6
    ld [w_ball_oob], a
    ret

.LAB_693F
    ld a, $7
    ld [w_ball_oob], a
    ret

.LAB_6945
    ld a, $8
    ld [w_ball_oob], a
    ret
    ret     ; 2 ret for some reason