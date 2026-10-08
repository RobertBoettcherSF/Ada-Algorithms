#!/usr/bin/env python3
"""Seeded random-input driver for plain-Ada folders (docs/VV.md 3h).

For every public subprogram of a non-generic library package spec whose
parameters are all simple (Integer, Natural, Positive, Long_Integer,
Boolean, Character, String, or an unconstrained array of Integer/Natural/
Positive or of a discrete type, declared in that spec; also integer and
modular types and integer subtypes declared there, random over their whole
range with extra weight near both ends), a driver is generated that calls it
2000 times with seeded random arguments (small ranges, lengths 0 .. 20),
in a scratch copy, with all checks on (-gnat2022 -gnata -gnato -gnatVa -g).

A call counts as a crash only when a language check fails inside the
library (Constraint_Error / Program_Error / Storage_Error whose message
names a failed check, e.g. "overflow check failed", "index check failed").
Precondition failures, explicit raises and the package's own exceptions
are rejections of the input, not crashes.

usage: random_drive.py [--from-file ids.txt] [-j N] [--out tools/vv/random_drive.csv]
"""
import argparse, csv, os, re, shutil, subprocess, tempfile
from concurrent.futures import ThreadPoolExecutor

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SCAL = {'integer': 'Next (-50, 50)', 'natural': 'Next (0, 50)', 'positive': 'Next (1, 50)',
        'long_integer': 'Long_Integer (Next (-50, 50))', 'boolean': '(Next (0, 1) = 1)',
        'character': "Character'Val (Next (32, 126))", 'string': 'Rand_String'}
CHECK = re.compile(r'check failed|access check|length check|discriminant check|accessibility|stack overflow|infinite recursion', re.I)

def strip(t):
    return '\n'.join(l.split('--')[0] for l in t.split('\n'))

def specs(folder):
    for d in ('', 'src'):
        p = os.path.join(folder, d)
        if not os.path.isdir(p): continue
        for f in sorted(os.listdir(p)):
            if f.endswith('.ads') and not f.startswith('test'):
                yield os.path.join(p, f)

def parse(path):
    t = strip(open(path, errors='replace').read())
    m = re.search(r'^\s*package\s+([\w.]+)\s+(?:with\s[^;]*?)?is\b', t, re.M | re.I)
    if not m or re.search(r'^\s*generic\b', t[:m.start()], re.M | re.I) or re.search(r'\bis\s+new\b', t[m.start():m.end() + 40], re.I):
        return None, []
    pkg = m.group(1)
    vis = re.split(r'^\s*private\b', t[m.end():], maxsplit=1, flags=re.M | re.I)[0]
    disc = {}
    for d in re.finditer(r'\btype\s+(\w+)\s+is\s+range\s+[^;]+;', vis, re.I):
        disc[d.group(1).lower()] = d.group(1)
    for d in re.finditer(r'\btype\s+(\w+)\s+is\s+mod\s+([^;]+);', vis, re.I):
        m2 = re.match(r'\s*2\s*\*\*\s*(\d+)\s*$', d.group(2)); m3 = re.match(r'\s*(\d[\d_]*)\s*$', d.group(2))
        if (m2 and int(m2.group(1)) <= 62) or (m3 and int(m3.group(1).replace('_', '')) < 2**62):
            disc[d.group(1).lower()] = d.group(1)
    for d in re.finditer(r'\bsubtype\s+(\w+)\s+is\s+(Integer|Natural|Positive|Long_Integer)\b[^;]*;', vis, re.I):
        disc[d.group(1).lower()] = d.group(1)
    elem_ok = lambda t: t.lower() in SCAL and t.lower() not in ('string', 'boolean', 'character') or t.lower() in disc
    arrays = {}
    for a in re.finditer(r'type\s+(\w+)\s+is\s+array\s*\(\s*(\w+)\s+range\s*<>\s*\)\s+of\s+(\w+)\s*;', vis, re.I):
        if a.group(2).lower() in ('positive', 'natural', 'integer') and elem_ok(a.group(3)):
            arrays[a.group(1).lower()] = (a.group(1), a.group(2), a.group(3))
    arrays['__disc__'] = disc
    subs = []
    for s in re.finditer(r'\b(function|procedure)\s+(\w+)\s*(\((.*?)\))?\s*(return\s+([\w.]+))?\s*(;|with\b|is\b)', vis, re.I | re.S):
        kind, name, params, rt, term = s.group(1).lower(), s.group(2), s.group(4), s.group(6), s.group(7)
        if term.lower() == 'is':   # expression function / renames / instance: still callable
            pass
        if not params:
            continue
        ok, plist = True, []
        for grp in params.split(';'):
            if ':' not in grp: ok = False; break
            names, spec = grp.split(':', 1)
            spec = spec.split(':=')[0].strip()
            mm = re.match(r'(in\s+out|out|in)?\s*([\w.]+)$', spec, re.I)
            if not mm: ok = False; break
            mode, typ = (mm.group(1) or 'in').lower().replace(' ', ''), mm.group(2).lower()
            if typ not in SCAL and typ not in arrays and typ not in arrays['__disc__']: ok = False; break
            for n in names.split(','):
                plist.append((n.strip(), mode, typ))
        if ok and plist and not (kind == 'function' and rt is None):
            subs.append((kind, name, plist, rt))
    return pkg, [(s, arrays) for s in subs]

def rnd(pkg, typ, disc):
    if typ in disc:
        t = f'{pkg}.{disc[typ]}'
        return f"{t}'Val (Rand_In (Long_Long_Integer ({t}'Pos ({t}'First)), Long_Long_Integer ({t}'Pos ({t}'Last))))"
    return SCAL[typ]

def driver(pkg, subs):
    lines = ['pragma Ada_2022;', 'with Ada.Text_IO; use Ada.Text_IO;', 'with Ada.Exceptions; use Ada.Exceptions;',
             f'with {pkg};', 'procedure RD_Main is',
             '   Seed : Long_Long_Integer := 20261008;',
             '   function Next (Lo, Hi : Integer) return Integer is',
             '   begin',
             '      Seed := (Seed * 16807) mod 2147483647;',
             '      return Lo + Integer (Seed mod Long_Long_Integer (Hi - Lo + 1));',
             '   end Next;',
             '   function Rand_String return String is',
             '      S : String (1 .. Next (0, 20));',
             '   begin',
             "      for C of S loop C := Character'Val (Next (32, 126)); end loop;",
             '      return S;',
             '   end Rand_String;',
             '   function Rand_In (Lo, Hi : Long_Long_Integer) return Long_Long_Integer is',
             '      Wide : constant Boolean := Hi / 2 - Lo / 2 > 2 ** 40;',
             '   begin',
             '      if not Wide and then Hi - Lo <= 40 then',
             '         return Lo + Long_Long_Integer (Next (0, Integer (Hi - Lo)));',
             '      end if;',
             '      case Next (0, 2) is',
             '         when 0 => return Lo + Long_Long_Integer (Next (0, 20));',
             '         when 1 => return Hi - Long_Long_Integer (Next (0, 20));',
             '         when others =>',
             '            return Lo + Long_Long_Integer (Next (0, Integer\'Last - 1)) mod',
             '              (if Wide then 2 ** 30 else Long_Long_Integer\'Min (Hi - Lo, 2 ** 30) + 1);',
             '      end case;',
             '   end Rand_In;']
    body = ['begin']
    for i, ((kind, name, plist, rt), arrays) in enumerate(subs):
        disc = arrays['__disc__']
        decl, args, pre = [], [], []
        for j, (n, mode, typ) in enumerate(plist):
            v = f'P{j}'
            if typ in arrays:
                tn, ix, el = arrays[typ]
                lo = {'positive': 1, 'natural': 0, 'integer': 1}[ix.lower()]
                decl.append(f'         {v} : {pkg}.{tn} ({lo} .. {lo} - 1 + Next (0, 20));')
                pre.append(f'         for X of {v} loop X := {rnd(pkg, el.lower(), disc)}; end loop;')
            elif typ in disc:
                decl.append(f'         {v} : {pkg}.{disc[typ]} := {rnd(pkg, typ, disc)};')
            elif typ == 'string':
                decl.append(f'         {v} : String := Rand_String;')
            else:
                tname = {'integer': 'Integer', 'natural': 'Natural', 'positive': 'Positive', 'long_integer': 'Long_Integer',
                         'boolean': 'Boolean', 'character': 'Character'}[typ]
                decl.append(f'         {v} : {tname} := {SCAL[typ]};')
            args.append(v)
        call = f'{pkg}.{name} ({", ".join(args)})'
        rt = (f'{pkg}.{rt}' if rt and '.' not in rt and rt.lower() not in ('integer', 'natural', 'positive', 'boolean', 'character', 'string', 'float', 'long_float', 'long_integer') else rt)
        stmt = (f'         declare R : constant {rt} := {call}; pragma Unreferenced (R); begin null; end;'
                if kind == 'function' else f'         {call};')
        body += [f'   for Run in 1 .. 2000 loop',
                 '      declare',
                 *decl,
                 '      begin',
                 *pre,
                 '         begin',
                 '   ' + stmt,
                 '         exception',
                 '            when E : Constraint_Error | Program_Error | Storage_Error =>',
                 f'               Put_Line ("RD_EXC {name} " & Exception_Name (E) & " : " & Exception_Message (E)',
                 f'                         & " | args:"' + ''.join(
                     f' & " " & {a}\'Image' if plist[k][2] not in arrays else f' & " len" & {a}\'Length\'Image'
                     for k, a in enumerate(args)) + ');',
                 '               exit;',
                 '            when others => null;',
                 '         end;',
                 '      end;',
                 '   end loop;']
    body += ['   Put_Line ("RD_DONE");', 'end RD_Main;']
    return '\n'.join(lines + body) + '\n'

def check(fid, work_root, timeout):
    src = os.path.join(ROOT, fid)
    rows = []
    for spec in specs(src):
        try:
            pkg, subs = parse(spec)
        except Exception:
            continue
        if not pkg or not subs:
            continue
        work = tempfile.mkdtemp(prefix=fid.replace('/', '_') + '_', dir=work_root)
        try:
            shutil.copytree(src, work, dirs_exist_ok=True, ignore=shutil.ignore_patterns('obj', 'bin', 'gnatprove', '*.o', '*.ali'))
            open(os.path.join(work, 'rd_main.adb'), 'w').write(driver(pkg, subs))
            os.makedirs(os.path.join(work, 'rdobj'), exist_ok=True)
            inc = [f'-I{d}' for d in ('src',) if os.path.isdir(os.path.join(work, d))]
            b = subprocess.run(['gnatmake', '-q', '-f', '-gnat2022', '-gnata', '-gnato', '-gnatVa', '-g', *inc, '-D', 'rdobj',
                                'rd_main.adb', '-o', 'rd'], cwd=work, capture_output=True, text=True, errors='replace')
            names = ' '.join(s[0][1] for s in subs)
            if b.returncode != 0:
                rows.append(dict(folder=fid, package=pkg, subprograms=names, result='driver not built', detail=''))
                continue
            try:
                r = subprocess.run(['./rd'], cwd=work, capture_output=True, text=True, errors='replace', timeout=timeout, stdin=subprocess.DEVNULL)
                out = r.stdout + r.stderr
            except subprocess.TimeoutExpired as e:
                out = (e.stdout or b'').decode(errors='replace') if isinstance(e.stdout, bytes) else (e.stdout or '')
                out += '\nRD_TIMEOUT'
            exc = [l for l in out.splitlines() if l.startswith('RD_EXC')]
            crash = [l for l in exc if CHECK.search(l)]
            if crash:
                res = 'crash (check failed)'
            elif 'RD_TIMEOUT' in out:
                res = 'timeout'
            elif 'RD_DONE' not in out:
                res = 'driver died'
            else:
                res = 'ok' if not exc else 'ok (explicit Constraint_Error/Program_Error only)'
            rows.append(dict(folder=fid, package=pkg, subprograms=names, result=res,
                             detail=' || '.join((crash or exc or [l for l in out.splitlines()[-2:]]))[:400] if res != 'ok' else ''))
        finally:
            shutil.rmtree(work, ignore_errors=True)
    return rows

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--from-file'); ap.add_argument('-j', type=int, default=4)
    ap.add_argument('--out', default=os.path.join(ROOT, 'tools/vv/random_drive.csv'))
    ap.add_argument('--work'); ap.add_argument('--timeout', type=int, default=20)
    a = ap.parse_args()
    if a.from_file:
        ids = [l.strip() for l in open(a.from_file) if l.strip() and not l.startswith('#')]
    else:
        ids = [r['folder'] for r in csv.DictReader(open(os.path.join(ROOT, 'PROOFS.csv'))) if r['level'] == 'Ada' and not r['duplicate_of']]
    work_root = a.work or tempfile.mkdtemp(prefix='rd_')
    os.makedirs(work_root, exist_ok=True)
    out = []
    with ThreadPoolExecutor(a.j) as ex:
        for rows in ex.map(lambda f: check(f, work_root, a.timeout), ids):
            for r in rows:
                print(f"{r['folder']:55s} {r['result']:28s} {r['detail'][:90]}", flush=True)
            out += rows
    out.sort(key=lambda r: (r['folder'], r['package']))
    with open(a.out, 'w', newline='') as f:
        w = csv.DictWriter(f, fieldnames=['folder', 'package', 'subprograms', 'result', 'detail'], lineterminator='\n')
        w.writeheader(); w.writerows(out)
    print('wrote', a.out)

if __name__ == '__main__':
    main()
