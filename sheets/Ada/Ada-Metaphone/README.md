# Original Metaphone in Ada 2023

## Project Overview

**Metaphone** is a phonetic algorithm published by Lawrence Philips in 1990
that encodes an English word by approximate pronunciation — for example
$\texttt{John}\to\texttt{JN}$, $\texttt{Smith}\to\texttt{SM0}$,
$\texttt{Schmidt}\to\texttt{SKMT}$, $\texttt{howl}\to\texttt{HL}$.
Names that sound alike tend to share a code. Relative to American Soundex
it uses richer English spelling/pronunciation rules and a 16-symbol
consonant alphabet (digit $\texttt{0}$ stands for $\texttt{TH}$ / theta).

This package is an **Ada 2023 (ISO/IEC 8652:2023)** educational
implementation of the **original Metaphone** rules: prefix exceptions,
duplicate collapse (except C), contextual C/G/D/T/X/S/H/W/Y/Z maps, and
truncation to $\mathrm{Max\_Code\_Len}=4$ (unpadded).

**Not** Double Metaphone (separate sheet `Ada-Double-Metaphone`).

Primary sources:

- Lawrence Philips, *Hanging on the Metaphone*, Computer Language,
  Dec. 1990, pp. 39–43
- [Wikipedia — Metaphone](https://en.wikipedia.org/wiki/Metaphone)
- Reference behaviour aligned with
  [Apache Commons Codec `Metaphone`](https://commons.apache.org/proper/commons-codec/apidocs/org/apache/commons/codec/language/Metaphone.html)
  (Brogden port; differs from PHP Metaphone — see CODEC-57)

Part of the **RobertBoettcherSF** Ada algorithm series.

## Contrast with string siblings

| Package | Idea |
| --- | --- |
| **This package** (`Ada-Metaphone`) | Original Metaphone (trunc. 4; TH→0) |
| **[Ada-Soundex](https://github.com/RobertBoettcherSF/Ada-Soundex)** | American Soundex (letter + 3 digits) |
| **[Ada-NYSIIS](https://github.com/RobertBoettcherSF/Ada-NYSIIS)** | Strict NYSIIS surname key (trunc. 6) |
| **Ada-Double-Metaphone** (later sheet) | Double Metaphone primary/alternate |
| **[Ada-Levenshtein-Distance](https://github.com/RobertBoettcherSF/Ada-Levenshtein-Distance)** | Unit-cost edit distance |

README links only — **no** package `with` of siblings.

## Algorithm

### Code alphabet

Original Metaphone keys use:

$$
\{0,B,F,H,J,K,L,M,N,P,R,S,T,W,X,Y\}
$$

plus a **leading vowel** $\{\texttt{A,E,I,O,U}\}$ when the working string
starts with a vowel. Digit $\texttt{0}$ (zero) is the ASCII stand-in for
$\texttt{TH}$ (theta). Many educational ports keep this $\texttt{0}$;
this package does too.

### Encoding steps (original / Commons)

1. **Strip non-letters** and fold to upper case.
2. Length-$1$ word → that letter (early return).
3. **Prefix exceptions**:
   - $\texttt{KN}|\texttt{GN}|\texttt{PN}|\texttt{AE}|\texttt{WR}$ → drop first letter
   - $\texttt{X}\to\texttt{S}$; $\texttt{WH}\to\texttt{W}$
4. Left-to-right scan (stop at $\mathrm{Max\_Code\_Len}$ symbols):
   - Drop **adjacent duplicate** letters **except** $\texttt{C}$.
   - Vowels kept **only** at position $0$ of the working string.
   - $\texttt{B}$ silent after $\texttt{M}$ at end ($\ldots\texttt{MB}$).
   - $\texttt{C}$: $\texttt{SCI}/\texttt{SCE}/\texttt{SCY}$ silent;
     $\texttt{SCH}\to\texttt{K}$; $\texttt{CIA}|\texttt{CH}\to\texttt{X}$;
     $\texttt{CI}|\texttt{CE}|\texttt{CY}\to\texttt{S}$; else $\texttt{K}$.
   - $\texttt{D}$: $\texttt{DGE}|\texttt{DGI}|\texttt{DGY}\to\texttt{J}$
     (skip the $\texttt{GE}/\texttt{GI}/\texttt{GY}$); else $\texttt{T}$.
   - $\texttt{G}$: silent before $\texttt{H}$ at end / before a consonant;
     silent $\texttt{GN}|\texttt{GNED}$; else $\texttt{GE}|\texttt{GI}|\texttt{GY}\to\texttt{J}$;
     else $\texttt{K}$.
   - $\texttt{H}$: silent at end or after $\texttt{C}/\texttt{S}/\texttt{P}/\texttt{T}/\texttt{G}$;
     else kept before a vowel.
   - $\texttt{K}$ silent after $\texttt{C}$; $\texttt{P}\to\texttt{F}$ before $\texttt{H}$;
     $\texttt{Q}\to\texttt{K}$; $\texttt{V}\to\texttt{F}$; $\texttt{Z}\to\texttt{S}$.
   - $\texttt{S}$: $\texttt{SH}|\texttt{SIO}|\texttt{SIA}\to\texttt{X}$ else $\texttt{S}$.
   - $\texttt{T}$: $\texttt{TIA}|\texttt{TIO}\to\texttt{X}$; $\texttt{TCH}$ silent;
     $\texttt{TH}\to\texttt{0}$; else $\texttt{T}$.
   - $\texttt{W}|\texttt{Y}$ kept only before a vowel; $\texttt{X}\to\texttt{KS}$.
5. **Truncate** to $\mathrm{Max\_Code\_Len}=4$ (unpadded).

If the input is empty, longer than $\mathrm{Max\_Len}$, letter-free after
stripping, or encodes to an empty code (classic $\texttt{WHY}$),
`Encode` raises `Invalid_Argument`.

### Documented choices / ambiguities

- **Reference port:** Apache Commons Codec `Metaphone` (William B. Brogden),
  not PHP `metaphone()` (CODEC-57 notes undocumented PHP/Perl drift).
- **Truncation:** leading $\min(\ell,4)$ symbols; **do not pad**. Length is
  therefore $1..\mathrm{Max\_Code\_Len}$.
- **TH → 0:** digit zero is retained in the code alphabet (e.g.
  $\texttt{Smith}\to\texttt{SM0}$).
- **SCH → K:** Wikipedia / Commons (so $\texttt{Schmidt}\to\texttt{SKMT}$).
  Double Metaphone’s primary $\texttt{XMT}$ is **out of scope** here.
- **Empty codes:** original / Commons yield $""$ for $\texttt{WHY}$; this
  package raises `Invalid_Argument` instead (API length $1..4$).
- **Non-letters:** stripped (educational; Commons historically assumed A–Z).

### Classic examples

| Word | Code (trunc. $\le 4$) | Notes |
| ---- | ---- | ---- |
| howl | HL | Commons sentence vector |
| testing | TSTN | |
| the | 0 | TH → 0 |
| John / Jane | JN | |
| Smith / Smythe | SM0 | |
| Schmidt | SKMT | SCH → K (not Double Metaphone XMT) |
| metaphone | MTFN | |
| Katherine | K0RN | |
| Wright | RT | WR- prefix |
| Knight | NT | KN- prefix |
| White | WT | WH → W |
| PHISH | FX | PH → F |
| SCIENCE | SNS | SCE/SCI silent C |
| COMB | KM | final MB silent B |
| WHY | *(raises)* | empty code → Invalid_Argument |

`Codes_Match(A,B)` is simply $\mathrm{Encode}(A)=\mathrm{Encode}(B)$.

## Complexity

| Measure | Bound |
| ------- | ----- |
| Time | $O(n)$ one left-to-right pass after $O(n)$ strip |
| Auxiliary space | $O(n)$ working buffer ($\le\mathrm{Max\_Len}$) |
| Capacity | $n \le \mathrm{Max\_Len}=10000$; code $\le 4$ |

## Features

- **`Encode`** — original Metaphone code, unpadded length $1..4$.
- **`Codes_Match`** — equality of Metaphone codes.
- **Non-letters skipped** — digits, spaces, punctuation ignored.
- **Case-insensitive** — letters folded to upper case.
- **TH → 0** — digit zero in the code alphabet.
- **Truncation 4** — Commons default educational length.
- **Capacity / empty guard** — `Invalid_Argument` for empty, overlong,
  letter-free, or empty-result input.
- **Arbitrary `String'First`** — slices work.
- **Zero-warning build** — `gnatmake -gnatwa -gnat2022 -Pmetaphone.gpr`.

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

=== 1. Apache Commons classic sentence vectors ===
  PASS: ...
...
Results:  NN PASS, 0 FAIL
```

(Exact `NN` is the current suite size; it is at least 100.)

## Testing

The test suite in `tests.adb` covers:

- Apache Commons Codec classic vectors (sentence, SCE/SCH/CH, GN/GH/MB, SH/TCH/TH)
- Well-known names (John, Schmidt, Smith, Katherine, Wright, …)
- Prefix exceptions KN/GN/PN/AE/WR/WH/X
- `Codes_Match` true/false pairs and symmetry
- Case folding and non-letter stripping
- Empty / letter-free / over-`Max_Len` / empty-code → `Invalid_Argument`
- Non-1 `String'First` slices
- Length invariant ($1..4$) and alphabet checks (including digit `0`)
- Bulk micro-cases over the alphabet and long inputs
- Vowel / W / Y / Q / V / Z / CK edge chains

## Building

- Prerequisites: GNAT compiler supporting Ada 2022 / Ada 2023 (e.g. GNAT FSF
  13+, GNAT 14+, or GNAT Pro).
- Standard: ISO/IEC 8652:2023.
- Build flag: `-gnatwa -gnat2022` with zero compiler warnings.

## API

```ada
package Metaphone is
   Max_Len      : constant Positive := 10_000;
   Max_Code_Len : constant Positive := 4;
   Invalid_Argument : exception;

   function Encode (Word : String) return String;
   --  Unpadded Metaphone code, length 1 .. Max_Code_Len
   --  (alphabet includes digit '0' for TH).

   function Codes_Match (A, B : String) return Boolean;
end Metaphone;
```

Raises `Invalid_Argument` if the input is empty, longer than `Max_Len`,
letter-free, or encodes to an empty code.

## License

Educational reference implementation. See repository `LICENSE` if present.
