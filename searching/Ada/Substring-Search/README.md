# Substring Search — Ada 2023 Survey

Educational, self-contained Ada 2023 survey of **exact single-pattern
[string-searching algorithms](https://en.wikipedia.org/wiki/String-searching_algorithm)**
(also called string-matching): thin sketches of **Naive**,
**Knuth–Morris–Pratt (LPS / $\pi$)**, **Rabin–Karp** (rolling hash +
verify), and **Boyer–Moore–Horspool** (simplified Boyer–Moore /
bad-character only).

Part of the **RobertBoettcherSF** Ada algorithm series. Specialized
sibling packages hold fuller treatments — this survey does **not**
`with` them; each algorithm is reimplemented here as a compact teaching
sketch.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

## Survey complexity table

Let $n = |T|$ (text / haystack), $m = |P|$ (pattern / needle),
$k = |\Sigma|$ (alphabet size).

| Method | Preprocess | Search (typical) | Worst search | Extra space | Strategy |
| --- | --- | --- | --- | --- | --- |
| **Naive** | — | $O(n+m)$ average | $O(nm)$ | $O(1)$ | Try every alignment |
| **KMP** | $O(m)$ LPS / $\pi$ | $O(n)$ | $O(n)$ | $O(m)$ | Match prefix; LPS jumps |
| **Rabin–Karp** | $O(m)$ hash | $O(n+m)$ average | $O(nm)$ | $O(1)$ | Rolling hash + verify |
| **Boyer–Moore–Horspool** | $O(m+k)$ skip | sublinear average | $O(nm)$ | $O(k)$ | Match suffix; bad-char shift |

All four return the **same** ascending list of **1-based** match starts
(overlapping hits included). An empty pattern raises `Invalid_Argument`;
empty text with a non-empty pattern yields no matches.

## Sibling specialized repos

| Algorithm | Specialized package |
| --- | --- |
| Knuth–Morris–Pratt | [Ada-Knuth-Morris-Pratt](https://github.com/RobertBoettcherSF/Ada-Knuth-Morris-Pratt) |
| Rabin–Karp | [Ada-Rabin-Karp](https://github.com/RobertBoettcherSF/Ada-Rabin-Karp) |
| Boyer–Moore | [Ada-Boyer-Moore](https://github.com/RobertBoettcherSF/Ada-Boyer-Moore) |
| Boyer–Moore–Horspool | [Ada-Boyer-Moore-Horspool](https://github.com/RobertBoettcherSF/Ada-Boyer-Moore-Horspool) |
| Zhu–Takaoka | [Ada-Zhu-Takaoka](https://github.com/RobertBoettcherSF/Ada-Zhu-Takaoka) |
| Aho–Corasick (multi-pattern) | [Ada-Aho-Corasick](https://github.com/RobertBoettcherSF/Ada-Aho-Corasick) |

## Algorithm sketches

### Naive

At each text index $i$, compare $P[1..m]$ to $T[i..i+m-1]$. Average
cost is near-linear when mismatches appear early; worst case (e.g.
$P=\texttt{aaaab}$, $T=\texttt{aaa}\ldots\texttt{aab}$) is $O(nm)$.

### Knuth–Morris–Pratt

Precompute the LPS / $\pi$ table so that for every prefix length $i$:

$$
\pi[i] = \max\bigl\{\,k < i : P[1..k] = P[i-k+1..i]\,\bigr\}
\quad\text{(or $0$ if none)}.
$$

During search the text cursor only advances; on mismatch the pattern
cursor falls back via $\pi$. Total time $O(n+m)$.

### Rabin–Karp

Treat each window as a base-$B$ polynomial modulo prime $Q$. Slide with

$$
H \leftarrow \bigl((H - T[i]\cdot B^{m-1})\cdot B + T[i+m]\bigr) \bmod Q.
$$

Hash hits are always verified character-by-character (no false positives
in the returned array).

### Boyer–Moore–Horspool

Retain only Boyer–Moore’s **bad-character** idea: after every attempt,
shift by the skip keyed on the text character aligned under the **last**
pattern character. No good-suffix table. Average case is often sublinear
in $n$.

## Project overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Oracle** | `Naive_Search` | Ground truth for tests |
| **Prefix matcher** | `KMP_Search` + `Build_LPS` | Text index never rewinds |
| **Hash matcher** | `Rabin_Karp_Search` | Rolling hash + exact verify |
| **Suffix matcher** | `Boyer_Moore_Horspool_Search` | Horspool skip table |
| **Dispatcher** | `Search (Pattern, Text, Method)` | `Search_Method` enum |
| **Empty pattern** | `Invalid_Argument` | Empty text → no matches |
| **Bounds** | `Max_Pattern_Length` / `Max_Text_Length` | Educational caps |

## API

| Subprogram / type | Role |
| --- | --- |
| `Naive_Search (Pattern, Text)` | Brute-force oracle |
| `KMP_Search (Pattern, Text)` | Knuth–Morris–Pratt |
| `Rabin_Karp_Search (Pattern, Text [, Base, Modulus])` | Rolling hash + verify |
| `Boyer_Moore_Horspool_Search (Pattern, Text)` | Horspool / simplified BM |
| `Search (Pattern, Text, Method)` | Dispatcher (`Naive` default) |
| `Build_LPS (Pattern)` | LPS / $\pi$ table |
| `Build_Bad_Character (Pattern)` | Horspool skip table |
| `Match_Index_Array` | `array (Positive range <>) of Positive` |
| `LPS_Array` | `array (Positive range <>) of Natural` |
| `Bad_Character_Table` | Skip table over `Character'Pos` |
| `Search_Method` | `Naive`, `KMP`, `Rabin_Karp`, `Boyer_Moore_Horspool` |
| `Invalid_Argument` | Empty pattern / length / modulus errors |

Positions are 1-based offsets into `Text` viewed as `1 .. Text'Length`.

## Build / test

```bash
make        # gnatmake -gnatwa -gnat2022 -Psubstring_search.gpr
make test   # prints Results:  N PASS, 0 FAIL
```

Requires GNAT with Ada 2022 support. Object files land in `obj/`, the
test binary in `bin/tests`.

## References

- [Wikipedia: String-searching algorithm](https://en.wikipedia.org/wiki/String-searching_algorithm)
- [Wikipedia: Knuth–Morris–Pratt algorithm](https://en.wikipedia.org/wiki/Knuth–Morris–Pratt_algorithm)
- [Wikipedia: Rabin–Karp algorithm](https://en.wikipedia.org/wiki/Rabin–Karp_algorithm)
- [Wikipedia: Boyer–Moore–Horspool algorithm](https://en.wikipedia.org/wiki/Boyer–Moore–Horspool_algorithm)
- Knuth, D. E.; Morris, J. H., Jr.; Pratt, V. R. (1977). “Fast pattern matching in strings.” *SIAM Journal on Computing*.
- Karp, R. M.; Rabin, M. O. (1987). “Efficient randomized pattern-matching algorithms.” *IBM Journal of Research and Development*.
- Horspool, R. N. (1980). “Practical fast searching in strings.” *Software: Practice and Experience*.
- Cormen, T. H.; Leiserson, C. E.; Rivest, R. L.; Stein, C. *Introduction to Algorithms* — string matching chapter.
