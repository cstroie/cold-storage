; save.asm: COLDSTOR.SAV, five records: the state, then the sleepers

SAVEREC equ     5

fcbclr: ld      hl,fcb_sav+12
        ld      de,fcb_sav+13
        ld      (hl),0
        ld      bc,23
        ldir
        ret

save:   call    fcbclr
        ld      de,fcb_sav
        ld      c,19
        call    BDOS
        call    fcbclr
        ld      de,fcb_sav
        ld      c,22
        call    BDOS
        inc     a
        ret     z               ; the disk is full: no save
        ld      hl,state
        ld      b,SAVEREC
sv1:    push    bc
        push    hl
        ex      de,hl
        ld      c,26
        call    BDOS
        ld      de,fcb_sav
        ld      c,21
        call    BDOS
        pop     hl
        ld      de,128
        add     hl,de
        pop     bc
        djnz    sv1
        ld      de,fcb_sav
        ld      c,16
        jp      BDOS

; load: A = 1 if there was a save to read
load:   call    fcbclr
        ld      de,fcb_sav
        ld      c,15
        call    BDOS
        inc     a
        jr      z,ld_none
        ld      hl,state
        ld      b,SAVEREC
lo1:    push    bc
        push    hl
        ex      de,hl
        ld      c,26
        call    BDOS
        ld      de,fcb_sav
        ld      c,20
        call    BDOS
        pop     hl
        pop     bc
        or      a
        jr      nz,ld_bad
        ld      de,128
        add     hl,de
        djnz    lo1
        ld      de,fcb_sav
        ld      c,16
        call    BDOS
        ld      a,(state)
        cp      'C'
        jr      nz,ld_bad
        ld      a,(state+1)
        cp      'S'
        jr      nz,ld_bad
        ld      a,(state+2)
        cp      1
        jr      nz,ld_bad
        ld      a,1
        ret
ld_bad: xor     a
        ret
ld_none: xor    a
        ret
