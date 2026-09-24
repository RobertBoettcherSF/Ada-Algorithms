# Phonetic Algorithms Survey in Ada 2023

## Project Overview

A **phonetic algorithm** maps a word or surname to a compact key that
groups names that *sound* alike under English (or other) pronunciation
heuristics. Classic uses include census indexing, airline passenger
matching, and fuzzy search when spelling variants are common
(Smith / Smyth / Schmidt).

This package is an **Ada 2023 (ISO/IEC 8652:2023)** educational *survey*:
self-contained implementations of four classical encoders in one
mini-suite. Letters are folded to upper case; non-letters are skipped
(Latin-1 `Character`; no Unicode normalization). All algorithms live
**inline** in `Phonetic_Algorithms` — there is **no** `with` of sibling
Ada-* packages.

Primary source:
[Wikipedia — Phonetic algorithm](https://en.wikipedia.org/wiki/Phonetic_algorithm).

Part of the **RobertBoettcherSF** Ada algorithm series.

## Contrast with phonetic siblings

| Package | Idea |
| --- | --- |
| **This package** (`Ada-Phonetic-Algorithms`) | Survey: Soundex, NYSIIS, Metaphone, MRA encode |
| **[Ada-Soundex](https://github.com/RobertBoettcherSF/Ada-Soundex)** | Dedicated American Soundex |
| **[Ada-NYSIIS](https://github.com/RobertBoettcherSF/Ada-NYSIIS)** | Dedicated original / strict NYSIIS |
| **[Ada-Metaphone](https://github.com/RobertBoettcherSF/Ada-Metaphone)** | Dedicated original Metaphone |
| **[Ada-Match-Rating-Approach](https://github.com/RobertBoettcherSF/Ada-Match-Rating-Approach)** | Dedicated MRA encode + similarity compare |
| **[Ada-Double-Metaphone](https://github.com/RobertBoettcherSF/Ada-Double-Metaphone)** | Dedicated Double Metaphone (primary/alternate) |
| **[Ada-Daitch-Mokotoff-Soundex](https://github.com/RobertBoettcherSF/Ada-Daitch-Mokotoff-Soundex)** | Dedicated Daitch–Mokotoff Soundex |

README links only — **no** package `with` of siblings. Double Metaphone
and Daitch–Mokotoff branching tables are **not** reimplemented here;
see those dedicated sheets for full coverage.

## Algorithms

### American Soundex

Retains the first letter, maps consonants to digits 1..6, drops vowels /
H / W / Y after the first letter, collapses adjacent equal digit codes,
and pads with `0` to length **4**. H and W do **not** reset the previous
digit (NARA / Wikipedia), so Ashcraft → `A261` (not `A226`).

Letter map: BFPV→1; CGJKQSXZ→2; DT→3; L→4; MN→5; R→6; AEIOUHWY→0.

### Original NYSIIS

New York State Identification and Intelligence System (Robert L. Taft,
1970). Alphabetic rewrite with prefix/suffix rules (MAC→MCC, KN→NN, …),
vowel collapse to A, adjacent-duplicate drop, trailing S/A/AY cleanup,
truncated to **≤6** characters (unpadded). Trailing cleanup never drops
the first key letter (Ash → `A`).

### Original Metaphone

Lawrence Philips (1990). Approximate English pronunciation using a
16-symbol alphabet including digit `0` for TH (theta). Truncated to
**≤4** (Commons Codec / Brogden style). This is **not** Double Metaphone.

### Match Rating Approach (encode)

Western Airlines (1977) personal numeric identifier / codex: strip
non-letters, drop vowels (keep a leading vowel; Y is a consonant),
collapse adjacent duplicates, then keep first 3 + last 3 when longer
than **6**. Full MRA similarity rating / compare lives in the dedicated
`Ada-Match-Rating-Approach` sibling.

## API Summary

Package `Phonetic_Algorithms`:

| Entity | Kind | Notes |
| --- | --- | --- |
| `Max_Len` | `constant Positive := 10_000` | pedagogical input bound |
| `Invalid_Argument` | exception | empty, overlong, letter-free, or empty Metaphone code |
| `Soundex (Name)` | `String` | always length 4 (letter + 3 digits) |
| `NYSIIS (Name)` | `String` | unpadded length 1..6 |
| `Metaphone (Word)` | `String` | unpadded length 1..4; `0` = TH |
| `Match_Rating_Encode (Name)` | `String` | unpadded length 1..6 |
| `Codes_Match_Soundex (A, B)` | `Boolean` | `Soundex(A) = Soundex(B)` |
| `Codes_Match_NYSIIS (A, B)` | `Boolean` | `NYSIIS(A) = NYSIIS(B)` |
| `Codes_Match_Metaphone (A, B)` | `Boolean` | `Metaphone(A) = Metaphone(B)` |

Every encoder raises `Invalid_Argument` when the input is empty, longer
than `Max_Len`, or letter-free after stripping. Metaphone also raises
when the code would be empty (e.g. `WHY`).

## Complexity

| Function | Time | Aux space |
| --- | --- | --- |
| `Soundex` | $O(n)$ | $O(1)$ |
| `NYSIIS` | $O(n)$ | $O(n)$ working buffer |
| `Metaphone` | $O(n)$ | $O(n)$ working buffer |
| `Match_Rating_Encode` | $O(n)$ | $O(n)$ working buffer |
| Match helpers | $O(n)$ | same as the two encodes |

## Build and test

```bash
make
make test
# or:
gnatmake -gnatwa -gnat2022 -Pphonetic_algorithms.gpr
./bin/tests
```

Requires GNAT (Ada 2022 switch `-gnat2022`). Expect **zero** `-gnatwa`
warnings and all tests **PASS**.

## Applications (from Wikipedia)

Phonetic algorithms appear in census and genealogy indexing, airline and
hotel passenger matching, spell-check suggestions, search engines,
fraud / identity resolution, and any system that must tolerate surname
spelling variation.

## License

Educational reference implementation for the RobertBoettcherSF Ada
algorithm series. Adapt freely with attribution.
