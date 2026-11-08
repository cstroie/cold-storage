; text.asm: the content file (COLDSTOR.DAT) and the words made from it.
;
; str      string number -> address
; xpand    a text with tokens (%n %N %p %P %o %a %y) -> plain text, by the generator xs
; wrapp    plain text wrapped by words into a block of the screen
; b*       a line built in lbuf, shown padded to a width

; ---------------------------------------------------------------- the DAT
loaddat: ld     de,fcb_dat
        ld      c,15
        call    BDOS
        inc     a
        jp      z,nodat
        ld      hl,datbuf
ld1:    push    hl
        ex      de,hl
        ld      c,26
        call    BDOS
        ld      de,fcb_dat
        ld      c,20
        call    BDOS
        pop     hl
        or      a
        jr      nz,ld2
        ld      de,128
        add     hl,de
        push    hl
        ld      de,(6)          ; the BDOS: keep two pages clear below it
        dec     d
        dec     d
        or      a
        sbc     hl,de
        pop     hl
        jr      c,ld1
        jp      nodat
ld2:    ld      de,fcb_dat
        ld      c,16
        call    BDOS
        ld      hl,datbuf       ; 'CDAT', version 1, and the right number of strings
        ld      a,(hl)
        cp      'C'
        jp      nz,nodat
        inc     hl
        ld      a,(hl)
        cp      'D'
        jp      nz,nodat
        ld      hl,(datbuf+5)
        ld      de,N_STR
        or      a
        sbc     hl,de
        jp      nz,nodat
        ret

nodat:  ld      hl,m_nodat
        call    puts
        jp      quit0

; str: HL = string number -> HL = its address (DE kept)
str:    push    de
        add     hl,hl
        ld      de,datbuf+16
        add     hl,de
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        ld      hl,datbuf
        add     hl,de
        pop     de
        ret

; ---------------------------------------------------------------- random words
; xrnd: the text generator xs (xorshift16, as rnd), HL = the new value
xrnd:   ld      hl,(xs)
        ld      a,h
        rra
        ld      a,l
        rra
        xor     h
        ld      h,a
        ld      a,l
        rra
        ld      a,h
        rra
        xor     l
        ld      l,a
        xor     h
        ld      h,a
        ld      (xs),hl
        ret

; xrndn: A = xs mod B
xrndn:  call    xrnd
        ld      a,h
xn1:    cp      b
        ret     c
        sub     b
        jr      xn1

; rndn: A = rseed mod B
rndn:   call    rnd
        ld      a,(rseed+1)
rn1:    cp      b
        ret     c
        sub     b
        jr      rn1

; xs from rseed: a text that does not need to come out the same twice
xsrnd:  call    rnd
        ld      hl,(rseed)
        ld      (xs),hl
        ret

; ---------------------------------------------------------------- sleepers' names
; slpadr: A = sleeper -> HL = its record
slpadr: ld      l,a
        ld      h,0
        add     hl,hl
        ld      e,l
        ld      d,h
        add     hl,hl
        add     hl,hl
        add     hl,de
        ld      de,slp
        add     hl,de
        ret

; cfirst, clast: HL = the first and the last name of sleeper `tsubj` (DE kept)
cfirst: ld      a,SL_FN
        ld      bc,S_FN
        jr      cname
clast:  ld      a,SL_LN
        ld      bc,S_LN
cname:  push    de
        push    bc
        push    af
        ld      a,(tsubj)
        call    slpadr
        pop     af
        ld      e,a
        ld      d,0
        add     hl,de
        ld      l,(hl)
        ld      h,0
        pop     bc
        add     hl,bc
        pop     de
        jp      str

; strcpy: HL -> DE, without the zero; both moved on
strcpy: ld      a,(hl)
        or      a
        ret     z
        ld      (de),a
        inc     hl
        inc     de
        jr      strcpy

; ---------------------------------------------------------------- tokens
; xpand: HL = text, DE = where to put the result (zero-terminated)
xpand:  ld      a,(hl)
        inc     hl
        or      a
        jr      z,xp_end
        cp      '%'
        jr      z,xp_tok
xp_put: ld      (de),a
        inc     de
        jr      xpand
xp_end: ld      (de),a
        ret
xp_tok: ld      a,(hl)
        inc     hl
        push    hl
        cp      'n'
        jr      z,xt_n
        cp      'N'
        jr      z,xt_nn
        cp      'p'
        jr      z,xt_p
        cp      'P'
        jr      z,xt_pp
        cp      'o'
        jr      z,xt_o
        cp      'a'
        jr      z,xt_a
        cp      'y'
        jr      z,xt_y
        pop     hl
        jr      xpand
xt_n:   call    cfirst
xt_cp:  call    strcpy
xt_ok:  pop     hl
        jr      xpand
xt_nn:  call    cfirst
        call    strcpy
        ld      a,' '
        ld      (de),a
        inc     de
        call    clast
        jr      xt_cp
xt_p:   call    pickp
        jr      xt_cp
xt_pp:  call    pickp
        push    de
        call    strcpy
        pop     hl
        ld      a,(hl)
        call    upcase
        ld      (hl),a
        jr      xt_ok
xt_o:   ld      b,N_SLOTO
        call    xrndn
        ld      l,a
        ld      h,0
        ld      bc,S_SLOTO
        add     hl,bc
        call    str
        jr      xt_cp
xt_a:   ld      b,N_SLOTA
        call    xrndn
        ld      l,a
        ld      h,0
        ld      bc,S_SLOTA
        add     hl,bc
        call    str
        jr      xt_cp
xt_y:   ld      a,(year)
        ld      hl,xy_buf
        push    de
        ld      de,xy_buf
        call    num3
        xor     a
        ld      (de),a
        pop     de
        ld      hl,xy_buf
        jr      xt_cp
pickp:  ld      b,N_SLOTP
        call    xrndn
        ld      l,a
        ld      h,0
        ld      bc,S_SLOTP
        add     hl,bc
        jp      str

; num3: A as three digits at DE (moved on)
num3:   ld      c,'0'-1
n3a:    inc     c
        sub     100
        jr      nc,n3a
        add     a,100
        ld      b,a
        ld      a,c
        ld      (de),a
        inc     de
        ld      a,b
        ld      c,'0'-1
n3b:    inc     c
        sub     10
        jr      nc,n3b
        add     a,10+'0'
        ld      b,a
        ld      a,c
        ld      (de),a
        inc     de
        ld      a,b
        ld      (de),a
        inc     de
        ret

; ---------------------------------------------------------------- lines in a buffer
bstart: ld      hl,lbuf
        ld      (bp),hl
        ret
bchar:  push    hl
        ld      hl,(bp)
        ld      (hl),a
        inc     hl
        ld      (bp),hl
        pop     hl
        ret
bstr:   push    de
        ld      de,(bp)
bs1:    ld      a,(hl)
        or      a
        jr      z,bs2
        ld      (de),a
        inc     hl
        inc     de
        jr      bs1
bs2:    ld      (bp),de
        pop     de
        ret
bdec2:  ld      c,'0'-1
bq1:    inc     c
        sub     10
        jr      nc,bq1
        add     a,10+'0'
        push    af
        ld      a,c
        call    bchar
        pop     af
        jp      bchar
bdec3:  ld      c,'0'-1
bt1:    inc     c
        sub     100
        jr      nc,bt1
        add     a,100
        push    af
        ld      a,c
        call    bchar
        pop     af
        jp      bdec2
; bsp: A spaces
bsp:    or      a
        ret     z
        ld      b,a
bsp1:   ld      a,' '
        call    bchar
        djnz    bsp1
        ret
; bbar: A = 0..10 cells filled
bbar:   ld      c,a
        ld      a,10
        sub     c
        ld      b,a
        ld      a,c
        or      a
        jr      z,bb2
bb1:    push    af
        ld      a,'#'
        call    bchar
        pop     af
        dec     a
        jr      nz,bb1
bb2:    ld      a,b
        or      a
        ret     z
bb3:    ld      a,'.'
        call    bchar
        djnz    bb3
        ret
; bshow: B = row, C = column, D = width: the line, padded
bshow:  ld      hl,(bp)
        ld      (hl),0
        push    de
        call    gotoxy
        pop     de
        ld      hl,lbuf
        ld      b,d
        jp      putsw

; putsw: HL = text, B = width: the text cut or padded to it
putsw:  ld      a,(hl)
        or      a
        jr      z,pw_pad
        call    putc
        inc     hl
        djnz    putsw
        ret
pw_pad: ld      a,' '
pw_p1:  call    putc
        djnz    pw_p1
        ret

; spaces: B of them
spaces: ld      a,b
        or      a
        ret     z
sp1:    ld      a,' '
        call    putc
        djnz    sp1
        ret

; ---------------------------------------------------------------- wrapping
; clrarea: B = row, C = column, D = width, E = rows
clrarea: ld     a,e
        or      a
        ret     z
ca1:    push    bc
        push    de
        call    gotoxy
        ld      b,d
        call    spaces
        pop     de
        pop     bc
        inc     b
        dec     e
        jr      nz,ca1
        ret

; wrapp: HL = text, B = row, C = column, D = width, E = rows: by words, the block cleared first
wrapp:  push    hl
        push    bc
        push    de
        call    clrarea
        pop     de
        pop     bc
        pop     hl
        ld      a,b
        ld      (wr_row),a
        ld      a,c
        ld      (wr_col),a
        ld      a,d
        ld      (wr_w),a
        ld      a,e
        ld      (wr_n),a
        xor     a
        ld      (wr_pos),a
        call    wr_goto
wr_nx:  ld      a,(hl)          ; skip spaces
        cp      ' '
        jr      nz,wr_w1
        inc     hl
        jr      wr_nx
wr_w1:  or      a
        ret     z
        ld      d,h             ; the word's length, into B
        ld      e,l
        ld      b,0
wr_l:   ld      a,(de)
        or      a
        jr      z,wr_l2
        cp      ' '
        jr      z,wr_l2
        inc     de
        inc     b
        jr      wr_l
wr_l2:  ld      a,(wr_pos)
        or      a
        jr      z,wr_put
        add     a,b
        inc     a
        ld      c,a
        ld      a,(wr_w)
        cp      c
        jr      nc,wr_sp
        ld      a,(wr_n)        ; no room: the next row, if there is one
        dec     a
        ret     z
        ld      (wr_n),a
        ld      a,(wr_row)
        inc     a
        ld      (wr_row),a
        xor     a
        ld      (wr_pos),a
        push    hl
        push    bc
        call    wr_goto
        pop     bc
        pop     hl
        jr      wr_put
wr_sp:  ld      a,' '
        call    putc
        ld      a,(wr_pos)
        inc     a
        ld      (wr_pos),a
wr_put: ld      a,(hl)
        call    putc
        inc     hl
        ld      a,(wr_pos)
        inc     a
        ld      (wr_pos),a
        djnz    wr_put
        jr      wr_nx
wr_goto: ld     a,(wr_row)
        ld      b,a
        ld      a,(wr_col)
        ld      c,a
        jp      gotoxy
