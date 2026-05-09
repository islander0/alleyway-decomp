DEF IE_REGISTER EQU $FFFF

SECTION "VBlank", ROM0[$01EF]

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

SECTION "Wait Frames", ROM0[$0257]

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
; compares consecutive SB reads and latches a filtered 1 -> 0
; transition on bit 7 into FF93 (used as a rare,
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

    ld hl, IE_REGISTER
    set $3, [hl]    ; 0000 1000: Serial interrupt handler enabled

    ret

SECTION "Debug VBlank", ROM0[$0446]

debug_disable_vblank:
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