; COLDSTOR: Cold Storage, a night shift as the last mind of a sleeper ship
;
;   A>COLDSTOR          asks for the terminal
;   A>COLDSTOR /100     VT100      /52  VT52      /ADM  ADM-3A
;
; Z80, CP/M 2.2, 4 MHz. Assemble with pasmo:  pasmo coldstor.asm COLDSTOR.COM
; The words are in COLDSTOR.DAT (node mkdat.js), read whole into memory after the program.
;
; Copyright (c) 2026 Costin Stroie, MIT licence.

BDOS    equ     0005h
TAIL    equ     0080h
ESC     equ     27
CR      equ     13
LF      equ     10
BEL     equ     7

T_VT100 equ     0
T_VT52  equ     1
T_ADM   equ     2

NSL     equ     40              ; sleepers
SLSZ    equ     10              ; bytes each: stability, theme, asked, flags, first, last, trade, origin, age, dream
SL_STAB equ     0
SL_THEME equ    1
SL_KNOWN equ    2
SL_FLAGS equ    3
SL_FN   equ     4
SL_LN   equ     5
SL_TRADE equ    6
SL_ORIG equ     7
SL_AGE  equ     8
SL_DSEED equ    9
F_LOST  equ     1               ; flags: lost, dreaming (~), awake (@)
STABMAX equ     250
AWAY    equ     3000            ; ticks without a key (5 min) = away
YEAREND equ     30              ; the Veil: the end of the first stretch

        include "dat.inc"

        org     100h

start:  ld      (oldsp),sp
        ld      sp,stack
        call    load
        ld      (loaded),a
        ld      a,(term)
        cp      3
        jr      c,s1
        cp      0ffh
        jr      z,s1
        ld      a,0ffh
        ld      (term),a
s1:     call    parse
        ld      a,(term)
        cp      0ffh
        call    z,askterm
        call    loaddat
        call    clkinit
        call    seed
        ld      a,(loaded)
        or      a
        call    z,newgame
        call    curoff
        xor     a
        ld      (cur),a
        ld      (mode),a
        ld      (evstate),a
        ld      (evpend),a
        ld      (away),a
        call    thought
        ld      a,(loaded)
        or      a
        jr      nz,s2
        call    title
        jr      s3
s2:     call    frame
s3:

; ---------------------------------------------------------------- main loop
loop:   call    key
        or      a
        jr      z,lp1
        call    upcase
        ld      b,a
        ld      hl,0
        ld      (idle),hl
        ld      a,(away)
        or      a
        call    nz,back
        ld      a,b
        cp      'Q'
        jp      z,quit
        call    dispatch
lp1:    call    evcheck
        call    ticker
        call    refresh
        ld      b,24
        ld      c,80
        call    gotoxy
        call    tickwait
        jr      loop

dispatch: push  af
        ld      a,(mode)
        add     a,a
        ld      e,a
        ld      d,0
        ld      hl,keytbl
        add     hl,de
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        ex      de,hl
        pop     af
        jp      (hl)
keytbl: dw      k_hall, k_talk, k_event, k_ship, k_any, k_any, k_any

; back: a key after being away
back:   push    bc
        xor     a
        ld      (away),a
        ld      a,(awaycnt)
        or      a
        jr      z,bk1
        ld      de,focbuf
        ld      hl,m_back
        call    strcpy
        xor     a
        ld      (de),a
        ld      hl,dirty
        set     5,(hl)
bk1:    pop     bc
        ret

quit:   call    save
quit0:  call    curon
        call    cls
        ld      hl,m_bye
        call    puts
        ld      sp,(oldsp)
        ret

; ---------------------------------------------------------------- a new voyage
newgame: ld     a,'C'
        ld      (state),a
        ld      a,'S'
        ld      (state+1),a
        ld      a,1
        ld      (state+2),a
        xor     a
        ld      (year),a
        ld      (tenth),a
        ld      (kind),a
        ld      (flags),a
        ld      hl,0
        ld      (watch),hl
        ld      hl,0a0ah
        ld      (sys),hl
        ld      (sys+2),hl
        ld      hl,0200h
        ld      (alloc),hl
        ld      hl,0202h
        ld      (alloc+2),hl
        ld      a,20
        ld      (resv),a
        ld      a,0ffh
        ld      (lastev),a
        ld      ix,slp
        ld      b,NSL
ng1:    push    bc
        ld      b,60
        call    rndn
        add     a,150
        ld      (ix+SL_STAB),a
        ld      b,6
        call    rndn
        ld      (ix+SL_THEME),a
        xor     a
        ld      (ix+SL_KNOWN),a
        ld      (ix+SL_FLAGS),a
        ld      b,N_FN
        call    rndn
        ld      (ix+SL_FN),a
        ld      b,N_LN
        call    rndn
        ld      (ix+SL_LN),a
        ld      b,N_TRADE
        call    rndn
        ld      (ix+SL_TRADE),a
        ld      b,N_ORIGIN
        call    rndn
        ld      (ix+SL_ORIG),a
        ld      b,40
        call    rndn
        add     a,22
        ld      (ix+SL_AGE),a
        call    rnd
        ld      a,(rseed)
        ld      (ix+SL_DSEED),a
        ld      de,SLSZ
        add     ix,de
        pop     bc
        djnz    ng1
        ret

; ---------------------------------------------------------------- the title
title:  call    cls
        ld      b,2
        ld      c,29
        call    gotoxy
        ld      a,A_BOLD
        call    setattr
        ld      hl,t_title
        call    puts
        xor     a
        call    setattr
        xor     a
        ld      (ti_i),a
        ld      b,5
ti1:    ld      a,(ti_i)
        ld      l,a
        ld      h,0
        ld      de,S_INTRO
        add     hl,de
        push    bc
        call    str
        pop     bc
        ld      c,6
        ld      d,68
        ld      e,4
        push    bc
        call    wrapp
        pop     bc
        ld      a,b
        add     a,4
        ld      b,a
        ld      hl,ti_i
        inc     (hl)
        ld      a,(hl)
        cp      N_INTRO
        jr      nz,ti1
        ld      b,22
        ld      c,29
        call    gotoxy
        ld      hl,t_press
        call    puts
ti2:    ld      hl,(rseed)
        inc     hl
        ld      (rseed),hl
        call    raw
        or      a
        jr      z,ti2
        jp      frame

        include "term.asm"
        include "clock.asm"
        include "text.asm"
        include "ui.asm"
        include "focus.asm"
        include "hall.asm"
        include "talk.asm"
        include "ship.asm"
        include "event.asm"
        include "voyage.asm"
        include "save.asm"

; ---------------------------------------------------------------- texts
t_title: db     'C O L D   S T O R A G E',0
t_press: db     '[ press a key ]',0
t_hall: db      'CRYO HALL 3',0
t_slp:  db      'SLEEPER',0
t_ship: db      'SHIP',0
t_log:  db      'LOG',0
t_foc:  db      'WREN',0
t_leg1: db      '[#]rest [~]dream [!]frayed',0
t_leg2: db      '[@]awake [ ]lost  <#> you',0
t_name: db      'ANSELM',39,'S PATIENCE',0
t_year: db      'YEAR ',0
t_watch: db     'WATCH ',0
t_cool: db      'COOL ',0
t_asleep: db    'ASLEEP ',0
t_from: db      'from ',0
t_theme: db     'theme: ',0
t_stab: db      'stability ',0
t_asked: db     'asked ',0
t_init: db      'HFOLGWKS'
t_lostln: db    'LOST ',0
shlab:  db      'REACTOR','COOLANT','HULL   ','COMMS  '
t_bud:  db      'bud ',0
t_home: db      'HOME [',0
t_veil: db      '] VEIL',0
t_resv: db      'Reserve ',0
t_of20: db      '/20   Asleep ',0
t_asl:  db      '   Lost ',0
t_lst:  db      '   Kindness ',0
t_kind: db      0
t_hint: db      'Choose a pod with the arrows, then press W to wake a sleeper. S is the ship.',0
t_watchl: db    'Watch ',0
t_resvl: db     '  coolant reserve ',0
t_cha:  db      '[A] ',0
t_chb:  db      '[B] ',0
t_crew: db      'Crew at work: ',0
t_crewof: db    ' of ',0
t_crewend: db   '   (the budget is 2 and half the reactor)',0
t_sh1:  db      'REACTOR  powers the crew budget. Nothing mends it; every year it wears.',0
t_sh2:  db      'COOLANT  keeps the sleepers cold. When it fails, they fray, year by year.',0
t_sh3:  db      'HULL     dust and meteors find thin places. Crews keep them thick.',0
t_sh4:  db      'COMMS    the home star''s signal. A strong array calms a sleeper.',0
t_endhint: db   '[any key]  and the voyage goes on, beyond the Veil.',0
m_nodat: db     CR,LF,'COLDSTOR.DAT is missing or wrong. Build it with: node mkdat.js',CR,LF,0
m_nobody: db    'Nobody is in that pod any more.',0
m_dry:  db      'The coolant reserve is too low to wake anyone. It refills a little each year.',0
m_again: db     'Again, then: ',0
m_lostlist: db  'Lost, and remembered: ',0
m_dot:  db      '.',0
m_dots: db      ', and more.',0
m_nolost: db    'Nobody is lost. Nobody lost yet.',0
m_back: db      'You are back. The ship carried on without you; the log has what happened.',0
m_bye:  db      'Anselm''s Patience sails on. WREN goes dim, and the hum keeps time.',CR,LF,0
m_ask:  db      CR,LF,'COLD STORAGE',CR,LF,CR,LF
        db      'Your terminal?  1 VT100   2 VT52   3 ADM-3A  ',0
mapyr:  db      0,14,22,30
keystr:
k0:     db      ' [arrows] pod  [W]ake  [S]hip  [M]ap  [L] the lost  [?] intro  [Q]uit (saves)',0
k1:     db      ' [1]-[4] ask  [Esc] let them sleep  [Q]uit',0
k2:     db      ' [A] [B] choose, then any key  [Q]uit',0
k3:     db      ' [up/down] system  [left/right] crew  [Esc] back  [Q]uit',0
k4:     db      ' [any key] back to the hall  [Q]uit',0
k5:     db      ' [any key] back to the hall  [Q]uit',0
k6:     db      ' [any key] go on, beyond the Veil  [Q]uit',0
keytab: dw      k0, k1, k2, k3, k4, k5, k6

; ---------------------------------------------------------------- state (the first 128 bytes are saved)
state:  db      'C','S',1
term:   db      0ffh
rseed:  dw      0ace1h
year:   db      0
tenth:  db      0
watch:  dw      0
sys:    db      10,10,10,10
alloc:  db      0,2,2,2
resv:   db      20
kind:   db      0
flags:  db      0
lastev: db      0ffh
        ds      state+128-$
slp:    ds      NSL*SLSZ
        ds      112

xs:     dw      1234h
oldsp:  dw      0
loaded: db      0
hasclk: db      0
nextms: dw      0
mode:   db      0
cur:    db      0
tsubj:  db      0
dirty:  db      0
rf_d:   db      0
t60:    db      0
idle:   dw      0
away:   db      0
awaycnt: db     0
nasleep: db     NSL
nlost:  db      0
shsel:  db      0
sy_i:   db      0
sl_i:   db      0
evstate: db     0
evpend: db      0
evi:    db      0
esubj:  db      0
evch:   db      0
fx_op:  db      0
fx_s:   db      0
fx_d:   db      0
fx_i:   db      0
wtimer: dw      0
qa:     db      0,0,0,0
qmask:  db      0
qcur:   db      0
ft_k:   db      0
ft_q:   db      0
fm_i:   db      0
ti_i:   db      0
mt_n:   db      0
mt_i:   db      0
mt_dst: dw      0
mt_f:   db      0
dp_i:   db      0
dp_c:   db      0
podsh:  ds      NSL
ds_i2v: db      0
bp:     dw      0
bx_hl:  dw      0
bx_row: db      0
bx_col: db      0
bx_w:   db      0
bx_h:   db      0
bx_n:   db      0
wr_row: db      0
wr_col: db      0
wr_w:   db      0
wr_n:   db      0
wr_pos: db      0
xy_buf: db      0,0,0,0
lbuf:   ds      90
xbuf:   ds      300
focbuf: ds      300
logbuf: ds      LOGW*4
fcb_dat: db     0,'COLDSTORDAT'
        ds      24
fcb_sav: db     0,'COLDSTORSAV'
        ds      24
        ds      128
stack:
datbuf:
