# Damerau–Levenshtein (OSA) Edit Distance in Ada 2023

## Project Overview

The **Damerau–Levenshtein distance** extends classical **Levenshtein** edit
distance by allowing a fourth unit-cost operation: **transposition of two
adjacent characters**, in addition to **insertions**, **deletions**, and
**substitutions**. Each of the four operations costs $1$ in the unit-cost
model used here.

This package implements the educational **optimal string alignment (OSA)**
variant — also called **restricted Damerau–Levenshtein** — in which
**each substring may participate in at most one edit**. OSA is the common
quadratic DP taught alongside Wagner–Fischer; it is **not** the unrestricted
Damerau–Levenshtein metric (see below).

Named after Frederick J. Damerau (1964, spelling-error taxonomy) and
Vladimir Levenshtein (1965). Damerau observed that more than 80% of
human misspellings were a single instance of one of the four edit types.

This package is an **Ada 2023 (ISO/IEC 8652:2023)** educational
implementation on Ada `String` / `Character` values, plus a simple
normalized **Similarity** helper. Matching is **case-sensitive** (no
folding). Characters are opaque octets (Latin-1 `Character`); there is
no Unicode normalization.

Primary source:
[Wikipedia — Damerau–Levenshtein distance](https://en.wikipedia.org/wiki/Damerau%E2%80%93Levenshtein_distance).

Part of the **RobertBoettcherSF** Ada algorithm series.

## OSA vs unrestricted Damerau–Levenshtein

| Variant | Constraint | Example $\texttt{CA}$ / $\texttt{ABC}$ |
| --- | --- | --- |
| **OSA (this package)** | No substring edited more than once | $\mathrm{OSA}=3$: $\texttt{CA}\to\texttt{A}\to\texttt{AB}\to\texttt{ABC}$ |
| **Unrestricted DL** | Same four ops; substrings may be re-edited | $\mathrm{DL}=2$: $\texttt{CA}\to\texttt{AC}\to\texttt{ABC}$ |

OSA is **not** a true metric: the triangle inequality can fail, e.g.
$\mathrm{OSA}(\texttt{CA},\texttt{AC})+\mathrm{OSA}(\texttt{AC},\texttt{ABC})
<\mathrm{OSA}(\texttt{CA},\texttt{ABC})$. Unrestricted DL (with adjacent
transpositions) is a metric but needs a more involved algorithm. This
educational package implements **OSA only**.

## Contrast with plain Levenshtein

| Pair | Classical Levenshtein | OSA (this package) |
| --- | --- | --- |
| $\texttt{ab}$ / $\texttt{ba}$ | $2$ (two substitutes, or delete+insert) | $1$ (one adjacent transposition) |
| $\texttt{kitten}$ / $\texttt{sitting}$ | $3$ | $3$ (no useful transposition) |
| $\texttt{ca}$ / $\texttt{abc}$ | $3$ | $3$ (OSA; unrestricted DL would be $2$) |

Sibling package (README link only — **no** package `with`):
**[Ada-Levenshtein-Distance](https://github.com/RobertBoettcherSF/Ada-Levenshtein-Distance)**
(unit-cost insert/delete/substitute only).

## Contrast with string siblings

| Package | Idea |
| --- | --- |
| **This package** (`Ada-Damerau-Levenshtein-Distance`) | OSA: insert/delete/substitute/**adjacent transpose** |
| **[Ada-Levenshtein-Distance](https://github.com/RobertBoettcherSF/Ada-Levenshtein-Distance)** | Unit-cost insert/delete/substitute only |
| **[Ada-Longest-Common-Subsequence](https://github.com/RobertBoettcherSF/Ada-Longest-Common-Subsequence)** | Non-contiguous shared sequence (DP) |
| **[Ada-Longest-Common-Substring](https://github.com/RobertBoettcherSF/Ada-Longest-Common-Substring)** | Contiguous shared fragment (DP) |
| **[Ada-Trigram-Search](https://github.com/RobertBoettcherSF/Ada-Trigram-Search)** | Overlapping trigrams; Dice similarity |

README links only — **no** package `with` of siblings.

## Algorithm

### Optimal string alignment recurrence

Let $A$ have length $m$ and $B$ have length $n$. Define $D(i,j)$ as the
OSA distance between the prefixes $A[1..i]$ and $B[1..j]$
(Ada indices are mapped to logical $1..m$ / $1..n$ so arbitrary
`String'First` works):

$$
D(i,0)=i,\qquad D(0,j)=j
$$

$$
D(i,j)=\min\begin{cases}
D(i-1,j)+1 & \text{(delete } A[i]\text{)} \\
D(i,j-1)+1 & \text{(insert } B[j]\text{)} \\
D(i-1,j-1)+\delta(A[i],B[j]) & \text{(substitute / match)} \\
D(i-2,j-2)+\delta(A[i],B[j]) & \text{(adjacent transposition, when applicable)}
\end{cases}
$$

where $\delta(x,y)=0$ if $x=y$ and $1$ otherwise. The transposition
candidate is considered only when $i>1$, $j>1$, $A[i]=B[j-1]$, and
$A[i-1]=B[j]$. The answer is $D(m,n)$.

This package fills the table with a **three-row** rolling formulation
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

$A=\texttt{ab}$, $B=\texttt{ba}$ — OSA distance $1$ (transpose the two
characters). Classical Levenshtein needs $2$.

$A=\texttt{kitten}$, $B=\texttt{sitting}$ — distance $3$ (same script as
Levenshtein; transposition does not help):

1. $\texttt{kitten}\to\texttt{sitten}$ (substitute $\texttt{s}$ for $\texttt{k}$)
2. $\texttt{sitten}\to\texttt{sittin}$ (substitute $\texttt{i}$ for $\texttt{e}$)
3. $\texttt{sittin}\to\texttt{sitting}$ (insert $\texttt{g}$)

$A=\texttt{CA}$, $B=\texttt{ABC}$ — OSA distance $3$ (unrestricted DL is $2$).

### Metric note

OSA does **not** always satisfy the triangle inequality, so it is not a
metric. Length-style bounds still hold in practice for many pairs:

$$
\bigl||A|-|B|\bigr| \le D(A,B) \le \max(|A|,|B|)
$$

and always $D_{\mathrm{OSA}}(A,B) \le D_{\mathrm{Levenshtein}}(A,B)$.

## Complexity

| Measure | Bound |
| ------- | ----- |
| Time | $O(mn)$ |
| Auxiliary space (this package) | $O(\min(m,n))$ three-row DP |
| Full matrix (README contrast) | $O(mn)$ space |
| Capacity | each $\|\,\cdot\,\| \le \mathrm{Max\_Len}=2000$ |

## Features

- **`Distance`** — OSA / restricted Damerau–Levenshtein $D(A,B)$.
- **`Similarity`** — $1 - D / \max(|A|,|B|)$ with empty/empty $= 1.0$.
- **Three-row DP** — $O(\min(m,n))$ auxiliary space; shorter string on the
  inner axis.
- **Adjacent transposition** — unit cost $1$, OSA single-edit restriction.
- **Capacity guard** — `Invalid_Argument` when length $> \mathrm{Max\_Len}$.
- **Arbitrary `String'First`** — slices work.
- **Case-sensitive** — no folding; opaque `Character` comparison.
- **Zero-warning build** — `gnatmake -gnatwa -gnat2022 -Pdamerau_levenshtein_distance.gpr`.

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
- **Adjacent transposition pairs** (`ab`/`ba` $= 1$, `plauge`/`plague` $= 1$, …)
- OSA vs unrestricted DL marker: `ca`/`abc` $= 3$
- Known Levenshtein pairs that remain valid (`kitten`/`sitting` $= 3$, …)
- Symmetry spot checks; length bounds
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
package Damerau_Levenshtein_Distance is
   Max_Len : constant Positive := 2_000;
   Invalid_Argument : exception;

   function Distance (A, B : String) return Natural;
   --  OSA / restricted DL (insert, delete, substitute, adjacent transpose)

   function Similarity (A, B : String) return Float;
end Damerau_Levenshtein_Distance;
```

Raises `Invalid_Argument` if either input length exceeds `Max_Len`.

## License

Educational reference implementation. See repository `LICENSE` if present.
