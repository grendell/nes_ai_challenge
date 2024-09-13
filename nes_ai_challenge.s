.segment "HEADER"
; https://www.nesdev.org/wiki/INES
  .byte $4e, $45, $53, $1a ; iNES header identifier
  .byte $01                ; 1x 16KB PRG code
  .byte $01                ; 1x  8KB CHR data
  .byte $00                ; mapper 0 and horizontal mirroring
  .byte $00                ; mapper 0

.segment "VECTORS"
  .addr nmi, reset, 0

.segment "ZEROPAGE"
buttons: .res 1
button_mask: .res 1
waiting_for_nmi: .res 1

.include "system.inc"
.include "readjoy.inc"

.segment "CODE"
; memory map
;   $00 -   $ff: zero page (fast-access variables)
; $0100 - $01ff: stack (program flow)
; $0200 - $02ff: OAM shadow (next sprite update)
; $0300 - $07ff: unused
OAM_SHADOW = $0200

NUM_SPRITES = 2 * 8
INV_PALETTE_MASK = %11111100

.enum palette
  BUTTON_OFF = 0
  BUTTON_ON_GRAY = 1
  BUTTON_ON_RED = 2
.endenum

.proc reset
  ; https://www.nesdev.org/wiki/Init_code
  sei                    ; ignore IRQs
  cld                    ; disable decimal mode
  ldx #$40
  stx APU_FRAME_COUNTER  ; disable APU frame IRQ
  ldx #$ff
  txs                    ; set up stack
  inx                    ; now x = 0
  stx PPU_CTRL           ; disable NMI
  stx PPU_MASK           ; disable rendering
  stx DMC_FREQ           ; disable DMC IRQs

  ; clear vblank flag
  bit PPU_STATUS

  ; wait for first vblank
: bit PPU_STATUS
  bpl :-

  ; initialize cpu variables
  lda #0
  sta buttons
  sta waiting_for_nmi

  ; wait for second vblank
: bit PPU_STATUS
  bpl :-

  ; initialize ppu
  jsr init_palettes
  jsr init_sprites

  lda #0
  sta PPU_SCROLL
  sta PPU_SCROLL

  ; enable NMI and tall sprites
  lda #%10100000
  sta PPU_CTRL

game_loop:
  ; wait for frame to be completed
  inc waiting_for_nmi
: lda waiting_for_nmi
  bne :-

  jsr readjoy
  jsr update_sprites

  jmp game_loop
.endproc

.proc init_palettes
  ; set ppu address to palette entries ($3f00)
  lda #$3f
  sta PPU_ADDR
  lda #0
  sta PPU_ADDR

  ; loop through each palette entry, 32 total
  ldx #0
: lda palettes, x
  sta PPU_DATA
  inx
  cpx #32
  bne :-

  rts
.endproc

.proc init_sprites
  ; set initial contents of the OAM shadow
  ; this copy will be sent to the PPU during NMI
  ldx #0
: lda initial_oam, x
  sta OAM_SHADOW, x

  inx
  cpx #NUM_SPRITES * .sizeof(sprite)
  bne :-

  ; move the unused sprites off-screen
  lda #$ff
: sta OAM_SHADOW, x
  inx
  bne :-

  rts
.endproc

.proc update_sprites
  lda #1
  sta button_mask

  ; for each button mask,
  ; update the next two sprites' palette index
  ldx #0
: ldy #2
  lda button_mask
  and buttons
  beq off

on:
  lda button_mask
  and #BUTTON_A | BUTTON_B
  beq gray

red:
  lda OAM_SHADOW + sprite::attrs, x
  and #INV_PALETTE_MASK
  ora #palette::BUTTON_ON_RED
  sta OAM_SHADOW + sprite::attrs, x

  txa
  clc
  adc #.sizeof(sprite)
  tax

  dey
  bne red
  jmp next

gray:
  lda OAM_SHADOW + sprite::attrs, x
  and #INV_PALETTE_MASK
  ora #palette::BUTTON_ON_GRAY
  sta OAM_SHADOW + sprite::attrs, x

  txa
  clc
  adc #.sizeof(sprite)
  tax

  dey
  bne gray
  jmp next

off:
  lda OAM_SHADOW + sprite::attrs, x
  and #INV_PALETTE_MASK
  ; only necessary if BUTTON_ON_GRAY != 0
  ; ora #palette::BUTTON_ON_GRAY
  sta OAM_SHADOW + sprite::attrs, x

  txa
  clc
  adc #.sizeof(sprite)
  tax

  dey
  bne off

next:
  ; the carry bit will only be set after all
  ; button masks have been evaluated
  asl button_mask
  bcc :-

  rts
.endproc

.proc nmi
  ; retain previous value of a on the stack
  pha

  ; clear vblank flag
  bit PPU_STATUS

  ; update sprite OAM via DMA
  lda #>OAM_SHADOW
  sta OAM_DMA

  ; show sprites
  lda #%00010000
  sta PPU_MASK

  ; allow game loop to continue after interrupt
  lda #0
  sta waiting_for_nmi

  ; restore previous value of a before interrupt
  pla
  rti
.endproc

palettes:
  ; background palettes
  .byte $0f, $0f, $0f, $0f
  .byte $0f, $0f, $0f, $0f
  .byte $0f, $0f, $0f, $0f
  .byte $0f, $0f, $0f, $0f

  ; sprite palettes
  .byte $0f, $00, $0f, $0f ; button off
  .byte $0f, $10, $0f, $0f ; button on (gray)
  .byte $0f, $16, $0f, $0f ; button on (red)
  .byte $0f, $0f, $0f, $0f

initial_oam:
  ; right button (left)
  .byte 112, 20, FLIP_HORIZONTAL, 84
  ; right button (right)
  .byte 112, 18, FLIP_HORIZONTAL, 92

  ; left button (left)
  .byte 112, 18, 0, 52
  ; left button (right)
  .byte 112, 20, 0, 60

  ; down button (left)
  .byte 128, 14, FLIP_VERTICAL, 68
  ; down button (right)
  .byte 128, 16, FLIP_VERTICAL, 76

  ; up button (left)
  .byte 96, 14, 0, 68
  ; up button (right)
  .byte 96, 16, 0, 76

  ; start button (left)
  .byte 128, 10, 0, 132
  ; start button (right)
  .byte 128, 12, 0, 140

  ; select button (left)
  .byte 128, 6, 0, 108
  ; select button (right)
  .byte 128, 8, 0, 116

  ; B button (left)
  .byte 108, 0, 0, 160
  ; B button (right)
  .byte 108, 4, 0, 168

  ; A button (left)
  .byte 108, 0, 0, 180
  ; A button (right)
  .byte 108, 2, 0, 188

.segment "CHARS"
  ; 0
  .byte %00000000
  .byte %00011111
  .byte %00111111
  .byte %01111111
  .byte %01111111
  .byte %01111111
  .byte %01111111
  .byte %01111111
  .byte $00, $00, $00, $00, $00, $00, $00, $00

  ; 1
  .byte %01111111
  .byte %00111111
  .byte %00011111
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte $00, $00, $00, $00, $00, $00, $00, $00

  ; 2
  .byte %00000000
  .byte %10000000
  .byte %11000000
  .byte %11100000
  .byte %11100000
  .byte %11100000
  .byte %11100000
  .byte %11100000
  .byte $00, $00, $00, $00, $00, $00, $00, $00

  ; 3
  .byte %11100000
  .byte %11000000
  .byte %10001100
  .byte %00010010
  .byte %00011110
  .byte %00010010
  .byte %00010010
  .byte %00000000
  .byte $00, $00, $00, $00, $00, $00, $00, $00

  ; 4
  .byte %00000000
  .byte %10000000
  .byte %11000000
  .byte %11100000
  .byte %11100000
  .byte %11100000
  .byte %11100000
  .byte %11100000
  .byte $00, $00, $00, $00, $00, $00, $00, $00

  ; 5
  .byte %11100000
  .byte %11000000
  .byte %10011100
  .byte %00010010
  .byte %00011100
  .byte %00010010
  .byte %00011100
  .byte %00000000
  .byte $00, $00, $00, $00, $00, $00, $00, $00

  ; 6
  .byte %00000000
  .byte %00011111
  .byte %00111111
  .byte %01111111
  .byte %01111111
  .byte %00111111
  .byte %00011111
  .byte %00000000
  .byte $00, $00, $00, $00, $00, $00, $00, $00

  ; 7
  .byte %00000000
  .byte %00011001
  .byte %00100101
  .byte %00010001
  .byte %00001001
  .byte %00100101
  .byte %00011001
  .byte %00000000
  .byte $00, $00, $00, $00, $00, $00, $00, $00

  ; 8
  .byte %00000000
  .byte %11111000
  .byte %11111100
  .byte %11111110
  .byte %11111110
  .byte %11111100
  .byte %11111000
  .byte %00000000
  .byte $00, $00, $00, $00, $00, $00, $00, $00

  ; 9
  .byte %00000000
  .byte %11010000
  .byte %00010000
  .byte %11010000
  .byte %00010000
  .byte %00010000
  .byte %11011100
  .byte %00000000
  .byte $00, $00, $00, $00, $00, $00, $00, $00

  ; 10
  .byte %00000000
  .byte %00011111
  .byte %00111111
  .byte %01111111
  .byte %01111111
  .byte %00111111
  .byte %00011111
  .byte %00000000
  .byte $00, $00, $00, $00, $00, $00, $00, $00

  ; 11
  .byte %00000000
  .byte %00110011
  .byte %01001000
  .byte %00100000
  .byte %00010000
  .byte %01001000
  .byte %00110000
  .byte %00000000
  .byte $00, $00, $00, $00, $00, $00, $00, $00

  ; 12
  .byte %00000000
  .byte %11111000
  .byte %11111100
  .byte %11111110
  .byte %11111110
  .byte %11111100
  .byte %11111000
  .byte %00000000
  .byte $00, $00, $00, $00, $00, $00, $00, $00

  ; 13
  .byte %00000000
  .byte %11100110
  .byte %10001001
  .byte %10001001
  .byte %10001111
  .byte %10001001
  .byte %10001001
  .byte %00000000
  .byte $00, $00, $00, $00, $00, $00, $00, $00

  ; 14
  .byte %00000000
  .byte %00000001
  .byte %00000011
  .byte %00000111
  .byte %00001111
  .byte %00011111
  .byte %00111111
  .byte %01111111
  .byte $00, $00, $00, $00, $00, $00, $00, $00

  ; 15
  .byte %00011111
  .byte %00011111
  .byte %00011111
  .byte %00011111
  .byte %00011111
  .byte %00011111
  .byte %00011111
  .byte %00000000
  .byte $00, $00, $00, $00, $00, $00, $00, $00

  ; 16
  .byte %00000000
  .byte %10000000
  .byte %11000000
  .byte %11100000
  .byte %11110000
  .byte %11111000
  .byte %11111100
  .byte %11111110
  .byte $00, $00, $00, $00, $00, $00, $00, $00

  ; 17
  .byte %11111000
  .byte %11111000
  .byte %11111000
  .byte %11111000
  .byte %11111000
  .byte %11111000
  .byte %11111000
  .byte %00000000
  .byte $00, $00, $00, $00, $00, $00, $00, $00

  ; 18
  .byte %00000000
  .byte %00000001
  .byte %00000011
  .byte %00000111
  .byte %00001111
  .byte %00011111
  .byte %00111111
  .byte %01111111
  .byte $00, $00, $00, $00, $00, $00, $00, $00

  ; 19
  .byte %01111111
  .byte %00111111
  .byte %00011111
  .byte %00001111
  .byte %00000111
  .byte %00000011
  .byte %00000001
  .byte %00000000
  .byte $00, $00, $00, $00, $00, $00, $00, $00

  ; 20
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %11111110
  .byte %11111110
  .byte %11111110
  .byte %11111110
  .byte %11111110
  .byte $00, $00, $00, $00, $00, $00, $00, $00

  ; 21
  .byte %11111110
  .byte %11111110
  .byte %11111110
  .byte %11111110
  .byte %11111110
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte $00, $00, $00, $00, $00, $00, $00, $00