# Longest common substring — Ada 2023

Educational, self-contained Ada 2023 package for the **longest common
substring problem**: find a longest **contiguous** string that is a
substring of both inputs $A$ and $B$. See
[Wikipedia: Longest common substring problem](https://en.wikipedia.org/wiki/Longest_common_substring_problem).

This package is a **classroom sketch** of the classic dynamic-programming
table (optionally cross-checked with a small-string brute-force oracle).
It is **not** a production string library (suffix trees / SAM are faster
for long inputs).

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Part of the **RobertBoettcherSF** Ada algorithm series.

## Substring vs subsequence

| Problem | Contiguous? | Typical DP idea |
| --- | --- | --- |
| **This package** (substring / LCSS) | Yes — one unbroken fragment | $L(i,j)=L(i-1,j-1)+1$ on match, else $0$ |
| Longest common **subsequence** (LCS) | No — characters may skip | $L(i,j)=L(i-1,j-1)+1$ on match, else $\max(L(i-1,j),L(i,j-1))$ |

README contrast only — this repo does **not** implement subsequence LCS.

Example (Wikipedia): the strings `ABABC`, `BABCA`, and `ABCBA` share the
longest common substring `ABC` of length $3$ across all three. For the
**pair** `ABABC` / `BABCA` the DP answer is `BABC` (length $4$).

## DP recurrence

Let $A$ have length $m$ and $B$ have length $n$. Define $L(i,j)$ as the
length of the longest **common suffix** of the prefixes $A[1..i]$ and
$B[1..j]$:

$$
L(i,j) =
\begin{cases}
L(i-1,j-1)+1 & \text{if } A[i]=B[j] \\
0 & \text{otherwise}
\end{cases}
$$

with $L(i,j)=1$ when a match occurs on the first row or column
($i=1$ or $j=1$). The length of a longest common substring is

$$
z = \max_{i,j} L(i,j).
$$

If the maximizing cell is $(i^\star,j^\star)$, one witness substring is
$A[i^\star-z+1\,..\,i^\star]$.

**Complexity.** Filling the table costs $\Theta(mn)$ time and
$\Theta(mn)$ space (here a fixed educational bound
`Max_Length = 256`). Wikipedia also notes suffix-tree methods in
$\Theta(m+n)$ time and memory-reduction tricks that keep only two rows.

**Tie-breaking (`Find`).** When several cells share the same maximal
$z$, this package keeps the **first** strict improvement in row-major
order over $i$ then $j$ — i.e. the match that ends at the smallest
1-based index in $A$, and among those the smallest ending index in $B$.

## API sketch

| Operation | Role |
| --- | --- |
| `Length (A, B)` | LCSS length ($\Theta(mn)$ DP) |
| `Find (A, B)` | One longest common substring (tie-break above) |
| `Brute_Force_Length (A, B)` | Small-string oracle for tests |
| `Invalid_Argument` | Raised if $\|A\|$ or $\|B\|$ exceeds `Max_Length` |

Empty inputs or no shared characters yield length $0$ and `Find = ""`.

## Build & test

```bash
make
make test
```

Requires GNAT with Ada 2022 support (`gnatmake -gnatwa -gnat2022`).

## License

Educational example code for the RobertBoettcherSF Ada algorithm series.
