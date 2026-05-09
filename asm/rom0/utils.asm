SECTION "Joypad Read", ROM0[$03C1]

joypad_read:
    ld a, $20
    ldh [rP1], a

    ldh a, [rP1]
    ldh a, [rP1]
    ldh a, [rP1]
    ldh a, [rP1]
    ldh a, [rP1]
    ldh a, [rP1]
    ldh a, [rP1]
    ldh a, [rP1]
    ldh a, [rP1]
    ldh a, [rP1]    ; 10 reads

    and $0F
    swap a
    ld b, a

    ld a, $10
    ldh [rP1], a

    ldh a, [rP1]
    ldh a, [rP1]
    ldh a, [rP1]
    ldh a, [rP1]
    ldh a, [rP1]
    ldh a, [rP1]
    ldh a, [rP1]
    ldh a, [rP1]
    ldh a, [rP1]
    ldh a, [rP1]    ; 10 reads

    and $0F
    or b

    ldh [h_button_pressed_neg], a

    ld a, $30
    ldh [rP1], a

    ld b, $8

    ldh a, [h_button_pressed] 
    ld c, a

    ldh a, [h_button_pressed_neg]           

.Lab_0406
    rrc c
    jr c, .Lab_0416

    rrca
    jr nc, .Lab_0421

.Lab_040d               
    dec b
    jr nz, .Lab_0406

    ldh [h_button_pressed_flag], a
    ld a, c
    ldh [h_button_pressed], a  

    ret

.Lab_0416
    rrca
    jr c, .Lab_041d

    set $07, a
    jr .Lab_040d

.Lab_041d
    res $07, c
    jr .Lab_040d

.Lab_0421
    set $07, c
    jp .Lab_040d

SECTION "Math", ROM0[$0454]

multiply:   ; BC = B * E
    push af
    push hl

    ld hl, $0
    ld c, $0
    srl b
    rr c    ; sets c flag to 0
    ld a, $8

.Lab_0461
    sla e
    jr nc, .Lab_0466
    add hl, bc

.Lab_0466
    srl b
    rr c
    dec a
    jr nz, .Lab_0461

    ld c, l
    ld b, h

    pop hl
    pop af

    ret

; general use math that never gets used in the game

unused_load_absolute_value:
    sub b
    ld b, a ; A -= B
    and $80 ; isolate bit 7
    ld a, b
    ret z   ; ret if result ≥ 0
    
    xor $FF
    inc a   ; negate number
    ret

; converts A to decimal digits: C = hundreds, B = tens, A = ones

binary_to_bcd:
    ld b, $FF
    ld c, $FF

.loop_hundreds
    inc c
    sub $64
    jr nc, .loop_hundreds
    add $64

.loop_tens
    inc b
    sub $A
    jr nc, .loop_tens
    add $A
    ret

; $FF96-$FF9A      

score_to_bcd:
    ldh [h_score_digit_tens], a

    ld a, b
    ldh [h_score_digit_ones], a

    ld b, $FF

.set_score_digit_thousands
    inc b

    ldh a, [h_score_digit_ones]
    sub $10
    ldh [h_score_digit_ones], a

    ldh a, [h_score_digit_tens]
    sbc $27
    ldh [h_score_digit_tens], a

    jr nc, .set_score_digit_thousands

.carry_tens_of_thousands_flag
    ldh a, [h_score_digit_ones]
    add $10
    ldh [h_score_digit_ones], a

    ldh a, [h_score_digit_tens]
    adc $27
    ldh [h_score_digit_tens], a

    ld a, b
    ldh [h_score_digit_tens_of_thousands], a

    ld b, $FF

.set_score_digit_hundreds
    inc b

    ldh a, [h_score_digit_ones]
    sub $E8
    ldh [h_score_digit_ones], a
    
    ldh a, [h_score_digit_tens]
    sbc $3
    ldh [h_score_digit_tens], a

    jr nc, .set_score_digit_hundreds

.carry_thousands_flag
    ldh a, [h_score_digit_ones]
    add $E8
    ldh [h_score_digit_ones], a

    ldh a, [h_score_digit_tens]
    adc $3
    ldh [h_score_digit_tens], a

    ld a, b
    ldh [h_score_digit_thousands], a

    ld b, $FF

.set_score_digit_tens 
    inc b

    ldh a, [h_score_digit_ones]
    sub $64
    ldh [h_score_digit_ones], a

    ldh a, [h_score_digit_tens]
    sbc $0
    ldh [h_score_digit_tens], a

    jr nc, .set_score_digit_tens

.carry_hundreds_flag
    ldh a, [h_score_digit_ones]
    add $64
    ldh [h_score_digit_ones], a

    ld a, b
    ldh [h_score_digit_hundreds], a

    ld b, $FF

.set_score_digit_ones
    inc b

    ldh a, [h_score_digit_ones]
    sub 10
    ldh [h_score_digit_ones], a

    jr nc, .set_score_digit_ones

.carry_tens_flag
    ldh a, [h_score_digit_ones]
    add 10
    ldh [h_score_digit_ones], a
    ldh [h_score_digit_ones], a ; mistake ?

    ld a, b
    ldh [h_score_digit_tens], a

    ret

SECTION "Clear Objects in WRAM0", ROM0[$0983]

; clears the WRAM memory where the bricks' type and state are stored

clear_objects_wram0:
    ld hl, $C000
    ld de, $C400
    ld bc, $348

.Lab_098c
    ld a, $0
    ld [hl+], a ; [hl]  ; =>BYTE_C000
    ld [de], a; (de)=>w_object_state_array
    inc de
    dec bc
    ld a, b
    or c
    jr nz, .Lab_098c
    ret

SECTION "Negate BC Register", ROM0[$0FB3]

negate_bc:
    ld a, b
    xor $FF
    ld b, a

    ld a, c
    xor $FF
    ld c, a

    inc bc
    ret

SECTION "Demo Flag", ROM0[$6382]

clear_demo_flag:
    xor a
    ld [w_demo_flag], a
    ret

set_demo_flag:
    ld a, $1
    ld [w_demo_flag], a
    ret

SECTION "Unused Input and Demo", ROM0[$69AA]

unused_joypad_update:
    push af
    push bc
    ld a, $10
    ldh [rP1], a
    ldh a, [rP1]
    ldh a, [rP1]
    ldh a, [rP1]
    ldh a, [rP1]
    ldh a, [rP1]
    ldh a, [rP1]
    cpl
    and $F
    ld b, a
    ld a, $20
    ldh [rP1], a
    ldh a, [rP1]
    ldh a, [rP1]
    ldh a, [rP1]
    ldh a, [rP1]
    ldh a, [rP1]
    ldh a, [rP1]
    cpl
    and $F
    swap a
    or b
    ld c, a
    ldh a, [h_oam_dma_routine]
    xor c
    and c
    ldh [$FF81], a ; [h_unused_joypad_press_latch], a
    ld a, c
    ldh [h_oam_dma_routine], a 
    ld a, $30
    ldh [rP1], a
    pop bc
    pop af

    ret

; resets game_event, ball_oob and track_index flags if the game is in demo mode

demo_flag_handler:
    ld a, [w_demo_flag]
    cp $1
    jp z, demo_reset

    ret

demo_reset:
    xor a
    ld [w_game_event], a 
    ld [w_ball_oob], a 
    ld [w_track_index], a
    ret