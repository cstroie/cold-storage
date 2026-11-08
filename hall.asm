; hall.asm: the cursor in the cryo hall (keys of the hall mode)

k_hall: cp      5
        jr      z,hl_up
        cp      24
        jr      z,hl_dn
        cp      19
        jr      z,hl_lt
        cp      4
        jr      z,hl_rt
        cp      'W'
        jp      z,dowake
        cp      13
        jp      z,dowake
        cp      'S'
        jr      z,go_ship
        cp      'M'
        jr      z,go_map
        cp      'L'
        jr      z,go_mem
        cp      '?'
        jp      z,go_intro
        ret
hl_up:  ld      a,(cur)
        cp      8
        ret     c
        sub     8
        jr      movecur
hl_dn:  ld      a,(cur)
        cp      32
        ret     nc
        add     a,8
        jr      movecur
hl_lt:  ld      a,(cur)
        and     7
        ret     z
        ld      a,(cur)
        dec     a
        jr      movecur
hl_rt:  ld      a,(cur)
        and     7
        cp      7
        ret     z
        ld      a,(cur)
        cp      NSL-1
        ret     nc
        inc     a
; movecur: A = the new pod
movecur: ld     b,a
        ld      a,(cur)
        push    af
        ld      a,b
        ld      (cur),a
        pop     af
        call    drawpod
        ld      a,(cur)
        call    drawpod
        ld      hl,dirty
        set     2,(hl)
        ret

go_ship: ld     a,M_SHIP
        jr      go_mode
go_map: ld      a,M_MAP
        jr      go_mode
go_mem: call    memtext
        ld      a,M_MEM
go_mode: ld     (mode),a
        ld      hl,dirty
        ld      a,D_FOC|D_KEYS|D_SHIP
        or      (hl)
        ld      (hl),a
        ret
go_intro: call  title
        ld      a,D_ALL
        ld      (dirty),a
        ret

; any key leaves the map, the roll of the lost, and the card at the end
k_any:  call    thought
        jp      tohall

; memtext: the lost, by name, in focbuf
memtext: ld     de,focbuf
        ld      hl,m_lostlist
        call    strcpy
        ld      (mt_dst),de
        xor     a
        ld      (mt_n),a
        ld      (mt_i),a
        ld      (mt_f),a
mt1:    ld      a,(mt_i)
        call    slpadr
        ld      de,SL_FLAGS
        add     hl,de
        bit     0,(hl)
        jr      z,mt2
        ld      hl,(mt_dst)     ; the list stops before it outgrows the buffer
        ld      de,focbuf+240
        or      a
        sbc     hl,de
        jr      c,mt_ok
        ld      a,1
        ld      (mt_f),a
        jr      mt2
mt_ok:  ld      a,(mt_i)
        ld      (tsubj),a
        ld      de,(mt_dst)
        call    cfirst
        call    strcpy
        ld      a,' '
        ld      (de),a
        inc     de
        call    clast
        call    strcpy
        ld      a,','
        ld      (de),a
        inc     de
        ld      a,' '
        ld      (de),a
        inc     de
        ld      (mt_dst),de
        ld      hl,mt_n
        inc     (hl)
mt2:    ld      hl,mt_i
        inc     (hl)
        ld      a,(hl)
        cp      NSL
        jr      nz,mt1
        ld      a,(mt_n)
        or      a
        jr      nz,mt3
        ld      de,focbuf
        ld      hl,m_nolost
        call    strcpy
        xor     a
        ld      (de),a
        ret
mt3:    ld      de,(mt_dst)
        dec     de
        dec     de
        ld      a,(mt_f)
        or      a
        ld      hl,m_dots
        jr      nz,mt4
        ld      hl,m_dot
mt4:    call    strcpy
        xor     a
        ld      (de),a
        ret
