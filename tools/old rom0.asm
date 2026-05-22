SECTION "ROM 0 Region", ROM0[$0000]

rst_00_vector:
    jp game_init

header_padding_0003:
    ds 5, $FF

rst_08_vector:
    rst rst_38_crash

header_padding_0009:
    ds 7, $FF

rst_10_vector:
    rst rst_38_crash

header_padding_0011:
    ds 7, $FF

rst_18_vector:
    rst rst_38_crash

header_padding_0019:
    ds 7, $FF

rst_20_vector:
    rst rst_38_crash

header_padding_0021:
    ds 7, $FF

rst_28_vector:
    rst rst_38_crash

header_padding_0029:
    ds 7, $FF

rst_30_vector:
    rst rst_38_crash

header_padding_0031:
    ds 7, $FF

rst_38_crash:
    rst rst_38_crash

header_padding_0039:
    ds 7, $FF

vblank_vector:
    jp vblank_handler

header_padding_0043:
    ds 5, $FF

lcd_stat_vector:
    jp lcd_stat_handler

header_padding_004b:
    ds 5, $FF

timer_vector:
    jp enable_interrupts

header_padding_0053:
    ds 5, $FF

serial_vector:
    jp serial_falling_edge_detector_bit7

header_padding_005b:
    ds 5, $FF

joypad_vector:
    reti

header_padding_0061:
    ds 159, $FF

cartridge_header:   ; Entry Point
    nop
    jp game_init

.nintendo_logo:
    db $CE,$ED,$66,$66,$CC,$0D,$00,$0B,$03,$73,$00,$83,$00,$0C,$00,$0D,$00,$08,$11,$1F,$88,$89,$00,$0E,$DC,$CC,$6E,$E6,$DD,$DD,$D9,$99,$BB,$BB,$67,$63,$6E,$0E,$EC,$CC,$DD,$DC,$99,$9F,$BB,$B9,$33,$3E

.game_title

    ; title_block

    db $41,$4C,$4C,$45  ; 'A', 'L', 'L', 'E',
    db $59,$20,$57,$41  ; 'Y', ' ', 'W', 'A',
    db $59,$00,$00,$00  ; 'Y'
    db $00,$00,$00,$00  ; 
    
    db $00, $00         ; new_licensee_code
    db $00              ; sgb_flag
    db $00              ; cartridge_type
    db $00              ; rom_size
    db $00              ; ram_size
    db $00              ; region
    db $01              ; old_licensee_code
    db $00              ; mask_rom_version
    db $5E              ; header_checksum
    dw $D19E            ; global_checksum

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
    call fill_tile_map_0                         
    call fill_tile_map_1
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

; sets up the joypad read, serial_phase_counter, DMA, OAM update,
; audio update and vblank flag: all functions that need to be 
; read while Interrupts are disabled.

vblank_handler:
    push af
    push bc
    push de
    push hl
    call joypad_read
    ld a, $2
    ldh [h_serial_phase_counter], a 
    ld a, $81
    ldh [rSC], a  
    call h_oam_dma_routine                      
    call oam_buffer_update                      
    ldh a, [h_lcdc_mirror] 
    ldh [rLCDC], a 
    ldh a, [h_lcdc_negative]                
    ldh [rSCX], a
    ldh a, [h_debug_scroll_x_init]          
    ldh [rSCY], a
    call audio_update_thunk
    ldh a, [h_game_tick]   
    inc a
    ldh [h_game_tick], a 
    ld a, $1
    ldh [h_vblank_flag], a 
    pop hl
    pop de
    pop bc
    pop af
    reti

wait_vblank:
    ld a, $0
    ldh [h_vblank_flag], a 

.Lab_0225:
    halt
    ldh a, [h_vblank_flag] 
    cp $0
    jr z,  .Lab_0225
    ret
   ; safety ret for game states $0D-$0F

interrupt_enable:
    ldh a, [h_joypad_pressed]               
    ldh [rIE], a
    ei
    ret

disable_interrupts_save:
    ldh a, [rIE]
    ldh [h_joypad_pressed], a    
    ld a, $0
    ldh [rIE], a
    di
    ret

check_object_dirty_flag:
    ldh a, [h_object_dirty_flag]            
    cp $0
    ret z
    jr wait_vblank

lcd_ppu_enable:
    ldh a, [h_lcdc_mirror] 
    and $7F
    or $80
    ldh [h_lcdc_mirror], a 
    ldh [rLCDC], a 
    ret

lcd_disable_and_wait_vblank:
    ldh a, [h_lcdc_mirror] 
    and $7F
    ldh [h_lcdc_mirror], a 
    jr wait_vblank
                 
wait_frames:    ; waits 10 VBlanks before LAB_0df3ing
    push af
    call wait_vblank
    pop af
    dec a
    jr nz, wait_frames
    ret

lcd_stat_handler:
    push af
    push bc
    push de
    push hl
    call lcd_stat_work                          
    ldh a, [rIF]             
    and $FD
    ldh [rIF], a  
    pop hl
    pop de
    pop bc
    pop af
    reti

;-------------------------------------------------------------               
;                   ! REAL HARDWARE ONLY !
; serial_falling_edge_detector_bit7
;-------------------------------------------------------------    
; 2-phase serial sampler using internal clock
; compares consecutive SB reads and latches a filtered 1 -> 0 =
; transition on bit 7 into FF93 (used as a rare, =
; hardware-derived init condition)
;-------------------------------------------------------------                          

serial_falling_edge_detector_bit7:
    push af
    push bc
    ldh a, [h_serial_phase_counter]   ; alternates between 2 and 1
    dec a
    ldh [h_serial_phase_counter], a 
    jr nz, .update_serial_sample
    ; IF serial_phase_counter = 0
    ldh a, [h_serial_prev_sample]           
    ld b, a
    ldh a, [rSB]             
    ldh [h_serial_prev_sample], a
    ld c, a
    xor b
    xor $FF
    or c
    ldh [h_serial_falling_edge_latch], a                   
    pop bc
    pop af
    reti
    ; IF serial_phase_counter = 1

.update_serial_sample
    ldh a, [rSB]             
    ldh [h_serial_sample_curr], a
    ld a, $81
    ldh [rSC], a  ; SC 1000 0001: transfer enable, internal clock
    pop bc
    pop af
    reti

; constantly fill the serial transfer data with ones
; this, in turn, fills the the register with $FF

serial_init:
    ld a, $1
    ldh [rSB], a  
    ld hl, $FFFF    ; Interrupt Enable Register
    set $3,[hl]     ; 0000 0100: Serial interrupt handler enabled
    ret

oam_buffer_update: 
    ldh a, [h_object_dirty_flag]            
    cp $0
    jr z, .cancel_oam_buffer_update
    ld de, $C901
    call is_oam_buffer_empty
    xor a
    ld [w_bg_map_buffer_pad], a    
    ld [w_tile_buffer + $00], a
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

is_oam_buffer_empty:
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

fill_tile_map_0: 
    ld hl, $9800
    jr Lab_0360

; Fill tile_map_1 with $FF tiles

fill_tile_map_1:
    ld hl, $9C00

Lab_0360:
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

clear_main_oam_buffer:
    ld b, $A0
    ld a, $0
    ld hl, $C800    ; [hl] = w_oam_buffer

Lab_0373:
    ld [hl+], a    ; =>[w_oam_buffer], a    
    dec b
    jr nz, Lab_0373
    ret

; clears the OAM buffer of the explosion

clear_anim_oam_buffer:
    ld b, $18
    ld a, $0
    ld hl, $C888
    jr Lab_0373

; loads all the visual assets of ROM Bank 01 into the 3 VRAM tile blocks

load_tile_data:
    ld hl, $5B75
    ld de, $9000
    ld bc, $800

.load_tile_data_block_2
    ld a, [hl+] ; =>[tile_data_block_2]
    ld [de], a ; =>[vram_tile_block_2], a     
    inc de
    dec bc
    ld a, b
    or c
    jr nz, .load_tile_data_block_2
    ld hl, $5375
    ld de, $8800
    ld bc, $800

.load_tile_data_block_1  
    ld a, [hl+] ; [tile_data_block_1]
    ld [de], a  ; =>[vram_tile_block_1], a     
    inc de
    dec bc
    ld a, b
    or c
    jr nz, .load_tile_data_block_1
    ld hl, $4b75
    ld de, $8000
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

joypad_read:
    ld a, $20
    ldh [rP1], a  
    ldh a, [rP1]             
    ldh a, [rP1]             
    ldh a, [rP1]             
    ldh a, [rP1]             

.Lab_03cd
    ldh a, [rP1]             
    ldh a, [rP1]             
    ldh a, [rP1]             
    ldh a, [rP1]             
    ldh a, [rP1]             
    ldh a, [rP1]             
    and $F
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
    ldh a, [rP1]             
    and $F
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
    set $7, a
    jr .Lab_040d

.Lab_041d
    res $7,c
    jr .Lab_040d

.Lab_0421
    set $7,C
    jp .Lab_040d

nop_handler:
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    ret

debug_update_vblank:
    ldh a, [rIE]
    and $FE ; 1111 1110: VBlank disable

update_interrupt_enable_register:
    ldh [rIE], a
    ret

debug_enable_vblank:
    ldh a, [rIE]
    or $1   ; set bit 0 of IE register: VBlank enable
    jr update_interrupt_enable_register

enable_interrupts:
    reti
                   
multiply:   ; BC = B * E
    push af
    push hl
    ld hl, $0
    ld c, $0
    srl b
    rr c
    ld a, $8

.Lab_0461
    sla E
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
    sub $A
    ldh [h_score_digit_ones], a  
    jr nc, .set_score_digit_ones

.carry_tens_flag
    ldh a, [h_score_digit_ones]             
    add $A
    ldh [h_score_digit_ones], a  
    ldh [h_score_digit_ones], a  
    ld a, b
    ldh [h_score_digit_tens], a  
    ret

; Advances a hidden frame accumulator
; Adds $41 per frame via 5 iterations of +$0D.

update_frame_accumulator:
    ld b, $5
    ldh a, [h_frame_accumulator]  ; starts at $00

.increment_frame_accumulator
    add $D
    dec b
    jr nz, .increment_frame_accumulator
    ldh [h_frame_accumulator], a  ; clear ffa1
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
    ld hl, $54C
    add hl, bc
    ld a, [hl+] ; =>[game_state_jump_table_lo] -> low nibble
    ld b, a
    ld h, [hl]  ; =>[game_state_jump_table_hi] -> high nibble
    ld l, b

.state_dispatcher
    jp hl

; ----------------------------------------------
; 16 x 16-bit addresses, little endian             
; ----------------------------------------------
; [1] state $00    boot init               $056C    
; [2] state $01    game init               $0578    
; [3] state $02    title screen            $0582    
; [4] state $03    load demo stage         $0613    
; [5] state $04    load stage              $06A2    
; [6] state $05    standby play            $0773    
; [7] state $06    normal play             $07A4    
; [8] state $07    lose life               $07d3    
; [9] state $08    stage clear             $0805    
; [10] state $09   win                     $0839    
; [11] state $0A   bonus state handler     $19F7    
; [12] state $0B   game over/respawn check $08D1    
; [13] state $0C   pause                   $0907    
; [14-16] $0D-$0F  null handler            $022C    
; ----------------------------------------------
                   
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
init_boot_init:
    ld a, $C8
    ldh [h_top_score_lo], a
    xor a
    ldh [h_top_score_hi], a
    ld a, $1
    ldh [h_game_state], a
    ret

init_game_init:
    ld a, $4
    ld [w_title_demo_cycle_index], a    
    ld a, $2
    ldh [h_game_state], a
    ret

init_title_screen:
    call lcd_disable_and_wait_vblank
    call disable_interrupts_save
    ldh a, [h_joypad_pressed]               
    and $FD
    ldh [h_joypad_pressed], a    
    call fill_tile_map_0
    call clear_main_oam_buffer 
    ld de, $41CD
    call is_oam_buffer_empty
    call load_title_screen_score_buffer_oam
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

init_load_demo:
    call set_demo_flag
    call level_load_handler

.Lab_0619
    call update_frame_accumulator

    and $1F
    ld [w_true_stage_number], a

    ld b, a
    ld e, $3
    call multiply

    ld hl, $1BE1
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
    ld a, [w_true_stage_number] ; =>[w_true_stage_number]
    ld b, a
    ld e, $3
    call multiply
    ld hl, $1BE1
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
    ld a, [w_true_stage_number]   ; =>[w_true_stage_number]
    call load_level_brick_data
    call count_level_bricks
    call init_scroll_x_table
    xor a
    ldh a, [h_brick_scroll_flag]            
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
    call clear_main_oam_buffer
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

; ball phases through and increase the bonus level number

bonus_ball_set:
    ld a, $1
    ldh [h_ball_phase_through], a
    ld a, [w_bonus_stage_number]  
    inc a
    ld [w_bonus_stage_number], a
    ret

; triggers upon losing in a bonus level       

increment_stage_number_display:
    ld a, [w_stage_number_display]
    inc a
    ld [w_stage_number_display], a
    ret

; set if the stage number displayed's value's bit 6 is se... *

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

load_track_5_and_wait:
    call load_track_stage_complete
    ld a, $90
    jp wait_frames  ; wait 144 frames

; checks if the player has reached the last level  
; if so, load the win animation/screen and set the player back to level 0

game_win_handler:
    ld a, [w_true_stage_number]
    inc a
    cp $20
    jr c, .load_next_true_stage_number
    ld a, $0

.load_next_true_stage_number
    ld [w_true_stage_number], a   ; if stage number < 32
    ret

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

; when the players wins the game, the screens fades out and in to show the "win" screen.
; shifts bitwise data for the color indices in BGP, OBP0 and OBP1 at the same time.

load_fade_in_data:
    ld hl, $8C2
    jr set_counter

game_win_fade_handler:
    ld hl, $8C6 ; load_fade_out_data

set_counter:
    ld b, $4

.Lab_08b1
    ld a, [hl+] ; =>palette_fade_out_data
    call set_palette_data
    push bc
    push hl
    ld a, $10
    call wait_frames    ; wait 10 frames
    pop hl
    pop bc
    dec b
    jr nz, .Lab_08b1
    ret

palette_fade_in_data:
    db $00,$40,$90,$E4

palette_fade_out_data:
    db $E4,$90,$40,$00

set_palette_data:
    ldh [rBGP], a
    ldh [rOBP0], a 
    ldh [rOBP1], a 
    ret

init_game_over:
    call mario_game_over_handler
    ld a, $40
    call wait_frames    ; 64 frames
    call lcd_disable_and_wait_vblank
    call disable_interrupts_save
    call fill_tile_map_0
    call clear_main_oam_buffer
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
    call clear_main_oam_buffer
    call update_score_oam_buffer
    call debug_ball_velocity
    call load_wall_oam_buffer
    call load_track_pause
    ld a, $6
    ldh [h_game_state], a   
    ret

; Loads the level's brick layout from a ROM pointer table into WRAM
; ($C000 = brick types, w_object_state_array = hit states).
; It also calculates h_total_row_count and
; lcd_y_descent_counter (rows that are off-screen above).

load_level_brick_data:
    ld b, a
    ld e, $3
    call multiply
    ld hl, $1BE1
    add hl, bc
    inc hl
    ld e, [hl]
    inc hl
    ld d, [hl]
    push de
    call clear_objects_wram0
    call bricks_slide_in_from_top
    pop de
    ld hl, $C000
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
    ld hl, $1B87
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

; clears the WRAM memory where the bricks' type and state... *
clear_objects_wram0:
    ld hl, $C000
    ld de, $C400
    ld bc, $348

.Lab_098c
    ld a, $0
    ld [hl+], a ; [hl]  ; =>BYTE_C000
    ld [de], a  ; (de)=>w_object_state_array
    inc de
    dec bc
    ld a, b
    or c
    jr nz, .Lab_098c
    ret

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
    ld hl, $C000    
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
    ld bc, $C000
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
    ld hl, $1B87
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

brick_collision_handler:
    call check_object_dirty_flag
    ldh a, [h_play_area_scroll_y]           
    srl a
    ld b, a
    ld e, $20
    call multiply
    ld hl, $9821
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
    ld hl, $C000
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
    ld hl, $1B87
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

; executed each frame during gameplay, even when the level doesn't scroll

scroll_x_handler:
    ldh a, [h_scrolling_x_stage_flag]       
    cp $0
    ret z
    ld hl, $CA00
    ld de, $CA14
    ld bc, $CA28
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

lcd_stat_work:
    ldh a, [h_brick_scroll_flag]            
    ld c, a
    inc a
    cp $15  ; counter = 20
    jr nc, .lcd_stat_reset

    ldh [h_brick_scroll_flag], a 
    sla a
    sla a
    ld b, $7
    add b

    ldh [rLYC], a
    ld b, $0
    ld hl, $CA00
    add hl, bc
    ld a, [hl]  ; =>[w_scroll_x_table]
    ldh [rSCX], a
    xor a
    cp c
    ret nz

    ld a, [w_lcd_y]               
    ldh [rSCY], a
    ret

.lcd_stat_reset
    xor a
    ldh [h_brick_scroll_flag], a 
    ld b, $7
    add b
    ldh [rLYC], a
    ld a, [w_lcd_y_vblank]        
    ldh [rSCY], a
    xor a
    ldh [rSCX], a
    ret

; on level load, sets up the origin of the 20 4px scrollables rows all at x = 0

init_scroll_x_table:
    ld a, $0
    ldh [h_lcdc_negative], a     
    ld hl, $CA00
    ld b, $14   ; counter = 20

.copy_next_row_origin
    ld [hl+], a ; => [w_scroll_x_table] set the bg origin
    dec b
    jr nz, .copy_next_row_origin
    xor a
    ldh [h_debug_scroll_x_init], a  

; executes on level load and bricks falling down
; set the LCD viewport's y origin to lcd_y_descent_counter * 4
; there's some code modifying the LCD's position during vblank 
; if the descent counter is <15, but this value is never reached
; during regular gameplay.

update_lcd_y:
    ldh a, [h_lcd_y_descent_counter]        
    sla a
    sla a   ; brick_fall_counter * 4
    add $0  ; useless, maybe old code remnant
    ld [w_lcd_y], a    
    ld b, $70
    ldh a, [h_lcd_y_descent_counter]        
    cp $15
    jr c, .update_lcd_y_vblank   ; normally never happens during normal gameplay
    ld b, $B0

.update_lcd_y_vblank
    ld a, b
    ld [w_lcd_y_vblank], a    ; = $70 always
    ret

lcd_y_handler:
    ldh a, [h_lcd_y_descent_counter]        
    cp $0
    ret z
    dec a
    ldh [h_lcd_y_descent_counter], a
    call load_track_brick_scrolldown    ; play brick scrolldown sfx
    call update_lcd_y
    call load_next_brick_line_obj
    ldh a, [h_lcd_y_descent_counter]        
    cp $0
    ret z
    dec a
    ret z
    ld b, a
    and $1
    ret z
    ld a, b
    ldh [h_play_area_scroll_y], a
    call brick_collision_handler
    ldh a, [h_play_area_scroll_y]           
    add $16
    ldh [h_play_area_scroll_y], a
    jp brick_collision_handler
                         
; executes when bricks "fall down"
; updates brick count based on obj state values from $C000 and $C400
; checks the whole line of bricks and updates obj data accordingly
; clears the level if there are no bricks left

load_next_brick_line_obj:
    ldh a, [h_lcd_y_descent_counter]    ; the counter is decremented before being loaded here
    add $14
    ld b, a
    ld e, $E
    call multiply
    ld hl, $C000
    add hl, bc
    ld a, $E    ; = 14 (counter), so 14 bricks in a line

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

.level_clear
    ld a, $8
    ldh [h_game_state], a

.decrement_loop_counter 
    pop hl
    inc hl
    pop af
    dec a
    jr nz, .check_brick_presence
    ret

; adds brick score to player_score, caps at $FFff  
add_brick_score_to_player_score:
    dec a   ; A = brick type collision - 1
    ld b, a
    ld e, $6
    call multiply   ; bc = A x 6
    ld hl, $1B87
    add hl, bc      ; hl +0, +$6, +$C or +$12
    ld b, $0
    ld c, $3
    add hl, bc
    ld a, [hl]  ; [hl]  ; =>brick_data_table[0][3]): hl +$3, +$9, +$F or +$15
    swap a
    and $F
    ld b, a
    ldh a, [h_player_score_lo]              
    add b
    ldh [h_player_score_lo], a   
    ldh a, [h_player_score_hi]              
    adc $0
    ldh [h_player_score_hi], a   
    ret nc
    xor a   ; cancel score addition: score cap
    dec a
    ldh [h_player_score_hi], a  ; = $FF
    ldh [h_player_score_lo], a  ; = $FF
    ret

; updates the current player score
; if the top score is achieved, the top score will
; update in sync with the player score

update_score_all:
    ld bc, $FFCC
    ld hl, $FFCA
    ldh a, [c]  ; =>h_top_score_lo   
    sub [hl]    ; =>h_player_score_lo
    push af
    inc c
    inc hl      ; =>h_player_score_hi   
    pop af
    ldh a, [c]  ; =>h_top_score_hi   
    sbc [hl]    ; =>h_player_score_hi
    ret nc
; IF SCORE > TOP
    ld a, [hl]  ; =>h_player_score_hi
    ldh [c], a  ; =>h_top_score_hi
    dec c
    dec hl    ; =>h_player_score_lo   
    ld a, [hl]  ; =>h_player_score_lo             
    ldh [c], a  ; =>h_top_score_lo, a 
    ret

extra_life_score_handler:
    ld hl, $FFCA
    ldh a, [h_extra_life_score_threshold_lo]
    sub [hl]    ; [hl]  ; =>h_player_score_lo
    push af
    inc hl      ; [hl] =>h_player_score_hi   
    pop af
    ldh a, [h_extra_life_score_threshold_hi]
    sbc [hl]    ; [hl]  ; =>h_player_score_hi
    ret nc
; IF SCORE >= MULTIPLE OF 1000
    ld a, [w_life_counter]   ; =>[w_life_counter]        
    cp $9
    jr nc, .Lab_0c8c
; IF life < 10
    inc a
    ld [w_life_counter], a      
    call set_event_extra_life

.Lab_0c8c 
    call load_lives_number_vram

set_next_extra_life_score_threshold:
    ldh a, [h_extra_life_gained_total]      
    sla a
    ld c, a
    ld b, $0
    ld hl, $1b5d
    add hl, bc
    ld a, [hl+] ; =>extra_life_threshold_table
    ldh [h_extra_life_score_threshold_hi], a               
    ld a, [hl]  ; =>extra_life_threshold_table[1]
    ldh [h_extra_life_score_threshold_lo], a               
    ldh a, [h_extra_life_gained_total]      
    inc a
    ldh [h_extra_life_gained_total], a                     
    ret

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

; On hit: aligns to tile boundary, negates Y velocity.       *
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

    cp $3c
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
    ld hl, $CA00
    add hl, bc
    ld a, [HL]  ; =>[w_scroll_x_table]
    sub $0
    ld b, a
    ldh a, [h_prev_ball_x] 
    sub $10     ; 10px left
    add b       ; if the level doesn't scroll x, then B = 0
    cp $70      ; two tiles left from the right wall
    jr c, .LAB_0e12    ; if left of x threshold, jp
    sub $70

.LAB_0e12
    srl a
    srl a
    srl a   ; (prev_ball_x - 10)/8
    ldh [h_brick_probe_x], a     
    ldh a, [h_play_area_scroll_y]           
    ld b, a
    ld e, $E
    call multiply
    ldh a, [h_brick_probe_x]                
    ld l, a
    ld h, $0
    add hl, bc
    ld bc, $C000
    add hl, bc
    ld a, [hl]  ; =>BYTE_C000       
    cp $0
    ret z
    ldh [h_brick_type_last_hit], a  
    push hl
    call brick_type_velocity_handler
    pop hl
    ld d,h
    ld e,l
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
    ld [DE], a
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
; IF NO REMAINING BRICKS:
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
; UNUSED CODE
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
; IF BALL_Y IS NOT A MULTIPLE OF 4:
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
; IF BALL_Y IS NOT A MULTIPLE OF 4:
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

; -------------------------------------------------
; brick_type_velocity_handler
; -------------------------------------------------
; On ball collision with any brick, checks the velocity
; data associated with it through the fifth data entry
; in the brick's data at $1B87.
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
    ld hl, $1B87
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

; most likely a scrapped game mechanic that incremented the ball's velocity each time the player hit 8 bricks

unused_ball_velocity_brick_collision_handler:
    ldh a, [h_unused_brick_collision_count] 
    inc a
    cp $8
    jr c, .update_brick_collision_count
    call increment_ball_velocity
    call update_ball_velocity_on_brick_collision
    xor a

.update_brick_collision_count
    ldh [h_unused_brick_collision_count], a                
    ret

increment_ball_velocity:
    ldh a, [h_ball_velocity]                
    inc a
    cp $1A
    jr c, .update_ball_velocity
    ld a, $3    ; ball_velocity is never >= $1A so it's an unused check

.update_ball_velocity 
    ldh [h_ball_velocity], a     
    jp debug_ball_velocity  ; ret right after

update_ball_position:
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

negate_bc:
    ld a, b
    xor $FF
    ld b, a
    ld a, c
    xor $FF
    ld c, a
    inc bc
    ret

update_ball_velocity_on_brick_collision:
    ld b, $0
    ldh a, [h_ball_velocity]                
    dec a
    sla a
    ld c, a
    ld hl, $11EE
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
    ld hl, $100B
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

BYTE_ARRAY_100b:
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
    add b           ; right: +$18
                    ; left: +$E8
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
    ld hl, $11EE
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
    cp $F   ; left wall
    jr nc, .update_paddle_x
    ld a, $F    ; IF PADDLE is touching left wall
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

; NOT EMULATED
.update_serial_sample 
    ldh a, [h_paddle_collision_width]      
    ld b, a
    ld a, $7F
    sub b       ; $7F - $10 or $7F - $18
    ld b, a     ; B = $6F or $67
    ldh a, [h_serial_sample_curr]           
    sub $30
    jr c, LAB_10f0

; Bounds clamp: ensures paddle stays within
; [$0F, $7F - paddle_collision_width].
; Called as a utility from paddle movement code.

clamp_paddle_x:
    cp $F   ; A = paddle_x
    jr nc, LAB_10f4
; IF PADDLE_X < $F

LAB_10f0:
    ld a, $F
    jr update_paddle_clamp_x

; IF PADDLE_X >= $F

LAB_10f4:
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
    ld a, $18
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
    ld hl, $11EE
    add hl, bc  ; +4, +8, +12
    ld a, [hl+] ; =>ball_velocity_ptr_table
    ld c, a
    ld a, [hl]  ; =>ball_velocity_ptr_table[1]
    ld b, a
    pop af
    push af
    ld d, $0
    ld e, a
    ld hl, $1B41
    ldh a, [h_paddle_size] 
    cp $0
    jr z, .LAB_1135
    ld hl, $1B51

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
    cp $0
    jr z, .LAB_115a
    ld d, $6

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
    jr nz, LAB_118c
    call lcd_y_handler

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
    jr LAB_118c

.LAB_1181
    ld c, a
    ld b, $0
    inc a
    ldh [h_lcd_y_offset_counter], a 
    ld hl, $1b7d
    add hl, bc  ; offset = how many times the bricks have scrolled down
    ld a, [hl]  ; =>paddle_hit_max_value_table

LAB_118c:
    ldh [h_paddle_hit_counter], a
    ret

update_paddle_oam_buffer:
    ld hl, OAM_PADDLE_START

    ldh a, [h_paddle_size] 
    cp $0
    jr nz, .LAB_11C3

; IF PADDLE SIZE NORMAL

    ldh a, [h_init_paddle_y]
    ld [hl+], a    ; OAM_PADDLE_START + $00 (sprite 0: Y)

    ldh a, [h_paddle_x]
    add $1
    ld [hl+], a    ; OAM_PADDLE_START + $01 (sprite 0: X)

    ld a, $0
    ld [hl+], a    ; OAM_PADDLE_START + $02 (tile)

    ld a, $0
    ld [hl+], a    ; OAM_PADDLE_START + $03 (attr)

    ldh a, [h_init_paddle_y]
    ld [hl+], a    ; OAM_PADDLE_START + $04 (sprite 1: Y)

    ldh a, [h_paddle_x]
    add $9
    ld [hl+], a    ; OAM_PADDLE_START + $05 (sprite 1: X)

    ld a, $1
    ld [hl+], a    ; OAM_PADDLE_START + $06 (tile)

    ld a, $0
    ld [hl+], a    ; OAM_PADDLE_START + $07 (attr)

    ldh a, [h_init_paddle_y]
    ld [hl+], a    ; OAM_PADDLE_START + $08 (sprite 2: Y)

    ldh a, [h_paddle_x]
    add $11
    ld [hl+], a    ; OAM_PADDLE_START + $09 (sprite 2: X)

    ld a, $0
    ld [hl+], a    ; OAM_PADDLE_START + $0A (tile)

    ld a, $20
    ld [hl+], a    ; OAM_PADDLE_START + $0B (attr)

    ret

; IF PADDLE SIZE SMALL
.LAB_11C3 
    ldh a, [h_init_paddle_y]                
    ld [hl+], a    ; OAM_PADDLE_START + $00 (sprite 0: Y)

    ldh a, [h_paddle_x]    
    add $1
    ld [hl+], a    ; OAM_PADDLE_START + $01 (sprite 0: X) 

    ld a, $0
    ld [hl+], a    ; OAM_PADDLE_START + $02 (tile)

    ld a, $0
    ld [hl+], a    ; OAM_PADDLE_START + $03 (attr)

    ldh a, [h_init_paddle_y]                
    ld [hl+], a    ; OAM_PADDLE_START + $04 (sprite 1: Y)

    ldh a, [h_paddle_x]    
    add $9
    ld [hl+], a    ; OAM_PADDLE_START + $05 (sprite 1: X)

    ld a, $0
    ld [hl+], a    ; OAM_PADDLE_START + $06 (tile)

    ld a, $20
    ld [hl+], a    ; OAM_PADDLE_START + $07 (attr)

    ldh a, [h_init_paddle_y]                
    ld [hl+], a    ; OAM_PADDLE_START + $08 (sprite 2: Y)

    ldh a, [h_paddle_x]    
    add $5
    ld [hl+], a    ; OAM_PADDLE_START + $09 (sprite 2: X)

    ld a, $1
    ld [hl+], a    ; OAM_PADDLE_START + $0A (tile)

    ld a, $0
    ld [hl+], a    ; OAM_PADDLE_START + $0B (attr)

    ret

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
; entry index = launch angle (0=horizontal, 18=vertical, ... *
; each entry: Y_velocity_hi, Y_velocity_lo, X_velocity_hi... *
; ----------------------------------- 
; 25 blocks × 19 angles × 4 bytes
; only blocks 1-3 accessed (ball_velocity 3, 5, 7) 
; blocks 4-24 ($1350-$1988) are never accessed     
; ~1672 bytes of unused ROM      
; -----------------------------------

ball_angle_speed_table:
    db $00,$00,$01,$00,$00,$16,$00,$FF,$00,$2C,$00,$FC,$00,$42,$00,$F7,$00,$58,$00,$F1,$00,$6C,$00,$E8,$00,$80,$00,$DE,$00,$93,$00,$D2,$00,$A5,$00,$C4,$00,$B5,$00,$B5,$00,$C4,$00,$A5,$00,$D2,$00,$93,$00,$DE,$00,$80,$00,$E8,$00,$6C,$00,$F1,$00,$58,$00,$F7,$00,$42,$00,$FC,$00,$2C,$00,$FF,$00,$16,$01,$00,$00,$00,$00,$00,$01,$20,$00,$19,$01,$1F,$00,$32,$01,$1C,$00,$4B,$01,$16,$00,$63,$01,$0F,$00,$7A,$01,$05,$00,$90,$00,$F9,$00,$A5,$00,$EC,$00,$B9,$00,$DD,$00,$CC,$00,$CC,$00,$DD,$00,$B9,$00,$EC,$00,$A5,$00,$F9,$00,$90,$01,$05,$00,$7A,$01,$0F,$00,$63,$01,$16,$00,$4B,$01,$1C,$00,$32,$01,$1F,$00,$19,$01,$20,$00,$00,$00,$00,$01,$40,$00,$1C,$01,$3F,$00,$38,$01,$3B,$00,$53,$01,$35,$00,$6D,$01,$2D,$00,$87,$01,$22,$00,$A0,$01,$15,$00,$B8,$01,$06,$00,$CE,$00,$F5,$00,$E2,$00,$E2,$00,$F5,$00,$CE,$01,$06,$00,$B8,$01,$15,$00,$A0,$01,$22,$00,$87,$01,$2D,$00,$6D,$01,$35,$00,$53,$01,$3B,$00,$38,$01,$3F,$00,$1C,$01,$40,$00,$00,$00,$00,$01,$60,$00,$1F,$01,$5F,$00,$3D,$01,$5B,$00,$5B,$01,$54,$00,$78,$01,$4B,$00,$95,$01,$3F,$00,$B0,$01,$31,$00,$CA,$01,$20,$00,$E2,$01,$0E,$00,$F9,$00,$F9,$01,$0E,$00,$E2,$01,$20,$00,$CA,$01,$31,$00,$B0,$01,$3F,$00,$95,$01,$4B,$00,$78,$01,$54,$00,$5B,$01,$5B,$00,$3D,$01,$5F,$00,$1F,$01,$60,$00,$00,$00,$00,$01,$80,$00,$21,$01,$7F,$00,$43,$01,$7A,$00,$63,$01,$73,$00,$83,$01,$69,$00,$A2,$01,$5C,$00,$C0,$01,$4D,$00,$DC,$01,$3B,$00,$F7,$01,$26,$01,$10,$01,$10,$01,$26,$00,$F7,$01,$3B,$00,$DC,$01,$4D,$00,$C0,$01,$5C,$00,$A2,$01,$69,$00,$83,$01,$73,$00,$63,$01,$7A,$00,$43,$01,$7F,$00,$21,$01,$80,$00,$00,$00,$00,$01,$A0,$00,$24,$01,$9E,$00,$48,$01,$9A,$00,$6C,$01,$92,$00,$8E,$01,$87,$00,$B0,$01,$79,$00,$D0,$01,$68,$00,$EF,$01,$55,$01,$0B,$01,$3F,$01,$26,$01,$26,$01,$3F,$01,$0B,$01,$55,$00,$EF,$01,$68,$00,$D0,$01,$79,$00,$B0,$01,$87,$00,$8E,$01,$92,$00,$6C,$01,$9A,$00,$48,$01,$9E,$00,$24,$01,$A0,$00,$00,$00,$00,$01,$C0,$00,$27,$01,$BE,$00,$4E,$01,$B9,$00,$74,$01,$B1,$00,$99,$01,$A5,$00,$BD,$01,$96,$00,$E0,$01,$84,$01,$01,$01,$6F,$01,$20,$01,$57,$01,$3D,$01,$3D,$01,$57,$01,$20,$01,$6F,$01,$01,$01,$84,$00,$E0,$01,$96,$00,$BD,$01,$A5,$00,$99,$01,$B1,$00,$74,$01,$B9,$00,$4E,$01,$BE,$00,$27,$01,$C0,$00,$00,$00,$00,$01,$E0,$00,$2A,$01,$DE,$00,$53,$01,$D9,$00,$7C,$01,$D0,$00,$A4,$01,$C3,$00,$CB,$01,$B3,$00,$F0,$01,$A0,$01,$13,$01,$89,$01,$35,$01,$70,$01,$53,$01,$53,$01,$70,$01,$35,$01,$89,$01,$13,$01,$A0,$00,$F0,$01,$B3,$00,$CB,$01,$C3,$00,$A4,$01,$D0,$00,$7C,$01,$D9,$00,$53,$01,$DE,$00,$2A,$01,$E0,$00,$00,$00,$00,$02,$00,$00,$2D,$01,$FE,$00,$59,$01,$F8,$00,$85,$01,$EF,$00,$AF,$01,$E1,$00,$D8,$01,$D0,$01,$00,$01,$BB,$01,$26,$01,$A3,$01,$49,$01,$88,$01,$6A,$01,$6A,$01,$88,$01,$49,$01,$A3,$01,$26,$01,$BB,$01,$00,$01,$D0,$00,$D8,$01,$E1,$00,$AF,$01,$EF,$00,$85,$01,$F8,$00,$59,$01,$FE,$00,$2D,$02,$00,$00,$00,$00,$00,$02,$20,$00,$2F,$02,$1E,$00,$5E,$02,$18,$00,$8D,$02,$0D,$00,$BA,$01,$FF,$00,$E6,$01,$ED,$01,$10,$01,$D7,$01,$38,$01,$BE,$01,$5E,$01,$A1,$01,$81,$01,$81,$01,$A1,$01,$5E,$01,$BE,$01,$38,$01,$D7,$01,$10,$01,$ED,$00,$E6,$01,$FF,$00,$BA,$02,$0D,$00,$8D,$02,$18,$00,$5E,$02,$1E,$00,$2F,$02,$20,$00,$00,$00,$00,$02,$40,$00,$32,$02,$3E,$00,$64,$02,$37,$00,$95,$02,$2C,$00,$C5,$02,$1D,$00,$F3,$02,$0A,$01,$20,$01,$F3,$01,$4A,$01,$D8,$01,$72,$01,$B9,$01,$97,$01,$97,$01,$B9,$01,$72,$01,$D8,$01,$4A,$01,$F3,$01,$20,$02,$0A,$00,$F3,$02,$1D,$00,$C5,$02,$2C,$00,$95,$02,$37,$00,$64,$02,$3E,$00,$32,$02,$40,$00,$00,$00,$00,$02,$60,$00,$35,$02,$5E,$00,$6A,$02,$57,$00,$9D,$02,$4B,$00,$D0,$02,$3B,$01,$01,$02,$27,$01,$30,$02,$0F,$01,$5D,$01,$F2,$01,$87,$01,$D2,$01,$AE,$01,$AE,$01,$D2,$01,$87,$01,$F2,$01,$5D,$02,$0F,$01,$30,$02,$27,$01,$01,$02,$3B,$00,$D0,$02,$4B,$00,$9D,$02,$57,$00,$6A,$02,$5E,$00,$35,$02,$60,$00,$00,$00,$00,$02,$80,$00,$38,$02,$7E,$00,$6F,$02,$76,$00,$A6,$02,$6A,$00,$DB,$02,$59,$01,$0E,$02,$44,$01,$40,$02,$2A,$01,$6F,$02,$0C,$01,$9B,$01,$EA,$01,$C5,$01,$C5,$01,$EA,$01,$9B,$02,$0C,$01,$6F,$02,$2A,$01,$40,$02,$44,$01,$0E,$02,$59,$00,$DB,$02,$6A,$00,$A6,$02,$76,$00,$6F,$02,$7E,$00,$38,$02,$80,$00,$00,$00,$00,$02,$A0,$00,$3B,$02,$9D,$00,$75,$02,$96,$00,$AE,$02,$89,$00,$E6,$02,$77,$01,$1C,$02,$61,$01,$50,$02,$46,$01,$81,$02,$26,$01,$B0,$02,$03,$01,$DB,$01,$DB,$02,$03,$01,$B0,$02,$26,$01,$81,$02,$46,$01,$50,$02,$61,$01,$1C,$02,$77,$00,$E6,$02,$89,$00,$AE,$02,$96,$00,$75,$02,$9D,$00,$3B,$02,$A0,$00,$00,$00,$00,$02,$C0,$00,$3D,$02,$BD,$00,$7A,$02,$B5,$00,$B6,$02,$A8,$00,$F1,$02,$96,$01,$2A,$02,$7E,$01,$60,$02,$62,$01,$94,$02,$41,$01,$C5,$02,$1B,$01,$F2,$01,$F2,$02,$1B,$01,$C5,$02,$41,$01,$94,$02,$62,$01,$60,$02,$7E,$01,$2A,$02,$96,$00,$F1,$02,$A8,$00,$B6,$02,$B5,$00,$7A,$02,$BD,$00,$3D,$02,$C0,$00,$00,$00,$00,$02,$E0,$00,$40,$02,$DD,$00,$80,$02,$D5,$00,$BE,$02,$C7,$00,$FC,$02,$B4,$01,$37,$02,$9B,$01,$70,$02,$7D,$01,$A6,$02,$5B,$01,$D9,$02,$34,$02,$08,$02,$08,$02,$34,$01,$D9,$02,$5B,$01,$A6,$02,$7D,$01,$70,$02,$9B,$01,$37,$02,$B4,$00,$FC,$02,$C7,$00,$BE,$02,$D5,$00,$80,$02,$DD,$00,$40,$02,$E0,$00,$00,$00,$00,$03,$00,$00,$43,$02,$FD,$00,$85,$02,$F4,$00,$C7,$02,$E6,$01,$07,$02,$D2,$01,$45,$02,$B8,$01,$80,$02,$99,$01,$B9,$02,$75,$01,$EE,$02,$4C,$02,$1F,$02,$1F,$02,$4C,$01,$EE,$02,$75,$01,$B9,$02,$99,$01,$80,$02,$B8,$01,$45,$02,$D2,$01,$07,$02,$E6,$00,$C7,$02,$F4,$00,$85,$02,$FD,$00,$43,$03,$00,$00,$00,$00,$00,$03,$20,$00,$46,$03,$1D,$00,$8B,$03,$14,$00,$CF,$03,$05,$01,$12,$02,$F0,$01,$52,$02,$D5,$01,$90,$02,$B5,$01,$CB,$02,$8F,$02,$02,$02,$65,$02,$36,$02,$36,$02,$65,$02,$02,$02,$8F,$01,$CB,$02,$B5,$01,$90,$02,$D5,$01,$52,$02,$F0,$01,$12,$03,$05,$00,$CF,$03,$14,$00,$8B,$03,$1D,$00,$46,$03,$20,$00,$00,$00,$00,$03,$40,$00,$49,$03,$3D,$00,$90,$03,$33,$00,$D7,$03,$24,$01,$1D,$03,$0E,$01,$60,$02,$F2,$01,$A0,$02,$D1,$01,$DD,$02,$AA,$02,$17,$02,$7D,$02,$4C,$02,$4C,$02,$7D,$02,$17,$02,$AA,$01,$DD,$02,$D1,$01,$A0,$02,$F2,$01,$60,$03,$0E,$01,$1D,$03,$24,$00,$D7,$03,$33,$00,$90,$03,$3D,$00,$49,$03,$40,$00,$00,$00,$00,$03,$60,$00,$4B,$03,$5D,$00,$96,$03,$53,$00,$E0,$03,$43,$01,$28,$03,$2C,$01,$6D,$03,$0F,$01,$B0,$02,$EC,$01,$F0,$02,$C4,$02,$2B,$02,$96,$02,$63,$02,$63,$02,$96,$02,$2B,$02,$C4,$01,$F0,$02,$EC,$01,$B0,$03,$0F,$01,$6D,$03,$2C,$01,$28,$03,$43,$00,$E0,$03,$53,$00,$96,$03,$5D,$00,$4B,$03,$60,$00,$00,$00,$00,$03,$80,$00,$4E,$03,$7D,$00,$9C,$03,$72,$00,$E8,$03,$61,$01,$32,$03,$4A,$01,$7B,$03,$2C,$01,$C0,$03,$08,$02,$02,$02,$DE,$02,$40,$02,$AE,$02,$7A,$02,$7A,$02,$AE,$02,$40,$02,$DE,$02,$02,$03,$08,$01,$C0,$03,$2C,$01,$7B,$03,$4A,$01,$32,$03,$61,$00,$E8,$03,$72,$00,$9C,$03,$7D,$00,$4E,$03,$80,$00,$00,$00,$00,$03,$A0,$00,$51,$03,$9C,$00,$A1,$03,$92,$00,$F0,$03,$80,$01,$3D,$03,$68,$01,$88,$03,$49,$01,$D0,$03,$24,$02,$14,$02,$F8,$02,$55,$02,$C7,$02,$90,$02,$90,$02,$C7,$02,$55,$02,$F8,$02,$14,$03,$24,$01,$D0,$03,$49,$01,$88,$03,$68,$01,$3D,$03,$80,$00,$F0,$03,$92,$00,$A1,$03,$9C,$00,$51,$03,$A0,$00,$00,$00,$00,$03,$C0,$00,$54,$03,$BC,$00,$A7,$03,$B1,$00,$F8,$03,$9F,$01,$48,$03,$86,$01,$96,$03,$66,$01,$E0,$03,$3F,$02,$27,$03,$12,$02,$69,$02,$DF,$02,$A7,$02,$A7,$02,$DF,$02,$69,$03,$12,$02,$27,$03,$3F,$01,$E0,$03,$66,$01,$96,$03,$86,$01,$48,$03,$9F,$00,$F8,$03,$B1,$00,$A7,$03,$BC,$00,$54,$03,$C0,$00,$00,$00,$00,$03,$E0,$00,$56,$03,$DC,$00,$AC,$03,$D1,$01,$01,$03,$BE,$01,$53,$03,$A4,$01,$A3,$03,$83,$01,$F0,$03,$5B,$02,$39,$03,$2D,$02,$7E,$02,$F8,$02,$BD,$02,$BD,$02,$F8,$02,$7E,$03,$2D,$02,$39,$03,$5B,$01,$F0,$03,$83,$01,$A3,$03,$A4,$01,$53,$03,$BE,$01,$01,$03,$D1,$00,$AC,$03,$DC,$00,$56,$03,$E0,$00,$00,$00,$00,$04,$00,$00,$59,$03,$FC,$00,$B2,$03,$F0,$01,$09,$03,$DD,$01,$5E,$03,$C2,$01,$B1,$03,$A0,$02,$00,$03,$77,$02,$4B,$03,$47,$02,$92,$03,$10,$02,$D4,$02,$D4,$03,$10,$02,$92,$03,$47,$02,$4B,$03,$77,$02,$00,$03,$A0,$01,$B1,$03,$C2,$01,$5E,$03,$DD,$01,$09,$03,$F0,$00,$B2,$03,$FC,$00,$59,$04,$00,$00,$00

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

set_lose_state:
    ld a, $7
    ldh [h_game_state], a
    ret

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
; stage time at $1B71.
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
    ld hl, $1B71
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
    inc hl  ; base: $1B71
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
    cp $0
    jr nz, .add_10_points
    ld a, c
    cp $0
    ret z
    cp $A
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
    ld c, $A
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

; loads the "SPECIAL BONUS" and "PTS." text when a bonus stage is won
; the two tile sets are offset, 2 addresses are used

load_special_bonus_text_vram:
    call check_object_dirty_flag
    ld hl, $1AAF
    ld de, $C901    ; [de] = w_tile_buffer
    ld b, $17       ; counter = 23

.copy_next_tile 
    ld a, [hl+] ; =>special_bonus_text_tile_data
    ld [de], a  ; w_tile_buffer + $00, a     
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

pts._text_tile_data:
    db $9B,$69,$04,$99,$9D,$9C,$B7,$00

; clears the "SPECIAL BONUS" and "PTS." text when a bonus stage is won
; the two tile sets are offset, 2 addresses are used

clear_special_bonus_text_vram:
    call check_object_dirty_flag
    ld hl, $1ADE
    ld de, $C901    ; [de] = w_tile_buffer
    ld b, $17       ; counter = 23
.copy_next_tile
    ld a, [hl+] ; =>clear_special_bonus_text_tile_data
    ld [de], a ; w_tile_buffer + $00, a     
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
    ld hl, $1B0D
    ld de, $C901    ; [de] = w_tile_buffer
    ld b, $E

.LAB_1b00
    ld a, [hl+]     ; =>try_again_tile_vram_data
    ld [de], a      ; w_tile_buffer + $00, a     
    inc de
    dec b
    jr nz, .LAB_1b00
    ld a, $1
    ldh [h_object_dirty_flag], a 
    jp wait_vblank

; VRAM address: $99C3            
; Number of tiles: 10            
; Loads the TRY AGAIN! text at the end of the Win sequence   *

try_again_tile_vram_data:
    db $99,$C3,$0A,$9D,$9B,$A2,$FF,$8A,$90,$8A,$92,$97,$1F,$00

; Removes TRY AGAIN! text with FF tiles            

clear_try_again_vram:
    call check_object_dirty_flag
    ld hl, $1B33
    ld de, $C901    ; [de] = w_tile_buffer
    ld b, $E

.LAB_1b26
    ld a, [hl+]     ; =>clear_try_again_tile_vram_data -> copy from $C901 to $C90D
    ld [de], a      ; w_tile_buffer + $00, a     
    inc de
    dec b
    jr nz, .LAB_1b26
    ld a, $1
    ldh [h_object_dirty_flag], a 
    jp wait_vblank
                         
; VRAM address: $99C3            
; Number of tiles: 10            
; Clears the TRY AGAIN! text with FF tiles         

clear_try_again_tile_vram_data:
    db $99,$C3,$0A,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$00

paddle_0_angle_steepness_data:
    db $03,$06,$06,$06
    db $09,$09,$09,$09
    db $09,$09,$09,$09
    db $06,$06,$06,$03

paddle_1_angle_steepness_data:
    db $03,$06,$06,$09
    db $09,$09,$09,$09
    db $09,$06,$06,$03

; 10 16-bit addresses            
; When extra_life_value increments, the score updates in ... *

extra_life_threshold_table:
    db $03,$E8,$07,$D0,$0B,$B8,$0F,$A0,$13,$88,$17,$70,$1B,$58,$1F,$40,$23,$28,$FF,$FF

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
; data containing each amount of paddle hits before the b... *
; for each scrolldown, the amount of paddle hits is decre... *
; after 10 times, the value is just set to 1 -> bricks sc... *

paddle_hit_max_value_table:
    db $08,$08,$05,$05,$03,$03,$02,$02,$02,$02
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

unknown_rom_data:
    db $00,$00,$00,$11,$00,$00,$00,$00,$00,$11,$00,$00,$00,$00,$00,$11,$00,$00,$00,$00,$00,$11,$00,$00,$00,$00,$00,$11,$00,$00,$00,$00,$00,$11,$00,$00,$00,$00,$00,$11,$00,$00,$00,$00,$00,$11,$00,$00,$00,$00,$00,$11,$00,$00,$00,$00,$00,$11,$00,$00,$00,$00,$00,$11,$00,$00,$00,$44,$1C,$40,$44,$1C,$00,$F4,$23,$80,$7C,$35,$02,$09,$1D,$41,$09,$1D,$00,$25,$26,$80,$95,$36,$00,$CE,$1D,$42,$CE,$1D,$00,$56,$28,$80,$AE,$37,$00,$E7,$1E,$43,$E7,$1E,$00,$87,$2A,$80,$C7,$38,$00,$C8,$1F,$44,$C8,$1F,$00,$B8,$2C,$80,$E0,$39,$00,$C5,$20,$45,$C5,$20,$00,$E9,$2E,$80,$F9,$3A,$00,$DE,$21,$46,$DE,$21,$00,$1A,$31,$80,$12,$3C,$00,$F7,$22,$47,$F7,$22,$00,$4B,$33,$80,$2B,$3D,$00,$44,$1C,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$00,$00,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$00,$00,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$00,$00,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$00,$00,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$00,$00,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$00,$00,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$FF,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$FF,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$03,$00,$03,$00,$03,$00,$03,$00,$03,$00,$03,$00,$03,$00,$03,$00,$03,$00,$03,$00,$03,$00,$03,$00,$03,$00,$03,$00,$00,$03,$00,$03,$00,$03,$00,$03,$00,$03,$00,$03,$00,$03,$00,$03,$00,$03,$00,$03,$00,$03,$00,$03,$00,$03,$00,$03,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$FF,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$03,$03,$03,$03,$04,$03,$03,$03,$03,$04,$03,$03,$03,$03,$03,$03,$03,$03,$04,$03,$03,$03,$03,$04,$03,$03,$03,$03,$00,$00,$00,$00,$04,$00,$00,$00,$00,$04,$00,$00,$00,$00,$00,$00,$00,$00,$04,$00,$00,$00,$00,$04,$00,$00,$00,$00,$02,$02,$02,$02,$04,$02,$02,$02,$02,$04,$02,$02,$02,$02,$02,$02,$02,$02,$04,$02,$02,$02,$02,$04,$02,$02,$02,$02,$00,$00,$00,$00,$04,$00,$00,$00,$00,$04,$00,$00,$00,$00,$00,$00,$00,$00,$04,$00,$00,$00,$00,$04,$00,$00,$00,$00,$01,$01,$01,$01,$04,$01,$01,$01,$01,$04,$01,$01,$01,$01,$01,$01,$01,$01,$04,$01,$01,$01,$01,$04,$01,$01,$01,$01,$01,$01,$01,$01,$04,$01,$01,$01,$01,$04,$01,$01,$01,$01,$00,$00,$00,$00,$04,$00,$00,$00,$00,$04,$00,$00,$00,$00,$FF,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$03,$00,$00,$00,$00,$00,$03,$03,$00,$00,$00,$00,$00,$03,$03,$03,$00,$00,$00,$03,$03,$03,$03,$00,$00,$00,$03,$03,$00,$03,$03,$00,$03,$03,$00,$00,$03,$03,$00,$03,$03,$00,$00,$00,$03,$03,$03,$00,$00,$00,$00,$03,$03,$03,$00,$00,$00,$00,$00,$03,$00,$00,$00,$00,$00,$00,$03,$00,$00,$00,$02,$00,$00,$00,$00,$00,$02,$02,$00,$00,$00,$00,$00,$02,$02,$02,$00,$00,$00,$02,$02,$02,$02,$00,$00,$00,$02,$02,$00,$02,$02,$00,$02,$02,$00,$00,$02,$02,$00,$02,$02,$00,$00,$00,$02,$02,$02,$00,$00,$00,$00,$02,$02,$02,$00,$00,$00,$00,$00,$02,$00,$00,$00,$00,$00,$00,$02,$00,$00,$00,$01,$00,$00,$00,$00,$00,$01,$01,$00,$00,$00,$00,$00,$01,$01,$01,$00,$00,$00,$01,$01,$01,$01,$00,$00,$00,$01,$01,$01,$01,$01,$00,$01,$01,$01,$01,$01,$01,$00,$01,$01,$01,$00,$01,$01,$01,$01,$01,$00,$00,$01,$01,$01,$01,$01,$00,$00,$00,$01,$01,$01,$00,$00,$00,$00,$01,$01,$01,$00,$00,$00,$00,$00,$01,$00,$00,$00,$00,$00,$00,$01,$00,$00,$00,$FF,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$02,$02,$02,$02,$02,$02,$02,$00,$00,$00,$00,$00,$00,$00,$02,$02,$02,$02,$02,$02,$02,$00,$00,$00,$00,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$00,$00,$00,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$00,$00,$00,$00,$00,$01,$01,$03,$01,$01,$03,$03,$03,$03,$00,$00,$00,$00,$00,$01,$01,$03,$01,$01,$03,$03,$03,$03,$00,$00,$00,$01,$01,$01,$01,$01,$01,$01,$03,$01,$01,$03,$03,$00,$00,$01,$01,$01,$01,$01,$01,$01,$03,$01,$01,$03,$03,$00,$00,$01,$01,$01,$01,$03,$01,$03,$03,$01,$01,$03,$03,$00,$00,$01,$01,$01,$01,$03,$01,$03,$03,$01,$01,$03,$03,$00,$00,$00,$03,$03,$03,$03,$03,$01,$01,$01,$03,$03,$03,$00,$00,$00,$03,$03,$03,$03,$03,$01,$01,$01,$03,$03,$03,$00,$00,$00,$00,$01,$01,$01,$01,$01,$01,$03,$03,$03,$00,$00,$00,$00,$00,$01,$01,$01,$01,$01,$01,$03,$03,$03,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$04,$04,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$04,$04,$04,$04,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$04,$04,$FF,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$04,$04,$00,$00,$04,$04,$00,$00,$04,$04,$00,$00,$04,$04,$04,$04,$00,$00,$04,$04,$00,$00,$04,$04,$00,$00,$04,$04,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$FF,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$02,$02,$02,$04,$04,$04,$02,$02,$04,$04,$04,$02,$02,$02,$02,$02,$02,$04,$04,$04,$02,$02,$04,$04,$04,$02,$02,$02,$02,$02,$04,$04,$02,$02,$02,$02,$02,$02,$04,$04,$02,$02,$02,$02,$04,$04,$02,$02,$02,$02,$02,$02,$04,$04,$02,$02,$00,$00,$04,$00,$00,$00,$00,$00,$00,$00,$00,$04,$00,$00,$00,$00,$04,$00,$00,$00,$00,$00,$00,$00,$00,$04,$00,$00,$01,$01,$04,$01,$01,$01,$01,$01,$01,$01,$01,$04,$01,$01,$01,$01,$04,$01,$01,$01,$01,$01,$01,$01,$01,$04,$01,$01,$01,$01,$04,$04,$01,$01,$01,$01,$01,$01,$04,$04,$01,$01,$01,$01,$04,$04,$01,$01,$01,$01,$01,$01,$04,$04,$01,$01,$00,$00,$00,$04,$04,$04,$00,$00,$04,$04,$04,$00,$00,$00,$00,$00,$00,$04,$04,$04,$00,$00,$04,$04,$04,$00,$00,$00,$FF,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$00,$00,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$00,$00,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$00,$00,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$00,$00,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$00,$00,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$00,$00,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$FF,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$FF,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$03,$00,$03,$00,$03,$00,$03,$00,$03,$00,$03,$00,$03,$00,$03,$00,$03,$00,$03,$00,$03,$00,$03,$00,$03,$00,$03,$00,$00,$03,$00,$03,$00,$03,$00,$03,$00,$03,$00,$03,$00,$03,$00,$03,$00,$03,$00,$03,$00,$03,$00,$03,$00,$03,$00,$03,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$03,$00,$03,$00,$03,$00,$03,$00,$03,$00,$03,$00,$03,$00,$03,$00,$03,$00,$03,$00,$03,$00,$03,$00,$03,$00,$03,$03,$00,$03,$00,$03,$00,$03,$00,$03,$00,$03,$00,$03,$00,$03,$00,$03,$00,$03,$00,$03,$00,$03,$00,$03,$00,$03,$00,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$FF,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$03,$03,$03,$03,$04,$03,$03,$03,$03,$04,$03,$03,$03,$03,$03,$03,$03,$03,$04,$03,$03,$03,$03,$04,$03,$03,$03,$03,$00,$00,$00,$00,$04,$00,$00,$00,$00,$04,$00,$00,$00,$00,$00,$00,$00,$00,$04,$00,$00,$00,$00,$04,$00,$00,$00,$00,$02,$02,$02,$02,$04,$02,$02,$02,$02,$04,$02,$02,$02,$02,$02,$02,$02,$02,$04,$02,$02,$02,$02,$04,$02,$02,$02,$02,$00,$00,$00,$00,$04,$00,$00,$00,$00,$04,$00,$00,$00,$00,$00,$00,$00,$00,$04,$00,$00,$00,$00,$04,$00,$00,$00,$00,$01,$01,$01,$01,$04,$01,$01,$01,$01,$04,$01,$01,$01,$01,$01,$01,$01,$01,$04,$01,$01,$01,$01,$04,$01,$01,$01,$01,$01,$01,$01,$01,$04,$01,$01,$01,$01,$04,$01,$01,$01,$01,$00,$00,$00,$00,$04,$00,$00,$00,$00,$04,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$03,$03,$03,$03,$04,$03,$03,$03,$03,$04,$03,$03,$03,$03,$03,$03,$03,$03,$04,$03,$03,$03,$03,$04,$03,$03,$03,$03,$00,$00,$00,$00,$04,$00,$00,$00,$00,$04,$00,$00,$00,$00,$00,$00,$00,$00,$04,$00,$00,$00,$00,$04,$00,$00,$00,$00,$02,$02,$02,$02,$04,$02,$02,$02,$02,$04,$02,$02,$02,$02,$02,$02,$02,$02,$04,$02,$02,$02,$02,$04,$02,$02,$02,$02,$00,$00,$00,$00,$04,$00,$00,$00,$00,$04,$00,$00,$00,$00,$00,$00,$00,$00,$04,$00,$00,$00,$00,$04,$00,$00,$00,$00,$01,$01,$01,$01,$04,$01,$01,$01,$01,$04,$01,$01,$01,$01,$01,$01,$01,$01,$04,$01,$01,$01,$01,$04,$01,$01,$01,$01,$01,$01,$01,$01,$04,$01,$01,$01,$01,$04,$01,$01,$01,$01,$00,$00,$00,$00,$04,$00,$00,$00,$00,$04,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$FF,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$03,$00,$00,$00,$00,$00,$03,$03,$00,$00,$00,$00,$00,$03,$03,$03,$00,$00,$00,$03,$03,$03,$03,$00,$00,$00,$03,$03,$00,$03,$03,$00,$03,$03,$00,$00,$03,$03,$00,$03,$03,$00,$00,$00,$03,$03,$03,$00,$00,$00,$00,$03,$03,$03,$00,$00,$00,$00,$00,$03,$00,$00,$00,$00,$00,$00,$03,$00,$00,$00,$02,$00,$00,$00,$00,$00,$02,$02,$00,$00,$00,$00,$00,$02,$02,$02,$00,$00,$00,$02,$02,$02,$02,$00,$00,$00,$02,$02,$00,$02,$02,$00,$02,$02,$00,$00,$02,$02,$00,$02,$02,$00,$00,$00,$02,$02,$02,$00,$00,$00,$00,$02,$02,$02,$00,$00,$00,$00,$00,$02,$00,$00,$00,$00,$00,$00,$02,$00,$00,$00,$01,$00,$00,$00,$00,$00,$01,$01,$00,$00,$00,$00,$00,$01,$01,$01,$00,$00,$00,$01,$01,$01,$01,$00,$00,$00,$01,$01,$01,$01,$01,$00,$01,$01,$01,$01,$01,$01,$00,$01,$01,$01,$00,$01,$01,$01,$01,$01,$00,$00,$01,$01,$01,$01,$01,$00,$00,$00,$01,$01,$01,$00,$00,$00,$00,$01,$01,$01,$00,$00,$00,$00,$00,$01,$00,$00,$00,$00,$00,$00,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$03,$00,$00,$00,$00,$00,$03,$03,$00,$00,$00,$00,$00,$03,$03,$03,$00,$00,$00,$03,$03,$03,$03,$00,$00,$00,$03,$03,$00,$03,$03,$00,$03,$03,$00,$00,$03,$03,$00,$03,$03,$00,$00,$00,$03,$03,$03,$00,$00,$00,$00,$03,$03,$03,$00,$00,$00,$00,$00,$03,$00,$00,$00,$00,$00,$00,$03,$00,$00,$00,$02,$00,$00,$00,$00,$00,$02,$02,$00,$00,$00,$00,$00,$02,$02,$02,$00,$00,$00,$02,$02,$02,$02,$00,$00,$00,$02,$02,$00,$02,$02,$00,$02,$02,$00,$00,$02,$02,$00,$02,$02,$00,$00,$00,$02,$02,$02,$00,$00,$00,$00,$02,$02,$02,$00,$00,$00,$00,$00,$02,$00,$00,$00,$00,$00,$00,$02,$00,$00,$00,$01,$00,$00,$00,$00,$00,$01,$01,$00,$00,$00,$00,$00,$01,$01,$01,$00,$00,$00,$01,$01,$01,$01,$00,$00,$00,$01,$01,$01,$01,$01,$00,$01,$01,$01,$01,$01,$01,$00,$01,$01,$01,$00,$01,$01,$01,$01,$01,$00,$00,$01,$01,$01,$01,$01,$00,$00,$00,$01,$01,$01,$00,$00,$00,$00,$01,$01,$01,$00,$00,$00,$00,$00,$01,$00,$00,$00,$00,$00,$00,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$FF,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$02,$02,$02,$02,$02,$02,$02,$00,$00,$00,$00,$00,$00,$00,$02,$02,$02,$02,$02,$02,$02,$00,$00,$00,$00,$00,$00,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$00,$00,$00,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$00,$00,$00,$03,$03,$03,$03,$01,$01,$03,$01,$01,$00,$00,$00,$00,$00,$03,$03,$03,$03,$01,$01,$03,$01,$01,$00,$00,$00,$00,$03,$03,$01,$01,$03,$01,$01,$01,$01,$01,$01,$01,$00,$00,$03,$03,$01,$01,$03,$01,$01,$01,$01,$01,$01,$01,$00,$00,$03,$03,$01,$01,$03,$03,$01,$03,$01,$01,$01,$01,$00,$00,$03,$03,$01,$01,$03,$03,$01,$03,$01,$01,$01,$01,$00,$00,$03,$03,$03,$01,$01,$01,$03,$03,$03,$03,$03,$00,$00,$00,$03,$03,$03,$01,$01,$01,$03,$03,$03,$03,$03,$00,$00,$00,$00,$03,$03,$03,$01,$01,$01,$01,$01,$01,$00,$00,$00,$00,$00,$03,$03,$03,$01,$01,$01,$01,$01,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$04,$04,$04,$04,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$04,$04,$04,$04,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$02,$02,$02,$02,$02,$02,$02,$00,$00,$00,$00,$00,$00,$00,$02,$02,$02,$02,$02,$02,$02,$00,$00,$00,$00,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$00,$00,$00,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$00,$00,$00,$00,$00,$01,$01,$03,$01,$01,$03,$03,$03,$03,$00,$00,$00,$00,$00,$01,$01,$03,$01,$01,$03,$03,$03,$03,$00,$00,$00,$01,$01,$01,$01,$01,$01,$01,$03,$01,$01,$03,$03,$00,$00,$01,$01,$01,$01,$01,$01,$01,$03,$01,$01,$03,$03,$00,$00,$01,$01,$01,$01,$03,$01,$03,$03,$01,$01,$03,$03,$00,$00,$01,$01,$01,$01,$03,$01,$03,$03,$01,$01,$03,$03,$00,$00,$00,$03,$03,$03,$03,$03,$01,$01,$01,$03,$03,$03,$00,$00,$00,$03,$03,$03,$03,$03,$01,$01,$01,$03,$03,$03,$00,$00,$00,$00,$01,$01,$01,$01,$01,$01,$03,$03,$03,$00,$00,$00,$00,$00,$01,$01,$01,$01,$01,$01,$03,$03,$03,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$04,$04,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$04,$04,$04,$04,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$04,$04,$FF,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$04,$04,$00,$00,$04,$04,$00,$00,$04,$04,$00,$00,$04,$04,$04,$04,$00,$00,$04,$04,$00,$00,$04,$04,$00,$00,$04,$04,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$04,$04,$00,$00,$04,$04,$00,$00,$04,$04,$00,$00,$00,$00,$04,$04,$00,$00,$04,$04,$00,$00,$04,$04,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$04,$04,$00,$00,$04,$04,$00,$00,$04,$04,$00,$00,$04,$04,$04,$04,$00,$00,$04,$04,$00,$00,$04,$04,$00,$00,$04,$04,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$FF,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$03,$03,$04,$04,$04,$03,$03,$03,$03,$04,$04,$04,$03,$03,$03,$03,$04,$04,$04,$03,$03,$03,$03,$04,$04,$04,$03,$03,$00,$00,$00,$00,$04,$04,$00,$00,$04,$04,$00,$00,$00,$00,$00,$00,$00,$00,$04,$04,$00,$00,$04,$04,$00,$00,$00,$00,$02,$02,$02,$02,$02,$04,$02,$02,$04,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$04,$02,$02,$04,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$04,$02,$02,$04,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$04,$02,$02,$04,$02,$02,$02,$02,$02,$00,$00,$00,$00,$00,$04,$00,$00,$04,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$04,$00,$00,$04,$00,$00,$00,$00,$00,$01,$01,$01,$01,$04,$04,$01,$01,$04,$04,$01,$01,$01,$01,$01,$01,$01,$01,$04,$04,$01,$01,$04,$04,$01,$01,$01,$01,$01,$01,$04,$04,$04,$01,$01,$01,$01,$04,$04,$04,$01,$01,$01,$01,$04,$04,$04,$01,$01,$01,$01,$04,$04,$04,$01,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$02,$02,$02,$04,$04,$04,$02,$02,$04,$04,$04,$02,$02,$02,$02,$02,$02,$04,$04,$04,$02,$02,$04,$04,$04,$02,$02,$02,$02,$02,$04,$04,$02,$02,$02,$02,$02,$02,$04,$04,$02,$02,$02,$02,$04,$04,$02,$02,$02,$02,$02,$02,$04,$04,$02,$02,$00,$00,$04,$00,$00,$00,$00,$00,$00,$00,$00,$04,$00,$00,$00,$00,$04,$00,$00,$00,$00,$00,$00,$00,$00,$04,$00,$00,$01,$01,$04,$01,$01,$01,$01,$01,$01,$01,$01,$04,$01,$01,$01,$01,$04,$01,$01,$01,$01,$01,$01,$01,$01,$04,$01,$01,$01,$01,$04,$04,$01,$01,$01,$01,$01,$01,$04,$04,$01,$01,$01,$01,$04,$04,$01,$01,$01,$01,$01,$01,$04,$04,$01,$01,$00,$00,$00,$04,$04,$04,$00,$00,$04,$04,$04,$00,$00,$00,$00,$00,$00,$04,$04,$04,$00,$00,$04,$04,$04,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$FF,$00,$00,$00,$00,$02,$02,$02,$02,$02,$02,$00,$00,$00,$00,$00,$00,$02,$02,$02,$02,$02,$02,$02,$02,$00,$00,$00,$00,$00,$00,$00,$00,$01,$03,$01,$03,$03,$03,$00,$00,$00,$00,$00,$00,$00,$01,$01,$03,$01,$03,$03,$03,$03,$00,$00,$00,$00,$00,$01,$01,$01,$01,$01,$03,$01,$03,$03,$00,$00,$00,$00,$00,$01,$01,$01,$01,$01,$03,$01,$03,$03,$00,$00,$00,$00,$00,$03,$03,$03,$03,$03,$01,$01,$03,$03,$00,$00,$00,$00,$00,$00,$03,$03,$03,$03,$01,$01,$03,$00,$00,$00,$00,$00,$00,$00,$01,$01,$01,$01,$01,$03,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$01,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$02,$03,$02,$02,$03,$02,$02,$00,$00,$00,$00,$00,$00,$02,$02,$03,$02,$02,$03,$02,$02,$02,$00,$00,$00,$00,$01,$01,$03,$01,$03,$03,$01,$03,$02,$01,$01,$00,$00,$00,$01,$01,$03,$01,$03,$03,$01,$03,$02,$01,$01,$00,$00,$00,$01,$03,$03,$03,$03,$03,$03,$03,$03,$01,$01,$00,$00,$00,$01,$03,$03,$03,$03,$03,$03,$03,$03,$01,$01,$00,$00,$00,$00,$03,$03,$03,$03,$00,$03,$03,$03,$03,$00,$00,$00,$00,$00,$03,$03,$03,$00,$00,$00,$03,$03,$03,$00,$00,$00,$00,$02,$02,$02,$02,$00,$00,$00,$02,$02,$02,$02,$00,$00,$00,$02,$02,$02,$02,$00,$00,$00,$02,$02,$02,$02,$00,$00,$FF,$00,$01,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$03,$01,$02,$00,$00,$00,$03,$03,$03,$00,$00,$00,$00,$02,$03,$01,$02,$00,$00,$03,$03,$03,$03,$03,$00,$00,$00,$02,$01,$01,$02,$02,$00,$03,$01,$03,$03,$03,$00,$00,$00,$02,$01,$01,$02,$02,$03,$03,$01,$03,$03,$03,$03,$00,$00,$02,$02,$02,$02,$02,$03,$03,$03,$03,$03,$03,$03,$00,$00,$02,$00,$02,$02,$02,$03,$03,$03,$03,$03,$03,$03,$00,$00,$02,$00,$02,$02,$00,$03,$03,$03,$03,$03,$03,$03,$00,$00,$00,$00,$02,$02,$00,$03,$03,$03,$03,$03,$03,$03,$00,$00,$00,$02,$02,$02,$01,$03,$03,$03,$03,$03,$03,$03,$00,$00,$00,$02,$00,$02,$01,$03,$03,$03,$03,$03,$03,$03,$00,$00,$00,$00,$00,$02,$02,$01,$03,$03,$03,$03,$03,$01,$00,$00,$00,$00,$00,$00,$02,$01,$03,$03,$03,$03,$03,$01,$02,$00,$00,$00,$00,$00,$00,$02,$01,$01,$01,$01,$01,$00,$02,$00,$00,$00,$00,$00,$00,$02,$01,$01,$01,$01,$01,$00,$00,$02,$00,$00,$00,$00,$02,$02,$02,$00,$00,$02,$02,$02,$00,$00,$00,$00,$00,$02,$02,$02,$02,$00,$00,$02,$02,$02,$00,$00,$00,$00,$01,$02,$02,$02,$00,$00,$00,$00,$02,$02,$01,$00,$00,$00,$01,$02,$02,$00,$00,$00,$00,$00,$02,$02,$01,$00,$FF,$00,$00,$00,$00,$00,$00,$01,$02,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$01,$02,$02,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$01,$01,$01,$01,$02,$00,$00,$00,$00,$00,$00,$00,$01,$01,$01,$01,$01,$01,$02,$02,$00,$00,$00,$00,$00,$01,$01,$01,$01,$01,$01,$01,$01,$01,$02,$00,$00,$00,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$02,$02,$00,$00,$01,$01,$02,$02,$03,$02,$02,$03,$02,$02,$02,$02,$00,$00,$00,$00,$02,$02,$03,$02,$02,$03,$02,$02,$00,$00,$00,$00,$00,$00,$01,$03,$00,$03,$03,$00,$03,$02,$00,$00,$00,$00,$00,$00,$01,$03,$00,$03,$03,$00,$03,$02,$00,$00,$00,$00,$00,$00,$01,$01,$03,$01,$01,$03,$01,$02,$00,$00,$00,$00,$00,$01,$01,$01,$03,$01,$01,$03,$01,$02,$02,$00,$00,$00,$00,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$00,$00,$00,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$02,$00,$00,$01,$02,$02,$01,$02,$02,$02,$01,$01,$02,$01,$02,$00,$00,$01,$02,$00,$01,$02,$02,$02,$01,$01,$02,$01,$02,$00,$00,$01,$02,$00,$01,$02,$00,$00,$01,$02,$00,$01,$02,$00,$00,$01,$02,$00,$01,$02,$00,$00,$01,$02,$00,$01,$02,$00,$00,$00,$01,$00,$00,$01,$01,$00,$01,$02,$00,$01,$02,$00,$00,$00,$01,$01,$00,$00,$00,$01,$01,$00,$01,$01,$00,$00,$FF,$00,$00,$00,$02,$01,$00,$00,$00,$01,$02,$00,$00,$00,$00,$00,$00,$03,$02,$00,$00,$00,$00,$00,$02,$03,$00,$00,$00,$00,$01,$03,$03,$02,$00,$00,$01,$02,$01,$03,$00,$00,$00,$00,$01,$03,$03,$02,$00,$00,$00,$02,$01,$03,$00,$00,$00,$00,$00,$03,$03,$02,$01,$00,$00,$02,$03,$03,$01,$00,$00,$00,$00,$03,$03,$02,$00,$00,$00,$02,$03,$03,$01,$00,$00,$00,$01,$03,$01,$03,$02,$00,$02,$03,$03,$01,$00,$00,$00,$00,$01,$03,$01,$03,$02,$00,$02,$03,$03,$01,$00,$00,$00,$00,$00,$03,$03,$03,$02,$01,$02,$01,$03,$03,$00,$00,$00,$00,$00,$00,$03,$03,$02,$00,$02,$01,$03,$00,$00,$00,$00,$00,$00,$00,$03,$01,$03,$02,$03,$03,$03,$01,$00,$00,$00,$00,$00,$00,$00,$01,$03,$02,$03,$03,$00,$01,$00,$00,$00,$00,$00,$00,$00,$00,$03,$01,$03,$00,$00,$00,$00,$00,$00,$00,$02,$02,$00,$00,$00,$01,$00,$00,$00,$02,$02,$00,$00,$00,$02,$02,$02,$00,$00,$01,$00,$00,$02,$02,$02,$02,$00,$00,$02,$02,$02,$02,$00,$01,$00,$02,$02,$02,$02,$02,$00,$00,$02,$02,$02,$02,$00,$01,$00,$02,$02,$02,$02,$02,$00,$00,$00,$02,$02,$02,$02,$01,$02,$02,$02,$02,$02,$00,$00,$00,$00,$00,$02,$02,$02,$01,$02,$02,$02,$00,$00,$00,$00,$00,$00,$00,$00,$00,$02,$01,$02,$00,$00,$00,$00,$00,$00,$FF,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$03,$03,$03,$03,$03,$03,$00,$03,$00,$00,$00,$00,$00,$03,$03,$03,$03,$03,$03,$03,$00,$03,$00,$00,$00,$00,$03,$01,$03,$03,$01,$01,$01,$03,$02,$01,$00,$00,$00,$03,$03,$01,$03,$03,$01,$01,$01,$03,$02,$01,$00,$00,$00,$03,$01,$01,$03,$01,$03,$03,$03,$03,$01,$03,$00,$00,$03,$03,$01,$01,$03,$01,$03,$03,$03,$03,$01,$03,$00,$00,$03,$01,$03,$01,$03,$03,$03,$03,$03,$03,$02,$03,$00,$00,$03,$01,$03,$01,$03,$03,$03,$03,$03,$03,$02,$03,$00,$00,$03,$03,$01,$03,$03,$03,$03,$02,$02,$03,$02,$03,$00,$00,$03,$03,$01,$03,$03,$03,$03,$02,$02,$03,$02,$03,$00,$00,$03,$03,$03,$03,$01,$01,$03,$01,$03,$03,$02,$03,$00,$00,$03,$03,$03,$03,$01,$01,$03,$01,$03,$03,$02,$03,$00,$00,$03,$03,$03,$01,$01,$01,$01,$01,$03,$03,$02,$03,$00,$00,$00,$03,$03,$01,$01,$01,$01,$01,$03,$03,$02,$03,$00,$00,$00,$03,$03,$03,$01,$01,$03,$03,$03,$03,$02,$03,$00,$00,$00,$00,$03,$03,$01,$01,$03,$03,$03,$03,$02,$03,$00,$00,$00,$00,$03,$03,$03,$03,$03,$03,$03,$03,$00,$03,$00,$00,$00,$00,$00,$03,$03,$03,$03,$03,$03,$03,$00,$03,$00,$FF,$00,$00,$00,$00,$00,$00,$02,$02,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$02,$02,$02,$02,$00,$00,$00,$00,$00,$00,$00,$03,$03,$03,$02,$02,$02,$02,$03,$03,$03,$00,$00,$00,$00,$00,$03,$03,$02,$02,$02,$02,$03,$03,$00,$00,$00,$00,$00,$00,$01,$01,$03,$02,$02,$03,$01,$01,$00,$00,$00,$00,$00,$02,$01,$01,$03,$02,$02,$03,$01,$01,$02,$00,$00,$00,$00,$02,$01,$01,$03,$01,$01,$03,$01,$01,$02,$00,$00,$00,$02,$02,$01,$01,$03,$01,$01,$03,$01,$01,$02,$02,$00,$00,$02,$02,$02,$01,$01,$02,$02,$01,$01,$02,$02,$02,$00,$00,$02,$02,$02,$01,$01,$02,$02,$01,$01,$02,$02,$02,$00,$00,$02,$02,$02,$02,$03,$03,$03,$03,$02,$02,$02,$02,$00,$00,$02,$02,$02,$02,$03,$03,$03,$03,$02,$02,$02,$02,$00,$00,$02,$02,$01,$03,$02,$02,$02,$02,$03,$01,$02,$02,$00,$00,$00,$02,$01,$03,$02,$02,$02,$02,$03,$01,$02,$00,$00,$00,$00,$00,$02,$02,$01,$01,$01,$01,$02,$02,$00,$00,$00,$00,$00,$00,$00,$00,$01,$01,$01,$01,$00,$00,$00,$00,$00,$00,$00,$00,$03,$03,$01,$01,$01,$01,$03,$03,$00,$00,$00,$00,$00,$00,$03,$03,$01,$01,$01,$01,$03,$03,$00,$00,$00,$00,$00,$03,$03,$00,$01,$01,$01,$01,$00,$03,$03,$00,$00,$00,$00,$03,$03,$00,$00,$01,$01,$00,$00,$03,$03,$00,$00,$FF,$00,$00,$00,$02,$02,$02,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$02,$02,$02,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$03,$03,$03,$03,$00,$00,$00,$01,$01,$00,$00,$00,$00,$03,$03,$03,$03,$03,$03,$00,$00,$01,$01,$01,$00,$00,$03,$01,$03,$01,$01,$03,$03,$03,$01,$01,$01,$01,$00,$00,$03,$01,$03,$01,$01,$03,$03,$03,$01,$01,$01,$01,$00,$00,$01,$03,$01,$03,$01,$01,$03,$03,$01,$01,$01,$01,$00,$00,$01,$03,$01,$03,$01,$01,$03,$03,$01,$01,$01,$01,$00,$00,$01,$03,$01,$03,$01,$01,$03,$01,$01,$01,$01,$01,$00,$00,$01,$03,$01,$03,$01,$01,$03,$01,$01,$01,$01,$00,$00,$00,$03,$01,$03,$01,$01,$03,$03,$01,$01,$01,$00,$00,$00,$00,$03,$01,$03,$01,$01,$03,$03,$01,$01,$01,$00,$00,$00,$02,$02,$02,$02,$03,$03,$03,$03,$01,$03,$03,$00,$01,$00,$00,$02,$02,$02,$03,$03,$03,$03,$01,$03,$03,$03,$01,$00,$00,$00,$03,$03,$02,$01,$01,$03,$03,$03,$03,$03,$01,$00,$00,$00,$00,$03,$02,$01,$01,$03,$03,$03,$03,$03,$01,$00,$00,$02,$02,$02,$01,$01,$01,$01,$01,$03,$03,$01,$01,$00,$00,$00,$02,$02,$01,$01,$01,$01,$01,$03,$00,$01,$00,$00,$00,$00,$00,$01,$01,$01,$01,$01,$01,$01,$00,$01,$00,$00,$00,$00,$00,$00,$01,$01,$01,$01,$00,$00,$00,$00,$00,$00,$FF,$00,$00,$00,$00,$00,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$03,$02,$01,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$03,$01,$02,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$03,$01,$02,$01,$02,$00,$00,$03,$00,$00,$00,$00,$00,$02,$01,$01,$02,$02,$02,$00,$03,$03,$03,$01,$00,$00,$00,$02,$01,$01,$02,$02,$02,$03,$03,$03,$03,$01,$00,$00,$00,$03,$03,$03,$03,$02,$01,$03,$03,$01,$03,$03,$03,$00,$00,$00,$00,$00,$03,$02,$01,$03,$03,$01,$03,$03,$03,$00,$00,$00,$00,$02,$03,$02,$01,$03,$03,$03,$03,$03,$01,$03,$00,$00,$02,$00,$03,$02,$01,$03,$03,$03,$03,$03,$01,$03,$00,$00,$00,$03,$03,$03,$01,$01,$01,$03,$01,$03,$03,$03,$01,$00,$03,$03,$00,$03,$01,$01,$01,$03,$01,$03,$03,$03,$01,$00,$00,$00,$00,$02,$02,$02,$01,$03,$03,$03,$01,$03,$00,$00,$00,$01,$02,$02,$02,$02,$01,$03,$03,$03,$01,$03,$00,$00,$00,$00,$02,$02,$02,$02,$01,$01,$01,$01,$01,$01,$01,$00,$00,$01,$02,$02,$02,$02,$01,$01,$01,$01,$01,$01,$01,$00,$00,$00,$02,$02,$00,$03,$03,$03,$03,$02,$02,$03,$02,$00,$00,$00,$00,$00,$00,$00,$03,$03,$03,$02,$02,$00,$02,$00,$00,$00,$00,$00,$00,$00,$00,$00,$02,$02,$02,$02,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$02,$02,$02,$02,$00,$FF,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$FF,$8D,$40,$A1,$40,$B5,$40,$C9,$40,$DD,$40,$F1,$40,$05,$41,$19,$41,$2D,$41,$41,$41,$55,$41,$69,$41,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$00,$00,$04,$04,$00,$00,$84,$84,$00,$00,$04,$04,$04,$04,$00,$00,$00,$00,$00,$00,$00,$00,$08,$08,$08,$08,$04,$04,$04,$04,$04,$04,$02,$02,$02,$02,$02,$02,$02,$02,$00,$00,$84,$84,$04,$04,$84,$84,$04,$04,$84,$84,$04,$04,$84,$84,$00,$00,$00,$00,$00,$00,$8F,$8F,$8F,$8F,$8F,$04,$04,$04,$04,$04,$0F,$0F,$0F,$0F,$0F,$0F,$00,$00,$00,$00,$10,$10,$10,$10,$10,$10,$10,$10,$10,$10,$10,$10,$10,$10,$00,$00,$84,$84,$00,$00,$84,$84,$84,$84,$84,$84,$84,$84,$04,$04,$84,$84,$84,$84,$84,$84,$84,$84,$00,$00,$00,$00,$00,$00,$84,$84,$84,$84,$84,$84,$04,$04,$04,$04,$04,$04,$00,$00,$09,$09,$89,$89,$09,$09,$89,$89,$09,$09,$89,$89,$09,$09,$89,$89,$09,$09,$81,$81,$01,$01,$01,$01,$81,$01,$81,$01,$81,$01,$81,$01,$81,$01,$81,$01,$81,$01,$81,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$81,$01,$81,$01,$81,$01,$81,$01,$81,$01,$81,$01,$81,$01,$81,$01,$81,$01,$81,$01,$02,$03,$04,$05,$06,$07,$08,$09,$0A,$0B,$0C,$0D,$0E,$0F,$10,$11,$12,$13,$14,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$98,$00,$14,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$98,$20,$14,$AC,$AC,$A9,$A9,$A9,$A9,$A9,$A9,$A9,$A9,$A9,$A9,$A9,$A9,$A9,$A9,$A9,$AC,$AC,$A9,$98,$40,$10,$FF,$FF,$FF,$AB,$FF,$A8,$AB,$A8,$A8,$FF,$AB,$A8,$A8,$FF,$A8,$AB,$98,$61,$02,$0E,$01,$98,$71,$02,$9D,$96,$98,$81,$11,$02,$03,$08,$FF,$08,$FF,$00,$15,$08,$08,$08,$08,$08,$0E,$01,$08,$08,$98,$A1,$11,$02,$03,$09,$FF,$09,$FF,$02,$16,$09,$09,$09,$09,$09,$02,$03,$09,$09,$98,$C1,$11,$02,$06,$09,$FF,$09,$FF,$02,$17,$04,$07,$09,$09,$09,$02,$06,$04,$07,$98,$E1,$11,$02,$03,$0A,$0B,$0A,$0B,$02,$0B,$FF,$09,$02,$A7,$06,$02,$03,$FF,$09,$99,$01,$11,$13,$14,$0C,$0D,$0C,$0D,$10,$0D,$08,$09,$0F,$12,$11,$13,$14,$08,$09,$99,$29,$02,$04,$05,$99,$30,$02,$04,$05,$99,$63,$09,$9D,$98,$99,$FF,$9C,$8C,$98,$9B,$8E,$99,$C3,$0E,$99,$9E,$9C,$91,$FF,$9C,$9D,$8A,$9B,$9D,$FF,$94,$8E,$A2,$9A,$04,$0C,$1E,$81,$89,$88,$89,$FF,$18,$19,$1A,$1B,$1C,$1D,$00,$98,$43,$0A,$97,$92,$8C,$8E,$FF,$99,$95,$8A,$A2,$1F,$98,$84,$07,$44,$45,$FF,$FF,$FF,$44,$45,$98,$A3,$09,$44,$46,$20,$21,$22,$23,$24,$44,$45,$98,$C2,$0B,$44,$45,$25,$26,$27,$28,$29,$2A,$2B,$44,$45,$98,$E2,$0B,$44,$45,$2C,$2D,$2E,$2F,$30,$31,$32,$44,$45,$99,$02,$0B,$44,$45,$33,$A5,$34,$35,$A5,$36,$37,$44,$45,$99,$22,$0B,$44,$45,$38,$39,$3A,$3B,$3C,$3D,$3E,$44,$45,$99,$43,$09,$44,$45,$3F,$40,$41,$42,$43,$44,$45,$99,$63,$09,$47,$48,$49,$4A,$4B,$4C,$4D,$4E,$4F,$99,$83,$09,$50,$51,$52,$53,$54,$55,$56,$57,$58,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$00,$00,$00,$FF
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
    ld [w_mario_anim_frame], a    ; stand still
    call copy_current_anim_xy
    call set_event_mario_jump
    call paddle_open_anim_handler
    ld a, $4
    ld [w_mario_anim_frame], a    ; jump to the left
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
    call clear_anim_oam_buffer
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
    call clear_anim_oam_buffer
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
    ld hl, $44F5
    add hl, bc
    ld a, [hl]  ; =>w_mario_jump_y_velocity_data
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

; [0-2]:          -3             
; [3-5]:          -2             
; [6-8]:          -1             
; [9]:            0              
; [10]:           -1             
; [11-12]:        0              
; [13]:           1              
; [14]:           0              
; [15-17]:        1              
; [18-20]:        2              
; [21-24]:        3              
mario_jump_y_velocity_data:
    db $FD,$FD,$FD,$FE,$FE,$FE,$FF,$FF,$FF,$00,$FF,$00,$00,$01,$00,$01,$01,$01,$02,$02,$02,$03,$03,$03

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
    ld c, a     ; A = $00 or $02
    ld hl, $4551
    add hl, bc
    ld b, [hl]  ; =>paddle_open_close_anim_spr_ptr
    ld e, $3
    call multiply   ; C *= $03
    ld hl, $4554
    add hl, bc
    ld a, [hl+] ; =>paddle_open_frame_0_tile_data
    ld [OAM_PADDLE_START + $02], a
    ld a, [hl+] ; =>paddle_open_frame_0_tile_data[1]
    ld [OAM_PADDLE_START + $06], a
    ld a, [hl]  ; =>paddle_open_frame_0_tile_data[2]
    ld [OAM_PADDLE_START + $0A], a
    ret

paddle_open_close_anim_spr_ptr:
    db $00,$01,$02

; Open: 0 -> 1 -> 2              
; Close: 2 -> 1 -> 0             

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
    ld hl, $4599
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
    jp clear_anim_oam_buffer

explosion_anim_offset_data:
    db $07,$07,$07,$07,$07,$07,$07,$07,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$09,$09,$09,$09,$09,$09,$09,$09,$09,$09,$09,$09,$09,$09,$09,$09

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
    ld hl, $45E6
    add hl, de
    ld a, [hl]  ; =>mario_wink_anim_offset_data
    call copy_tiles4_oam_buffer
    call wait_vblank
    pop bc
    ld a, [w_anim_timer]          
    inc a
    ld [w_anim_timer], a 
    cp $1d
    jr c, .next_anim_frame
    jp clear_anim_oam_buffer

mario_wink_anim_offset_data:
    db $0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0B,$0B,$0B,$0B,$0B,$0B,$0C,$0C,$0C,$0C,$0C,$0C,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0A

level_load_handler:
    call lcd_disable_and_wait_vblank
    call disable_interrupts_save
    call fill_tile_map_0
    call fill_tile_map_1
    call clear_main_oam_buffer
    call stop_music_wrapper
    ld a, $7F
    ldh [rWX], a 
    ld a, $0
    ldh [rWY], a 
    ldh a, [h_lcdc_mirror] 
    or $60
    ldh [h_lcdc_mirror], a 
    xor a
    ldh a, [h_brick_scroll_flag]            
    ld a, $8
    ldh [rLYC], a
    ld a, $44
    ldh [rSTAT], a 
    ldh a, [h_joypad_pressed]               
    or $2
    or $8
    ldh [h_joypad_pressed], a    
    ld a, $E4
    call set_palette_data
    ld de, $4A3C
    call is_oam_buffer_empty
    ldh a, [h_game_state]  
    cp $3
    jr z, .LAB_4660
    ld a, [w_stage_number_display]
    cp $0
    jr z, .LAB_4660
    ld a, [w_true_stage_number]
    cp $0
    jr nz, .LAB_4660
    ld de, $42B3    ; [DE] = $98
    call is_oam_buffer_empty
    ld a, $0
    call set_palette_data

.LAB_4660
    call load_wall_oam_buffer
    call interrupt_enable
    jp lcd_ppu_enable
                         
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

.LAB_46ea
    ld a, b
    add $80
    ld [OAM_STAGE_NUMBER_START + $1A], a    

    pop af
    add $80
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

; loads the stage number (not counting bonus levels) to VRAM *

load_stage_number_display_vram:
    call check_object_dirty_flag
    ld hl, $C901    ; [hl] = w_tile_buffer

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

    ; STAGE NUMBER TEXT

    ld a, b
    add $80
    ld [hl+], a
    pop af
    add $80
    ld [hl+], a
    xor a
    ld [hl+], a
    inc a
    ldh [h_object_dirty_flag], a 
    jp wait_vblank

; loads the number of lives that the player currently has to VRAM

load_lives_number_vram:
    call check_object_dirty_flag

.LAB_47ca 
    ld hl, $C901    ; [hl] = w_tile_buffer

    ; $9E04

    ld a, $9E
    ld [hl+], a     ; w_tile_buffer + $00, a    
    ld a, $4
    ld [hl+], a     ; w_tile_buffer + $01, a  

    ; 1 tile

    ld a, $1
    ld [hl+], a     ; w_tile_buffer + $02, a    

    ; life number

    ld a, [w_life_counter]       
    add $80         ; number text offset
    ld [hl+], a     ; w_tile_buffer + $03, a
    xor a
    ld [hl+], a     ; w_tile_buffer + $04, a
    inc a
    ldh [h_object_dirty_flag], a 
    jp wait_vblank

; loads the "TIME" text that appears during bonus stages     *

load_bonus_time_text_vram:
    call check_object_dirty_flag
    ld hl, $C901    ; [hl] = w_tile_buffer

.LAB_47ea
    ld a, $9D
    ld [hl+], a      ; w_tile_buffer + $00, a    
    ld a, $A1
    ld [hl+], a      ; w_tile_buffer + $01, a

    ; 4 tiles

    ld a, $4
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

LAB_47ff:
    xor a
    ld [hl+], a      ; w_tile_buffer + $07, a
    inc a
    ldh [h_object_dirty_flag], a 
    jp wait_vblank

; on every level load, clears the "TIME" tiles of the bonus stages

clear_bonus_time_text_vram:
    call check_object_dirty_flag
    ld hl, $C901    ; [hl] = w_tile_buffer

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
    jr LAB_47ff

; updates score on level load, bonus win and game win

update_score_oam_buffer:
    ld hl, $C814
    ldh a, [h_player_score_lo]      

    ld b, a
    ldh a, [h_player_score_hi]    

    call score_to_bcd

    ld a, $40
    ld [hl+], a ; <=

    ld a, $88
    ld [hl+], a ; <=

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
    ld [hl+], a ; if score < 10000, display FF tile

    ld a, $0
    ld [hl+], a

    ld a, $38
    ld [hl+], a

    ld a, $88
    ld [hl+], a

    ldh a, [h_score_digit_thousands]        
    add $80
    ld [hl+], a

    ld a, $0
    ld [hl+], a

    ld a, $38
    ld [hl+], a
    
    ld a, $90
    ld [hl+], a

    ldh a, [h_score_digit_hundreds]         
    add $80
    ld [hl+], a

    ld a, $0
    ld [hl+], a

    ld a, $38
    ld [hl+], a

    ld a, $98
    ld [hl+], a

    ldh a, [h_score_digit_tens]             
    add $80
    ld [hl+], a

    ld a, $0
    ld [hl+], a

    ld a, $38
    ld [hl+], a

    ld a, $A0
    ld [hl+], a

    ldh a, [h_score_digit_ones]             
    add $80
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
    add $80
    ld [hl+], a
    ld a, $0
    ld [hl+], a
    ld a, $20
    ld [hl+], a
    ld a, $90
    ld [hl+], a
    ldh a, [h_score_digit_hundreds]         
    add $80
    ld [hl+], a
    ld a, $0
    ld [hl+], a
    ld a, $20
    ld [hl+], a
    ld a, $98
    ld [hl+], a
    ldh a, [h_score_digit_tens]             
    add $80
    ld [hl+], a
    ld a, $0
    ld [hl+], a
    ld a, $20
    ld [hl+], a
    ld a, $A0
    ld [hl+], a
    ldh a, [h_score_digit_ones]             
    add $80
    ld [hl+], a
    ld a, $0
    ld [hl+], a
    ret

; called during title screen initialization        
load_title_screen_score_buffer_oam:
    ldh a, [h_top_score_lo]

    ld b, a
    ldh a, [h_top_score_hi]

    call score_to_bcd

    ld hl, OAM_TITLE_SCORE_START

    ld a, $70
    ld [hl+], a    ; =>OAM_TITLE_SCORE_START + $00, a 

    ld a, $70
    ld [hl+], a    ; =>OAM_TITLE_SCORE_START + $01, a  

    ld b, $FF
    ldh a, [h_score_digit_tens_of_thousands]
    cp $0
    jr z, .load_score

    ld b, $BF
    cp $1
    jr z, .load_score

    ld b, $BC
    cp $2
    jr z, .load_score

    ld b, $C9

.load_score
    ld a, b
    ld [hl+], a    ; =>BYTE_c82a, a    
    ld a, $0
    ld [hl+], a    ; =>BYTE_c82b, a    

    ld a, $68
    ld [hl+], a    ; =>BYTE_c82c, a    
    ld a, $70
    ld [hl+], a    ; =>BYTE_c82d, a
    ldh a, [h_score_digit_thousands]        
    add $80
    ld [hl+], a    ; =>BYTE_c82e, a    
    ld a, $0
    ld [hl+], a    ; =>BYTE_c82f, a    

    ld a, $68
    ld [hl+], a    ; =>BYTE_c830, a    
    ld a, $78
    ld [hl+], a    ; =>BYTE_c831, a    
    ldh a, [h_score_digit_hundreds]         
    add $80
    ld [hl+], a    ; =>BYTE_c832, a    
    ld a, $0
    ld [hl+], a    ; =>BYTE_c833, a    

    ld a, $68
    ld [hl+], a    ; =>BYTE_c834, a    
    ld a, $80
    ld [hl+], a    ; =>BYTE_c835, a    
    ldh a, [h_score_digit_tens]             
    add $80
    ld [hl+], a    ; =>BYTE_c836, a    
    ld a, $0
    ld [hl+], a    ; =>BYTE_c837, a    

    ld a, $68
    ld [hl+], a    ; =>BYTE_c838, a    
    ld a, $88
    ld [hl+], a    ; =>BYTE_c839, a    
    ldh a, [h_score_digit_ones]             
    add $80
    ld [hl+], a    ; =>BYTE_c83a, a    
    ld a, $0
    ld [hl+], a    ; =>BYTE_c83b, a 

    ret

; triggers upon bonus level win  
; only loads the number, not the "SPECIAL BONUS PTS." text   *

load_special_bonus_points_oam_buffer:
    ld hl, OAM_SPECIAL_BONUS_POINTS_START
    ld a, b
    ld b, c
    call score_to_bcd
    ld a, $78
    ld [hl+], a                     ; Y
    ld a, $30
    ld [hl+], a                     ; X
    ldh a, [h_score_digit_thousands]        
    add $80
    ld [hl+], a                     ; Tile ID: +$80 offset for numbers
    ld a, $0
    ld [hl+], a                     ; Attribute
    ld a, $78
    ld [hl+], a                     ; Y
    ld a, $38
    ld [hl+], a                     ; X
    ldh a, [h_score_digit_hundreds]         
    add $80
    ld [hl+], a                     ; Tile ID
    ld a, $0
    ld [hl+], a                      ; Attribute
    ld a, $78
    ld [hl+], a                     ; Y
    ld a, $40
    ld [hl+], a                     ; X
    ldh a, [h_score_digit_tens]             
    add $80
    ld [hl+], a                     ; Tile ID
    ld a, $0
    ld [hl+], a                      ; Attribute
    ld a, $78
    ld [hl+], a                     ; Y
    ld a, $48
    ld [hl+], a                     ; X
    ldh a, [h_score_digit_ones]             
    add $80
    ld [hl+], a                     ; Tile ID
    ld a, $0
    ld [hl+], a                      ; Attribute
    ret

load_game_over_text_oam_buffer:
    ; Y plane
    ld a, $50
    ld [OAM_GAME_OVER_START + $00], a
    ld [OAM_GAME_OVER_START + $04], a
    ld [OAM_GAME_OVER_START + $08], a
    ld [OAM_GAME_OVER_START + $0C], a
    ld [OAM_GAME_OVER_START + $10], a
    ld [OAM_GAME_OVER_START + $14], a
    ld [OAM_GAME_OVER_START + $18], a
    ld [OAM_GAME_OVER_START + $1C], a

    ; X plane
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

    ; Attr. plane
    ld a, $0
    ld [OAM_GAME_OVER_START + $03], a
    ld [OAM_GAME_OVER_START + $07], a
    ld [OAM_GAME_OVER_START + $0B], a
    ld [OAM_GAME_OVER_START + $0F], a
    ld [OAM_GAME_OVER_START + $13], a
    ld [OAM_GAME_OVER_START + $17], a
    ld [OAM_GAME_OVER_START + $1B], a
    ld [OAM_GAME_OVER_START + $1F], a

    ; Tile ID plane
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
    ld e, $18
    ld d, $11   ; number of sprites = 17

.load_next_wall_tile  
    ld a, e
    ld [hl+], a     ; Y
    ld a, $8
    ld [hl+], a     ; X
    ld a, $B4
    ld [hl+], a     ; Tile ID
    ld a, $0
    ld [hl+], a     ; Attribute   
    ld a, e
    add $8          ; offset 1 tile (8 px) down
    ld e, a
    dec d
    jr nz, .load_next_wall_tile
    ret

;loads the current value of the ball's velocity at the upper right corner of the screen

debug_ball_velocity:
    ret

    ; unused code

    ld hl, OAM_DEBUG_BALL_VELOCITY_START

    ld a, $98
    ld [hl+], a    ; =>[OAM_DEBUG_BALL_VELOCITY_START + $00], a 
    
    ld a, $10
    ld [hl+], a    ; =>[OAM_DEBUG_BALL_VELOCITY_START + $01], a  

    ldh a, [h_ball_velocity]                
    add $80
    ld [hl+], a    ; =>[OAM_DEBUG_BALL_VELOCITY_START + $02], a  

    ld a, $0
    ld [hl+], a    ; =>[OAM_DEBUG_BALL_VELOCITY_START + $03], a  

    ret

unknown_data:
    db $9C,$00,$01,$BE,$9C,$20,$D8,$B4,$98,$00,$01,$BD,$98,$01,$54,$B5,$9C,$21,$03,$9D,$98,$99,$9C,$81,$04,$B8,$B9,$BA,$BB,$9D,$41,$04,$C0,$C1,$C2,$C3,$9E,$02,$02,$B1,$B2,$00

copy_tiles4_oam_buffer:
    sla a   ; A *= 2
    ld e, a
    ld d, $0
    ld hl, $4A8B
    add hl, de
    ld d, [hl]   ; =>mario_start_spr_ptr_table
    inc hl
    ld e, [hl]   ; =>mario_start_spr_ptr_table[1]
    ld hl, $C888
    ld a, $4

.load_tiles4  
    push af     ; $C888-$C897
    ld a, [DE]  ; Y-loc
    add c       ; y offset
    ld [hl+], a    ; =>BYTE_c888, a    
    inc de
    ld a, [DE]  ; X-loc
    add b       ; x offset
    ld [hl+], a    ; =>BYTE_c889, a    
    inc de
    ld a, [DE]  ; Tile No
    ld [hl+], a    ; =>BYTE_c88a, a    
    inc de
    ld a, [DE]  ; Attribute
    ld [hl+], a    ; =>BYTE_c88b, a    
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

tile_data_block_0:
    db $68,$7F,$A8,$A8,$FF,$E8,$E8,$FF,$7F,$7F,$00,$00,$00,$00,$00,$00,$00,$FF,$00,$00,$FF,$00,$00,$FF,$FF,$FF,$00,$00,$00,$00,$00,$00,$6F,$7F,$AF,$AF,$F8,$E8,$E8,$FF,$7F,$7F,$00,$00,$00,$00,$00,$00,$FF,$FF,$FF,$FF,$00,$00,$00,$FF,$FF,$FF,$00,$00,$00,$00,$00,$00,$3C,$FF,$3C,$3C,$81,$00,$00,$FF,$FF,$FF,$00,$00,$00,$00,$00,$00,$60,$60,$B0,$B0,$F0,$F0,$60,$60,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$04,$07,$10,$1F,$06,$02,$1F,$01,$0F,$0F,$07,$00,$01,$03,$00,$00,$00,$E0,$00

audio_data:
    db $F0,$F0,$50,$F8,$58,$F0,$30,$C0,$00,$00,$E0,$03,$06,$0B,$06,$0D,$0D,$1F,$1F,$0F,$0F,$06,$3E,$00,$06,$00,$00,$80,$70,$80,$70,$10,$F0,$F0,$F0,$F8,$F8,$38,$3C,$00,$18,$00,$30,$02,$03,$08,$0F,$03,$01,$0F,$00,$07,$07,$03,$00,$01,$01,$02,$03,$00,$F0,$00,$F8,$78,$28,$FC,$AC,$F8,$98,$E0,$00,$A0,$70,$40,$F8,$0E,$03,$0F,$03,$03,$07,$03,$03,$01,$01,$00,$03,$00,$00,$00,$00,$40,$F8,$B0,$88,$F8,$C8,$F8,$F8,$F8,$F8,$70,$F0,$30,$38,$00,$70,$00,$00,$04,$07,$10,$1F,$06,$02,$1F,$01,$0F,$0F,$07,$00,$00,$03,$00,$00,$00,$E0,$00,$F0,$F0,$50,$F8,$58,$F0,$30,$C0,$00,$80,$F0,$01,$07,$09,$07,$0E,$06,$07,$07,$07,$07,$03,$03,$01,$01,$00,$03,$60,$98,$60,$98,$C0,$F0,$F8,$FC,$F8,$FC,$F0,$F8,$C0,$C8,$00,$C0,$00,$00,$04,$07,$10,$1F,$06,$02,$1F,$01,$0F,$0F,$07,$00,$03,$02,$00,$00,$00,$E0,$00,$F0,$F0,$50,$F8,$58,$F0,$30,$C0,$00,$C0,$60,$04,$0F,$04,$1F,$3B,$0B,$3F,$0F,$0F,$0F,$1F,$1F,$1C,$1C,$00,$3C,$80,$F8,$80,$FC,$7C,$70,$FC,$F0,$F0,$F0,$F8,$F8,$38,$38,$00,$3C,$04,$07,$10,$1F,$06,$02,$1F,$01,$0F,$0F,$07,$00,$05,$07,$09,$0F,$00,$E0,$00,$F0,$F0,$50,$F8,$58,$F0,$30,$80,$FC,$10,$FE,$0C,$F2,$0E,$4E,$3F,$7F,$3F,$7F,$07,$27,$01,$01,$00,$00,$00,$00,$00,$00,$FC,$F0,$F0,$F0,$F0,$F0,$E0,$E0,$F0,$F8,$F0,$F8,$00,$10,$00,$10,$04,$07,$10,$1C,$06,$02,$1C,$00,$0F,$0F,$07,$00,$05,$07,$09,$0F,$00,$00,$00,$00,$00,$00,$06,$01,$18,$00,$16,$20,$28,$34,$17,$1E,$00,$00,$06,$09,$10,$24,$00,$40,$00,$80,$48,$80,$A4,$C8,$5D,$66,$3F,$3B,$05,$04,$02,$02,$02,$02,$00,$02,$02,$00,$06,$07,$0A,$51,$01,$02,$00,$08,$00,$00,$04,$08,$01,$06,$00,$01,$00,$00,$00,$00,$00,$01,$00,$00,$00,$00,$00,$01,$00,$00,$00,$01,$00,$02,$08,$B0,$06,$07,$0A,$0A,$0F,$0E,$0E,$0F,$07,$07,$00,$00,$00,$00,$00,$00,$F9,$FF,$FF,$FF,$3F,$3E,$7F,$78,$FF,$F8,$7F,$70,$DF,$D0,$DF,$D0,$FF,$FF,$FF,$FF,$FF,$3F,$FF,$0F,$FF,$07,$FF,$03,$FF,$03,$FF,$02,$FF,$FF,$F0,$30,$F8,$18,$FC,$0C,$FE,$06,$FF,$01,$FF,$00,$FF,$00,$FF,$FE,$F7,$F6,$FF,$FE,$FF,$FC,$3F,$3C,$FF,$F0,$FF,$00,$FF,$00,$FF,$F0,$FF,$30,$FF,$18,$FF,$0C,$FF,$06,$FF,$01,$FF,$00,$FF,$00,$FF,$02,$FF,$02,$FF,$02,$FF,$02,$FF,$06,$FF,$FC,$FF,$00,$FF,$00,$00

rom_padding_4de6:
    ds 1423, $00

tile_data_block_1:
    db $00,$00,$3C,$3C,$66,$66,$66,$66,$66,$66,$66,$66,$3C,$3C,$00,$00,$00,$00,$18,$18,$38,$38,$18,$18,$18,$18,$18,$18,$3C,$3C,$00,$00,$00,$00,$3C,$3C,$66,$66,$0C,$0C,$38,$38,$60,$60,$7E,$7E,$00,$00,$00,$00,$7E,$7E,$08,$08,$3C,$3C,$06,$06,$66,$66,$3C,$3C,$00,$00,$00,$00,$1C,$1C,$2C,$2C,$4C,$4C,$7E,$7E,$0C,$0C,$0C,$0C,$00,$00,$00,$00,$7C,$7C,$40,$40,$7C,$7C,$06,$06,$66,$66,$3C,$3C,$00,$00,$00,$00,$3C,$3C,$60,$60,$7C,$7C,$66,$66,$66,$66,$3C,$3C,$00,$00,$00,$00,$7E,$7E,$66,$66,$0C,$0C,$18,$18,$18,$18,$18,$18,$00,$00,$00,$00,$3C,$3C,$66,$66,$3C,$3C,$66,$66,$66,$66,$3C,$3C,$00,$00,$00,$00,$3C,$3C,$66,$66,$66,$66,$3E,$3E,$06,$06,$3C,$3C,$00,$00,$00,$00,$18,$18,$3C,$3C,$66,$66,$7E,$7E,$66,$66,$66,$66,$00,$00,$00,$00,$7C,$7C,$66,$66,$7C,$7C,$66,$66,$66,$66,$7E,$7E,$00,$00,$00,$00,$3C,$3C,$66,$66,$60,$60,$60,$60,$66,$66,$3C,$3C,$00,$00,$00,$00,$7C,$7C,$66,$66,$66,$66,$66,$66,$66,$66,$7C,$7C,$00,$00,$00,$00,$7E,$7E,$60,$60,$7C,$7C,$60,$60,$60,$60,$7E,$7E,$00,$00,$00,$00,$7E,$7E,$60,$60,$7C,$7C,$60,$60,$60,$60,$60,$60,$00,$00,$00,$00,$3C,$3C,$66,$66,$60,$60,$6E,$6E,$66,$66,$3E,$3E,$00,$00,$00,$00,$66,$66,$66,$66,$7E,$7E,$66,$66,$66,$66,$66,$66,$00,$00,$00,$00,$3C,$3C,$18,$18,$18,$18,$18,$18,$18,$18,$3C,$3C,$00,$00,$00,$00,$1E,$1E,$0C,$0C,$0C,$0C,$0C,$0C,$6C,$6C,$38,$38,$00,$00,$00,$00,$66,$66,$6C,$6C,$78,$78,$7C,$7C,$6E,$6E,$66,$66,$00,$00,$00,$00,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$7E,$7E,$00,$00,$00,$00,$62,$62,$76,$76,$7E,$7E,$6A,$6A,$62,$62,$62,$62,$00,$00,$00,$00,$66,$66,$76,$76,$7E,$7E,$6E,$6E,$66,$66,$66,$66,$00,$00,$00,$00,$3C,$3C,$66,$66,$66,$66,$66,$66,$66,$66,$3C,$3C,$00,$00,$00,$00,$7C,$7C,$66,$66,$66,$66,$7C,$7C,$60,$60,$60,$60,$00,$00,$00,$00,$3C,$3C,$66,$66,$66,$66,$7E,$7E,$64,$64,$3A,$3A,$00,$00,$00,$00,$7C,$7C,$66,$66,$66,$66,$7C,$7C,$66,$66,$66,$66,$00,$00,$00,$00,$3C,$3C,$66,$66,$38,$38,$0C,$0C,$66,$66,$3C,$3C,$00,$00,$00,$00,$7E,$7E,$18,$18,$18,$18,$18,$18,$18,$18,$18,$18,$00,$00,$00,$00,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$3C,$3C,$00,$00,$00,$00,$62,$62,$62,$62,$62,$62,$62,$62,$34,$34,$18,$18,$00,$00,$00,$00,$62,$62,$6A,$6A,$6A,$6A,$6A,$6A,$7E,$7E,$34,$34,$00,$00,$00,$00,$62,$62,$74,$74,$38,$38,$1C,$1C,$2E,$2E,$46,$46,$00,$00,$00,$00,$62,$62,$76,$76,$3C,$3C,$18,$18,$18,$18,$18,$18,$00,$00,$00,$00,$7E,$7E,$0C,$0C,$18,$18,$30,$30,$60,$60,$7E,$7E,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$01,$81,$01,$81,$01,$FF,$FF,$FF,$01,$81,$01,$81,$01,$FF,$FF,$FF,$01,$FF,$01,$FF,$01,$FF,$FF,$FF,$01,$FF,$01,$FF,$01,$FF,$FF,$01,$FF,$01,$FF,$01,$FF,$FF,$FF,$01,$FF,$01,$FF,$01,$FF,$FF,$FF,$FF,$01,$81,$01,$81,$01,$FF,$FF,$00,$00,$00,$00,$00,$00,$00,$00,$FF,$01,$FF,$01,$FF,$01,$FF,$FF,$00,$00,$00,$00,$00,$00,$00,$00,$01,$FF,$01,$FF,$01,$FF,$FF,$FF,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$FF,$01,$81,$01,$81,$01,$FF,$FF,$00,$00,$00,$00,$00,$00,$00,$00,$FF,$01,$FF,$01,$FF,$01,$FF,$FF,$00,$00,$00,$00,$00,$00,$00,$00,$01,$FF,$01,$FF,$01,$FF,$FF,$FF,$00,$00,$20,$3C,$80,$FE,$6E,$2A,$FE,$12,$FE,$F6,$38,$44,$00,$00,$00,$00,$00,$00,$44,$44,$28,$28,$10,$10,$28,$28,$44,$44,$00,$00,$01,$FF,$3D,$83,$19,$87,$01,$8F,$19,$9F,$3D,$BF,$7F,$FF,$FF,$FF,$B9,$C7,$B9,$C7,$B9,$C7,$B9,$C7,$B9,$C7,$B9,$C7,$B9,$C7,$B9,$C7,$FF,$FF,$00,$FF,$FF,$00,$FF,$00,$FF,$00,$00,$FF,$00,$FF,$FF,$FF,$00,$00,$00,$00,$3C,$3C,$00,$00,$3C,$3C,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$30,$30,$30,$30,$00,$00,$00,$00,$38,$38,$65,$65,$31,$31,$19,$19,$4D,$4D,$38,$38,$00,$00,$00,$00,$E3,$E3,$96,$96,$86,$86,$86,$86,$96,$96,$E3,$E3,$00,$00,$00,$00,$9E,$9E,$59,$59,$59,$59,$5E,$5E,$5B,$5B,$9B,$9B,$00,$00,$00,$00,$7C,$7C,$60,$60,$78,$78,$60,$60,$60,$60,$7C,$7C,$00,$00,$3E,$3E,$53,$41,$F3,$81,$9E,$8E,$74,$7C,$04,$14,$02,$12,$04,$0C,$7F,$7F,$C0,$FF,$A9,$E0,$AF,$D0,$B7,$C8,$BC,$C7,$BA,$C7,$B9,$C7,$FE,$FE,$03,$FF,$95,$07,$F1,$0F,$E9,$17,$59,$A7,$79,$C7,$B9,$C7,$7E,$66,$C3,$81,$FF,$81,$7E,$7E,$00,$08,$00,$6B,$00,$7F,$00,$1C,$00,$00,$3B,$3B,$6C,$6C,$30,$30,$18,$18,$6C,$6C,$38,$38,$00,$00,$00,$00,$F3,$F3,$C7,$C7,$CC,$CC,$CF,$CF,$CC,$CC,$CC,$CC,$00,$00,$00,$00,$0F,$0F,$99,$99,$D8,$D8,$DB,$DB,$D9,$D9,$CF,$CF,$00,$00,$00,$00,$3E,$3E,$B0,$B0,$3C,$3C,$B0,$B0,$B0,$B0,$BE,$BE,$00,$00,$00,$00,$79,$79,$CD,$CD,$71,$71,$19,$19,$CD,$CD,$79,$79,$00,$00,$00,$00,$F3,$F3,$9B,$9B,$9B,$9B,$F3,$F3,$83,$83,$83,$83,$00,$00,$00,$00,$F3,$F3,$06,$06,$E6,$E6,$06,$06,$06,$06,$F3,$F3,$00,$00,$00,$00,$CF,$CF,$66,$66,$06,$06,$06,$06,$66,$66,$CF,$CF,$00,$00,$00,$00,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$FC,$FC,$00,$00,$10,$08,$38,$04,$FE,$01,$7C,$2A,$3C,$28,$7C,$02,$C6,$39,$82,$41

rom_padding_5815:
    ds 864, $00

tile_data_block_2:
    db $7F,$7F,$40,$40,$60,$40,$7F,$4F,$7F,$4F,$7F,$4F,$7F,$4F,$7F,$4F,$E0,$E0,$18,$18,$04,$04,$E2,$E2,$F6,$F2,$FF,$F9,$FF,$F9,$FF,$F9,$7F,$4F,$7F,$4F,$7F,$4F,$7F,$4F,$7F,$4F,$7F,$4F,$7F,$4F,$7F,$4F,$7F,$79,$7F,$79,$7F,$79,$7F,$79,$7F,$79,$7F,$79,$7F,$79,$7F,$79,$7F,$5F,$7F,$5F,$7F,$4F,$3F,$2F,$3F,$27,$1F,$10,$0F,$0C,$03,$03,$FF,$FD,$FF,$FD,$FF,$F9,$FE,$FA,$FE,$F2,$FC,$04,$F8,$18,$E0,$E0,$FF,$F9,$FF,$F9,$FF,$F9,$FF,$F9,$FF,$F9,$FF,$F9,$FF,$F9,$FF,$F9,$FF,$FD,$FF,$FD,$FF,$FD,$FF,$FD,$FF,$FD,$FF,$FD,$FF,$FD,$FF,$FD,$7F,$7F,$41,$41,$63,$41,$7F,$5D,$7F,$5D,$7F,$5D,$7F,$5D,$7F,$5D,$7F,$5D,$7F,$5D,$7F,$5D,$7F,$5D,$7F,$5D,$7F,$5D,$7F,$5D,$7F,$5D,$7F,$5D,$7E,$5C,$7C,$5C,$7F,$5F,$7F,$5F,$7F,$5F,$7F,$5F,$7F,$5F,$FF,$FF,$01,$01,$03,$01,$FF,$F9,$FF,$F9,$FF,$F9,$FF,$F9,$FF,$F9,$7F,$5F,$7F,$5F,$7F,$5F,$7F,$5F,$7F,$5F,$7F,$40,$7F,$40,$7F,$7F,$FF,$F9,$FF,$F9,$FF,$F9,$FF,$F9,$FF,$F9,$FF,$01,$FF,$01,$FF,$FF,$03,$03,$0C,$0C,$10,$10,$23,$23,$37,$27,$7F,$4F,$7F,$4F,$7F,$4F,$3F,$27,$3F,$27,$3F,$27,$3F,$27,$3F,$27,$3F,$21,$3F,$21,$3F,$3F,$7F,$4F,$7F,$4F,$7F,$4F,$7F,$4F,$7F,$4F,$7F,$40,$7F,$40,$7F,$7F,$7E,$72,$7E,$72,$7E,$72,$7E,$72,$7E,$72,$7E,$42,$7E,$42,$7E,$7E,$7F,$5D,$7F,$5D,$7F,$5D,$7F,$5D,$7F,$5D,$7F,$41,$7F,$41,$7F,$7F,$7F,$4F,$7F,$4F,$7F,$4F,$7F,$4F,$7F,$4F,$7F,$41,$7F,$41,$7F,$7F,$7F,$79,$7F,$79,$7F,$79,$7F,$79,$7F,$79,$7F,$41,$7F,$41,$7F,$7F,$FF,$FF,$03,$01,$07,$01,$FF,$F9,$FF,$F9,$FF,$F9,$FF,$01,$FF,$FF,$00,$00,$00,$00,$FF,$FF,$03,$01,$07,$01,$FF,$F9,$FF,$F9,$FF,$F9,$FF,$01,$FF,$FF,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$C6,$C6,$E6,$E6,$E6,$E6,$D6,$D6,$CE,$CE,$CE,$CE,$C6,$C6,$00,$00,$C0,$C0,$C0,$C0,$1B,$1B,$DD,$DD,$D9,$D9,$D9,$D9,$D9,$D9,$00,$00,$30,$30,$78,$78,$33,$33,$B6,$B6,$B7,$B7,$B6,$B6,$B3,$B3,$00,$00,$00,$00,$00,$00,$CD,$CD,$6E,$6E,$EC,$EC,$0C,$0C,$EC,$EC,$00,$00,$01,$01,$01,$01,$8F,$8F,$D9,$D9,$D9,$D9,$D9,$D9,$CF,$CF,$00,$00,$80,$80,$80,$80,$9E,$9E,$B3,$B3,$B3,$B3,$B3,$B3,$9E,$9E,$00,$00,$38,$38,$44,$44,$BA,$BA,$A2,$A2,$BA,$BA,$44,$44,$38,$38,$00,$00,$18,$18,$18,$18,$18,$18,$10,$10,$10,$10,$00,$00,$30,$30,$00,$00,$00,$00,$3C,$3C,$FF,$FF,$C3,$FF,$80,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$00,$00,$00,$03,$03,$C3,$C3,$E6,$E7,$36,$F7,$1C,$FF,$0C,$FF,$3C,$3C,$FF,$FF,$C3,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$01,$FF,$00,$00,$80,$80,$C0,$C0,$C0,$C0,$60,$E0,$7F,$FF,$FF,$FF,$80,$FF,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$C0,$C0,$F0,$F0,$06,$07,$06,$07,$07,$07,$03,$03,$03,$03,$01,$01,$00,$00,$00,$00,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$82,$FF,$E7,$FF,$7F,$7F,$06,$FF,$03,$FF,$01,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$C0,$FF,$03,$FF,$02,$FF,$06,$FF,$04,$FF,$00,$FF,$00,$FF,$03,$FF,$3F,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$80,$FF,$C0,$FF,$C0,$FF,$38,$F8,$1C,$FC,$0C,$FC,$06,$FE,$06,$FE,$03,$FF,$03,$FF,$03,$FF,$00,$00,$00,$00,$00,$00,$00,$00,$E0,$E0,$F0,$F0,$B8,$F8,$18,$F8,$00,$00,$00,$00,$00,$00,$00,$00,$03,$03,$0F,$0F,$1F,$1C,$3F,$30,$1F,$1F,$3F,$3F,$1E,$1E,$0C,$0C,$EC,$EC,$FC,$FC,$FE,$1E,$FF,$07,$F9,$FF,$FF,$FF,$3E,$3E,$78,$78,$F8,$F8,$70,$70,$D0,$D0,$D0,$D0,$FF,$FF,$FF,$FF,$3F,$3F,$0F,$0F,$37,$37,$7F,$7F,$7F,$7F,$37,$36,$C0,$FF,$E0,$FF,$FC,$FF,$FF,$F7,$FF,$F1,$FF,$C3,$FF,$03,$FF,$01,$01,$FF,$00,$FF,$00,$FF,$81,$FF,$F1,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$18,$F8,$18,$F8,$B0,$F0,$F0,$F0,$E0,$E0,$80,$80,$C0,$C0,$C0,$C0,$7F,$60,$7F,$60,$FF,$C0,$FF,$C0,$FF,$C0,$FF,$C0,$7F,$60,$7F,$60,$F0,$F0,$F0,$30,$F8,$18,$FC,$0C,$FE,$06,$FF,$01,$FF,$00,$FF,$00,$E3,$E2,$F7,$F6,$FF,$FE,$FF,$FC,$3F,$3C,$FF,$F0,$FF,$00,$FF,$00,$FF,$FF,$FF,$FF,$FF,$7F,$FF,$3F,$FF,$1F,$FF,$1E,$FF,$3E,$FF,$3E,$F0,$F0,$FC,$FC,$FE,$8E,$FE,$02,$FF,$03,$FF,$03,$FF,$03,$FF,$03,$3F,$30,$1F,$1C,$0F,$0E,$1F,$1F,$1F,$1F,$1F,$1F,$0F,$0F,$01,$01,$FF,$00,$FF,$00,$FF,$00,$FF,$E0,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$03,$FF,$07,$FF,$0F,$FF,$FF,$FF,$FF,$FF,$FF,$FD,$FD,$FC,$FC,$FF,$80,$FF,$E0,$FF,$F0,$FF,$F7,$FC,$FC,$E0,$E0,$80,$80,$10,$10,$FF,$1E,$F3,$73,$C0,$C0,$80,$80,$04,$04,$04,$04,$9F,$9F,$84,$84,$FF,$1E,$FF,$8C,$FF,$E4,$3F,$20,$3F,$30,$1F,$13,$1F,$13,$3F,$33,$FF,$03,$FE,$06,$FE,$06,$FE,$0E,$FC,$7C,$F0,$F0,$00,$00,$00,$00,$FC,$FC,$70,$70,$38,$38,$1E,$1E,$07,$07,$03,$03,$00,$00,$00,$00,$F8,$F8,$02,$02,$07,$07,$02,$02,$80,$80,$F0,$F0,$FF,$FF,$3F,$3F,$13,$13,$38,$38,$10,$10,$10,$10,$00,$00,$00,$00,$FF,$FF,$FF,$FF,$E4,$E4,$80,$80,$80,$80,$00,$00,$03,$03,$1F,$1F,$FE,$FE,$F0,$F0,$3E,$26,$7E,$6E,$7C,$5C,$F8,$F8,$E0,$E0,$80,$80,$00,$00,$00,$00,$00,$00,$00,$40,$39,$40,$3D,$41,$0E,$70,$06,$38,$10,$1E,$03,$03,$00,$02,$9C,$82,$3C,$82,$70,$0E,$60,$1C,$08,$78,$C0,$C0,$00,$00,$00,$02,$9C,$82,$3C,$82,$71,$0F,$63,$1F,$0B,$7B,$C7,$C7,$06,$07,$00,$00,$03,$03,$0E,$0E,$18,$18,$30,$30,$60,$60,$C0,$C0,$80,$80,$F8,$F8,$9C,$94,$3F,$27,$7C,$5C,$F0,$B0,$E0,$E6,$80,$87,$C0,$C7,$0F,$0F,$F8,$F8,$80,$86,$00,$06,$00,$30,$00,$36,$00,$36,$00,$B6,$F0,$F0,$00,$01,$00,$03,$00,$D9,$00,$ED,$00,$CD,$00,$CD,$00,$CD,$00,$00,$00,$80,$00,$C0,$00,$9E,$00,$B3,$00,$BF,$00,$B0,$00,$9F,$0F,$0F,$00,$00,$00,$00,$00,$60,$00,$7C,$00,$66,$00,$66,$00,$66,$F0,$F0,$1F,$1F,$01,$01,$00,$0C,$00,$0C,$00,$7C,$00,$CC,$00,$CC,$1F,$1F,$39,$29,$FC,$E4,$3E,$3A,$0F,$0D,$07,$07,$01,$01,$03,$E3,$00,$00,$C0,$C0,$70,$70,$18,$18,$0C,$0C,$06,$06,$03,$03,$01,$01,$C0,$C0,$60,$60,$30,$30,$18,$18,$0C,$0C,$06,$06,$03,$03,$01,$01,$40,$46,$60,$66,$20,$26,$30,$36,$70,$70,$D8,$D8,$8D,$8D,$07,$07,$00,$F6,$00,$76,$00,$30,$01,$01,$0F,$0F,$78,$78,$C0,$C0,$00,$00,$00,$C0,$00,$00,$0F,$0F,$F8,$F8,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$FF,$FF,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$06,$00,$00,$F0,$F0,$1F,$1F,$00,$00,$00,$00,$00,$00,$00,$00,$00,$CD,$00,$7D,$00,$01,$80,$80,$F0,$F0,$1E,$1E,$03,$03,$00,$00,$02,$B2,$06,$B6,$04,$B4,$0C,$EC,$0E,$0E,$1B,$1B,$B1,$B1,$E0,$E0,$03,$03,$06,$06,$0C,$0C,$18,$18,$30,$30,$60,$60,$C0,$C0,$80,$80

rom_padding_6105:
    ds 624, $00

; Audio systems on               
audio_init:
    ld a, $80
    ldh [rNR52], a 
    ld a, $77
    ldh [rNR50], a 
    ld a, $FF
    ldh [rNR51], a 
    ret

clear_demo_flag:
    xor a
    ld [w_demo_flag], a
    ret

set_demo_flag:
    ld a, $1
    ld [w_demo_flag], a
    ret

brick_type_handler:
    ldh a, [h_brick_type_last_hit]          
    dec a
    ld b, a
    ld e, $6
    call multiply
    ld hl, $1B87
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

set_ball_oob:
    ld a, $1
    jr .nop_jr ; no-op jump, possibly leftover from development
.nop_jr  
    ld [w_ball_oob], a    ; $1 = when ball is lost
    ret

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

rom_padding_641a:
    ds 998, $FF

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
    ld hl, $6FDE
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
    ld hl, $6FBB
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
    ld hl, $6FCA
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
    ld hl, $6FAC
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
    ld hl, $6FFC
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
    ld hl, $700B
    ld c, $10
    call ch1_initializer

.cancel_dark_grey_brick_sfx
    ret

.init_ball_launch_env_4_sfx:
    ld a, $7
    ld [w_current_sfx_active], a
    ld a, $4
    ld [w_sfx_envelope], a      
    ld hl, $701A
    ld c, $10
    call ch1_initializer
    ret

.init_point_countdown_env_5_sfx:
    ld a, $8
    ld [w_current_sfx_active], a
    ld a, $5
    ld [w_sfx_envelope], a      
    ld hl, $7029
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
    jp nz, .LAB_6f9c
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
    cp $1
    xor a
    ld [w_current_sfx_active], a
    jp .clear_sfx

.init_extra_life_env_6_sfx
    ld hl, $6FE3
    ld c, $10
    call ch1_initializer
    ret

.init_extra_life_env_5_sfx
    ld hl, $6FE8
    ld c, $10
    call ch1_initializer
    ret

.init_extra_life_env_4_sfx
    ld hl, $6FED
    ld c, $10
    call ch1_initializer
    ret

.init_extra_life_env_3_sfx
    ld hl, $6FF2
    ld c, $10
    call ch1_initializer
    ret

.init_extra_life_env_2_sfx
    ld hl, $6FF7
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
    jp nz, .LAB_6f9c
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
    ld hl, $6Fbb
    ld c, $10
    call ch1_initializer
    ret

.init_white_brick_env_3_sfx
    ld hl, $6Fc0
    ld c, $10
    call ch1_initializer
    ret

.init_white_brick_env_2_sfx
    ld hl, $6Fc5
    ld c, $10
    call ch1_initializer
    ret

.unbreakable_brick_sfx_env_decrementor
    ld a, [w_sfx_envelope_counter]
    inc a
    ld [w_sfx_envelope_counter], a
    cp $3
    jp nz, .LAB_6f9c
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
    ld hl, $6FCf
    ld c, $10
    call ch1_initializer
    ret

.init_unbreakable_brick_env_3_sfx
    ld hl, $6FD4
    ld c, $10
    call ch1_initializer
    ret

.init_unbreakable_brick_env_2_sfx
    ld hl, $6FD9
    ld c, $10
    call ch1_initializer
    ret

.paddle_collision_sfx_env_decrementor
    ld a, [w_sfx_envelope_counter]
    inc a
    ld [w_sfx_envelope_counter], a
    cp $5
    jp nz, .LAB_6f9c
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
    ld hl, $6FAC
    ld c, $10
    call ch1_initializer
    ret

.init_paddle_collision_env_3_sfx
    ld hl, $6FB1
    ld c, $10
    call ch1_initializer
    ret

.init_paddle_collision_env_2_sfx
    ld hl, $6FB6
    ld c, $10
    call ch1_initializer
    ret

.light_grey_brick_sfx_env_decrementor
    ld a, [w_sfx_envelope_counter]
    inc a
    ld [w_sfx_envelope_counter], a
    cp $5
    jp nz, .LAB_6f9c
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
    ld hl, $6FFC
    ld c, $10
    call ch1_initializer
    ret

.init_light_grey_brick_env_3_sfx
    ld hl, $7001
    ld c, $10
    call ch1_initializer
    ret

.init_light_grey_brick_env_2_sfx
    ld hl, $7006
    ld c, $10
    call ch1_initializer
    ret

.dark_grey_brick_sfx_env_decrementor
    ld a, [w_sfx_envelope_counter]
    inc a
    ld [w_sfx_envelope_counter], a
    cp $5
    jp nz, .LAB_6f9c
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
    ld hl, $700b
    ld c, $10
    call ch1_initializer
    ret

.init_dark_grey_brick_env_3_sfx
    ld hl, $7010
    ld c, $10
    call ch1_initializer
    ret

.init_dark_grey_brick_env_2_sfx
    ld hl, $7015
    ld c, $10
    call ch1_initializer
    ret

.ball_launch_sfx_env_decrementor
    ld a, [w_sfx_envelope_counter]
    inc a
    ld [w_sfx_envelope_counter], a
    cp $5
    jp nz, .LAB_6f9c
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
    ld hl, $701F
    ld c, $10
    call ch1_initializer
    ret

.init_ball_launch_env_2_sfx
    ld hl, $7024
    ld c, $10
    call ch1_initializer
    ret

.point_cooldown_sfx_env_decrementor
    ld a, [w_sfx_envelope_counter]
    inc a
    ld [w_sfx_envelope_counter], a
    cp $2
    jp nz, .LAB_6f9c
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
    ld hl, $702E
    ld c, $10
    call ch1_initializer
    ret

.init_point_cooldown_env_3_sfx
    ld hl, $7033
    ld c, $10
    call ch1_initializer
    ret

.init_point_cooldown_env_2_sfx
    ld hl, $7038
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
    cp $1e
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
    ret

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
; UNUSED/OLD CODE
    call debug_set_sfx_clear_flag
    ret

.clear_sfx:
    xor a
    ld [w_current_sfx_active], a
    ldh [rNR12], a  ; Mute CH1
    ld [w_sfx_envelope_counter], a
    ld [w_sfx_envelope], a      
    ret

.LAB_6f9c
    ret

; Copies 5 bytes of data from [hl] to [c] incrementally      *
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
; [2] paddle_sfx_env_3_data             
; [3] paddle_sfx_env_2_data             
; [4] white_brick_sfx_env_5|4_data      
; [5] white_brick_sfx_env_3_data        
; [6] white_brick_sfx_env_2_data        
; [7] unbreakable_brick_sfx_env_5_data  
; [8] unbreakable_brick_sfx_env_4_data  
; [9] unbreakable_brick_sfx_env_3_data  
; [10] unbreakable_brick_sfx_env_2_data 
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
    ld hl, $704C    ; executes when the player loses
    ld c, $20
    ld a, $49
    ld [w_ch4_pan_timer], a 
    ld a, $F
    ld [w_ch4_pan], a
    xor a
    ld [w_ch2_pan_active], a  ; disable CH2 panning during explosion SFX
    call ch4_initializer    ; enable CH4
    ret

; Triggers the explosion soundWrites 4 bytes that inits CH4

ch4_initializer:
    ld a, [hl+]     ; $704C = 00
    ldh [c], a      ; NR41: 0000 0000
    inc c
    ld a, [hl+]     ; $704D = F7
    ldh [c], a      ; NR42: 1111 0111
    inc c
    ld a, [hl+]     ; $704E = 57
    ldh [c], a      ; NR43: 0101 0111
    inc c
    ld a, [hl+]     ; $704F = 80
    ldh [c], a      ; NR44: 1000 000
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
    ld hl, $75E3
    ld a, h
    ld [w_ch2_pattern_ptr_hi], a
    ld a, l
    ld [w_ch2_pattern_ptr_lo], a
    ld hl, $7652
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
    ld hl, $76C3
    ld a, h
    ld [w_ch2_pattern_ptr_hi], a
    ld a, l
    ld [w_ch2_pattern_ptr_lo], a
    ld hl, $76D9
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
    ld hl, $76F0
    ld a, h
    ld [w_ch2_pattern_ptr_hi], a
    ld a, l
    ld [w_ch2_pattern_ptr_lo], a
    ld hl, $7712
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
    ld hl, $7733
    ld a, h
    ld [w_ch2_pattern_ptr_hi], a
    ld a, l
    ld [w_ch2_pattern_ptr_lo], a
    ld hl, $7738
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
    ld hl, $773B
    ld a, h
    ld [w_ch2_pattern_ptr_hi], a
    ld a, l
    ld [w_ch2_pattern_ptr_lo], a
    ld hl, $7750
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
    ld hl, $7765
    ld a, h
    ld [w_ch2_pattern_ptr_hi], a
    ld a, l
    ld [w_ch2_pattern_ptr_lo], a
    ld hl, $779B
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
    ld hl, $77D7
    ld a, h
    ld [w_ch2_pattern_ptr_hi], a
    ld a, l
    ld [w_ch2_pattern_ptr_lo], a
    ld hl, $780D
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
    ld hl, $7849
    ld a, h
    ld [w_ch2_pattern_ptr_hi], a
    ld a, l
    ld [w_ch2_pattern_ptr_lo], a
    ld hl, $785C
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
    ld hl, $7875
    ld a, h
    ld [w_ch2_pattern_ptr_hi], a
    ld a, l
    ld [w_ch2_pattern_ptr_lo], a
    ld hl, $7887
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
    ld hl, $789C
    ld a, h
    ld [w_ch2_pattern_ptr_hi], a
    ld a, l
    ld [w_ch2_pattern_ptr_lo], a
    ld hl, $78D6
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
    ld hl, $790F
    ld a, h
    ld [w_ch2_pattern_ptr_hi], a
    ld a, l
    ld [w_ch2_pattern_ptr_lo], a
    ld hl, $7919
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
    ld hl, $791F
    ld a, h
    ld [w_ch2_pattern_ptr_hi], a
    ld a, l
    ld [w_ch2_pattern_ptr_lo], a
    ld hl, $7988
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
    ld a, [w_ch2_pattern_ptr_hi]  ;if ch2 has finished playing
    ld h, a
    ld a, [w_ch2_pattern_ptr_lo]  
    ld l, a

pattern_read_loop:
    ld a, [hl+]
    bit $7, a
    jp nz, ch2_set_note_length
    cp $0
    jp z, mute_ch1
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
    ld hl, $7574
    ld d, $0
    ld e, a
    add hl, de
    ld a, [hl]  ; =>note_freq_hi_table
    ldh [rNR23], a 
    ld hl, $7531
    add hl, de
    ld a, [hl]  ; =>note_freq_lo_table
    ldh [rNR24], a 
    pop hl

.ch2_save_ptr
    xor a
    ld a, h
    ld [w_ch2_pattern_ptr_hi], a
    ld a, l
    ld [w_ch2_pattern_ptr_lo], a
    ld a, [w_ch2_note_length]     
    and A
    jr nz, ch3_note_length_decrement
    ld a, [w_ch2_note_length_max] 
    ld [w_ch2_note_length], a   

ch3_note_length_decrement:
    ld a, [w_ch3_note_length] ; if the ch2 note still is playing
    dec a
    ld [w_ch3_note_length], a   
    cp $0
    jp nz, LAB_745e
    ld a, [w_ch3_pattern_ptr_hi]  
    ld h, a
    ld a, [w_ch3_pattern_ptr_lo]  
    ld l, a

ch3_pattern_read_loop:
    ld a, [hl+]
    bit $7, a
    jp nz, LAB_748d
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
    ld hl, $7574
    ld d, $0
    ld e, a
    add hl, de
    ld a, [hl]  ; =>note_freq_hi_table
    ldh [rNR33], a 
    ld hl, $7531
    add hl, de
    ld a, [hl]  ; =>note_freq_lo_table
    ldh [rNR34], a 
    pop hl

ch3_save_ptr:
    ld a, h
    ld [w_ch3_pattern_ptr_hi], a
    ld a, l
    ld [w_ch3_pattern_ptr_lo], a
    ld a, [w_ch3_note_length]     
    and A
    jr nz, LAB_745e
    ld a, [w_ch3_note_length_max] 
    ld [w_ch3_note_length], a   

LAB_745e:
    ret

; loads ch3_waveform_data in intervals of $10     
load_ch3_waveform:
    ld hl, $7A6f
    ld c, $30

.LAB_7464
    ld a, [hl+]         ; =>ch3_waveform_data
    ldh [c], a          ; =>WAVE, a
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
    ld hl, $75B7
    ld d, $0
    ld e, a
    add hl, de
    ld a, [hl]  ; =>note_length_table
    ld [w_ch2_note_length], a   
    ld [w_ch2_note_length_max], a 
    pop hl
    jp pattern_read_loop

LAB_748d:
    push hl
    and $7F
    ld hl, $75B7
    ld d, $0
    ld e, a
    add hl, de
    ld a, [hl]  ; =>note_length_table)
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
    ldh [rNR51], a  ; $75 = $01,$11,$01,$01, — CH2 left, others mixed     
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

mute_ch1:
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

note_freq_table:    ; 16-bit address, little endian
    db $00,$C0,$80,$80,$81,$81,$81,$82,$82,$82,$83,$83,$83,$83,$84,$84,$84,$84,$84,$85,$85,$85,$85,$85,$85,$85,$86,$86,$86,$86,$86,$86,$86,$86,$86,$86,$86,$86,$87,$87,$87,$87,$87,$87,$87,$87,$87,$87,$87,$87,$87,$87,$87,$87,$87,$87,$87,$87,$87,$87,$87,$87,$87,$87,$87,$87,$87  ; lower nibble
    db $00,$00,$2C,$9D,$07,$6B,$C9,$23,$77,$C7,$12,$58,$9B,$DA,$16,$4F,$83,$B5,$E5,$11,$3B,$63,$88,$AC,$CE,$ED,$0B,$27,$42,$5B,$72,$89,$9E,$B2,$C4,$D6,$E7,$F7,$06,$14,$21,$2D,$39,$44,$4F,$59,$62,$6B,$73,$7B,$83,$8A,$90,$97,$9D,$A2,$A7,$AC,$B1,$B6,$BA,$BE,$C1,$C5,$C8,$CB,$CE  ; higher nibble

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

rom_padding_7a7f:
    ds 1393, $FF                

audio_update_thunk:
    jp audio_update

; Trampoline wrapper, likely a remnant of a banked development architecture.
; Alleyway is a 32KB ROM-only cart no MBC, no bank switching occurs at runtime.

stop_music_wrapper:
    call stop_music
    ret

rom_padding_7ff7:
    ds 9, $FF