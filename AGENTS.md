# AGENTS.md

Cold Storage: a sleeper-ship game in Z80 assembly for CP/M 2.2 (80x24, VT100/VT52/ADM-3A, plain
ASCII). Standalone project; DigitalRerun only ships the built files. Read `DESIGN.md` first.

- Build: `sh build.sh` (needs `node` and `pasmo`): `COLDSTOR.DAT` and `dat.inc` from `coldstor.txt`
  with `mkdat.js`, then `COLDSTOR.COM`. The `.COM` and `.DAT` are not in git; releases carry both.
  `dat.inc` is generated and tracked: edit `coldstor.txt`, never `dat.inc`.
- Test: `ROOT=<digital-rerun checkout> node --test test/*.test.js` (build first). Without the
  checkout, or without the built files, only the text tests run. `tools/screen.js` runs the game
  by hand in the same emulator.
- Words: `mkdat.js` refuses a line that does not fit; keep to the limits it reports.
- Version: `VERSION` and `CHANGELOG.md`; tag releases `vX.Y.Z`. Commits: `feat:`, `fix:`, `docs:`.
