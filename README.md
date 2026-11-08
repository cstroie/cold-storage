# Cold Storage (COLDSTOR)

A sleeper-ship game for CP/M: you are the last mind awake on a colony ship, and you may wake
one of forty sleepers at a time and talk to them. What you ask is what they dream.

Z80 assembly, CP/M 2.2, 80x24, VT100 / VT52 / ADM-3A, plain ASCII. No hurry, no game over.
Written for [DigitalRerun](https://github.com/cstroie/digital-rerun), where it sits on the shelf.
Player's guide: [docs/PLAYING.txt](docs/PLAYING.txt). Design notes: [DESIGN.md](DESIGN.md).

    sh build.sh        COLDSTOR.COM (pasmo) and COLDSTOR.DAT (node mkdat.js)
    node --test test/  needs a DigitalRerun checkout (ROOT=<dir>, default ../../..)

MIT licence.
