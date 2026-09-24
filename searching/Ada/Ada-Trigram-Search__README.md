# Trigram Search in Ada 2023

## Project Overview

A **trigram** is a character **n-gram** of size $n = 3$: three adjacent
symbols in order. Sliding a window of length 3 across a string yields the
overlapping character trigrams used in approximate / fuzzy matching,
spell-checking, and duplicate detection. For `"hello"` the windows are
`"hel"`, `"ell"`, `"llo"`.

This package is an **Ada 2023 (ISO/IEC 8652:2023)** educational
implementation of character-trigram extraction, unique-set intersection,
and the **Sørensen–Dice** coefficient over those sets. Matching is
**case-sensitive** (no folding). Exact substring search (e.g. Ada
`Index` / a naive scan) is contrasted below in the README only — it is
not part of the package API.

Primary sources:
[Wikipedia — N-gram](https://en.wikipedia.org/wiki/N-gram),
[Sørensen–Dice coefficient](https://en.wikipedia.org/wiki/S%C3%B8rensen%E2%80%93Dice_coefficient).

Part of the **RobertBoettcherSF** Ada algorithm series.

## Contrast with string siblings

| Package | Idea |
| --- | --- |
| **This package** (`Ada-Trigram-Search`) | Overlapping character trigrams; Dice similarity |
| **[Ada-Substring-Search](https://github.com/RobertBoettcherSF/Ada-Substring-Search)** | Exact single-pattern search (Naive / KMP / RK / Horspool) |
| **[Ada-Longest-Common-Substring](https://github.com/RobertBoettcherSF/Ada-Longest-Common-Substring)** | Longest contiguous shared fragment (DP) |
| **[Ada-Aho-Corasick](https://github.com/RobertBoettcherSF/Ada-Aho-Corasick)** | Multi-pattern exact dictionary matching |

README links only — **no** package `with` of siblings.

## Algorithm

### Character trigrams

Given a string $S$ of length $n = |S|$ (Ada indices
$S'\mathit{First} \ldots S'\mathit{Last}$):

1. If $n < 3$, $S$ has **no** trigram windows.
2. Otherwise the overlapping windows are
   $S(i..i+2)$ for $i = S'\mathit{First} \ldots S'\mathit{Last}-2$.
3. Occurrence count: $\max(0, n-2)$.
4. This package prefers the **unique set** $T_S$ of those windows
   (educational Dice standard). Repeated identical windows collapse to
   one set element (e.g. `"aaaa"` has two occurrences of `"aaa"` but
   $|T_S| = 1$).

If $n > \mathrm{Max\_Len}$, every entry point raises `Invalid_Argument`.

### Shared trigrams and Dice

$$
|T_A \cap T_B|
\qquad
\mathrm{Dice}(A,B) = \frac{2\,|T_A \cap T_B|}{|T_A| + |T_B|}
$$

Edge cases for `Dice_Coefficient` (evaluated before the formula):

- Both empty ($|A| = |B| = 0$) → $1.0$
- Either string has length $< 3$ (including one empty) → $0.0$
- Otherwise the formula; result lies in $[0,1]$

Identical strings of length $\ge 3$ yield $1.0$. Disjoint trigram sets
yield $0.0$.

### Fuzzy containment

`Contains_Trigram (Haystack, Needle)` is True iff
$T_{\mathrm{Needle}} \subseteq T_{\mathrm{Haystack}}$. When
$|\mathrm{Needle}| < 3$ the needle set is empty, so the result is True
(vacuous subset). `Has_Trigram` tests membership of a single length-3
window.

### Exact substring (README contrast only)

Exact search asks whether `Needle` occurs contiguously inside
`Haystack` (one alignment). Trigram containment is weaker and fuzzier:
every length-3 piece of `Needle` must appear *somewhere* in
`Haystack`, not necessarily as one contiguous block matching `Needle`.
Use sibling exact-search packages when you need true substring hits.

### Example

$A = \texttt{abcdef}$, $B = \texttt{defghi}$:

- $T_A = \{\texttt{abc},\texttt{bcd},\texttt{cde},\texttt{def}\}$
- $T_B = \{\texttt{def},\texttt{efg},\texttt{fgh},\texttt{ghi}\}$
- $|T_A \cap T_B| = 1$ (`def`)
- $\mathrm{Dice}(A,B) = 2\cdot 1 / (4+4) = 0.25$

## Complexity

| Measure | Bound |
| ------- | ----- |
| Extract / count | $O(n)$ windows |
| Uniquify (educational linear scan) | $O(u \cdot n)$ with $u \le n-2$ |
| Shared / Dice | $O(u_A u_B)$ set intersection |
| Auxiliary space | $O(n)$ for unique buffers |
| Case folding | **None** (case-sensitive) |

## Features

- **`Trigram_Count`** — occurrence windows $\max(0, n-2)$.
- **`Unique_Trigram_Count`** — $|T_S|$ unique set size.
- **`Shared_Trigrams`** — $|T_A \cap T_B|$ (unique sets, not multisets).
- **`Dice_Coefficient`** — $2|T_A \cap T_B| / (|T_A|+|T_B|)$ with documented empty/short rules.
- **`Contains_Trigram`** — educational fuzzy containment $T_N \subseteq T_H$.
- **`Has_Trigram`** — single length-3 window membership.
- **Capacity guard** — `Invalid_Argument` when length $> \mathrm{Max\_Len}$
  (default $10\,000$); `Has_Trigram` also rejects $\mathrm{Tri}'\mathit{Length} \ne 3$.
- **Arbitrary `String'First`** — slices work.
- **Zero-warning build** — `gnatmake -gnatwa -gnat2022 -Ptrigram_search.gpr`.

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

=== 1. Trigram_Count — empty and short ===
  PASS: ...
...
Results:  NN PASS, 0 FAIL
```

(Exact `NN` is the current suite size; it is at least 100.)

## Testing

The test suite in `tests.adb` covers:

- Empty / short ($n < 3$) counts and Dice edge cases
- Unique vs occurrence counts (multiset contrast)
- Shared intersection and Dice formula cross-checks
- Identical strings, disjoint sets, partial overlap
- Dice bounds $[0,1]$, symmetry, reflexivity
- One-character-edit intuition (`kitten` / `sitting`, `color` / `colour`)
- Case sensitivity (no folding)
- Spaces, punctuation, digits
- Non-1 `String'First` slices
- `Contains_Trigram` / `Has_Trigram` consistency
- `Invalid_Argument` for oversized inputs and bad trigram length
- Modest sizes (50–400) and `Max_Len` boundary

## Building

- Prerequisites: GNAT compiler supporting Ada 2022 / Ada 2023 (e.g. GNAT FSF
  13+, GNAT 14+, or GNAT Pro).
- Standard: ISO/IEC 8652:2023.
- Build flag: `-gnatwa -gnat2022` with zero compiler warnings.

## API

```ada
package Trigram_Search is
   Max_Len : constant Positive := 10_000;
   Invalid_Argument : exception;

   function Trigram_Count (S : String) return Natural;
   function Unique_Trigram_Count (S : String) return Natural;
   function Shared_Trigrams (A, B : String) return Natural;
   function Dice_Coefficient (A, B : String) return Float;
   function Contains_Trigram (Haystack, Needle : String) return Boolean;
   function Has_Trigram (Haystack : String; Tri : String) return Boolean;
end Trigram_Search;
```

Unique trigram **sets** for Dice / shared counts. Raises
`Invalid_Argument` if any input length exceeds `Max_Len`, or if
`Has_Trigram` is given a `Tri` whose length is not 3.

## License

Educational reference implementation. See repository `LICENSE` if present.
