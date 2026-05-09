DEF BRICK_DATA_TABLE_START  EQU $1B87

DEF PADDLE_HIT_MAX_VALUE_TABLE_START    EQU $1B7D

DEF TILE_MAP_0  EQU $9800

DEF BRICK_TYPE_BUFFER_START EQU $C000
DEF W_SCROLL_X_TABLE_START  EQU $CA00

SECTION "Load Level Brick Data", ROM0[$092A]

; Loads the level's brick layout from a ROM pointer table into WRAM
; (BRICK_TYPE_BUFFER_START = brick types, w_object_state_array = hit states).
; It also calculates h_total_row_count and
; lcd_y_descent_counter (rows that are off-screen above).

load_level_brick_data:
    ld b, a
    ld e, $3
    call multiply
    ld hl, STAGE_PROPERTIES_TABLE_START
    add hl, bc
    inc hl
    ld e, [hl]
    inc hl
    ld d, [hl]
    push de
    call clear_objects_wram0
    call bricks_slide_in_from_top
    pop de
    ld hl, BRICK_TYPE_BUFFER_START
    ld b, $0

.load_counter
    ld c, $E    ; counter = 14

.Lab_0947
    push bc
    push de
    push hl
    ld a, [de]
    ld [hl], a   ; [hl] ; hl=>BYTE_C000
    cp $0
    jr z, .Lab_096a
    push hl
    dec a
    ld b, a
    ld e, $6
    call multiply
    ld hl, BRICK_DATA_TABLE_START
    add hl, bc
    ld b, $0
    ld c, $3
    add hl, bc
    ld a, [hl]  ; [hl]  ; =>brick_data_table[0][3])
    and $F
    pop hl
    ld bc, $400
    add hl, bc
    ld [hl], a  ; [hl]  ; =>w_object_state_array

.Lab_096a
    pop hl
    pop de
    pop bc
    inc hl  ; BYTE_C001
    inc de
    dec c
    jr nz, .Lab_0947
    inc b
    ld a, [de]
    cp $FF
    jr nz, .load_counter
    ld a, b
    ldh [h_total_row_count], a   
    sub $14
    jr nc, .update_descent_counter
    xor a

.update_descent_counter 
    ldh [h_lcd_y_descent_counter], a
    ret

SECTION "Brick Count", ROM0[$09BB]

bricks_slide_in_from_top:
    ld a, $3A
    ldh [h_play_area_scroll_y], a

.Lab_09bf
    call brick_collision_handler
    call wait_vblank
    ldh a, [h_play_area_scroll_y]     
    cp $0
    ret z
    dec a
    dec a
    ldh [h_play_area_scroll_y], a
    jr .Lab_09bf

; sets initial brick count at load time only
; h_active_brick_count_hi and h_active_brick_count_lo
; updated during gameplay by load_next_brick_line_obj
; and get_brick_at_pixel_pos

count_level_bricks:
    ld hl, BRICK_TYPE_BUFFER_START    
    ld de, $0
    ld bc, $348

.Lab_09d9  
    push bc
    push hl
    ld a, [hl]  ; [hl]  ; hl=>BYTE_C000       
    cp $0
    jr z, .Lab_09ea
    ld bc, $400
    add hl, bc
    ld a, [hl]  ; [hl]  ; =>w_object_state_array
    cp $0
    jr z, .Lab_09ea
    inc de

.Lab_09ea
    pop hl
    inc hl  ; =>BYTE_c001           
    pop bc
    dec bc
    ld a, b
    or c
    jr nz, .Lab_09d9
    ld a, d
    ldh [h_active_brick_count_hi], a
    ld a, e
    ldh [h_active_brick_count_lo], a
    ret

; Sets up the OAM buffer entries for a single specific brick
; It writes two OAM entries side by side (the brick's top and
; bottom halves) using $C901 to $C909

setup_single_brick_oam_entry:
    call check_object_dirty_flag
    ldh a, [h_play_area_scroll_y]     
    srl a
    ld b, a
    ld e, $20
    call multiply
    ldh a, [h_brick_probe_x]          
    ld l, a
    ld h, $0
    add hl, bc
    ld a, h
    ldh [h_brick_tilemap_offset_hi], a                     
    ld a, l
    ldh [h_brick_tilemap_offset_lo], a                     
    ldh a, [h_play_area_scroll_y]     
    srl a
    ld b, a
    ld e, $1C
    call multiply
    ldh a, [h_brick_probe_x]          
    ld l, a
    ld h, $0
    add hl, bc
    ld a, $FF
    ldh [h_brick_type_last_hit], a  
    xor a
    push af
    ld bc, BRICK_TYPE_BUFFER_START
    add hl, bc
    ld a, [hl]  ; [hl]  ; =>BYTE_C000)   
    cp $0
    jr z, .Lab_0a37
    ldh [h_brick_type_last_hit], a  
    pop af
    or $1
    push af

.Lab_0a37
    ld b, $0
    ld c, $E
    add hl, bc
    ld a, [hl]  ; [hl]  ; =>BYTE_c00e)       
    cp $0
    jr z, .Lab_0a47
    ldh [h_brick_type_last_hit], a  
    pop af
    or $2
    push af

.Lab_0a47 
    pop af
    cp $0
    jp z, .Lab_0a64
    dec a
    push af
    ldh a, [h_brick_type_last_hit]    
    dec a
    ld b, a
    ld e, $6
    call multiply
    ld hl, BRICK_DATA_TABLE_START
    add hl, bc
    pop af
    ld b, $0
    ld c, a
    add hl, bc
    ld a, [hl]
    ldh [h_brick_type_last_hit], a  

.Lab_0a64   
    ldh a, [h_brick_tilemap_offset_hi]
    ld b, a
    ldh a, [h_brick_tilemap_offset_lo]
    ld c, a
    ld hl, $9821
    add hl, bc
    ld b, h
    ld c, l
    push bc
    ld b, $0
    ld c, $E
    add hl, bc
    ld b, h
    ld c, l
    ld hl, $C901    ; [hl] = w_tile_buffer
    ld a, b
    ld [hl+], a     ; w_tile_buffer + $00, a    
    ld a, c
    ld [hl+], a     ; w_tile_buffer + $01, a    
    ld a, $1
    ld [hl+], a     ; w_tile_buffer + $02, a    
    ldh a, [h_brick_type_last_hit]    
    ld [hl+], a     ; w_tile_buffer + $03, a    
    pop bc
    ld a, b
    ld [hl+], a     ; w_tile_buffer + $04, a    
    ld a, c
    ld [hl+], a     ; w_tile_buffer + $05, a    
    ld a, $1
    ld [hl+], a     ; w_tile_buffer + $06, a    
    ldh a, [h_brick_type_last_hit]    
    ld [hl+], a     ; w_tile_buffer + $07, a    
    xor a
    ld [hl+], a     ; w_tile_buffer + $08, a    
    inc a
    ldh [h_object_dirty_flag], a 
    ret

SECTION "Brick Collision", ROM0[$0A96]

brick_collision_handler:
    call check_object_dirty_flag
    ldh a, [h_play_area_scroll_y]     
    srl a
    ld b, a
    ld e, $20
    call multiply
    ld hl, $9821    ; MAGIC NUMBER
    add hl, bc
    ld b, h
    ld c, l
    ld hl, $C901    ; [hl] = w_tile_buffer
    ld a, b
    ld [hl+], a     ; w_tile_buffer + $00, a    
    ld a, c
    ld [hl+], a     ; w_tile_buffer + $01, a    
    ld a, $1C
    ld [hl], a      ; w_tile_buffer + $02, a     
    ldh a, [h_play_area_scroll_y]     
    srl a
    ld b, a
    ld e, $1C
    call multiply
    ld hl, BRICK_TYPE_BUFFER_START
    add hl, bc
    ld de, $C904
    ld a, $E

.Lab_0ac6
    push af
    push hl
    push de
    ld a, $FF
    ldh [h_brick_type_last_hit], a  
    xor a
    push af
    ld a, [hl]  ; hl=>BYTE_C000       
    cp $0
    jr z, .Lab_0ada
    ldh [h_brick_type_last_hit], a  
    pop af
    or $1
    push af

.Lab_0ada
    ld b, $0
    ld c, $E
    add hl, bc
    ld a, [hl]  ; =>BYTE_c00e       
    cp $0
    jr z, .Lab_0aea
    ldh [h_brick_type_last_hit], a  
    pop af
    or $2
    push af

.Lab_0aea
    pop af
    cp $0
    jp z, .Lab_0b07
    dec a
    push af
    ldh a, [h_brick_type_last_hit]    
    dec a
    ld b, a
    ld e, $6
    call multiply
    ld hl, BRICK_DATA_TABLE_START
    add hl, bc
    pop af
    ld b, $0
    ld c, a
    add hl, bc
    ld a, [hl]
    ldh [h_brick_type_last_hit], a  

.Lab_0b07
    pop de
    ldh a, [h_brick_type_last_hit]    
    ld [de], a ; =>BYTE_c904), a     
    ld b, d
    ld c, e
    ld hl, $E
    add hl, bc
    ld [hl+], a    ; =>BYTE_c912, a    
    ld b, h
    ld c, l
    inc de
    pop hl
    inc hl
    pop af
    dec a
    jr nz, .Lab_0ac6
    xor a
    ld [bc], a  ; (bc=>BYTE_c913), a     
    inc a
    ldh [h_object_dirty_flag], a 
    ret

; SECTION "Scroll X", ROM0[$0B21]

; executed each frame during gameplay, even when the level doesn't scroll

scroll_x_handler:
    ldh a, [h_scrolling_x_stage_flag] 
    cp $0
    ret z

    ld hl, W_SCROLL_X_TABLE_START
    ld de, $CA14    ; MAGIC NUMBER
    ld bc, $CA28    ; MAGIC NUMBER
    ld a, $0

.update_scroll_x_timer
    push af
    ld a, [bc]  ; =>w_level_scroll_x_timer
    dec a

.Lab_0b34
    jr nz, .load_next_scroll_x_data
    ld a, [de]  ; =>w_level_scroll_x_max_timer        
    cp $0
    jr z, .load_next_scroll_x_data
    and $80
    push af
    call z, scroll_x_advance
    pop af
    call nz, scroll_x_recede
    ld a, [de]  ; =>w_level_scroll_x_max_timer        
    and $7F

.load_next_scroll_x_data
    ld [bc], a  ; =>w_level_scroll_x_timer, a  
    inc hl
    inc de
    inc bc
    pop af
    inc a
    cp $14
    jr c, .update_scroll_x_timer
    ret

; Increments the current row's scroll X value, wrapping at $6F back to 0.

scroll_x_advance:
    ld a, [hl]
    inc a
    cp $70
    jr c, .Lab_0b5b

    ld a, $0

.Lab_0b5b
    ld [hl], a
    ret

; Mirror of above: decrements, wrapping $FF -> $6F
; This is a safeguard put in place in case the scroll x value goes above 6F.

scroll_x_recede:
    ld a, [hl]
    dec a
    cp $FF  ; failsafe
    jr nz, .Lab_0b65
    
    ld a, $6F

.Lab_0b65
    ld [hl], a
    ret

SECTION "Init Scroll X", ROM0[$0B9D]

; on level load, sets up the origin of the 20 4px scrollables rows all at x = 0

init_scroll_x_table:
    ld a, $0
    ldh [h_lcdc_negative], a    

    ld hl, W_SCROLL_X_TABLE_START
    ld b, 20   ; counter

.copy_next_row_origin
    ld [hl+], a ; => [w_scroll_x_table] set the bg origin
    dec b
    jr nz, .copy_next_row_origin

    xor a
    ldh [h_debug_scroll_x_init], a  

SECTION "Load Next Brick Line", ROM0[$0BF2]

load_next_brick_line_obj:
    ldh a, [h_lcd_y_descent_counter] ; the counter is decremented before being loaded here
    add $14
    ld b, a
    ld e, 15
    call multiply

    ld hl, BRICK_TYPE_BUFFER_START
    add hl, bc
    ld a, 14    ; = 14 (counter), so 14 bricks in a line

.check_brick_presence
    push af
    push hl

    ld a, [hl]  ; hl=>BYTE_C000       
    cp $0
    jr z, .decrement_loop_counter

.update_brick_obj_state
    ld d,h
    ld e,l

    ld bc, $400
    add hl, bc

    ld a, [hl]  ; [hl]  ; =>w_object_state_array
    cp $0
    ld a, $0
    ld [de], a
    jr z, .decrement_loop_counter

.decrement_brick_count
    ldh a, [h_active_brick_count_hi]  
    ld b, a
    ldh a, [h_active_brick_count_lo]  
    ld c, a

    dec bc

    ld a, b
    ldh [h_active_brick_count_hi], a
    ld a, c
    ldh [h_active_brick_count_lo], a

    or b
    jr nz, .decrement_loop_counter

.stage_clear
    ld a, $8
    ldh [h_game_state], a

.decrement_loop_counter 
    pop hl
    inc hl
    pop af

    dec a
    jr nz, .check_brick_presence
    ret

SECTION "Check Brick Collision", ROM0[$0D37]

; Unconditionally probes both X and Y axes by dispatching
; to the appropriate directional collision checks based on
; current velocity signs. Called before a confirmed collision.

check_brick_collision_both_axes:
    ldh a, [h_ball_x_velocity_hi]     
    and $80

    push af
    call z, check_brick_collision_x_leading_right
    pop af

    call nz, check_brick_collision_x_leading_left

    ldh a, [h_ball_y_velocity_hi]     
    and $80

    push af
    call z, check_brick_collision_y_leading_down
    pop af

    call nz, check_brick_collision_y_leading_up

    ret

; On hit: aligns to tile boundary, negates Y velocity.

check_brick_collision_y_leading_down:
    ldh a, [h_ball_y]
    add $3
    ldh [h_prev_ball_y], a 

    ldh a, [h_ball_x_mirror]
    ldh [h_prev_ball_x], a

    call get_brick_at_pixel_pos

    cp $0
    jp nz, reverse_ball_y_velocity

    ldh a, [h_ball_y]
    ldh [h_prev_ball_y], a 

    ldh a, [h_ball_x_mirror]
    ldh [h_prev_ball_x], a
    call get_brick_at_pixel_pos

    cp $0
    ret z

    jp LAB_0ecd    ; to ret instruction
; ret whether Z = 0 or not

; mirror of check_brick_collision_y_leading_down       

check_brick_collision_y_leading_up:
    ldh a, [h_ball_y]
    ldh [h_prev_ball_y], a 

    ldh a, [h_ball_x_mirror]
    ldh [h_prev_ball_x], a

    call get_brick_at_pixel_pos

    cp $0
    jp nz, reverse_ball_y_velocity

    ldh a, [h_ball_y]
    add $3
    ldh [h_prev_ball_y], a 

    ldh a, [h_ball_x_mirror]
    ldh [h_prev_ball_x], a

    call get_brick_at_pixel_pos

    cp $0
    ret z

    jp LAB_0ecd    ; to ret instruction

; On hit: aligns to tile boundary, negates X velocity.

check_brick_collision_x_leading_right:
    ldh a, [h_ball_y_mirror]
    ldh [h_prev_ball_y], a

    ldh a, [h_ball_x]
    add $3
    ldh [h_prev_ball_x], a

    call get_brick_at_pixel_pos

    cp $0
    jp nz, reverse_ball_x_velocity

    ldh a, [h_ball_y_mirror]
    ldh [h_prev_ball_y], a

    ldh a, [h_ball_x]
    ldh [h_prev_ball_x], a

    call get_brick_at_pixel_pos

    cp $0
    ret z

    jp align_ball_x_update

; Mirror of check_brick_collision_x_leading_right         

check_brick_collision_x_leading_left:
    ldh a, [h_ball_y_mirror]
    ldh [h_prev_ball_y], a

    ldh a, [h_ball_x]
    ldh [h_prev_ball_x], a

    call get_brick_at_pixel_pos

    cp $0
    jp nz, reverse_ball_x_velocity

    ldh a, [h_ball_y_mirror]
    ldh [h_prev_ball_y], a

    ldh a, [h_ball_x]
    add $3
    ldh [h_prev_ball_x], a

    call get_brick_at_pixel_pos

    cp $0
    ret z

    jp align_ball_x_update

; Change the value of the amount of paddle hits necessary
; to decrease the "brick scrolldown" mechanic uses the data 
; table at $1B7D with the current number of times the ball
; has hit the table as the offset.
; After 10 scrolldowns, each paddle hit lowers the bricks

get_brick_at_pixel_pos:
    ld a, [w_lcd_y]   ; triggered every frame
    sub $0
    ld b, a

    ldh a, [h_prev_ball_y] 
    sub $18
    
    add b
    jr c, .LAB_0df3

    srl a
    srl a
    ldh [h_play_area_scroll_y], a

    cp $3C
    jr c, .LAB_0df6

.LAB_0df3
    ld a, $0
    ret

.LAB_0df6
    ld b, a ; where the ball is vertically
    ldh a, [h_lcd_y_descent_counter]  
    ld c, a
    ld a, b
    sub c

    ld c, a
    ld b, $0
    ld hl, W_SCROLL_X_TABLE_START
    add hl, bc
    ld a, [HL]  ; =>[w_scroll_x_table]

    sub $0
    ld b, a
    ldh a, [h_prev_ball_x] 
    sub $10     ; 16 px left
    add b       ; if the level doesn't scroll x, then B = 0

    cp $70      ; two tiles left from the right wall
    jr c, .LAB_0e12    ; if left of x threshold, jp

    sub $70

.LAB_0e12
    srl a
    srl a   
    srl a   ; (prev_ball_x - 16) / 8
    ldh [h_brick_probe_x], a     

    ldh a, [h_play_area_scroll_y]     
    ld b, a
    ld e, $0E
    call multiply

    ldh a, [h_brick_probe_x]          
    ld l, a
    ld h, $0
    add hl, bc

    ld bc, BRICK_TYPE_BUFFER_START
    add hl, bc
    ld a, [hl]  ; =>BYTE_C000       
    cp $0
    ret z

    ldh [h_brick_type_last_hit], a  

    push hl
    call brick_type_velocity_handler
    pop hl

    ld d, h
    ld e, l
    ld bc, $400
    add hl, bc
    ld a, [hl]  ; =>w_object_state_array
    cp $0
    jr z, unbreakable_brick_handler ; if you collide with an unbreakable brick

    ld b, a
    ldh a, [h_ball_phase_through]     
    cp $0
    jr nz, .bonus_stage_brick_handler

    dec b
    ld [hl], b  ; =>w_object_state_array
    ret nz

.bonus_stage_brick_handler
    xor a
    ld [de], a

    ldh a, [h_brick_type_last_hit]

    call add_brick_score_to_player_score
    call update_score_all
    call extra_life_score_handler
    call update_score_oam_buffer
    call brick_type_handler
    call setup_single_brick_oam_entry

    ldh a, [h_active_brick_count_hi]  
    ld b, a
    ldh a, [h_active_brick_count_lo]  
    ld c, a

    dec bc
    ld a, b
    ldh [h_active_brick_count_hi], a
    ld a, c
    ldh [h_active_brick_count_lo], a

    or b
    jr nz, .check_if_bonus_stage

    ; if no remaining bricks

    ld a, $8
    ldh [h_game_state], a   ; stage clear

.check_if_bonus_stage
    ldh a, [h_ball_phase_through]   ; Ambiguous purpose: this code is only reached if the ball phases through, so the
    cp $0
    jp nz, .LAB_0df3  ; always jump

update_ball_collision_flag:
    ldh a, [h_ball_collision_flag]    
    inc a
    ldh [h_ball_collision_flag], a  

    ld a, $1
    ret

unbreakable_brick_handler:
    call update_unbreakable_brick_collision_counter
    call brick_type_handler
    jr update_ball_collision_flag

SECTION "Brick Type Velocity", ROM0[$0F2F]

; -------------------------------------------------
; brick_type_velocity_handler
; -------------------------------------------------
; On ball collision with any brick, checks the velocity
; data associated with it through the fifth data entry
; in the brick's data at BRICK_DATA_TABLE_START.
; If it's a white or unbreakable brick -> no update
; if it's light/dark grey -> check if the brick would
; increase the velocity of the ball or not. If yes,
; update it. If not, RET.
; -------------------------------------------------

brick_type_velocity_handler:
    ldh a, [h_brick_type_last_hit]    
    dec a
    ld b, a
    ld e, $6
    call multiply   ; BC = brick type hit * 6

    ld hl, BRICK_DATA_TABLE_START
    add hl, bc

    ld b, $0
    ld c, $4
    add hl, bc
    ld a, [hl]  ; =>brick_data_table[0][4]

    cp $0
    ret z

    ld b, a     ; copy new ball velocity
    ldh a, [h_ball_velocity]          
    cp b
    ret nc      ; if it's the same velocity

    ld a, b
    ldh [h_ball_velocity], a     
    jr update_ball_velocity_on_brick_collision
                         
; when the ball hits an unbreakable brick, increase the value of the counter
; if the ball hits an unbreakable brick for the 10th time, reset the value

update_unbreakable_brick_collision_counter:
    ldh a, [h_unbreakable_brick_collision_counter]           
    inc a
    cp $A
    jr c, .LAB_0f5a

    call update_ball_velocity_on_brick_collision
    xor a

.LAB_0f5a
    ldh [h_unbreakable_brick_collision_counter], a         
    ret

SECTION "Update Ball OAM Buffer", ROM0[$108D]

; fetches the ball's XY coordinates and updates the oam data accordingly
; only affects the oam, not the collision data

update_ball_oam_buffer:
    ld hl, OAM_BALL_START

    ldh a, [h_ball_y]
    ld [hl+], a    ; y

    ldh a, [h_ball_x]
    ld [hl+], a    ; x

    ld a, $5
    ld [hl+], a    ; tile ID

    ld a, $0
    ld [hl+], a    ; attr

    ret

SECTION "Brick Scrolldown Threshold", ROM0[$1177]

; Change the value of the amount of paddle hits necessary
; to decrease the "brick scrolldown" mechanic uses the data 
; table at $1B7D with the current number of times the ball
; has hit the table as the offset.
; After 10 scrolldowns, each paddle hit lowers the bricks

update_brick_scrolldown_threshold:
    ldh a, [h_lcd_y_offset_counter]
    cp $A
    jr c, .LAB_1181 ; if lcd_offset_counter < 10

    ld a, $1
    jr paddle_hit_counter_set

.LAB_1181
    ld c, a
    ld b, $0

    inc a
    ldh [h_lcd_y_offset_counter], a 

    ld hl, PADDLE_HIT_MAX_VALUE_TABLE_START
    add hl, bc  ; offset = how many times the bricks have scrolled down
    ld a, [hl]  ; =>paddle_hit_max_value_table

paddle_hit_counter_set:
    ldh [h_paddle_hit_counter], a
    ret

SECTION "Brick Data", ROM0[BRICK_DATA_TABLE_START]

; ---------------------------------------------
; 4 x 6 bytes
; ---------------------------------------------                
; [1] white brick data
;         [1] upper brick tile   
;         [2] lower brick tile   
;         [3] 2 bricks full tile 
;         [4] ? affects points and breakability    
;         [5] velocity modifier  
;         [6] ?                  
; [2] light grey brick data             
; [3] dark grey brick data              
; [4] unbreakable brick data            
; ---------------------------------------------

brick_data_table:
    db $AB,$AE,$A8,$11,$00,$01
    db $AC,$AF,$A9,$21,$05,$02
    db $AD,$B0,$AA,$31,$07,$03
    db $00,$00,$B3,$10,$00,$00

; most likely a safe guard: these 6 byte arrays -- counting the brick data table -- end at 0x0F
; these stages are effectively empty

blank_brick_data_table:
    db $00,$00,$00,$11,$00,$00
    db $00,$00,$00,$11,$00,$00
    db $00,$00,$00,$11,$00,$00
    db $00,$00,$00,$11,$00,$00
    db $00,$00,$00,$11,$00,$00
    db $00,$00,$00,$11,$00,$00
    db $00,$00,$00,$11,$00,$00
    db $00,$00,$00,$11,$00,$00
    db $00,$00,$00,$11,$00,$00
    db $00,$00,$00,$11,$00,$00
    db $00,$00,$00,$11,$00,$00

; -------------------------------------
; 1st parameter: 
;   - low nibble: scroll x properties
;   - high nibble: 
;           a) 1000 = bonus level
;           b) 0100 = scrolling x
;
; 2nd parameter
;   - 16-bit little endian pointer
; -------------------------------------

stage_properties_table:
    db $00,$44,$1C  ; stage 0   = $1C44
    db $40,$44,$1C  ; stage 1   = $1C44
    db $00,$F4,$23  ; stage 2   = $23F4
    db $80,$7C,$35  ; stage 3   = $357C

    db $02,$09,$1D  ; stage 4   = $1D09
    db $41,$09,$1D  ; stage 5   = $1D09
    db $00,$25,$26  ; stage 6   = $2625
    db $80,$95,$36  ; stage 7   = $3695

    db $00,$CE,$1D  ; stage 8   = $1DCE
    db $42,$CE,$1D  ; stage 9   = $1DCE
    db $00,$56,$28  ; stage 10  = $2856
    db $80,$AE,$37  ; stage 11  = $37AE

    db $00,$E7,$1E  ; stage 12  = $1EE7
    db $43,$E7,$1E  ; stage 13  = $1EE7
    db $00,$87,$2A  ; stage 14  = $2A87
    db $80,$C7,$38  ; stage 15  = $38C7

    db $00,$C8,$1F  ; stage 16  = $1FC8
    db $44,$C8,$1F  ; stage 17  = $1FC8
    db $00,$B8,$2C  ; stage 18  = $2CB8
    db $80,$E0,$39  ; stage 19  = $39E0

    db $00,$C5,$20  ; stage 20  = $20C5
    db $45,$C5,$20  ; stage 21  = $20C5
    db $00,$E9,$2E  ; stage 22  = $2EE9
    db $80,$F9,$3A  ; stage 23  = $3AF9

    db $00,$DE,$21  ; stage 24  = $21DE
    db $46,$DE,$21  ; stage 25  = $21DE
    db $00,$1A,$31  ; stage 26  = $311A
    db $80,$12,$3C  ; stage 27  = $3C12

    db $00,$F7,$22  ; stage 28  = $22F7
    db $47,$F7,$22  ; stage 29  = $22F7
    db $00,$4B,$33  ; stage 30  = $334B
    db $80,$2B,$3D  ; stage 31  = $3D2B

    db $00,$44,$1C  ; stage 0 (again)

stage_0_1_brick_data:
    db $04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$00,$00,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$00,$00,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$00,$00,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$00,$00,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$00,$00,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$00,$00,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$FF

stage_4_5_brick_data:
    db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$FF

stage_8_9_brick_data:
    db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$03,$00,$03,$00,$03,$00,$03,$00,$03,$00,$03,$00,$03,$00,$03,$00,$03,$00,$03,$00,$03,$00,$03,$00,$03,$00,$03,$00,$00,$03,$00,$03,$00,$03,$00,$03,$00,$03,$00,$03,$00,$03,$00,$03,$00,$03,$00,$03,$00,$03,$00,$03,$00,$03,$00,$03,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$FF
    
stage_12_13_brick_data:
    db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$03,$03,$03,$03,$04,$03,$03,$03,$03,$04,$03,$03,$03,$03,$03,$03,$03,$03,$04,$03,$03,$03,$03,$04,$03,$03,$03,$03,$00,$00,$00,$00,$04,$00,$00,$00,$00,$04,$00,$00,$00,$00,$00,$00,$00,$00,$04,$00,$00,$00,$00,$04,$00,$00,$00,$00,$02,$02,$02,$02,$04,$02,$02,$02,$02,$04,$02,$02,$02,$02,$02,$02,$02,$02,$04,$02,$02,$02,$02,$04,$02,$02,$02,$02,$00,$00,$00,$00,$04,$00,$00,$00,$00,$04,$00,$00,$00,$00,$00,$00,$00,$00,$04,$00,$00,$00,$00,$04,$00,$00,$00,$00,$01,$01,$01,$01,$04,$01,$01,$01,$01,$04,$01,$01,$01,$01,$01,$01,$01,$01,$04,$01,$01,$01,$01,$04,$01,$01,$01,$01,$01,$01,$01,$01,$04,$01,$01,$01,$01,$04,$01,$01,$01,$01,$00,$00,$00,$00,$04,$00,$00,$00,$00,$04,$00,$00,$00,$00,$FF
    
stage_16_17_brick_data:
    db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$03,$00,$00,$00,$00,$00,$03,$03,$00,$00,$00,$00,$00,$03,$03,$03,$00,$00,$00,$03,$03,$03,$03,$00,$00,$00,$03,$03,$00,$03,$03,$00,$03,$03,$00,$00,$03,$03,$00,$03,$03,$00,$00,$00,$03,$03,$03,$00,$00,$00,$00,$03,$03,$03,$00,$00,$00,$00,$00,$03,$00,$00,$00,$00,$00,$00,$03,$00,$00,$00,$02,$00,$00,$00,$00,$00,$02,$02,$00,$00,$00,$00,$00,$02,$02,$02,$00,$00,$00,$02,$02,$02,$02,$00,$00,$00,$02,$02,$00,$02,$02,$00,$02,$02,$00,$00,$02,$02,$00,$02,$02,$00,$00,$00,$02,$02,$02,$00,$00,$00,$00,$02,$02,$02,$00,$00,$00,$00,$00,$02,$00,$00,$00,$00,$00,$00,$02,$00,$00,$00,$01,$00,$00,$00,$00,$00,$01,$01,$00,$00,$00,$00,$00,$01,$01,$01,$00,$00,$00,$01,$01,$01,$01,$00,$00,$00,$01,$01,$01,$01,$01,$00,$01,$01,$01,$01,$01,$01,$00,$01,$01,$01,$00,$01,$01,$01,$01,$01,$00,$00,$01,$01,$01,$01,$01,$00,$00,$00,$01,$01,$01,$00,$00,$00,$00,$01,$01,$01,$00,$00,$00,$00,$00,$01,$00,$00,$00,$00,$00,$00,$01,$00,$00,$00,$FF
    
stage_20_21_brick_data:
    db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$02,$02,$02,$02,$02,$02,$02,$00,$00,$00,$00,$00,$00,$00,$02,$02,$02,$02,$02,$02,$02,$00,$00,$00,$00,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$00,$00,$00,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$00,$00,$00,$00,$00,$01,$01,$03,$01,$01,$03,$03,$03,$03,$00,$00,$00,$00,$00,$01,$01,$03,$01,$01,$03,$03,$03,$03,$00,$00,$00,$01,$01,$01,$01,$01,$01,$01,$03,$01,$01,$03,$03,$00,$00,$01,$01,$01,$01,$01,$01,$01,$03,$01,$01,$03,$03,$00,$00,$01,$01,$01,$01,$03,$01,$03,$03,$01,$01,$03,$03,$00,$00,$01,$01,$01,$01,$03,$01,$03,$03,$01,$01,$03,$03,$00,$00,$00,$03,$03,$03,$03,$03,$01,$01,$01,$03,$03,$03,$00,$00,$00,$03,$03,$03,$03,$03,$01,$01,$01,$03,$03,$03,$00,$00,$00,$00,$01,$01,$01,$01,$01,$01,$03,$03,$03,$00,$00,$00,$00,$00,$01,$01,$01,$01,$01,$01,$03,$03,$03,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$04,$04,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$04,$04,$04,$04,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$04,$04,$FF
    
stage_24_25_brick_data:
    db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$04,$04,$00,$00,$04,$04,$00,$00,$04,$04,$00,$00,$04,$04,$04,$04,$00,$00,$04,$04,$00,$00,$04,$04,$00,$00,$04,$04,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$FF
    
stage_28_29_brick_data:
    db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$02,$02,$02,$04,$04,$04,$02,$02,$04,$04,$04,$02,$02,$02,$02,$02,$02,$04,$04,$04,$02,$02,$04,$04,$04,$02,$02,$02,$02,$02,$04,$04,$02,$02,$02,$02,$02,$02,$04,$04,$02,$02,$02,$02,$04,$04,$02,$02,$02,$02,$02,$02,$04,$04,$02,$02,$00,$00,$04,$00,$00,$00,$00,$00,$00,$00,$00,$04,$00,$00,$00,$00,$04,$00,$00,$00,$00,$00,$00,$00,$00,$04,$00,$00,$01,$01,$04,$01,$01,$01,$01,$01,$01,$01,$01,$04,$01,$01,$01,$01,$04,$01,$01,$01,$01,$01,$01,$01,$01,$04,$01,$01,$01,$01,$04,$04,$01,$01,$01,$01,$01,$01,$04,$04,$01,$01,$01,$01,$04,$04,$01,$01,$01,$01,$01,$01,$04,$04,$01,$01,$00,$00,$00,$04,$04,$04,$00,$00,$04,$04,$04,$00,$00,$00,$00,$00,$00,$04,$04,$04,$00,$00,$04,$04,$04,$00,$00,$00,$FF
    
stage_2_brick_data:
    db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$00,$00,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$00,$00,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$00,$00,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$00,$00,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$00,$00,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$00,$00,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$FF
    
stage_6_brick_data:
    db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$FF
    
stage_10_brick_data:
    db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$03,$00,$03,$00,$03,$00,$03,$00,$03,$00,$03,$00,$03,$00,$03,$00,$03,$00,$03,$00,$03,$00,$03,$00,$03,$00,$03,$00,$00,$03,$00,$03,$00,$03,$00,$03,$00,$03,$00,$03,$00,$03,$00,$03,$00,$03,$00,$03,$00,$03,$00,$03,$00,$03,$00,$03,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$03,$00,$03,$00,$03,$00,$03,$00,$03,$00,$03,$00,$03,$00,$03,$00,$03,$00,$03,$00,$03,$00,$03,$00,$03,$00,$03,$03,$00,$03,$00,$03,$00,$03,$00,$03,$00,$03,$00,$03,$00,$03,$00,$03,$00,$03,$00,$03,$00,$03,$00,$03,$00,$03,$00,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$FF
    
stage_14_brick_data:
    db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$03,$03,$03,$03,$04,$03,$03,$03,$03,$04,$03,$03,$03,$03,$03,$03,$03,$03,$04,$03,$03,$03,$03,$04,$03,$03,$03,$03,$00,$00,$00,$00,$04,$00,$00,$00,$00,$04,$00,$00,$00,$00,$00,$00,$00,$00,$04,$00,$00,$00,$00,$04,$00,$00,$00,$00,$02,$02,$02,$02,$04,$02,$02,$02,$02,$04,$02,$02,$02,$02,$02,$02,$02,$02,$04,$02,$02,$02,$02,$04,$02,$02,$02,$02,$00,$00,$00,$00,$04,$00,$00,$00,$00,$04,$00,$00,$00,$00,$00,$00,$00,$00,$04,$00,$00,$00,$00,$04,$00,$00,$00,$00,$01,$01,$01,$01,$04,$01,$01,$01,$01,$04,$01,$01,$01,$01,$01,$01,$01,$01,$04,$01,$01,$01,$01,$04,$01,$01,$01,$01,$01,$01,$01,$01,$04,$01,$01,$01,$01,$04,$01,$01,$01,$01,$00,$00,$00,$00,$04,$00,$00,$00,$00,$04,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$03,$03,$03,$03,$04,$03,$03,$03,$03,$04,$03,$03,$03,$03,$03,$03,$03,$03,$04,$03,$03,$03,$03,$04,$03,$03,$03,$03,$00,$00,$00,$00,$04,$00,$00,$00,$00,$04,$00,$00,$00,$00,$00,$00,$00,$00,$04,$00,$00,$00,$00,$04,$00,$00,$00,$00,$02,$02,$02,$02,$04,$02,$02,$02,$02,$04,$02,$02,$02,$02,$02,$02,$02,$02,$04,$02,$02,$02,$02,$04,$02,$02,$02,$02,$00,$00,$00,$00,$04,$00,$00,$00,$00,$04,$00,$00,$00,$00,$00,$00,$00,$00,$04,$00,$00,$00,$00,$04,$00,$00,$00,$00,$01,$01,$01,$01,$04,$01,$01,$01,$01,$04,$01,$01,$01,$01,$01,$01,$01,$01,$04,$01,$01,$01,$01,$04,$01,$01,$01,$01,$01,$01,$01,$01,$04,$01,$01,$01,$01,$04,$01,$01,$01,$01,$00,$00,$00,$00,$04,$00,$00,$00,$00,$04,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$FF
    
stage_18_brick_data:
    db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$03,$00,$00,$00,$00,$00,$03,$03,$00,$00,$00,$00,$00,$03,$03,$03,$00,$00,$00,$03,$03,$03,$03,$00,$00,$00,$03,$03,$00,$03,$03,$00,$03,$03,$00,$00,$03,$03,$00,$03,$03,$00,$00,$00,$03,$03,$03,$00,$00,$00,$00,$03,$03,$03,$00,$00,$00,$00,$00,$03,$00,$00,$00,$00,$00,$00,$03,$00,$00,$00,$02,$00,$00,$00,$00,$00,$02,$02,$00,$00,$00,$00,$00,$02,$02,$02,$00,$00,$00,$02,$02,$02,$02,$00,$00,$00,$02,$02,$00,$02,$02,$00,$02,$02,$00,$00,$02,$02,$00,$02,$02,$00,$00,$00,$02,$02,$02,$00,$00,$00,$00,$02,$02,$02,$00,$00,$00,$00,$00,$02,$00,$00,$00,$00,$00,$00,$02,$00,$00,$00,$01,$00,$00,$00,$00,$00,$01,$01,$00,$00,$00,$00,$00,$01,$01,$01,$00,$00,$00,$01,$01,$01,$01,$00,$00,$00,$01,$01,$01,$01,$01,$00,$01,$01,$01,$01,$01,$01,$00,$01,$01,$01,$00,$01,$01,$01,$01,$01,$00,$00,$01,$01,$01,$01,$01,$00,$00,$00,$01,$01,$01,$00,$00,$00,$00,$01,$01,$01,$00,$00,$00,$00,$00,$01,$00,$00,$00,$00,$00,$00,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$03,$00,$00,$00,$00,$00,$03,$03,$00,$00,$00,$00,$00,$03,$03,$03,$00,$00,$00,$03,$03,$03,$03,$00,$00,$00,$03,$03,$00,$03,$03,$00,$03,$03,$00,$00,$03,$03,$00,$03,$03,$00,$00,$00,$03,$03,$03,$00,$00,$00,$00,$03,$03,$03,$00,$00,$00,$00,$00,$03,$00,$00,$00,$00,$00,$00,$03,$00,$00,$00,$02,$00,$00,$00,$00,$00,$02,$02,$00,$00,$00,$00,$00,$02,$02,$02,$00,$00,$00,$02,$02,$02,$02,$00,$00,$00,$02,$02,$00,$02,$02,$00,$02,$02,$00,$00,$02,$02,$00,$02,$02,$00,$00,$00,$02,$02,$02,$00,$00,$00,$00,$02,$02,$02,$00,$00,$00,$00,$00,$02,$00,$00,$00,$00,$00,$00,$02,$00,$00,$00,$01,$00,$00,$00,$00,$00,$01,$01,$00,$00,$00,$00,$00,$01,$01,$01,$00,$00,$00,$01,$01,$01,$01,$00,$00,$00,$01,$01,$01,$01,$01,$00,$01,$01,$01,$01,$01,$01,$00,$01,$01,$01,$00,$01,$01,$01,$01,$01,$00,$00,$01,$01,$01,$01,$01,$00,$00,$00,$01,$01,$01,$00,$00,$00,$00,$01,$01,$01,$00,$00,$00,$00,$00,$01,$00,$00,$00,$00,$00,$00,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$FF
    
stage_22_brick_data:
    db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$02,$02,$02,$02,$02,$02,$02,$00,$00,$00,$00,$00,$00,$00,$02,$02,$02,$02,$02,$02,$02,$00,$00,$00,$00,$00,$00,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$00,$00,$00,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$00,$00,$00,$03,$03,$03,$03,$01,$01,$03,$01,$01,$00,$00,$00,$00,$00,$03,$03,$03,$03,$01,$01,$03,$01,$01,$00,$00,$00,$00,$03,$03,$01,$01,$03,$01,$01,$01,$01,$01,$01,$01,$00,$00,$03,$03,$01,$01,$03,$01,$01,$01,$01,$01,$01,$01,$00,$00,$03,$03,$01,$01,$03,$03,$01,$03,$01,$01,$01,$01,$00,$00,$03,$03,$01,$01,$03,$03,$01,$03,$01,$01,$01,$01,$00,$00,$03,$03,$03,$01,$01,$01,$03,$03,$03,$03,$03,$00,$00,$00,$03,$03,$03,$01,$01,$01,$03,$03,$03,$03,$03,$00,$00,$00,$00,$03,$03,$03,$01,$01,$01,$01,$01,$01,$00,$00,$00,$00,$00,$03,$03,$03,$01,$01,$01,$01,$01,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$04,$04,$04,$04,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$04,$04,$04,$04,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$02,$02,$02,$02,$02,$02,$02,$00,$00,$00,$00,$00,$00,$00,$02,$02,$02,$02,$02,$02,$02,$00,$00,$00,$00,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$00,$00,$00,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$00,$00,$00,$00,$00,$01,$01,$03,$01,$01,$03,$03,$03,$03,$00,$00,$00,$00,$00,$01,$01,$03,$01,$01,$03,$03,$03,$03,$00,$00,$00,$01,$01,$01,$01,$01,$01,$01,$03,$01,$01,$03,$03,$00,$00,$01,$01,$01,$01,$01,$01,$01,$03,$01,$01,$03,$03,$00,$00,$01,$01,$01,$01,$03,$01,$03,$03,$01,$01,$03,$03,$00,$00,$01,$01,$01,$01,$03,$01,$03,$03,$01,$01,$03,$03,$00,$00,$00,$03,$03,$03,$03,$03,$01,$01,$01,$03,$03,$03,$00,$00,$00,$03,$03,$03,$03,$03,$01,$01,$01,$03,$03,$03,$00,$00,$00,$00,$01,$01,$01,$01,$01,$01,$03,$03,$03,$00,$00,$00,$00,$00,$01,$01,$01,$01,$01,$01,$03,$03,$03,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$04,$04,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$04,$04,$04,$04,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$04,$04,$FF
    
stage_26_brick_data:
    db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$04,$04,$00,$00,$04,$04,$00,$00,$04,$04,$00,$00,$04,$04,$04,$04,$00,$00,$04,$04,$00,$00,$04,$04,$00,$00,$04,$04,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$04,$04,$00,$00,$04,$04,$00,$00,$04,$04,$00,$00,$00,$00,$04,$04,$00,$00,$04,$04,$00,$00,$04,$04,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$04,$04,$00,$00,$04,$04,$00,$00,$04,$04,$00,$00,$04,$04,$04,$04,$00,$00,$04,$04,$00,$00,$04,$04,$00,$00,$04,$04,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$FF
    
stage_30_brick_data:
    db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$03,$03,$04,$04,$04,$03,$03,$03,$03,$04,$04,$04,$03,$03,$03,$03,$04,$04,$04,$03,$03,$03,$03,$04,$04,$04,$03,$03,$00,$00,$00,$00,$04,$04,$00,$00,$04,$04,$00,$00,$00,$00,$00,$00,$00,$00,$04,$04,$00,$00,$04,$04,$00,$00,$00,$00,$02,$02,$02,$02,$02,$04,$02,$02,$04,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$04,$02,$02,$04,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$04,$02,$02,$04,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$04,$02,$02,$04,$02,$02,$02,$02,$02,$00,$00,$00,$00,$00,$04,$00,$00,$04,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$04,$00,$00,$04,$00,$00,$00,$00,$00,$01,$01,$01,$01,$04,$04,$01,$01,$04,$04,$01,$01,$01,$01,$01,$01,$01,$01,$04,$04,$01,$01,$04,$04,$01,$01,$01,$01,$01,$01,$04,$04,$04,$01,$01,$01,$01,$04,$04,$04,$01,$01,$01,$01,$04,$04,$04,$01,$01,$01,$01,$04,$04,$04,$01,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$02,$02,$02,$04,$04,$04,$02,$02,$04,$04,$04,$02,$02,$02,$02,$02,$02,$04,$04,$04,$02,$02,$04,$04,$04,$02,$02,$02,$02,$02,$04,$04,$02,$02,$02,$02,$02,$02,$04,$04,$02,$02,$02,$02,$04,$04,$02,$02,$02,$02,$02,$02,$04,$04,$02,$02,$00,$00,$04,$00,$00,$00,$00,$00,$00,$00,$00,$04,$00,$00,$00,$00,$04,$00,$00,$00,$00,$00,$00,$00,$00,$04,$00,$00,$01,$01,$04,$01,$01,$01,$01,$01,$01,$01,$01,$04,$01,$01,$01,$01,$04,$01,$01,$01,$01,$01,$01,$01,$01,$04,$01,$01,$01,$01,$04,$04,$01,$01,$01,$01,$01,$01,$04,$04,$01,$01,$01,$01,$04,$04,$01,$01,$01,$01,$01,$01,$04,$04,$01,$01,$00,$00,$00,$04,$04,$04,$00,$00,$04,$04,$04,$00,$00,$00,$00,$00,$00,$04,$04,$04,$00,$00,$04,$04,$04,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$FF
    
stage_3_brick_data:
    db $00,$00,$00,$00,$02,$02,$02,$02,$02,$02,$00,$00,$00,$00,$00,$00,$02,$02,$02,$02,$02,$02,$02,$02,$00,$00,$00,$00,$00,$00,$00,$00,$01,$03,$01,$03,$03,$03,$00,$00,$00,$00,$00,$00,$00,$01,$01,$03,$01,$03,$03,$03,$03,$00,$00,$00,$00,$00,$01,$01,$01,$01,$01,$03,$01,$03,$03,$00,$00,$00,$00,$00,$01,$01,$01,$01,$01,$03,$01,$03,$03,$00,$00,$00,$00,$00,$03,$03,$03,$03,$03,$01,$01,$03,$03,$00,$00,$00,$00,$00,$00,$03,$03,$03,$03,$01,$01,$03,$00,$00,$00,$00,$00,$00,$00,$01,$01,$01,$01,$01,$03,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$01,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$02,$03,$02,$02,$03,$02,$02,$00,$00,$00,$00,$00,$00,$02,$02,$03,$02,$02,$03,$02,$02,$02,$00,$00,$00,$00,$01,$01,$03,$01,$03,$03,$01,$03,$02,$01,$01,$00,$00,$00,$01,$01,$03,$01,$03,$03,$01,$03,$02,$01,$01,$00,$00,$00,$01,$03,$03,$03,$03,$03,$03,$03,$03,$01,$01,$00,$00,$00,$01,$03,$03,$03,$03,$03,$03,$03,$03,$01,$01,$00,$00,$00,$00,$03,$03,$03,$03,$00,$03,$03,$03,$03,$00,$00,$00,$00,$00,$03,$03,$03,$00,$00,$00,$03,$03,$03,$00,$00,$00,$00,$02,$02,$02,$02,$00,$00,$00,$02,$02,$02,$02,$00,$00,$00,$02,$02,$02,$02,$00,$00,$00,$02,$02,$02,$02,$00,$00,$FF
    
stage_7_brick_data:
    db $00,$01,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$03,$01,$02,$00,$00,$00,$03,$03,$03,$00,$00,$00,$00,$02,$03,$01,$02,$00,$00,$03,$03,$03,$03,$03,$00,$00,$00,$02,$01,$01,$02,$02,$00,$03,$01,$03,$03,$03,$00,$00,$00,$02,$01,$01,$02,$02,$03,$03,$01,$03,$03,$03,$03,$00,$00,$02,$02,$02,$02,$02,$03,$03,$03,$03,$03,$03,$03,$00,$00,$02,$00,$02,$02,$02,$03,$03,$03,$03,$03,$03,$03,$00,$00,$02,$00,$02,$02,$00,$03,$03,$03,$03,$03,$03,$03,$00,$00,$00,$00,$02,$02,$00,$03,$03,$03,$03,$03,$03,$03,$00,$00,$00,$02,$02,$02,$01,$03,$03,$03,$03,$03,$03,$03,$00,$00,$00,$02,$00,$02,$01,$03,$03,$03,$03,$03,$03,$03,$00,$00,$00,$00,$00,$02,$02,$01,$03,$03,$03,$03,$03,$01,$00,$00,$00,$00,$00,$00,$02,$01,$03,$03,$03,$03,$03,$01,$02,$00,$00,$00,$00,$00,$00,$02,$01,$01,$01,$01,$01,$00,$02,$00,$00,$00,$00,$00,$00,$02,$01,$01,$01,$01,$01,$00,$00,$02,$00,$00,$00,$00,$02,$02,$02,$00,$00,$02,$02,$02,$00,$00,$00,$00,$00,$02,$02,$02,$02,$00,$00,$02,$02,$02,$00,$00,$00,$00,$01,$02,$02,$02,$00,$00,$00,$00,$02,$02,$01,$00,$00,$00,$01,$02,$02,$00,$00,$00,$00,$00,$02,$02,$01,$00,$FF
    
stage_11_brick_data:
    db $00,$00,$00,$00,$00,$00,$01,$02,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$01,$02,$02,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$01,$01,$01,$01,$02,$00,$00,$00,$00,$00,$00,$00,$01,$01,$01,$01,$01,$01,$02,$02,$00,$00,$00,$00,$00,$01,$01,$01,$01,$01,$01,$01,$01,$01,$02,$00,$00,$00,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$02,$02,$00,$00,$01,$01,$02,$02,$03,$02,$02,$03,$02,$02,$02,$02,$00,$00,$00,$00,$02,$02,$03,$02,$02,$03,$02,$02,$00,$00,$00,$00,$00,$00,$01,$03,$00,$03,$03,$00,$03,$02,$00,$00,$00,$00,$00,$00,$01,$03,$00,$03,$03,$00,$03,$02,$00,$00,$00,$00,$00,$00,$01,$01,$03,$01,$01,$03,$01,$02,$00,$00,$00,$00,$00,$01,$01,$01,$03,$01,$01,$03,$01,$02,$02,$00,$00,$00,$00,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$00,$00,$00,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$02,$00,$00,$01,$02,$02,$01,$02,$02,$02,$01,$01,$02,$01,$02,$00,$00,$01,$02,$00,$01,$02,$02,$02,$01,$01,$02,$01,$02,$00,$00,$01,$02,$00,$01,$02,$00,$00,$01,$02,$00,$01,$02,$00,$00,$01,$02,$00,$01,$02,$00,$00,$01,$02,$00,$01,$02,$00,$00,$00,$01,$00,$00,$01,$01,$00,$01,$02,$00,$01,$02,$00,$00,$00,$01,$01,$00,$00,$00,$01,$01,$00,$01,$01,$00,$00,$FF
    
stage_15_brick_data:
    db $00,$00,$00,$02,$01,$00,$00,$00,$01,$02,$00,$00,$00,$00,$00,$00,$03,$02,$00,$00,$00,$00,$00,$02,$03,$00,$00,$00,$00,$01,$03,$03,$02,$00,$00,$01,$02,$01,$03,$00,$00,$00,$00,$01,$03,$03,$02,$00,$00,$00,$02,$01,$03,$00,$00,$00,$00,$00,$03,$03,$02,$01,$00,$00,$02,$03,$03,$01,$00,$00,$00,$00,$03,$03,$02,$00,$00,$00,$02,$03,$03,$01,$00,$00,$00,$01,$03,$01,$03,$02,$00,$02,$03,$03,$01,$00,$00,$00,$00,$01,$03,$01,$03,$02,$00,$02,$03,$03,$01,$00,$00,$00,$00,$00,$03,$03,$03,$02,$01,$02,$01,$03,$03,$00,$00,$00,$00,$00,$00,$03,$03,$02,$00,$02,$01,$03,$00,$00,$00,$00,$00,$00,$00,$03,$01,$03,$02,$03,$03,$03,$01,$00,$00,$00,$00,$00,$00,$00,$01,$03,$02,$03,$03,$00,$01,$00,$00,$00,$00,$00,$00,$00,$00,$03,$01,$03,$00,$00,$00,$00,$00,$00,$00,$02,$02,$00,$00,$00,$01,$00,$00,$00,$02,$02,$00,$00,$00,$02,$02,$02,$00,$00,$01,$00,$00,$02,$02,$02,$02,$00,$00,$02,$02,$02,$02,$00,$01,$00,$02,$02,$02,$02,$02,$00,$00,$02,$02,$02,$02,$00,$01,$00,$02,$02,$02,$02,$02,$00,$00,$00,$02,$02,$02,$02,$01,$02,$02,$02,$02,$02,$00,$00,$00,$00,$00,$02,$02,$02,$01,$02,$02,$02,$00,$00,$00,$00,$00,$00,$00,$00,$00,$02,$01,$02,$00,$00,$00,$00,$00,$00,$FF
    
stage_19_brick_data:
    db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$03,$03,$03,$03,$03,$03,$00,$03,$00,$00,$00,$00,$00,$03,$03,$03,$03,$03,$03,$03,$00,$03,$00,$00,$00,$00,$03,$01,$03,$03,$01,$01,$01,$03,$02,$01,$00,$00,$00,$03,$03,$01,$03,$03,$01,$01,$01,$03,$02,$01,$00,$00,$00,$03,$01,$01,$03,$01,$03,$03,$03,$03,$01,$03,$00,$00,$03,$03,$01,$01,$03,$01,$03,$03,$03,$03,$01,$03,$00,$00,$03,$01,$03,$01,$03,$03,$03,$03,$03,$03,$02,$03,$00,$00,$03,$01,$03,$01,$03,$03,$03,$03,$03,$03,$02,$03,$00,$00,$03,$03,$01,$03,$03,$03,$03,$02,$02,$03,$02,$03,$00,$00,$03,$03,$01,$03,$03,$03,$03,$02,$02,$03,$02,$03,$00,$00,$03,$03,$03,$03,$01,$01,$03,$01,$03,$03,$02,$03,$00,$00,$03,$03,$03,$03,$01,$01,$03,$01,$03,$03,$02,$03,$00,$00,$03,$03,$03,$01,$01,$01,$01,$01,$03,$03,$02,$03,$00,$00,$00,$03,$03,$01,$01,$01,$01,$01,$03,$03,$02,$03,$00,$00,$00,$03,$03,$03,$01,$01,$03,$03,$03,$03,$02,$03,$00,$00,$00,$00,$03,$03,$01,$01,$03,$03,$03,$03,$02,$03,$00,$00,$00,$00,$03,$03,$03,$03,$03,$03,$03,$03,$00,$03,$00,$00,$00,$00,$00,$03,$03,$03,$03,$03,$03,$03,$00,$03,$00,$FF
    
stage_23_brick_data:
    db $00,$00,$00,$00,$00,$00,$02,$02,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$02,$02,$02,$02,$00,$00,$00,$00,$00,$00,$00,$03,$03,$03,$02,$02,$02,$02,$03,$03,$03,$00,$00,$00,$00,$00,$03,$03,$02,$02,$02,$02,$03,$03,$00,$00,$00,$00,$00,$00,$01,$01,$03,$02,$02,$03,$01,$01,$00,$00,$00,$00,$00,$02,$01,$01,$03,$02,$02,$03,$01,$01,$02,$00,$00,$00,$00,$02,$01,$01,$03,$01,$01,$03,$01,$01,$02,$00,$00,$00,$02,$02,$01,$01,$03,$01,$01,$03,$01,$01,$02,$02,$00,$00,$02,$02,$02,$01,$01,$02,$02,$01,$01,$02,$02,$02,$00,$00,$02,$02,$02,$01,$01,$02,$02,$01,$01,$02,$02,$02,$00,$00,$02,$02,$02,$02,$03,$03,$03,$03,$02,$02,$02,$02,$00,$00,$02,$02,$02,$02,$03,$03,$03,$03,$02,$02,$02,$02,$00,$00,$02,$02,$01,$03,$02,$02,$02,$02,$03,$01,$02,$02,$00,$00,$00,$02,$01,$03,$02,$02,$02,$02,$03,$01,$02,$00,$00,$00,$00,$00,$02,$02,$01,$01,$01,$01,$02,$02,$00,$00,$00,$00,$00,$00,$00,$00,$01,$01,$01,$01,$00,$00,$00,$00,$00,$00,$00,$00,$03,$03,$01,$01,$01,$01,$03,$03,$00,$00,$00,$00,$00,$00,$03,$03,$01,$01,$01,$01,$03,$03,$00,$00,$00,$00,$00,$03,$03,$00,$01,$01,$01,$01,$00,$03,$03,$00,$00,$00,$00,$03,$03,$00,$00,$01,$01,$00,$00,$03,$03,$00,$00,$FF
    
stage_27_brick_data:
    db $00,$00,$00,$02,$02,$02,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$02,$02,$02,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$03,$03,$03,$03,$00,$00,$00,$01,$01,$00,$00,$00,$00,$03,$03,$03,$03,$03,$03,$00,$00,$01,$01,$01,$00,$00,$03,$01,$03,$01,$01,$03,$03,$03,$01,$01,$01,$01,$00,$00,$03,$01,$03,$01,$01,$03,$03,$03,$01,$01,$01,$01,$00,$00,$01,$03,$01,$03,$01,$01,$03,$03,$01,$01,$01,$01,$00,$00,$01,$03,$01,$03,$01,$01,$03,$03,$01,$01,$01,$01,$00,$00,$01,$03,$01,$03,$01,$01,$03,$01,$01,$01,$01,$01,$00,$00,$01,$03,$01,$03,$01,$01,$03,$01,$01,$01,$01,$00,$00,$00,$03,$01,$03,$01,$01,$03,$03,$01,$01,$01,$00,$00,$00,$00,$03,$01,$03,$01,$01,$03,$03,$01,$01,$01,$00,$00,$00,$02,$02,$02,$02,$03,$03,$03,$03,$01,$03,$03,$00,$01,$00,$00,$02,$02,$02,$03,$03,$03,$03,$01,$03,$03,$03,$01,$00,$00,$00,$03,$03,$02,$01,$01,$03,$03,$03,$03,$03,$01,$00,$00,$00,$00,$03,$02,$01,$01,$03,$03,$03,$03,$03,$01,$00,$00,$02,$02,$02,$01,$01,$01,$01,$01,$03,$03,$01,$01,$00,$00,$00,$02,$02,$01,$01,$01,$01,$01,$03,$00,$01,$00,$00,$00,$00,$00,$01,$01,$01,$01,$01,$01,$01,$00,$01,$00,$00,$00,$00,$00,$00,$01,$01,$01,$01,$00,$00,$00,$00,$00,$00,$FF
    
stage_31_brick_data:
    db $00,$00,$00,$00,$00,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$03,$02,$01,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$03,$01,$02,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$03,$01,$02,$01,$02,$00,$00,$03,$00,$00,$00,$00,$00,$02,$01,$01,$02,$02,$02,$00,$03,$03,$03,$01,$00,$00,$00,$02,$01,$01,$02,$02,$02,$03,$03,$03,$03,$01,$00,$00,$00,$03,$03,$03,$03,$02,$01,$03,$03,$01,$03,$03,$03,$00,$00,$00,$00,$00,$03,$02,$01,$03,$03,$01,$03,$03,$03,$00,$00,$00,$00,$02,$03,$02,$01,$03,$03,$03,$03,$03,$01,$03,$00,$00,$02,$00,$03,$02,$01,$03,$03,$03,$03,$03,$01,$03,$00,$00,$00,$03,$03,$03,$01,$01,$01,$03,$01,$03,$03,$03,$01,$00,$03,$03,$00,$03,$01,$01,$01,$03,$01,$03,$03,$03,$01,$00,$00,$00,$00,$02,$02,$02,$01,$03,$03,$03,$01,$03,$00,$00,$00,$01,$02,$02,$02,$02,$01,$03,$03,$03,$01,$03,$00,$00,$00,$00,$02,$02,$02,$02,$01,$01,$01,$01,$01,$01,$01,$00,$00,$01,$02,$02,$02,$02,$01,$01,$01,$01,$01,$01,$01,$00,$00,$00,$02,$02,$00,$03,$03,$03,$03,$02,$02,$03,$02,$00,$00,$00,$00,$00,$00,$00,$03,$03,$03,$02,$02,$00,$02,$00,$00,$00,$00,$00,$00,$00,$00,$00,$02,$02,$02,$02,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$02,$02,$02,$02,$00,$FF
    
blank_stage_brick_data: ; if w_true_stage_number = 32, program guard
    db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$FF

SECTION "Brick Type", ROM0[$638D]

brick_type_handler:
    ldh a, [h_brick_type_last_hit]    
    dec a
    ld b, a

    ld e, $6
    call multiply

    ld hl, BRICK_DATA_TABLE_START
    add hl, bc

    ld b, $0
    ld c, $5
    add hl, bc

    ld a, [hl]  ; =>brick_data_table[0][5]
    cp $0
    jr z, set_event_unbreakable_brick

    cp $1
    jr z, set_event_white_brick

    cp $2
    jr z, set_event_light_grey_brick
    
    jr set_event_dark_grey_brick