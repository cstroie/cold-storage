; clock.asm: the machine's clock, for the ticks. DigitalRerun has a clock device on port 20:
; OUT latches a record, 15 INs read it, bytes 11-14 are milliseconds of machine time, which
; follows the machine's speed setting. With it, a tick is 100 ms of it whatever the speed;
; without it (a real Z80, another emulator) a busy-wait calibrated for 4 MHz.

CLKPORT equ     20
TICKMS  equ     100
DLY_OUT equ     110             ; outer loops of 256 x DJNZ (13 T) = 3328 T, ~100 ms at 4 MHz

; clkinit: is there a clock? (it answers 1 to the first IN after a latch)
clkinit: out    (CLKPORT),a
        in      a,(CLKPORT)
        cp      1
        ld      a,0
        jr      nz,ci1
        inc     a
ci1:    ld      (hasclk),a
        or      a
        ret     z
        call    readms
        ld      de,TICKMS
        add     hl,de
        ld      (nextms),hl
        ret

; readms: HL = the low 16 bits of the clock's milliseconds
readms: out     (CLKPORT),a
        ld      b,11
rm1:    in      a,(CLKPORT)
        djnz    rm1
        in      a,(CLKPORT)
        ld      l,a
        in      a,(CLKPORT)
        ld      h,a
        ret

; tickwait: until the next tick. By the clock, 100 ms after the last one (or now, if more
; than a second behind: no rush to catch up); by the busy-wait without it.
tickwait: ld    a,(hasclk)
        or      a
        jp      z,delay
tw1:    call    readms
        ld      de,(nextms)
        or      a
        sbc     hl,de           ; now - due: negative, not yet
        bit     7,h
        jr      nz,tw1
        ld      de,1000         ; more than a second late: start afresh
        sbc     hl,de
        jr      nc,tw2
        ld      hl,(nextms)
        ld      de,TICKMS
        add     hl,de
        ld      (nextms),hl
        ret
tw2:    call    readms
        ld      de,TICKMS
        add     hl,de
        ld      (nextms),hl
        ret

delay:  ld      c,DLY_OUT
dly1:   ld      b,0
dly2:   djnz    dly2
        dec     c
        jr      nz,dly1
        ret
