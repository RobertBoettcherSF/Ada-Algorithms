# Dice's Coefficient in Ada 2023

## Project Overview

**Dice's coefficient** (also **Sørensen–Dice coefficient**, **Dice similarity**)
measures overlap between two sets. For sets $X$ and $Y$:

$$
\mathrm{DSC}(X,Y) = \frac{2\,|X \cap Y|}{|X| + |Y|}
$$

As a **string metric**, the sets are usually the **unique character
bigrams** (overlapping length-$2$ windows) of each string. The result
lies in $[0,1]$: $1$ means identical bigram sets, $0$ means disjoint
(or empty-set edge cases below).

This package is an **Ada 2023 (ISO/IEC 8652:2023)** educational
implementation of that classical bigram Dice coefficient. Matching is
**case-sensitive** (no folding). Characters are opaque octets (Latin-1
`Character`); there is no Unicode normalization.

Primary source:
[Wikipedia — Sørensen–Dice coefficient](https://en.wikipedia.org/wiki/S%C3%B8rensen%E2%80%93Dice_coefficient).

Part of the **RobertBoettcherSF** Ada algorithm series.

## Contrast with string siblings

| Package | Idea |
| --- | --- |
| **This package** (`Ada-Dice-Coefficient`) | General string-metric Dice over **character bigrams** |
| **[Ada-Trigram-Search](https://github.com/RobertBoettcherSF/Ada-Trigram-Search)** | Overlapping **trigrams**; Dice + fuzzy containment |
| **[Ada-Jaro-Winkler-Distance](https://github.com/RobertBoettcherSF/Ada-Jaro-Winkler-Distance)** | Jaro / Jaro–Winkler similarity & distance |
| **[Ada-Levenshtein-Distance](https://github.com/RobertBoettcherSF/Ada-Levenshtein-Distance)** | Unit-cost insert/delete/substitute edit distance |

README links only — **no** package `with` of siblings. This sheet is the
general bigram Dice metric; it is **not** a duplicate of trigram search.

## Algorithm

### Character bigrams

Given a string $S$ of length $n = |S|$ (Ada indices
$S'\mathit{First} \ldots S'\mathit{Last}$):

1. If $n < 2$, $S$ has **no** bigram windows (empty set $T_S$).
2. Otherwise the overlapping windows are
   $S(i..i+1)$ for $i = S'\mathit{First} \ldots S'\mathit{Last}-1$.
3. Occurrence count: $\max(0, n-1)$.
4. This package prefers the **unique set** $T_S$ of those windows
   (educational Dice string-metric standard). Repeated identical
   windows collapse to one set element (e.g. `"aaa"` has two
   occurrences of `"aa"` but $|T_S| = 1$).

If $n > \mathrm{Max\_Len}$, every entry point raises `Invalid_Argument`.

### Shared bigrams and Dice

$$
|T_A \cap T_B|
\qquad
\mathrm{DSC}(A,B) = \frac{2\,|T_A \cap T_B|}{|T_A| + |T_B|}
$$

Edge cases for `Coefficient` (evaluated with / before the formula):

- Both empty ($|A| = |B| = 0$) → $1.0$
- Exactly one empty, **or** denominator $|T_A|+|T_B| = 0$ → $0.0$
  (includes two nonempty length-$<2$ strings such as `"a"` vs `"b"`)
- Otherwise the formula; result lies in $[0,1]$

Identical strings of length $\ge 2$ yield $1.0$. Disjoint bigram sets
yield $0.0$.

### Relation to Jaccard

The Jaccard index over the same unique bigram sets is

$$
J = \frac{|T_A \cap T_B|}{|T_A \cup T_B|}
$$

when the union is nonempty. Dice and Jaccard are monotone transforms of
each other:

$$
\mathrm{DSC} = \frac{2J}{1+J}
\qquad
J = \frac{\mathrm{DSC}}{2 - \mathrm{DSC}}
$$

(when defined). This package exposes Dice only; the identity is useful
when comparing against Jaccard-based literature.

### Binary / set form (context)

For binary feature vectors, Dice is often written
$2\,\mathrm{TP}/(2\,\mathrm{TP}+\mathrm{FP}+\mathrm{FN})$. That is the
same set formula with positive-feature sets. This package implements the
string / bigram form above.

### Example

$A = \texttt{night}$, $B = \texttt{nacht}$:

- $T_A = \{\texttt{ni},\texttt{ig},\texttt{gh},\texttt{ht}\}$
- $T_B = \{\texttt{na},\texttt{ac},\texttt{ch},\texttt{ht}\}$
- $|T_A \cap T_B| = 1$ (`ht`)
- $\mathrm{DSC}(A,B) = 2\cdot 1 / (4+4) = 0.25$

Another classic pair: $A = \texttt{cheese}$, $B = \texttt{chese}$:

- $T_A = \{\texttt{ch},\texttt{he},\texttt{ee},\texttt{es},\texttt{se}\}$ ($5$)
- $T_B = \{\texttt{ch},\texttt{he},\texttt{es},\texttt{se}\}$ ($4$)
- $|T_A \cap T_B| = 4$
- $\mathrm{DSC}(A,B) = 8/9 \approx 0.88889$

## Complexity

| Measure | Bound |
| ------- | ----- |
| Extract / count | $O(n)$ windows |
| Uniquify (educational linear scan) | $O(u \cdot n)$ with $u \le n-1$ |
| Intersection | $O(|T_A|\cdot|T_B|)$ |
| Auxiliary space | $O(n)$ unique buffers |
| Capacity | each $\|\,\cdot\,\| \le \mathrm{Max\_Len}=10000$ |

## Features

- **`Bigram_Count`** — occurrence windows $\max(0, n-1)$.
- **`Unique_Bigram_Count`** — $|T_S|$ of the unique bigram set.
- **`Shared_Bigrams`** — $|T_A \cap T_B|$.
- **`Coefficient`** — $2|T_A \cap T_B| / (|T_A|+|T_B|)$ with documented edges.
- **Capacity guard** — `Invalid_Argument` when length $> \mathrm{Max\_Len}$.
- **Arbitrary `String'First`** — slices work.
- **Case-sensitive** — no folding; opaque `Character` comparison.
- **Zero-warning build** — `gnatmake -gnatwa -gnat2022 -Pdice_coefficient.gpr`.

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

=== 1. Bigram_Count — empty and short ===
  PASS: ...
...
Results:  NN PASS, 0 FAIL
```

(Exact `NN` is the current suite size; it is at least 120.)

## Testing

The test suite in `tests.adb` covers:

- Empty/empty and empty/nonempty coefficients and counts
- Short strings (length $< 2$) → empty bigram sets
- Identical strings (including repeats and length ladders)
- Known overlaps (`night`/`nacht`, `cheese`/`chese`, shared tails/heads)
- Bounds in $[0,1]$; Float epsilon comparisons
- Symmetry and reflexivity
- Occurrences vs unique (multiset contrast, e.g. `"aaa"`)
- Case sensitivity; spaces, digits, punctuation; Latin-1 octets
- Non-1 `String'First` slices
- Formula cross-checks: $2\cdot\mathrm{Shared}/(\mathrm{Unique}_A+\mathrm{Unique}_B)$
- Modest sizes and `Max_Len` boundary acceptance / rejection
- Jaccard relation spot checks: $\mathrm{DSC}=2J/(1+J)$

## Building

- Prerequisites: GNAT compiler supporting Ada 2022 / Ada 2023 (e.g. GNAT FSF
  13+, GNAT 14+, or GNAT Pro).
- Standard: ISO/IEC 8652:2023.
- Build flag: `-gnatwa -gnat2022` with zero compiler warnings.

## API

```ada
package Dice_Coefficient is
   Max_Len : constant Positive := 10_000;
   Invalid_Argument : exception;

   function Bigram_Count (S : String) return Natural;
   function Unique_Bigram_Count (S : String) return Natural;
   function Shared_Bigrams (A, B : String) return Natural;
   function Coefficient (A, B : String) return Float;
end Dice_Coefficient;
```

Raises `Invalid_Argument` if any input length exceeds `Max_Len`.

## License

Educational reference implementation. See repository `LICENSE` if present.
