DEF PLACEHOLDER_BYTE_ARRAY_100B_START   EQU $100B

DEF BALL_VELOCITY_PTR_TABLE_START   EQU $11EE

SECTION "Bonus Ball Set", ROM0[$0738]

; ball phases through and increase the bonus level number

bonus_ball_set:
    ld a, $1
    ldh [h_ball_phase_through], a

    ld a, [w_bonus_stage_number]  
    inc a
    ld [w_bonus_stage_number], a

    ret

SECTION "Ball Physics", ROM0[$0CA6]

; Thin wrapper called each frame during gameplay   

ball_update:
    call update_ball_position
    call ball_physics_and_collision_handler
    call update_ball_oam_buffer
    ret

; Ball physics dispatcher. Handles paddle collision (including side-hit -> reverse_ball_x_velocity),
; ceiling bounce + paddle shrink, wall bounce, out-of-bounds -> game_state = 7 (ball lost),
; and dispatches to the brick collision sub-system via check_brick_collision_both_axes.

ball_physics_and_collision_handler:
    nop

    ldh a, [h_ball_y_velocity_hi]
    and $80
    jr nz, .ball_y_collision_handler

    ldh a, [h_ball_y]      
    sub $8d
    jr c, .ball_y_collision_handler

    cp $8
    jr nc, .ball_y_collision_handler

    ld c, a
    ldh a, [h_paddle_collision_width]
    add $5
    ld d, a
    ldh a, [h_paddle_x]
    sub $3
    ld b, a
    ldh a, [h_ball_x]  
    sub b
    cp d
    jr nc, .ball_y_collision_handler

    srl a
    ld b, a
    ld a, c
    cp $7
    ld a, b

    push af
    call c, paddle_collision_handler
    pop af

    call nc, reverse_ball_x_velocity

.ball_y_collision_handler
    ldh a, [h_ball_y]      
    cp $18
    jp c, .update_paddle_size ; if ball hits ceiling

    cp $A0
    jp c, .check_ball_x

    ld a, $7    ; if ball oob
    ldh [h_game_state], a

    ret

.update_paddle_size 
    call set_event_wall

    ldh a, [h_ball_phase_through]
    cp $0
    jr nz, .reverse_ball_y_velocity ; jr if bonus stage

    ldh a, [h_paddle_size] 
    cp $0
    jr nz, .reverse_ball_y_velocity  ; jr IF PADDLE small

    ld a, $1
    ldh [h_paddle_size], a 

    ld a, $10
    ldh [h_paddle_collision_width], a 

    ldh a, [h_paddle_x]
    add $4
    ldh [h_paddle_x], a  

    call set_event_ceiling

.reverse_ball_y_velocity
    call reverse_ball_y_velocity

.check_ball_x
    ldh a, [h_ball_x]  
    cp $10
    jp c, .ball_wall_collision

    cp $7C
    jp c, .LAB_0d27


.ball_wall_collision
    call reverse_ball_x_velocity
    call set_event_wall

.LAB_0d27 
    ldh a, [h_ball_y]   ; if no wall is hit
    sub $88
    ret nc

    xor a
    ldh [h_ball_collision_flag], a  
    call check_brick_collision_both_axes

    ldh a, [h_ball_collision_flag]  
    cp $0
    ret z

SECTION "Ball Collision and Velocity", ROM0[$E8D]

reverse_ball_y_velocity:
    ldh a, [h_ball_y_velocity_hi]
    and $80     ; $80: 1000 0000

    push af
    call z, align_ball_y_down
    pop af

    call nz, align_ball_y_up

    ldh a, [h_ball_y_velocity_hi]
    ld b, a
    ldh a, [h_ball_y_velocity_lo]
    ld c, a

    call negate_bc

    ld a, b
    ldh [h_ball_y_velocity_hi], a
    ld a, c
    ldh [h_ball_y_velocity_lo], a

    ldh a, [h_ball_y]      
    ldh [h_ball_y_mirror], a

    ret

reverse_ball_x_velocity:
    ldh a, [h_ball_x_velocity_hi]
    and $80

    push af
    call z, align_ball_x_left
    pop af

    call nz, align_ball_x_right

    ldh a, [h_ball_x_velocity_hi]
    ld b, a
    ldh a, [h_ball_x_velocity_lo]
    ld c, a

    call negate_bc

    ld a, b
    ldh [h_ball_x_velocity_hi], a
    ld a, c
    ldh [h_ball_x_velocity_lo], a

    ldh a, [h_ball_x]  
    ldh [h_ball_x_mirror], a

    ret

LAB_0ecd:
    ret

    ; unused code

    ldh a, [h_ball_y_velocity_hi]
    and $80

    push af
    call nz, align_ball_y_down
    pop af

    call z, align_ball_y_up

    ret

align_ball_x_update:
    ldh a, [h_ball_x_velocity_hi]
    and $80

    push af
    call nz, align_ball_x_left
    pop af

    call z, align_ball_x_right

    ret

; snap to lower 4-pixel boundary (ball moving down)

align_ball_y_down:
    ldh a, [h_ball_y]      
    and $3

    ret z

; if ball_y != multiple of 4

    ld b, a

    ldh a, [h_ball_y]      
    and $FC ; $FC = 1111 1100
    sub b
    inc a
    ldh [h_ball_y], a 

    ret

; snap to lower 4-pixel boundary (ball moving up)  

align_ball_y_up:
    ldh a, [h_ball_y]      
    and $3
    ret z

; if ball_y != a multiple of 4

    ld b, a

    ldh a, [h_ball_y]      
    and $FC
    add $8
    sub b
    dec a
    ldh [h_ball_y], a 

    ret

align_ball_x_left:
    ld b, $4

    ldh a, [h_ball_x]  
    and $4
    jr nz, .LAB_0f12

    ld b, $FC

.LAB_0f12
    ldh a, [h_ball_x]  
    and $F8
    add b
    cp $10  ; left wall boundary
    jr nc, .update_ball_x

    ld a, $10

.update_ball_x
    ldh [h_ball_x], a 
    ret

align_ball_x_right:
    ldh a, [h_ball_x]  
    and $F8
    add $8
    cp $7C  ; right wall boundary
    jr c, .update_ball_x
    
    ld a, $7C

.update_ball_x
    ldh [h_ball_x], a 
    ret

SECTION "Unused Ball Velocity", ROM0[$0F5D]

; most likely a scrapped game mechanic that incremented the ball's velocity each time the player hit 8 bricks

unused_ball_velocity_brick_collision_handler:
    ldh a, [h_unused_brick_collision_count] 
    inc a
    cp $8
    jr c, .update_brick_collision_count
    call unused_increment_ball_velocity
    call update_ball_velocity_on_brick_collision
    xor a

.update_brick_collision_count
    ldh [h_unused_brick_collision_count], a             
    ret

unused_increment_ball_velocity:
    ldh a, [h_ball_velocity]     
    inc a
    cp $1A
    jr c, .update_ball_velocity

    ld a, $3    ; ball_velocity is never >= $1A so it's an unused check

.update_ball_velocity 
    ldh [h_ball_velocity], a
    jp debug_ball_velocity

update_ball_position:
    
    ; ball y
    
    ldh a, [h_ball_y]
    ldh [h_ball_y_mirror], a

    ld h, a
    ldh a, [h_ball_y_subpixel]
    ld l, a
    ldh a, [h_ball_y_velocity_hi]

    ld b, a
    ldh a, [h_ball_y_velocity_lo]
    ld c, a

    add hl, bc

    ld a, c
    ldh [h_ball_y_velocity_lo], a
    ld a, b
    ldh [h_ball_y_velocity_hi], a

    ld a, l
    ldh [h_ball_y_subpixel], a
    ld a, h
    ldh [h_ball_y], a

    ; ball x

    ldh a, [h_ball_x]
    ldh [h_ball_x_mirror], a

    ld h, a
    ldh a, [h_ball_x_subpixel]
    ld l, a
    ldh a, [h_ball_x_velocity_hi]

    ld b, a
    ldh a, [h_ball_x_velocity_lo]
    ld c, a
    
    add hl, bc

    ld a, c
    ldh [h_ball_x_velocity_lo], a
    ld a, b
    ldh [h_ball_x_velocity_hi], a

    ld a, l
    ldh [h_ball_x_subpixel], a
    ld a, h
    ldh [h_ball_x], a

    ret

SECTION "Ball Velocity and Spawn", ROM0[$0FBD]

update_ball_velocity_on_brick_collision:
    ld b, $0

    ldh a, [h_ball_velocity]     
    dec a
    sla a
    ld c, a

    ld hl, BALL_VELOCITY_PTR_TABLE_START
    add hl, bc  ; +4, +8 or +12

    ld a, [hl+] ; =>ball_velocity_ptr_table
    ld c, a
    ld a, [hl]  ; =>ball_velocity_ptr_table[1]
    ld b, a

    push bc

    call update_frame_accumulator

    and $7

    ld b, $0
    ld c, a
    
    ld hl, PLACEHOLDER_BYTE_ARRAY_100B_START
    add hl, bc
    ld a, [hl]  ; =>BYTE_ARRAY_100B

    pop bc

    sla a
    sla a

    ld h, $0
    ld l, a
    add hl, bc

    ld a, [hl+]
    ld b, a
    ld a, [hl+]
    ld c, a
    ldh a, [h_ball_y_velocity_hi]
    and $80
    jr z, .LAB_0ff1

    call negate_bc

.LAB_0ff1
    ld a, b
    ldh [h_ball_y_velocity_hi], a
    ld a, c
    ldh [h_ball_y_velocity_lo], a
    ld a, [hl+]
    ld b, a
    ld a, [hl+]
    ld c, a
    ldh a, [h_ball_x_velocity_hi]
    and $80
    jr z, .LAB_1004
    call negate_bc

.LAB_1004
    ld a, b
    ldh [h_ball_x_velocity_hi], a
    ld a, c
    ldh [h_ball_x_velocity_lo], a
    ret

byte_array_100B:
    db $06,$08,$0A,$06,$08,$0A,$08,$0A,$0A,$0C,$0E,$0A,$0C,$0E,$0A,$0C

; calculates where the ball should spawn relative to the paddle's collision center and its x velocity

ball_spawn_handler:
    xor a
    ldh [h_ball_y_subpixel], a
    ldh [h_ball_x_subpixel], a

    ld a, $3
    ldh [h_ball_velocity], a

    ldh a, [h_ball_phase_through]
    cp $0
    jr nz, .set_ball_velocity_7

    ldh a, [h_active_brick_count_hi]
    cp $0
    jr nz, .read_paddle_center_x

    ldh a, [h_active_brick_count_lo]
    cp $28
    jr nc, .read_paddle_center_x

.set_ball_velocity_7
    ld a, $7
    ldh [h_ball_velocity], a

.read_paddle_center_x
    ld a, $18
    ld b, a

    ldh a, [h_paddle_collision_width]
    srl a
    ld c, a

    ldh a, [h_paddle_x]
    add c
    cp $48  ; = center of play area
    jr c, .init_ball_coordinate_and_velocity

; IF PADDLE RIGHT OF CENTER PLAY AREA:
    ld a, $E8
    ld b, a

.init_ball_coordinate_and_velocity 
    ldh a, [h_paddle_x]
    add b           ; right: +$18, left: +$E8                    
    add c
    ldh [h_ball_x], a 
    ldh [h_ball_x_mirror], a 

    ld a, $8C
    sub $18     ; A = $74
    ldh [h_ball_y], a 
    ldh [h_ball_y_mirror], a

    ld a, b

    push af

    ld b, $0
    ld c, $0
    ld hl, BALL_VELOCITY_PTR_TABLE_START
    add hl, bc

    ld a, [hl+] ; =>ball_velocity_ptr_table
    ld c, a
    ld a, [hl]  ; =>ball_velocity_ptr_table[1]
    ld b, a     ; BC = 1220

    ld a, $9
    sla a
    sla a
    ld h, $0
    ld l, a     ; A = $24 (36)
    add hl, bc

    ld a, [hl+] ; =>ball_angle_speed_table[36]
    ldh [h_ball_y_velocity_hi], a
    ld a, [hl+] ; =>ball_angle_speed_table[37]
    ldh [h_ball_y_velocity_lo], a

    ld a, [hl+] ; =>ball_angle_speed_table[38]
    ld b, a
    ld a, [hl+] ; =>ball_angle_speed_table[39]
    ld c, a

    pop af

    cp $80
    jr nc, .set_ball_x_velocity

    call negate_bc

.set_ball_x_velocity
    ld a, b
    ldh [h_ball_x_velocity_hi], a

    ld a, c
    ldh [h_ball_x_velocity_lo], a

    ret

SECTION "Ball Data", ROM0[$11EE]

; -----------------------------------
; 25 16-bit addresses, little endian               
; -----------------------------------
; [4]     ball_velocity = 3      
; [8]     ball_velocity = 5      
; [12]    ball_velocity = 7      
; -----------------------------------

ball_velocity_ptr_table:
    db $20,$12
    db $6C,$12
    db $B8,$12
    db $04,$13
    db $50,$13
    db $9C,$13
    db $E8,$13
    db $34,$14
    db $80,$14
    db $CC,$14
    db $18,$15
    db $64,$15
    db $B0,$15
    db $FC,$15
    db $48,$16
    db $94,$16
    db $E0,$16
    db $2C,$17
    db $78,$17
    db $C4,$17
    db $10,$18
    db $5C,$18
    db $A8,$18
    db $F4,$18
    db $40,$19

; -----------------------------------
; 25 blocks × 19 angles × 4 bytes
; -----------------------------------
; block index = speed tier (ball_velocity)         
; entry index = launch angle (0=horizontal, 18=vertical, 9=45°)
; each entry: Y_velocity_hi, Y_velocity_lo, X_velocity_hi, X_velocity_lo
; ----------------------------------- 
; only blocks 1-3 accessed (ball_velocity 3, 5, 7) 
; blocks 4-24 ($1350-$1988) are never accessed     
; ~1672 bytes of unused ROM      
; -----------------------------------

ball_angle_speed_table:
; ball velocity 3
    db $00,$00,$01,$00
    db $00,$16,$00,$FF
    db $00,$2C,$00,$FC
    db $00,$42,$00,$F7
    db $00,$58,$00,$F1
    db $00,$6C,$00,$E8
    db $00,$80,$00,$DE
    db $00,$93,$00,$D2
    db $00,$A5,$00,$C4
    db $00,$B5,$00,$B5
    db $00,$C4,$00,$A5
    db $00,$D2,$00,$93
    db $00,$DE,$00,$80
    db $00,$E8,$00,$6C
    db $00,$F1,$00,$58
    db $00,$F7,$00,$42
    db $00,$FC,$00,$2C
    db $00,$FF,$00,$16
    db $01,$00,$00,$00

; ball velocity 5
    db $00,$00,$01,$20
    db $00,$19,$01,$1F
    db $00,$32,$01,$1C
    db $00,$4B,$01,$16
    db $00,$63,$01,$0F
    db $00,$7A,$01,$05
    db $00,$90,$00,$F9
    db $00,$A5,$00,$EC
    db $00,$B9,$00,$DD
    db $00,$CC,$00,$CC
    db $00,$DD,$00,$B9
    db $00,$EC,$00,$A5
    db $00,$F9,$00,$90
    db $01,$05,$00,$7A
    db $01,$0F,$00,$63
    db $01,$16,$00,$4B
    db $01,$1C,$00,$32
    db $01,$1F,$00,$19
    db $01,$20,$00,$00

; ball velocity 7
    db $00,$00,$01,$40
    db $00,$1C,$01,$3F
    db $00,$38,$01,$3B
    db $00,$53,$01,$35
    db $00,$6D,$01,$2D
    db $00,$87,$01,$22
    db $00,$A0,$01,$15
    db $00,$B8,$01,$06
    db $00,$CE,$00,$F5
    db $00,$E2,$00,$E2
    db $00,$F5,$00,$CE
    db $01,$06,$00,$B8
    db $01,$15,$00,$A0
    db $01,$22,$00,$87
    db $01,$2D,$00,$6D
    db $01,$35,$00,$53
    db $01,$3B,$00,$38
    db $01,$3F,$00,$1C
    db $01,$40,$00,$00
    
    db $00,$00,$01,$60,$00,$1F,$01,$5F,$00,$3D,$01,$5B,$00,$5B,$01,$54,$00,$78,$01,$4B,$00,$95,$01,$3F,$00,$B0,$01,$31,$00,$CA,$01,$20,$00,$E2,$01,$0E,$00,$F9,$00,$F9,$01,$0E,$00,$E2,$01,$20,$00,$CA,$01,$31,$00,$B0,$01,$3F,$00,$95,$01,$4B,$00,$78,$01,$54,$00,$5B,$01,$5B,$00,$3D,$01,$5F,$00,$1F,$01,$60,$00,$00,$00,$00,$01,$80,$00,$21,$01,$7F,$00,$43,$01,$7A,$00,$63,$01,$73,$00,$83,$01,$69,$00,$A2,$01,$5C,$00,$C0,$01,$4D,$00,$DC,$01,$3B,$00,$F7,$01,$26,$01,$10,$01,$10,$01,$26,$00,$F7,$01,$3B,$00,$DC,$01,$4D,$00,$C0,$01,$5C,$00,$A2,$01,$69,$00,$83,$01,$73,$00,$63,$01,$7A,$00,$43,$01,$7F,$00,$21,$01,$80,$00,$00,$00,$00,$01,$A0,$00,$24,$01,$9E,$00,$48,$01,$9A,$00,$6C,$01,$92,$00,$8E,$01,$87,$00,$B0,$01,$79,$00,$D0,$01,$68,$00,$EF,$01,$55,$01,$0B,$01,$3F,$01,$26,$01,$26,$01,$3F,$01,$0B,$01,$55,$00,$EF,$01,$68,$00,$D0,$01,$79,$00,$B0,$01,$87,$00,$8E,$01,$92,$00,$6C,$01,$9A,$00,$48,$01,$9E,$00,$24,$01,$A0,$00,$00,$00,$00,$01,$C0,$00,$27,$01,$BE,$00,$4E,$01,$B9,$00,$74,$01,$B1,$00,$99,$01,$A5,$00,$BD,$01,$96,$00,$E0,$01,$84,$01,$01,$01,$6F,$01,$20,$01,$57,$01,$3D,$01,$3D,$01,$57,$01,$20,$01,$6F,$01,$01,$01,$84,$00,$E0,$01,$96,$00,$BD,$01,$A5,$00,$99,$01,$B1,$00,$74,$01,$B9,$00,$4E,$01,$BE,$00,$27,$01,$C0,$00,$00,$00,$00,$01,$E0,$00,$2A,$01,$DE,$00,$53,$01,$D9,$00,$7C,$01,$D0,$00,$A4,$01,$C3,$00,$CB,$01,$B3,$00,$F0,$01,$A0,$01,$13,$01,$89,$01,$35,$01,$70,$01,$53,$01,$53,$01,$70,$01,$35,$01,$89,$01,$13,$01,$A0,$00,$F0,$01,$B3,$00,$CB,$01,$C3,$00,$A4,$01,$D0,$00,$7C,$01,$D9,$00,$53,$01,$DE,$00,$2A,$01,$E0,$00,$00,$00,$00,$02,$00,$00,$2D,$01,$FE,$00,$59,$01,$F8,$00,$85,$01,$EF,$00,$AF,$01,$E1,$00,$D8,$01,$D0,$01,$00,$01,$BB,$01,$26,$01,$A3,$01,$49,$01,$88,$01,$6A,$01,$6A,$01,$88,$01,$49,$01,$A3,$01,$26,$01,$BB,$01,$00,$01,$D0,$00,$D8,$01,$E1,$00,$AF,$01,$EF,$00,$85,$01,$F8,$00,$59,$01,$FE,$00,$2D,$02,$00,$00,$00,$00,$00,$02,$20,$00,$2F,$02,$1E,$00,$5E,$02,$18,$00,$8D,$02,$0D,$00,$BA,$01,$FF,$00,$E6,$01,$ED,$01,$10,$01,$D7,$01,$38,$01,$BE,$01,$5E,$01,$A1,$01,$81,$01,$81,$01,$A1,$01,$5E,$01,$BE,$01,$38,$01,$D7,$01,$10,$01,$ED,$00,$E6,$01,$FF,$00,$BA,$02,$0D,$00,$8D,$02,$18,$00,$5E,$02,$1E,$00,$2F,$02,$20,$00,$00,$00,$00,$02,$40,$00,$32,$02,$3E,$00,$64,$02,$37,$00,$95,$02,$2C,$00,$C5,$02,$1D,$00,$F3,$02,$0A,$01,$20,$01,$F3,$01,$4A,$01,$D8,$01,$72,$01,$B9,$01,$97,$01,$97,$01,$B9,$01,$72,$01,$D8,$01,$4A,$01,$F3,$01,$20,$02,$0A,$00,$F3,$02,$1D,$00,$C5,$02,$2C,$00,$95,$02,$37,$00,$64,$02,$3E,$00,$32,$02,$40,$00,$00,$00,$00,$02,$60,$00,$35,$02,$5E,$00,$6A,$02,$57,$00,$9D,$02,$4B,$00,$D0,$02,$3B,$01,$01,$02,$27,$01,$30,$02,$0F,$01,$5D,$01,$F2,$01,$87,$01,$D2,$01,$AE,$01,$AE,$01,$D2,$01,$87,$01,$F2,$01,$5D,$02,$0F,$01,$30,$02,$27,$01,$01,$02,$3B,$00,$D0,$02,$4B,$00,$9D,$02,$57,$00,$6A,$02,$5E,$00,$35,$02,$60,$00,$00,$00,$00,$02,$80,$00,$38,$02,$7E,$00,$6F,$02,$76,$00,$A6,$02,$6A,$00,$DB,$02,$59,$01,$0E,$02,$44,$01,$40,$02,$2A,$01,$6F,$02,$0C,$01,$9B,$01,$EA,$01,$C5,$01,$C5,$01,$EA,$01,$9B,$02,$0C,$01,$6F,$02,$2A,$01,$40,$02,$44,$01,$0E,$02,$59,$00,$DB,$02,$6A,$00,$A6,$02,$76,$00,$6F,$02,$7E,$00,$38,$02,$80,$00,$00,$00,$00,$02,$A0,$00,$3B,$02,$9D,$00,$75,$02,$96,$00,$AE,$02,$89,$00,$E6,$02,$77,$01,$1C,$02,$61,$01,$50,$02,$46,$01,$81,$02,$26,$01,$B0,$02,$03,$01,$DB,$01,$DB,$02,$03,$01,$B0,$02,$26,$01,$81,$02,$46,$01,$50,$02,$61,$01,$1C,$02,$77,$00,$E6,$02,$89,$00,$AE,$02,$96,$00,$75,$02,$9D,$00,$3B,$02,$A0,$00,$00,$00,$00,$02,$C0,$00,$3D,$02,$BD,$00,$7A,$02,$B5,$00,$B6,$02,$A8,$00,$F1,$02,$96,$01,$2A,$02,$7E,$01,$60,$02,$62,$01,$94,$02,$41,$01,$C5,$02,$1B,$01,$F2,$01,$F2,$02,$1B,$01,$C5,$02,$41,$01,$94,$02,$62,$01,$60,$02,$7E,$01,$2A,$02,$96,$00,$F1,$02,$A8,$00,$B6,$02,$B5,$00,$7A,$02,$BD,$00,$3D,$02,$C0,$00,$00,$00,$00,$02,$E0,$00,$40,$02,$DD,$00,$80,$02,$D5,$00,$BE,$02,$C7,$00,$FC,$02,$B4,$01,$37,$02,$9B,$01,$70,$02,$7D,$01,$A6,$02,$5B,$01,$D9,$02,$34,$02,$08,$02,$08,$02,$34,$01,$D9,$02,$5B,$01,$A6,$02,$7D,$01,$70,$02,$9B,$01,$37,$02,$B4,$00,$FC,$02,$C7,$00,$BE,$02,$D5,$00,$80,$02,$DD,$00,$40,$02,$E0,$00,$00,$00,$00,$03,$00,$00,$43,$02,$FD,$00,$85,$02,$F4,$00,$C7,$02,$E6,$01,$07,$02,$D2,$01,$45,$02,$B8,$01,$80,$02,$99,$01,$B9,$02,$75,$01,$EE,$02,$4C,$02,$1F,$02,$1F,$02,$4C,$01,$EE,$02,$75,$01,$B9,$02,$99,$01,$80,$02,$B8,$01,$45,$02,$D2,$01,$07,$02,$E6,$00,$C7,$02,$F4,$00,$85,$02,$FD,$00,$43,$03,$00,$00,$00,$00,$00,$03,$20,$00,$46,$03,$1D,$00,$8B,$03,$14,$00,$CF,$03,$05,$01,$12,$02,$F0,$01,$52,$02,$D5,$01,$90,$02,$B5,$01,$CB,$02,$8F,$02,$02,$02,$65,$02,$36,$02,$36,$02,$65,$02,$02,$02,$8F,$01,$CB,$02,$B5,$01,$90,$02,$D5,$01,$52,$02,$F0,$01,$12,$03,$05,$00,$CF,$03,$14,$00,$8B,$03,$1D,$00,$46,$03,$20,$00,$00,$00,$00,$03,$40,$00,$49,$03,$3D,$00,$90,$03,$33,$00,$D7,$03,$24,$01,$1D,$03,$0E,$01,$60,$02,$F2,$01,$A0,$02,$D1,$01,$DD,$02,$AA,$02,$17,$02,$7D,$02,$4C,$02,$4C,$02,$7D,$02,$17,$02,$AA,$01,$DD,$02,$D1,$01,$A0,$02,$F2,$01,$60,$03,$0E,$01,$1D,$03,$24,$00,$D7,$03,$33,$00,$90,$03,$3D,$00,$49,$03,$40,$00,$00,$00,$00,$03,$60,$00,$4B,$03,$5D,$00,$96,$03,$53,$00,$E0,$03,$43,$01,$28,$03,$2C,$01,$6D,$03,$0F,$01,$B0,$02,$EC,$01,$F0,$02,$C4,$02,$2B,$02,$96,$02,$63,$02,$63,$02,$96,$02,$2B,$02,$C4,$01,$F0,$02,$EC,$01,$B0,$03,$0F,$01,$6D,$03,$2C,$01,$28,$03,$43,$00,$E0,$03,$53,$00,$96,$03,$5D,$00,$4B,$03,$60,$00,$00,$00,$00,$03,$80,$00,$4E,$03,$7D,$00,$9C,$03,$72,$00,$E8,$03,$61,$01,$32,$03,$4A,$01,$7B,$03,$2C,$01,$C0,$03,$08,$02,$02,$02,$DE,$02,$40,$02,$AE,$02,$7A,$02,$7A,$02,$AE,$02,$40,$02,$DE,$02,$02,$03,$08,$01,$C0,$03,$2C,$01,$7B,$03,$4A,$01,$32,$03,$61,$00,$E8,$03,$72,$00,$9C,$03,$7D,$00,$4E,$03,$80,$00,$00,$00,$00,$03,$A0,$00,$51,$03,$9C,$00,$A1,$03,$92,$00,$F0,$03,$80,$01,$3D,$03,$68,$01,$88,$03,$49,$01,$D0,$03,$24,$02,$14,$02,$F8,$02,$55,$02,$C7,$02,$90,$02,$90,$02,$C7,$02,$55,$02,$F8,$02,$14,$03,$24,$01,$D0,$03,$49,$01,$88,$03,$68,$01,$3D,$03,$80,$00,$F0,$03,$92,$00,$A1,$03,$9C,$00,$51,$03,$A0,$00,$00,$00,$00,$03,$C0,$00,$54,$03,$BC,$00,$A7,$03,$B1,$00,$F8,$03,$9F,$01,$48,$03,$86,$01,$96,$03,$66,$01,$E0,$03,$3F,$02,$27,$03,$12,$02,$69,$02,$DF,$02,$A7,$02,$A7,$02,$DF,$02,$69,$03,$12,$02,$27,$03,$3F,$01,$E0,$03,$66,$01,$96,$03,$86,$01,$48,$03,$9F,$00,$F8,$03,$B1,$00,$A7,$03,$BC,$00,$54,$03,$C0,$00,$00,$00,$00,$03,$E0,$00,$56,$03,$DC,$00,$AC,$03,$D1,$01,$01,$03,$BE,$01,$53,$03,$A4,$01,$A3,$03,$83,$01,$F0,$03,$5B,$02,$39,$03,$2D,$02,$7E,$02,$F8,$02,$BD,$02,$BD,$02,$F8,$02,$7E,$03,$2D,$02,$39,$03,$5B,$01,$F0,$03,$83,$01,$A3,$03,$A4,$01,$53,$03,$BE,$01,$01,$03,$D1,$00,$AC,$03,$DC,$00,$56,$03,$E0,$00,$00,$00,$00,$04,$00,$00,$59,$03,$FC,$00,$B2,$03,$F0,$01,$09,$03,$DD,$01,$5E,$03,$C2,$01,$B1,$03,$A0,$02,$00,$03,$77,$02,$4B,$03,$47,$02,$92,$03,$10,$02,$D4,$02,$D4,$03,$10,$02,$92,$03,$47,$02,$4B,$03,$77,$02,$00,$03,$A0,$01,$B1,$03,$C2,$01,$5E,$03,$DD,$01,$09,$03,$F0,$00,$B2,$03,$FC,$00,$59,$04,$00,$00,$00

SECTION "Debug Ball Velocity", ROM0[$4A29]

; loads the current value of the ball's velocity at the upper right corner of the screen

debug_ball_velocity:
    ret

    ; unused code

    ld hl, OAM_DEBUG_BALL_VELOCITY_START

    ld a, $98
    ld [hl+], a ; =>[OAM_DEBUG_BALL_VELOCITY_START + $00], a 
    
    ld a, $10
    ld [hl+], a ; =>[OAM_DEBUG_BALL_VELOCITY_START + $01], a  

    ldh a, [h_ball_velocity]     
    add $80
    ld [hl+], a ; =>[OAM_DEBUG_BALL_VELOCITY_START + $02], a  

    ld a, $0
    ld [hl+], a ; =>[OAM_DEBUG_BALL_VELOCITY_START + $03], a  

    ret

SECTION "Ball OOB", ROM0[$63E0]

set_ball_oob:
    ld a, $1
    jr .nop_jr ; nop jump, possibly leftover from development

.nop_jr  
    ld [w_ball_oob], a ; $1 = when ball is lost
    ret