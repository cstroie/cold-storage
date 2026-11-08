# Cold Storage (COLDSTOR)

A night shift as WREN, the last of a sleeper ship's minds. Z80 assembly, CP/M 2.2, 4 MHz,
80x24, VT100 / VT52 / ADM-3A, plain ASCII. No hurry, no game over. The first slice runs to
the Veil at year 30 and does not stop there.

## Files

| File | Role |
|------|------|
| `coldstor.asm` | start, main loop, key dispatch, new voyage, title, texts, state and buffers |
| `term.asm` | terminal driver, console, decimal, random, `/100 /52 /ADM` (from Signal Seeker) |
| `clock.asm` | DigitalRerun's clock device for 100 ms ticks, busy-wait without it (from Signal Seeker) |
| `text.asm` | DAT loader, `str`, token expansion (`xpand`), line builder (`b*`), word wrap (`wrapp`) |
| `ui.asm` | boxes, frame, `dirty` and `refresh`, header, hall, sleeper pane, ship pane, log, keys line |
| `focus.asm` | the focus pane per mode: voyage, talk, event, ship help, map, the lost, the ending |
| `hall.asm`, `talk.asm`, `ship.asm`, `event.asm` | the keys of each mode and what they do |
| `voyage.asm` | ticks, years, ship wear, sleeper drift, losses, the ending, the quiet-year line |
| `save.asm` | `COLDSTOR.SAV`: five records straight from `state` |
| `coldstor.txt`, `mkdat.js` | the words; the packer (checks every length) and `dat.inc` |
| `tools/screen.js` | runs the program in DigitalRerun's emulator and prints the screen (development, tests) |

## Screen

Row 1 header; rows 2-10 hall (cols 1-30) and sleeper (32-79); rows 11-16 ship and log; rows 17-23
the focus pane; row 24 the keys. Nothing is written at column 80 of row 24. Everything is placed
by cursor address, and only what changed is redrawn: code sets bits of `dirty` (`D_HDR` ...) and
`refresh` draws them once a tick.

## State

`state` (the first 128 bytes: signature, terminal, seed, year, systems, crew, reserve, kindness)
and `slp` (40 sleepers x 10 bytes: stability, theme, asked bits, flags, first, last, trade,
origin, age, dream seed) are written as five records. A sleeper's name, trade and origin are
indexes into DAT sections; the dream shown is a pure function of theme and dream seed, so it
does not change when the pane is redrawn.

## The words

`coldstor.txt` sections are listed in `mkdat.js`. Tokens in any text: `%n` first name, `%N` full
name, `%p` `%P` place, `%o` object, `%a` adjective, `%y` year (the slot words come from the
generator `xs`). An event is eight strings: title, text, then label, effects and result for each
of two choices. Effects: `R C H M` systems, `S` the sleeper's stability (x10), `A` everyone's (x4),
`T=n` theme, `X` takes another sleeper's theme and dream (a shared dream), `K` kindness.
`dat.inc` carries `S_<section>` (first string number) and `N_<section>` (entries).

## Rules of thumb

- A tick is 100 ms, a tenth of a year 60 ticks, a year 600 ticks.
- Nothing may keep `DE` across `str`, `slpadr`, `cfirst`, `clast` unless the routine says so
  (`str`, `cfirst`, `clast` keep it; `slpadr` does not).
- `rnd` keeps `HL` and leaves the value in `rseed`; `rndn` is `rseed` mod B; `xrnd`/`xrndn` are
  the text generator's.
