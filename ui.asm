; ui.asm: the screen. Boxes, the header, the hall, the sleeper, the ship, the log, the focus
; pane and the keys line. Everything is drawn by cursor address; what changed is marked in
; `dirty` and redrawn by `refresh`.
;
;   row  1       header (reversed)
;   rows 2-10    CRYO HALL (cols 1-30)      SLEEPER (cols 32-79)
;   rows 11-16   SHIP (cols 1-30)           LOG (cols 32-79)
;   rows 17-23   FOCUS (cols 1-79): the voyage, the talk, the event, the map
;   row  24      keys (reversed, to column 79)

D_HDR   equ     1
D_HALL  equ     2
D_SLP   equ     4
D_SHIP  equ     8
D_LOG   equ     16
D_FOC   equ     32
D_KEYS  equ     64
D_ALL   equ     127
LOGW    equ     48

M_HALL  equ     0
M_TALK  equ     1
M_EVENT equ     2
M_SHIP  equ     3
M_MAP   equ     4
M_MEM   equ     5
M_END   equ     6

; ---------------------------------------------------------------- boxes
; box: B = row, C = column, D = width, E = height, HL = title or 0
box:    ld      (bx_hl),hl
        ld      a,b
        ld      (bx_row),a
        ld      a,c
        ld      (bx_col),a
        ld      a,d
        ld      (bx_w),a
        ld      a,e
        ld      (bx_h),a
        call    gotoxy
        ld      a,'+'
        call    putc
        ld      a,(bx_w)
        sub     2
        ld      e,a
        ld      hl,(bx_hl)
        ld      a,h
        or      l
        jr      z,bx_t0
        ld      a,'-'
        call    putc
        ld      a,' '
        call    putc
        ld      d,0
bx_t1:  ld      a,(hl)
        or      a
        jr      z,bx_t2
        call    putc
        inc     hl
        inc     d
        jr      bx_t1
bx_t2:  ld      a,' '
        call    putc
        ld      a,d
        add     a,3
        ld      d,a
        ld      a,e
        sub     d
        ld      e,a
bx_t0:  ld      b,e
        call    dashes
        ld      a,'+'
        call    putc
        ld      a,(bx_h)
        sub     2
        ld      (bx_n),a
bx_rl:  ld      hl,bx_row
        inc     (hl)
        ld      a,(bx_row)
        ld      b,a
        ld      a,(bx_col)
        ld      c,a
        call    gotoxy
        ld      a,'|'
        call    putc
        ld      a,(bx_w)
        sub     2
        ld      b,a
        call    spaces
        ld      a,'|'
        call    putc
        ld      hl,bx_n
        dec     (hl)
        jr      nz,bx_rl
        ld      hl,bx_row
        inc     (hl)
        ld      a,(bx_row)
        ld      b,a
        ld      a,(bx_col)
        ld      c,a
        call    gotoxy
        ld      a,'+'
        call    putc
        ld      a,(bx_w)
        sub     2
        ld      b,a
        call    dashes
        ld      a,'+'
        jp      putc
dashes: ld      a,b
        or      a
        ret     z
dh1:    ld      a,'-'
        call    putc
        djnz    dh1
        ret

; ---------------------------------------------------------------- the frame
frame:  call    cls
        ld      hl,podsh
        ld      de,podsh+1
        ld      (hl),0
        ld      bc,NSL-1
        ldir
        ld      b,2
        ld      c,1
        ld      d,30
        ld      e,9
        ld      hl,t_hall
        call    box
        ld      b,2
        ld      c,32
        ld      d,48
        ld      e,9
        ld      hl,t_slp
        call    box
        ld      b,11
        ld      c,1
        ld      d,30
        ld      e,6
        ld      hl,t_ship
        call    box
        ld      b,11
        ld      c,32
        ld      d,48
        ld      e,6
        ld      hl,t_log
        call    box
        ld      b,17
        ld      c,1
        ld      d,79
        ld      e,7
        ld      hl,t_foc
        call    box
        ld      b,8
        ld      c,3
        call    gotoxy
        ld      hl,t_leg1
        call    puts
        ld      b,9
        ld      c,3
        call    gotoxy
        ld      hl,t_leg2
        call    puts
        ld      a,D_ALL
        ld      (dirty),a
        ret

; refresh: redraw what is marked
refresh: ld     a,(dirty)
        or      a
        ret     z
        ld      b,a
        xor     a
        ld      (dirty),a
        ld      a,b
        ld      (rf_d),a
        bit     0,a
        call    nz,drawhdr
        ld      a,(rf_d)
        bit     1,a
        call    nz,drawhall
        ld      a,(rf_d)
        bit     2,a
        call    nz,drawslp
        ld      a,(rf_d)
        bit     3,a
        call    nz,drawship
        ld      a,(rf_d)
        bit     4,a
        call    nz,drawlog
        ld      a,(rf_d)
        bit     5,a
        call    nz,drawfoc
        ld      a,(rf_d)
        bit     6,a
        call    nz,drawkeys
        ret

; ---------------------------------------------------------------- header
drawhdr: ld     b,1
        ld      c,1
        call    gotoxy
        call    revon
        ld      b,79
        call    spaces
        call    bstart
        ld      hl,t_name
        call    bstr
        ld      b,1
        ld      c,3
        ld      d,17
        call    bshow
        call    bstart
        ld      hl,t_year
        call    bstr
        ld      a,(year)
        call    bdec3
        ld      a,'.'
        call    bchar
        ld      a,(tenth)
        add     a,'0'
        call    bchar
        ld      b,1
        ld      c,23
        ld      d,10
        call    bshow
        call    bstart
        ld      hl,t_watch
        call    bstr
        ld      hl,(watch)
        ld      de,1000
        call    bdg
        ld      de,100
        call    bdg
        ld      de,10
        call    bdg
        ld      a,l
        add     a,'0'
        call    bchar
        ld      b,1
        ld      c,36
        ld      d,10
        call    bshow
        call    bstart
        ld      hl,t_cool
        call    bstr
        ld      a,(resv)
        srl     a
        cp      11
        jr      c,dh_r
        ld      a,10
dh_r:   call    bbar
        ld      b,1
        ld      c,49
        ld      d,15
        call    bshow
        call    count
        call    bstart
        ld      hl,t_asleep
        call    bstr
        ld      a,(nasleep)
        call    bdec2
        ld      b,1
        ld      c,67
        ld      d,9
        call    bshow
        jp      revoff
; bdg: HL as one digit by DE into the line buffer
bdg:    ld      a,'0'-1
bdg1:   inc     a
        or      a
        sbc     hl,de
        jr      nc,bdg1
        add     hl,de
        jp      bchar

; count: the sleepers not lost, in nasleep; the lost in nlost
count:  ld      b,NSL
        ld      c,0
        ld      hl,slp+SL_FLAGS
        ld      de,SLSZ
cn1:    ld      a,(hl)
        and     F_LOST
        jr      nz,cn2
        inc     c
cn2:    add     hl,de
        djnz    cn1
        ld      a,c
        ld      (nasleep),a
        ld      b,a
        ld      a,NSL
        sub     b
        ld      (nlost),a
        ret

; ---------------------------------------------------------------- the hall
drawhall: xor   a
dhl1:   push    af
        call    drawpod
        pop     af
        inc     a
        cp      NSL
        jr      nz,dhl1
        ret

; drawpod: A = sleeper; only if it looks different from what is on the screen
drawpod: ld     (dp_i),a
        call    slpadr
        push    hl
        pop     ix
        ld      a,'#'
        ld      c,(ix+SL_FLAGS)
        bit     0,c
        jr      z,dp_a
        ld      a,' '
        jr      dp_g
dp_a:   bit     2,c
        jr      z,dp_b
        ld      a,'@'
        jr      dp_g
dp_b:   ld      a,(ix+SL_STAB)
        cp      70
        ld      a,'!'
        jr      c,dp_g
        ld      a,'#'
        bit     1,c
        jr      z,dp_g
        ld      a,'~'
dp_g:   ld      (dp_c),a
        ld      a,(dp_i)
        ld      hl,cur
        cp      (hl)
        ld      a,(dp_c)
        jr      nz,dp_n
        or      80h
dp_n:   ld      (dp_c),a
        ld      a,(dp_i)
        ld      e,a
        ld      d,0
        ld      hl,podsh
        add     hl,de
        ld      a,(dp_c)
        cp      (hl)
        ret     z
        ld      (hl),a
        ld      a,(dp_i)
        ld      b,a
        and     7
        ld      c,a
        add     a,a
        add     a,c
        add     a,3
        ld      c,a
        ld      a,b
        rrca
        rrca
        rrca
        and     31
        add     a,3
        ld      b,a
        call    gotoxy
        ld      a,(dp_c)
        bit     7,a
        jr      nz,dp_sel
        ld      d,a
        ld      a,'['
        call    putc
        ld      a,d
        call    putc
        ld      a,']'
        jp      putc
dp_sel: and     7fh
        ld      d,a
        call    revon
        ld      a,'<'
        call    putc
        ld      a,d
        call    putc
        ld      a,'>'
        call    putc
        jp      revoff

; ---------------------------------------------------------------- the sleeper
drawslp: ld     a,(cur)
        ld      (tsubj),a
        call    slpadr
        push    hl
        pop     ix
        call    bstart
        ld      a,'#'
        call    bchar
        ld      a,(cur)
        inc     a
        call    bdec2
        ld      a,' '
        call    bchar
        ld      a,' '
        call    bchar
        call    cfirst
        call    bstr
        ld      a,' '
        call    bchar
        call    clast
        call    bstr
        bit     0,(ix+SL_FLAGS)
        jp      nz,ds_lost
        ld      a,','
        call    bchar
        ld      a,' '
        call    bchar
        ld      a,(ix+SL_AGE)
        call    bdec2
        ld      a,','
        call    bchar
        ld      a,' '
        call    bchar
        ld      l,(ix+SL_TRADE)
        ld      h,0
        ld      de,S_TRADE
        add     hl,de
        call    str
        call    bstr
        ld      b,3
        ld      c,34
        ld      d,45
        call    bshow
        call    bstart
        ld      hl,t_from
        call    bstr
        ld      l,(ix+SL_ORIG)
        ld      h,0
        ld      de,S_ORIGIN
        add     hl,de
        call    str
        call    bstr
        ld      hl,(bp)         ; pad the line to 28 characters
        ld      de,lbuf
        or      a
        sbc     hl,de
        ld      a,28
        sub     l
        jr      nc,ds_p
        xor     a
ds_p:   call    bsp
        ld      hl,t_theme
        call    bstr
        ld      l,(ix+SL_THEME)
        ld      h,0
        ld      de,S_THEME
        add     hl,de
        call    str
        call    bstr
        ld      b,4
        ld      c,34
        ld      d,45
        call    bshow
        call    bstart
        ld      hl,t_stab
        call    bstr
        ld      a,(ix+SL_STAB)
        ld      b,25
        call    divb
        call    bbar
        ld      a,' '
        call    bchar
        ld      a,(ix+SL_STAB)
        ld      b,42
        call    divb
        ld      l,a
        ld      h,0
        ld      de,S_MOOD
        add     hl,de
        call    str
        call    bstr
        ld      b,5
        ld      c,34
        ld      d,45
        call    bshow
        call    bstart
        ld      hl,t_asked
        call    bstr
        ld      c,(ix+SL_KNOWN)
        ld      hl,t_init
        ld      b,8
ds_i:   ld      a,'-'
        rr      c
        jr      nc,ds_i2
        ld      a,(hl)
ds_i2:  call    bchar
        ld      a,' '
        call    bchar
        inc     hl
        djnz    ds_i
        ld      b,6
        ld      c,34
        ld      d,45
        call    bshow
        ld      b,7
        ld      c,34
        ld      d,45
        ld      e,3
        call    clrarea
        ld      a,(ix+SL_THEME)
        ld      b,6
        call    mulb
        ld      c,a
        ld      a,(ix+SL_DSEED)
        ld      (xs),a
        xor     0a5h
        or      1
        ld      (xs+1),a
        call    xrnd
        ld      b,6
        call    xrndn
        add     a,c
        ld      l,a
        ld      h,0
        ld      de,S_DREAM
        add     hl,de
        call    str
        ld      de,xbuf
        call    xpand
        ld      hl,xbuf
        ld      b,7
        ld      c,34
        ld      d,45
        ld      e,3
        jp      wrapp
ds_lost: ld     b,3
        ld      c,34
        ld      d,45
        call    bshow
        ld      b,4
        ld      c,34
        ld      d,45
        ld      e,6
        call    clrarea
        ld      a,(ix+SL_THEME)
        ld      l,a
        ld      h,0
        ld      de,S_EPIT
        add     hl,de
        call    str
        call    xsrnd
        ld      de,xbuf
        call    xpand
        ld      hl,xbuf
        ld      b,5
        ld      c,34
        ld      d,45
        ld      e,4
        jp      wrapp

; divb: A = A / B     mulb: A = A * B (small)
divb:   ld      c,0
dv1:    sub     b
        jr      c,dv2
        inc     c
        jr      dv1
dv2:    ld      a,c
        ret
mulb:   ld      c,a
        xor     a
        or      b
        ret     z
        xor     a
mb1:    add     a,c
        djnz    mb1
        ret

; ---------------------------------------------------------------- the ship
drawship: xor   a
        ld      (ds_i2v),a
dsh1:   call    bstart
        ld      a,(mode)
        cp      M_SHIP
        ld      a,' '
        jr      nz,dsh2
        ld      a,(ds_i2v)
        ld      hl,shsel
        cp      (hl)
        ld      a,' '
        jr      nz,dsh2
        ld      a,'>'
dsh2:   call    bchar
        ld      a,' '
        call    bchar
        ld      a,(ds_i2v)
        ld      b,7
        call    mulb
        ld      e,a
        ld      d,0
        ld      hl,shlab
        add     hl,de
        ld      b,7
dsh3:   ld      a,(hl)
        call    bchar
        inc     hl
        djnz    dsh3
        ld      a,' '
        call    bchar
        ld      a,(ds_i2v)
        ld      e,a
        ld      d,0
        ld      hl,sys
        add     hl,de
        ld      a,(hl)
        call    bbar
        ld      a,' '
        call    bchar
        ld      a,(ds_i2v)
        or      a
        jr      nz,dsh4
        ld      hl,t_bud
        call    bstr
        call    budget
        add     a,'0'
        call    bchar
        jr      dsh5
dsh4:   ld      a,'['
        call    bchar
        ld      a,(ds_i2v)
        ld      e,a
        ld      d,0
        ld      hl,alloc
        add     hl,de
        ld      a,(hl)
        add     a,'0'
        call    bchar
        ld      a,']'
        call    bchar
dsh5:   ld      a,(ds_i2v)
        add     a,12
        ld      b,a
        ld      c,3
        ld      d,27
        call    bshow
        ld      hl,ds_i2v
        inc     (hl)
        ld      a,(hl)
        cp      4
        jp      nz,dsh1
        ret

; ---------------------------------------------------------------- the log
drawlog: ld     b,12
        ld      hl,logbuf
dlg1:   push    bc
        push    hl
        ld      c,33
        call    gotoxy
        pop     hl
        push    hl
        ld      b,46
        call    putsw
        pop     hl
        ld      de,LOGW
        add     hl,de
        pop     bc
        inc     b
        ld      a,b
        cp      16
        jr      nz,dlg1
        ret

; logadd: HL = a line of at most 40 characters: onto the top, the rest down
logadd: push    hl
        ld      hl,logbuf+LOGW*3-1
        ld      de,logbuf+LOGW*4-1
        ld      bc,LOGW*3
        lddr
        ld      a,' '
        ld      (logbuf+LOGW),a
        ld      de,logbuf
        ld      a,'>'
        ld      (de),a
        inc     de
        ld      a,' '
        ld      (de),a
        inc     de
        ld      a,(year)
        call    num3
        ld      a,' '
        ld      (de),a
        inc     de
        pop     hl
        ld      b,40
lga1:   ld      a,(hl)
        or      a
        jr      z,lga2
        ld      (de),a
        inc     hl
        inc     de
        djnz    lga1
lga2:   xor     a
        ld      (de),a
        ld      hl,dirty
        set     4,(hl)
        ret

; ---------------------------------------------------------------- the keys line
drawkeys: ld    b,24
        ld      c,1
        call    gotoxy
        call    revon
        ld      a,(mode)
        add     a,a
        ld      e,a
        ld      d,0
        ld      hl,keytab
        add     hl,de
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        ex      de,hl
        ld      b,79
        call    putsw
        jp      revoff
