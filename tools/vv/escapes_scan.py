#!/usr/bin/env python3
"""Proof-escape and warning-suppression scan (training_ready rules 3 and 4, docs/VV.md).

Writes, over the tracked files of every folder (git ls-files, so build output is ignored):
  tools/vv/proof_escapes.csv        folder,file,line,kind,text,justification,justified
      every pragma Assume and pragma Annotate (GNATprove, ...). An Annotate counts as justified
      when its reason string (4th argument) is non-empty; Hide_Info is a proof-abstraction
      directive (no check is suppressed) and counts as justified when a comment within the
      3 lines above or on the same line says why. An Assume needs such a comment.
  tools/vv/warnings_suppressed.csv  folder,file,line,text
      every pragma Warnings (Off ...) in Ada sources, and -gnatws / -gnatwA / Warnings (Off
      in gpr, Makefile and .adc files.
Deterministic; rerunning on the same tree gives byte-identical files.
"""
import csv, os, re, subprocess
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
files = subprocess.run(['git', 'ls-files'], cwd=ROOT, capture_output=True, text=True).stdout.split('\n')
def folder_of(f):
    p = f.split('/')
    return '/'.join(p[:3]) if len(p) > 3 and p[1] in ('Ada',) or (len(p) > 3 and p[1].startswith('SPARK')) else None
ESC = re.compile(r'pragma\s+(Assume|Annotate\s*\(\s*GNATprove)', re.I)
WARN_ADA = re.compile(r'pragma\s+Warnings\s*\(\s*Off', re.I)
WARN_BUILD = re.compile(r'-gnatw[a-zA-Z.]*[sA]\b|[Ww]arnings\s*\(\s*[Oo]ff')
esc, sup = [], []
for f in sorted(files):
    fid = folder_of(f)
    if not fid: continue
    path = os.path.join(ROOT, f)
    base = os.path.basename(f)
    if f.endswith(('.ads', '.adb')):
        lines = open(path, errors='replace').read().split('\n')
        for i, l in enumerate(lines):
            code = l.split('--')[0]
            if WARN_ADA.search(code):
                sup.append(dict(folder=fid, file=f, line=i + 1, text=l.strip()[:120]))
            m = ESC.search(code)
            if not m: continue
            stmt = ' '.join(x.strip() for x in lines[i:i + 4])
            stmt = stmt[:stmt.find(';') + 1] if ';' in stmt else stmt
            near = [x.strip() for x in lines[max(0, i - 3):i] if x.strip().startswith('--')] + \
                   ([l[l.index('--'):].strip()] if '--' in l else [])
            if m.group(1).lower() == 'assume':
                kind, just = 'Assume', ' '.join(near)
            else:
                args = re.findall(r'"([^"]*)"', stmt)
                kind = 'Annotate ' + (re.search(r'GNATprove\s*,\s*(\w+)', stmt, re.I) or [None, '?'])[1]
                if kind.endswith(('Intentional', 'False_Positive')):
                    just = args[1] if len(args) > 1 else ''
                else:
                    just = ' '.join(near)
            esc.append(dict(folder=fid, file=f, line=i + 1, kind=kind, text=stmt[:160], justification=just[:200],
                            justified='yes' if just.strip() else 'no'))
    elif base.endswith(('.gpr', '.adc')) or base == 'Makefile':
        for i, l in enumerate(open(path, errors='replace').read().split('\n')):
            if WARN_BUILD.search(l.split('#')[0].split('--')[0]):
                sup.append(dict(folder=fid, file=f, line=i + 1, text=l.strip()[:120]))
for name, rows, cols in (('proof_escapes.csv', esc, ['folder', 'file', 'line', 'kind', 'text', 'justification', 'justified']),
                         ('warnings_suppressed.csv', sup, ['folder', 'file', 'line', 'text'])):
    with open(os.path.join(ROOT, 'tools', 'vv', name), 'w', newline='') as fh:
        w = csv.DictWriter(fh, fieldnames=cols, lineterminator='\n'); w.writeheader(); w.writerows(rows)
    print(name, len(rows), 'rows,', len({r['folder'] for r in rows}), 'folders')
