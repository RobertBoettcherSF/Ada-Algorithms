# Boyer–Moore String Search — Ada 2023

Educational, self-contained Ada 2023 package implementing the
[Boyer–Moore string-search algorithm](https://en.wikipedia.org/wiki/Boyer–Moore_string-search_algorithm)
(Boyer & Moore, 1977) — the classic **right-to-left** exact matcher that
shifts each alignment by the **maximum** of the **bad-character** and
**good-suffix** rules. In practice the average number of character
inspections is often **sublinear** in the text length ($O(n/m)$ best
case on large alphabets).

Part of the **RobertBoettcherSF** Ada algorithm series. Sibling packages:
[Horspool](https://github.com/RobertBoettcherSF/Ada-Horspool) (simplified
bad-character only) and
[Zhu–Takaoka](https://github.com/RobertBoettcherSF/Ada-Zhu-Takaoka)
(digram bad-character + the same good-suffix table).

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

## Bad-character and good-suffix

Each attempt aligns a window of length $m$ on the text and compares
**from the right end of the pattern toward the left**. On the first
mismatch (or after a full match) two independent shifts are looked up;
the window advances by their maximum:

$$
\text{shift} = \max\bigl(\mathrm{bmGs}[i],\ \mathrm{bmBc}[T[j+i]] - m + 1 + i\bigr).
$$

| Rule | Idea |
| --- | --- |
| **Bad-character** (`bmBc`) | Align the mismatched text character with its rightmost occurrence in the pattern proper; if it never occurs, slide the window entirely past it |
| **Good-suffix** (`bmGs`) | Re-align the already-matched suffix of the pattern with its next plausible occurrence (or the longest border that is a prefix) |

After a full match the window advances by $\mathrm{bmGs}[0]$ (the period
of the pattern), so **overlapping** hits are still reported.

Reference implementation notes:
[Charras & Lecroq — Boyer–Moore](http://www-igm.univ-mlv.fr/~lecroq/string/node14.html).

## Complexity

| Phase | Time | Space |
| --- | --- | --- |
| **Preprocess** (`Build_Bad_Character`, `Build_Good_Suffix`) | $O(m + \lvert\Sigma\rvert)$ | $O(m + \lvert\Sigma\rvert)$ |
| **Search (worst)** | $O(n\cdot m)$ | $O(m + \lvert\Sigma\rvert)$ |
| **Search (typical / best)** | Often sublinear; $O(n/m)$ comparisons in favourable cases | same |

This package uses the full 8-bit `Character` alphabet
($\lvert\Sigma\rvert = 256$).

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Bad character** | `bmBc[c]` occurrence table | Exported via `Build_Bad_Character` |
| **Good suffix** | Lecroq `bmGs` + `suff` | Exported via `Build_Good_Suffix` |
| **Scan** | Right-to-left per window | Report every hit (overlaps allowed) |
| **Oracle** | `Naive_Search` | Brute-force for tests |
| **Alphabet** | `Character'Pos` → $0..255$ | Documented educational bound |
| **Empty pattern** | `Invalid_Argument` | Empty text → no matches |

## API

| Subprogram / type | Role |
| --- | --- |
| `Search (Pattern, Text)` | Boyer–Moore; returns `Match_Index_Array` of 1-based starts |
| `Naive_Search (Pattern, Text)` | Linear oracle; same result contract |
| `Build_Bad_Character (Pattern)` | `Bad_Character_Table` over $0..255$ |
| `Build_Good_Suffix (Pattern)` | `Good_Suffix_Array` bounds $0..m-1$ |
| `Match_Index_Array` | `array (Positive range <>) of Positive` |
| `Bad_Character_Table` | `array (Alphabet_Index) of Natural` |
| `Good_Suffix_Array` | `array (Natural range <>) of Natural` |
| `Invalid_Argument` | Empty pattern or length above `Max_*_Length` |
| `Alphabet_Size` | $256$ (bad-character extent) |
| `Max_Pattern_Length` / `Max_Text_Length` | Educational caps |

Positions are 1-based offsets into `Text` viewed as `1 .. Text'Length`.
Overlapping matches are reported in ascending order.

## Build / test

```bash
make        # gnatmake -gnatwa -gnat2022 -Pboyer_moore.gpr
make test   # prints Results: N PASS, 0 FAIL
```

Requires GNAT with Ada 2022 support. Object files land in `obj/`, the
test binary in `bin/tests`.

## References

- [Wikipedia: Boyer–Moore string-search algorithm](https://en.wikipedia.org/wiki/Boyer–Moore_string-search_algorithm)
- Boyer, R. S.; Moore, J S. (1977). “A fast string searching algorithm.” *Communications of the ACM* 20(10):762–772.
- Rytter, W. (1980). Corrected construction of the good-suffix table.
- Charras, C.; Lecroq, T. *Exact String Matching Algorithms* — Boyer–Moore chapter.
