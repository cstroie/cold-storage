; talk.asm: waking a sleeper and talking. A watch costs the coolant reserve; every answer
; steadies the sleeper, and what is asked becomes what they dream.

QDRY    equ     0

; dowake: the sleeper under the cursor
dowake: ld      a,(cur)
        call    slpadr
        push    hl
        pop     ix
        bit     0,(ix+SL_FLAGS)
        jr      nz,dw_lost
        ld      a,(resv)
        cp      2
        jr      c,dw_dry
        sub     2
        ld      (resv),a
        set     2,(ix+SL_FLAGS)
        ld      hl,(watch)
        inc     hl
        ld      (watch),hl
        ld      hl,400
        ld      (wtimer),hl
        call    pick4
        ld      a,(cur)
        ld      (tsubj),a
        call    xsrnd
        ld      b,N_GREET
        call    xrndn
        ld      l,a
        ld      h,0
        ld      de,S_GREET
        add     hl,de
        call    str
        ld      de,focbuf
        call    xpand
        ld      a,M_TALK
        ld      (mode),a
        ld      hl,dirty
        ld      a,D_HDR|D_HALL|D_SLP|D_FOC|D_KEYS
        or      (hl)
        ld      (hl),a
        ret
dw_lost: ld     hl,m_nobody
        jr      dw_msg
dw_dry: ld      hl,m_dry
dw_msg: ld      de,focbuf
        call    strcpy
        xor     a
        ld      (de),a
        ld      hl,dirty
        set     5,(hl)
        ret

; pick4: four different questions of the eight, into qa
pick4:  xor     a
        ld      (qmask),a
        ld      hl,qa
        ld      c,4
p4a:    ld      b,8
        call    rndn
        ld      d,a
        call    bitq
        ld      e,a
        ld      a,(qmask)
        and     e
        jr      nz,p4a
        ld      a,(qmask)
        or      e
        ld      (qmask),a
        ld      (hl),d
        inc     hl
        dec     c
        jr      nz,p4a
        ret
; bitq: A = 1 << D
bitq:   ld      b,d
        inc     b
        ld      a,1
bq0:    dec     b
        ret     z
        add     a,a
        jr      bq0

; k_talk: A = key
k_talk: cp      27
        jp      z,talkend
        sub     '1'
        ret     c
        cp      4
        ret     nc
; askq: A = 0..3, the question on that line
askq:   ld      e,a
        ld      d,0
        ld      hl,qa
        add     hl,de
        ld      a,(hl)
        ld      (qcur),a
        ld      a,(resv)
        or      a
        jp      z,talkend
        dec     a
        ld      (resv),a
        ld      a,(cur)
        ld      (tsubj),a
        call    slpadr
        push    hl
        pop     ix
        ld      a,(qcur)
        ld      b,6
        call    mulb
        add     a,(ix+SL_THEME)
        ld      l,a
        ld      h,0
        ld      de,S_ANS
        add     hl,de
        call    str
        ld      de,focbuf
        ld      a,(qcur)
        ld      d,a
        call    bitq
        ld      e,a
        ld      a,(ix+SL_KNOWN)
        and     e
        jr      nz,aq_old
        ld      a,(ix+SL_KNOWN) ; the first time: steadier, and maybe a new weather in the dream
        or      e
        ld      (ix+SL_KNOWN),a
        push    hl
        push    ix
        pop     hl
        ld      b,16
        ld      c,0
        ld      d,STABMAX
        call    clampadd
        pop     hl
        ld      b,3
        call    rndn
        or      a
        jr      z,aq_k
        ld      a,(qcur)
        cp      6
        jr      nc,aq_k
        ld      (ix+SL_THEME),a
        call    newdream
aq_k:   ld      a,(qcur)
        cp      7
        jr      nz,aq_t
        push    hl
        ld      hl,kind
        ld      b,1
        ld      c,0
        ld      d,255
        call    clampadd
        pop     hl
        jr      aq_t
aq_old: push    hl              ; asked before: the same answer, a little less
        push    ix
        pop     hl
        ld      b,4
        ld      c,0
        ld      d,STABMAX
        call    clampadd
        pop     hl
        push    hl
        ld      hl,m_again
        ld      de,focbuf
        call    strcpy
        pop     hl
        jr      aq_x
aq_t:   ld      de,focbuf
aq_x:   call    xpand
        ld      hl,dirty
        ld      a,D_HDR|D_HALL|D_SLP|D_FOC
        or      (hl)
        ld      (hl),a
        ret

; talkend: the pod closes
talkend: ld     a,(cur)
        ld      (tsubj),a
        call    slpadr
        res     2,(hl)
        call    xsrnd
        ld      b,N_BYE
        call    xrndn
        ld      l,a
        ld      h,0
        ld      de,S_BYE
        add     hl,de
        call    str
        ld      de,focbuf
        call    xpand
        jp      tohall
