# Double Metaphone in Ada 2023

## Project Overview

**Double Metaphone** is the second-generation phonetic algorithm by Lawrence
Philips (C/C++ Users Journal, June 2000). Unlike original Metaphone, it can
return **both a primary and an alternate** code for a string, covering
ambiguous pronunciations and surname variants of common ancestry. For example
$\texttt{Smith}\to\texttt{SM0}/\texttt{XMT}$ while
$\texttt{Schmidt}\to\texttt{XMT}/\texttt{SMT}$ — both share $\texttt{XMT}$.

It accounts for English spelling irregularities of Slavic, Germanic, Celtic,
Greek, French, Italian, Spanish, Chinese, and other origins, with a much
richer ruleset than original Metaphone (roughly a hundred contexts for
$\texttt{C}$ alone).

This package is an **Ada 2023 (ISO/IEC 8652:2023)** educational
implementation aligned with
[Apache Commons Codec `DoubleMetaphone`](https://commons.apache.org/proper/commons-codec/apidocs/org/apache/commons/codec/language/DoubleMetaphone.html)
semantics: silent-start skip, Slavo-Germanic flag, letter handlers for
C/CH/CC, G/GH/GN, J (Jose/San), S/SH/SC, T/TH, W/WR/Witz, X, Z/ZH, and
truncation of **each** key to $\mathrm{Max\_Code\_Len}=4$ (unpadded).

**Not** original Metaphone (sibling sheet `Ada-Metaphone`) and **not**
Metaphone 3 (commercial).

Primary sources:

- Lawrence Philips, *The Double Metaphone Search Algorithm*, C/C++ Users
  Journal, June 2000
- [Wikipedia — Metaphone](https://en.wikipedia.org/wiki/Metaphone)
  (Double Metaphone section)
- Reference behaviour aligned with Apache Commons Codec `DoubleMetaphone`

Part of the **RobertBoettcherSF** Ada algorithm series.

## Contrast with string siblings

| Package | Idea |
| --- | --- |
| **This package** (`Ada-Double-Metaphone`) | Double Metaphone primary/alternate (trunc. 4) |
| **[Ada-Metaphone](https://github.com/RobertBoettcherSF/Ada-Metaphone)** | Original Metaphone (single key; TH→0) |
| **[Ada-Soundex](https://github.com/RobertBoettcherSF/Ada-Soundex)** | American Soundex (letter + 3 digits) |
| **[Ada-NYSIIS](https://github.com/RobertBoettcherSF/Ada-NYSIIS)** | Strict NYSIIS surname key (trunc. 6) |
| **[Ada-Levenshtein-Distance](https://github.com/RobertBoettcherSF/Ada-Levenshtein-Distance)** | Unit-cost edit distance |

README links only — **no** package `with` of siblings.

## Algorithm

### Primary and alternate keys

Double Metaphone builds two codes in parallel. Many letters append the same
symbol to both; ambiguous contexts append different primary/alternate
symbols (e.g. leading $\texttt{J}\to\texttt{J}/\texttt{A}$,
$\texttt{CH}\to\texttt{X}/\texttt{K}$ in many non-Greek cases,
$\texttt{TH}\to\texttt{0}/\texttt{T}$). When there is no divergence, the
alternate equals the primary.

Code alphabet symbols are drawn from
$\{\texttt{0},\texttt{A},\texttt{F},\texttt{H},\texttt{J},\texttt{K},\texttt{L},\texttt{M},\texttt{N},\texttt{P},\texttt{R},\texttt{S},\texttt{T},\texttt{X}\}$
(digit $\texttt{0}$ = TH). Leading vowel sound → $\texttt{A}$.

### Encoding steps (Commons / Philips)

1. **Trim**, fold letters to upper case; **keep spaces** (needed for
   $\texttt{VAN }$ / $\texttt{VON }$ / $\texttt{SAN }$); drop other
   non-letters. Require at least one A–Z letter.
2. **Silent start**: $\texttt{GN}|\texttt{KN}|\texttt{PN}|\texttt{WR}|\texttt{PS}$
   → begin at index $1$.
3. **Slavo-Germanic** flag if the working string contains
   $\texttt{W}|\texttt{K}|\texttt{CZ}|\texttt{WITZ}$.
4. Left-to-right scan until **both** keys reach $\mathrm{Max\_Code\_Len}$:
   - Vowels → leading $\texttt{A}$ only; $\texttt{B}\to\texttt{P}$;
     $\texttt{Ç}\to\texttt{S}$ (if present); complex $\texttt{C}$ /
     $\texttt{CH}$ / $\texttt{CC}$ / $\texttt{CZ}$ / $\texttt{CIA}$;
   - $\texttt{D}/\texttt{DG}\to\texttt{J}|\texttt{TK}|\texttt{T}$;
     $\texttt{F}$; rich $\texttt{G}/\texttt{GH}/\texttt{GN}$;
   - $\texttt{H}$ between vowels; $\texttt{J}$ (Jose / San / …);
     $\texttt{K}$; Spanish $\texttt{LL}$; $\texttt{M}$ (UMB); $\texttt{N}$;
   - $\texttt{P}/\texttt{PH}\to\texttt{F}$; $\texttt{Q}\to\texttt{K}$;
     French-silent $\texttt{R}$; $\texttt{S}/\texttt{SH}/\texttt{SC}/\ldots$;
   - $\texttt{T}/\texttt{TH}\to\texttt{0}|\texttt{T}$; $\texttt{V}\to\texttt{F}$;
     $\texttt{W}/\texttt{WH}/\texttt{WR}/\texttt{WICZ}$;
     $\texttt{X}\to\texttt{S}|\texttt{KS}$; $\texttt{Z}/\texttt{ZH}\to\texttt{J}|\texttt{S}|\texttt{TS}$.
5. **Truncate** each key to $\mathrm{Max\_Code\_Len}=4$ (unpadded).

If the input is empty, longer than $\mathrm{Max\_Len}$, or letter-free after
cleaning, `Encode` raises `Invalid_Argument`. Inputs that encode to an empty
primary (e.g. lone $\texttt{H}$) also raise.

### Documented choices / ambiguities

- **Reference port:** Apache Commons Codec `DoubleMetaphone` (educational
  default length 4).
- **Truncation:** each of primary and alternate independently truncated to
  $4$; **do not pad**.
- **TH → 0:** digit zero retained (e.g. $\texttt{Smith}\to\texttt{SM0}$).
- **Spaces kept:** so $\texttt{san jose}$ and $\texttt{VAN }$ / $\texttt{VON }$
  patterns match Commons.
- **Alternate vs primary:** when rules never diverge, alternate equals
  primary; `Alternate_Length` may differ on primary-only / alternate-only
  appends (Spanish $\texttt{LL}$, French final $\texttt{R}$, etc.).
- **`Codes_Match`:** true if **any** key of $A$ equals **any** key of $B$
  (cross product). So $\texttt{Smith}$ matches $\texttt{Schmidt}$ via shared
  $\texttt{XMT}$. This is broader than Commons
  `isDoubleMetaphoneEqual` (which compares primary-to-primary or
  alternate-to-alternate only).
- **Non-letters:** punctuation/digits stripped; spaces kept.

### Classic examples

| Word | Primary | Alternate | Notes |
| ---- | ---- | ---- | ---- |
| Smith / Smyth | SM0 | XMT | wiki example |
| Schmidt / Schmitt | XMT | SMT | shares XMT with Smith |
| Jose | HS | HS | Spanish Jose |
| jumped | JMPT | AMPT | leading J → J/A |
| testing | TSTN | TSTN | Commons sentence |
| The | 0 | T | TH → 0/T |
| Wagner | AKNR | FKNR | W → A/F |
| School | SKL | SKL | SCH+OO → SK |
| Sugar | XKR | SKR | SUGAR special |
| Wright | RT | RT | silent WR |
| Knight | NT | NT | silent KN |
| xenophobia | SNFP | SNFP | leading X → S |
| san jose | SNHS | SNHS | SAN + Jose |

`Codes_Match("Smith","Schmidt")` is true via shared $\texttt{XMT}$.

## Complexity

| Measure | Bound |
| ------- | ----- |
| Time | $O(n)$ one left-to-right pass after $O(n)$ clean |
| Auxiliary space | $O(n)$ working buffer ($\le\mathrm{Max\_Len}$) |
| Capacity | $n \le \mathrm{Max\_Len}=10000$; each code $\le 4$ |

## Features

- **`Encode`** — `Codes` record with primary/alternate and length fields.
- **`Primary` / `Alternate`** — unpadded key strings (alternate may be empty).
- **`Codes_Match`** — any-key cross equality (Smith↔Schmidt).
- **Spaces kept; other non-letters skipped** — Commons VAN/VON/SAN.
- **Case-insensitive** — letters folded to upper case.
- **TH → 0** — digit zero in the code alphabet.
- **Truncation 4** — Commons default educational length.
- **Capacity / empty guard** — `Invalid_Argument` for empty, overlong,
  letter-free, or empty-primary input.
- **Arbitrary `String'First`** — slices work.
- **Zero-warning build** — `gnatmake -gnatwa -gnat2022 -Pdouble_metaphone.gpr`.

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

=== 1. Commons classic sentence / name vectors ===
  PASS: ...
...
Results:  NN PASS, 0 FAIL
```

(Exact `NN` is the current suite size; it is at least 200.)

## Testing

The test suite in `tests.adb` covers:

- Apache Commons Codec classic vectors (sentence, MacCafferey, Kuczewski, …)
- Wiki Smith/Schmidt/Jose and `Codes_Match` cross-key share of XMT
- Silent starts KN/GN/PN/WR/PS and WH/WR
- C/CH/CC/CZ, G/GH/GN, S/SH/SC, T/TH, W/Witz, J/Jose/San, Z/ZH
- Case folding, trim, non-letter stripping, non-1 `String'First`
- Empty / letter-free / over-`Max_Len` → `Invalid_Argument`
- Length invariant ($1..4$ primary) and alphabet checks (including digit `0`)
- Bulk single-letter and long-input truncation
- Surname table and Encode record field checks

## Building

- Prerequisites: GNAT compiler supporting Ada 2022 / Ada 2023 (e.g. GNAT FSF
  13+, GNAT 14+, or GNAT Pro).
- Standard: ISO/IEC 8652:2023.
- Build flag: `-gnatwa -gnat2022` with zero compiler warnings.

## API

```ada
package Double_Metaphone is
   Max_Len      : constant Positive := 10_000;
   Max_Code_Len : constant Positive := 4;
   Invalid_Argument : exception;

   type Codes is record
      Primary          : String (1 .. Max_Code_Len);
      Alternate        : String (1 .. Max_Code_Len);
      Primary_Length   : Natural;
      Alternate_Length : Natural;
   end record;

   function Encode (Word : String) return Codes;
   function Primary (Word : String) return String;
   function Alternate (Word : String) return String;
   function Codes_Match (A, B : String) return Boolean;
end Double_Metaphone;
```

Raises `Invalid_Argument` if the input is empty, longer than `Max_Len`,
letter-free, or encodes to an empty primary.

## License

Educational reference implementation. See repository `LICENSE` if present.
