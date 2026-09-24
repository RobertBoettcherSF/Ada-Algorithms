# Rabin–Karp String Search — Ada 2023

Educational, self-contained Ada 2023 package implementing the
[Rabin–Karp algorithm](https://en.wikipedia.org/wiki/Rabin–Karp_algorithm)
(Karp & Rabin, 1987) — exact string matching that filters candidate
windows with a **polynomial rolling hash**, then verifies equality
character-by-character so hash collisions never appear in the results.

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

## Rolling-hash intuition

A naive search compares the pattern of length $m$ at every text offset —
up to $O((n-m+1)\cdot m)$ character comparisons. Rabin–Karp instead
assigns each length-$m$ window a numeric fingerprint. Only when the
fingerprint matches the pattern’s hash do we spend $O(m)$ time on an
exact compare.

Treat a string $s_0 s_1 \ldots s_{m-1}$ as a base-$B$ integer modulo a
prime $Q$:

$$
H = \bigl(s_0 B^{m-1} + s_1 B^{m-2} + \cdots + s_{m-1} B^{0}\bigr) \bmod Q.
$$

After computing the first window hash, each slide reuses the previous
value: **remove** the leading character’s contribution, **shift** by
multiplying by $B$, and **add** the new trailing character:

$$
H_{\mathrm{new}} =
\bigl((H_{\mathrm{old}} - T[i]\cdot B^{m-1})\cdot B + T[i+m]\bigr) \bmod Q.
$$

That update is $O(1)$ arithmetic, independent of $m$. This package uses
`Character'Pos` as digit values, default $B = 256$ (full 8-bit alphabet)
and $Q = 1\,000\,000\,007$.

## Average vs worst case

| Regime | Complexity | Why |
| --- | --- | --- |
| **Average / expected** | $O(n+m)$ | Few hash hits → few exact compares |
| **Worst case** | $O((n-m+1)\cdot m)$ | Pathological collisions or adversarial $Q$ force a compare almost every window — same order as naive |

Exact verification on every hash hit keeps the returned match list
**collision-free**. Tiny moduli in the test suite deliberately create
collisions; `Search` still agrees with `Naive_Search`.

For **multiple patterns** of equal length, a common sketch (README-only
here) is: hash every pattern into a set / Bloom filter, then scan the
text once and probe the set with each window hash — expected
$O(n + km)$ for $k$ patterns instead of $k$ independent scans. This
package implements the single-pattern case.

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Filter** | Polynomial rolling hash mod $Q$ | Defaults exported as `Default_Base` / `Default_Modulus` |
| **Verify** | Character equality on hash hit | No false positives in results |
| **Oracle** | `Naive_Search` | Brute-force for tests |
| **Empty pattern** | `Invalid_Argument` | Empty text → no matches |
| **Bad modulus** | `Invalid_Argument` if $Q < 2$ | Optional `Base` / `Modulus` parameters |

## API

| Subprogram / type | Role |
| --- | --- |
| `Search (Pattern, Text[, Base, Modulus])` | Rabin–Karp; returns `Match_Index_Array` of 1-based starts |
| `Naive_Search (Pattern, Text)` | Linear oracle; same result contract |
| `Match_Index_Array` | `array (Positive range <>) of Positive` |
| `Invalid_Argument` | Empty pattern, length above `Max_*_Length`, or `Modulus < 2` |
| `Default_Base` / `Default_Modulus` | $256$ / $1\,000\,000\,007$ |
| `Max_Pattern_Length` / `Max_Text_Length` | Educational caps |

Positions are 1-based offsets into `Text` viewed as `1 .. Text'Length`.
Overlapping matches are reported in ascending order.

## Build / test

```bash
make        # gnatmake -gnatwa -gnat2022 -Prabin_karp.gpr
make test   # prints Results: N PASS, 0 FAIL
```

Requires GNAT with Ada 2022 support. Object files land in `obj/`, the
test binary in `bin/tests`.

## References

- [Wikipedia: Rabin–Karp algorithm](https://en.wikipedia.org/wiki/Rabin–Karp_algorithm)
- Karp, R. M.; Rabin, M. O. (1987). “Efficient randomized pattern-matching algorithms.” *IBM Journal of Research and Development* 31(2):249–260.
- Cormen, T. H.; Leiserson, C. E.; Rivest, R. L.; Stein, C. *Introduction to Algorithms* — chapter on the Rabin–Karp algorithm.
