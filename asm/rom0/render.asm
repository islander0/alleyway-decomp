DEF TILE_BLOCK_1_OFFSET EQU $80

DEF SPECIAL_BONUS_TEXT_TILE_DATA_START          EQU $1AAF
DEF CLEAR_SPECIAL_BONUS_TEXT_TILE_DATA_START    EQU $1ADE
DEF TRY_AGAIN_TILE_VRAM_DATA_START              EQU $1B0D
DEF CLEAR_TRY_AGAIN_TILE_VRAM_DATA_START        EQU $1B33

DEF MARIO_START_SPR_PTR_TABLE_START EQU $4A8B

DEF TILE_DATA_BLOCK_0_START EQU $4B75
DEF TILE_DATA_BLOCK_1_START EQU $5375
DEF TILE_DATA_BLOCK_2_START EQU $5B75

DEF VRAM_TILE_BLOCK_0_START  EQU $8000
DEF VRAM_TILE_BLOCK_1_START  EQU $8800
DEF VRAM_TILE_BLOCK_2_START  EQU $9000

DEF VRAM_TILE_MAP_0_START    EQU $9800
DEF VRAM_TILE_MAP_1_START    EQU $9C00

SECTION "OAM System", ROM0[$023D]

check_object_dirty_flag:
    ldh a, [h_object_dirty_flag]            
    cp $0
    ret z

    jr wait_vblank

SECTION "OAM Buffer Updates", ROM0[$02A1]

oam_buffer_update:
    ldh a, [h_object_dirty_flag]            
    cp $0
    jr z, .cancel_oam_buffer_update

    ld de, TILE_BUFFER_START

    call process_copy_table

    xor a
    ld [w_bg_map_buffer_pad], a
    ld [w_tile_buffer], a
    ldh [h_object_dirty_flag], a

.cancel_oam_buffer_update
    ret

copy_oam_buffer_to_hl:
    inc de

    ld h, a
    ld a, [de]
    ld l, a

    inc de
    ld a, [de]

    inc de

    call oam_buffer_handler                     

process_copy_table:
    ld a, [de]
    cp $0
    jr nz, copy_oam_buffer_to_hl

    ret

oam_buffer_handler:
    push af

    and $3F
    ld b, a

    pop af

    rlca
    rlca
    and $3
    jr z, .Lab_02da

    dec a
    jr z, .Lab_02e1

    dec a
    jr z, .Lab_02e8

    jr .Lab_02f5

.Lab_02da
    ld a, [de]
    ld [hl+], a

    inc de
    dec b
    jr nz, .Lab_02da

    ret

.Lab_02e1
    ld a, [de]
    inc de

.Lab_02e3
    ld [hl+], a

    dec b
    jr nz, .Lab_02e3

    ret

.Lab_02e8
    ld a, [de]
    ld [hl], a

    inc de

    ld a, b
    ld bc, $20
    add hl, bc

    ld b, a
    dec b
    jr nz, .Lab_02e8

    ret

.Lab_02f5
    ld a, [de]
    ld [hl], a

    ld a, b
    ld bc, $20
    add hl, bc

    ld b, a
    dec b
    jr nz, .Lab_02f5

    inc de
    ret

; general-purpose rectangular tile stamp routine.
; walks a descriptor table and writes rectangular regions
; of tiles into VRAM, supporting both unique-tile copies
; and single-tile fills.
; most likely a scrapped screen layout loader to replace
; the many load_*_vram functions in the game.

unused_tilemap_blit:
    pop de
    ld a, [de]
    ld l, a
    inc de
    ld a, [de]
    ld h, a
    inc de
    push de
    push af
    push bc

.Lab_030c
    ld a, [hl+]
    cp $FF
    jr z, .Lab_0355
    ld d, a
    ld a, [hl+]
    ld e, a
    push de
    ld a, [hl+]
    push af
    and $1F
    ld c, a
    ld a, [hl+]
    ldh [h_unused_blit_width], a 
    pop af

.Lab_031e
    and $80
    jr z, .Lab_033b

.Lab_0322
    ldh a, [h_unused_blit_width]            
    ld b, a

.Lab_0325
    ld a, [hl+]
    ld [de], a
    inc de
    dec b
    jr nz, .Lab_0325
    pop de
    push hl
    ld hl, $20
    add hl, de
    push hl
    pop de
    pop hl
    push de
    dec c
    jr nz, .Lab_0322
    pop de
    jr .Lab_030c

.Lab_033b
    ldh a, [h_unused_blit_width]            
    ld b, a

.copy_next_data
    ld a, [hl]
    ld [de], a
    inc de
    dec b
    jr nz, .copy_next_data
    pop de
    push hl
    ld hl, $20
    add hl, de
    push hl
    pop de
    pop hl
    push de
    dec c
    jr nz, .Lab_033b
    pop de
    inc hl
    jr .Lab_030c

.Lab_0355
    pop bc
    pop af
    ret

; Fill tile_map_0 with $FF tiles

load_tile_map_0:
    ld hl, VRAM_TILE_MAP_0_START
    jr clear_tile_map

; Fill tile_map_1 with $FF tiles

load_tile_map_1:
    ld hl, VRAM_TILE_MAP_1_START

clear_tile_map:
    ld bc, $400

.Lab_0363
    ld a, $FF
    ld [hl+], a ; =>[tile_map_1], a

    dec bc
    ld a, b
    or c
    jr nz, .Lab_0363

    ret

; clear most OAMs' buffer on screen during gameplay

load_main_oam_buffer:
    ld b, 160
    ld a, 0
    ld hl, OAM_BUFFER_START

clear_oam_handler:
    ld [hl+], a
    dec b
    jr nz, clear_oam_handler

    ret

; clears the OAM buffer of the explosion

load_anim_oam_buffer:
    ld b, 24
    ld a, 0
    ld hl, OAM_SPECIAL_BONUS_POINTS_START
    jr clear_oam_handler

; loads all the visual assets of ROM Bank 01 into the 3 VRAM tile blocks

load_tile_data:
    ld hl, TILE_DATA_BLOCK_2_START
    ld de, VRAM_TILE_BLOCK_2_START
    ld bc, $800

.load_tile_data_block_2
    ld a, [hl+] ; =>[tile_data_block_2]
    ld [de], a ; =>[vram_tile_block_2], a     
    inc de

    dec bc
    ld a, b
    or c
    jr nz, .load_tile_data_block_2

    ld hl, TILE_DATA_BLOCK_1_START
    ld de, VRAM_TILE_BLOCK_1_START
    ld bc, $800

.load_tile_data_block_1  
    ld a, [hl+] ; [tile_data_block_1]
    ld [de], a  ; =>[vram_tile_block_1], a     
    inc de

    dec bc
    ld a, b
    or c
    jr nz, .load_tile_data_block_1

    ld hl, TILE_DATA_BLOCK_0_START
    ld de, VRAM_TILE_BLOCK_0_START
    ld bc, $800

.load_tile_data_block_0
    ld a, [hl+] ; =>[tile_data_block_0]
    ld [de], a  ; =>[vram_tile_block_0], a     
    inc de

    dec bc
    ld a, b
    or c
    jr nz, .load_tile_data_block_0

    ret

; data containes opcodes for a function in HRAM at $FF80

oma_dma_routine_data:
    db $F3,$3E,$C8,$E0,$46,$3E,$28,$3D,$20,$FD,$FB,$C9

SECTION "Palette Fade Data", ROM0[$08C2]

palette_fade_in_data:
    db $00,$40,$90,$E4

palette_fade_out_data:
    db $E4,$90,$40,$00

SECTION "VRAM Text", ROM0[$1A97]

; loads the "SPECIAL BONUS" and "PTS." text when a bonus stage is won
; the two tile sets are offset, 2 addresses are used

load_special_bonus_text_vram:
    call check_object_dirty_flag

    ld hl, SPECIAL_BONUS_TEXT_TILE_DATA_START
    ld de, TILE_BUFFER_START
    ld b, 23

.copy_next_tile 
    ld a, [hl+]
    ld [de], a 
    inc de
    dec b
    jr nz, .copy_next_tile

    ld a, $1
    ldh [h_object_dirty_flag], a 

    jp wait_vblank

; VRAM address: $9B42            
; Number of tiles: 12            
; spells out SPECIAL BONUS       

special_bonus_text_tile_data:
    db $9B,$42,$0C,$C4,$C5,$C6,$C7,$8A,$C8,$FF,$8B,$98,$97,$9E,$9C

; VRAM address: $9B69            
; Number of tiles: 4             
; spells out PTS.                

pts_text_tile_data:
    db $9B,$69,$04,$99,$9D,$9C,$B7,$00

; clears the "SPECIAL BONUS" and "PTS." text when a bonus stage is won
; the two tile sets are offset, 2 addresses are used

clear_special_bonus_text_vram:
    call check_object_dirty_flag

    ld hl, CLEAR_SPECIAL_BONUS_TEXT_TILE_DATA_START
    ld de, TILE_BUFFER_START
    ld b, 23

.copy_next_tile
    ld a, [hl+]
    ld [de], a  
    inc de
    dec b
    jr nz, .copy_next_tile

    ld a, $1
    ldh [h_object_dirty_flag], a 

    jp wait_vblank

; VRAM address: $9B42            
; Number of tiles: 12            
; Clears the "SPECIAL POINTS" text                 

clear_special_bonus_text_tile_data:
    db $9B,$42,$0C,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF

; VRAM address: $9B69            
; Number of tiles: 4             
; Removes the "PTS." text        

clear_pts_text_tile_data:
    db $9B,$69,$04,$FF,$FF,$FF,$FF,$00

; Loads "TRY AGAIN!" under the big Mario during the Win sequence

load_try_again_vram:
    call check_object_dirty_flag

    ld hl, TRY_AGAIN_TILE_VRAM_DATA_START
    ld de, TILE_BUFFER_START    ; [de] = w_tile_buffer
    ld b, 15

.LAB_1b00
    ld a, [hl+]
    ld [de], a      ; w_tile_buffer + $00, a     
    inc de
    dec b
    jr nz, .LAB_1b00

    ld a, 1
    ldh [h_object_dirty_flag], a 

    jp wait_vblank

; VRAM address: $99C3            
; Number of tiles: 10            
; Loads the TRY AGAIN! text at the end of the Win sequence

try_again_tile_vram_data:
    db $99,$C3,$0A,$9D,$9B,$A2,$FF,$8A,$90,$8A,$92,$97,$1F,$00

; Removes TRY AGAIN! text with FF tiles            

clear_try_again_vram:
    call check_object_dirty_flag

    ld hl, CLEAR_TRY_AGAIN_TILE_VRAM_DATA_START
    ld de, TILE_BUFFER_START    ; [de] = w_tile_buffer
    ld b, 15

.LAB_1b26
    ld a, [hl+]     ; =>clear_try_again_tile_vram_data -> copy from TILE_BUFFER_START to $C90D
    ld [de], a      ; w_tile_buffer + $00, a     
    inc de
    dec b
    jr nz, .LAB_1b26

    ld a, 1
    ldh [h_object_dirty_flag], a 

    jp wait_vblank
                         
; VRAM address: $99C3            
; Number of tiles: 10            
; Clears the TRY AGAIN! text with FF tiles         

clear_try_again_tile_vram_data:
    db $99,$C3,$0A,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$00

SECTION "Stage and Score OAM", ROM0[$4669]

; loads OAM buffer data from $C990 to $C89F        

load_stage_number_oam_buffer:

    ; Y plane

    ld a, $70
    ld [OAM_STAGE_NUMBER_START + $00], a
    ld [OAM_STAGE_NUMBER_START + $04], a
    ld [OAM_STAGE_NUMBER_START + $08], a
    ld [OAM_STAGE_NUMBER_START + $0C], a
    ld [OAM_STAGE_NUMBER_START + $10], a
    ld [OAM_STAGE_NUMBER_START + $14], a
    ld [OAM_STAGE_NUMBER_START + $18], a
    ld [OAM_STAGE_NUMBER_START + $1C], a

    ; X plane

    ld a, $30
    ld [OAM_STAGE_NUMBER_START + $01], a
    ld a, $38
    ld [OAM_STAGE_NUMBER_START + $05], a
    ld a, $40
    ld [OAM_STAGE_NUMBER_START + $09], a
    ld a, $48
    ld [OAM_STAGE_NUMBER_START + $0D], a
    ld a, $50
    ld [OAM_STAGE_NUMBER_START + $11], a
    ld a, $58
    ld [OAM_STAGE_NUMBER_START + $15], a
    ld a, $60
    ld [OAM_STAGE_NUMBER_START + $19], a
    ld a, $68
    ld [OAM_STAGE_NUMBER_START + $1D], a

    ; Attribute plane

    ld a, $0
    ld [OAM_STAGE_NUMBER_START + $03], a
    ld [OAM_STAGE_NUMBER_START + $07], a
    ld [OAM_STAGE_NUMBER_START + $0B], a
    ld [OAM_STAGE_NUMBER_START + $0F], a
    ld [OAM_STAGE_NUMBER_START + $13], a
    ld [OAM_STAGE_NUMBER_START + $17], a
    ld [OAM_STAGE_NUMBER_START + $1B], a
    ld [OAM_STAGE_NUMBER_START + $1F], a

    ; Tile ID plane

    ld a, $9C
    ld [OAM_STAGE_NUMBER_START + $02], a
    ld a, $9D
    ld [OAM_STAGE_NUMBER_START + $06], a
    ld a, $8A
    ld [OAM_STAGE_NUMBER_START + $0A], a
    ld a, $90
    ld [OAM_STAGE_NUMBER_START + $0E], a
    ld a, $8E
    ld [OAM_STAGE_NUMBER_START + $12], a
    ld a, $3E
    ld [OAM_STAGE_NUMBER_START + $16], a

    ld a, [w_stage_number_display]
    call binary_to_bcd

    push af

    ld a, b
    add TILE_BLOCK_1_OFFSET
    ld [OAM_STAGE_NUMBER_START + $1A], a    

    pop af

    add TILE_BLOCK_1_OFFSET
    ld [OAM_STAGE_NUMBER_START + $1E], a    

    ret



load_bonus_text_oam_buffer:

    ; Y plane

    ld a, $70
    ld [OAM_BONUS_TEXT_START + $00], a
    ld [OAM_BONUS_TEXT_START + $04], a
    ld [OAM_BONUS_TEXT_START + $08], a
    ld [OAM_BONUS_TEXT_START + $0C], a
    ld [OAM_BONUS_TEXT_START + $10], a

    ; X plane

    ld a, $38
    ld [OAM_BONUS_TEXT_START + $01], a
    ld a, $40
    ld [OAM_BONUS_TEXT_START + $05], a
    ld a, $48
    ld [OAM_BONUS_TEXT_START + $09], a
    ld a, $50
    ld [OAM_BONUS_TEXT_START + $0D], a
    ld a, $58
    ld [OAM_BONUS_TEXT_START + $11], a

    ; Attribute plane

    ld a, $0
    ld [OAM_BONUS_TEXT_START + $13], a
    ld [OAM_BONUS_TEXT_START + $17], a
    ld [OAM_BONUS_TEXT_START + $1B], a
    ld [OAM_BONUS_TEXT_START + $1F], a
    ld [OAM_BONUS_TEXT_START + $13], a  ; bug: useless write, should be + $23 and not + $13

    ; Tile ID plane

    ld a, $8B
    ld [OAM_BONUS_TEXT_START + $02], a
    ld a, $98
    ld [OAM_BONUS_TEXT_START + $06], a
    ld a, $97
    ld [OAM_BONUS_TEXT_START + $0A], a
    ld a, $9E
    ld [OAM_BONUS_TEXT_START + $0E], a
    ld a, $9C
    ld [OAM_BONUS_TEXT_START + $12], a
    
    ret

load_pause_text_oam_buffer:

    ; Y plane

    ld a, $70
    ld [OAM_PAUSE_START + $00], a
    ld [OAM_PAUSE_START + $04], a
    ld [OAM_PAUSE_START + $08], a
    ld [OAM_PAUSE_START + $0C], a
    ld [OAM_PAUSE_START + $10], a

    ; X plane

    ld a, $38
    ld [OAM_PAUSE_START + $01], a
    ld a, $40
    ld [OAM_PAUSE_START + $05], a
    ld a, $48
    ld [OAM_PAUSE_START + $09], a
    ld a, $50
    ld [OAM_PAUSE_START + $0D], a
    ld a, $58
    ld [OAM_PAUSE_START + $11], a

    ; Attribute plane

    ld a, $0
    ld [OAM_PAUSE_START + $13], a   
    ld [OAM_PAUSE_START + $17], a
    ld [OAM_PAUSE_START + $1B], a
    ld [OAM_PAUSE_START + $1F], a
    ld [OAM_PAUSE_START + $13], a   ; likely a typo, probably meant to be $23 instead

    ; Tile ID plane

    ld a, $99
    ld [OAM_PAUSE_START + $02], a   ; P
    ld a, $8A
    ld [OAM_PAUSE_START + $06], a   ; A
    ld a, $9E
    ld [OAM_PAUSE_START + $0A], a   ; U
    ld a, $9C
    ld [OAM_PAUSE_START + $0E], a   ; S
    ld a, $8E
    ld [OAM_PAUSE_START + $12], a   ; E
    ret

; loads the stage number (not counting bonus levels) to VRAM

load_stage_number_display_vram:
    call check_object_dirty_flag

    ld hl, TILE_BUFFER_START

    ; $9D62

    ld a, $9D
    ld [hl+], a     ; w_tile_buffer + $00, a  

    ld a, $62
    ld [hl+], a     ; w_tile_buffer + $01, a    

    ; 2 TILES

    ld a, $2
    ld [hl+], a     ; w_tile_buffer + $02, a    

    ld a, [w_stage_number_display]    
    call binary_to_bcd  ; loads the stage number and converts it to BCD
    
    push af

    ; stage number text

    ld a, b
    add TILE_BLOCK_1_OFFSET
    ld [hl+], a

    pop af

    add TILE_BLOCK_1_OFFSET
    ld [hl+], a

    xor a
    ld [hl+], a

    inc a
    ldh [h_object_dirty_flag], a 

    jp wait_vblank

; loads the number of lives that the player currently has to VRAM

load_lives_number_vram:
    call check_object_dirty_flag

    ld hl, TILE_BUFFER_START

    ; $9E04

    ld a, $9E
    ld [hl+], a     ; w_tile_buffer + $00, a    
    ld a, $04
    ld [hl+], a     ; w_tile_buffer + $01, a  

    ; 1 tile

    ld a, 1
    ld [hl+], a     ; w_tile_buffer + $02, a    

    ; life number

    ld a, [w_life_counter]
    add TILE_BLOCK_1_OFFSET
    ld [hl+], a     ; w_tile_buffer + $03, a

    xor a
    ld [hl+], a     ; w_tile_buffer + $04, a

    inc a
    ldh [h_object_dirty_flag], a 

    jp wait_vblank

; loads the "TIME" text that appears during bonus stages     *

load_bonus_time_text_vram:
    call check_object_dirty_flag

    ld hl, TILE_BUFFER_START

    ld a, $9D
    ld [hl+], a      ; w_tile_buffer + $00, a    
    ld a, $A1
    ld [hl+], a      ; w_tile_buffer + $01, a

    ; 4 tiles

    ld a, 4
    ld [hl+], a      ; w_tile_buffer + $02, a

    ; "TIME"

    ld a, $9D
    ld [hl+], a      ; w_tile_buffer + $03, a    
    ld a, $92
    ld [hl+], a      ; w_tile_buffer + $04, a    
    ld a, $96
    ld [hl+], a      ; w_tile_buffer + $05, a    
    ld a, $8E
    ld [hl+], a      ; w_tile_buffer + $06, a    

end_tile_load:
    xor a
    ld [hl+], a      ; w_tile_buffer + $07, a

    inc a
    ldh [h_object_dirty_flag], a 

    jp wait_vblank

; on every level load, clears the "TIME" tiles of the bonus stages

clear_bonus_time_text_vram:
    call check_object_dirty_flag

    ld hl, TILE_BUFFER_START    ; [hl] = w_tile_buffer

    ; $9D1A

    ld a, $9D
    ld [hl+], a      ; w_tile_buffer + $00, a    
    ld a, $A1
    ld [hl+], a      ; w_tile_buffer + $01, a

    ; 4 tiles

    ld a, $4
    ld [hl+], a      ; w_tile_buffer + $02, a

    ; transparent

    ld a, $FF
    ld [hl+], a      ; w_tile_buffer + $03, a    
    ld [hl+], a      ; w_tile_buffer + $04, a    
    ld [hl+], a      ; w_tile_buffer + $05, a    
    ld [hl+], a      ; w_tile_buffer + $06, a   

    jr end_tile_load

; updates score on level load, bonus win and game win

update_score_oam_buffer:
    ld hl, OAM_SCORE_START  ; $C814

    ldh a, [h_player_score_lo]      
    ld b, a
    ldh a, [h_player_score_hi]    
    call score_to_bcd

    ld a, $40
    ld [hl+], a ; y
    ld a, $88
    ld [hl+], a ; x

    ld b, $FF
    ldh a, [h_score_digit_tens_of_thousands]

    cp $0
    jr z, .update_current_score

    ld b, $BF
    cp $1
    jr z, .update_current_score

    ld b, $BC
    cp $2
    jr z, .update_current_score

    ld b, $C9

.update_current_score  
    ld a, b
    ld [hl+], a ; tile ID: if score < 10000, display FF tile
    ld a, $0
    ld [hl+], a ; attribute

    ld a, $38
    ld [hl+], a
    ld a, $88
    ld [hl+], a
    ldh a, [h_score_digit_thousands]        
    add TILE_BLOCK_1_OFFSET
    ld [hl+], a
    ld a, $0
    ld [hl+], a

    ld a, $38
    ld [hl+], a
    ld a, $90
    ld [hl+], a
    ldh a, [h_score_digit_hundreds]         
    add TILE_BLOCK_1_OFFSET
    ld [hl+], a
    ld a, $0
    ld [hl+], a

    ld a, $38
    ld [hl+], a
    ld a, $98
    ld [hl+], a
    ldh a, [h_score_digit_tens]             
    add TILE_BLOCK_1_OFFSET
    ld [hl+], a
    ld a, $0
    ld [hl+], a

    ld a, $38
    ld [hl+], a
    ld a, $A0
    ld [hl+], a
    ldh a, [h_score_digit_ones]             
    add TILE_BLOCK_1_OFFSET
    ld [hl+], a
    ld a, $0
    ld [hl+], a

    ldh a, [h_top_score_lo]
    ld b, a
    ldh a, [h_top_score_hi]
    call score_to_bcd

    ld a, $28
    ld [hl+], a
    ld a, $88
    ld [hl+], a

    ld b, $FF
    ldh a, [h_score_digit_tens_of_thousands]

    cp $0
    jr z, .update_top_score

    ld b, $BF
    cp $1
    jr z, .update_top_score

    ld b, $BC
    cp $2
    jr z, .update_top_score

    ld b, $C9

.update_top_score
    ld a, b
    ld [hl+], a
    ld a, $0
    ld [hl+], a

    ld a, $20
    ld [hl+], a
    ld a, $88
    ld [hl+], a
    ldh a, [h_score_digit_thousands]        
    add TILE_BLOCK_1_OFFSET
    ld [hl+], a
    ld a, $0
    ld [hl+], a

    ld a, $20
    ld [hl+], a
    ld a, $90
    ld [hl+], a
    ldh a, [h_score_digit_hundreds]         
    add TILE_BLOCK_1_OFFSET
    ld [hl+], a
    ld a, $0
    ld [hl+], a

    ld a, $20
    ld [hl+], a
    ld a, $98
    ld [hl+], a
    ldh a, [h_score_digit_tens]             
    add TILE_BLOCK_1_OFFSET
    ld [hl+], a
    ld a, $0
    ld [hl+], a

    ld a, $20
    ld [hl+], a
    ld a, $A0
    ld [hl+], a
    ldh a, [h_score_digit_ones]             
    add TILE_BLOCK_1_OFFSET
    ld [hl+], a
    ld a, $0
    ld [hl+], a

    ret

; called during title screen initialization    

load_title_screen_top_score_buffer_oam:
    ldh a, [h_top_score_lo]
    ld b, a
    ldh a, [h_top_score_hi]
    call score_to_bcd

    ld hl, OAM_TITLE_SCORE_START

    ld a, $70
    ld [hl+], a

    ld a, $70
    ld [hl+], a

    ld b, $FF
    ldh a, [h_score_digit_tens_of_thousands]
    cp $0
    jr z, .load_top_score

    ld b, $BF
    cp $1
    jr z, .load_top_score

    ld b, $BC
    cp $2
    jr z, .load_top_score

    ld b, $C9

.load_top_score
    ld a, b
    ld [hl+], a    
    ld a, $0
    ld [hl+], a    

    ld a, $68
    ld [hl+], a    
    ld a, $70
    ld [hl+], a
    ldh a, [h_score_digit_thousands]        
    add TILE_BLOCK_1_OFFSET
    ld [hl+], a    
    ld a, $0
    ld [hl+], a    

    ld a, $68
    ld [hl+], a    
    ld a, $78
    ld [hl+], a    
    ldh a, [h_score_digit_hundreds]         
    add TILE_BLOCK_1_OFFSET
    ld [hl+], a    
    ld a, $0
    ld [hl+], a    

    ld a, $68
    ld [hl+], a    
    ld a, $80
    ld [hl+], a    
    ldh a, [h_score_digit_tens]             
    add TILE_BLOCK_1_OFFSET
    ld [hl+], a    
    ld a, $0
    ld [hl+], a    

    ld a, $68
    ld [hl+], a    
    ld a, $88
    ld [hl+], a    
    ldh a, [h_score_digit_ones]             
    add TILE_BLOCK_1_OFFSET
    ld [hl+], a    
    ld a, $0
    ld [hl+], a 

    ret

; triggers upon bonus level win  
; only loads the number, not the "SPECIAL BONUS PTS." text   *

load_special_bonus_points_oam_buffer:
    ld hl, OAM_SPECIAL_BONUS_POINTS_START

    ld a, b
    ld b, c
    call score_to_bcd

    ld a, $78
    ld [hl+], a
    ld a, $30
    ld [hl+], a
    ldh a, [h_score_digit_thousands]        
    add TILE_BLOCK_1_OFFSET
    ld [hl+], a
    ld a, $0
    ld [hl+], a

    ld a, $78
    ld [hl+], a
    ld a, $38
    ld [hl+], a
    ldh a, [h_score_digit_hundreds]         
    add TILE_BLOCK_1_OFFSET
    ld [hl+], a
    ld a, $0
    ld [hl+], a

    ld a, $78
    ld [hl+], a
    ld a, $40
    ld [hl+], a
    ldh a, [h_score_digit_tens]             
    add TILE_BLOCK_1_OFFSET
    ld [hl+], a
    ld a, $0
    ld [hl+], a

    ld a, $78
    ld [hl+], a
    ld a, $48
    ld [hl+], a
    ldh a, [h_score_digit_ones]             
    add TILE_BLOCK_1_OFFSET
    ld [hl+], a
    ld a, $0
    ld [hl+], a

    ret

load_game_over_text_oam_buffer:

    ; y plane

    ld a, $50
    ld [OAM_GAME_OVER_START + $00], a
    ld [OAM_GAME_OVER_START + $04], a
    ld [OAM_GAME_OVER_START + $08], a
    ld [OAM_GAME_OVER_START + $0C], a

    ld [OAM_GAME_OVER_START + $10], a
    ld [OAM_GAME_OVER_START + $14], a
    ld [OAM_GAME_OVER_START + $18], a
    ld [OAM_GAME_OVER_START + $1C], a

    ; x plane

    ld a, $38
    ld [OAM_GAME_OVER_START + $01], a
    ld a, $40
    ld [OAM_GAME_OVER_START + $05], a
    ld a, $48
    ld [OAM_GAME_OVER_START + $09], a
    ld a, $50
    ld [OAM_GAME_OVER_START + $0D], a

    ld a, $60
    ld [OAM_GAME_OVER_START + $11], a
    ld a, $68
    ld [OAM_GAME_OVER_START + $15], a
    ld a, $70
    ld [OAM_GAME_OVER_START + $19], a
    ld a, $78
    ld [OAM_GAME_OVER_START + $1D], a

    ; attribute

    ld a, $0
    ld [OAM_GAME_OVER_START + $03], a
    ld [OAM_GAME_OVER_START + $07], a
    ld [OAM_GAME_OVER_START + $0B], a
    ld [OAM_GAME_OVER_START + $0F], a

    ld [OAM_GAME_OVER_START + $13], a
    ld [OAM_GAME_OVER_START + $17], a
    ld [OAM_GAME_OVER_START + $1B], a
    ld [OAM_GAME_OVER_START + $1F], a

    ; tile ID

    ld a, $90
    ld [OAM_GAME_OVER_START + $02], a   ; G
    ld a, $8A
    ld [OAM_GAME_OVER_START + $06], a   ; A
    ld a, $96
    ld [OAM_GAME_OVER_START + $0A], a   ; M
    ld a, $8E
    ld [OAM_GAME_OVER_START + $0E], a   ; E

    ld a, $98
    ld [OAM_GAME_OVER_START + $12], a   ; O
    ld a, $9F
    ld [OAM_GAME_OVER_START + $16], a   ; V
    ld a, $8E
    ld [OAM_GAME_OVER_START + $1A], a   ; E
    ld a, $9B
    ld [OAM_GAME_OVER_START + $1E], a   ; R

    ret

load_wall_oam_buffer:
    ld hl, OAM_WALL_START
    ld e, 24
    ld d, 17   ; loop counter

.load_next_wall_tile  
    ld a, e
    ld [hl+], a     ; Y
    ld a, 8
    ld [hl+], a     ; X
    ld a, $B4
    ld [hl+], a     ; Tile ID
    ld a, $0
    ld [hl+], a     ; Attribute  

    ld a, e
    add 8          ; offset 1 tile (8 px) down
    ld e, a

    dec d
    jr nz, .load_next_wall_tile

    ret

SECTION "Tilemap Patch Table", ROM0[$4A3C]

tilemap_patch_table:
    db $9C,$00,$01,$BE,$9C,$20,$D8,$B4,$98,$00,$01,$BD,$98,$01,$54,$B5,$9C,$21,$03,$9D,$98,$99,$9C,$81,$04,$B8,$B9,$BA,$BB,$9D,$41,$04,$C0,$C1,$C2,$C3,$9E,$02,$02,$B1,$B2,$00

SECTION "Copy Tiles and Sprite Pointers Tables", ROM0[$4A66]

copy_tiles4_oam_buffer:
    sla a
    ld e, a
    ld d, $0    ; de = a

    ld hl, MARIO_START_SPR_PTR_TABLE_START
    add hl, de

    ld d, [hl]   ; =>mario_start_spr_ptr_table
    inc hl
    ld e, [hl]   ; =>mario_start_spr_ptr_table[1]

    ld hl, OAM_MARIO_WALK_START
    ld a, 4    ; loop counter

.load_tiles4  
    push af

    ld a, [DE]
    add c
    ld [hl+], a
    inc de

    ld a, [DE]
    add b
    ld [hl+], a
    inc de

    ld a, [DE]  ; Tile No
    ld [hl+], a
    inc de

    ld a, [DE]  ; Attribute
    ld [hl+], a
    inc de

    pop af

    dec a
    jr nz, .load_tiles4

    ret

mario_start_spr_ptr_table:
    db $4A,$A5,$4A,$B5,$4A,$C5,$4A,$D5,$4A,$E5

mario_jump_out_spr_ptr_table:
    db $4A,$F5,$4B,$05

explosion_spr_ptr_table:
    db $4B,$15,$4B,$25,$4B,$35

mario_wink_spr_ptr_table:
    db $4B,$45,$4B,$55,$4B,$65

SECTION "Tile Data Block 0", ROM0[$4B75]

tile_data_block_0:
    db $68,$7F,$A8,$A8,$FF,$E8,$E8,$FF,$7F,$7F,$00,$00,$00,$00,$00,$00,$00,$FF,$00,$00,$FF,$00,$00,$FF,$FF,$FF,$00,$00,$00,$00,$00,$00,$6F,$7F,$AF,$AF,$F8,$E8,$E8,$FF,$7F,$7F,$00,$00,$00,$00,$00,$00,$FF,$FF,$FF,$FF,$00,$00,$00,$FF,$FF,$FF,$00,$00,$00,$00,$00,$00,$3C,$FF,$3C,$3C,$81,$00,$00,$FF,$FF,$FF,$00,$00,$00,$00,$00,$00,$60,$60,$B0,$B0,$F0,$F0,$60,$60,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$04,$07,$10,$1F,$06,$02,$1F,$01,$0F,$0F,$07,$00,$01,$03,$00,$00,$00,$E0,$00

SECTION "Tile Data Block 1", ROM0[$5375]

tile_data_block_1:
    db $00,$00,$3C,$3C,$66,$66,$66,$66,$66,$66,$66,$66,$3C,$3C,$00,$00,$00,$00,$18,$18,$38,$38,$18,$18,$18,$18,$18,$18,$3C,$3C,$00,$00,$00,$00,$3C,$3C,$66,$66,$0C,$0C,$38,$38,$60,$60,$7E,$7E,$00,$00,$00,$00,$7E,$7E,$08,$08,$3C,$3C,$06,$06,$66,$66,$3C,$3C,$00,$00,$00,$00,$1C,$1C,$2C,$2C,$4C,$4C,$7E,$7E,$0C,$0C,$0C,$0C,$00,$00,$00,$00,$7C,$7C,$40,$40,$7C,$7C,$06,$06,$66,$66,$3C,$3C,$00,$00,$00,$00,$3C,$3C,$60,$60,$7C,$7C,$66,$66,$66,$66,$3C,$3C,$00,$00,$00,$00,$7E,$7E,$66,$66,$0C,$0C,$18,$18,$18,$18,$18,$18,$00,$00,$00,$00,$3C,$3C,$66,$66,$3C,$3C,$66,$66,$66,$66,$3C,$3C,$00,$00,$00,$00,$3C,$3C,$66,$66,$66,$66,$3E,$3E,$06,$06,$3C,$3C,$00,$00,$00,$00,$18,$18,$3C,$3C,$66,$66,$7E,$7E,$66,$66,$66,$66,$00,$00,$00,$00,$7C,$7C,$66,$66,$7C,$7C,$66,$66,$66,$66,$7E,$7E,$00,$00,$00,$00,$3C,$3C,$66,$66,$60,$60,$60,$60,$66,$66,$3C,$3C,$00,$00,$00,$00,$7C,$7C,$66,$66,$66,$66,$66,$66,$66,$66,$7C,$7C,$00,$00,$00,$00,$7E,$7E,$60,$60,$7C,$7C,$60,$60,$60,$60,$7E,$7E,$00,$00,$00,$00,$7E,$7E,$60,$60,$7C,$7C,$60,$60,$60,$60,$60,$60,$00,$00,$00,$00,$3C,$3C,$66,$66,$60,$60,$6E,$6E,$66,$66,$3E,$3E,$00,$00,$00,$00,$66,$66,$66,$66,$7E,$7E,$66,$66,$66,$66,$66,$66,$00,$00,$00,$00,$3C,$3C,$18,$18,$18,$18,$18,$18,$18,$18,$3C,$3C,$00,$00,$00,$00,$1E,$1E,$0C,$0C,$0C,$0C,$0C,$0C,$6C,$6C,$38,$38,$00,$00,$00,$00,$66,$66,$6C,$6C,$78,$78,$7C,$7C,$6E,$6E,$66,$66,$00,$00,$00,$00,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$7E,$7E,$00,$00,$00,$00,$62,$62,$76,$76,$7E,$7E,$6A,$6A,$62,$62,$62,$62,$00,$00,$00,$00,$66,$66,$76,$76,$7E,$7E,$6E,$6E,$66,$66,$66,$66,$00,$00,$00,$00,$3C,$3C,$66,$66,$66,$66,$66,$66,$66,$66,$3C,$3C,$00,$00,$00,$00,$7C,$7C,$66,$66,$66,$66,$7C,$7C,$60,$60,$60,$60,$00,$00,$00,$00,$3C,$3C,$66,$66,$66,$66,$7E,$7E,$64,$64,$3A,$3A,$00,$00,$00,$00,$7C,$7C,$66,$66,$66,$66,$7C,$7C,$66,$66,$66,$66,$00,$00,$00,$00,$3C,$3C,$66,$66,$38,$38,$0C,$0C,$66,$66,$3C,$3C,$00,$00,$00,$00,$7E,$7E,$18,$18,$18,$18,$18,$18,$18,$18,$18,$18,$00,$00,$00,$00,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$3C,$3C,$00,$00,$00,$00,$62,$62,$62,$62,$62,$62,$62,$62,$34,$34,$18,$18,$00,$00,$00,$00,$62,$62,$6A,$6A,$6A,$6A,$6A,$6A,$7E,$7E,$34,$34,$00,$00,$00,$00,$62,$62,$74,$74,$38,$38,$1C,$1C,$2E,$2E,$46,$46,$00,$00,$00,$00,$62,$62,$76,$76,$3C,$3C,$18,$18,$18,$18,$18,$18,$00,$00,$00,$00,$7E,$7E,$0C,$0C,$18,$18,$30,$30,$60,$60,$7E,$7E,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$01,$81,$01,$81,$01,$FF,$FF,$FF,$01,$81,$01,$81,$01,$FF,$FF,$FF,$01,$FF,$01,$FF,$01,$FF,$FF,$FF,$01,$FF,$01,$FF,$01,$FF,$FF,$01,$FF,$01,$FF,$01,$FF,$FF,$FF,$01,$FF,$01,$FF,$01,$FF,$FF,$FF,$FF,$01,$81,$01,$81,$01,$FF,$FF,$00,$00,$00,$00,$00,$00,$00,$00,$FF,$01,$FF,$01,$FF,$01,$FF,$FF,$00,$00,$00,$00,$00,$00,$00,$00,$01,$FF,$01,$FF,$01,$FF,$FF,$FF,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$FF,$01,$81,$01,$81,$01,$FF,$FF,$00,$00,$00,$00,$00,$00,$00,$00,$FF,$01,$FF,$01,$FF,$01,$FF,$FF,$00,$00,$00,$00,$00,$00,$00,$00,$01,$FF,$01,$FF,$01,$FF,$FF,$FF,$00,$00,$20,$3C,$80,$FE,$6E,$2A,$FE,$12,$FE,$F6,$38,$44,$00,$00,$00,$00,$00,$00,$44,$44,$28,$28,$10,$10,$28,$28,$44,$44,$00,$00,$01,$FF,$3D,$83,$19,$87,$01,$8F,$19,$9F,$3D,$BF,$7F,$FF,$FF,$FF,$B9,$C7,$B9,$C7,$B9,$C7,$B9,$C7,$B9,$C7,$B9,$C7,$B9,$C7,$B9,$C7,$FF,$FF,$00,$FF,$FF,$00,$FF,$00,$FF,$00,$00,$FF,$00,$FF,$FF,$FF,$00,$00,$00,$00,$3C,$3C,$00,$00,$3C,$3C,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$30,$30,$30,$30,$00,$00,$00,$00,$38,$38,$65,$65,$31,$31,$19,$19,$4D,$4D,$38,$38,$00,$00,$00,$00,$E3,$E3,$96,$96,$86,$86,$86,$86,$96,$96,$E3,$E3,$00,$00,$00,$00,$9E,$9E,$59,$59,$59,$59,$5E,$5E,$5B,$5B,$9B,$9B,$00,$00,$00,$00,$7C,$7C,$60,$60,$78,$78,$60,$60,$60,$60,$7C,$7C,$00,$00,$3E,$3E,$53,$41,$F3,$81,$9E,$8E,$74,$7C,$04,$14,$02,$12,$04,$0C,$7F,$7F,$C0,$FF,$A9,$E0,$AF,$D0,$B7,$C8,$BC,$C7,$BA,$C7,$B9,$C7,$FE,$FE,$03,$FF,$95,$07,$F1,$0F,$E9,$17,$59,$A7,$79,$C7,$B9,$C7,$7E,$66,$C3,$81,$FF,$81,$7E,$7E,$00,$08,$00,$6B,$00,$7F,$00,$1C,$00,$00,$3B,$3B,$6C,$6C,$30,$30,$18,$18,$6C,$6C,$38,$38,$00,$00,$00,$00,$F3,$F3,$C7,$C7,$CC,$CC,$CF,$CF,$CC,$CC,$CC,$CC,$00,$00,$00,$00,$0F,$0F,$99,$99,$D8,$D8,$DB,$DB,$D9,$D9,$CF,$CF,$00,$00,$00,$00,$3E,$3E,$B0,$B0,$3C,$3C,$B0,$B0,$B0,$B0,$BE,$BE,$00,$00,$00,$00,$79,$79,$CD,$CD,$71,$71,$19,$19,$CD,$CD,$79,$79,$00,$00,$00,$00,$F3,$F3,$9B,$9B,$9B,$9B,$F3,$F3,$83,$83,$83,$83,$00,$00,$00,$00,$F3,$F3,$06,$06,$E6,$E6,$06,$06,$06,$06,$F3,$F3,$00,$00,$00,$00,$CF,$CF,$66,$66,$06,$06,$06,$06,$66,$66,$CF,$CF,$00,$00,$00,$00,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$FC,$FC,$00,$00,$10,$08,$38,$04,$FE,$01,$7C,$2A,$3C,$28,$7C,$02,$C6,$39,$82,$41

SECTION "Tile Data Block 2", ROM0[$5B75]

tile_data_block_2:
    db $7F,$7F,$40,$40,$60,$40,$7F,$4F,$7F,$4F,$7F,$4F,$7F,$4F,$7F,$4F,$E0,$E0,$18,$18,$04,$04,$E2,$E2,$F6,$F2,$FF,$F9,$FF,$F9,$FF,$F9,$7F,$4F,$7F,$4F,$7F,$4F,$7F,$4F,$7F,$4F,$7F,$4F,$7F,$4F,$7F,$4F,$7F,$79,$7F,$79,$7F,$79,$7F,$79,$7F,$79,$7F,$79,$7F,$79,$7F,$79,$7F,$5F,$7F,$5F,$7F,$4F,$3F,$2F,$3F,$27,$1F,$10,$0F,$0C,$03,$03,$FF,$FD,$FF,$FD,$FF,$F9,$FE,$FA,$FE,$F2,$FC,$04,$F8,$18,$E0,$E0,$FF,$F9,$FF,$F9,$FF,$F9,$FF,$F9,$FF,$F9,$FF,$F9,$FF,$F9,$FF,$F9,$FF,$FD,$FF,$FD,$FF,$FD,$FF,$FD,$FF,$FD,$FF,$FD,$FF,$FD,$FF,$FD,$7F,$7F,$41,$41,$63,$41,$7F,$5D,$7F,$5D,$7F,$5D,$7F,$5D,$7F,$5D,$7F,$5D,$7F,$5D,$7F,$5D,$7F,$5D,$7F,$5D,$7F,$5D,$7F,$5D,$7F,$5D,$7F,$5D,$7E,$5C,$7C,$5C,$7F,$5F,$7F,$5F,$7F,$5F,$7F,$5F,$7F,$5F,$FF,$FF,$01,$01,$03,$01,$FF,$F9,$FF,$F9,$FF,$F9,$FF,$F9,$FF,$F9,$7F,$5F,$7F,$5F,$7F,$5F,$7F,$5F,$7F,$5F,$7F,$40,$7F,$40,$7F,$7F,$FF,$F9,$FF,$F9,$FF,$F9,$FF,$F9,$FF,$F9,$FF,$01,$FF,$01,$FF,$FF,$03,$03,$0C,$0C,$10,$10,$23,$23,$37,$27,$7F,$4F,$7F,$4F,$7F,$4F,$3F,$27,$3F,$27,$3F,$27,$3F,$27,$3F,$27,$3F,$21,$3F,$21,$3F,$3F,$7F,$4F,$7F,$4F,$7F,$4F,$7F,$4F,$7F,$4F,$7F,$40,$7F,$40,$7F,$7F,$7E,$72,$7E,$72,$7E,$72,$7E,$72,$7E,$72,$7E,$42,$7E,$42,$7E,$7E,$7F,$5D,$7F,$5D,$7F,$5D,$7F,$5D,$7F,$5D,$7F,$41,$7F,$41,$7F,$7F,$7F,$4F,$7F,$4F,$7F,$4F,$7F,$4F,$7F,$4F,$7F,$41,$7F,$41,$7F,$7F,$7F,$79,$7F,$79,$7F,$79,$7F,$79,$7F,$79,$7F,$41,$7F,$41,$7F,$7F,$FF,$FF,$03,$01,$07,$01,$FF,$F9,$FF,$F9,$FF,$F9,$FF,$01,$FF,$FF,$00,$00,$00,$00,$FF,$FF,$03,$01,$07,$01,$FF,$F9,$FF,$F9,$FF,$F9,$FF,$01,$FF,$FF,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$C6,$C6,$E6,$E6,$E6,$E6,$D6,$D6,$CE,$CE,$CE,$CE,$C6,$C6,$00,$00,$C0,$C0,$C0,$C0,$1B,$1B,$DD,$DD,$D9,$D9,$D9,$D9,$D9,$D9,$00,$00,$30,$30,$78,$78,$33,$33,$B6,$B6,$B7,$B7,$B6,$B6,$B3,$B3,$00,$00,$00,$00,$00,$00,$CD,$CD,$6E,$6E,$EC,$EC,$0C,$0C,$EC,$EC,$00,$00,$01,$01,$01,$01,$8F,$8F,$D9,$D9,$D9,$D9,$D9,$D9,$CF,$CF,$00,$00,$80,$80,$80,$80,$9E,$9E,$B3,$B3,$B3,$B3,$B3,$B3,$9E,$9E,$00,$00,$38,$38,$44,$44,$BA,$BA,$A2,$A2,$BA,$BA,$44,$44,$38,$38,$00,$00,$18,$18,$18,$18,$18,$18,$10,$10,$10,$10,$00,$00,$30,$30,$00,$00,$00,$00,$3C,$3C,$FF,$FF,$C3,$FF,$80,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$00,$00,$00,$03,$03,$C3,$C3,$E6,$E7,$36,$F7,$1C,$FF,$0C,$FF,$3C,$3C,$FF,$FF,$C3,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$01,$FF,$00,$00,$80,$80,$C0,$C0,$C0,$C0,$60,$E0,$7F,$FF,$FF,$FF,$80,$FF,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$C0,$C0,$F0,$F0,$06,$07,$06,$07,$07,$07,$03,$03,$03,$03,$01,$01,$00,$00,$00,$00,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$82,$FF,$E7,$FF,$7F,$7F,$06,$FF,$03,$FF,$01,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$C0,$FF,$03,$FF,$02,$FF,$06,$FF,$04,$FF,$00,$FF,$00,$FF,$03,$FF,$3F,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$80,$FF,$C0,$FF,$C0,$FF,$38,$F8,$1C,$FC,$0C,$FC,$06,$FE,$06,$FE,$03,$FF,$03,$FF,$03,$FF,$00,$00,$00,$00,$00,$00,$00,$00,$E0,$E0,$F0,$F0,$B8,$F8,$18,$F8,$00,$00,$00,$00,$00,$00,$00,$00,$03,$03,$0F,$0F,$1F,$1C,$3F,$30,$1F,$1F,$3F,$3F,$1E,$1E,$0C,$0C,$EC,$EC,$FC,$FC,$FE,$1E,$FF,$07,$F9,$FF,$FF,$FF,$3E,$3E,$78,$78,$F8,$F8,$70,$70,$D0,$D0,$D0,$D0,$FF,$FF,$FF,$FF,$3F,$3F,$0F,$0F,$37,$37,$7F,$7F,$7F,$7F,$37,$36,$C0,$FF,$E0,$FF,$FC,$FF,$FF,$F7,$FF,$F1,$FF,$C3,$FF,$03,$FF,$01,$01,$FF,$00,$FF,$00,$FF,$81,$FF,$F1,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$18,$F8,$18,$F8,$B0,$F0,$F0,$F0,$E0,$E0,$80,$80,$C0,$C0,$C0,$C0,$7F,$60,$7F,$60,$FF,$C0,$FF,$C0,$FF,$C0,$FF,$C0,$7F,$60,$7F,$60,$F0,$F0,$F0,$30,$F8,$18,$FC,$0C,$FE,$06,$FF,$01,$FF,$00,$FF,$00,$E3,$E2,$F7,$F6,$FF,$FE,$FF,$FC,$3F,$3C,$FF,$F0,$FF,$00,$FF,$00,$FF,$FF,$FF,$FF,$FF,$7F,$FF,$3F,$FF,$1F,$FF,$1E,$FF,$3E,$FF,$3E,$F0,$F0,$FC,$FC,$FE,$8E,$FE,$02,$FF,$03,$FF,$03,$FF,$03,$FF,$03,$3F,$30,$1F,$1C,$0F,$0E,$1F,$1F,$1F,$1F,$1F,$1F,$0F,$0F,$01,$01,$FF,$00,$FF,$00,$FF,$00,$FF,$E0,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$03,$FF,$07,$FF,$0F,$FF,$FF,$FF,$FF,$FF,$FF,$FD,$FD,$FC,$FC,$FF,$80,$FF,$E0,$FF,$F0,$FF,$F7,$FC,$FC,$E0,$E0,$80,$80,$10,$10,$FF,$1E,$F3,$73,$C0,$C0,$80,$80,$04,$04,$04,$04,$9F,$9F,$84,$84,$FF,$1E,$FF,$8C,$FF,$E4,$3F,$20,$3F,$30,$1F,$13,$1F,$13,$3F,$33,$FF,$03,$FE,$06,$FE,$06,$FE,$0E,$FC,$7C,$F0,$F0,$00,$00,$00,$00,$FC,$FC,$70,$70,$38,$38,$1E,$1E,$07,$07,$03,$03,$00,$00,$00,$00,$F8,$F8,$02,$02,$07,$07,$02,$02,$80,$80,$F0,$F0,$FF,$FF,$3F,$3F,$13,$13,$38,$38,$10,$10,$10,$10,$00,$00,$00,$00,$FF,$FF,$FF,$FF,$E4,$E4,$80,$80,$80,$80,$00,$00,$03,$03,$1F,$1F,$FE,$FE,$F0,$F0,$3E,$26,$7E,$6E,$7C,$5C,$F8,$F8,$E0,$E0,$80,$80,$00,$00,$00,$00,$00,$00,$00,$40,$39,$40,$3D,$41,$0E,$70,$06,$38,$10,$1E,$03,$03,$00,$02,$9C,$82,$3C,$82,$70,$0E,$60,$1C,$08,$78,$C0,$C0,$00,$00,$00,$02,$9C,$82,$3C,$82,$71,$0F,$63,$1F,$0B,$7B,$C7,$C7,$06,$07,$00,$00,$03,$03,$0E,$0E,$18,$18,$30,$30,$60,$60,$C0,$C0,$80,$80,$F8,$F8,$9C,$94,$3F,$27,$7C,$5C,$F0,$B0,$E0,$E6,$80,$87,$C0,$C7,$0F,$0F,$F8,$F8,$80,$86,$00,$06,$00,$30,$00,$36,$00,$36,$00,$B6,$F0,$F0,$00,$01,$00,$03,$00,$D9,$00,$ED,$00,$CD,$00,$CD,$00,$CD,$00,$00,$00,$80,$00,$C0,$00,$9E,$00,$B3,$00,$BF,$00,$B0,$00,$9F,$0F,$0F,$00,$00,$00,$00,$00,$60,$00,$7C,$00,$66,$00,$66,$00,$66,$F0,$F0,$1F,$1F,$01,$01,$00,$0C,$00,$0C,$00,$7C,$00,$CC,$00,$CC,$1F,$1F,$39,$29,$FC,$E4,$3E,$3A,$0F,$0D,$07,$07,$01,$01,$03,$E3,$00,$00,$C0,$C0,$70,$70,$18,$18,$0C,$0C,$06,$06,$03,$03,$01,$01,$C0,$C0,$60,$60,$30,$30,$18,$18,$0C,$0C,$06,$06,$03,$03,$01,$01,$40,$46,$60,$66,$20,$26,$30,$36,$70,$70,$D8,$D8,$8D,$8D,$07,$07,$00,$F6,$00,$76,$00,$30,$01,$01,$0F,$0F,$78,$78,$C0,$C0,$00,$00,$00,$C0,$00,$00,$0F,$0F,$F8,$F8,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$FF,$FF,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$06,$00,$00,$F0,$F0,$1F,$1F,$00,$00,$00,$00,$00,$00,$00,$00,$00,$CD,$00,$7D,$00,$01,$80,$80,$F0,$F0,$1E,$1E,$03,$03,$00,$00,$02,$B2,$06,$B6,$04,$B4,$0C,$EC,$0E,$0E,$1B,$1B,$B1,$B1,$E0,$E0,$03,$03,$06,$06,$0C,$0C,$18,$18,$30,$30,$60,$60,$C0,$C0,$80,$80