DEF PADDLE_0_ANGLE_STEEPNESS_DATA_START EQU $1B41
DEF PADDLE_1_ANGLE_STEEPNESS_DATA_START EQU $1B51

SECTION "Paddle", ROM0[$109D]

; syncs the collision and sprites of the paddle    

paddle_update:
    call paddle_movement_handler
    call update_paddle_oam_buffer
    ret

; ------------------------------------------------------------------
; paddle_movement_handler
; ------------------------------------------------------------------
; manages the movement and collision of the paddle,
; taking into account its size and collision against the walls
; B is the speed modifier of the paddle:
; - slow (+1):	    B only		
; - normal (+3):	N/A
; - fast (+5):	    A (even if A + B)
; (there's also code that executes based on serial_sample_curr,
; but in emulators, it's always set to $FF, so it never executes)
; ------------------------------------------------------------------

paddle_movement_handler:
    ldh a, [h_serial_sample_curr]           
    cp $F1
    jr c, .update_serial_sample

    ld b, $5    ; A pressed: fast
    ldh a, [h_button_pressed_neg]           
    rrca
    jr nc, .check_l_and_r

    ld b, $1    ; B pressed: slow
    rrca
    jr nc, .check_l_and_r

    ld b, $3    ; N/A: normal

.check_l_and_r
    ldh a, [h_button_pressed_neg]           
    xor $FF
    and $30 ; if L+R, LAB_0df3 -> don't move
    ret z

    and $20
    jr z, .move_paddle_right

.move_paddle_left
    ldh a, [h_paddle_x]    
    sub b
    cp 15   ; left wall
    jr nc, .update_paddle_x

    ld a, 15    ; IF PADDLE is touching left wall
    jr .update_paddle_x

.move_paddle_right
    ldh a, [h_paddle_collision_width]   ; $10 or $18
    ld c, a
    ld a, $7F   ; right wall of play area
    sub c       ; take into account the size of the paddle
    ld c, a

    ldh a, [h_paddle_x]    
    add b   ; +$1, +$3 or +$5
    cp c
    jr c, .update_paddle_x

    ld a, c

.update_paddle_x
    ldh [h_paddle_x], a  
    ret

; not emulated

.update_serial_sample 
    ldh a, [h_paddle_collision_width]      
    ld b, a
    ld a, $7F
    sub b       ; $7F - $10 or $7F - $18
    ld b, a     ; B = $6F or $67

    ldh a, [h_serial_sample_curr]           
    sub $30
    jr c, set_paddle_x_15

; Bounds clamp: ensures paddle stays within
; [$0F, $7F - paddle_collision_width].
; Called as a utility from paddle movement code.

clamp_paddle_x:
    cp 15   ; a = paddle_x
    jr nc, check_paddle_x_pos

set_paddle_x_15:
    ld a, 15
    jr update_paddle_clamp_x

check_paddle_x_pos:
    cp b    ; b = paddle_collision_width
    jr c, update_paddle_clamp_x
    ld a, b

update_paddle_clamp_x:
    ldh [h_paddle_x], a  
    ret

; shifts paddle 4px left when player dies or demo starts     *
; also set the paddle size to 0  

shift_paddle_left:
    xor a
    ldh [h_paddle_size], a  ; normal paddle

    ld a, 24
    ldh [h_paddle_collision_width], a     

    ldh a, [h_paddle_x]    
    sub $4
    ldh [h_paddle_x], a ; move paddle 4px to the left

    ldh a, [h_paddle_collision_width]      
    ld b, a

    ld a, $80
    sub b
    ld b, a

    ldh a, [h_paddle_x]    
    jr clamp_paddle_x

paddle_collision_handler:
    push af

    ld b, $0
    ldh a, [h_ball_velocity]                
    dec a
    sla a
    ld c, a

    ld hl, BALL_VELOCITY_PTR_TABLE_START
    add hl, bc  ; +4, +8, +12
    ld a, [hl+] ; =>ball_velocity_ptr_table
    ld c, a
    ld a, [hl]  ; =>ball_velocity_ptr_table[1]
    ld b, a

    pop af
    push af ; push/pop does nothing

    ld d, 0
    ld e, a
    ld hl, PADDLE_0_ANGLE_STEEPNESS_DATA_START
    
    ldh a, [h_paddle_size] 
    cp $0
    jr z, .LAB_1135

    ld hl, PADDLE_1_ANGLE_STEEPNESS_DATA_START

.LAB_1135 
    add hl, de  ; where the ball landed on the offsets

    ld a, [hl]  ; =>paddle_1_angle_steepness_data
    sla a
    sla a
    ld h, $0
    ld l, a
    add hl, bc

    ld a, [hl+]
    ld b, a
    ld a, [hl+]
    ld c, a

    call negate_bc

    ld a, b
    ldh [h_ball_y_velocity_hi], a
    ld a, c
    ldh [h_ball_y_velocity_lo], a

    ld a, [hl+]
    ld b, a
    ld a, [hl+]
    ld c, a
    ld d, $8

    ldh a, [h_paddle_size] 
    cp 0
    jr z, .LAB_115a

    ld d, 6

.LAB_115a 
    pop af

    cp d
    jr nc, .LAB_1161

    call negate_bc

.LAB_1161
    ld a, b
    ldh [h_ball_x_velocity_hi], a
    ld a, c
    ldh [h_ball_x_velocity_lo], a

    call update_paddle_hit_counter
    jp set_event_paddle_collision

update_paddle_hit_counter:
    ldh a, [h_paddle_hit_counter]           
    dec a
    ldh [h_paddle_hit_counter], a

    jr nz, paddle_hit_counter_set

    call lcd_y_handler

SECTION "Update Paddle OAM", ROM0[$118F]

update_paddle_oam_buffer:
    ld hl, OAM_PADDLE_START

    ldh a, [h_paddle_size] 
    cp $0
    jr nz, .LAB_11C3

    ; if paddle size normal

    ldh a, [h_init_paddle_y]
    ld [hl+], a    ; OAM_PADDLE_START + $00 (sprite 0: Y)
    ldh a, [h_paddle_x]
    add 1
    ld [hl+], a    ; OAM_PADDLE_START + $01 (sprite 0: X)
    ld a, 0
    ld [hl+], a    ; OAM_PADDLE_START + $02 (tile)
    ld a, 0
    ld [hl+], a    ; OAM_PADDLE_START + $03 (attr)

    ldh a, [h_init_paddle_y]
    ld [hl+], a    ; OAM_PADDLE_START + $04 (sprite 1: Y)
    ldh a, [h_paddle_x]
    add 9
    ld [hl+], a    ; OAM_PADDLE_START + $05 (sprite 1: X)
    ld a, 1
    ld [hl+], a    ; OAM_PADDLE_START + $06 (tile)
    ld a, 0
    ld [hl+], a    ; OAM_PADDLE_START + $07 (attr)

    ldh a, [h_init_paddle_y]
    ld [hl+], a    ; OAM_PADDLE_START + $08 (sprite 2: Y)
    ldh a, [h_paddle_x]
    add 17
    ld [hl+], a    ; OAM_PADDLE_START + $09 (sprite 2: X)
    ld a, 0
    ld [hl+], a    ; OAM_PADDLE_START + $0A (tile)
    ld a, $20
    ld [hl+], a    ; OAM_PADDLE_START + $0B (attr)

    ret

    ; if paddle size small

.LAB_11C3 
    ldh a, [h_init_paddle_y]                
    ld [hl+], a    ; OAM_PADDLE_START + $00 (sprite 0: Y)
    ldh a, [h_paddle_x]    
    add 1
    ld [hl+], a    ; OAM_PADDLE_START + $01 (sprite 0: X) 
    ld a, 0
    ld [hl+], a    ; OAM_PADDLE_START + $02 (tile)
    ld a, 0
    ld [hl+], a    ; OAM_PADDLE_START + $03 (attr)

    ldh a, [h_init_paddle_y]                
    ld [hl+], a    ; OAM_PADDLE_START + $04 (sprite 1: Y)
    ldh a, [h_paddle_x]    
    add 9
    ld [hl+], a    ; OAM_PADDLE_START + $05 (sprite 1: X)
    ld a, 0
    ld [hl+], a    ; OAM_PADDLE_START + $06 (tile)
    ld a, $20
    ld [hl+], a    ; OAM_PADDLE_START + $07 (attr)

    ldh a, [h_init_paddle_y]                
    ld [hl+], a    ; OAM_PADDLE_START + $08 (sprite 2: Y)
    ldh a, [h_paddle_x]    
    add 5
    ld [hl+], a    ; OAM_PADDLE_START + $09 (sprite 2: X)
    ld a, 1
    ld [hl+], a    ; OAM_PADDLE_START + $0A (tile)
    ld a, 0
    ld [hl+], a    ; OAM_PADDLE_START + $0B (attr)

    ret

SECTION "Paddle Angle Steepness", ROM0[$1B41]

paddle_0_angle_steepness_data:
    db $03,$06,$06,$06
    db $09,$09,$09,$09
    db $09,$09,$09,$09
    db $06,$06,$06,$03

paddle_1_angle_steepness_data:
    db $03,$06,$06,$09
    db $09,$09,$09,$09
    db $09,$06,$06,$03

SECTION "Paddle Hit Max Value Table", ROM0[$1B7D]

; data containing each amount of paddle hits before the b... *
; for each scrolldown, the amount of paddle hits is decre... *
; after 10 times, the value is just set to 1 -> bricks sc... *

paddle_hit_max_value_table:
    db $08,$08,$05,$05,$03,$03,$02,$02,$02,$02