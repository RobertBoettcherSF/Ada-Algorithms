# Boyer–Moore–Horspool String Search — Ada 2023

Educational, self-contained Ada 2023 package implementing the
[Boyer–Moore–Horspool algorithm](https://en.wikipedia.org/wiki/Boyer–Moore–Horspool_algorithm)
(Nigel Horspool, 1980 — also called **Simplified Boyer–Moore** / SBM).
It is the **bad-character-only** simplification of classic
[Boyer–Moore](https://en.wikipedia.org/wiki/Boyer–Moore_string-search_algorithm):
each alignment window is compared (typically right-to-left), then the
window always advances by a shift keyed on the **text character aligned
under the last pattern character**. There is **no good-suffix table**.

Part of the **RobertBoettcherSF** Ada algorithm series. Sibling package:
[Ada-Boyer-Moore](https://github.com/RobertBoettcherSF/Ada-Boyer-Moore)
(full bad-character + good-suffix).

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

## Horspool vs full Boyer–Moore

| Aspect | Boyer–Moore–Horspool (this package) | Full Boyer–Moore |
| --- | --- | --- |
| **Shift rules** | Bad-character / skip table only | $\max(\mathrm{bmGs}[i],\ \mathrm{bmBc}[\cdot]-m+1+i)$ |
| **Character that keys the shift** | Always the text char under the **last** pattern position | The mismatched text character (plus good-suffix) |
| **Tables** | One table of size $\lvert\Sigma\rvert$ | Bad-character + good-suffix ($O(m)$) |
| **Preprocess** | $O(m + \lvert\Sigma\rvert)$ | $O(m + \lvert\Sigma\rvert)$ (extra $O(m)$ for `bmGs`) |
| **Worst case** | $O(n\cdot m)$ (same order as naive `memcmp`) | Still $O(n\cdot m)$, but good-suffix often helps more |
| **Typical use** | Simpler code, lower constant overhead | Stronger shifts when long suffixes match |

Horspool’s insight: looking up the shift from the character already under
the pattern’s rightmost cell is enough to get **average-case $O(n)$**
behaviour on random text, while dropping the more intricate good-suffix
construction.

After every attempt — whether the window matched or not — advance by:

$$
j \leftarrow j + \mathrm{bmBc}\bigl[T[j+m-1]\bigr].
$$

Reference notes:
[Charras & Lecroq — Horspool](http://www-igm.univ-mlv.fr/~lecroq/string/node18.html).

## Skip (bad-character) table

For pattern length $m$ and alphabet size $\lvert\Sigma\rvert = 256$:

1. Initialise every entry to $m$.
2. For each index $i$ in $0 .. m-2$ (the last pattern character is
   **excluded**), set
   $\mathrm{bmBc}[P[i]] \leftarrow m-1-i$
   (later writes win → rightmost usable occurrence).

Characters that never appear in the pattern proper keep shift $m$, so the
window slides entirely past them when they sit under the last cell.

## Complexity

| Phase | Time | Space |
| --- | --- | --- |
| **Preprocess** (`Build_Bad_Character`) | $O(m + \lvert\Sigma\rvert)$ | $O(\lvert\Sigma\rvert)$ |
| **Search (worst)** | $O(n\cdot m)$ | $O(\lvert\Sigma\rvert)$ |
| **Search (average / random text)** | Often $O(n)$ | same |

Best case resembles full Boyer–Moore (large alphabet, rare last-byte
hits); the worst case is easier to provoke than for full BM when the
last pattern byte also occurs earlier (shift of 1) and long prefixes
match.

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Skip table** | Horspool `bmBc` | Exported via `Build_Bad_Character` |
| **Scan** | Compare window; always shift on last-cell char | Report every hit (overlaps allowed) |
| **Oracle** | `Naive_Search` | Brute-force for tests |
| **Alphabet** | `Character'Pos` → $0..255$ | Documented educational bound |
| **Empty pattern** | `Invalid_Argument` | Empty text → no matches |
| **No good-suffix** | — | Contrast with full Boyer–Moore sibling |

## API

| Subprogram / type | Role |
| --- | --- |
| `Search (Pattern, Text)` | Horspool; returns `Match_Index_Array` of 1-based starts |
| `Naive_Search (Pattern, Text)` | Linear oracle; same result contract |
| `Build_Bad_Character (Pattern)` | `Bad_Character_Table` over $0..255$ |
| `Match_Index_Array` | `array (Positive range <>) of Positive` |
| `Bad_Character_Table` | `array (Alphabet_Index) of Natural` |
| `Invalid_Argument` | Empty pattern or length above `Max_*_Length` |
| `Alphabet_Size` | $256$ (skip-table extent) |
| `Max_Pattern_Length` / `Max_Text_Length` | Educational caps |

Positions are 1-based offsets into `Text` viewed as `1 .. Text'Length`.
Overlapping matches are reported in ascending order.

## Build / test

```bash
make        # gnatmake -gnatwa -gnat2022 -Pboyer_moore_horspool.gpr
make test   # prints Results: N PASS, 0 FAIL
```

Requires GNAT with Ada 2022 support. Object files land in `obj/`, the
test binary in `bin/tests`.

## References

- [Wikipedia: Boyer–Moore–Horspool algorithm](https://en.wikipedia.org/wiki/Boyer–Moore–Horspool_algorithm)
- Horspool, R. N. (1980). “Practical fast searching in strings.” *Software: Practice and Experience* 10(6):501–506.
- Boyer, R. S.; Moore, J S. (1977). “A fast string searching algorithm.” *Communications of the ACM* 20(10):762–772.
- Charras, C.; Lecroq, T. *Exact String Matching Algorithms* — Horspool chapter.
