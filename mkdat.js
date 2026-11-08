'use strict';
/*
 * mkdat.js: packs coldstor.txt into COLDSTOR.DAT and writes dat.inc (the section bases for the
 * assembler). Every length is checked against the screen, tokens counted at their longest.
 *
 *   node mkdat.js            writes COLDSTOR.DAT and dat.inc
 *
 * coldstor.txt: `@section` starts a section, each following line is an entry (`#` comments and
 * blank lines are skipped). A section with a stride has that many `|`-separated fields per line.
 * Tokens in a text: %n first name, %N full name, %p place, %o object, %a adjective, %y year.
 *
 * DAT layout: 'CDAT', version, string count (word), zero to 16 bytes; a table of word offsets
 * from the start of the file; the 0-terminated strings; ^Z to a whole 128-byte record.
 */
const fs = require('node:fs');
const path = require('node:path');

// name, stride, longest field, number of entries wanted (0: any)
const SECTIONS = [
    ['fn', 1, 10, 0], ['ln', 1, 12, 0], ['trade', 1, 14, 0], ['origin', 1, 16, 0],
    ['theme', 1, 8, 6], ['mood', 1, 14, 6], ['quest', 1, 34, 8],
    ['ans', 1, 230, 48], ['dream', 1, 140, 36],
    ['slotp', 1, 20, 0], ['sloto', 1, 16, 0], ['slota', 1, 14, 0],
    ['logl', 1, 40, 0], ['greet', 1, 150, 6], ['bye', 1, 150, 4], ['epit', 1, 150, 6],
    ['event', 8, 230, 0], ['endc', 1, 300, 0], ['intro', 1, 300, 0], ['away', 1, 150, 0], ['map', 1, 70, 0]
];
let TOK = { n: 10, N: 24, p: 16, P: 16, o: 16, a: 14, y: 3 };
const EVMAX = [28, 150, 40, 24, 220, 40, 24, 220];       // an event's fields: title, text, then label, effects, result twice

function expandedLength(s) {
    let n = 0;
    for (let i = 0; i < s.length; i++) {
        if (s[i] === '%') { n += TOK[s[i + 1]] || 0; i++; } else n++;
    }
    return n;
}

function parse(text) {
    const sec = {}; let cur = null;
    text.split(/\r?\n/).forEach((raw, i) => {
        const line = raw.replace(/\s+$/, '');
        if (!line || line[0] === '#') return;
        if (line[0] === '@') { cur = line.slice(1).trim(); if (!SECTIONS.find(s => s[0] === cur)) throw new Error(`line ${i + 1}: unknown section ${cur}`); sec[cur] = sec[cur] || []; return; }
        if (!cur) throw new Error(`line ${i + 1}: text before a section`);
        if (/[^\x20-\x7e]/.test(line)) throw new Error(`line ${i + 1}: not plain ASCII`);
        sec[cur].push({ line, no: i + 1 });
    });
    return sec;
}

function pack(text) {
    const sec = parse(text);
    const longest = n => Math.max(0, ...(sec[n] || []).map(e => e.line.length));
    TOK = { n: longest('fn'), N: longest('fn') + 1 + longest('ln'), p: longest('slotp'), P: longest('slotp'), o: longest('sloto'), a: longest('slota'), y: 3 };
    const strings = []; const inc = ['; written by mkdat.js: section bases (string numbers) and entry counts', ''];
    for (const [name, stride, max, want] of SECTIONS) {
        const entries = sec[name] || [];
        if (want && entries.length !== want) throw new Error(`@${name}: ${entries.length} entries, want ${want}`);
        inc.push(`S_${name.toUpperCase()} equ ${strings.length}`, `N_${name.toUpperCase()} equ ${entries.length}`);
        for (const e of entries) {
            const f = e.line.split('|').map(x => x.trim());
            if (f.length > stride) throw new Error(`line ${e.no}: ${f.length} fields, stride ${stride}`);
            while (f.length < stride) f.push('');
            for (const [k, x] of f.entries()) {
                const lim = name === 'event' ? EVMAX[k] : max;
                if (expandedLength(x) > lim) throw new Error(`line ${e.no}: ${expandedLength(x)} > ${lim}: ${x}`);
                strings.push(x);
            }
        }
    }
    inc.push(`N_STR equ ${strings.length}`, '');
    const head = 16 + strings.length * 2;
    const offs = []; let pos = head;
    for (const s of strings) { offs.push(pos); pos += s.length + 1; }
    const len = Math.ceil(pos / 128) * 128;
    const buf = Buffer.alloc(len, 0x1a);
    buf.write('CDAT', 0, 'latin1'); buf[4] = 1; buf.writeUInt16LE(strings.length, 5);
    buf.fill(0, 7, 16);
    offs.forEach((o, i) => buf.writeUInt16LE(o, 16 + i * 2));
    strings.forEach((s, i) => { buf.write(s, offs[i], 'latin1'); buf[offs[i] + s.length] = 0; });
    return { dat: buf, inc: inc.join('\n'), strings };
}

module.exports = { pack, parse, SECTIONS, expandedLength };

if (require.main === module) {
    const dir = __dirname;
    const r = pack(fs.readFileSync(path.join(dir, 'coldstor.txt'), 'utf8'));
    fs.writeFileSync(path.join(dir, 'COLDSTOR.DAT'), r.dat);
    fs.writeFileSync(path.join(dir, 'dat.inc'), r.inc);
    console.log(`COLDSTOR.DAT ${r.dat.length} bytes, ${r.strings.length} strings`);
}
