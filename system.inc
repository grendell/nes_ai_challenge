.segment "CODE"
; https://www.nesdev.org/wiki/PPU_registers
PPU_CTRL = $2000
PPU_MASK = $2001
PPU_STATUS = $2002
PPU_SCROLL = $2005
PPU_ADDR = $2006
PPU_DATA = $2007
OAM_DMA = $4014

; https://www.nesdev.org/wiki/APU_registers
DMC_FREQ = $4010
SND_CHN = $4015
APU_FRAME_COUNTER = $4017

; https://www.nesdev.org/wiki/Controller_reading_code
JOYPAD1 = $4016
BUTTON_A = %10000000
BUTTON_B = %01000000
BUTTON_SELECT = %00100000
BUTTON_START = %00010000
BUTTON_UP = %00001000
BUTTON_DOWN = %00000100
BUTTON_LEFT = %00000010
BUTTON_RIGHT = %00000001

; https://www.nesdev.org/wiki/PPU_OAM
.struct sprite
  y_pos .byte
  tile .byte
  attrs .byte
  x_pos .byte
.endstruct

FLIP_HORIZONTAL = %01000000
FLIP_VERTICAL = %10000000