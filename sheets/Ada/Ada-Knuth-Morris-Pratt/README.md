# Knuth–Morris–Pratt String Search — Ada 2023

Educational, self-contained Ada 2023 package implementing the
[Knuth–Morris–Pratt algorithm](https://en.wikipedia.org/wiki/Knuth–Morris–Pratt_algorithm)
(Knuth, Morris & Pratt, 1977) — exact string matching in **$O(n+m)$**
time using a **partial-match / LPS / $\pi$ (failure) table** so the
text cursor never rewinds.

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

## Partial-match table intuition

A naive search may re-compare the same text characters after a mismatch —
worst case $O((n-m+1)\cdot m)$. KMP first studies the **pattern against
itself**. For every prefix length $i$, the LPS entry $\pi[i]$ stores the
length of the longest **proper** prefix of $P[1..i]$ that is also a
**suffix** of that prefix:

$$
\pi[i] = \max\bigl\{\,k < i : P[1..k] = P[i-k+1..i]\,\bigr\}
\quad\text{(or $0$ if none)}.
$$

During search, when $P[1..j]$ has matched and the next characters
disagree, the algorithm does **not** slide the window by one and restart.
It already knows that the matched prefix has a border of length
$\pi[j]$, so it sets the pattern cursor to $\pi[j]$ and continues —
the text index only ever moves forward. Those LPS jumps are the whole
reason KMP is linear.

Classic check: for $P = \texttt{AABAACAABABA}$,

$$
\pi = [0,1,0,1,2,0,1,2,3,4,0,1].
$$

## Complexity

| Phase | Time | Space |
| --- | --- | --- |
| **Build LPS** (`Build_LPS` / `Prefix_Table`) | $O(m)$ | $O(m)$ |
| **Search** | $O(n)$ comparisons after preprocess | $O(m)$ for the table |
| **Total** | $O(n+m)$ | $O(m)$ |

Each text character is examined at most twice in an amortized sense
(the pattern cursor falls via strictly smaller $\pi$ values). The
returned match list includes **overlapping** hits, sorted ascending.

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Preprocess** | LPS / $\pi$ / failure function | Exported for unit tests |
| **Search** | Left-to-right; LPS jumps on mismatch | Text index never rewinds |
| **Oracle** | `Naive_Search` | Brute-force for tests |
| **Empty pattern** | `Invalid_Argument` | Empty text → no matches |
| **Bounds** | `Max_Pattern_Length` / `Max_Text_Length` | Educational caps |

## API

| Subprogram / type | Role |
| --- | --- |
| `Build_LPS (Pattern)` | LPS / $\pi$ table, length $m$, `LPS(1)=0` |
| `Prefix_Table (Pattern)` | Renames `Build_LPS` (failure-function alias) |
| `Search (Pattern, Text)` | KMP; returns `Match_Index_Array` of 1-based starts |
| `Naive_Search (Pattern, Text)` | Linear oracle; same result contract |
| `Match_Index_Array` | `array (Positive range <>) of Positive` |
| `LPS_Array` | `array (Positive range <>) of Natural` |
| `Invalid_Argument` | Empty pattern or length above `Max_*_Length` |
| `Max_Pattern_Length` / `Max_Text_Length` | Educational caps |

Positions are 1-based offsets into `Text` viewed as `1 .. Text'Length`.
Overlapping matches are reported in ascending order.

## Build / test

```bash
make        # gnatmake -gnatwa -gnat2022 -Pknuth_morris_pratt.gpr
make test   # prints Results: N PASS, 0 FAIL
```

Requires GNAT with Ada 2022 support. Object files land in `obj/`, the
test binary in `bin/tests`.

## References

- [Wikipedia: Knuth–Morris–Pratt algorithm](https://en.wikipedia.org/wiki/Knuth–Morris–Pratt_algorithm)
- Knuth, D. E.; Morris, J. H., Jr.; Pratt, V. R. (1977). “Fast pattern matching in strings.” *SIAM Journal on Computing* 6(2):323–350.
- Cormen, T. H.; Leiserson, C. E.; Rivest, R. L.; Stein, C. *Introduction to Algorithms* — chapter on string matching (KMP / $\pi$ function).
