#pragma once

#include <stdint.h>

extern void vblank_handler(void);
extern void wait_vblank(void);
extern void wait_frames(uint8_t frames);