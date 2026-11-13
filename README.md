# Cold Storage (COLDSTOR)

A sleeper-ship game for CP/M: you are the last mind awake on a colony ship, and you may wake
one of forty sleepers at a time and talk to them. What you ask is what they dream.

Z80 assembly, CP/M 2.2, 80x24, VT100 / VT52 / ADM-3A, plain ASCII. No hurry, no game over.
A standalone project, shipped unchanged on the shelf of
[DigitalRerun](https://github.com/cstroie/digital-rerun), whose emulator the tests use.
Player's guide: [docs/PLAYING.txt](docs/PLAYING.txt). Design notes: [DESIGN.md](DESIGN.md).

## Build and test

To build `COLDSTOR.COM` and `COLDSTOR.DAT` you need `node` and [pasmo](https://pasmo.speccy.org/)
(`apt install pasmo`); copy both onto a disk, side by side:

    sh build.sh                      COLDSTOR.DAT and dat.inc (node mkdat.js), then COLDSTOR.COM (pasmo)

The tests play the real program in the emulator of a
[DigitalRerun](https://github.com/cstroie/digital-rerun) checkout. Build first, and say where the
checkout is (default: a `digital-rerun` folder next to this one). Without it only the text tests run:

    ROOT=/path/to/digital-rerun node --test test/*.test.js

The version is in [VERSION](VERSION), the history in [CHANGELOG.md](CHANGELOG.md).

MIT, see [LICENSE](LICENSE). Copyright (c) 2026 Costin Stroie. Cold Storage is a separate project from
DigitalRerun: DigitalRerun only ships the built files, under this same licence, and its own
licence terms do not apply to them.
