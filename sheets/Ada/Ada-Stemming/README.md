# Stemming — Ada 2023

Educational, self-contained Ada 2023 package for
[Wikipedia: Stemming](https://en.wikipedia.org/wiki/Stemming): reducing
inflected (or sometimes derived) words to a **word stem**, base, or root form.
The stem need not be a real dictionary word; related forms are **conflated** to
the same stem for information retrieval (query expansion / indexing).

Primary algorithm: **Martin F. Porter**'s English suffix-stripping stemmer
(*An Algorithm for Suffix Stripping*, *Program* 14(3), 1980, pp. 130–137) —
steps 1a–5b with measure $m$, consonant/vowel tests, and the classic rule set.
Secondary helper: a tiny length-guarded **simple suffix stripper** for comparison.

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Primary** | Porter 1980 (steps 1a–5b) | Public-domain algorithm description |
| **Measure** | $m$ in $[C](VC)^{m}[V]$ | Guards short stems |
| **Secondary** | `Simple_Stem` / `Suffix_Strip` | `-ing/-ed/-ly/-es/-s`, keep ≥3 |
| **API** | `Stem_Word` ≡ `Porter_Stem` | Lowercases first |
| **I/O** | `String` | Max length 256 |
| **Vs lemma** | No POS / lexicon | Stem ≠ lemma |

## Features

| Area | Subprograms / types | Role |
| --- | --- | --- |
| Normalize | `To_Lower` | Case folding |
| Letters | `Is_Vowel`, `Is_Consonant_At`, `Contains_Vowel` | Porter definitions |
| Measure | `Measure_M`, `Ends_Double_Consonant`, `Ends_CVC` | $m$, `*d`, `*o` |
| Porter | `Porter_Stem`, `Stem_Word` | Full English stemmer |
| Simple | `Simple_Stem`, `Suffix_Strip` | Tiny comparison stripper |

Named exception: `Invalid_Argument` (oversize input).
`SPARK_Mode => Off`; helpers carry `Global => null` where meaningful.

## Stemming vs lemmatization

**Stemming** chops suffixes by rules (or tables) and may produce non-words
(`argue` → `argu`). **Lemmatization** maps to a dictionary **lemma** using
part-of-speech and a lexicon (`better` → `good`). Stemming is cheaper and
common in IR conflation; lemmatization is linguistically cleaner when a lexicon
is available.

## History (Lovins → Porter → beyond)

- **Julie Beth Lovins** (1968) published the first major stemming algorithm —
  influential longest-match suffix stripping with recoding.
- **Martin Porter** (1980) published the de facto English standard: small,
  fast, rule-driven, measure-gated. Many early ports had subtle bugs; Porter
  later released a reference implementation and **Snowball** / Porter2
  (improved English and other languages) — **not** implemented in this package.
- **Paice–Husk** and commercial/lexical stemmers are further alternatives
  (see Wikipedia).

Search engines treat same-stem tokens as related (**conflation**). Classic
Porter overstemming example: `universal` / `university` / `universe` →
`univers`. Understemming example: Latinate `alumnus` / `alumni` / `alumna`
do not all meet.

## Porter measure and rules

A **consonant** is any letter other than A,E,I,O,U, and other than Y preceded
by a consonant (so Y is contextual). Any word part has form

$$
[C](VC)^{m}[V]
$$

where $C$ / $V$ are nonempty consonant / vowel runs. The integer $m$ is the
**measure** (`Measure_M`). Examples: `tree` → $m=0$, `trouble` → $m=1$,
`troubles` → $m=2$.

Rules look like `(condition) S1 → S2` (longest matching $S1$ wins). Conditions
include $m>0$, $m>1$, `*v*` (stem contains a vowel), `*d` (double consonant),
`*o` (ends cvc with final consonant not W/X/Y).

| Step | Role | Examples |
| --- | --- | --- |
| 1a | Plurals | `caresses`→`caress`, `cats`→`cat` |
| 1b | Past / -ing (+ follow-up) | `motoring`→`motor`, `hopping`→`hop` |
| 1c | Y→I if vowel in stem | `happy`→`happi`, `sky`→`sky` |
| 2–3 | Derivational map | `relational`→…→`relat`, `hopefulness`→`hope` |
| 4 | Strip with $m>1$ | `adoption`→`adopt`, `revival`→`reviv` |
| 5a/b | Final `-e` / double `-l` | `cease`→`ceas`, `controll`→`control` |

Wikipedia examples: `fishing`/`fished` → `fish`; `argue`/`argued`/`argues`/
`arguing`/`argus` → `argu`. Classic Porter does **not** map `fisher`→`fish`
(the `-er` rule needs $m>1$ on the stem). Stems need not be words.

## Simple suffix stripper

`Simple_Stem` / `Suffix_Strip` only tries `-ing`, `-ed`, `-ly`, `-es`, `-s`
(longest first) and keeps at least three characters — useful to contrast with
Porter in tests/README, not a production IR stemmer.

## Usage

```ada
with Stemming; use Stemming;

procedure Demo is
begin
   --  Primary (Porter 1980)
   pragma Assert (Porter_Stem ("arguing") = "argu");
   pragma Assert (Stem_Word ("CONNECTIONS") = "connect");
   pragma Assert (Measure_M ("trouble") = 1);

   --  Tiny comparison helper
   pragma Assert (Simple_Stem ("fishing") = "fish");
end Demo;
```

## Build / test

```bash
make clean && make
make test
```

Uses `gnatmake -gnatwa -gnat2022 -Pstemming.gpr`. Main program is `tests.adb`
(no `main.adb`). Expect **Fail_Count = 0** and well over 100 `PASS` lines
(classic Porter pairs, measure checks, idempotence, simple stripper, capacity).

## Layout

| File | Role |
| --- | --- |
| `stemming.ads` | Package spec |
| `stemming.adb` | Package body (Porter + simple) |
| `stemming.gpr` | GNAT project (main = `tests.adb`) |
| `Makefile` | `all` / `test` / `clean` |
| `tests.adb` | Custom Check suite (`Fail_Count`, no Ada.Assertions in checks) |
| `README.md` | This document |
| `.gitignore` | `obj/`, `bin/` |

## References

- Porter, M. F. *An Algorithm for Suffix Stripping*. Program 14(3) (1980),
  130–137. Algorithm description treated as public-domain for reimplementation;
  see also [tartarus.org/martin/PorterStemmer](https://tartarus.org/martin/PorterStemmer/).
- Lovins, J. B. *Development of a Stemming Algorithm*. Mechanical Translation
  and Computational Linguistics 11 (1968), 22–31.
- Wikipedia: [Stemming](https://en.wikipedia.org/wiki/Stemming).
- Snowball / Porter2 (improved English) — related successor, not this package.

## License

Educational reference implementation for the RobertBoettcherSF Ada algorithm
series. Use and adapt freely for learning and research. Porter (1980) rule
description is used under its well-known public-domain status for the
algorithm itself.
