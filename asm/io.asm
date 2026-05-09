; Joypad input
DEF rP1     EQU $FF00

; Serial transfer
DEF rSB     EQU $FF01
DEF rSC     EQU $FF02   ; used as a rare, hardware-derived init condition, see: serial_falling_edge_detector_bit7 ($0272)

; Timer and divider
DEF rDIV    EQU $FF04
DEF rTIMA   EQU $FF05
DEF rTMA    EQU $FF06
DEF rTAC    EQU $FF07

; Interrupts
DEF rIF     EQU $FF0F

; Audio
DEF rNR10   EQU $FF10
DEF rNR11   EQU $FF11
DEF rNR12   EQU $FF12
DEF rNR13   EQU $FF13
DEF rNR14   EQU $FF14
DEF rNR21   EQU $FF16
DEF rNR22   EQU $FF17
DEF rNR23   EQU $FF18
DEF rNR24   EQU $FF19
DEF rNR30   EQU $FF1A
DEF rNR31   EQU $FF1B
DEF rNR32   EQU $FF1C
DEF rNR33   EQU $FF1D
DEF rNR34   EQU $FF1E
DEF rNR41   EQU $FF20
DEF rNR42   EQU $FF21
DEF rNR43   EQU $FF22
DEF rNR44   EQU $FF23
DEF rNR50   EQU $FF24
DEF rNR51   EQU $FF25
DEF rNR52   EQU $FF26

; Wave pattern RAM: $FF30–$FF3F
DEF rWAVE   EQU $FF30

; LCD Control, Status, Position, Scrolling, and Palettes
DEF rLCDC   EQU $FF40
DEF rSTAT   EQU $FF41
DEF rSCY    EQU $FF42
DEF rSCX    EQU $FF43
DEF rLY     EQU $FF44
DEF rLYC    EQU $FF45
DEF rDMA    EQU $FF46
DEF rBGP    EQU $FF47
DEF rOBP0   EQU $FF48
DEF rOBP1   EQU $FF49
DEF rWY     EQU $FF4A
DEF rWX     EQU $FF4B

; Boot ROM mapping control
DEF rBANK   EQU $FF50   ; Unused in Alleyway (no MBC)

; Interrupts Enable
DEF rIE     EQU $FFFF