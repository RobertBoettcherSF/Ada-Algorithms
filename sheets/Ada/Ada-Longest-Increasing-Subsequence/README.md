# Longest increasing subsequence (LIS) — Ada 2023

Educational, self-contained Ada 2023 package for the **longest increasing
subsequence** problem: given a sequence of integers, find a longest
**strictly increasing** subsequence (not necessarily contiguous). See
[Wikipedia: Longest increasing subsequence](https://en.wikipedia.org/wiki/Longest_increasing_subsequence).

This package is a **classroom sketch** of the classic $O(n^2)$ DP length
routine and the $O(n \log n)$ patience-sorting / tails method (with
predecessor reconstruction of one witness). It is **not** a production
sequence library.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Part of the **RobertBoettcherSF** Ada algorithm series.

## Example (Wikipedia)

In the first 16 terms of the binary Van der Corput sequence

$$
0, 8, 4, 12, 2, 10, 6, 14, 1, 9, 5, 13, 3, 11, 7, 15
$$

one longest increasing subsequence is $0, 2, 6, 9, 11, 15$ (length $6$).
Other length-$6$ witnesses exist (e.g. $0, 4, 6, 9, 13, 15$).

## Strict increase

This package uses **strict** inequalities: equal adjacent values do **not**
extend an increasing subsequence. A constant sequence therefore has LIS
length $1$; a strictly sorted sequence of length $n$ has LIS length $n$; a
strictly decreasing sequence has LIS length $1$.

## Contrast with LCS

| Problem | Input | Typical complexity |
| --- | --- | --- |
| **This package** (LIS) | One integer sequence | $O(n^2)$ DP or $O(n \log n)$ patience |
| Longest common **subsequence** (LCS) | Two sequences | $O(mn)$ DP |

Wikipedia notes that the LIS of a sequence $S$ is the LCS of $S$ and
$T = \mathrm{sort}(S)$. That reduction is educational contrast only —
this repo does **not** implement general LCS.

## $O(n^2)$ DP (`Length_DP`)

Let $A[1..n]$ be the input. Define $L(i)$ as the length of a longest
increasing subsequence **ending at** index $i$:

$$
L(i) = 1 + \max\big(\{0\} \cup \{ L(j) \mid j < i,\ A[j] < A[i] \}\big).
$$

The answer is $\max_i L(i)$. Time $\Theta(n^2)$, space $\Theta(n)$. Soft
classroom bound: `Max_Length_DP = 512`.

## $O(n \log n)$ patience / tails (`Length`, `Find`)

Maintain an array $M$ where $M[\ell]$ stores the index of the **smallest
tail** of any increasing subsequence of length $\ell$ found so far. For
each $A[i]$, binary-search the first $\ell$ with $A[M[\ell]] \ge A[i]$
and replace (or append). The length of $M$ in use is the LIS length.

To reconstruct one witness (`Find`), record predecessor indices $P[i]$
(the previous index in the chain ending at $i$) and walk backwards from
$M[L]$. Time $\Theta(n \log n)$, space $\Theta(n)$. Soft classroom bound:
`Max_Length = 10\,000`.

Patience sorting interprets the tails as piles: each new card is placed
on the leftmost pile whose top is $\ge$ the card (strict LIS uses
strictly smaller tops to extend). The number of piles is the LIS length
(Erdős–Szekeres / Dilworth connection on permutations).

## API sketch

| Operation | Role |
| --- | --- |
| `Length_DP (A)` | LIS length via $O(n^2)$ DP |
| `Length (A)` | LIS length via $O(n \log n)$ patience / tails |
| `Find (A)` | One strictly increasing witness of that length |
| `Invalid_Argument` | Empty input, or $n$ over the routine’s max |

`Length` and `Length_DP` agree on length for every valid input that fits
both bounds. `Find` returns one valid LIS (not necessarily unique).

Types: `Int_Array` is `array (Positive range <>) of Integer`.

## Build & test

```bash
make
make test
```

Requires GNAT with Ada 2022 support (`gnatmake -gnatwa -gnat2022`).
Expected summary line: `Results:  N PASS, 0 FAIL` with $N \ge 40$.

## License

Educational example code for the RobertBoettcherSF Ada algorithm series.
