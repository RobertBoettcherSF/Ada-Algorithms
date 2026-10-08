#!/usr/bin/env python3
"""Reference encoders for misc/Ada/Phonetic-Algorithms own checks (docs/VV.md 3i).

Own code (MIT), written from the published rule lists, not from the Ada body:
* Soundex and MRA codex: cross-checked against jellyfish 1.1.0 (MIT) when it
  is importable (`--cross`), otherwise our own reference only;
* NYSIIS (strict, 6 letters, Commons-Codec-style rule order) as a sequence of
  whole-string rewrites;
* original Metaphone (4 symbols) as a left-to-right transducer over a
  context window (look-behind / look-ahead strings), with the rule order
  documented in the package spec.
Writes tests/vectors.txt: word|soundex|nysiis|metaphone|mra ('!' = Invalid_Argument).
usage: sweep_phonetic_ref.py OUT [--n 4000] [--seed 20261008] [--cross]
"""
import random, re, sys, argparse

V = set('AEIOU')

def letters(w):
    return ''.join(c for c in w.upper() if 'A' <= c <= 'Z')

def soundex(w):
    s = letters(w)
    if not s: return None
    code = {**{c: '1' for c in 'BFPV'}, **{c: '2' for c in 'CGJKQSXZ'}, **{c: '3' for c in 'DT'},
            'L': '4', **{c: '5' for c in 'MN'}, 'R': '6'}
    # 1. code every letter (vowels / Y -> '.', H / W -> '' : transparent)
    t = ''.join('' if c in 'HW' else code.get(c, '.') for c in s)
    first_code = '' if s[0] in 'HW' else t[0]
    rest = t[1:] if s[0] not in 'HW' else t
    # 2. collapse runs of equal codes (H/W already removed, vowels separate)
    rest = re.sub(r'(\d)\1+', r'\1', first_code + rest)[len(first_code):] if first_code else re.sub(r'(\d)\1+', r'\1', rest)
    if first_code.isdigit() and rest.startswith(first_code):
        rest = rest[1:]
    digits = rest.replace('.', '')
    return (s[0] + digits + '000')[:4]

def mra(w):
    s = letters(w)
    if not s: return None
    t = s[0] + re.sub('[AEIOU]', '', s[1:])
    t = re.sub(r'(.)\1+', r'\1', t)
    return t if len(t) <= 6 else t[:3] + t[-3:]

def nysiis(w):
    s = letters(w)
    if not s: return None
    for a, b in (('MAC', 'MCC'), ('KN', 'NN'), ('K', 'C'), ('PH', 'FF'), ('PF', 'FF'), ('SCH', 'SSS')):
        if s.startswith(a):
            s = b + s[len(a):]; break
    if len(s) >= 2:
        if s[-2:] in ('EE', 'IE'): s = s[:-2] + 'Y'
        elif s[-2:] in ('DT', 'RT', 'RD', 'NT', 'ND'): s = s[:-2] + 'D'
    c = list(s); key = c[0]
    for i in range(1, len(c)):
        prev = c[i - 1]; cur = c[i]
        nx = c[i + 1] if i + 1 < len(c) else ' '
        ax = c[i + 2] if i + 2 < len(c) else ' '
        if cur == 'E' and nx == 'V': rep = 'AF'
        elif cur in V: rep = 'A'
        elif cur in 'QZM': rep = {'Q': 'G', 'Z': 'S', 'M': 'N'}[cur]
        elif cur == 'K': rep = 'NN' if nx == 'N' else 'C'
        elif cur == 'S' and nx == 'C' and ax == 'H': rep = 'SSS'
        elif cur == 'P' and nx == 'H': rep = 'FF'
        elif cur == 'H' and (prev not in V or nx not in V): rep = prev
        elif cur == 'W' and prev in V: rep = prev
        else: rep = cur
        rep = rep[:len(c) - i]
        c[i:i + len(rep)] = list(rep)
        if c[i] != c[i - 1]: key += c[i]
    if len(key) > 1 and key.endswith('S'): key = key[:-1]
    if len(key) > 2 and key.endswith('AY'): key = key[:-2] + 'Y'
    if len(key) > 1 and key.endswith('A'): key = key[:-1]
    return key[:6]

FRONT = set('EIY'); VARSON = set('CSPTG')

def metaphone(w):
    s = letters(w)
    if not s: return None
    if len(s) == 1: return s
    if s[:2] in ('KN', 'GN', 'PN', 'AE', 'WR'): s = s[1:]
    elif s[:2] == 'WH': s = 'W' + s[2:]
    elif s[0] == 'X': s = 'S' + s[1:]
    out = []; n = 0; L = len(s)
    while len(out) < 4 and n < L:
        c = s[n]; behind = s[:n]; ahead = s[n + 1:]; last = n == L - 1
        def put(x): out.extend(x)
        if c != 'C' and behind.endswith(c):
            n += 1; continue
        if c in V:
            if n == 0: put(c)
        elif c == 'B':
            if not (behind.endswith('M') and last): put('B')
        elif c == 'C':
            if behind.endswith('S') and ahead[:1] in FRONT and ahead: pass
            elif behind.endswith('S') and ahead.startswith('H'): put('K')
            elif ahead.startswith('IA') or ahead.startswith('H'): put('X')
            elif ahead[:1] and ahead[0] in FRONT: put('S')
            else: put('K')
        elif c == 'D':
            if len(ahead) >= 2 and ahead[0] == 'G' and ahead[1] in FRONT: put('J'); n += 2
            else: put('T')
        elif c == 'G':
            if ahead == 'H': pass                                  # GH at the end
            elif ahead.startswith('H') and len(ahead) >= 2 and ahead[1] not in V: pass
            elif n > 0 and ahead.startswith('N'): pass             # GN / GNED (GN is a prefix of GNED)
            elif ahead[:1] and ahead[0] in FRONT and not behind.endswith('G'): put('J')
            else: put('K')
        elif c == 'H':
            if last or (behind and behind[-1] in VARSON): pass
            elif ahead[:1] and ahead[0] in V: put('H')
        elif c in 'FJLMNR': put(c)
        elif c == 'K':
            if not behind.endswith('C'): put('K')
        elif c == 'P': put('F' if ahead.startswith('H') else 'P')
        elif c == 'Q': put('K')
        elif c == 'S': put('X' if ahead.startswith('H') or ahead.startswith('IO') or ahead.startswith('IA') else 'S')
        elif c == 'T':
            if ahead.startswith('IA') or ahead.startswith('IO'): put('X')
            elif ahead.startswith('CH'): pass
            elif ahead.startswith('H'): put('0')
            else: put('T')
        elif c == 'V': put('F')
        elif c in 'WY':
            if ahead[:1] and ahead[0] in V: put(c)
        elif c == 'X': put('KS')
        elif c == 'Z': put('S')
        n += 1
    code = ''.join(out)[:4]
    return code or None

def main():
    ap = argparse.ArgumentParser(); ap.add_argument('out'); ap.add_argument('--n', type=int, default=4000)
    ap.add_argument('--seed', type=int, default=20261008); ap.add_argument('--cross', action='store_true')
    a = ap.parse_args(); rng = random.Random(a.seed)
    names = ['Robert', 'Rupert', 'Rubin', 'Ashcraft', 'Ashcroft', 'Tymczak', 'Pfister', 'Honeyman', 'Lee', 'Gutierrez',
             'Jackson', 'Washington', 'Knight', 'Thompson', 'Schmidt', 'MacIntosh', 'Byrne', 'Smith', 'Smyth', 'Ash',
             'Why', 'Thumb', 'Christopher', 'Xavier', 'Wright', 'Whalen', 'Aegis', 'Gnome', 'Pneumonia', 'Dodge',
             'Edgar', 'Knuth', 'Phillips', 'Schoenberg', 'Laugh', 'Night', 'Signed', 'Science', 'Scythe', 'Mitchell',
             "O'Brien", 'de la Cruz', 'Ng', 'A', 'b', 'Mc-Kay', 'Brown', 'Bevan', 'Kennedy', 'Ghost', 'Thomas']
    alpha = 'ABCDEFGHIKLMNOPRSTUWXYZ' * 2 + 'AEIOUHGCSTKNW' * 2 + 'JQV' + "aeh -'"
    words = list(names)
    while len(words) < a.n:
        words.append(''.join(rng.choice(alpha) for _ in range(rng.randint(1, 10))))
    # all 1..3-letter strings over a context-heavy alphabet
    small = 'ACEGHIKNSTWY'
    for x in small:
        words.append(x)
        for y in small:
            words.append(x + y)
            for z in small:
                words.append(x + y + z)
    if a.cross:
        import jellyfish
        bad = 0
        for w in words:
            if letters(w):
                if jellyfish.soundex(letters(w)) != soundex(w) or jellyfish.match_rating_codex(letters(w)) != mra(w):
                    bad += 1; print('cross-check differs:', w, soundex(w), jellyfish.soundex(letters(w)), mra(w), jellyfish.match_rating_codex(letters(w)))
        print('cross-checked', len(words), 'words against jellyfish; differences:', bad)
    with open(a.out, 'w') as f:
        for w in words:
            r = [soundex(w), nysiis(w), metaphone(w), mra(w)]
            f.write(w + '|' + '|'.join('!' if x is None else x for x in r) + '\n')

if __name__ == '__main__':
    main()
