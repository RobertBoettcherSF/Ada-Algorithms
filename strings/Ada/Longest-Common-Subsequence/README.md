# Longest common subsequence — Ada 2023

Educational, self-contained Ada 2023 package for the **longest common
subsequence problem**: find a longest sequence that appears in both inputs
$A$ and $B$ in the same order, but **not necessarily contiguously**. See
[Wikipedia: Longest common subsequence problem](https://en.wikipedia.org/wiki/Longest_common_subsequence_problem).

This package is a **classroom sketch** of the classic dynamic-programming
table with Wikipedia-style backtracking to recover one witness, plus a
two-row space-optimized length routine. It is **not** a production string
library (Hirschberg / Hunt–Szymanski / Myers are better for long diffs).

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Part of the **RobertBoettcherSF** Ada algorithm series.

## Subsequence vs substring

| Problem | Contiguous? | Typical DP idea |
| --- | --- | --- |
| **This package** (subsequence / LCS) | No — characters may skip | $L(i,j)=L(i-1,j-1)+1$ on match, else $\max(L(i-1,j),L(i,j-1))$ |
| Longest common **substring** (LCSS) | Yes — one unbroken fragment | $L(i,j)=L(i-1,j-1)+1$ on match, else $0$ |

Sibling package: `Ada-Longest-Common-Substring` (contiguous LCSS only).

## Example (Wikipedia)

For $R=$ `GAC` and $C=$ `AGCAT`, the longest common subsequences have
length $2$: `AC`, `GC`, and `GA`. This package's `Find ("AGCAT", "GAC")`
returns `AC` under the documented tie-break (see below).

Another classic pair: `ABCD` / `ACBAD` share length-$3$ LCS witnesses
`ABD` and `ACD`.

## DP recurrence

Let $A$ have length $m$ and $B$ have length $n$. Define $L(i,j)$ as the
LCS length of the prefixes $A[1..i]$ and $B[1..j]$:

$$
L(i,j) =
\begin{cases}
0 & \text{if } i=0 \text{ or } j=0 \\
L(i-1,j-1)+1 & \text{if } A[i]=B[j] \\
\max\bigl(L(i-1,j),\, L(i,j-1)\bigr) & \text{otherwise}
\end{cases}
$$

The answer length is $L(m,n)$. One witness is recovered by walking from
$(m,n)$ toward $(0,0)$: on a match, emit $A[i]$ and step diagonally;
otherwise step to the neighbour with the larger $L$ value.

**Complexity.** Filling the table costs $\Theta(mn)$ time and
$\Theta(mn)$ space (here a fixed educational bound
`Max_Length = 512`). `Length_Space_Optimized` keeps only two rolling rows
($\Theta(\min(m,n))$ auxiliary space) for the length alone. Wikipedia
also notes Hirschberg's algorithm, which reconstructs a witness in
linear space.

**Tie-breaking (`Find`).** When $L(i,j-1)$ and $L(i-1,j)$ are equal, this
package prefers moving **up** (discard $A[i]$) and moves **left** only
when $L(i,j-1) > L(i-1,j)$. That matches the Wikipedia backtrack
pseudocode and fixes which of several length-maximal LCS strings is
returned.

## Diff / edit distance

LCS is the backbone of classical `diff` / revision-control merge logic:
unchanged lines form a common subsequence of the two file versions.
When only insertions and deletions are allowed (or substitution costs
twice as much as insert/delete), the edit distance is

$$
d'(A,B) = |A| + |B| - 2\cdot |LCS(A,B)|.
$$

(The shortest common supersequence length is $|A|+|B|-|LCS(A,B)|$.)

## API sketch

| Operation | Role |
| --- | --- |
| `Length (A, B)` | LCS length ($\Theta(mn)$ DP) |
| `Find (A, B)` | One LCS string (backtrack; tie-break above) |
| `Length_Space_Optimized (A, B)` | Same length, two-row space |
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
