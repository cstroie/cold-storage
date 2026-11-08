; event.asm: the year's event. An event is eight strings in the DAT: title, text, then for each
; of two choices its label, its effects and its result. Effects are letter, sign, digit:
;   R C H M  reactor, coolant, hull, comms        S  the sleeper's stability (x10)
;   A        everyone's stability (x4)            T=n  the sleeper's theme    X  takes another's
;   K        kindness

; evfield: A = field -> HL = the string
evfield: ld     c,a
        ld      a,(evi)
        ld      l,a
        ld      h,0
        add     hl,hl
        add     hl,hl
        add     hl,hl
        ld      e,c
        ld      d,0
        add     hl,de
        ld      de,S_EVENT
        add     hl,de
        jp      str

; evnew: this year's event, about a sleeper
evnew:  ld      b,N_EVENT
evn1:   call    rndn
        ld      c,a
        ld      a,(lastev)
        cp      c
        jr      z,evn1
        ld      a,c
        ld      (evi),a
        ld      (lastev),a
        call    pickalive
        ld      (esubj),a
        ld      (tsubj),a
        push    af
        call    movecur         ; the hall's cursor goes to them
        pop     af
        call    xsrnd
        ld      a,1
        call    evfield
        ld      de,focbuf
        call    xpand
        ld      a,1
        ld      (evstate),a
        ld      a,M_EVENT
        ld      (mode),a
        ld      hl,dirty
        ld      a,D_FOC|D_KEYS
        or      (hl)
        ld      (hl),a
        ret

; evpass: nobody answered: the second choice
evpass: ld      a,1
; evchoose: A = 0 or 1
evchoose: ld    (evch),a
        ld      b,a
        add     a,a
        add     a,b
        add     a,3
        call    evfield
        call    applyfx
        ld      a,(evch)
        ld      b,a
        add     a,a
        add     a,b
        add     a,4
        call    evfield
        ld      a,(esubj)
        ld      (tsubj),a
        push    hl
        call    xsrnd
        pop     hl
        ld      de,focbuf
        call    xpand
        xor     a
        call    evfield
        call    logadd
        ld      a,2
        ld      (evstate),a
        ld      hl,dirty
        ld      a,D_FOC|D_KEYS
        or      (hl)
        ld      (hl),a
        ret

evdone: xor     a
        ld      (evstate),a
        call    thought
        jp      tohall

k_event: ld     b,a
        ld      a,(evstate)
        cp      1
        jr      z,ke1
        jp      evdone
ke1:    ld      a,b
        cp      'A'
        jr      z,ke_a
        cp      '1'
        jr      z,ke_a
        cp      'B'
        jr      z,ke_b
        cp      '2'
        jr      z,ke_b
        ret
ke_a:   xor     a
        jp      evchoose
ke_b:   ld      a,1
        jp      evchoose

; applyfx: HL = effects
applyfx: ld     a,(hl)
        or      a
        jr      z,afx_end
        ld      (fx_op),a
        inc     hl
        ld      a,(hl)
        ld      (fx_s),a
        inc     hl
        ld      a,(hl)
        sub     '0'
        ld      (fx_d),a
        inc     hl
        push    hl
        call    fxone
        pop     hl
        jr      applyfx
afx_end: ld     hl,dirty
        ld      a,D_HDR|D_HALL|D_SLP|D_SHIP
        or      (hl)
        ld      (hl),a
        ret

fxsign: ld      a,(fx_s)
        cp      '-'
        ld      c,0
        ret     nz
        inc     c
        ret

fxone:  ld      a,(fx_op)
        cp      'R'
        ld      hl,sys
        jr      z,fx_sys
        cp      'C'
        ld      hl,sys+1
        jr      z,fx_sys
        cp      'H'
        ld      hl,sys+2
        jr      z,fx_sys
        cp      'M'
        ld      hl,sys+3
        jr      z,fx_sys
        cp      'K'
        ld      hl,kind
        jr      z,fx_kind
        cp      'S'
        jr      z,fx_subj
        cp      'A'
        jr      z,fx_all
        cp      'T'
        jr      z,fx_t
        cp      'X'
        jr      z,fx_x
        ret
fx_sys: ld      d,10
        jr      fx_cl
fx_kind: ld     d,255
fx_cl:  ld      a,(fx_d)
        ld      b,a
        call    fxsign
        jp      clampadd
fx_subj: ld     a,(esubj)
        call    slpadr
        ld      a,(fx_d)
        ld      b,a
        add     a,a
        add     a,a
        add     a,b
        add     a,a
        ld      b,a
        ld      d,STABMAX
        call    fxsign
        jp      clampadd
fx_all: xor     a
        ld      (fx_i),a
fxa1:   ld      a,(fx_i)
        call    slpadr
        push    hl
        ld      de,SL_FLAGS
        add     hl,de
        bit     0,(hl)
        pop     hl
        jr      nz,fxa2
        ld      a,(fx_d)
        add     a,a
        add     a,a
        ld      b,a
        ld      d,STABMAX
        call    fxsign
        call    clampadd
fxa2:   ld      hl,fx_i
        inc     (hl)
        ld      a,(hl)
        cp      NSL
        jr      nz,fxa1
        ret
fx_t:   ld      a,(esubj)
        call    slpadr
        push    hl
        pop     ix
        ld      a,(fx_d)
        ld      (ix+SL_THEME),a
        jp      newdream
fx_x:   ld      a,(esubj)
        call    slpadr
        push    hl
        call    pickalive
        call    slpadr
        push    hl
        pop     iy
        pop     ix
        ld      a,(iy+SL_THEME)
        ld      (ix+SL_THEME),a
        call    newdream
        ld      a,(ix+SL_DSEED)
        ld      (iy+SL_DSEED),a
        set     1,(iy+SL_FLAGS)
        ret
