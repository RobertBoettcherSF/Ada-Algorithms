# Jaro–Winkler Distance in Ada 2023

## Project Overview

The **Jaro similarity** is a string metric for comparing short strings
(especially names in record linkage). **Jaro–Winkler** extends Jaro with a
**common-prefix boost**: strings that share a leading prefix are scored
more favourably. The boost uses a prefix scale $p$ (default $0.1$) and a
prefix length $\ell$ capped at $4$.

The **Jaro–Winkler distance** is the inversion of similarity:

$$
d_w = 1 - \mathrm{sim}_w
$$

so $0$ means an exact match and $1$ means no similarity. Although often
called a distance metric, Jaro–Winkler is **not** a metric in the
mathematical sense (it need not obey the triangle inequality).

This package is an **Ada 2023 (ISO/IEC 8652:2023)** educational
implementation of classical Jaro similarity and Jaro–Winkler
similarity/distance on Ada `String` / `Character` values. Matching is
**case-sensitive** (no folding). Characters are opaque octets (Latin-1
`Character`); there is no Unicode normalization.

Primary source:
[Wikipedia — Jaro–Winkler distance](https://en.wikipedia.org/wiki/Jaro%E2%80%93Winkler_distance).

Part of the **RobertBoettcherSF** Ada algorithm series.

## Contrast with string siblings

| Package | Idea |
| --- | --- |
| **This package** (`Ada-Jaro-Winkler-Distance`) | Jaro / Jaro–Winkler similarity & distance |
| **[Ada-Levenshtein-Distance](https://github.com/RobertBoettcherSF/Ada-Levenshtein-Distance)** | Unit-cost insert/delete/substitute edit distance |
| **[Ada-Trigram-Search](https://github.com/RobertBoettcherSF/Ada-Trigram-Search)** | Overlapping trigrams; Dice similarity |
| **[Ada-Longest-Common-Subsequence](https://github.com/RobertBoettcherSF/Ada-Longest-Common-Subsequence)** | Non-contiguous shared sequence (DP) |

README links only — **no** package `with` of siblings.

## Algorithm

### Matching window

Two characters from $A$ and $B$ match only if they are equal and not
farther than

$$
w = \left\lfloor \frac{\max(|A|,|B|)}{2} \right\rfloor - 1
$$

positions apart. Each character is consumed at most once (greedy left-to-
right matching).

**Short strings:** when $\max(|A|,|B|) \le 1$, the formula yields $w = -1$.
This package clamps $w$ to $\max(0,\,\cdot)$ so identical length-$1$
strings still match at the same index (distance $0$). Document this when
comparing against implementations that omit the clamp and rely only on an
early identity check.

### Jaro similarity

Let $m$ be the number of matching characters and $t$ the number of
**transpositions** (half the number of matched characters that are out of
order). Then

$$
\mathrm{sim}_j =
\begin{cases}
0 & \text{if } m = 0 \\
\dfrac{1}{3}\left(\dfrac{m}{|A|} + \dfrac{m}{|B|} + \dfrac{m - t}{m}\right)
  & \text{otherwise}
\end{cases}
$$

Edge cases in this package: both empty $\to 1.0$; exactly one empty
$\to 0.0$; identical nonempty $\to 1.0$.

### Jaro–Winkler similarity

$$
\mathrm{sim}_w = \mathrm{sim}_j + \ell\, p\, (1 - \mathrm{sim}_j)
$$

where $\ell$ is the length of the common prefix at the start of the
strings, **capped at $4$**, and $p$ is the prefix scale (default
$p = 0.1$). Typically $p \le 0.25$ so that $\mathrm{sim}_w$ cannot exceed
$1$ when $\ell = 4$.

### Distance

$$
d_w = 1 - \mathrm{sim}_w
$$

### Example

$A=\texttt{MARTHA}$, $B=\texttt{MARHTA}$: Jaro similarity
$\mathrm{sim}_j \approx 0.94444$ (six matches, one transposition). Common
prefix $\ell = 3$, so with $p = 0.1$

$$
\mathrm{sim}_w \approx 0.94444 + 3\cdot 0.1\cdot(1 - 0.94444) \approx 0.96111
$$

Wikipedia also illustrates $\texttt{FAREMVIEL}$ / $\texttt{FARMVILLE}$
with eight matches and one transposition:
$\mathrm{sim}_j \approx 0.88426$ (often rounded to $0.88$).

### Metric properties

Jaro–Winkler distance is **not** a metric: it need not satisfy the
triangle inequality, and $d_w(x,y)=0$ does not strictly characterize
string identity under all formulations (this package returns $0$ for
identical inputs). Prefer Levenshtein when a true metric is required.

## Complexity

| Measure | Bound |
| ------- | ----- |
| Time | $O(|A|\cdot|B|)$ worst case within the matching window |
| Auxiliary space | $O(|A|+|B|)$ match flags |
| Capacity | each $\|\,\cdot\,\| \le \mathrm{Max\_Len}=10000$ |

## Features

- **`Jaro_Similarity`** — classical Jaro $\mathrm{sim}_j \in [0,1]$.
- **`Jaro_Winkler_Similarity`** — prefix-boosted $\mathrm{sim}_w$; optional $p$.
- **`Jaro_Winkler_Distance`** — $1 - \mathrm{sim}_w$.
- **`Default_P`** — $0.1$ Winkler prefix scale.
- **Capacity guard** — `Invalid_Argument` when length $> \mathrm{Max\_Len}$.
- **Arbitrary `String'First`** — slices work.
- **Case-sensitive** — no folding; opaque `Character` comparison.
- **Zero-warning build** — `gnatmake -gnatwa -gnat2022 -Pjaro_winkler_distance.gpr`.

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

- Empty/empty and empty/nonempty similarities and distances
- Identical strings (including length ladder and letter bulk)
- Known pairs (`MARTHA`/`MARHTA`, `DIXON`/`DICKSONX`,
  `FAREMVIEL`/`FARMVILLE`, `dwayne`/`duane`, `CRATE`/`TRACE`)
- Prefix boost vs plain Jaro; $P=0$; larger $P$; $\ell$ cap at $4$
- Distance $= 1 -$ similarity cross-checks
- Short-string matching window (including clamp for length $1$)
- Case sensitivity; spaces, digits, punctuation; Latin-1 octets
- Symmetry; $[0,1]$ bounds
- Non-1 `String'First` slices
- Modest sizes and `Max_Len` boundary acceptance / rejection
- Transposition / reorder spot checks; custom $P$ wiring

## Building

- Prerequisites: GNAT compiler supporting Ada 2022 / Ada 2023 (e.g. GNAT FSF
  13+, GNAT 14+, or GNAT Pro).
- Standard: ISO/IEC 8652:2023.
- Build flag: `-gnatwa -gnat2022` with zero compiler warnings.

## API

```ada
package Jaro_Winkler_Distance is
   Max_Len   : constant Positive := 10_000;
   Default_P : constant Float    := 0.1;
   Invalid_Argument : exception;

   function Jaro_Similarity (A, B : String) return Float;
   function Jaro_Winkler_Similarity
     (A, B : String; P : Float := Default_P) return Float;
   function Jaro_Winkler_Distance
     (A, B : String; P : Float := Default_P) return Float;
end Jaro_Winkler_Distance;
```

Raises `Invalid_Argument` if either input length exceeds `Max_Len`.

## License

Educational reference implementation. See repository `LICENSE` if present.
