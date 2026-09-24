# Zhu–Takaoka String Matching — Ada 2023

Educational, self-contained Ada 2023 package implementing the
[Zhu–Takaoka string matching algorithm](https://en.wikipedia.org/wiki/Zhu–Takaoka_string_matching_algorithm)
(Zhu & Takaoka, 1987) — a **Boyer–Moore** variant that replaces the
single-character bad-character rule with a **digram** (two consecutive
text characters) shift table.

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

## Relation to Boyer–Moore

Classic Boyer–Moore scans each alignment window **right to left** and
shifts using the maximum of:

- **bad-character** shift for the mismatched text character, and
- **good-suffix** shift for the matched suffix of the pattern.

Zhu–Takaoka keeps the same right-to-left scan and the same
**good-suffix** table (`bmGs`), but builds a **two-dimensional**
bad-character table `ZT[a][b]` indexed by a digram of text characters.
On a mismatch (or after reporting a hit), the shift uses the digram
formed by the last two characters of the current text window:

$$
\text{shift} = \max\bigl(\mathrm{bmGs}[i],\ \mathrm{ZT}[y_{j+m-2}][y_{j+m-1}]\bigr).
$$

After a full match the window advances by $\mathrm{bmGs}[0]$ (period of
the pattern), as in Boyer–Moore.

## Digram shift tradeoff

| Aspect | Effect |
| --- | --- |
| **Search** | Larger average skips when the alphabet or pattern is small — digrams discriminate better than one character |
| **Preprocess** | $O(m + \lvert\Sigma\rvert^2)$ time and $\Theta(\lvert\Sigma\rvert^2)$ space for `ZT` |
| **Alphabet** | This package uses the full 8-bit `Character` set ($\lvert\Sigma\rvert = 256$), so the digram table has $256\times 256$ entries |

Faster searching is bought with a heavier skip table; on huge alphabets
the preprocess cost dominates, which is why the Wikipedia summary notes
the algorithm is attractive when the alphabet or pattern is small.

Reference implementation notes:
[Charras & Lecroq — Zhu–Takaoka](http://www-igm.univ-mlv.fr/~lecroq/string/node20.html).

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Bad character** | Digram table `ZT[a][b]` | Rightmost safe shift for text digram $ab$ |
| **Good suffix** | Boyer–Moore `bmGs` | Same suffix / border logic as BM |
| **Scan** | Right-to-left per window | Report every hit (overlaps allowed) |
| **Oracle** | `Naive_Search` | Brute-force for tests |
| **Alphabet** | `Character'Pos` → $0..255$ | Documented educational bound |
| **Empty pattern** | `Invalid_Argument` | Empty text → no matches |

## API

| Subprogram / type | Role |
| --- | --- |
| `Search (Pattern, Text)` | Zhu–Takaoka; returns `Match_Index_Array` of 1-based starts |
| `Naive_Search (Pattern, Text)` | Linear oracle; same result contract |
| `Match_Index_Array` | `array (Positive range <>) of Positive` |
| `Invalid_Argument` | Empty pattern or length above `Max_*_Length` |
| `Alphabet_Size` | $256$ (digram table extent) |
| `Max_Pattern_Length` / `Max_Text_Length` | Educational caps |

Positions are 1-based offsets into `Text` viewed as `1 .. Text'Length`.
Patterns of length 1 skip the digram table (undefined for $m < 2$) and
use a simple linear scan.

## Build / test

```bash
make        # gnatmake -gnatwa -gnat2022 -Pzhu_takaoka.gpr
make test   # prints Results: N PASS, 0 FAIL
```

Requires GNAT with Ada 2022 support. Object files land in `obj/`, the
test binary in `bin/tests`.

## References

- [Wikipedia: Zhu–Takaoka string matching algorithm](https://en.wikipedia.org/wiki/Zhu–Takaoka_string_matching_algorithm)
- Zhu, R. F.; Takaoka, T. (1987). “On improving the average case of the Boyer-Moore string matching algorithm.” *Journal of Information Processing* 10(3):173–177.
- NIST DADS: Zhu–Takaoka (public domain summary incorporated by Wikipedia)
