#!/usr/bin/env python3
"""Proof-escape and warning-suppression scan (training_ready rules 3 and 4, docs/VV.md).

Writes, over the tracked files of every folder (git ls-files, so build output is ignored):
  tools/vv/proof_escapes.csv        folder,file,line,kind,text,justification,justified
      every pragma Assume and pragma Annotate (GNATprove, ...). An Annotate counts as justified
      when its reason string (4th argument) is non-empty; Hide_Info is a proof-abstraction
      directive (no check is suppressed) and counts as justified when a comment within the
      3 lines above or on the same line says why. An Assume needs such a comment.
  tools/vv/warnings_suppressed.csv  folder,file,line,text
      every pragma Warnings (Off ...) in Ada sources, -gnatws / -gnatwA / Warnings (Off in gpr,
      Makefile and .adc files, and every pragma Unreferenced / Unused that is not allowed (below).
  tools/vv/unreferenced.csv         every pragma Unreferenced / Unused entity: kind (parameter / local),
      interface_required (overriding, or the subprogram is passed as 'Access or a generic actual),
      the written reason if any, allowed (interface-required parameter, or a written reason).
  tools/vv/unused_local_review.csv  unreferenced locals in non-test code initialised from a call:
      a computed value nobody uses is a shortcut sign; each is a review item.
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
# Reviewed verdicts (tools/vv/proof_escapes_review.csv: folder,file,line,justified,reason,decided): a written
# reason string is not enough when a review found that it states a prover limit, not that the check cannot
# fail (Robert, 2026-10-09 09:57, Lemke-Howson). The review's verdict and reason replace the scanner's.
_rev = os.path.join(ROOT, 'tools', 'vv', 'proof_escapes_review.csv')
if os.path.exists(_rev):
    _r = {(x['file'], int(x['line'])): x for x in csv.DictReader(open(_rev, newline=''))}
    for e in esc:
        x = _r.get((e['file'], e['line']))
        if x:
            e['justified'] = x['justified']
            e['justification'] = (e['justification'] + ' [review ' + x['decided'] + ': ' + x['reason'] + ']')[:400]
# pragma Unreferenced / Unused (room guard 2026-10-08 19:18): allowed without comment on a parameter that an
# interface requires (overriding subprogram, or one passed as 'Access / generic actual); otherwise only with a
# written reason (comment within 3 lines above or on the same line). Not allowed -> warnings_suppressed.
UNREF = re.compile(r'pragma\s+(Unreferenced|Unused)\s*\(([^)]*)\)', re.I)
HEAD = re.compile(r'^\s*(overriding\s+)?(procedure|function)\s+("?[\w.]+"?)', re.I)
unref, review = [], []
_folder_text = {}
def folder_text(fid):
    if fid not in _folder_text:
        _folder_text[fid] = '\n'.join(open(os.path.join(ROOT, g), errors='replace').read()
                                      for g in files if g.startswith(fid + '/') and g.endswith(('.ads', '.adb')))
    return _folder_text[fid]
def classify(lines, i, name):
    """(kind, required, decl_line_text) for entity `name` referenced by the pragma at line i."""
    decl = re.compile(r'(^|[\s(;,])' + re.escape(name) + r'\s*(,\s*\w+\s*)*:(?!=)', re.I)
    for j in range(i - 1, max(-1, i - 400), -1):
        code = lines[j].split('--')[0]
        if decl.search(code):
            # walk back to the nearest subprogram header; parameter if the paren depth is open at the declaration
            depth = 0
            for k in range(j, max(-1, j - 60), -1):
                c = lines[k].split('--')[0]
                seg = c[:c.find(name)] if k == j and name in c else c
                depth += seg.count('(') - seg.count(')')
                h = HEAD.match(c)
                if h:
                    if depth > 0:
                        sub = h.group(3).strip('"')
                        txt = folder_text(fid)
                        req = bool(h.group(1)) or bool(re.search(r'\b' + re.escape(sub) + r"'(Unrestricted_)?Access", txt, re.I)) \
                              or bool(re.search(r'=>\s*' + re.escape(sub) + r'\b', txt)) \
                              or bool(re.search(r'\bnew\s+[\w.]+\s*\([^;]*\b' + re.escape(sub) + r'\b', txt, re.I))
                        return 'parameter', req, code.strip()
                    return 'local', False, code.strip()
                if k != j and re.search(r'^\s*(begin|end\b)', c, re.I):
                    return 'local', False, code.strip()
            return 'local', False, code.strip()
    return 'unknown', False, ''
for f in sorted(files):
    fid = folder_of(f)
    if not fid or not f.endswith(('.ads', '.adb')): continue
    lines = open(os.path.join(ROOT, f), errors='replace').read().split('\n')
    for i, l in enumerate(lines):
        code = l.split('--')[0]
        m = UNREF.search(code)
        if not m: continue
        near = [x.strip() for x in lines[max(0, i - 3):i] if x.strip().startswith('--')] + ([l[l.index('--'):].strip()] if '--' in l else [])
        reason = ' '.join(near)[:160]
        is_test = os.path.basename(f).startswith(('test', 'own_checks')) or '/tests/' in f
        for name in [n.strip() for n in m.group(2).split(',') if n.strip()]:
            kind, req, dtext = classify(lines, i, name)
            allowed = 'yes' if (kind == 'parameter' and req) or reason else 'no'
            unref.append(dict(folder=fid, file=f, line=i + 1, pragma=m.group(1), entity=name, kind=kind,
                              interface_required='yes' if req else '', reason=reason, allowed=allowed))
            if kind == 'local' and not is_test and ':=' in dtext and re.search(r':=\s*[\w.]+\s*\(', dtext):
                review.append(dict(folder=fid, file=f, line=i + 1, entity=name, declaration=dtext[:140]))
            if allowed == 'no':
                sup.append(dict(folder=fid, file=f, line=i + 1, text=f'pragma {m.group(1)} ({name}) on a {kind} without a written reason'))
sup.sort(key=lambda r: (r['folder'], r['file'], int(r['line'])))
for name, rows, cols in (('proof_escapes.csv', esc, ['folder', 'file', 'line', 'kind', 'text', 'justification', 'justified']),
                         ('warnings_suppressed.csv', sup, ['folder', 'file', 'line', 'text']),
                         ('unreferenced.csv', unref, ['folder', 'file', 'line', 'pragma', 'entity', 'kind', 'interface_required', 'reason', 'allowed']),
                         ('unused_local_review.csv', review, ['folder', 'file', 'line', 'entity', 'declaration'])):
    with open(os.path.join(ROOT, 'tools', 'vv', name), 'w', newline='') as fh:
        w = csv.DictWriter(fh, fieldnames=cols, lineterminator='\n'); w.writeheader(); w.writerows(rows)
    print(name, len(rows), 'rows,', len({r['folder'] for r in rows}), 'folders')
