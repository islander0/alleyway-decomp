DEF PADDLE_SFX_ENV_5_4_DATA_START           EQU $6FAC
DEF PADDLE_SFX_ENV_3_DATA_START             EQU $6FB1
DEF PADDLE_SFX_ENV_2_DATA_START             EQU $6FB6
DEF WHITE_BRICK_SFX_ENV_5_4_DATA_START      EQU $6FBB
DEF WHITE_BRICK_SFX_ENV_3_DATA_START        EQU $6FC0
DEF WHITE_BRICK_SFX_ENV_2_DATA_START        EQU $6FC5
DEF UNBREAKABLE_BRICK_SFX_ENV_5_DATA_START  EQU $6FCA
DEF UNBREAKABLE_BRICK_SFX_ENV_4_DATA_START  EQU $6FCF
DEF UNBREAKABLE_BRICK_SFX_ENV_3_DATA_START  EQU $6FD4
DEF UNBREAKABLE_BRICK_SFX_ENV_2_DATA_START  EQU $6FD9
DEF EXTRA_LIFE_SFX_ENV_7_DATA_START         EQU $6FDE
DEF EXTRA_LIFE_SFX_ENV_6_DATA_START         EQU $6FE3
DEF EXTRA_LIFE_SFX_ENV_5_DATA_START         EQU $6FE8
DEF EXTRA_LIFE_SFX_ENV_4_DATA_START         EQU $6FED
DEF EXTRA_LIFE_SFX_ENV_3_DATA_START         EQU $6FF2
DEF EXTRA_LIFE_SFX_ENV_2_DATA_START         EQU $6FF7
DEF LIGHT_GREY_BRICK_SFX_ENV_5_4_DATA_START EQU $6FFC
DEF LIGHT_GREY_BRICK_SFX_ENV_3_DATA_START   EQU $7001
DEF LIGHT_GREY_BRICK_SFX_ENV_2_DATA_START   EQU $7006
DEF DARK_GREY_BRICK_SFX_ENV_5_4_DATA_START  EQU $700B
DEF DARK_GREY_BRICK_SFX_ENV_3_DATA_START    EQU $7010
DEF DARK_GREY_BRICK_SFX_ENV_2_DATA_START    EQU $7015
DEF BALL_LAUNCH_SFX_ENV_4_DATA_START        EQU $701A
DEF BALL_LAUNCH_SFX_ENV_3_DATA_START        EQU $701F
DEF BALL_LAUNCH_SFX_ENV_2_DATA_START        EQU $7024
DEF POINT_COUNTDOWN_SFX_ENV_5_DATA_START    EQU $7029
DEF POINT_COUNTDOWN_SFX_ENV_4_DATA_START    EQU $702E
DEF POINT_COUNTDOWN_SFX_ENV_3_DATA_START    EQU $7033
DEF POINT_COUNTDOWN_SFX_ENV_2_DATA_START    EQU $7038

DEF EXPLOSION_SFX_DATA_START    EQU $704C

DEF NOTE_FREQ_PTR_TABLE_HI_START  EQU $7531
DEF NOTE_FREQ_PTR_TABLE_LO_START  EQU $7574

DEF NOTE_LENGTH_TABLE_START EQU $75B7

DEF TRACK_01_CH2_PATTERN_DATA_START EQU $75E3
DEF TRACK_01_CH3_PATTERN_DATA_START EQU $7652
DEF TRACK_02_CH2_PATTERN_DATA_START EQU $76C3
DEF TRACK_02_CH3_PATTERN_DATA_START EQU $76D9
DEF TRACK_03_CH2_PATTERN_DATA_START EQU $76F0
DEF TRACK_03_CH3_PATTERN_DATA_START EQU $7712
DEF TRACK_04_CH2_PATTERN_DATA_START EQU $7733
DEF TRACK_04_CH3_PATTERN_DATA_START EQU $7738
DEF TRACK_05_CH2_PATTERN_DATA_START EQU $773B
DEF TRACK_05_CH3_PATTERN_DATA_START EQU $7750
DEF TRACK_06_CH2_PATTERN_DATA_START EQU $7765
DEF TRACK_06_CH3_PATTERN_DATA_START EQU $779B
DEF TRACK_07_CH2_PATTERN_DATA_START EQU $77D7
DEF TRACK_07_CH3_PATTERN_DATA_START EQU $780D
DEF TRACK_08_CH2_PATTERN_DATA_START EQU $7849
DEF TRACK_08_CH3_PATTERN_DATA_START EQU $785C
DEF TRACK_09_CH2_PATTERN_DATA_START EQU $7875
DEF TRACK_09_CH3_PATTERN_DATA_START EQU $7887
DEF TRACK_0A_CH2_PATTERN_DATA_START EQU $789C
DEF TRACK_0A_CH3_PATTERN_DATA_START EQU $78D6
DEF TRACK_0B_CH2_PATTERN_DATA_START EQU $790F
DEF TRACK_0B_CH3_PATTERN_DATA_START EQU $7919
DEF TRACK_0C_CH2_PATTERN_DATA_START EQU $791F
DEF TRACK_0C_CH3_PATTERN_DATA_START EQU $7988

DEF CH3_WAVEFORM_DATA_START EQU $7A6F

SECTION "Load Track 5", ROM0[$0823]

load_track_5_and_wait:
    call load_track_stage_complete
    ld a, $90
    jp wait_frames  ; wait 144 frames

SECTION "Audio Data", ROM0[$4BEA]

audio_data:
    db $F0,$F0,$50,$F8,$58,$F0,$30,$C0,$00,$00,$E0,$03,$06,$0B,$06,$0D,$0D,$1F,$1F,$0F,$0F,$06,$3E,$00,$06,$00,$00,$80,$70,$80,$70,$10,$F0,$F0,$F0,$F8,$F8,$38,$3C,$00,$18,$00,$30,$02,$03,$08,$0F,$03,$01,$0F,$00,$07,$07,$03,$00,$01,$01,$02,$03,$00,$F0,$00,$F8,$78,$28,$FC,$AC,$F8,$98,$E0,$00,$A0,$70,$40,$F8,$0E,$03,$0F,$03,$03,$07,$03,$03,$01,$01,$00,$03,$00,$00,$00,$00,$40,$F8,$B0,$88,$F8,$C8,$F8,$F8,$F8,$F8,$70,$F0,$30,$38,$00,$70,$00,$00,$04,$07,$10,$1F,$06,$02,$1F,$01,$0F,$0F,$07,$00,$00,$03,$00,$00,$00,$E0,$00,$F0,$F0,$50,$F8,$58,$F0,$30,$C0,$00,$80,$F0,$01,$07,$09,$07,$0E,$06,$07,$07,$07,$07,$03,$03,$01,$01,$00,$03,$60,$98,$60,$98,$C0,$F0,$F8,$FC,$F8,$FC,$F0,$F8,$C0,$C8,$00,$C0,$00,$00,$04,$07,$10,$1F,$06,$02,$1F,$01,$0F,$0F,$07,$00,$03,$02,$00,$00,$00,$E0,$00,$F0,$F0,$50,$F8,$58,$F0,$30,$C0,$00,$C0,$60,$04,$0F,$04,$1F,$3B,$0B,$3F,$0F,$0F,$0F,$1F,$1F,$1C,$1C,$00,$3C,$80,$F8,$80,$FC,$7C,$70,$FC,$F0,$F0,$F0,$F8,$F8,$38,$38,$00,$3C,$04,$07,$10,$1F,$06,$02,$1F,$01,$0F,$0F,$07,$00,$05,$07,$09,$0F,$00,$E0,$00,$F0,$F0,$50,$F8,$58,$F0,$30,$80,$FC,$10,$FE,$0C,$F2,$0E,$4E,$3F,$7F,$3F,$7F,$07,$27,$01,$01,$00,$00,$00,$00,$00,$00,$FC,$F0,$F0,$F0,$F0,$F0,$E0,$E0,$F0,$F8,$F0,$F8,$00,$10,$00,$10,$04,$07,$10,$1C,$06,$02,$1C,$00,$0F,$0F,$07,$00,$05,$07,$09,$0F,$00,$00,$00,$00,$00,$00,$06,$01,$18,$00,$16,$20,$28,$34,$17,$1E,$00,$00,$06,$09,$10,$24,$00,$40,$00,$80,$48,$80,$A4,$C8,$5D,$66,$3F,$3B,$05,$04,$02,$02,$02,$02,$00,$02,$02,$00,$06,$07,$0A,$51,$01,$02,$00,$08,$00,$00,$04,$08,$01,$06,$00,$01,$00,$00,$00,$00,$00,$01,$00,$00,$00,$00,$00,$01,$00,$00,$00,$01,$00,$02,$08,$B0,$06,$07,$0A,$0A,$0F,$0E,$0E,$0F,$07,$07,$00,$00,$00,$00,$00,$00,$F9,$FF,$FF,$FF,$3F,$3E,$7F,$78,$FF,$F8,$7F,$70,$DF,$D0,$DF,$D0,$FF,$FF,$FF,$FF,$FF,$3F,$FF,$0F,$FF,$07,$FF,$03,$FF,$03,$FF,$02,$FF,$FF,$F0,$30,$F8,$18,$FC,$0C,$FE,$06,$FF,$01,$FF,$00,$FF,$00,$FF,$FE,$F7,$F6,$FF,$FE,$FF,$FC,$3F,$3C,$FF,$F0,$FF,$00,$FF,$00,$FF,$F0,$FF,$30,$FF,$18,$FF,$0C,$FF,$06,$FF,$01,$FF,$00,$FF,$00,$FF,$02,$FF,$02,$FF,$02,$FF,$02,$FF,$06,$FF,$FC,$FF,$00,$FF,$00,$00

SECTION "Set Event", ROM0[$63AE]

set_event_extra_life:
    ld a, $1
    jr set_event

set_event_white_brick:
    ld a, $2
    jr set_event

set_event_unbreakable_brick:
    ld a, $3
    jr set_event

set_event_paddle_collision:
    ld a, $4
    jr set_event

set_event_light_grey_brick:
    ld a, $5
    jr set_event

set_event_dark_grey_brick:
    ld a, $6
    jr set_event

set_event_ball_launched:
    ld a, $7
    jr set_event

set_event_bonus_countdown:
    ld a, $8
    jr set_event

set_event_mario_jump:
    ld a, $9
    jr set_event

set_event_death_no_lives:
    ld a, $A
    jr set_event

set_event_ceiling:
    ld a, $B
    jr set_event

; game_event = 0C: ball collides with wall         
set_event_wall:
    ld a, $C

set_event:
    ld [w_game_event], a
    ret

SECTION "Load Track", ROM0[$63E8]

load_track_title:
    ld a, $1
    jr load_track_index

load_track_start:
    ld a, $2
    jr load_track_index

load_track_game_over:
    ld a, $3
    jr load_track_index

load_track_pause:
    ld a, $4
    jr load_track_index

load_track_stage_complete:
    ld a, $5
    jr load_track_index

load_track_bonus_stage:
    ld a, $6
    jr load_track_index

load_track_bonus_stage_fast:
    ld a, $7
    jr load_track_index

load_track_bonus_stage_start:
    ld a, $8
    jr load_track_index

load_track_bonus_stage_lose:
    ld a, $9
    jr load_track_index

load_track_bonus_stage_win:
    ld a, $A
    jr load_track_index

load_track_brick_scrolldown:
    ld a, $B
    jr load_track_index

load_track_nice_play:
    ld a, $C

load_track_index:
    ld [w_track_index], a
    ret

SECTION "Audio Update", ROM0 [$6800]

audio_update:
    call demo_flag_handler
    call sfx_handler
    call ch4_explosion_handler
    call music_track_handler                    
    call ch2_pan_handler

    xor a
    ld [w_game_event], a
    ld [w_ball_oob], a
    ld [w_track_index], a

    ret

SECTION "Unused Track Handler", ROM0[$694C]

unused_track_handler:
    ldh a, [$FF81]  ; [h_unused_joypad_press_latch]
    bit $0, a
    jp nz, .LAB_6979

    bit $1, a
    jp nz, .LAB_697f

    bit $3, a
    jp nz, .LAB_6985

    bit $2, a
    jp nz, .LAB_698b

    bit $4, a
    jp nz, .LAB_6991

    bit $5, a
    jp nz, .LAB_6997

    bit $6, a
    jp nz, .LAB_699d

    bit $7, a
    jp nz, .LAB_69a3

    jp .LAB_69a9

.LAB_6979
    ld a, $1
    ld [w_track_index], a
    ret

.LAB_697f
    ld a, $2
    ld [w_track_index], a
    ret

.LAB_6985
    ld a, $3
    ld [w_track_index], a
    ret

.LAB_698b
    ld a, $4
    ld [w_track_index], a
    ret

.LAB_6991
    ld a, $5
    ld [w_track_index], a
    ret

.LAB_6997
    ld a, $6
    ld [w_track_index], a
    ret

.LAB_699d
    ld a, $7
    ld [w_track_index], a
    ret

.LAB_69a3
    ld a, $8
    ld [w_track_index], a
    ret

.LAB_69a9
    ret

SECTION "Music and SFX", ROM0[$69FB]

sfx_handler:
    ld a, [w_current_sfx_active]  

    cp $1
    jp z, .extra_life_sfx_env_decrementor

    ld a, [w_game_event]      
    
    ; if no sfx active

    cp $4
    jp z, .paddle_collision_env_4_sfx_handler

    cp $2
    jp z, .init_white_brick_env_5_sfx

    cp $3
    jp z, .init_unbreakable_brick_env_5_sfx

    cp $1
    jp z, .init_extra_life_env_7_sfx

    cp $5
    jp z, .init_light_grey_brick_env_5_sfx

    cp $6
    jp z, .init_dark_grey_brick_env_5_sfx

    cp $7
    jp z, .init_ball_launch_env_4_sfx

    cp $8
    jp z, .init_point_countdown_env_5_sfx

    cp $9
    jp z, .init_mario_jump_in_sfx

    cp $A
    jp z, .init_mario_jump_out_sfx

    cp $B
    jp z, .init_ceiling_collision_sfx

    cp $C
    jp z, .init_wall_collision_sfx

    ; if any other sfx active

    ld a, [w_current_sfx_active]  

    cp $2
    jp z, .white_brick_sfx_env_decrementor

    cp $3
    jp z, .unbreakable_brick_sfx_env_decrementor

    cp $4
    jp z, .paddle_collision_sfx_env_decrementor

    cp $5
    jp z, .light_grey_brick_sfx_env_decrementor

    cp $6
    jp z, .dark_grey_brick_sfx_env_decrementor

    cp $7
    jp z, .ball_launch_sfx_env_decrementor

    cp $8
    jp z, .point_cooldown_sfx_env_decrementor

    cp $9
    jp z, .LAB_6df3

    cp $A
    jp z, .LAB_6e66

    cp $B
    jp z, .LAB_6ed7

    cp $C
    jp z, .LAB_6f18

    ret

.init_extra_life_env_7_sfx:
    ld a, $1
    ld [w_current_sfx_active], a

    ld a, $7
    ld [w_sfx_envelope], a

    ld hl, EXTRA_LIFE_SFX_ENV_7_DATA_START
    ld c, $10

    call ch1_initializer

    ret

.init_white_brick_env_5_sfx: 
    ld a, [w_ceiling_collision_sfx_active_flag]
    cp $1
    jp z, .cancel_white_brick_sfx

    ld a, $2
    ld [w_current_sfx_active], a

    ld a, $5
    ld [w_sfx_envelope], a

    ld hl, WHITE_BRICK_SFX_ENV_5_4_DATA_START
    ld c, $10

    call ch1_initializer

.cancel_white_brick_sfx
    ret

.init_unbreakable_brick_env_5_sfx:
    ld a, [w_ceiling_collision_sfx_active_flag]
    cp $1
    jp z, .cancel_unbreakable_brick_sfx

    ld a, $3
    ld [w_current_sfx_active], a

    ld a, $5
    ld [w_sfx_envelope], a

    ld hl, UNBREAKABLE_BRICK_SFX_ENV_5_DATA_START
    ld c, $10

    call ch1_initializer

.cancel_unbreakable_brick_sfx
    ret

.paddle_collision_env_4_sfx_handler
    ld a, [w_ceiling_collision_sfx_active_flag]
    cp $1
    jp z, .cancel_paddle_collision_sfx

    ld a, $4
    ld [w_current_sfx_active], a

    ld a, $4
    ld [w_sfx_envelope], a

    ld hl, PADDLE_SFX_ENV_5_4_DATA_START
    ld c, $10   ; copy the data from $FF10 to $FF14
    
    call ch1_initializer

.cancel_paddle_collision_sfx
    ret

.init_light_grey_brick_env_5_sfx:
    ld a, [w_ceiling_collision_sfx_active_flag]
    cp $1
    jp z, .cancel_light_grey_brick_sfx

    ld a, $5
    ld [w_current_sfx_active], a

    ld a, $5
    ld [w_sfx_envelope], a

    ld hl, LIGHT_GREY_BRICK_SFX_ENV_5_4_DATA_START
    ld c, $10

    call ch1_initializer

.cancel_light_grey_brick_sfx
    ret

.init_dark_grey_brick_env_5_sfx:
    ld a, [w_ceiling_collision_sfx_active_flag]
    cp $1
    jp z, .cancel_dark_grey_brick_sfx

    ld a, $6
    ld [w_current_sfx_active], a

    ld a, $5
    ld [w_sfx_envelope], a

    ld hl, DARK_GREY_BRICK_SFX_ENV_5_4_DATA_START
    ld c, $10

    call ch1_initializer

.cancel_dark_grey_brick_sfx
    ret

.init_ball_launch_env_4_sfx:
    ld a, $7
    ld [w_current_sfx_active], a

    ld a, $4
    ld [w_sfx_envelope], a

    ld hl, BALL_LAUNCH_SFX_ENV_4_DATA_START
    ld c, $10
    
    call ch1_initializer

    ret

.init_point_countdown_env_5_sfx:
    ld a, $8
    ld [w_current_sfx_active], a

    ld a, $5
    ld [w_sfx_envelope], a

    ld hl, POINT_COUNTDOWN_SFX_ENV_5_DATA_START
    ld c, $10

    call ch1_initializer

    ret

.init_mario_jump_in_sfx:
    ld a, $9
    ld [w_current_sfx_active], a

    ld a, $63
    ld [w_ch1_pitch], a

    ld a, $A
    ld [w_ch1_freq_lo], a

    ld a, $87
    ld [w_ch1_freq_hi], a

    ld a, $FF
    ld [w_sfx_envelope_counter], a

    ret

.init_mario_jump_out_sfx:
    ld a, $A
    ld [w_current_sfx_active], a

    ld a, $B
    ld [w_ch1_pitch], a

    ld a, $AC
    ld [w_ch1_freq_lo], a

    ld a, $86
    ld [w_ch1_freq_hi], a

    ld a, $87
    ld [w_unknown_dffe], a

    ld a, $FF
    ld [w_sfx_envelope_counter], a

    ret

.init_ceiling_collision_sfx:
    ld a, $B
    ld [w_current_sfx_active], a

    ld a, $A5
    ld [w_ch1_freq_lo], a

    ld a, $87
    ld [w_unknown_dffe], a

    ld a, $1
    ld [w_ceiling_collision_sfx_active_flag], a 

    ret

.init_wall_collision_sfx:
    ld a, [w_ceiling_collision_sfx_active_flag]
    cp $1
    jp z, .cancel_wall_collision_sfx

    ld a, $C
    ld [w_current_sfx_active], a

    ld a, $FF
    ld [w_ch1_pitch], a

    ld a, $A
    ld [w_ch1_freq_lo], a

    ld a, $85
    ld [w_ch1_freq_hi], a

    ld a, $FF
    ld [w_sfx_envelope_counter], a

.cancel_wall_collision_sfx
    ret

; IF EXTRA LIFE SFX PLAYING:
.extra_life_sfx_env_decrementor
    ld a, [w_sfx_envelope_counter]
    inc a
    ld [w_sfx_envelope_counter], a

    cp $7
    jp nz, .return

    xor a
    ld [w_sfx_envelope_counter], a

    ld a, [w_sfx_envelope]    
    dec a
    ld [w_sfx_envelope], a

    cp $6
    jp z, .init_extra_life_env_6_sfx

    cp $5
    jp z, .init_extra_life_env_5_sfx

    cp $4
    jp z, .init_extra_life_env_4_sfx

    cp $3
    jp z, .init_extra_life_env_3_sfx

    cp $2
    jp z, .init_extra_life_env_2_sfx

    cp $1   ; useless
    xor a
    ld [w_current_sfx_active], a

    jp .clear_sfx

.init_extra_life_env_6_sfx
    ld hl, EXTRA_LIFE_SFX_ENV_6_DATA_START
    ld c, $10

    call ch1_initializer

    ret

.init_extra_life_env_5_sfx
    ld hl, EXTRA_LIFE_SFX_ENV_5_DATA_START
    ld c, $10

    call ch1_initializer

    ret

.init_extra_life_env_4_sfx
    ld hl, EXTRA_LIFE_SFX_ENV_4_DATA_START
    ld c, $10

    call ch1_initializer

    ret

.init_extra_life_env_3_sfx
    ld hl, EXTRA_LIFE_SFX_ENV_3_DATA_START
    ld c, $10

    call ch1_initializer

    ret

.init_extra_life_env_2_sfx
    ld hl, EXTRA_LIFE_SFX_ENV_2_DATA_START
    ld c, $10

    call ch1_initializer

    xor a
    ld [w_ceiling_collision_sfx_active_flag], a       
              
    ret

.white_brick_sfx_env_decrementor
    ld a, [w_sfx_envelope_counter]
    inc a
    ld [w_sfx_envelope_counter], a

    cp $5
    jp nz, .return

    xor a
    ld [w_sfx_envelope_counter], a
    
    ld a, [w_sfx_envelope]    
    dec a
    ld [w_sfx_envelope], a

    cp $4
    jp z, .init_white_brick_env_4_sfx

    cp $3
    jp z, .init_white_brick_env_3_sfx

    cp $2
    jp z, .init_white_brick_env_2_sfx
    
    cp $1
    jp .clear_sfx

.init_white_brick_env_4_sfx
    ld hl, WHITE_BRICK_SFX_ENV_5_4_DATA_START
    ld c, $10

    call ch1_initializer

    ret

.init_white_brick_env_3_sfx
    ld hl, WHITE_BRICK_SFX_ENV_3_DATA_START
    ld c, $10

    call ch1_initializer

    ret

.init_white_brick_env_2_sfx
    ld hl, WHITE_BRICK_SFX_ENV_2_DATA_START
    ld c, $10

    call ch1_initializer

    ret

.unbreakable_brick_sfx_env_decrementor
    ld a, [w_sfx_envelope_counter]
    inc a
    ld [w_sfx_envelope_counter], a

    cp $3
    jp nz, .return

    xor a
    ld [w_sfx_envelope_counter], a

    ld a, [w_sfx_envelope]    
    dec a
    ld [w_sfx_envelope], a

    cp $4
    jp z, .init_unbreakable_brick_env_4_sfx

    cp $3
    jp z, .init_unbreakable_brick_env_3_sfx

    cp $2
    jp z, .init_unbreakable_brick_env_2_sfx

    cp $1
    jp .clear_sfx

.init_unbreakable_brick_env_4_sfx
    ld hl, UNBREAKABLE_BRICK_SFX_ENV_4_DATA_START
    ld c, $10

    call ch1_initializer

    ret

.init_unbreakable_brick_env_3_sfx
    ld hl, UNBREAKABLE_BRICK_SFX_ENV_3_DATA_START
    ld c, $10

    call ch1_initializer

    ret

.init_unbreakable_brick_env_2_sfx
    ld hl, UNBREAKABLE_BRICK_SFX_ENV_2_DATA_START
    ld c, $10

    call ch1_initializer

    ret

.paddle_collision_sfx_env_decrementor
    ld a, [w_sfx_envelope_counter]
    inc a
    ld [w_sfx_envelope_counter], a

    cp $5
    jp nz, .return
    
    xor a
    ld [w_sfx_envelope_counter], a

    ld a, [w_sfx_envelope]    
    dec a
    ld [w_sfx_envelope], a

    cp $4
    jp z, .init_paddle_collision_env_4_sfx

    cp $3
    jp z, .init_paddle_collision_env_3_sfx

    cp $2
    jp z, .init_paddle_collision_env_2_sfx

    cp $1
    jp .clear_sfx

.init_paddle_collision_env_4_sfx
    ld hl, PADDLE_SFX_ENV_5_4_DATA_START
    ld c, $10

    call ch1_initializer

    ret

.init_paddle_collision_env_3_sfx
    ld hl, PADDLE_SFX_ENV_3_DATA_START
    ld c, $10

    call ch1_initializer

    ret

.init_paddle_collision_env_2_sfx
    ld hl, PADDLE_SFX_ENV_2_DATA_START
    ld c, $10

    call ch1_initializer

    ret

.light_grey_brick_sfx_env_decrementor
    ld a, [w_sfx_envelope_counter]
    inc a
    ld [w_sfx_envelope_counter], a

    cp $5
    jp nz, .return

    xor a
    ld [w_sfx_envelope_counter], a

    ld a, [w_sfx_envelope]    
    dec a
    ld [w_sfx_envelope], a

    cp $4
    jp z, .init_light_grey_brick_env_4_sfx

    cp $3
    jp z, .init_light_grey_brick_env_3_sfx

    cp $2
    jp z, .init_light_grey_brick_env_2_sfx

    cp $1
    jp .clear_sfx

.init_light_grey_brick_env_4_sfx
    ld hl, LIGHT_GREY_BRICK_SFX_ENV_5_4_DATA_START
    ld c, $10

    call ch1_initializer

    ret

.init_light_grey_brick_env_3_sfx
    ld hl, LIGHT_GREY_BRICK_SFX_ENV_3_DATA_START
    ld c, $10

    call ch1_initializer

    ret

.init_light_grey_brick_env_2_sfx
    ld hl, LIGHT_GREY_BRICK_SFX_ENV_2_DATA_START
    ld c, $10

    call ch1_initializer

    ret

.dark_grey_brick_sfx_env_decrementor
    ld a, [w_sfx_envelope_counter]
    inc a
    ld [w_sfx_envelope_counter], a

    cp $5
    jp nz, .return

    xor a
    ld [w_sfx_envelope_counter], a

    ld a, [w_sfx_envelope]    
    dec a
    ld [w_sfx_envelope], a

    cp $4
    jp z, .init_dark_grey_brick_env_4_sfx

    cp $3
    jp z, .init_dark_grey_brick_env_3_sfx

    cp $2
    jp z, .init_dark_grey_brick_env_2_sfx

    cp $1
    jp .clear_sfx

.init_dark_grey_brick_env_4_sfx
    ld hl, DARK_GREY_BRICK_SFX_ENV_5_4_DATA_START
    ld c, $10

    call ch1_initializer

    ret

.init_dark_grey_brick_env_3_sfx
    ld hl, DARK_GREY_BRICK_SFX_ENV_3_DATA_START
    ld c, $10

    call ch1_initializer

    ret

.init_dark_grey_brick_env_2_sfx
    ld hl, DARK_GREY_BRICK_SFX_ENV_2_DATA_START
    ld c, $10

    call ch1_initializer

    ret

.ball_launch_sfx_env_decrementor
    ld a, [w_sfx_envelope_counter]
    inc a
    ld [w_sfx_envelope_counter], a

    cp $5
    jp nz, .return

    xor a
    ld [w_sfx_envelope_counter], a

    ld a, [w_sfx_envelope]    
    dec a
    ld [w_sfx_envelope], a

    cp $3
    jp z, .init_ball_launch_env_3_sfx

    cp $2
    jp z, .init_ball_launch_env_2_sfx

    cp $1
    jp .clear_sfx

.init_ball_launch_env_3_sfx
    ld hl, BALL_LAUNCH_SFX_ENV_3_DATA_START
    ld c, $10

    call ch1_initializer

    ret

.init_ball_launch_env_2_sfx
    ld hl, BALL_LAUNCH_SFX_ENV_2_DATA_START
    ld c, $10

    call ch1_initializer

    ret

.point_cooldown_sfx_env_decrementor
    ld a, [w_sfx_envelope_counter]
    inc a
    ld [w_sfx_envelope_counter], a

    cp $2
    jp nz, .return

    xor a
    ld [w_sfx_envelope_counter], a

    ld a, [w_sfx_envelope]    
    dec a
    ld [w_sfx_envelope], a

    cp $4
    jp z, .init_point_cooldown_env_4_sfx

    cp $3
    jp z, .init_point_cooldown_env_3_sfx

    cp $2
    jp z, .init_point_cooldown_env_2_sfx

    cp $1
    jp .clear_sfx

.init_point_cooldown_env_4_sfx
    ld hl, POINT_COUNTDOWN_SFX_ENV_4_DATA_START
    ld c, $10

    call ch1_initializer

    ret

.init_point_cooldown_env_3_sfx
    ld hl, POINT_COUNTDOWN_SFX_ENV_3_DATA_START
    ld c, $10

    call ch1_initializer

    ret

.init_point_cooldown_env_2_sfx
    ld hl, POINT_COUNTDOWN_SFX_ENV_2_DATA_START
    ld c, $10

    call ch1_initializer

    ret

.LAB_6df3
    ld a, $5
    ld [w_unknown_dfd0], a
    ld a, $4
    ld [w_unknown_dfd1], a

    ld a, $0
    ldh [rNR10], a
    ld a, $BF
    ldh [rNR11], a
    ld a, $40
    ldh [rNR12], a

    ld a, [w_sfx_envelope_counter]
    cp $0
    jp z, .LAB_6e3a

.LAB_6e11
    ld a, [w_ch1_pitch]       
    inc a
    cp $63
    jp z, .LAB_6e34

    ld [w_ch1_pitch], a

    ld a, [w_unknown_dfd0]       
    dec a
    ld [w_unknown_dfd0], a

    cp $0
    jp nz, .LAB_6e11

    ld a, [w_ch1_pitch]       
    ldh [rNR13], a
    ld a, [w_ch1_freq_hi]     
    ldh [rNR14], a

    ret

.LAB_6e34
    ld a, $0
    ld [w_sfx_envelope_counter], a
    ret

.LAB_6e3a
    ld a, [w_ch1_freq_lo]     
    dec a
    cp $10
    jp z, .LAB_6e5d

    ld [w_ch1_freq_lo], a

    ld a, [w_unknown_dfd1]       
    dec a
    ld [w_unknown_dfd1], a
    cp $0
    jp nz, .LAB_6e3a

    ld a, [w_ch1_freq_lo]     
    ldh [rNR13], a
    ld a, [w_ch1_freq_hi]     
    ldh [rNR14], a
    ret

.LAB_6e5d
    xor a
    ld [w_current_sfx_active], a
    ldh [rNR12], a

    jp .clear_sfx

.LAB_6e66
    ld a, $9
    ld [w_unknown_dfd0], a
    ld a, $4
    ld [w_unknown_dfd1], a

    ld a, $0
    ldh [rNR10], a
    ld a, $BF
    ldh [rNR11], a
    ld a, $90
    ldh [rNR12], a

    ld a, [w_sfx_envelope_counter]
    cp $0
    jp z, .LAB_6ead

.LAB_6e84
    ld a, [w_ch1_pitch]       
    inc a
    cp $89
    jp z, .LAB_6ea7

    ld [w_ch1_pitch], a

    ld a, [w_unknown_dfd0]       
    dec a
    ld [w_unknown_dfd0], a
    cp $0
    jp nz, .LAB_6e84

    ld a, [w_ch1_pitch]       
    ldh [rNR13], a
    ld a, [w_ch1_freq_hi]     
    ldh [rNR14], a

    ret

.LAB_6ea7 
    ld a, $0
    ld [w_sfx_envelope_counter], a
    ret

.LAB_6ead
    ld a, [w_ch1_freq_lo]     
    dec a
    cp $1E
    jp z, .LAB_6ed0

    ld [w_ch1_freq_lo], a

    ld a, [w_unknown_dfd1]       
    dec a
    ld [w_unknown_dfd1], a
    cp $0
    jp nz, .LAB_6ead

    ld a, [w_ch1_freq_lo]     
    ldh [rNR13], a
    ld a, [w_unknown_dffe]       
    ldh [rNR14], a

    ret

.LAB_6ed0
    xor a
    ld [w_current_sfx_active], a
    ldh [rNR12], a
    ret

.LAB_6ed7
    ld a, $8
    ld [w_unknown_dfd1], a
    
    ld a, $0
    ldh [rNR10], a
    ld a, $BF
    ldh [rNR11], a
    ld a, $90
    ldh [rNR12], a

.LAB_6ee8
    ld a, [w_ch1_freq_lo]     
    dec a
    cp $6
    jp z, .LAB_6f0b

    ld [w_ch1_freq_lo], a
    
    ld a, [w_unknown_dfd1]       
    dec a
    ld [w_unknown_dfd1], a
    cp $0
    jp nz, .LAB_6ee8

    ld a, [w_ch1_freq_lo]     
    ldh [rNR13], a
    ld a, [w_unknown_dffe]       
    ldh [rNR14], a

    ret

.LAB_6f0b
    xor a
    ld [w_current_sfx_active], a
    ldh [rNR12], a
    ld [w_ceiling_collision_sfx_active_flag], a     

    jp .clear_sfx

    ret ; safeguard

.LAB_6f18
    ld a, $28
    ld [w_unknown_dfd0], a
    ld a, $28
    ld [w_unknown_dfd1], a

    ld a, $0
    ldh [rNR10], a
    ld a, $BF
    ldh [rNR11], a
    ld a, $40
    ldh [rNR12], a

    ld a, [w_sfx_envelope_counter]
    cp $0

    jp z, .LAB_6f5f

.LAB_6f36
    ld a, [w_ch1_pitch]       
    dec a
    cp $10
    jp z, .LAB_6f59

    ld [w_ch1_pitch], a

    ld a, [w_unknown_dfd0]       
    dec a
    ld [w_unknown_dfd0], a

    cp $0
    jp nz, .LAB_6f36

    ld a, [w_ch1_pitch]       
    ldh [rNR13], a
    ld a, [w_ch1_freq_hi]     
    ldh [rNR14], a

    ret

.LAB_6f59
    ld a, $0
    ld [w_sfx_envelope_counter], a
    ret

.LAB_6f5f
    ld a, [w_ch1_freq_lo]     
    inc a
    cp $63
    jp z, .clear_sfx_redundant

    ld [w_ch1_freq_lo], a

    ld a, [w_unknown_dfd1]       
    dec a
    ld [w_unknown_dfd1], a
    cp $0
    jp nz, .LAB_6f5f

    ld a, [w_ch1_freq_lo]     
    ldh [rNR13], a
    ld a, [w_ch1_freq_hi]     
    ldh [rNR14], a

    ret

; probably a leftover conditional that got axed during de... *

.clear_sfx_redundant:
    xor a
    ld [w_current_sfx_active], a
    ldh [rNR12], a

    jp .clear_sfx

    ; unused code

    call debug_set_sfx_clear_flag

    ret

.clear_sfx:
    xor a
    ld [w_current_sfx_active], a
    ldh [rNR12], a; Mute CH1
    ld [w_sfx_envelope_counter], a
    ld [w_sfx_envelope], a

    ret

.return
    ret

; Copies 5 bytes of data from [hl] to [c] incrementally

ch1_initializer:
    ld a, [hl+]
    ldh [c], a

    inc c
    ld a, [hl+]
    ldh [c], a

    inc c
    ld a, [hl+]
    ldh [c], a

    inc c
    ld a, [hl+]
    ldh [c], a

    inc c
    ld a, [hl]
    ldh [c], a
    ret

; Arrays containing CH1 initial properties for all SFX       *
; 32 entries × 5 bytes (NR10-NR14), +1 CH4 entry at $704C    *
; Indexed by current_sfx_active value:             
;    
; [1] paddle_sfx_env_5|4_data
; [2] paddle_sfx_env_3_data_START
; [3] paddle_sfx_env_2_data_START
; [4] white_brick_sfx_env_5_4_data_START
; [5] white_brick_sfx_env_3_data_START
; [6] white_brick_sfx_env_2_data_START
; [7] unbreakable_brick_sfx_env_5_data_START
; [8] unbreakable_brick_sfx_env_4_data_START
; [9] unbreakable_brick_sfx_env_3_data_START
; [10] unbreakable_brick_sfx_env_2_data_START 
; [11] extra_life_sfx_env_7_data
; [12] extra_life_sfx_env_6_data
; [13] extra_life_sfx_env_5_data
; [14] extra_life_sfx_env_4_data
; [15] extra_life_sfx_env_3_data
; [16] extra_life_sfx_env_2_data
; [17] light_grey_brick_sfx_env_5|4_data
; [18] light_grey_brick_sfx_env_3_data
; [19] light_grey_brick_sfx_env_2_data
; [20] dark_grey_brick_sfx_env_5|4_data 
; [21] dark_grey_brick_sfx_env_3_data
; [22] dark_grey_brick_sfx_env_2_data
; [23] ball_launch_sfx_env_4_data
; [24] ball_launch_sfx_env_3_data
; [25] ball_launch_sfx_env_2_data
; [26] point_countdown_sfx_env_5_data
; [27] point_countdown_sfx_env_4_data
; [28] point_countdown_sfx_env_3_data
; [29] point_countdown_sfx_env_2_data
; [30-32] unused_sfx_data

; possible mistake on the devs' part: envelope level 5 and 4 point to the same ad

ch1_env_data_index:

    ; NR10: 0000 0000     

    db $00,$81,$72,$4B,$C7
    db $00,$81,$15,$4B,$C7
    db $00,$81,$17,$4B,$C7
    db $00,$81,$72,$7B,$C7
    db $00,$81,$15,$7B,$C7
    db $00,$81,$17,$7B,$C7
    db $00,$81,$C2,$AC,$C7
    db $00,$81,$C2,$BE,$C7
    db $00,$81,$95,$BE,$C7
    db $00,$81,$48,$BE,$C7
    db $00,$71,$F2,$59,$87
    db $00,$7F,$F2,$83,$87
    db $00,$BF,$F2,$9D,$87
    db $00,$BF,$F2,$83,$87
    db $00,$BF,$F2,$90,$87
    db $00,$BF,$F2,$AC,$87
    db $00,$81,$72,$97,$C7
    db $00,$81,$15,$97,$C7
    db $00,$81,$17,$97,$C7
    db $00,$81,$72,$A7,$C7
    db $00,$81,$15,$A7,$C7
    db $00,$81,$17,$A7,$C7
    db $1A,$81,$F0,$9D,$C7
    db $19,$83,$72,$9E,$C7
    db $12,$43,$3A,$9F,$C7
    db $00,$81,$72,$7F,$C7
    db $00,$81,$15,$7F,$C7
    db $00,$81,$72,$7F,$C7
    db $00,$81,$17,$7F,$C7
    db $1A,$81,$F0,$E9,$C7
    db $19,$83,$72,$E9,$C7
    db $12,$43,$3A,$E9,$C7

explosion_ch4_sfx_data:  ; only SFX using CH4
    db $00,$F7,$57,$80

; Handles whether to trigger the explosion SFX or not and loads the CH4 data for it

ch4_explosion_handler:
    ld a, [w_ball_oob]        
    cp $1
    jp z, load_ch4_data

    call init_ch4_explosion_sfx_pan

    ret

load_ch4_data:
    ld hl, EXPLOSION_SFX_DATA_START    ; executes when the player loses
    ld c, $20

    ld a, $49
    ld [w_ch4_pan_timer], a

    ld a, $F
    ld [w_ch4_pan], a

    xor a
    ld [w_ch2_pan_active], a   ; disable CH2 panning during explosion SFX

    call ch4_initializer        ; enable CH4

    ret

; Triggers the explosion soundWrites 4 bytes that inits CH4

ch4_initializer:
    ld a, [hl+] ; $704C = 00
    ldh [c], a     ; NR41: 0000 0000
    inc c

    ld a, [hl+] ; $704D = F7
    ldh [c], a     ; NR42: 1111 0111
    inc c

    ld a, [hl+] ; $704E = 57
    ldh [c], a     ; NR43: 0101 0111
    inc c

    ld a, [hl+] ; $704F = 80
    ldh [c], a     ; NR44: 1000 000
    ret

; Inits the auto-pan for the explosion sfx         
init_ch4_explosion_sfx_pan:
    ld a, [w_ch4_pan_timer]   
    cp $0
    jp z, .clear_panning_timer

    dec a
    ld [w_ch4_pan_timer], a
    cp $0
    jp z, .sound_pan_center

    ld a, [w_ch4_pan]     
    rlc a
    ld [w_ch4_pan], a
    jp nc, .sound_pan_left

.sound_pan_right
    ld a, $F
    ldh [rNR51], a
    ret

.sound_pan_left
    ld a, $F0
    ldh [rNR51], a
    ret

.sound_pan_center
    ld a, $FF
    ldh [rNR51], a

.clear_panning_timer
    xor a
    ld [w_ch4_pan_timer], a
    ret

music_track_handler:
    ld a, [w_track_index]     
    cp $1
    jp z, .track_01_title

    cp $2
    jp z, .track_02_game_start

    cp $3
    jp z, .track_03_game_over

    cp $4
    jp z, .track_04_pause

    cp $5
    jp z, .track_05_level_completed

    cp $6
    jp z, .track_06_bonus

    cp $7
    jp z, .track_07_bonus_fast

    cp $8
    jp z, .track_08_bonus_start

    cp $9
    jp z, .track_09_bonus_fail

    cp $A
    jp z, .track_0a_bonus_win

    cp $B
    jp z, .track_0b_brick_scrolldown

    cp $C
    jp z, .track_0c_nice_play

    ld a, [w_ch1_current_track]   
    cp $0
    jp nz, music_playback_handler

    ld a, [w_ch3_current_track]   
    cp $0
    jp nz, ch3_note_length_decrement

    ret

.track_01_title
    ld a, $1
    ld [w_ch1_current_track], a
    ld [w_ch3_current_track], a
    ld [w_ch2_note_length], a 
    ld [w_ch3_note_length], a 
    ld [w_music_triggered_flag], a
    ld [w_ch2_pan_active], a  
    ld [w_ch2_pan_triggered_flag], a
    ld [w_ch2_pan_direction], a

    ld a, $60
    ld [w_ch2_pan_timer], a   
    ld [w_ch2_pan_timer_max], a

    ld hl, TRACK_01_CH2_PATTERN_DATA_START
    ld a, h
    ld [w_ch2_pattern_ptr_hi], a
    ld a, l
    ld [w_ch2_pattern_ptr_lo], a

    ld hl, TRACK_01_CH3_PATTERN_DATA_START
    ld a, h
    ld [w_ch3_pattern_ptr_hi], a
    ld a, l
    ld [w_ch3_pattern_ptr_lo], a

    call music_playback_handler
    ret

.track_02_game_start
    ld a, $FF
    ldh [rNR51], a

    xor a
    ld [w_ch2_pan_active], a  

    ld a, $2
    ld [w_ch1_current_track], a
    ld [w_ch3_current_track], a

    ld a, $1
    ld [w_ch2_note_length], a 
    ld [w_ch3_note_length], a 
    ld [w_music_triggered_flag], a

    ld hl, TRACK_02_CH2_PATTERN_DATA_START
    ld a, h
    ld [w_ch2_pattern_ptr_hi], a
    ld a, l
    ld [w_ch2_pattern_ptr_lo], a

    ld hl, TRACK_02_CH3_PATTERN_DATA_START
    ld a, h
    ld [w_ch3_pattern_ptr_hi], a
    ld a, l
    ld [w_ch3_pattern_ptr_lo], a

    call music_playback_handler

    ret

.track_03_game_over
    ld a, $3
    ld [w_ch1_current_track], a
    ld [w_ch3_current_track], a

    ld a, $1
    ld [w_ch2_note_length], a 
    ld [w_ch3_note_length], a 
    ld [w_music_triggered_flag], a
    ld [w_ch2_pan_active], a  
    ld [w_ch2_pan_triggered_flag], a
    ld [w_ch2_pan_direction], a

    ld a, $60
    ld [w_ch2_pan_timer], a   
    ld [w_ch2_pan_timer_max], a

    ld hl, TRACK_03_CH2_PATTERN_DATA_START
    ld a, h
    ld [w_ch2_pattern_ptr_hi], a
    ld a, l
    ld [w_ch2_pattern_ptr_lo], a

    ld hl, TRACK_03_CH3_PATTERN_DATA_START
    ld a, h
    ld [w_ch3_pattern_ptr_hi], a
    ld a, l
    ld [w_ch3_pattern_ptr_lo], a

    call music_playback_handler

    ret

.track_04_pause
    xor a
    ld [w_ch2_pan_active], a  

    ld a, $4
    ld [w_ch1_current_track], a
    ld [w_ch3_current_track], a

    ld a, $1
    ld [w_ch2_note_length], a 
    ld [w_ch3_note_length], a 
    ld [w_music_triggered_flag], a

    ld hl, TRACK_04_CH2_PATTERN_DATA_START
    ld a, h
    ld [w_ch2_pattern_ptr_hi], a
    ld a, l
    ld [w_ch2_pattern_ptr_lo], a

    ld hl, TRACK_04_CH3_PATTERN_DATA_START
    ld a, h
    ld [w_ch3_pattern_ptr_hi], a
    ld a, l
    ld [w_ch3_pattern_ptr_lo], a

    call music_playback_handler

    ret

.track_05_level_completed
    ld a, $FF
    ldh [rNR51], a

    xor a
    ld [w_ch2_pan_active], a  

    ld a, $5
    ld [w_ch1_current_track], a
    ld [w_ch3_current_track], a

    ld a, $1
    ld [w_ch2_note_length], a 
    ld [w_ch3_note_length], a 
    ld [w_music_triggered_flag], a

    ld hl, TRACK_05_CH2_PATTERN_DATA_START
    ld a, h
    ld [w_ch2_pattern_ptr_hi], a
    ld a, l
    ld [w_ch2_pattern_ptr_lo], a

    ld hl, TRACK_05_CH3_PATTERN_DATA_START
    ld a, h
    ld [w_ch3_pattern_ptr_hi], a
    ld a, l
    ld [w_ch3_pattern_ptr_lo], a

    call music_playback_handler

    ret

.track_06_bonus
    ld a, $6
    ld [w_ch1_current_track], a
    ld [w_ch3_current_track], a

    ld a, $1
    ld [w_ch2_note_length], a 
    ld [w_ch3_note_length], a 
    ld [w_music_triggered_flag], a
    ld [w_ch2_pan_active], a  
    ld [w_ch2_pan_triggered_flag], a
    ld [w_ch2_pan_direction], a

    ld a, $28
    ld [w_ch2_pan_timer], a   
    ld [w_ch2_pan_timer_max], a

    ld hl, TRACK_06_CH2_PATTERN_DATA_START
    ld a, h
    ld [w_ch2_pattern_ptr_hi], a
    ld a, l
    ld [w_ch2_pattern_ptr_lo], a

    ld hl, TRACK_06_CH3_PATTERN_DATA_START
    ld a, h
    ld [w_ch3_pattern_ptr_hi], a
    ld a, l
    ld [w_ch3_pattern_ptr_lo], a

    call music_playback_handler

    ret

.track_07_bonus_fast
    ld a, $7
    ld [w_ch1_current_track], a
    ld [w_ch3_current_track], a

    ld a, $1
    ld [w_ch2_note_length], a 
    ld [w_ch3_note_length], a 
    ld [w_music_triggered_flag], a
    ld [w_ch2_pan_active], a  
    ld [w_ch2_pan_triggered_flag], a
    ld [w_ch2_pan_direction], a

    ld a, $20
    ld [w_ch2_pan_timer], a   
    ld [w_ch2_pan_timer_max], a

    ld hl, TRACK_07_CH2_PATTERN_DATA_START
    ld a, h
    ld [w_ch2_pattern_ptr_hi], a
    ld a, l
    ld [w_ch2_pattern_ptr_lo], a

    ld hl, TRACK_07_CH3_PATTERN_DATA_START
    ld a, h
    ld [w_ch3_pattern_ptr_hi], a
    ld a, l
    ld [w_ch3_pattern_ptr_lo], a

    call music_playback_handler

    ret

.track_08_bonus_start
    xor a
    ld [w_ch2_pan_active], a  

    ld a, $6
    ld [w_ch1_current_track], a
    ld [w_ch3_current_track], a

    ld a, $1
    ld [w_ch2_note_length], a 
    ld [w_ch3_note_length], a 
    ld [w_music_triggered_flag], a

    ld hl, TRACK_08_CH2_PATTERN_DATA_START
    ld a, h
    ld [w_ch2_pattern_ptr_hi], a
    ld a, l
    ld [w_ch2_pattern_ptr_lo], a

    ld hl, TRACK_08_CH3_PATTERN_DATA_START
    ld a, h
    ld [w_ch3_pattern_ptr_hi], a
    ld a, l
    ld [w_ch3_pattern_ptr_lo], a

    call music_playback_handler

    ret

.track_09_bonus_fail
    xor a
    ld [w_ch2_pan_active], a  

    ld a, $FF
    ldh [rNR51], a

    ld a, $6
    ld [w_ch1_current_track], a
    ld [w_ch3_current_track], a

    ld a, $1
    ld [w_ch2_note_length], a 
    ld [w_ch3_note_length], a 
    ld [w_music_triggered_flag], a

    ld hl, TRACK_09_CH2_PATTERN_DATA_START
    ld a, h
    ld [w_ch2_pattern_ptr_hi], a
    ld a, l
    ld [w_ch2_pattern_ptr_lo], a

    ld hl, TRACK_09_CH3_PATTERN_DATA_START
    ld a, h
    ld [w_ch3_pattern_ptr_hi], a
    ld a, l
    ld [w_ch3_pattern_ptr_lo], a

    call music_playback_handler
    
    ret

.track_0a_bonus_win
    xor a
    ld [w_ch2_pan_active], a  

    ld a, $FF
    ldh [rNR51], a

    ld a, $6
    ld [w_ch1_current_track], a
    ld [w_ch3_current_track], a

    ld a, $1
    ld [w_ch2_note_length], a 
    ld [w_ch3_note_length], a 
    ld [w_music_triggered_flag], a

    ld hl, TRACK_0A_CH2_PATTERN_DATA_START
    ld a, h
    ld [w_ch2_pattern_ptr_hi], a
    ld a, l
    ld [w_ch2_pattern_ptr_lo], a

    ld hl, TRACK_0A_CH3_PATTERN_DATA_START
    ld a, h
    ld [w_ch3_pattern_ptr_hi], a
    ld a, l
    ld [w_ch3_pattern_ptr_lo], a

    call music_playback_handler

    ret

.track_0b_brick_scrolldown
    xor a
    ld [w_ch2_pan_active], a  

    ld a, $6
    ld [w_ch1_current_track], a
    ld [w_ch3_current_track], a

    ld a, $1
    ld [w_ch2_note_length], a 
    ld [w_ch3_note_length], a 
    ld [w_music_triggered_flag], a

    ld hl, TRACK_0B_CH2_PATTERN_DATA_START
    ld a, h
    ld [w_ch2_pattern_ptr_hi], a
    ld a, l
    ld [w_ch2_pattern_ptr_lo], a

    ld hl, TRACK_0B_CH3_PATTERN_DATA_START
    ld a, h
    ld [w_ch3_pattern_ptr_hi], a
    ld a, l
    ld [w_ch3_pattern_ptr_lo], a

    call music_playback_handler

    ret

.track_0c_nice_play
    xor a
    ld [w_ch2_pan_active], a  

    ld a, $6
    ld [w_ch1_current_track], a
    ld [w_ch3_current_track], a

    ld a, $1
    ld [w_ch2_note_length], a 
    ld [w_ch3_note_length], a 
    ld [w_music_triggered_flag], a

    ld hl, TRACK_0C_CH2_PATTERN_DATA_START
    ld a, h
    ld [w_ch2_pattern_ptr_hi], a
    ld a, l
    ld [w_ch2_pattern_ptr_lo], a

    ld hl, TRACK_0C_CH3_PATTERN_DATA_START
    ld a, h
    ld [w_ch3_pattern_ptr_hi], a
    ld a, l
    ld [w_ch3_pattern_ptr_lo], a

    call music_playback_handler

    ret

music_playback_handler:
    ld a, [w_ch2_note_length] 
    dec a
    ld [w_ch2_note_length], a 

    cp $0
    jp nz, ch3_note_length_decrement

    ld a, [w_ch2_pattern_ptr_hi]  ; if ch2 has finished playing
    ld h, a
    ld a, [w_ch2_pattern_ptr_lo]  
    ld l, a

ch2_pattern_read_loop:
    ld a, [hl+]
    bit $7, a
    jp nz, ch2_set_note_length

    cp $0
    jp z, pattern_loop_command_mute_ch1

    cp $7F
    jp z, pattern_loop_command

    cp $1
    jp nz, .ch2_play_note

    call mute_ch2

    jr .ch2_save_ptr

.ch2_play_note
    ld [w_ch2_pitch_mirror], a

    ld a, $BF
    ldh [rNR21], a

    ld a, $F2
    ldh [rNR22], a

    ld a, [w_ch2_pitch_mirror]

    push hl

    ld hl, NOTE_FREQ_PTR_TABLE_LO_START
    ld d, $0
    ld e, a ; a = w_ch2_pitch_mirror
    add hl, de
    ld a, [hl]
    ldh [rNR23], a

    ld hl, NOTE_FREQ_PTR_TABLE_HI_START
    add hl, de
    ld a, [hl]
    ldh [rNR24], a

    pop hl

.ch2_save_ptr
    xor a   ; useless
    ld a, h
    ld [w_ch2_pattern_ptr_hi], a
    ld a, l
    ld [w_ch2_pattern_ptr_lo], a

    ld a, [w_ch2_note_length] 
    and a   ; affects Z flag
    jr nz, ch3_note_length_decrement

    ld a, [w_ch2_note_length_max] 
    ld [w_ch2_note_length], a 

ch3_note_length_decrement:
    ld a, [w_ch3_note_length] ; if the ch2 note still is playing
    dec a
    ld [w_ch3_note_length], a 

    cp $0
    jp nz, return_745e

    ld a, [w_ch3_pattern_ptr_hi]  
    ld h, a
    ld a, [w_ch3_pattern_ptr_lo]  
    ld l, a

ch3_pattern_read_loop:
    ld a, [hl+]
    bit $7, a
    jp nz, ch3_set_note_length

    cp $0
    jp z, pattern_loop_command_mute_ch3

    cp $7F
    jp z, pattern_loop_command

    cp $1
    jp nz, ch3_play_note

    call mute_ch3

    jr ch3_save_ptr

ch3_play_note:
    ld [w_ch3_pitch_mirror], a

    push hl

    ld a, $0
    ldh [rNR30], a

    ld a, $80
    ldh [rNR30], a

    ld a, $FF
    ldh [rNR31], a

    call load_ch3_waveform

    ld a, $20
    ldh [rNR32], a

    ld a, [w_ch3_pitch_mirror]
    ld hl, NOTE_FREQ_PTR_TABLE_LO_START
    ld d, $0
    ld e, a
    add hl, de
    ld a, [hl]
    ldh [rNR33], a

    ld hl, NOTE_FREQ_PTR_TABLE_HI_START
    add hl, de
    ld a, [hl]
    ldh [rNR34], a

    pop hl

ch3_save_ptr:
    ld a, h
    ld [w_ch3_pattern_ptr_hi], a
    ld a, l
    ld [w_ch3_pattern_ptr_lo], a

    ld a, [w_ch3_note_length] 
    and a   ; affects Z flag
    jr nz, return_745e
    
    ld a, [w_ch3_note_length_max] 
    ld [w_ch3_note_length], a 

return_745e:
    ret

; loads ch3_waveform_data in intervals of $10

load_ch3_waveform:
    ld hl, CH3_WAVEFORM_DATA_START
    ld c, $30

.LAB_7464
    ld a, [hl+]     ; =>ch3_waveform_data
    ldh [c], a        ; =>WAVE, a
    inc c

    ld a, [w_ch3_waveform_index]  
    inc a
    ld [w_ch3_waveform_index], a

    cp $10
    jp nz, .LAB_7464

    xor a
    ld [w_ch3_waveform_index], a

    ret

ch2_set_note_length:
    push hl

    and $7F

    ld hl, NOTE_LENGTH_TABLE_START
    ld d, $0
    ld e, a
    add hl, de

    ld a, [hl]
    ld [w_ch2_note_length], a 
    ld [w_ch2_note_length_max], a

    pop hl

    jp ch2_pattern_read_loop

ch3_set_note_length:
    push hl

    and $7F

    ld hl, NOTE_LENGTH_TABLE_START
    ld d, $0
    ld e, a
    add hl, de

    ld a, [hl]
    ld [w_ch3_note_length], a 
    ld [w_ch3_note_length_max], a

    pop hl

    jp ch3_pattern_read_loop

; $7F handler: reads current ch1 track as byte as track number, restarts music_handler

pattern_loop_command:
    ld a, [w_ch1_current_track]   
    ld [w_track_index], a

    jp music_track_handler                    

ch2_pan_handler:    ; Auto-panner for CH2
    ld a, [w_ch2_pan_active]  
    cp $1
    jp nz, .ch2_pan_deactivate

    ld a, [w_ch2_pan_direction]   
    cp $1
    jp nz, .ch2_pan_right

.ch2_pan_left
    ld a, [w_ch2_pan_timer]   
    dec a
    ld [w_ch2_pan_timer], a  

    cp $0
    jp z, .ch2_pan_left_to_right

    ld a, $75
    ldh [rNR51], a  ; $75 = 0111 0101 — CH2 left, others mixed     
    ret

.ch2_pan_left_to_right
    xor a
    ld [w_ch2_pan_direction], a
    
    ld a, [w_ch2_pan_timer_max]   
    ld [w_ch2_pan_timer], a   
    ret

.ch2_pan_right:
    ld a, [w_ch2_pan_timer]   
    dec a
    ld [w_ch2_pan_timer], a

    cp $0
    jp z, .ch2_pan_right_to_left

    ld a, $57
    ldh [rNR51], a
    ret

.ch2_pan_right_to_left
    ld a, $1
    ld [w_ch2_pan_direction], a

    ld a, [w_ch2_pan_timer_max]   
    ld [w_ch2_pan_timer], a   
    ret

.ch2_pan_deactivate
    xor a
    ld [w_ch2_pan_active], a  
    ret

pattern_loop_command_mute_ch1:
    xor a
    ld [w_ch1_current_track], a
    ld [w_ch2_pan_active], a  
    ldh [rNR12], a
    ret

pattern_loop_command_mute_ch3:
    xor a
    ld [w_ch3_current_track], a
    ld [w_ch2_pan_active], a  
    ldh [rNR32], a
    ret

; clears the current_track values and sets the music_flag to 0
; turns CH1, 2 and 3's amplitudes to 0 as well

stop_music:
    xor a
    ld [w_music_flag], a
    ld [w_ch1_current_track], a
    ld [w_ch3_current_track], a

    ldh [rNR12], a
    ldh [rNR22], a
    ldh [rNR32], a
    ret

mute_ch2: ; Turns off CH2's volume and envelope
    xor a
    ldh [rNR22], a
    ret

mute_ch3:   ;turns off CH3's DAC
    xor a
    ldh [rNR30], a
    ret

debug_reset_sfx_clear_flag:
    ld a, $1
    ld [w_debug_sfx_clear_flag], a
    ret

debug_set_sfx_clear_flag:
    xor a
    ld [w_debug_sfx_clear_flag], a
    ret

note_freq_ptr_table_hi:
    db $00,$C0,$80,$80,$81,$81,$81,$82,$82,$82,$83,$83,$83,$83,$84,$84,$84,$84,$84,$85,$85,$85,$85,$85,$85,$85,$86,$86,$86,$86,$86,$86,$86,$86,$86,$86,$86,$86,$87,$87,$87,$87,$87,$87,$87,$87,$87,$87,$87,$87,$87,$87,$87,$87,$87,$87,$87,$87,$87,$87,$87,$87,$87,$87,$87,$87,$87
    
note_freq_ptr_table_lo:
    db $00,$00,$2C,$9D,$07,$6B,$C9,$23,$77,$C7,$12,$58,$9B,$DA,$16,$4F,$83,$B5,$E5,$11,$3B,$63,$88,$AC,$CE,$ED,$0B,$27,$42,$5B,$72,$89,$9E,$B2,$C4,$D6,$E7,$F7,$06,$14,$21,$2D,$39,$44,$4F,$59,$62,$6B,$73,$7B,$83,$8A,$90,$97,$9D,$A2,$A7,$AC,$B1,$B6,$BA,$BE,$C1,$C5,$C8,$CB,$CE

note_length_table:
    db $04,$08,$10,$20,$40,$0C,$18,$30,$05,$06,$0B,$0A,$05,$0A,$14,$28,$50,$0F,$1E,$3C,$07,$06,$02,$01,$03,$06,$0C,$18,$30,$09,$12,$24,$04,$04,$0B,$0A,$06,$0C,$18,$30,$60,$12,$24,$48

track_01_ch2_pattern_data:
    db $99,$1E,$01,$9B,$1E,$99,$1E,$1F,$01,$20,$01,$9E,$21,$9A,$01,$27,$99,$25,$23,$01,$27,$99,$01,$27,$01,$27,$9A,$25,$23,$9A,$01,$28,$99,$25,$23,$01,$28,$99,$01,$28,$01,$28,$9A,$25,$23,$9A,$01,$27,$99,$25,$23,$01,$27,$99,$01,$9E,$27,$99,$25,$23,$25,$27,$9A,$01,$28,$99,$25,$23,$25,$27,$99,$01,$28,$9A,$01,$99,$2B,$2C,$9A,$28,$9A,$01,$27,$99,$25,$23,$25,$27,$99,$01,$9E,$27,$99,$2B,$9A,$2C,$99,$28,$99,$28,$01,$25,$23,$01,$20,$23,$01,$99,$28,$01,$00

track_01_ch3_pattern_data:
    db $99,$1E,$01,$9B,$1E,$99,$1E,$1F,$01,$20,$01,$9E,$21,$99,$23,$01,$2D,$01,$23,$01,$2F,$2D,$23,$2D,$2F,$2D,$23,$01,$2F,$01,$1C,$01,$2C,$01,$1C,$01,$2C,$01,$1C,$2C,$28,$2C,$1C,$01,$28,$01,$99,$23,$01,$2D,$01,$23,$01,$2F,$2D,$23,$2D,$2F,$01,$23,$01,$2F,$2D,$1C,$01,$2C,$01,$1C,$01,$28,$01,$1C,$2C,$28,$01,$1C,$01,$28,$01,$99,$23,$01,$2D,$01,$23,$01,$2F,$2D,$23,$2D,$2F,$01,$23,$2D,$2F,$01,$2C,$01,$28,$01,$1C,$01,$28,$01,$2C,$01,$20,$01,$1C,$01,$82,$01,$00

track_02_ch2_pattern_data:
    db $81,$2A,$26,$21,$82,$2B,$28,$81,$21,$81,$2A,$26,$82,$21,$81,$28,$01,$28,$01,$87,$2A,$00

track_02_ch3_pattern_data:
    db $81,$1A,$21,$82,$26,$81,$1F,$23,$82,$26,$81,$21,$2A,$26,$2A,$25,$01,$25,$01,$83,$26,$01,$00

track_03_ch2_pattern_data:
    db $9A,$01,$27,$99,$25,$23,$25,$27,$99,$01,$9E,$27,$99,$2B,$9A,$2C,$99,$28,$99,$28,$01,$25,$23,$01,$20,$23,$01,$99,$28,$01,$01,$01,$1C,$00

track_03_ch3_pattern_data:
    db $99,$23,$01,$2D,$01,$23,$01,$2F,$2D,$23,$2D,$2F,$01,$23,$2D,$2F,$01,$2C,$01,$28,$01,$1C,$01,$28,$01,$28,$01,$01,$01,$96,$01,$10,$00

track_04_ch2_pattern_data:
    db $81,$2A,$2D,$32,$00

track_04_ch3_pattern_data:
    db $86,$01,$00

track_05_ch2_pattern_data:
    db $81,$1E,$1A,$15,$1F,$1C,$15,$21,$1E,$81,$26,$25,$23,$25,$01,$21,$23,$25,$87,$2A,$00

track_05_ch3_pattern_data:
    db $82,$1A,$81,$26,$86,$1A,$82,$26,$82,$21,$81,$2D,$86,$21,$82,$2D,$83,$26,$82,$01,$00

track_06_ch2_pattern_data:
    db $8C,$2A,$26,$21,$01,$2B,$28,$21,$01,$2A,$26,$21,$01,$28,$25,$21,$01,$2A,$26,$21,$01,$2B,$28,$21,$01,$2A,$26,$21,$01,$28,$25,$21,$01,$8D,$1F,$23,$26,$8E,$1F,$8E,$23,$8D,$26,$8D,$21,$25,$28,$8E,$21,$8E,$26,$8D,$28,$7F

track_06_ch3_pattern_data:
    db $8C,$1A,$01,$1A,$01,$1F,$01,$1F,$01,$1A,$01,$1A,$01,$21,$01,$21,$01,$1A,$01,$1A,$01,$1F,$01,$1F,$01,$1A,$01,$1A,$01,$21,$01,$21,$01,$8D,$1F,$2B,$2B,$1F,$8C,$1F,$01,$2B,$01,$8D,$2B,$1F,$8D,$21,$2D,$2D,$21,$8C,$21,$01,$2D,$01,$8D,$2D,$21,$7F

track_07_ch2_pattern_data:
    db $80,$2A,$26,$21,$01,$2B,$28,$21,$01,$2A,$26,$21,$01,$28,$25,$21,$01,$2A,$26,$21,$01,$2B,$28,$21,$01,$2A,$26,$21,$01,$28,$25,$21,$01,$81,$1F,$23,$26,$82,$1F,$82,$23,$81,$26,$81,$21,$25,$28,$82,$21,$82,$26,$81,$28,$7F

track_07_ch3_pattern_data:
    db $80,$1A,$01,$1A,$01,$1F,$01,$1F,$01,$1A,$01,$1A,$01,$21,$01,$21,$01,$1A,$01,$1A,$01,$1F,$01,$1F,$01,$1A,$01,$1A,$01,$21,$01,$21,$01,$81,$1F,$2B,$2B,$1F,$80,$1F,$01,$2B,$01,$81,$2B,$1F,$81,$21,$2D,$2D,$21,$80,$21,$01,$2D,$01,$81,$2D,$21,$7F

track_08_ch2_pattern_data:
    db $91,$2A,$8C,$2A,$91,$28,$8C,$28,$91,$21,$8C,$21,$91,$2B,$8C,$2B,$93,$2D,$00

track_08_ch3_pattern_data:
    db $94,$21,$26,$95,$2A,$94,$21,$28,$95,$2B,$94,$21,$26,$95,$2A,$94,$21,$28,$95,$2B,$92,$2A,$92,$01,$00

track_09_ch2_pattern_data:
    db $83,$26,$81,$01,$21,$23,$25,$82,$26,$81,$2A,$28,$01,$86,$25,$87,$26,$00

track_09_ch3_pattern_data:
    db $82,$1A,$81,$26,$1A,$01,$1A,$82,$26,$82,$21,$81,$23,$25,$01,$1A,$01,$1A,$87,$1A,$00

track_0a_ch2_pattern_data:
    db $83,$26,$81,$01,$21,$23,$25,$82,$26,$81,$2A,$28,$01,$86,$25,$81,$1F,$82,$23,$81,$26,$01,$2B,$01,$2B,$81,$21,$82,$25,$81,$28,$01,$2D,$01,$2D,$81,$1F,$82,$23,$81,$26,$01,$2B,$01,$2B,$81,$21,$82,$25,$81,$28,$01,$2D,$01,$2D,$83,$1E,$00

track_0a_ch3_pattern_data:
    db $82,$1A,$81,$26,$1A,$01,$1A,$82,$26,$82,$21,$81,$23,$25,$01,$1A,$01,$1A,$82,$1F,$81,$2B,$1F,$01,$23,$01,$26,$82,$21,$81,$2D,$21,$01,$28,$01,$2D,$82,$1F,$81,$2B,$1F,$01,$23,$01,$26,$82,$21,$81,$2D,$21,$01,$28,$01,$2D,$83,$26,$00

track_0b_ch2_pattern_data:
    db $97,$14,$11,$0F,$17,$13,$11,$0F,$17,$00

track_0b_ch3_pattern_data:
    db $96,$10,$10,$0E,$0E,$00

track_0c_ch2_pattern_data:
    db $A5,$2A,$26,$21,$2B,$28,$21,$2D,$2A,$A5,$2A,$26,$21,$2B,$28,$21,$2D,$2A,$A5,$1F,$23,$26,$A6,$2B,$2A,$A5,$28,$AA,$26,$A6,$25,$26,$A5,$28,$A5,$2A,$26,$21,$2B,$28,$21,$2D,$2A,$A5,$2A,$26,$21,$2B,$28,$21,$2D,$2A,$A5,$1F,$23,$26,$A6,$2B,$2A,$A5,$28,$AA,$26,$A6,$25,$26,$A5,$28,$A5,$1F,$23,$26,$A7,$2B,$A5,$01,$A5,$21,$25,$28,$A7,$2D,$A5,$01,$A5,$1F,$23,$26,$A7,$2B,$A5,$01,$A5,$21,$25,$28,$2D,$01,$AA,$2D,$A7,$2A,$A7,$01,$00

track_0c_ch3_pattern_data:
    db $A4,$1A,$01,$1A,$01,$1A,$01,$1A,$01,$A4,$1A,$01,$1A,$01,$1A,$01,$1A,$01,$A4,$1A,$01,$1A,$01,$1A,$01,$1A,$01,$A4,$1A,$01,$1A,$01,$1A,$01,$1A,$01,$A4,$1F,$01,$1F,$01,$1F,$01,$1F,$01,$A4,$1F,$01,$1F,$01,$1F,$01,$1F,$01,$A4,$21,$01,$21,$01,$21,$01,$21,$01,$A4,$21,$01,$21,$01,$21,$01,$21,$01,$A4,$1A,$01,$1A,$01,$1A,$01,$1A,$01,$A4,$1A,$01,$1A,$01,$1A,$01,$1A,$01,$A4,$1A,$01,$1A,$01,$1A,$01,$1A,$01,$A4,$1A,$01,$1A,$01,$1A,$01,$1A,$01,$A4,$1F,$01,$1F,$01,$1F,$01,$1F,$01,$A4,$1F,$01,$1F,$01,$1F,$01,$1F,$01,$A4,$21,$01,$21,$01,$21,$01,$21,$01,$A4,$21,$01,$21,$01,$21,$01,$21,$01,$A4,$1F,$23,$26,$2B,$A4,$1F,$23,$26,$2B,$A4,$1F,$23,$26,$2B,$A4,$1F,$23,$26,$2B,$A4,$21,$25,$28,$2D,$A4,$21,$25,$28,$2D,$A4,$21,$25,$28,$2D,$A4,$21,$25,$28,$2D,$A4,$1F,$23,$26,$2B,$A4,$1F,$23,$26,$2B,$A4,$1F,$23,$26,$2B,$A4,$1F,$23,$26,$2B,$A4,$21,$25,$28,$2D,$A4,$21,$25,$28,$2D,$A4,$21,$25,$28,$2D,$A4,$21,$25,$28,$2D,$AA,$26,$A7,$01,$A5,$01,$00

ch3_waveform_data:
    db $89,$AB,$BB,$BB,$BB,$BB,$98,$54,$21,$00,$00,$00,$00,$00,$00,$00

SECTION "Audio Update Thunk", ROM0[$7FF0]

audio_update_thunk:
    jp audio_update

; Trampoline wrapper, likely a remnant of a banked development architecture.
; Alleyway is a 32KB ROM-only cart no MBC, no bank switching occurs at runtime.

stop_music_wrapper:
    call stop_music
    ret