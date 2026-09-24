# NYSIIS in Ada 2023

## Project Overview

**NYSIIS** (New York State Identification and Intelligence System) is a
phonetic algorithm devised by Robert L. Taft in 1970 that encodes an
English surname as an alphabetic key — for example
$\texttt{Bishop}\to\texttt{BASAP}$, $\texttt{Willis}\to\texttt{WAL}$,
$\texttt{Macintosh}\to\texttt{MCANT}$. Names that sound alike tend to
share a code. Relative to American Soundex it was reported to improve
matching accuracy by about $2.7\%$.

This package is an **Ada 2023 (ISO/IEC 8652:2023)** educational
implementation of the **original / strict** NYSIIS rules: prefix and
suffix rewrites, vowel normalisation, H/W contextual rules, adjacent
duplicate collapse, trailing S / AY / A cleanup, and truncation to
$\mathrm{Max\_Code\_Len}=6$ (unpadded).

Primary sources:

- [Wikipedia — NYSIIS](https://en.wikipedia.org/wiki/New_York_State_Identification_and_Intelligence_System)
- Robert L. Taft, *Name Search Techniques*, NYSIIS (1970)
- Reference behaviour aligned with [Apache Commons Codec `Nysiis`](https://commons.apache.org/proper/commons-codec/apidocs/org/apache/commons/codec/language/Nysiis.html) (strict mode)

Part of the **RobertBoettcherSF** Ada algorithm series.

## Contrast with string siblings

| Package | Idea |
| --- | --- |
| **This package** (`Ada-NYSIIS`) | Phonetic surname key (letters, trunc. 6) |
| **[Ada-Soundex](https://github.com/RobertBoettcherSF/Ada-Soundex)** | American Soundex (letter + 3 digits) |
| **[Ada-Levenshtein-Distance](https://github.com/RobertBoettcherSF/Ada-Levenshtein-Distance)** | Unit-cost insert/delete/substitute edit distance |
| **[Ada-Dice-Coefficient](https://github.com/RobertBoettcherSF/Ada-Dice-Coefficient)** | Bigram-set Sørensen–Dice similarity |
| **[Ada-Jaro-Winkler-Distance](https://github.com/RobertBoettcherSF/Ada-Jaro-Winkler-Distance)** | Prefix-biased Jaro–Winkler similarity |

README links only — **no** package `with` of siblings.

## Algorithm

### Encoding steps (original / strict)

1. **Strip non-letters** and fold to upper case.
2. **Prefix** (first match, in order):
   - $\texttt{MAC}\to\texttt{MCC}$
   - $\texttt{KN}\to\texttt{NN}$
   - $\texttt{K}\to\texttt{C}$
   - $\texttt{PH}|\texttt{PF}\to\texttt{FF}$
   - $\texttt{SCH}\to\texttt{SSS}$
3. **Suffix**:
   - $\texttt{EE}|\texttt{IE}\to\texttt{Y}$
   - $\texttt{DT}|\texttt{RT}|\texttt{RD}|\texttt{NT}|\texttt{ND}\to\texttt{D}$
4. Key starts with the (rewritten) **first letter**.
5. **Scan** remaining letters with a sliding window, rewriting in place:
   - $\texttt{EV}\to\texttt{AF}$; else vowels $\{\texttt{A,E,I,O,U}\} \to\texttt{A}$
   - $\texttt{Q}\to\texttt{G}$; $\texttt{Z}\to\texttt{S}$; $\texttt{M}\to\texttt{N}$
   - $\texttt{KN}\to\texttt{NN}$ else $\texttt{K}\to\texttt{C}$
   - $\texttt{SCH}\to\texttt{SSS}$; $\texttt{PH}\to\texttt{FF}$
   - $\texttt{H}\to$ previous if previous **or** next is a non-vowel
   - $\texttt{W}\to$ previous if previous is a vowel
   - Append the rewritten letter to the key iff it differs from the
     previous rewritten name letter (adjacent duplicates drop).
6. If the last key letter is $\texttt{S}$, remove it (**never** drop the
   first key letter).
7. If the last two key letters are $\texttt{AY}$, replace with $\texttt{Y}$.
8. If the last key letter is $\texttt{A}$, remove it (**never** drop the
   first key letter).
9. **Truncate** to $\mathrm{Max\_Code\_Len}=6$ (unpadded).

$\texttt{Y}$ is **not** treated as a vowel. Vowels $=\{A,E,I,O,U\}$.

If the input is empty, longer than $\mathrm{Max\_Len}$, or contains no
A–Z letter after stripping non-letters, `Encode` raises
`Invalid_Argument`.

### Documented choices / ambiguities

- **Truncation policy:** return the leading $\min(\ell,6)$ letters of the
  key; **do not pad**. Length is therefore $1..\mathrm{Max\_Code\_Len}$.
- **First-letter preservation:** trailing S / A cleanup never removes the
  sole remaining key letter. Classic consequence:
  $$
  \texttt{Ash}\to\texttt{A}
  $$
  (Apache Commons Codec historically emptied the key here — CODEC-308;
  this package keeps $\texttt{A}$.)
- **Collapse timing:** adjacent duplicates are dropped during the scan
  (comparing rewritten neighbours), matching Commons Codec rather than a
  separate final collapse pass.
- **KN prefix:** $\texttt{KN}\to\texttt{NN}$ (Wikipedia / Commons), not
  $\texttt{N}$.

### Classic examples

| Name | Code (strict, $\le 6$) |
| ---- | ---- |
| Bishop | BASAP |
| Willis | WAL |
| Matthews | MAT |
| Macintosh | MCANT |
| Knuth | NAT |
| Westerlund | WASTAR |
| Brian / Brown / Brun | BRAN |
| Capp / Kipp | CAP |
| Smith / Schmit | SNAT |
| Schmidt | SNAD |
| McKee / Mackie | MCY |
| Ash | A |
| Franklin | FRANCL |
| Carlson | CARLSA |

`Codes_Match(A,B)` is simply $\mathrm{Encode}(A)=\mathrm{Encode}(B)$.
Under truncation, $\texttt{McDaniel}$ and $\texttt{McDonald}$ both become
$\texttt{MCDANA}$ and therefore match.

## Complexity

| Measure | Bound |
| ------- | ----- |
| Time | $O(n)$ one left-to-right pass after $O(n)$ strip |
| Auxiliary space | $O(n)$ working name buffer ($\le\mathrm{Max\_Len}$) |
| Capacity | $n \le \mathrm{Max\_Len}=10000$; code $\le 6$ |

## Features

- **`Encode`** — strict NYSIIS code, unpadded length $1..6$.
- **`Codes_Match`** — equality of NYSIIS codes.
- **Non-letters skipped** — digits, spaces, punctuation ignored.
- **Case-insensitive** — letters folded to upper case.
- **Strict truncation** — original algorithm, $\mathrm{Max\_Code\_Len}=6$.
- **Ash → A** — first key letter never dropped by trailing cleanup.
- **Capacity / empty guard** — `Invalid_Argument` for empty, overlong,
  or letter-free input.
- **Arbitrary `String'First`** — slices work.
- **Zero-warning build** — `gnatmake -gnatwa -gnat2022 -Pnysiis.gpr`.

## Usage

```bash
# Build test suite
make

# Run tests
make test

# Clean artifacts
make clean
```

### Expected Output

```text
Running tests...

=== 1. Apache Commons / dropby classic vectors ===
  PASS: ...
...
Results:  NN PASS, 0 FAIL
```

(Exact `NN` is the current suite size; it is at least 100.)

## Testing

The test suite in `tests.adb` covers:

- Apache Commons Codec / dropby.com vectors (strict, trunc. 6)
- Rosetta Code surname table (truncated)
- Bran / Cap / Dad / Dan / Fal clusters
- Prefix and suffix rule unit vectors
- Mid-scan EV / vowel / Q Z M / trailing S AY A rules
- Case folding and non-letter stripping
- `Codes_Match` true/false pairs and symmetry
- Empty / letter-free / over-`Max_Len` → `Invalid_Argument`
- Non-1 `String'First` slices
- Length invariant ($1..6$) and alphabetic code checks
- Bulk micro-cases over the alphabet and long inputs
- H / W / SCH / PH edge chains

## Building

- Prerequisites: GNAT compiler supporting Ada 2022 / Ada 2023 (e.g. GNAT FSF
  13+, GNAT 14+, or GNAT Pro).
- Standard: ISO/IEC 8652:2023.
- Build flag: `-gnatwa -gnat2022` with zero compiler warnings.

## API

```ada
package NYSIIS is
   Max_Len      : constant Positive := 10_000;
   Max_Code_Len : constant Positive := 6;
   Invalid_Argument : exception;

   function Encode (Name : String) return String;
   --  Unpadded uppercase code, length 1 .. Max_Code_Len.

   function Codes_Match (A, B : String) return Boolean;
end NYSIIS;
```

Raises `Invalid_Argument` if the input is empty, longer than `Max_Len`,
or contains no A–Z letter.

## License

Educational reference implementation. See repository `LICENSE` if present.
