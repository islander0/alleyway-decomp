DEF BONUS_STAGE_PROPERTIES_TABLE_START  EQU $1B71

SECTION "Bonus Stage Time", ROM0[$198C]

decrement_bonus_stage_time:
    ldh a, [h_game_tick]
    and $1F ; 0001 1111
    ret nz

    ld a, [w_bonus_stage_time]    
    dec a
    ld [w_bonus_stage_time], a    ; bonus time--
    
    push af
    call z, set_lose_state  ; if no time left -> lose
    pop af

    cp $14  ; 20 sec
    call z, load_track_bonus_stage_fast ; Bonus Fast

; |                               |
; | LOAD THE NEW DECREMENTED TIME |
; V                               V

; Loads maximum bonus time into the OAM buffer     
; bonus stage 1 = $5F           
; bonus stage 2 = $5a
; bonus stage 3 = $55           
; bonus stage 4+ = $50          

load_bonus_stage_time_oam_buffer:
    ld hl, OAM_BONUS_STAGE_TIME_START
    ld a, [w_bonus_stage_time]    
    call binary_to_bcd

    ld c, a
    ld a, $80
    ld [hl+], a ; OAM_BONUS_STAGE_TIME_START + $00 Y

    ld a, $90
    ld [hl+], a ; OAM_BONUS_STAGE_TIME_START + $01 X

    ld a, b
    add $80
    ld [hl+], a ; OAM_BONUS_STAGE_TIME_START + $02 Tile ID (+$80 offset for number)

    ld a, $0
    ld [hl+], a ; OAM_BONUS_STAGE_TIME_START + $03 Attribute

    ld a, $80
    ld [hl+], a ; OAM_BONUS_STAGE_TIME_START + $04 Y

    ld a, $98
    ld [hl+], a ; OAM_BONUS_STAGE_TIME_START + $05 X

    ld a, c
    add $80
    ld [hl+], a ; OAM_BONUS_STAGE_TIME_START + $06 Tile ID (+$80 offset for number)

    ld a, $0
    ld [hl+], a ; OAM_BONUS_STAGE_TIME_START + $07 Attribute
    
    ret

SECTION "Bonus System", ROM0[$19CC]

; loads the time and points of the bonus level + loads the music that plays when bonus stages begin

bonus_start_handler:
    call update_bonus_stage_properties

    ld a, [hl]  ; $5F, $5A, $55 or $50
    ld [w_bonus_stage_time], a  

    call load_bonus_time_text_vram
    call load_bonus_stage_time_oam_buffer
    call load_track_bonus_stage_start

    ld a, $20
    call wait_frames    ; 32 frames
    
    ret

; Tracks the value of the current bonus stage and uses that value
; to point to a table that contains the data of the maximum bonus
; stage time at BONUS_STAGE_PROPERTIES_TABLE_START.
; caps at bonus stage 4     

update_bonus_stage_properties:
    ld a, [w_bonus_stage_number]  
    dec a
    cp $3
    jr c, .LAB_19ec ; jr if on bonus stage 1-3

    ld a, $3

.LAB_19ec
    ld b, a
    ld e, $3
    call multiply   ; bc = b * 3

    ld hl, BONUS_STAGE_PROPERTIES_TABLE_START
    add hl, bc
    ret

; checks whether the player lost the bonus stage or not

init_bonus_state:
    call stop_music_wrapper

    ldh a, [h_active_brick_count_hi]        
    ld b, a
    ldh a, [h_active_brick_count_lo] 

    or b
    jr z, .load_track_0a_and_wait    ; If there are no bricks on screen, jr -> $1A0A

    call load_track_bonus_stage_lose

    ld a, $80
    jp wait_frames

.load_track_0a_and_wait 
    call load_track_bonus_stage_win

    ld a, $FF
    call wait_frames

    ld a, $40
    call wait_frames    ; wait 319 frames total

    jp .LAB_1a1a

.LAB_1a1a
    call load_special_bonus_text_vram
    call update_bonus_stage_properties

    inc hl  ; base: BONUS_STAGE_PROPERTIES_TABLE_START
    ld b, [hl]
    inc hl
    ld c, [hl]

    push bc

    call load_special_bonus_points_oam_buffer

    ld a, $80
    call wait_frames

    pop bc

.check_remaining_bonus_points
    ld a, b
    cp 0
    jr nz, .add_10_points

    ld a, c
    cp 0
    ret z

    cp 10
    jr c, .add_1_point

.add_10_points 
    dec bc
    dec bc
    dec bc
    dec bc
    dec bc
    dec bc
    dec bc
    dec bc
    dec bc
    dec bc  ; BC -= 10

    push bc

    call load_special_bonus_points_oam_buffer

    ldh a, [h_player_score_hi]              
    ld h, a
    ldh a, [h_player_score_lo]              
    ld l, a

    ld b, $0
    ld c, 10
    add hl, bc

    ld a, h
    ldh [h_player_score_hi], a   
    ld a, l
    ldh [h_player_score_lo], a  ; player_score += 10

    call update_score_all
    call extra_life_score_handler
    call update_score_oam_buffer
    call set_event_bonus_countdown
    call wait_vblank

    pop bc

    jr .check_remaining_bonus_points

.add_1_point
    dec bc

    push bc

    call load_special_bonus_points_oam_buffer

    ldh a, [h_player_score_hi]              
    ld h, a
    ldh a, [h_player_score_lo]              
    ld l, a

    ld b, $0
    ld c, $1
    add hl, bc

    ld a, h
    ldh [h_player_score_hi], a   
    ld a, l
    ldh [h_player_score_lo], a  ; player_score++

    call update_score_all
    call extra_life_score_handler
    call update_score_oam_buffer
    call set_event_bonus_countdown
    call wait_vblank

    pop bc

    ld a, b
    or c
    jr nz, .add_1_point

    ret

SECTION "Bonus Stage Data", ROM0[BONUS_STAGE_PROPERTIES_TABLE_START]

; 4 x (bonus stage max (8-bit) + bonus stage points (16-b... *
; [1] Bonus stage 1:      95 sec  500 bonus points 
; [2] Bonus stage 2:      90 sec  700 bonus points 
; [3] Bonus stage 3:      85 sec  1000 bonus points
; [4] Bonus stage 4+:     80 sec  1500 bonus points

bonus_stage_properties_table:
    db $5F,$01,$F4
    db $5A,$02,$BC
    db $55,$03,$E8
    db $50,$05,$DC