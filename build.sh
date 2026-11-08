#!/bin/sh
# Build Cold Storage: COLDSTOR.COM with pasmo (apt install pasmo, or set PASMO=/path/to/pasmo),
# COLDSTOR.DAT and dat.inc from coldstor.txt with mkdat.js (Node.js).
# DEST=<dir> also copies both files there (DigitalRerun's shelf disk).
set -e
cd "$(dirname "$0")"
node mkdat.js
${PASMO:-pasmo} coldstor.asm COLDSTOR.COM
if [ -n "$DEST" ]; then cp COLDSTOR.COM COLDSTOR.DAT "$DEST"/; fi
ls -l COLDSTOR.COM COLDSTOR.DAT
