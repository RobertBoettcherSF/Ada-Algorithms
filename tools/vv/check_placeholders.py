#!/usr/bin/env python3
"""Placeholder warning lines (tools/vv/placeholders.csv).

A folder that is a placeholder or misnamed (an open handover row of category placeholder /
misplaced_algorithm or H102-H109, a 'hidden stub' verdict in tools/vv/hidden_stub.csv, or stub = yes in
PROOFS.csv) must have a row in tools/vv/placeholders.csv. For an open row the README (first 5 lines) and
every spec (.ads, or the main .adb when there is none; first 5 lines) carry the line
    PLACEHOLDER: <what>; see <ref>
(as an Ada comment `--  PLACEHOLDER: ...` in the spec). Any other placeholder comment in code
(`-- placeholder` anywhere in a .ads / .adb line, any case, also indented) needs the folder to be an open
row, or the file to be listed with a reason in tools/vv/placeholder_comment_ok.csv. A closed row, or a folder without a row, must not
carry the line anywhere in README / .ads / .adb, and a row may only be closed when its handover row
(if any) is closed. Removing the line is part of the commit that fixes the folder.
  python3 tools/vv/check_placeholders.py [--root REPO]     (exit 0 = consistent)
"""
import argparse, csv, os, re, sys
ap = argparse.ArgumentParser()
ap.add_argument('--root', default=os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
a = ap.parse_args()
R = a.root
PREFIX = 'PLACEHOLDER: '
CODE_MARK = re.compile(r'--\s*placeholder\b', re.I)   # a placeholder comment anywhere in code
MARK = re.compile(r'^(--  )?' + PREFIX, re.M)   # the warning line itself (start of line)
TESTISH = re.compile(r'^(tests?|own_checks?|test_\w+|tests_\w+|main|demo\w*)\.ad[sb]$', re.I)

def rows(p):
    p = os.path.join(R, p)
    return list(csv.DictReader(open(p, newline=''))) if os.path.exists(p) else []

def line_for(r):
    return f"{PREFIX}{r['what']}; see {r['ref']}"

def specs(folder):
    d = os.path.join(R, folder)
    fs = sorted(f for f in os.listdir(d) if f.endswith('.ads') and not TESTISH.match(f))
    if not fs:
        fs = sorted(f for f in os.listdir(d) if f.endswith('.adb') and not TESTISH.match(f))[:1]
    return fs

def head_has(path, text, n=5):
    try:
        return any(text in l for l in open(path, errors='replace').read().split('\n')[:n])
    except FileNotFoundError:
        return False

# folders the sources flag as placeholders / misnamed
flag = {}
handover = {}
for h in rows('tools/vv/handover.csv'):
    num = int(h['id'][1:]) if h['id'][1:].isdigit() else 0
    if h['category'] in ('placeholder', 'misplaced_algorithm') or 102 <= num <= 109:
        handover.setdefault(h['folder'], []).append(h)
        if h['status'].startswith('open'):
            flag.setdefault(h['folder'], []).append(h['id'])
for h in rows('tools/vv/hidden_stub.csv'):
    if h['verdict'].startswith('hidden stub'):
        flag.setdefault(h['folder'], []).append('hidden_stub.csv')
for p in rows('PROOFS.csv'):
    if p.get('stub') == 'yes':
        flag.setdefault(p['folder'], []).append('PROOFS stub')

comment_ok = {(r['folder'], r['file']) for r in rows('tools/vv/placeholder_comment_ok.csv')}
listed = {r['folder']: r for r in rows('tools/vv/placeholders.csv')}
bad = []
for f, why in sorted(flag.items()):
    if f not in listed:
        bad.append(f'unlisted placeholder: {f} (flagged by {", ".join(why)}) has no row in tools/vv/placeholders.csv')
for f, r in sorted(listed.items()):
    d = os.path.join(R, f)
    if not os.path.isdir(d):
        bad.append(f'missing folder: {f}'); continue
    if r['status'] == 'open':
        if not r['what'] or not r['ref']:
            bad.append(f'{f}: open row needs what and ref')
        if not head_has(os.path.join(d, 'README.md'), line_for(r)):
            bad.append(f'{f}: README.md lacks "{line_for(r)}" in its first 5 lines')
        for s in specs(f):
            if not head_has(os.path.join(d, s), '--  ' + line_for(r)):
                bad.append(f'{f}: {s} lacks "--  {line_for(r)}" in its first 5 lines')
    else:
        for h in handover.get(f, []):
            if h['status'].startswith('open'):
                bad.append(f'{f}: row closed but handover {h["id"]} is still open')
# no stray lines: closed / unlisted folders must not carry the prefix
for dirpath, dirs, files in os.walk(R):
    dirs[:] = [x for x in dirs if x not in ('.git', 'obj', 'bin', 'gnatprove', 'alire', 'tools', 'docs')]
    rel = os.path.relpath(dirpath, R)
    for fn in files:
        if fn == 'README.md' and rel == '.':
            continue
        if fn == 'README.md' or fn.endswith(('.ads', '.adb')):
            try:
                txt = open(os.path.join(dirpath, fn), errors='replace').read()
            except OSError:
                continue
            r = listed.get(rel)
            if fn.endswith(('.ads', '.adb')) and (r is None or r['status'] != 'open') \
                    and (rel, fn) not in comment_ok:
                for k, l in enumerate(txt.split('\n'), 1):
                    if CODE_MARK.search(l) and not MARK.search(l):
                        bad.append(f'{rel}/{fn}:{k}: placeholder comment in code, but the folder is not an open row in '
                                   f'tools/vv/placeholders.csv (nor listed in tools/vv/placeholder_comment_ok.csv)')
            if MARK.search(txt):
                r = listed.get(rel)
                if r is None or r['status'] != 'open':
                    bad.append(f'{rel}/{fn}: carries "{PREFIX}" but the folder is not an open row in tools/vv/placeholders.csv')
n_open = sum(1 for r in listed.values() if r['status'] == 'open')
for b in bad:
    print('FAIL', b)
print(('ok  ' if not bad else 'FAIL') + f' placeholder lines: {n_open} open row(s), {len(listed) - n_open} closed, {len(bad)} problem(s)')
sys.exit(1 if bad else 0)
