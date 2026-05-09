DEF TILEMAP_PATCH_TABLE_START   EQU $4A3C

SECTION "Level Load Handler", ROM0[$4603]

level_load_handler:
    call lcd_disable_and_wait_vblank
    call disable_interrupts_save
    call load_tile_map_0
    call load_tile_map_1
    call load_main_oam_buffer
    call stop_music_wrapper

    ld a, $7F
    ldh [rWX], a
    ld a, $0
    ldh [rWY], a

    ldh a, [h_lcdc_mirror]
    or $60
    ldh [h_lcdc_mirror], a

    xor a   ; useless
    ldh a, [h_brick_scroll_flag]    ; useless

    ld a, $8
    ldh [rLYC], a
    ld a, $44
    ldh [rSTAT], a

    ldh a, [h_joypad_pressed]
    or 2    ; 0000 0010
    or 8    ; 0000 1000
    ldh [h_joypad_pressed], a   ; flip bit 1 & 3
    
    ld a, $E4
    call set_palette_data

    ld de, TILEMAP_PATCH_TABLE_START
    call process_copy_table
    
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
    call process_copy_table
    ld a, $0
    call set_palette_data

.LAB_4660
    call load_wall_oam_buffer
    call interrupt_enable
    jp lcd_ppu_enable