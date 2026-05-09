; Hardware-dependent code, C equivalent is more unstable and inefficient.

SECTION "rom0.asm", ROM0[$0000]

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