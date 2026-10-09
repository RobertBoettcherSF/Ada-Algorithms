#!/usr/bin/env python3
"""Fail if a tracked file names an absolute path on the build box.

Handover evidence and docs must be reproducible from a fresh clone, so no tracked file
may name an absolute path under the box roots tmp, workspace or home (scratch dirs, other
worktrees, the box home directory).
Scope: every file from `git ls-files` (text files only).
Allowlist: tools/vv/check_paths_allow.csv (path,pattern,reason); every entry needs a written reason.
Usage: python3 tools/vv/check_paths.py [--handover-only] [--list]
"""
import csv, os, re, subprocess, sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
RX = re.compile(r'(?<![\w.~$-])/(?:tmp|workspace|home)(?=[/\s"\'`),;:]|$)')
HANDOVER = ['tools/vv/handover.csv', 'docs/HANDOVER.md']
ALLOW = 'tools/vv/check_paths_allow.csv'

def allow():
    p = os.path.join(ROOT, ALLOW)
    out = []
    if os.path.exists(p):
        for r in csv.DictReader(open(p, newline='')):
            if not (r.get('reason') or '').strip():
                print(f'FAIL {ALLOW}: entry {r["path"]} has no written reason'); sys.exit(1)
            out.append((r['path'], re.compile(r['pattern'])))
    return out

def main():
    handover_only = '--handover-only' in sys.argv
    files = HANDOVER if handover_only else subprocess.run(
        ['git', 'ls-files', '-z'], cwd=ROOT, capture_output=True, check=True).stdout.decode().split('\0')
    al = allow()
    bad = []
    for f in files:
        if not f or f.startswith('tools/vv/handover_evidence/'):
            continue  # verbatim evidence copies (logs, patches, claim snapshots) are kept as recorded
        p = os.path.join(ROOT, f)
        if not os.path.isfile(p):
            continue
        b = open(p, 'rb').read()
        if b'\0' in b[:8192]:
            continue
        for n, line in enumerate(b.decode('utf-8', 'replace').splitlines(), 1):
            if RX.search(line) and not any(f == ap and pr.search(line) for ap, pr in al):
                bad.append((f, n, line.strip()))
    for f, n, l in bad:
        print(f'{f}:{n}: {l[:160]}')
    files_bad = len({f for f, _, _ in bad})
    print(('FAIL' if bad else 'ok  ') + f' absolute box paths: {len(bad)} line(s) in {files_bad} tracked file(s)'
          + (' (handover only)' if handover_only else ''))
    return 1 if bad else 0

if __name__ == '__main__':
    sys.exit(main())
