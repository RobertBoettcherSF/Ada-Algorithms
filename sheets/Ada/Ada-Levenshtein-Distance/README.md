# Levenshtein Edit Distance in Ada 2023

## Project Overview

The **Levenshtein distance** (a classical **edit distance**) measures how
different two strings are: the minimum number of single-symbol edits —
**insertions**, **deletions**, or **substitutions** — needed to transform
one string into the other. In the unit-cost model each edit costs $1$.

The distance is named after Soviet mathematician Vladimir Levenshtein
(1965, coding theory). The standard quadratic dynamic program is often
associated with Wagner and Fischer's 1974 string-to-string correction
formulation.

This package is an **Ada 2023 (ISO/IEC 8652:2023)** educational
implementation of classical unit-cost Levenshtein distance on Ada
`String` / `Character` values, plus a simple normalized **Similarity**
helper. Matching is **case-sensitive** (no folding). Characters are
opaque octets (Latin-1 `Character`); there is no Unicode normalization.

Primary source:
[Wikipedia — Levenshtein distance](https://en.wikipedia.org/wiki/Levenshtein_distance).

Part of the **RobertBoettcherSF** Ada algorithm series.

## Contrast with string siblings

| Package | Idea |
| --- | --- |
| **This package** (`Ada-Levenshtein-Distance`) | Unit-cost insert/delete/substitute edit distance |
| **[Ada-Longest-Common-Subsequence](https://github.com/RobertBoettcherSF/Ada-Longest-Common-Subsequence)** | Non-contiguous shared sequence (DP) |
| **[Ada-Longest-Common-Substring](https://github.com/RobertBoettcherSF/Ada-Longest-Common-Substring)** | Contiguous shared fragment (DP) |
| **[Ada-Trigram-Search](https://github.com/RobertBoettcherSF/Ada-Trigram-Search)** | Overlapping trigrams; Dice similarity |

README links only — **no** package `with` of siblings.

When only insertions and deletions are allowed (or a substitution is
priced as delete+insert), edit cost relates to LCS length by
$|A|+|B|-2\cdot\mathrm{LCS}(A,B)$. Classical Levenshtein is cheaper when
a single substitution replaces that pair of edits.

## Algorithm

### Wagner–Fischer recurrence

Let $A$ have length $m$ and $B$ have length $n$. Define $D(i,j)$ as the
Levenshtein distance between the prefixes $A[1..i]$ and $B[1..j]$
(Ada indices are mapped to logical $1..m$ / $1..n$ so arbitrary
`String'First` works):

$$
D(i,0)=i,\qquad D(0,j)=j
$$

$$
D(i,j)=\min\begin{cases}
D(i-1,j)+1 & \text{(delete } A[i]\text{)} \\
D(i,j-1)+1 & \text{(insert } B[j]\text{)} \\
D(i-1,j-1)+\delta(A[i],B[j]) & \text{(substitute / match)}
\end{cases}
$$

where $\delta(x,y)=0$ if $x=y$ and $1$ otherwise. The answer is
$D(m,n)$.

This package fills the table with a **two-row** rolling formulation
(auxiliary space $O(\min(m,n))$) while retaining $O(mn)$ time.

If either length exceeds $\mathrm{Max\_Len}$, every entry point raises
`Invalid_Argument`.

### Similarity

$$
\mathrm{Similarity}(A,B)=\begin{cases}
1.0 & \text{if } |A|=|B|=0 \\
1-\dfrac{D(A,B)}{\max(|A|,|B|)} & \text{otherwise}
\end{cases}
$$

The result lies in $[0,1]$. Identical nonempty strings yield $1.0$.

### Example

$A=\texttt{kitten}$, $B=\texttt{sitting}$ — distance $3$:

1. $\texttt{kitten}\to\texttt{sitten}$ (substitute $\texttt{s}$ for $\texttt{k}$)
2. $\texttt{sitten}\to\texttt{sittin}$ (substitute $\texttt{i}$ for $\texttt{e}$)
3. $\texttt{sittin}\to\texttt{sitting}$ (insert $\texttt{g}$)

Another classic: $\texttt{saturday}$ / $\texttt{sunday}$ also has
distance $3$.

### Metric properties

With unit insert/delete/substitute costs, Levenshtein distance is a
metric: non-negative, zero iff the strings are equal, symmetric, and
satisfies the triangle inequality. Length bounds:

$$
\bigl||A|-|B|\bigr| \le D(A,B) \le \max(|A|,|B|)
$$

## Complexity

| Measure | Bound |
| ------- | ----- |
| Time | $O(mn)$ |
| Auxiliary space (this package) | $O(\min(m,n))$ two-row DP |
| Full matrix (README contrast) | $O(mn)$ space |
| Capacity | each $\|\,\cdot\,\| \le \mathrm{Max\_Len}=2000$ |

## Features

- **`Distance`** — classical unit-cost Levenshtein $D(A,B)$.
- **`Similarity`** — $1 - D / \max(|A|,|B|)$ with empty/empty $= 1.0$.
- **Two-row DP** — $O(\min(m,n))$ auxiliary space; shorter string on the
  inner axis.
- **Capacity guard** — `Invalid_Argument` when length $> \mathrm{Max\_Len}$.
- **Arbitrary `String'First`** — slices work.
- **Case-sensitive** — no folding; opaque `Character` comparison.
- **Zero-warning build** — `gnatmake -gnatwa -gnat2022 -Plevenshtein_distance.gpr`.

## Usage

```bash
# Build test suite
make

# Run tests
make test

# Clean artifacts
make clean
```

### Expected Output

```text
Running tests...

=== 1. Empty / empty and empty / nonempty ===
  PASS: ...
...
Results:  NN PASS, 0 FAIL
```

(Exact `NN` is the current suite size; it is at least 120.)

## Testing

The test suite in `tests.adb` covers:

- Empty/empty and empty/nonempty distances and similarities
- Identical strings
- Single insert / delete / substitute
- Known pairs (`kitten`/`sitting` $= 3$, `saturday`/`sunday` $= 3`,
  `flaw`/`lawn` $= 2`, `intention`/`execution` $= 5`)
- Prefixes, suffixes, repeated patterns
- Symmetry and triangle-inequality spot checks
- Length bounds $|m-n| \le d \le \max(m,n)$
- Case sensitivity; spaces, digits, punctuation; Latin-1 octets
- Non-1 `String'First` slices
- Similarity formula cross-checks and $[0,1]$ bounds
- Modest sizes (50–200) and `Max_Len` boundary acceptance / rejection
- Bulk letter and length-ladder micro-cases

## Building

- Prerequisites: GNAT compiler supporting Ada 2022 / Ada 2023 (e.g. GNAT FSF
  13+, GNAT 14+, or GNAT Pro).
- Standard: ISO/IEC 8652:2023.
- Build flag: `-gnatwa -gnat2022` with zero compiler warnings.

## API

```ada
package Levenshtein_Distance is
   Max_Len : constant Positive := 2_000;
   Invalid_Argument : exception;

   function Distance (A, B : String) return Natural;
   function Similarity (A, B : String) return Float;
end Levenshtein_Distance;
```

Raises `Invalid_Argument` if either input length exceeds `Max_Len`.

## License

Educational reference implementation. See repository `LICENSE` if present.
