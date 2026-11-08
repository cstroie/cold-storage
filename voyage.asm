; voyage.asm: the ticks, the years, the ship wearing, the sleepers drifting, the end of the slice.
;
; A tick is 100 ms, a tenth of a voyage year is 60 ticks, a year 600 ticks (one real minute).

; ticker: once a tick
ticker: ld      hl,(idle)
        inc     hl
        ld      (idle),hl
        ld      de,AWAY
        or      a
        sbc     hl,de
        jr      nz,tk1
        ld      a,1
        ld      (away),a
        xor     a
        ld      (awaycnt),a
tk1:    ld      a,(mode)
        cp      M_TALK
        jr      nz,tk2
        ld      hl,(wtimer)
        dec     hl
        ld      (wtimer),hl
        ld      a,h
        or      l
        jr      nz,tk1a
        call    talkend         ; the coolant ran out
        jr      tk2
tk1a:   ld      a,l
        and     15
        jr      nz,tk2
        ld      hl,dirty
        set     5,(hl)
tk2:    ld      hl,t60
        inc     (hl)
        ld      a,(hl)
        cp      60
        ret     c
        ld      (hl),0
        ld      hl,tenth
        inc     (hl)
        ld      a,(hl)
        cp      10
        jr      c,tk3
        ld      (hl),0
        call    yearwrap
tk3:    ld      hl,dirty
        set     0,(hl)
        ret

; yearwrap: a voyage year has passed
yearwrap: ld    hl,year
        inc     (hl)
        call    sysyear
        call    sleepyear
        ld      a,(year)
        cp      YEAREND
        jr      nz,yw1
        ld      a,(flags)
        bit     0,a
        jr      nz,yw1
        call    endnew
        jr      yw_end
yw1:    ld      a,(evstate)     ; an event left unanswered: the moment passes
        cp      1
        call    z,evpass
        ld      b,3
        call    rndn
        or      a
        jr      z,yw_q
        ld      a,1
        ld      (evpend),a
        jr      yw_end
yw_q:   call    quietline
yw_end: call    save
        ld      hl,dirty
        ld      a,D_HDR|D_HALL|D_SLP|D_SHIP
        or      (hl)
        ld      (hl),a
        ret

quietline: call xsrnd
        ld      b,N_LOGL
        call    xrndn
        ld      l,a
        ld      h,0
        ld      de,S_LOGL
        add     hl,de
        call    str
        jp      logadd

; thought: WREN's one line for the hall's focus pane
thought: call   xsrnd
        ld      b,N_LOGL
        call    xrndn
        ld      l,a
        ld      h,0
        ld      de,S_LOGL
        add     hl,de
        call    str
        ld      de,focbuf
        call    xpand
        ret

; evcheck: an event waits for the hall to be quiet; an operator who is away misses it
evcheck: ld     a,(evpend)
        or      a
        ret     z
        ld      a,(away)
        or      a
        jr      z,ec1
        xor     a
        ld      (evpend),a
        ld      hl,awaycnt
        inc     (hl)
        call    evnew
        call    evpass
        jp      evdone
ec1:    ld      a,(mode)
        or      a
        ret     nz
        xor     a
        ld      (evpend),a
        jp      evnew

; ---------------------------------------------------------------- the ship wears
sysyear: ld     b,5             ; the reactor: one year in five it loses a little
        call    rndn
        or      a
        jr      nz,sy1
        ld      hl,sys
        ld      b,1
        ld      c,1
        ld      d,10
        call    clampalloc0
sy1:    call    clampalloc
        ld      a,1
        ld      (sy_i),a
sy2:    ld      b,4             ; every system: a quarter of the years a little worse
        call    rndn
        or      a
        jr      nz,sy3
        call    sysptr
        ld      b,1
        ld      c,1
        ld      d,10
        call    clampadd
sy3:    ld      a,(sy_i)        ; the crew's work: [2] holds even, [3] and [4] mend
        ld      e,a
        ld      d,0
        ld      hl,alloc
        add     hl,de
        ld      a,(hl)
        cp      2
        jr      c,sy4
        sub     1
        ld      c,a
        ld      b,4
        call    rndn
        cp      c
        jr      nc,sy4
        call    sysptr
        ld      b,1
        ld      c,0
        ld      d,10
        call    clampadd
sy4:    ld      hl,sy_i
        inc     (hl)
        ld      a,(hl)
        cp      4
        jr      nz,sy2
        ld      a,(sys+1)       ; the coolant reserve refills: 4 and a third of the loop
        ld      b,3
        call    divb
        add     a,4
        ld      hl,resv
        add     a,(hl)
        cp      21
        jr      c,sy5
        ld      a,20
sy5:    ld      (resv),a
        ld      a,(sys+3)       ; a strong array: the home star's signal calms someone
        cp      7
        ret     c
        call    pickalive
        call    slpadr
        ld      b,10
        ld      c,0
        ld      d,STABMAX
        jp      clampadd
clampalloc0: jp clampadd
sysptr: ld      a,(sy_i)
        ld      e,a
        ld      d,0
        ld      hl,sys
        add     hl,de
        ret

; clampadd: HL = a byte, B = how much, C = 1 to take away, D = the most it may be
clampadd: ld    a,(hl)
        bit     0,c
        jr      nz,ca_sub
        add     a,b
        jr      c,ca_max
        cp      d
        jr      c,ca_ok
        jr      z,ca_ok
ca_max: ld      a,d
ca_ok:  ld      (hl),a
        ret
ca_sub: sub     b
        jr      nc,ca_ok
        xor     a
        jr      ca_ok

; budget: A = the crew the ship can spare: 2, and half the reactor
budget: ld      a,(sys)
        srl     a
        add     a,2
        ret
allocsum: ld    a,(alloc+1)
        ld      hl,alloc+2
        add     a,(hl)
        inc     hl
        add     a,(hl)
        ret
; clampalloc: the crew shrinks to the budget, the last system first
clampalloc: call allocsum
        ld      b,a
        call    budget
        cp      b
        ret     nc
        ld      hl,alloc+3
        ld      b,3
cal2:   ld      a,(hl)
        or      a
        jr      nz,cal3
        dec     hl
        djnz    cal2
        ret
cal3:   dec     (hl)
        jr      clampalloc

; pickalive: A = a sleeper not lost
pickalive: ld   c,60
pk1:    ld      b,NSL
        call    rndn
        push    af
        call    slpadr
        ld      de,SL_FLAGS
        add     hl,de
        bit     0,(hl)
        jr      nz,pk2
        pop     af
        ret
pk2:    pop     af
        dec     c
        jr      nz,pk1
        xor     a
        ret

; ---------------------------------------------------------------- the sleepers drift
sleepyear: xor  a
        ld      (sl_i),a
sly1:   ld      a,(sl_i)
        call    slpadr
        push    hl
        pop     ix
        bit     0,(ix+SL_FLAGS)
        jr      nz,sly9
        res     1,(ix+SL_FLAGS)
        ld      b,4             ; how much the cold takes: more with a weak coolant or a thin hull
        ld      a,(sys+1)
        cp      5
        jr      nc,sly1a
        ld      b,8
        cp      2
        jr      nc,sly1a
        ld      b,14
sly1a:  ld      a,(sys+2)
        cp      3
        jr      nc,sly2
        inc     b
        inc     b
sly2:   ld      a,(ix+SL_STAB)
        sub     b
        jr      nc,sly3
        xor     a
sly3:   ld      (ix+SL_STAB),a
        or      a
        jr      nz,sly4
        call    lose
        jr      sly9
sly4:   cp      100
        jr      nc,sly5
        ld      a,(ix+SL_THEME) ; thin: the dreams turn to fear
        cp      1
        jr      z,sly6
        ld      b,3
        call    rndn
        or      a
        jr      nz,sly6
        ld      (ix+SL_THEME),1
        call    newdream
        jr      sly6
sly5:   cp      200             ; steady: fear lets go
        jr      c,sly6
        ld      a,(ix+SL_THEME)
        cp      1
        jr      nz,sly6
        ld      (ix+SL_THEME),2
        call    newdream
sly6:   ld      b,8             ; and now and then a new dream
        call    rndn
        or      a
        jr      nz,sly9
        call    newdream
sly9:   ld      hl,sl_i
        inc     (hl)
        ld      a,(hl)
        cp      NSL
        jp      nz,sly1
        ret

; newdream: IX = a sleeper: a new dream, shown as ~
newdream: call  rnd
        ld      a,(rseed)
        ld      (ix+SL_DSEED),a
        set     1,(ix+SL_FLAGS)
        ret

; lose: the sleeper in IX (sl_i) is gone: a quiet line in the log
lose:   set     0,(ix+SL_FLAGS)
        res     2,(ix+SL_FLAGS)
        ld      a,(sl_i)
        ld      (tsubj),a
        call    bstart
        ld      hl,t_lostln
        call    bstr
        call    cfirst
        call    bstr
        ld      a,' '
        call    bchar
        call    clast
        call    bstr
        ld      hl,(bp)
        ld      (hl),0
        ld      hl,lbuf
        jp      logadd

; ---------------------------------------------------------------- the end of the slice
endnew: ld      a,(flags)
        or      1
        ld      (flags),a
        call    count
        ld      a,(nlost)
        ld      b,0
        cp      3
        jr      c,en1
        inc     b
        cp      11
        jr      c,en1
        inc     b
en1:    ld      l,b
        ld      h,0
        ld      de,S_ENDC
        add     hl,de
        call    str
        push    hl
        call    xsrnd
        pop     hl
        ld      de,focbuf
        call    xpand
        ld      a,M_END
        ld      (mode),a
        ld      hl,dirty
        ld      a,D_FOC|D_KEYS
        or      (hl)
        ld      (hl),a
        ret

; tohall: back to the hall (the focus text is as it was left)
tohall: ld      a,M_HALL
        ld      (mode),a
        ld      hl,dirty
        ld      a,D_HALL|D_SLP|D_SHIP|D_FOC|D_KEYS|D_HDR
        or      (hl)
        ld      (hl),a
        ret
