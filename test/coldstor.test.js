'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { pack } = require('../mkdat.js');

const APP = path.join(__dirname, '..');
const ROOT = process.env.ROOT || path.join(APP, '..', 'digital-rerun');
// the game tests need the checkout and the built files (they are not in git: sh build.sh)
const built = ['COLDSTOR.COM', 'COLDSTOR.DAT'].every(f => fs.existsSync(path.join(APP, f)));
const haveRoot = fs.existsSync(path.join(ROOT, 'js/machine.js')) && built;

test('COLDSTOR.DAT and dat.inc are what coldstor.txt packs to', () => {
    const r = pack(fs.readFileSync(path.join(APP, 'coldstor.txt'), 'utf8'));
    if (fs.existsSync(path.join(APP, 'COLDSTOR.DAT'))) assert.deepEqual(fs.readFileSync(path.join(APP, 'COLDSTOR.DAT')), r.dat);
    assert.equal(fs.readFileSync(path.join(APP, 'dat.inc'), 'utf8'), r.inc);
});

test('mkdat refuses a line that does not fit, a wrong count and an unknown section', () => {
    const txt = fs.readFileSync(path.join(APP, 'coldstor.txt'), 'utf8');
    assert.throws(() => pack(txt.replace('@theme\nHOME', '@theme\nHOMEHOMEHOME')), /> 8/);
    assert.throws(() => pack(txt.replace('@mood\nadrift\n', '@mood\n')), /@mood: 5 entries, want 6/);
    assert.throws(() => pack(txt + '\n@nonsense\nx\n'), /unknown section/);
    assert.throws(() => pack(txt.replace('Mop polishes pod 12. Again.', 'x'.repeat(41))), /> 40/);
});

test('every event is eight fields and every effect is one the game knows', () => {
    const { parse, SECTIONS } = require('../mkdat.js');
    const sec = parse(fs.readFileSync(path.join(APP, 'coldstor.txt'), 'utf8'));
    assert.ok(sec.event.length >= 15);
    for (const e of sec.event) {
        const f = e.line.split('|').map(x => x.trim());
        assert.equal(f.length, 8, e.line.slice(0, 30));
        for (const fx of [f[3], f[6]]) assert.match(fx, /^([RCHMKSA][+-=][0-9]|T=[0-5]|X=0)*$/, fx);
    }
});

(haveRoot ? test : test.skip)('the game runs: title, the hall, a wake, a question, a year, the ship, quit, resume', async () => {
    const { boot } = require('../tools/screen.js');
    const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'coldstor-'));
    for (const f of ['COLDSTOR.COM', 'COLDSTOR.DAT']) fs.copyFileSync(path.join(APP, f), path.join(dir, f));
    const s = await boot(dir);
    const send = keys => { s.m.console.type(keys); s.run(1.5); return s.text(); };
    s.m.console.paste('COLDSTOR /100\r'); s.run(1);
    assert.match(s.text(), /C O L D   S T O R A G E[\s\S]*press a key/);
    let t = send(' ');
    assert.match(t, /ANSELM'S PATIENCE\s+YEAR 000\.0\s+WATCH 0000\s+COOL #{10}\s+ASLEEP 40/);
    assert.match(t, /\| <#>\[#\]/, 'the cursor is on the first pod');
    assert.match(t, /\[W\]ake/);
    t = send('w');
    assert.match(t, /WATCH 0001/);
    assert.match(t, /<@>/);
    assert.match(t, /\[1\]-\[4\] ask/);
    t = send('1');
    assert.match(t, /asked [A-Z-]( [A-Z-])+/);
    assert.match(t, /coolant reserve 17/);
    t = send('\x1b');
    assert.match(t, /<#>/, 'the pod is closed again');
    t = send('s'); send('\x1b[B'); t = send('+');
    assert.match(t, /> COOLANT #{10} \[3\]/);
    assert.match(t, /Crew at work: 07 of 07/);
    send('\x1b');
    s.run(60);
    assert.match(s.text(), /YEAR 001\./);
    t = send('q');
    assert.match(t, /sails on/);
    s.m.out = ''; s.m.console.paste('DIR\r'); s.run(1);
    assert.ok(fs.readdirSync(dir).includes('COLDSTOR.COM'));
    s.m.console.paste('COLDSTOR /100\r'); s.run(1);
    t = s.text();
    assert.doesNotMatch(t, /press a key/, 'a saved voyage goes straight to the hall');
    assert.match(t, /YEAR 001\./);
    assert.match(t, /WATCH 0001/);
});
