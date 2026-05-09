#pragma once
#include <stdint.h>

#define TILE_BLOCK_1_OFFSET 0x80

typedef struct VRAM {
    uint8_t tile_block_0[2048];    // $8000
    uint8_t tile_block_1[2048];    // $8800
    uint8_t tile_block_2[2048];    // $9000

    uint8_t tile_map_0[1024];           // $9800
    uint8_t tile_map_1[1024];           // $9C00
} VRAM;

enum TILE_BLOCK_0 {
    // paddle and ball
    PADDLE_EDGE_CLOSED = 0x00,
    PADDLE_CLOSED = 0x01,
    PADDLE_EDGE_OPEN = 0x02,
    PADDLE_OPEN_FULL = 0x03,
    PADDLE_OPEN_PARTIAL = 0x04,
    PADDLE_EDGE_SMALL = 0x20,

    BALL = 0x05,

    // mario
    MARIO_HEAD_LEFT_0 = 0x06,
    MARIO_HEAD_RIGHT_0 = 0x07,
    MARIO_BODY_LEFT_0 = 0x08,
    MARIO_BODY_RIGHT_0 = 0x09,

    MARIO_HEAD_LEFT_1 = 0x0A,
    MARIO_HEAD_RIGHT_1 = 0x0B,
    MARIO_BODY_LEFT_1 = 0x0C,
    MARIO_BODY_RIGHT_1 = 0x0D,

    MARIO_HEAD_LEFT_2 = 0xE,
    MARIO_HEAD_RIGHT_2 = 0xF,
    MARIO_BODY_LEFT_2 = 0x10,
    MARIO_BODY_RIGHT_2 = 0x11,

    MARIO_HEAD_LEFT_3 = 0x12,
    MARIO_HEAD_RIGHT_3 = 0x13,
    MARIO_BODY_LEFT_3 = 0x14,
    MARIO_BODY_RIGHT_3 = 0x15,

    MARIO_HEAD_LEFT_4 = 0x16,
    MARIO_HEAD_RIGHT_4 = 0x17,
    MARIO_BODY_LEFT_4 = 0x18,
    MARIO_BODY_RIGHT_4 = 0x19,

    MARIO_HEAD_LEFT_SURPRISE = 0x1A,

    // explosion
    EXPLOSION_0 = 0x1B,
    EXPLOSION_2 = 0x1C,
    EXPLOSION_3 = 0x1D,
    EXPLOSION_4 = 0x1E,
    EXPLOSION_5 = 0x1F,

    // mario wink
    MARIO_WINK_0 = 0x21,
    MARIO_WINK_1 = 0x22,
    MARIO_WINK_2 = 0x23,
    MARIO_WINK_3 = 0x24,
    MARIO_WINK_4 = 0x25,
    MARIO_WINK_5 = 0x26,
};

enum TILE_BLOCK_1 {
    // alphanumeric set
    ZERO = 0x80,
    ONE = 0x81,
    TWO = 0x82,
    THREE = 0x83,
    FOUR = 0x84,
    FIVE = 0x85,
    SIX = 0x86,
    SEVEN = 0x87,
    EIGHT = 0x88,
    NINE = 0x89,
    A = 0x8A,
    B = 0x8B,
    C = 0x8C,
    D = 0x8D,
    E = 0x8E,
    F = 0x8F,
    G = 0x90,
    H = 0x91,
    I = 0x92,
    J = 0x93,
    K = 0x94,
    L = 0x95,
    M = 0x96,
    N = 0x97,
    O = 0x98,
    P = 0x99,
    Q = 0x9A,
    R = 0x9B,
    S = 0x9C,
    T = 0x9D,
    U = 0x9E,
    V = 0x9F,
    W = 0xA0,
    X = 0xA1,
    Y = 0xA2,
    Z = 0xA3,

    // background
    BG_WHITE = 0xA4,
    BG_LIGHT_GREY = 0xA5,
    BG_DARK_GREY = 0xA6,
    BG_BLACK = 0xA7,

    //bricks
    BRICK_WHITE_FULL = 0xA8,
    BRICK_LIGHT_GREY_FULL = 0xA9,
    BRICK_DARK_GREY_FULL = 0xAA,

    BRICK_WHITE_HIGH = 0xAB,
    BRICK_LIGHT_GREY_HIGH = 0xAC,
    BRICK_DARK_GREY_HIGH = 0xAD,

    BRICK_WHITE_LOW = 0xAE,
    BRICK_LIGHT_GREY_LOW = 0xAF,
    BRICK_DARK_GREY_LOW = 0xB0,

    BRICK_UNBREAKABLE = 0xB3,

    // misc.
    LIFE_ICON = 0xB1,

    WALL_VERTICAL = 0xB4,
    WALL_HORIZONTAL = 0xB5,
    WALL_UL_CORNER = 0xBD,
    WALL_UR_CORNER = 0xBE,

    TIMES_SIGN = 0xB2,
    EQUALS_SIGN = 0xB6,
    DOT = 0xB7,

    CLEAR = 0xFF,

    // compressed text
    SCORE_TEXT_0 = 0xB8,
    SCORE_TEXT_1 = 0xB9,
    SCORE_TEXT_2 = 0xBA,
    SCORE_TEXT_3 = 0xBB,

    STAGE_SPECIAL_TEXT_0 = 0xC0,
    STAGE_SPECIAL_TEXT_1 = 0xC1,
    STAGE_SPECIAL_TEXT_2 = 0xC2,
    STAGE_SPECIAL_TEXT_3 = 0xC3,
    STAGE_SPECIAL_TEXT_4 = 0xC4,
    STAGE_SPECIAL_TEXT_5 = 0xC5,
    STAGE_SPECIAL_TEXT_6 = 0xC6,
    STAGE_SPECIAL_TEXT_7 = 0xC7,
    STAGE_SPECIAL_TEXT_8 = 0xC8,

    // 10 K score tiles
    SCORE_FLOWER = 0xBF,    
    SCORE_MUSHROOM = 0xBC,
    SCORE_STAR = 0xC9
};

enum TILE_BLOCK_2 {
    // title screen
    ALLEYWAY_0 = 0x00,
    ALLEYWAY_1 = 0x01,
    ALLEYWAY_2 = 0x02,
    ALLEYWAY_3 = 0x03,
    ALLEYWAY_4 = 0x04,
    ALLEYWAY_5 = 0x05,
    ALLEYWAY_6 = 0x06,
    ALLEYWAY_7 = 0x07,
    ALLEYWAY_8 = 0x08,
    ALLEYWAY_9 = 0x09,
    ALLEYWAY_10 = 0x0A,
    ALLEYWAY_11 = 0x0B,
    ALLEYWAY_12 = 0x0C,
    ALLEYWAY_13 = 0x0D,
    ALLEYWAY_14 = 0x0E,
    ALLEYWAY_15 = 0x0F,
    ALLEYWAY_16 = 0x10,
    ALLEYWAY_17 = 0x11,
    ALLEYWAY_18 = 0x12,
    ALLEYWAY_19 = 0x13,
    ALLEYWAY_20 = 0x14,
    ALLEYWAY_21 = 0x15,
    ALLEYWAY_22 = 0x16,
    ALLEYWAY_23 = 0x17,

    // boot nintendo logo
    BOOT_LOGO_0 = 0x18,
    BOOT_LOGO_1 = 0x19,
    BOOT_LOGO_2 = 0x1A,
    BOOT_LOGO_3 = 0x1B,
    BOOT_LOGO_4 = 0x1C,
    BOOT_LOGO_5 = 0x1D,
    BOOT_LOGO_6 = 0x1E,

    // misc.
    EXCLAMATION_POINT = 0x1F,

    // win screen
    WIN_SCREEN_0 = 0x20,
    WIN_SCREEN_1 = 0x21,
    WIN_SCREEN_2 = 0x22,
    WIN_SCREEN_3 = 0x23,
    WIN_SCREEN_4 = 0x24,
    WIN_SCREEN_5 = 0x25,
    WIN_SCREEN_6 = 0x26,
    WIN_SCREEN_7 = 0x27,
    WIN_SCREEN_8 = 0x28,
    WIN_SCREEN_9 = 0x29,
    WIN_SCREEN_10 = 0x2A,
    WIN_SCREEN_11 = 0x2B,
    WIN_SCREEN_12 = 0x2C,
    WIN_SCREEN_13 = 0x2D,
    WIN_SCREEN_14 = 0x2E,
    WIN_SCREEN_15 = 0x2F,

    WIN_SCREEN_16 = 0x30,
    WIN_SCREEN_17 = 0x31,
    WIN_SCREEN_18 = 0x32,
    WIN_SCREEN_19 = 0x33,
    WIN_SCREEN_20 = 0x34,
    WIN_SCREEN_21 = 0x35,
    WIN_SCREEN_22 = 0x36,
    WIN_SCREEN_23 = 0x37,
    WIN_SCREEN_24 = 0x38,
    WIN_SCREEN_25 = 0x39,
    WIN_SCREEN_26 = 0x3A,
    WIN_SCREEN_27 = 0x3B,
    WIN_SCREEN_28 = 0x3C,
    WIN_SCREEN_29 = 0x3D,
    WIN_SCREEN_30 = 0x3E,
    WIN_SCREEN_31 = 0x3F,

    WIN_SCREEN_32 = 0x40,
    WIN_SCREEN_33 = 0x41,
    WIN_SCREEN_34 = 0x42,
    WIN_SCREEN_35 = 0x43,
    WIN_SCREEN_36 = 0x44,
    WIN_SCREEN_37 = 0x45,
    WIN_SCREEN_38 = 0x46,
    WIN_SCREEN_39 = 0x47,
    WIN_SCREEN_40 = 0x48,
    WIN_SCREEN_41 = 0x49,
    WIN_SCREEN_42 = 0x4A,
    WIN_SCREEN_43 = 0x4B,
    WIN_SCREEN_44 = 0x4C,
    WIN_SCREEN_45 = 0x4D,
    WIN_SCREEN_46 = 0x4E,
    WIN_SCREEN_47 = 0x4F,

    WIN_SCREEN_48 = 0x50,
    WIN_SCREEN_49 = 0x51,
    WIN_SCREEN_50 = 0x52,
    WIN_SCREEN_51 = 0x53,
    WIN_SCREEN_52 = 0x54,
    WIN_SCREEN_53 = 0x55,
    WIN_SCREEN_54 = 0x56,
    WIN_SCREEN_55 = 0x57,
    WIN_SCREEN_56 = 0x58,
};