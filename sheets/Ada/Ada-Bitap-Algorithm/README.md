# Bitap Algorithm (Shift-Or / Baeza-Yates–Gonnet) in Ada 2023

## Project Overview

The **Bitap** algorithm (also known as **shift-or**, **shift-and**, or
**Baeza-Yates–Gonnet**) finds whether a text contains a substring that is
exactly equal to a pattern, or **approximately equal** within a given
**Levenshtein** edit distance $k$ (insertions, deletions, and
substitutions). It precomputes a bitmask per alphabet character and then
advances one or more bit-vectors with fast bitwise shifts and masks.

Exact Bitap was described by Dömölki (1964) and reinvented by
Baeza-Yates and Gonnet (1989). Manber and Wu (1991/1992) extended it to
full fuzzy matching; that Wu–Manber form underlies the Unix tool
`agrep`. Because each pattern position occupies one bit of a machine
word, the educational implementation limits the pattern to
$\mathrm{Max\_Pattern\_Len} = 63$ bits of `Interfaces.Unsigned_64`.

This package is an **Ada 2023 (ISO/IEC 8652:2023)** educational
implementation of **exact** shift-and Bitap and **approximate**
Wu–Manber Bitap. Matching is **case-sensitive** (no folding).

Primary source:
[Wikipedia — Bitap algorithm](https://en.wikipedia.org/wiki/Bitap_algorithm).

Part of the **RobertBoettcherSF** Ada algorithm series.

## Contrast with string siblings

| Package | Idea |
| --- | --- |
| **This package** (`Ada-Bitap-Algorithm`) | Bit-parallel exact / Levenshtein-$\le k$ search |
| **[Ada-Substring-Search](https://github.com/RobertBoettcherSF/Ada-Substring-Search)** | Exact Naive / KMP / Rabin–Karp / Horspool survey |
| **[Ada-Trigram-Search](https://github.com/RobertBoettcherSF/Ada-Trigram-Search)** | Character trigrams + Dice similarity |
| **[Ada-Aho-Corasick](https://github.com/RobertBoettcherSF/Ada-Aho-Corasick)** | Multi-pattern exact dictionary matching |

README links only — **no** package `with` of siblings.

## Algorithm

### Exact search (shift-and)

Let the pattern $P$ have length $m$ and the text $T$ have length $n$
(Ada indices $T'\mathit{First}\ldots T'\mathit{Last}$). Precompute a
mask table so that bit $i$ of $\mathrm{Pattern\_Mask}[c]$ is set iff
$P(P'\mathit{First}+i) = c$:

$$
\mathrm{Pattern\_Mask}[c] = \bigvee_{0 \le i < m,\ P_i = c} 2^{i}
$$

Maintain a state word $R$ (initially $0$). After reading text character
$T_j$:

$$
R \leftarrow \bigl((R \ll 1) \lor 1\bigr) \land \mathrm{Pattern\_Mask}[T_j]
$$

Bit $i$ of $R$ is set iff the prefix $P[0..i]$ matches the suffix of
$T$ ending at $j$. A full match ends at $j$ when bit $(m-1)$ is set; the
start index is $j - m + 1$. Empty pattern raises `Invalid_Argument`;
empty text yields `Not_Found`.

### Approximate search (Wu–Manber)

Extend to $k+1$ state words $R[0],\ldots,R[k]$. Array $R[d]$ represents
prefixes of $P$ that match a suffix of the text so far with **at most**
$d$ Levenshtein edits. Initialize $R[0] = 0$ and, for $d \ge 1$,

$$
R[d] \leftarrow 2^{d} - 1
$$

(allowing $d$ leading deletions). After reading $T_j$, with
$S = \mathrm{Pattern\_Mask}[T_j]$:

$$
\begin{align*}
R'[0] &\leftarrow \bigl((R[0] \ll 1) \lor 1\bigr) \land S \\
R'[d] &\leftarrow
  \bigl((R[d] \ll 1) \lor 1\bigr) \land S
  & \text{(match)} \\
&\quad{} \lor \bigl((R[d-1] \ll 1) \lor 1\bigr)
  & \text{(substitution)} \\
&\quad{} \lor R[d-1]
  & \text{(insertion)} \\
&\quad{} \lor \bigl((R'[d-1] \ll 1) \lor 1\bigr)
  & \text{(deletion)}
\end{align*}
$$

A hit ends at $j$ when bit $(m-1)$ of $R[k]$ is set. Because insertions
and deletions change the matched span length, the package recovers the
**leftmost** Ada start index $s$ in
$[j-m-k+1,\ j]$ (clamped to $T'\mathit{First}$) such that
$\mathrm{Lev}(T(s..j), P) \le k$, and returns the globally leftmost such
start among all hit ends. $K = 0$ reduces to `Find_Exact`.

### Example

Text `caxt`, pattern `cat`, $k = 1$ (one insertion of `x`):

- Exact Bitap does not match.
- Approximate Bitap sets bit $(m-1)$ of $R[1]$ when `t` is read; recovered
  start is the first index of `caxt` (Levenshtein distance $1$).

Text `hello`, pattern `ell`, $k = 0$: start index of `ell` (second
character when $T'\mathit{First}=1$).

## Complexity

| Measure | Bound |
| ------- | ----- |
| Exact preprocess | $O(\|\Sigma\| + m)$ mask table |
| Exact search | $O(n)$ word operations ($m \le w$) |
| Approx search | $O(n \cdot (k+1))$ word operations |
| Start recovery (on hits) | $O(m \cdot (m+k))$ Levenshtein per candidate |
| Auxiliary space | $O(\|\Sigma\| + k)$ |
| Pattern limit | $m \le 63$ (`Unsigned_64`) |
| Case folding | **None** (case-sensitive) |

## Features

- **`Find_Exact`** — first exact start index, or `Not_Found` ($-1$).
- **`Contains_Exact`** — Boolean membership via `Find_Exact`.
- **`Find_Approx`** — first start of a substring within Levenshtein
  distance $\le K$; $K=0$ ≡ exact.
- **Bitmasks / $R$ arrays** — documented above with shift-and semantics
  (bit set = active match state).
- **Capacity guards** — `Invalid_Argument` for empty pattern, pattern
  longer than $\mathrm{Max\_Pattern\_Len}$, text longer than
  $\mathrm{Max\_Text\_Len}$, or $K > \mathrm{Max\_Pattern\_Len}$.
- **Arbitrary `String'First`** — slices work; returned indices are Ada
  indices into `Text`.
- **Zero-warning build** — `gnatmake -gnatwa -gnat2022 -Pbitap_algorithm.gpr`.

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

=== 1. Exact — empty text / misses ===
  PASS: ...
...
Results:  NN PASS, 0 FAIL
```

(Exact `NN` is the current suite size; it is at least 120.)

## Testing

The test suite in `tests.adb` covers:

- Empty text, exact hits at first / middle / last, systematic misses
- `Contains_Exact` equivalence with `Find_Exact`
- $K = 0$ reduces to exact; $K = 1, 2$ insertion / deletion / substitution
- Overlapping candidates and leftmost-start recovery
- Pattern length bounds ($1$ .. $63$) and oversize rejection
- Case sensitivity, digits, spaces, punctuation
- Non-1 `String'First` slices
- `Invalid_Argument` for empty pattern, long pattern/text, large $K`
- Brute-force Levenshtein oracle cross-checks on random short strings

## Building

- Prerequisites: GNAT compiler supporting Ada 2022 / Ada 2023 (e.g. GNAT FSF
  13+, GNAT 14+, or GNAT Pro).
- Standard: ISO/IEC 8652:2023.
- Build flag: `-gnatwa -gnat2022` with zero compiler warnings.

## API

```ada
package Bitap_Algorithm is
   Max_Text_Len    : constant Positive := 100_000;
   Max_Pattern_Len : constant Positive := 63;
   Not_Found       : constant Integer  := -1;
   Invalid_Argument : exception;

   function Find_Exact (Text, Pattern : String) return Integer;
   function Contains_Exact (Text, Pattern : String) return Boolean;
   function Find_Approx
     (Text, Pattern : String; K : Natural) return Integer;
end Bitap_Algorithm;
```

Raises `Invalid_Argument` for an empty pattern, pattern / text above the
educational maxima, or $K > \mathrm{Max\_Pattern\_Len}$. Sentinel when
absent: `Not_Found` ($-1$).

## License

Educational reference implementation. See repository `LICENSE` if present.
