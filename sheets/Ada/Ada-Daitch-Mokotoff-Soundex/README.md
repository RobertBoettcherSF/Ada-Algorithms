# Daitch–Mokotoff Soundex in Ada 2023

## Project Overview

**Daitch–Mokotoff Soundex** (D–M Soundex) is a phonetic algorithm invented in
1985 by Jewish genealogists Gary Mokotoff and Randy Daitch. It refines Russell
and American Soundex for greater accuracy on Slavic and Yiddish surnames with
similar pronunciation but different spelling. Codes are **six digits** (not
four characters), the **initial** sound is coded, multi-character **n-grams**
(e.g. $\texttt{SCH}$, $\texttt{TSH}$, $\texttt{RS}$) map as units, and a name
may yield **multiple** codes when letter groups have alternate pronunciations.

Examples (Commons Codec / Wikipedia order may list branches differently;
primary is the first branch):

- $\texttt{Peters}\to\texttt{734000}|\texttt{739400}$
- $\texttt{Peterson}\to\texttt{734600}|\texttt{739460}$
- $\texttt{Moskowitz}=\texttt{Moskovitz}\to\texttt{645740}$
- $\texttt{Auerbach}\to\texttt{097400}|\texttt{097500}$

This package is an **Ada 2023 (ISO/IEC 8652:2023)** educational implementation
aligned with the JewishGen / Avotaynu coding table as realized by
[Apache Commons Codec `DaitchMokotoffSoundex`](https://commons.apache.org/proper/commons-codec/apidocs/org/apache/commons/codec/language/DaitchMokotoffSoundex.html)
(`dmrules.txt`).

Primary sources:

- [Wikipedia — Daitch–Mokotoff Soundex](https://en.wikipedia.org/wiki/Daitch%E2%80%93Mokotoff_Soundex)
- [JewishGen — Soundex Coding](https://www.jewishgen.org/infofiles/soundex.html)
- [Avotaynu — Soundexing and Genealogy](https://www.avotaynu.com/soundex.htm)
- Apache Commons Codec `dmrules.txt` (table-driven reference)

Part of the **RobertBoettcherSF** Ada algorithm series.

## Contrast with string siblings

| Package | Idea |
| --- | --- |
| **This package** (`Ada-Daitch-Mokotoff-Soundex`) | D–M Soundex (6 digits, branching) |
| **[Ada-Soundex](https://github.com/RobertBoettcherSF/Ada-Soundex)** | American Soundex (letter + 3 digits) |
| **[Ada-Double-Metaphone](https://github.com/RobertBoettcherSF/Ada-Double-Metaphone)** | Double Metaphone primary/alternate |
| **[Ada-Metaphone](https://github.com/RobertBoettcherSF/Ada-Metaphone)** | Original Metaphone |
| **[Ada-NYSIIS](https://github.com/RobertBoettcherSF/Ada-NYSIIS)** | Strict NYSIIS surname key |
| **[Ada-Levenshtein-Distance](https://github.com/RobertBoettcherSF/Ada-Levenshtein-Distance)** | Unit-cost edit distance |

README links only — **no** package `with` of siblings.

## Algorithm

### Improvements over American Soundex

1. Codes are **six digits**, zero-padded ($\texttt{GOLDEN}\to\texttt{583600}$).
2. The **first** character/sound is coded ($\texttt{Alpert}\to\texttt{087930}$).
3. Multi-character n-grams encode as single replacements ($\texttt{Mintz}$ is
   $\texttt{MIN}$-$\texttt{TZ}$, not $\texttt{MIN}$-$\texttt{T}$-$\texttt{Z}$).
4. **Branching**: ambiguous groups ($\texttt{C}$, $\texttt{CH}$, $\texttt{CK}$,
   $\texttt{J}$, $\texttt{RS}$, $\texttt{RZ}$, …) produce alternate codes.

### Encoding steps (Commons / JewishGen)

1. **Strip** non-letters (spaces, hyphens, punctuation, digits). Fold common
   Latin-1 accents to ASCII; fold letters to lower case for matching. Multi-word
   names are treated as one word ($\texttt{Ben Aron}\to\texttt{Benaron}$).
2. Left-to-right **longest-match** against the coding table. Each rule has three
   context columns: **start of name** / **before a vowel** ($\texttt{AEIOU}$) /
   **other**.
3. Empty replacement = **not coded** (NC); the previous-replacement token is
   still updated so the next digit is not collapsed against an earlier one.
4. Adjacent **identical** replacement strings collapse, except $\texttt{MN}$ /
   $\texttt{NM}$, which force both digits ($\texttt{Kleinmann}\to\texttt{586660}$).
5. Branching forks alternate codes; `Primary_Encode` keeps the **first**
   alternate at each fork (Commons `encode` without branching).
6. **Pad** each code with trailing $\texttt{0}$ to length 6.

If the input is empty, longer than $\mathrm{Max\_Len}$, or letter-free after
cleaning, `Encode` / `Primary_Encode` raise `Invalid_Argument`.

### Documented choices / simplifications

- **Reference port:** Apache Commons Codec `DaitchMokotoffSoundex` +
  `dmrules.txt` (educational). Branch **order** follows Commons (first pipe
  alternative is primary). Wikipedia tables sometimes list the other order
  (e.g. $\texttt{Peters}$ as $\texttt{739400},\texttt{734000}$); membership is
  the same.
- **Branch bound:** at most $\mathrm{Max\_Codes}=16$ distinct codes retained
  (observed Commons examples ≤ 10). Extra branches would be dropped if ever
  exceeded.
- **ASCII + Latin-1 folding:** letters outside Ada `Character` (full Unicode
  beyond Latin-1) are not mapped; educational tests stay in ASCII / Latin-1.
- **Romanian / Polish specials** in Commons ($\texttt{ţ}$, $\texttt{ę}$, …)
  beyond Latin-1 are omitted; core Latin letter table is complete.
- **`Codes_Match`:** true if **any** code of $A$ equals **any** code of $B$
  (cross product), so $\texttt{Auerbach}$ matches $\texttt{Ohrbach}$.

### Classic examples

| Name | Primary | All codes (Commons order) |
| ---- | ---- | ---- |
| Peters | 734000 | 734000\|739400 |
| Peterson | 734600 | 734600\|739460 |
| Moskowitz / Moskovitz | 645740 | 645740 |
| Auerbach / Ohrbach | 097400 | 097400\|097500 |
| Jackson | 154600 | 154600\|145460\|454600\|445460 |
| GOLDEN | 583600 | 583600 |
| Alpert | 087930 | 087930 |
| Kleinmann | 586660 | 586660 |
| Lipshitz / Lippszyc | 874400 | 874400 / 874400\|874500 |

## Package API

```ada
package Daitch_Mokotoff_Soundex is
   Max_Len     : constant Positive := 10_000;
   Code_Length : constant := 6;
   Max_Codes   : constant Positive := 16;

   Invalid_Argument : exception;

   subtype Code_String is String (1 .. 6);
   type Code_List is array (Positive range <>) of Code_String;

   function Encode (Name : String) return Code_List;
   function Primary_Encode (Name : String) return Code_String;
   function Codes_Match (A, B : String) return Boolean;
end Daitch_Mokotoff_Soundex;
```

- `Encode` — all branch codes, primary first, length $1..\mathrm{Max\_Codes}$.
- `Primary_Encode` — first code only (no branching forks).
- `Codes_Match` — any-vs-any equality of the two `Encode` lists.

## Build and test

```bash
make
make test
# or:
gnatmake -gnatwa -gnat2022 -Pdaitch_mokotoff_soundex.gpr
```

Expect **zero** `-gnatwa` warnings and **ALL PASS** from `bin/tests`.

## Layout

Exactly seven root files (no `main.adb`):

| File | Role |
| --- | --- |
| `daitch_mokotoff_soundex.ads` | Package spec / API |
| `daitch_mokotoff_soundex.adb` | Table-driven encoder |
| `daitch_mokotoff_soundex.gpr` | GNAT project (main = `tests.adb`) |
| `tests.adb` | Standalone test program |
| `Makefile` | `all` / `test` / `clean` |
| `README.md` | This document |
| `.gitignore` | `obj/`, `bin/`, artifacts |

## License / provenance

Educational reimplementation for the RobertBoettcherSF Ada algorithm series.
Algorithm and table: Mokotoff & Daitch; rule-file structure follows Apache
Commons Codec (`dmrules.txt`) under the Apache License 2.0. Not affiliated
with JewishGen, Avotaynu, or the ASF.
