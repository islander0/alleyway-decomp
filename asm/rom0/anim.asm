DEF PADDLE_OPEN_CLOSE_ANIM_SPR_PTR_START    EQU $4551
DEF PADDLE_OPEN_FRAME_0_TILE_DATA_START     EQU $4554
DEF EXPLOSION_ANIM_OFFSET_DATA_START        EQU $4599
DEF MARIO_WINK_ANIM_OFFSET_DATA_START       EQU $45E6

SECTION "Bricks Animation", ROM0[$0997]

; Runs brick_collision_handler + wait_vblank 10 times, decrementing h_play_area_scroll_y
; by 2 each time, then handles the remainder via lcd_y_descent_counter.
; This is the timed scroll-in animation that slides the brick field down
; into view when a level starts.

animate_bricks_scroll_in:
    ldh a, [h_total_row_count]    
    dec a
    dec a
    ldh [h_play_area_scroll_y], a

    ld a, $A

.Lab_099f  
    push af
    call brick_collision_handler
    call wait_vblank
    ldh a, [h_play_area_scroll_y] 
    dec a
    dec a
    ldh [h_play_area_scroll_y], a
    pop af
    dec a
    jr nz, .Lab_099f

    ldh a, [h_lcd_y_descent_counter]   
    cp $0
    ret z
    
    dec a
    ldh [h_play_area_scroll_y], a
    jp brick_collision_handler

SECTION "Animations", ROM0[$43DC]

; initializes the paddle and music                 
; manages mario's walking and jumping animation    

mario_start_handler:
    call update_paddle_oam_buffer
    call load_track_start

    ldh a, [h_paddle_x]    
    add $50
    ld [w_current_anim_x], a

    ldh a, [h_init_paddle_y] 
    sub $10
    ld [w_current_anim_y], a

    ld a, $3
    ld [w_anim_timer], a 

.update_mario_walk 
    call update_mario_walking_frame
    call copy_current_anim_xy
    ld a, [w_current_anim_x]
    dec a
    ld [w_current_anim_x], a
    cp $44  ;when mario reaches x = $44
    jr nz, .update_mario_walk

    ld a, $3
    ld [w_mario_anim_frame], a; stand still

    call copy_current_anim_xy
    call set_event_mario_jump
    call paddle_open_anim_handler

    ld a, $4
    ld [w_mario_anim_frame], a; jump to the left

    xor a
    ld [w_mario_jump_frame_index], a
    ld [w_mario_jump_x_direction_flag], a  

.update_mario_jump_velocity
    call copy_current_anim_xy
    call mario_jump_velocity_handler

    ld a, [w_mario_jump_frame_index]
    cp $18  ; jump_frame_index finished
    jr c, .update_mario_jump_velocity

.lower_mario 
    call copy_current_anim_xy
    ld a, [w_current_anim_y] 
    inc a
    inc a
    inc a
    inc a
    ld [w_current_anim_y], a  ; descend mario 4px down
    cp $88
    jr c, .lower_mario  ; mario y = $88

    call load_anim_oam_buffer
    ld a, $10
    call wait_frames
    call paddle_close_anim_handler
    call update_paddle_oam_buffer
    ret

mario_game_over_handler:
    call shift_paddle_left
    call update_paddle_oam_buffer
    call set_event_death_no_lives
    call paddle_open_anim_handler

    ld a, $88
    ld [w_current_anim_y], a  

    ldh a, [h_paddle_x]    
    add $4
    ld [w_current_anim_x], a  

    ld b, $0
    ld c, $5
    cp $4C
    jr nc, .LAB_4471

    ld b, $1
    ld c, $6

.LAB_4471 
    ld a, b
    ld [w_mario_jump_x_direction_flag], a  
    ld a, c
    ld [w_mario_anim_frame], a  

    xor a
    ld [w_mario_jump_frame_index], a

.LAB_447d
    call copy_current_anim_xy
    call mario_jump_velocity_handler
    ld a, [w_mario_jump_frame_index]
    cp $18
    jr c, .LAB_447d

.LAB_448a 
    call copy_current_anim_xy

    ld a, [w_current_anim_y] 
    inc a
    inc a
    inc a
    inc a
    ld [w_current_anim_y], a

    cp $A0
    jr c, .LAB_448a

    call load_anim_oam_buffer
    ld a, $40
    call wait_frames
    ret

; increase mario's walking frame when the animation timer hits 0
; caps at 3                  

update_mario_walking_frame:
    ld a, [w_anim_timer]
    dec a
    ld [w_anim_timer], a 
    ret nz

    ld a, [w_mario_anim_frame]    
    inc a
    cp $3
    jr c, .LAB_44b5

    xor a

.LAB_44b5
    ld [w_mario_anim_frame], a  

    ld a, $5
    ld [w_anim_timer], a 
    ret

; Copy mario's XY to BC

copy_current_anim_xy:
    ld a, [w_current_anim_x] 
    ld b, a
    ld a, [w_current_anim_y] 
    ld c, a

    ld a, [w_mario_anim_frame]    
    call copy_tiles4_oam_buffer
    jp wait_vblank

mario_jump_velocity_handler:
    ld a, [w_mario_jump_frame_index]
    ld c, a
    inc a
    ld [w_mario_jump_frame_index], a

    ld b, $0
    ld hl, $44F5    ; [$44F5] = mario_jump_y_velocity_data
    add hl, bc

    ld a, [hl]  ; =>mario_jump_y_velocity_data
    ld b, a
    ld a, [w_current_anim_y]
    add b
    ld [w_current_anim_y], a

    ld a, [w_mario_jump_x_direction_flag]
    sla a
    dec a
    ld b, a
    ld a, [w_current_anim_x]
    add b
    ld [w_current_anim_x], a
    ret

mario_jump_y_velocity_data:
    db $FD,$FD,$FD  ; -3
    db $FE,$FE,$FE  ; -2
    db $FF,$FF,$FF  ; -1
    db $00          ; 0
    db $FF          ; -1
    db $00,$00      ; 0
    db $01          ; 1
    db $00          ; 0
    db $01,$01,$01  ; 1
    db $02,$02,$02  ; 2
    db $03,$03,$03  ; 3

paddle_open_anim_handler:
    call update_paddle_oam_buffer
    xor a

.next_anim_frame 
    push af
    call paddle_open_close_oam_handler
    ld a, $8
    call wait_frames
    pop af

    inc a
    cp $3
    jr c, .next_anim_frame

    ret

paddle_close_anim_handler:
    ld a, $2

.next_anim_frame 
    push af
    call paddle_open_close_oam_handler
    ld a, $C
    call wait_frames
    pop af
    dec a
    cp $FF
    jr nz, .next_anim_frame
    ret

paddle_open_close_oam_handler:
    ld b, $0
    ld c, a         ; A = $00 or $02
    ld hl, PADDLE_OPEN_CLOSE_ANIM_SPR_PTR_START
    add hl, bc

    ld b, [hl]      ; =>paddle_open_close_anim_spr_ptr
    ld e, $3
    call multiply   ; C *= $03
    
    ld hl, PADDLE_OPEN_FRAME_0_TILE_DATA_START
    add hl, bc

    ld a, [hl+]     ; =>paddle_open_frame_0_tile_data
    ld [OAM_PADDLE_START + $02], a

    ld a, [hl+]     ; =>paddle_open_frame_0_tile_data[1]
    ld [OAM_PADDLE_START + $06], a

    ld a, [hl]      ; =>paddle_open_frame_0_tile_data[2]
    ld [OAM_PADDLE_START + $0A], a
    ret

; Open: 0 -> 1 -> 2              
; Close: 2 -> 1 -> 0  

paddle_open_close_anim_spr_ptr:
    db $00,$01,$02

paddle_open_frame_0_tile_data:
    db $00,$04,$00

paddle_open_frame_1_tile_data:
    db $00,$03,$00

paddle_open_frame_2_tile_data:
    db $02,$03,$02

explosion_oam_handler:
    call set_ball_oob   ; function call on ball_oob
    ldh a, [h_ball_x] 
    sub $8
    ld [w_current_anim_x], a  ; offset the explosion oam 8 pixels to the left
    ld a, $90
    ld [w_current_anim_y], a
    xor a
    ld [w_anim_timer], a 

.next_anim_frame
    push bc
    ld a, [w_current_anim_x] 
    ld b, a
    ld a, [w_current_anim_y] 
    ld c, a ; copy explosion xy to BC
    ld a, [w_anim_timer]
    ld d, $0
    ld e, a

    ld hl, EXPLOSION_ANIM_OFFSET_DATA_START
    add hl, de
    ld a, [hl]  ; =>explosion_anim_offset_data

    ; write the value at hl offset (inc) by the animation counter

    call copy_tiles4_oam_buffer
    call wait_vblank
    pop bc
    
    ld a, [w_anim_timer]
    inc a
    ld [w_anim_timer], a

    cp $24
    jr c, .next_anim_frame

    jp load_anim_oam_buffer

explosion_anim_offset_data:
    db $07,$07,$07,$07,$07,$07,$07,$07
    db $08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08
    db $09,$09,$09,$09,$09,$09,$09,$09,$09,$09,$09,$09,$09,$09,$09,$09

mario_wink_oam_handler:
    xor a
    ld [w_anim_timer], a

.next_anim_frame
    push bc
    ld b, $38   ; x offset
    ld c, $48   ; y offset
    ld a, [w_anim_timer]
    ld d, $0
    ld e, a

    ld hl, MARIO_WINK_ANIM_OFFSET_DATA_START
    add hl, de
    ld a, [hl]  ; =>mario_wink_anim_offset_data
    call copy_tiles4_oam_buffer
    call wait_vblank
    pop bc
    ld a, [w_anim_timer]
    inc a
    ld [w_anim_timer], a 
    cp $1D
    jr c, .next_anim_frame
    jp load_anim_oam_buffer

mario_wink_anim_offset_data:
    db $0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A
    db $0B,$0B,$0B,$0B,$0B,$0B
    db $0C,$0C,$0C,$0C,$0C,$0C
    db $0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B
    db $0A

SECTION "Animation Frame Tile Data", ROM0[$4AA5]

; [0] mario_walk_frame_0
; [1] mario_walk_frame_1
; [2] mario_walk_frame_2
; [3] mario_still
; [4] mario_jump_in
; [5] mario_jump_out_left
; [6] mario_jump_out_right
; [7] explosion_frame_0
; [8] explosion_frame_1
; [9] explosion_frame_2
; [10] mario_wink_frame_0
; [11] mario_wink_frame_1
; [12] mario_wink_frame_2

anim_frame_tile_data:
    db $00,$00,$06,$80,$00,$08,$07,$80,$08,$00,$08,$80,$08,$08,$09,$80
    db $00,$00,$0A,$80,$00,$08,$0B,$80,$08,$00,$0C,$80,$08,$08,$0D,$80
    db $00,$00,$0E,$80,$00,$08,$0F,$80,$08,$00,$10,$80,$08,$08,$11,$80
    db $00,$00,$12,$80,$00,$08,$13,$80,$08,$00,$14,$80,$08,$08,$15,$80
    db $00,$00,$16,$80,$00,$08,$17,$80,$08,$00,$18,$80,$08,$08,$19,$80
    db $00,$00,$1A,$80,$00,$08,$17,$80,$08,$00,$18,$80,$08,$08,$19,$80
    db $00,$00,$17,$A0,$00,$08,$1A,$A0,$08,$00,$19,$A0,$08,$08,$18,$A0
    db $00,$00,$FF,$00,$00,$08,$FF,$00,$08,$00,$1B,$00,$08,$08,$1B,$20
    db $00,$00,$1C,$00,$00,$08,$1C,$20,$08,$00,$1D,$00,$08,$08,$1D,$20
    db $00,$00,$1E,$00,$00,$08,$1E,$20,$08,$00,$1F,$00,$08,$08,$1F,$20
    db $00,$00,$FF,$00,$00,$08,$FF,$00,$08,$00,$FF,$00,$08,$08,$FF,$00
    db $00,$00,$21,$00,$00,$08,$22,$00,$08,$00,$23,$00,$08,$08,$24,$00
    db $00,$00,$21,$00,$00,$08,$22,$00,$08,$00,$25,$00,$08,$08,$26,$00