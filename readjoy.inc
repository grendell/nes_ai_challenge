.segment "CODE"

; https://www.nesdev.org/wiki/Controller_reading_code

; At the same time that we strobe bit 0, we initialize the ring counter
; so we're hitting two birds with one stone here
readjoy:
    lda #$01
    ; While the strobe bit is set, buttons will be continuously reloaded.
    ; This means that reading from JOYPAD1 will only return the state of the
    ; first button: button A.
    sta JOYPAD1
    sta buttons
    lsr a        ; now A is 0
    ; By storing 0 into JOYPAD1, the strobe bit is cleared and the reloading stops.
    ; This allows all 8 buttons (newly reloaded) to be read from JOYPAD1.
    sta JOYPAD1
loop:
    lda JOYPAD1
    lsr a        ; bit 0 -> Carry
    rol buttons  ; Carry -> bit 0; bit 7 -> Carry
    bcc loop
    rts

.if 0
; Google Gemini Advanced
; version: 2024.09.04

; prompt: Please generate a ca65-compatible 6502 assembly subroutine named readjoy to populate
; a variable named buttons with the current state of the buttons on player 1's controller.

; results: Does not build (Error: Syntax error)

; output:
; Subroutine: readjoy
; Purpose:  Reads the button states from player 1's controller
;           and stores them in the "buttons" variable.
;           Bit assignments in "buttons":
;           Bit 0: A button
;           Bit 1: B button
;           Bit 2: Select button
;           Bit 3: Start button
;           Bit 4: Up button
;           Bit 5: Down button
;           Bit 6: Left button
;           Bit 7: Right button

readjoy:
        LDA #$01        ; Initialize data direction register for controller port
        STA $4016       ; (Assuming controller is connected to port 1)

        LDA #$00        ; Initialize buttons variable
        STA buttons      ; Store the initial value

        LDA #$40        ; Strobe the controller
        STA $4016

        LDA $4016       ; Read the first button state

        ; Check each button and set corresponding bits in "buttons"

        ; A button
        AND #$01        ; Mask all bits except bit 0
        BEQ +           ; If A button is not pressed, skip
        ORA #$01        ; Set bit 0 in "buttons"
+
        ; B button
        LDA $4016       ; Read the next button state
        AND #$01        ; Mask all bits except bit 0
        BEQ +           ; If B button is not pressed, skip
        ORA #$02        ; Set bit 1 in "buttons"
+
        ; Select button
        LDA $4016       ; Read the next button state
        AND #$01        ; Mask all bits except bit 0
        BEQ +           ; If Select button is not pressed, skip
        ORA #$04        ; Set bit 2 in "buttons"
+
        ; Start button
        LDA $4016       ; Read the next button state
        AND #$01        ; Mask all bits except bit 0
        BEQ +           ; If Start button is not pressed, skip
        ORA #$08        ; Set bit 3 in "buttons"
+
        ; Up button
        LDA $4016       ; Read the next button state
        AND #$01        ; Mask all bits except bit 0
        BEQ +           ; If Up button is not pressed, skip
        ORA #$10        ; Set bit 4 in "buttons"
+
        ; Down button
        LDA $4016       ; Read the next button state
        AND #$01        ; Mask all bits except bit 0
        BEQ +           ; If Down button is not pressed, skip
        ORA #$20        ; Set bit 5 in "buttons"
+
        ; Left button
        LDA $4016       ; Read the next button state
        AND #$01        ; Mask all bits except bit 0
        BEQ +           ; If Left button is not pressed, skip
        ORA #$40        ; Set bit 6 in "buttons"
+
        ; Right button
        LDA $4016       ; Read the next button state
        AND #$01        ; Mask all bits except bit 0
        BEQ +           ; If Right button is not pressed, skip
        ORA #$80        ; Set bit 7 in "buttons"
+

        STA buttons      ; Store the final button states

        RTS             ; Return from subroutine
.endif

.if 0
; Google Gemini Advanced + manual syntax correction
; version: 2024.09.04

; prompt: Please generate a ca65-compatible 6502 assembly subroutine named readjoy to populate
; a variable named buttons with the current state of the buttons on player 1's controller.

; results: Incorrect results.
; * When right is pressed, right and A are reported as pressed.
; * No other buttons are ever reported as pressed.
; * Each LDA $4016 replaces the (malformed) previous result.
; * Each AND #$01 unconditionally clears the seven high bits of A.
; * Each ORA conditionally sets the wrong bit in A, based on the lowest bit of A.

; output:
readjoy:
        LDA #$01        ; Initialize data direction register for controller port
        STA $4016       ; (Assuming controller is connected to port 1)

        LDA #$00        ; Initialize buttons variable
        STA buttons      ; Store the initial value

        LDA #$40        ; Strobe the controller
        STA $4016

        LDA $4016       ; Read the first button state

        ; Check each button and set corresponding bits in "buttons"

        ; A button
        AND #$01        ; Mask all bits except bit 0
        BEQ :+          ; If A button is not pressed, skip
        ORA #$01        ; Set bit 0 in "buttons"
:
        ; B button
        LDA $4016       ; Read the next button state
        AND #$01        ; Mask all bits except bit 0
        BEQ :+          ; If B button is not pressed, skip
        ORA #$02        ; Set bit 1 in "buttons"
:
        ; Select button
        LDA $4016       ; Read the next button state
        AND #$01        ; Mask all bits except bit 0
        BEQ :+          ; If Select button is not pressed, skip
        ORA #$04        ; Set bit 2 in "buttons"
:
        ; Start button
        LDA $4016       ; Read the next button state
        AND #$01        ; Mask all bits except bit 0
        BEQ :+           ; If Start button is not pressed, skip
        ORA #$08        ; Set bit 3 in "buttons"
:
        ; Up button
        LDA $4016       ; Read the next button state
        AND #$01        ; Mask all bits except bit 0
        BEQ :+          ; If Up button is not pressed, skip
        ORA #$10        ; Set bit 4 in "buttons"
:
        ; Down button
        LDA $4016       ; Read the next button state
        AND #$01        ; Mask all bits except bit 0
        BEQ :+          ; If Down button is not pressed, skip
        ORA #$20        ; Set bit 5 in "buttons"
:
        ; Left button
        LDA $4016       ; Read the next button state
        AND #$01        ; Mask all bits except bit 0
        BEQ :+          ; If Left button is not pressed, skip
        ORA #$40        ; Set bit 6 in "buttons"
:
        ; Right button
        LDA $4016       ; Read the next button state
        AND #$01        ; Mask all bits except bit 0
        BEQ :+          ; If Right button is not pressed, skip
        ORA #$80        ; Set bit 7 in "buttons"
:

        STA buttons      ; Store the final button states

        RTS             ; Return from subroutine
.endif

.if 0
; Microsoft Copilot
; date: 2024.09.04

; prompt: Please generate a ca65-compatible 6502 assembly subroutine named readjoy to populate
; a variable named buttons with the current state of the buttons on player 1's controller.

; results: Success!
; notes: When compared to the example solution, this solution consumes slightly more code space
; but executes in slightly fewer CPU cycles by omitting the bcc loop.

; output:
.proc readjoy
    lda #$01       ; Select player 1
    sta $4016      ; Write to the joystick port
    lda #$00       ; Clear the accumulator
    sta $4016      ; Write to the joystick port again to reset

    lda $4016      ; Read the first button state
    lsr            ; Shift right to get the button state in the carry flag
    rol buttons    ; Rotate left through carry into the buttons variable

    lda $4016      ; Read the second button state
    lsr
    rol buttons

    lda $4016      ; Read the third button state
    lsr
    rol buttons

    lda $4016      ; Read the fourth button state
    lsr
    rol buttons

    lda $4016      ; Read the fifth button state
    lsr
    rol buttons

    lda $4016      ; Read the sixth button state
    lsr
    rol buttons

    lda $4016      ; Read the seventh button state
    lsr
    rol buttons

    lda $4016      ; Read the eighth button state
    lsr
    rol buttons

    rts            ; Return from subroutine
.endproc
.endif

.if 0
; ChatGPT
; version: 2024.08.08

; prompt: Please generate a ca65-compatible 6502 assembly subroutine named readjoy to populate
; a variable named buttons with the current state of the buttons on player 1's controller.

; results: Incorrect results.
; * Each lsr JOYPAD1 will load the next button state into the carry bit, but it also stores an
;   unconditional 0 back to $4016, which will bring the voltage to the controller's 4021 latch
;   line low while already in output mode.
; notes: Unnecessarily clobbers X.

; output:
; Read controller subroutine
readjoy:
    lda #$01                ; Set strobe high
    sta JOYPAD1             ; Write to controller port
    lda #$00                ; Set strobe low
    sta JOYPAD1             ; Write to controller port again

    ldx #$08                ; Set counter to 8 (8 buttons)
    lda #$00                ; Clear A register for storing the button states

read_loop:
    lsr JOYPAD1             ; Read button state into carry
    rol A                   ; Rotate carry into A register
    dex                     ; Decrement button counter
    bne read_loop           ; Continue loop until all 8 buttons are read

    sta buttons             ; Store result in 'buttons' variable
    rts                     ; Return from subroutine
.endif

.if 0
; Meta AI
; version: Llama 3.1-405B • Preview

; prompt: Please generate a ca65-compatible 6502 assembly subroutine named readjoy to populate
; a variable named buttons with the current state of the buttons on player 1's controller.

; results: Incorrect results.
; * LSR buttons unconditionally shifts the current button state out of buttons.
; * readjoy_clear conditionally clears all bits in buttons, if the current button is not pressed.
; notes: Unnecessarily clobbers X.  Unclear whether comments use LSb 0 or MSb 0.

; output:
; -----------------------------------------------------------------------------
; readjoy: Read the state of player 1's controller buttons
; -----------------------------------------------------------------------------
; Outputs:
;   buttons: A byte containing the current state of the buttons
;            (bit 0: A, bit 1: B, bit 2: Select, bit 3: Start,
;             bit 4: Up, bit 5: Down, bit 6: Left, bit 7: Right)
; -----------------------------------------------------------------------------

readjoy:
    LDA #$01     ; Latch the controller
    STA $4016
    LDA #$00     ; Clear the latch
    STA $4016

    LDX #$08     ; Loop 8 times to read the 8 buttons
readjoy_loop:
    LDA $4016    ; Read the controller
    AND #$01     ; Check the state of the current button
    BEQ readjoy_clear
    ORA buttons  ; Set the corresponding bit in the buttons variable
    STA buttons
    JMP readjoy_next
readjoy_clear:
    AND #$FE     ; Clear the corresponding bit in the buttons variable
    STA buttons
readjoy_next:
    LSR buttons  ; Shift the buttons variable right to prepare for the next bit
    DEX
    BNE readjoy_loop

    RTS
.endif