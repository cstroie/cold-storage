; ship.asm: the ship's four systems and the crew's work (keys only; the wear is in voyage.asm)

k_ship: cp      5
        jr      z,sh_up
        cp      24
        jr      z,sh_dn
        cp      19
        jr      z,sh_m
        cp      '-'
        jr      z,sh_m
        cp      4
        jr      z,sh_p
        cp      '+'
        jr      z,sh_p
        cp      '='
        jr      z,sh_p
        cp      27
        jr      z,sh_out
        cp      13
        jr      z,sh_out
        cp      'S'
        jr      z,sh_out
        ret
sh_up:  ld      a,(shsel)
        or      a
        ret     z
        dec     a
        jr      sh_set
sh_dn:  ld      a,(shsel)
        cp      3
        ret     nc
        inc     a
sh_set: ld      (shsel),a
        ld      hl,dirty
        set     3,(hl)
        ret
sh_p:   ld      a,(shsel)
        or      a
        ret     z
        ld      e,a
        ld      d,0
        ld      hl,alloc
        add     hl,de
        ld      a,(hl)
        cp      4
        ret     nc
        push    hl
        call    allocsum
        ld      b,a
        call    budget
        pop     hl
        cp      b
        ret     z
        ret     c
        inc     (hl)
        jr      sh_dirty
sh_m:   ld      a,(shsel)
        or      a
        ret     z
        ld      e,a
        ld      d,0
        ld      hl,alloc
        add     hl,de
        ld      a,(hl)
        or      a
        ret     z
        dec     (hl)
sh_dirty: ld    hl,dirty
        ld      a,D_SHIP|D_FOC
        or      (hl)
        ld      (hl),a
        ret
sh_out: call    thought
        jp      tohall
