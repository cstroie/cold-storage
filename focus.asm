; focus.asm: the focus pane (rows 18-22, columns 3-77): what the hall is about to say

drawfoc: ld     b,18
        ld      c,2
        ld      d,77
        ld      e,5
        call    clrarea
        ld      a,(mode)
        add     a,a
        ld      e,a
        ld      d,0
        ld      hl,foctab
        add     hl,de
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        ex      de,hl
        jp      (hl)
foctab: dw      foc_hall, foc_talk, foc_event, foc_ship, foc_map, foc_mem, foc_end

; strip: the voyage as a line of cells with the ship at its year, row B
strip:  push    bc
        call    bstart
        ld      hl,t_home
        call    bstr
        ld      a,(year)
        cp      31
        jr      c,st1
        ld      a,30
st1:    ld      c,a
        srl     a
        add     a,c
        ld      c,a             ; the ship's cell: year x 1.5, 0..45
        ld      b,0
st2:    ld      a,b
        cp      c
        ld      a,'='
        jr      c,st3
        ld      a,'>'
        jr      z,st3
        ld      a,'.'
st3:    call    bchar
        inc     b
        ld      a,b
        cp      46
        jr      nz,st2
        ld      hl,t_veil
        call    bstr
        pop     bc
        ld      c,3
        ld      d,75
        jp      bshow

foc_hall: ld    b,18
        call    strip
        ld      hl,focbuf
        ld      b,19
        ld      c,3
        ld      d,75
        ld      e,2
        call    wrapp
        call    bstart
        ld      hl,t_resv
        call    bstr
        ld      a,(resv)
        call    bdec2
        ld      hl,t_of20
        call    bstr
        ld      a,(nasleep)
        call    bdec2
        ld      hl,t_asl
        call    bstr
        ld      a,(nlost)
        call    bdec2
        ld      hl,t_lst
        call    bstr
        ld      a,(kind)
        call    bdec3
        ld      hl,t_kind
        call    bstr
        ld      b,21
        ld      c,3
        ld      d,75
        call    bshow
        ld      hl,t_hint
        ld      b,22
        ld      c,3
        ld      d,75
        call    gotoputs
        ret

; gotoputs: HL = text, B = row, C = column, D = width
gotoputs: push  hl
        push    de
        call    gotoxy
        pop     de
        pop     hl
        ld      b,d
        jp      putsw

foc_talk: ld    hl,focbuf
        ld      b,18
        ld      c,3
        ld      d,75
        ld      e,2
        call    wrapp
        call    bstart          ; the watch: how long the pod stays open
        ld      hl,t_watchl
        call    bstr
        ld      hl,(wtimer)
        ld      b,0
        ld      de,40
ft1:    or      a
        sbc     hl,de
        jr      c,ft2
        inc     b
        jr      ft1
ft2:    ld      a,b
        cp      11
        jr      c,ft3
        ld      a,10
ft3:    call    bbar
        ld      hl,t_resvl
        call    bstr
        ld      a,(resv)
        call    bdec2
        ld      b,20
        ld      c,3
        ld      d,75
        call    bshow
        xor     a
        ld      (ft_k),a
ft4:    call    bstart          ; the four questions
        ld      a,(ft_k)
        add     a,'1'
        call    bchar
        ld      a,' '
        call    bchar
        ld      a,(ft_k)
        ld      e,a
        ld      d,0
        ld      hl,qa
        add     hl,de
        ld      a,(hl)
        ld      (ft_q),a
        ld      l,a
        ld      h,0
        ld      de,S_QUEST
        add     hl,de
        call    str
        call    bstr
        ld      a,(cur)
        call    slpadr
        ld      de,SL_KNOWN
        add     hl,de
        ld      a,(ft_q)
        ld      d,a
        call    bitq
        and     (hl)
        ld      a,'*'
        jr      z,ft5
        ld      a,'.'
ft5:    push    af
        ld      hl,(bp)
        ld      de,lbuf
        or      a
        sbc     hl,de
        ld      a,34
        sub     l
        jr      nc,ft6
        xor     a
ft6:    call    bsp
        pop     af
        call    bchar
        ld      a,(ft_k)
        and     1
        ld      c,3
        jr      z,ft7
        ld      c,41
ft7:    ld      a,(ft_k)
        srl     a
        add     a,21
        ld      b,a
        ld      d,36
        call    bshow
        ld      hl,ft_k
        inc     (hl)
        ld      a,(hl)
        cp      4
        jr      nz,ft4
        ret

foc_event: ld   b,18
        ld      c,3
        call    gotoxy
        ld      a,A_BOLD
        call    setattr
        xor     a
        call    evfield
        ld      b,75
        call    putsw
        xor     a
        call    setattr
        ld      a,(evstate)
        cp      1
        jr      nz,fe_res
        ld      hl,focbuf
        ld      b,19
        ld      c,3
        ld      d,75
        ld      e,2
        call    wrapp
        ld      b,21
        ld      c,3
        call    gotoxy
        ld      hl,t_cha
        call    puts
        ld      a,2
        call    evfield
        ld      b,70
        call    putsw
        ld      b,22
        ld      c,3
        call    gotoxy
        ld      hl,t_chb
        call    puts
        ld      a,5
        call    evfield
        ld      b,70
        jp      putsw
fe_res: ld      hl,focbuf
        ld      b,19
        ld      c,3
        ld      d,75
        ld      e,3
        call    wrapp
        ld      b,22
        ld      c,3
        ld      d,75
        ld      e,1
        jp      clrarea

foc_ship: call  bstart
        ld      hl,t_crew
        call    bstr
        call    allocsum
        call    bdec2
        ld      hl,t_crewof
        call    bstr
        call    budget
        call    bdec2
        ld      hl,t_crewend
        call    bstr
        ld      b,18
        ld      c,3
        ld      d,75
        call    bshow
        ld      hl,t_sh1
        ld      b,19
        ld      c,3
        ld      d,75
        call    gotoputs
        ld      hl,t_sh2
        ld      b,20
        ld      c,3
        ld      d,75
        call    gotoputs
        ld      hl,t_sh3
        ld      b,21
        ld      c,3
        ld      d,75
        call    gotoputs
        ld      hl,t_sh4
        ld      b,22
        ld      c,3
        ld      d,75
        jp      gotoputs

foc_map: ld     b,18
        call    strip
        xor     a
        ld      (fm_i),a
fm1:    call    bstart
        ld      a,(fm_i)
        ld      e,a
        ld      d,0
        ld      hl,mapyr
        add     hl,de
        ld      a,(year)
        cp      (hl)
        ld      a,'*'
        jr      nc,fm2
        ld      a,' '
fm2:    ld      b,a
        ld      a,'['
        call    bchar
        ld      a,b
        call    bchar
        ld      a,']'
        call    bchar
        ld      a,' '
        call    bchar
        ld      a,(fm_i)
        ld      l,a
        ld      h,0
        ld      de,S_MAP
        add     hl,de
        call    str
        call    bstr
        ld      a,(fm_i)
        add     a,19
        ld      b,a
        ld      c,3
        ld      d,75
        call    bshow
        ld      hl,fm_i
        inc     (hl)
        ld      a,(hl)
        cp      4
        jr      nz,fm1
        ld      b,23
        ret

foc_mem: ld     hl,focbuf
        ld      b,18
        ld      c,3
        ld      d,75
        ld      e,5
        jp      wrapp

foc_end: ld     hl,focbuf
        ld      b,18
        ld      c,3
        ld      d,75
        ld      e,4
        call    wrapp
        ld      hl,t_endhint
        ld      b,22
        ld      c,3
        ld      d,75
        jp      gotoputs
