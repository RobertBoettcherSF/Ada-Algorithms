#!/usr/bin/env python3
"""Calibrate the shortcut-pattern flags of tools/vv/sweep_triage.py (docs/VV.md 3i).

Labelled folders:
  buggy  every folder of tools/vv/findings.csv (one label per folder);
  clean  folders with own tests (PROOFS.csv own_tests = yes) and no finding.
Each labelled folder is scanned with sweep_triage.scan (imported read-only)
as it was BEFORE it was checked, so a fix or an added own test does not
change its flags: buggy folders at the parent of the failing-test commit
(else the parent of the fix commit), clean folders at the parent of the
commit that first added their own_checks / own tests (else HEAD).

Per pattern (flag fires = count > 0): fire rate in buggy and clean folders,
precision, recall and the positive likelihood ratio LR+ = P(fire | buggy) /
P(fire | clean), with +0.5 smoothing. Calibrated weight = ln LR+ (negative
when a flag is commoner in clean folders; 0 when the flag never fires in
the labelled set, i.e. no evidence either way).

Bias: many findings were found BY hunting these patterns (caps, silent
no-ops, stubs), so their LR is inflated. Validation therefore uses the two
unbiased random samples (tools/vv/sample_30.txt, SPARK, seed 20261008;
tools/vv/sample_ada_30.txt, plain Ada, seed 20261009): weights are fitted
WITHOUT the sampled folders and then used to rank the sampled folders; the
ranks of their bug folders (and the AUC) are reported for the calibrated and
the uncalibrated (sweep_triage W) score.

Outputs: tools/vv/sweep_calibration.csv (one row per pattern + validation rows)
         tools/vv/sweep_rank_calibrated.csv (unchecked folders, calibrated order)
"""
import csv, math, os, re, subprocess, sys, tarfile, io, tempfile, shutil
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import sweep_triage as T

ROOT = T.ROOT
PAT = list(T.W)

def git(*a):
    return subprocess.run(['git', '-C', ROOT, *a], capture_output=True, text=True).stdout.strip()

def ok(c):
    return bool(c) and re.fullmatch(r'[0-9a-f]{6,40}', c) and \
        subprocess.run(['git', '-C', ROOT, 'cat-file', '-e', c + '^{commit}'], capture_output=True).returncode == 0

def snapshot(folder, commit, tmp):
    """Extract folder at commit into tmp; return the path (None if absent)."""
    data = subprocess.run(['git', '-C', ROOT, 'archive', commit, folder], capture_output=True).stdout
    if not data:
        return None
    tarfile.open(fileobj=io.BytesIO(data)).extractall(tmp, filter='data')
    p = os.path.join(tmp, folder)
    return p if os.path.isdir(p) else None

def scan_at(folder, commit, row, tmp):
    p = snapshot(folder, commit, tmp) if commit else None
    p = p or os.path.join(ROOT, folder)
    f, _, _ = T.scan(p, row)
    return f

def sample_folders():
    s = {}
    for name in ('sample_30_results.csv', 'sample_ada_30_results.csv'):
        for r in csv.DictReader(open(os.path.join(ROOT, 'tools/vv', name))):
            s[r['folder']] = r['outcome'].startswith('bug')
    return s

def stats(rows, flags):
    B = [r for r in rows if r['buggy']]; C = [r for r in rows if not r['buggy']]
    out = {}
    for k in flags:
        fb = sum(1 for r in B if r['f'][k] > 0); fc = sum(1 for r in C if r['f'][k] > 0)
        pb = (fb + 0.5) / (len(B) + 1); pc = (fc + 0.5) / (len(C) + 1)
        out[k] = dict(fires_buggy=fb, n_buggy=len(B), fires_clean=fc, n_clean=len(C),
                      precision=round(fb / (fb + fc), 3) if fb + fc else '', recall=round(fb / len(B), 3) if B else '',
                      lr_plus=round(pb / pc, 2) if fb + fc else '', weight=round(math.log(pb / pc), 3) if fb + fc else 0.0)
    return out

def score(f, w):
    return sum(w[k] for k in w if f[k] > 0)

def auc(rows, key):
    B = [key(r) for r in rows if r['buggy']]; C = [key(r) for r in rows if not r['buggy']]
    if not B or not C: return ''
    s = sum((b > c) + 0.5 * (b == c) for b in B for c in C)
    return round(s / (len(B) * len(C)), 3)

def main():
    proofs = {r['folder']: r for r in csv.DictReader(open(os.path.join(ROOT, 'PROOFS.csv')))}
    findings = {}
    for r in csv.DictReader(open(os.path.join(ROOT, 'tools/vv/findings.csv'))):
        findings.setdefault(r['folder'], r)   # first (earliest) finding per folder
    samples = sample_folders()
    tmp = tempfile.mkdtemp(prefix='sweep_cal_')
    rows = []
    try:
        for folder, row in proofs.items():
            buggy = folder in findings or samples.get(folder, False)
            if not buggy and row['own_tests'] != 'yes' and folder not in samples:
                continue
            if folder in findings:
                fr = findings[folder]
                c = fr['test_commit'] if ok(fr['test_commit']) else fr['fix_commit'] if ok(fr['fix_commit']) else ''
                commit = c + '^' if c else ''
            else:
                added = git('log', '--diff-filter=A', '--format=%H', '--', f'{folder}/own_checks.adb',
                            f'{folder}/tests/own_checks.adb', f'{folder}/tests/SOURCES.txt').split('\n')
                commit = added[-1] + '^' if added and added[-1] else ''
            f = scan_at(folder, commit, row, os.path.join(tmp, str(len(rows))))
            rows.append(dict(folder=folder, buggy=buggy, sample=folder in samples, f=f, commit=commit))
    finally:
        shutil.rmtree(tmp, ignore_errors=True)
    fit = [r for r in rows if not r['sample']]
    test = [r for r in rows if r['sample']]
    st_all = stats(rows, PAT); st_fit = stats(fit, PAT)
    wcal = {k: st_fit[k]['weight'] for k in PAT}
    wold = dict(T.W)
    out = []
    for k in PAT:
        out.append(dict(kind='pattern', name=k, **st_all[k], weight_fit_excl_samples=st_fit[k]['weight'],
                        triage_weight=wold[k]))
    # validation on the unbiased samples
    key_c = lambda r: score(r['f'], wcal)
    key_o = lambda r: sum(min(r['f'][k], 3) * wold[k] for k in PAT)
    for name, key in (('calibrated', key_c), ('uncalibrated', key_o)):
        ranked = sorted(test, key=lambda r: (-key(r), r['folder']))
        pos = {r['folder']: i + 1 for i, r in enumerate(ranked)}
        bugs = '; '.join(f"{r['folder'].split('/')[-1]}={pos[r['folder']]}" for r in ranked if r['buggy'])
        out.append(dict(kind='validation', name=name, n_buggy=sum(r['buggy'] for r in test), n_clean=sum(not r['buggy'] for r in test),
                        precision='', recall='', lr_plus='', weight=auc(test, key),
                        weight_fit_excl_samples=f'AUC on samples={auc(test, key)}; bug ranks among {len(test)}: {bugs}'))
    cols = ['kind', 'name', 'fires_buggy', 'n_buggy', 'fires_clean', 'n_clean', 'precision', 'recall', 'lr_plus', 'weight',
            'weight_fit_excl_samples', 'triage_weight']
    with open(os.path.join(ROOT, 'tools/vv/sweep_calibration.csv'), 'w', newline='') as fh:
        w = csv.DictWriter(fh, fieldnames=cols, extrasaction='ignore'); w.writeheader(); w.writerows(out)
    for x in out:
        print({k: x.get(k, '') for k in cols if x.get(k, '') != ''})
    # calibrated order of the unchecked folders (features from sweep_triage.csv;
    # non-pattern terms of sweep_triage kept unchanged, they are not calibrated)
    tri = list(csv.DictReader(open(os.path.join(ROOT, 'tools/vv/sweep_triage.csv'))))
    res = []
    for r in tri:
        f = {k: float(r[k] or 0) for k in PAT}
        old_pat = sum(min(f[k], 3) * wold[k] for k in PAT)
        rest = float(r['risk']) - old_pat
        cal = score(f, wcal) + rest / 3.0   # rest is on the triage scale (weights 2-6); ~ln-scale
        res.append(dict(folder=r['folder'], level=r['level'], family=r['family'], risk_calibrated=round(cal, 3),
                        triage_rank=r['rank'], triage_risk=r['risk'], **{k: r[k] for k in PAT}, do_nothing=r['do_nothing'],
                        input_var=r['input_var']))
    res.sort(key=lambda x: (x['family'] != '', -x['risk_calibrated'], x['folder']))
    for i, x in enumerate(res, 1):
        x['rank_calibrated'] = i
    cols2 = ['rank_calibrated', 'folder', 'level', 'family', 'risk_calibrated', 'triage_rank', 'triage_risk', *PAT, 'do_nothing', 'input_var']
    with open(os.path.join(ROOT, 'tools/vv/sweep_rank_calibrated.csv'), 'w', newline='') as fh:
        w = csv.DictWriter(fh, fieldnames=cols2); w.writeheader(); w.writerows(res)
    print('labelled folders:', len(rows), 'buggy', sum(r['buggy'] for r in rows), '; fit set', len(fit), '; sample set', len(test))
    print('calibrated weights:', wcal)

if __name__ == '__main__':
    main()
