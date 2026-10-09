#!/usr/bin/env python3
"""Write the score138 records for one folder (agent-S138).

Reads the private run files of tools/vv/score138.py (tune, held, held dummy;
held already through score138_prove.py) and tools/vv/score138_equivalent.csv
(survivors judged equivalent, one written reason each; only for mutants whose
test AND proof results are 'survived').  Appends/replaces the folder's rows in
  tools/vv/score138_halves.csv   one 'tuning' and one 'heldout' row; killed /
      survived / timeout are NON-EQUIVALENT counts (timeouts are survivors in the
      score); per-family k/n, raw k/n, equivalents, test / proof / uninit kills,
      dummy, exact Clopper-Pearson two-sided 95% lower bound (Beta(0.025; k, n-k+1)).
      Read by tools/proof_index.py and tools/vv/recount_strict.py (*_halves.csv).
  tools/vv/score138_sealed.csv   held mutants: family, operator, result, kill_kind
      (file / line / text hidden; survivors classified equivalent are listed
      with their text in score138_equivalent.csv).
usage: score138_record.py FOLDER --test-commit C [--note TEXT]
"""
import argparse, csv, json, math, os
VV = os.path.dirname(os.path.abspath(__file__))
PRIV = os.environ.get('AA_S138_PRIVATE', os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))), 's138_private'))   # same default as score138.py --out
FAMS = ('std', 'alt', 'ho', 'B', 'C')


def cp95_lower(k, n):
    if n <= 0 or k <= 0: return 0.0
    def sf(p):
        lp, lq = math.log(p), math.log1p(-p)
        return sum(math.exp(math.lgamma(n + 1) - math.lgamma(i + 1) - math.lgamma(n - i + 1) + i * lp + (n - i) * lq) for i in range(k, n + 1))
    lo, hi = 0.0, 1.0
    for _ in range(80):
        mid = (lo + hi) / 2
        lo, hi = (mid, hi) if sf(mid) < 0.025 else (lo, mid)
    return (lo + hi) / 2


def load(fid, half, dummy=False):
    p = os.path.join(PRIV, fid.replace('/', '_') + f'_{half}' + ('_dummy' if dummy else '') + '.json')
    return json.load(open(p)) if os.path.exists(p) else None


def tally(rec, eq):
    fam = {f: [0, 0] for f in FAMS}
    raw_k = raw_n = to = sb = nk_test = nk_proof = nk_uninit = 0
    k = s = 0
    for i, m in enumerate(rec['mutants']):
        r = m['result']
        if r == 'stillborn':
            sb += 1; continue
        raw_n += 1
        if r == 'killed':
            raw_k += 1
            kk = m.get('kill_kind') or ''
            nk_proof += kk == 'proof'; nk_uninit += kk == 'uninit'; nk_test += kk == ''
        if i in eq:
            continue
        fam[m['family']][1] += 1
        if r == 'killed':
            k += 1; fam[m['family']][0] += 1
        elif r == 'timeout':
            to += 1
        else:
            s += 1
    return dict(k=k, s=s, to=to, sb=sb, raw=f'{raw_k}/{raw_n}', eq=len(eq), fam=fam,
                kills=f'test {nk_test}, proof {nk_proof}, uninit {nk_uninit}')


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('folder'); ap.add_argument('--test-commit', required=True); ap.add_argument('--note', default='')
    a = ap.parse_args()
    fid = a.folder
    eqs = {'tune': set(), 'held': set()}
    ep = os.path.join(VV, 'score138_equivalent.csv')
    if os.path.exists(ep):
        for r in csv.DictReader(open(ep)):
            if r['folder'] == fid:
                eqs[r['half']].add(int(r['index']))
    fields = ['folder', 'half', 'family', 'split_seed', 'sample_seed', 'pool', 'drawn', 'topped_up', 'killed', 'survived',
              'timeout', 'stillborn', 'score', 'pct', 'enough_20', 'compiler', 'note', 'cp95_lower',
              'per_family', 'raw', 'equivalent', 'kills', 'dummy', 'n_ge_40', 'test_commit', 'proof_commit']
    hp = os.path.join(VV, 'score138_halves.csv')
    rows = [r for r in csv.DictReader(open(hp))] if os.path.exists(hp) else []
    rows = [r for r in rows if r['folder'] != fid]
    held = load(fid, 'held'); tune = load(fid, 'tune'); dummy = load(fid, 'held', True)
    for half, rec in (('tuning', tune), ('heldout', held)):
        if not rec:
            continue
        t = tally(rec, eqs['tune' if half == 'tuning' else 'held'])
        n = t['k'] + t['s'] + t['to']
        dk = sum(m['result'] == 'killed' for m in dummy['mutants']) if (dummy and half == 'heldout') else ''
        dn = sum(m['result'] != 'stillborn' for m in dummy['mutants']) if (dummy and half == 'heldout') else ''
        note = ('blind: split seed recorded (claims file + tools/vv/score138_seeds.csv) before any test change; held run once on '
                f'the final tests ({a.test_commit}); survivors opened only after the held run and proof pass, for classification; '
                if half == 'heldout' else 'tune half: survivors looked at and used to guide tests; information only; ') + \
               'timeouts count as survivors; equivalents excluded only with a written reason (score138_equivalent.csv). ' + a.note
        rows.append(dict(folder=fid, half=half, family='mixed std+alt+ho+B+C (round robin)', split_seed=rec['seed'],
                         sample_seed=rec['seed'], pool=sum(rec['pool'].values()), drawn=len(rec['mutants']), topped_up=0,
                         killed=t['k'], survived=t['s'], timeout=t['to'], stillborn=t['sb'],
                         score=f"{t['k']}/{n}", pct=(f"{100.0 * t['k'] / n:.1f}%" if n else ''),
                         enough_20=('yes' if n >= 20 else 'no'), compiler=rec['compiler'], note=note.strip(),
                         cp95_lower=f"{cp95_lower(t['k'], n):.3f}",
                         per_family=' '.join(f"{f} {kn[0]}/{kn[1]}" for f, kn in t['fam'].items()),
                         raw=t['raw'], equivalent=t['eq'], kills=t['kills'],
                         dummy=(f'{dk}/{dn}' if dn != '' else ''), n_ge_40=('yes' if n >= 40 else 'no'),
                         test_commit=a.test_commit, proof_commit=rec.get('proof_commit', '')))
        print(half, rows[-1]['score'], rows[-1]['pct'], 'cp95', rows[-1]['cp95_lower'], rows[-1]['per_family'],
              'raw', t['raw'], 'eq', t['eq'], t['kills'], 'dummy', rows[-1]['dummy'])
    with open(hp, 'w', newline='') as f:
        w = csv.DictWriter(f, fieldnames=fields, lineterminator='\n'); w.writeheader(); w.writerows(rows)
    sp = os.path.join(VV, 'score138_sealed.csv')
    srows = [r for r in csv.DictReader(open(sp))] if os.path.exists(sp) else []
    srows = [r for r in srows if r['folder'] != fid]
    for i, m in enumerate(held['mutants']):
        srows.append(dict(folder=fid, seed=held['seed'], index=i, family=m['family'], op=m['op'].split(' ->')[0] if m['family'] != 'ho' else 'std pair',
                          line='hidden', result=('equivalent' if i in eqs['held'] else m['result']), kill_kind=m.get('kill_kind') or '',
                          proof=(m.get('prove') or [''])[0]))
    with open(sp, 'w', newline='') as f:
        w = csv.DictWriter(f, fieldnames=['folder', 'seed', 'index', 'family', 'op', 'line', 'result', 'kill_kind', 'proof'], lineterminator='\n')
        w.writeheader(); w.writerows(srows)


if __name__ == '__main__':
    main()
