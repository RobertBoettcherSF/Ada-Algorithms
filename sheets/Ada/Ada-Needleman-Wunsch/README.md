# Needleman–Wunsch Algorithm in Ada 2023

## Project Overview

The **Needleman–Wunsch algorithm** performs **global sequence alignment**: it
finds an optimal *end-to-end* alignment of two strings of nucleic acid or
protein sequence. It is a **dynamic programming** method introduced by Saul B.
Needleman and Christian D. Wunsch (1970), one of the first applications of DP
to biological sequence comparison.

This package is an **Ada 2023 (ISO/IEC 8652:2023)** educational
implementation with a **linear gap penalty**, fixed DP matrix pool, simple
match / mismatch scoring, best-score query, and traceback to recover one
optimal global alignment (gapped strings).

Primary source:
[Wikipedia — Needleman–Wunsch algorithm](https://en.wikipedia.org/wiki/Needleman%E2%80%93Wunsch_algorithm).

## Global vs local (Smith–Waterman)

| | **Needleman–Wunsch** (this package) | **Smith–Waterman** |
| --- | --- | --- |
| Goal | Best *global* end-to-end alignment | Best *local* similar region |
| Boundary | $F(i,0)=i\cdot W_{\mathrm{gap}}$, $F(0,j)=j\cdot W_{\mathrm{gap}}$ | $H(i,0)=H(0,j)=0$ |
| Recurrence | No zero floor; negatives allowed | $\max(0,\ldots)$ — scores never go negative |
| Traceback | From the corner $F(m,n)$ to $(0,0)$ | From the **maximum** cell until $0$ |

Do **not** confuse the two: NW is for aligning full sequences of similar
length; SW is for spotting shared motifs / domains. This package does
not `with` any Smith–Waterman package.

## Algorithm

Given strings $A = a_1\ldots a_m$ and $B = b_1\ldots b_n$, a scoring
function $s(a_i,b_j)$ (match / mismatch), and linear gap penalty
$W_{\mathrm{gap}}$:

$$
\begin{aligned}
F(i,0) &= i \cdot W_{\mathrm{gap}}, \quad i = 0,\ldots,m \\
F(0,j) &= j \cdot W_{\mathrm{gap}}, \quad j = 0,\ldots,n \\
F(i,j) &= \max\begin{cases}
F(i-1,j-1) + s(a_i,b_j) \\
F(i-1,j) + W_{\mathrm{gap}} \\
F(i,j-1) + W_{\mathrm{gap}}
\end{cases}
\end{aligned}
$$

The **global alignment score** is $F(m,n)$. Traceback starts at the
bottom-right corner $(m,n)$ and walks predecessors to $(0,0)$, producing
gapped aligned strings (gap character `-`).

### Default scoring

| Symbol | Value | Role |
| ------ | ----- | ---- |
| Match | $+2$ | Identical characters |
| Mismatch | $-1$ | Differing characters |
| Gap | $-1$ | Linear indel penalty |

Custom schemes use the `Scoring_Scheme` record (`Match`, `Mismatch`,
`Gap`). Affine gap penalties are **not** implemented here.

### Pseudocode

$$
\begin{align*}
&\mathbf{for}\ i \leftarrow 1\ \mathbf{to}\ m:\ \mathbf{for}\ j \leftarrow 1\ \mathbf{to}\ n: \\
&\quad F(i,j) \leftarrow \max\bigl(F(i-1,j-1)+s(a_i,b_j),\ F(i-1,j)+W_{\mathrm{gap}},\ F(i,j-1)+W_{\mathrm{gap}}\bigr) \\
&\mathit{score} \leftarrow F(m,n);\ \text{traceback from }(m,n)\text{ to }(0,0)
\end{align*}
$$

### Example

With Match $=+2$, Mismatch $=-1$, Gap $=-1$:

- $A = \texttt{ACGT}$, $B = \texttt{ACGT}$ → score $8$, full match.
- $A = \texttt{AAAA}$, $B = \texttt{TTTT}$ → score $-4$ (four mismatches;
  global alignment still covers the whole strings).
- $A = \texttt{GCATGCG}$, $B = \texttt{GATTACA}$ → score $4$, e.g.
  $\texttt{GCA{-}TGCG}$ vs $\texttt{G{-}ATTACA}$.
- Same pair with Match $=+1$, Mismatch $=-1$, Gap $=-1$ (Wikipedia walkthrough)
  → score $0$.

## Complexity

| Measure | Bound |
| ------- | ----- |
| Time | $O(mn)$ |
| Space | $O(mn)$ — fixed pool $({\mathrm{Max\_Len}}+1)^2$ |
| Capacity | Each string length $\le \mathrm{Max\_Len}$ (default $256$) |

Needleman–Wunsch is **optimal** for global alignment under the chosen scoring,
but the quadratic time / space cost limits it to modest educational lengths
(or to short refinement after a heuristic seed search).

## Features

- **`Best_Score (A, B)`** — global alignment score $F(m,n)$.
- **`Align (A, B)`** — score plus one optimal pair of gapped
  `Unbounded_String` alignments (`-` for gaps).
- **`Align` (procedure)** — same path with out-parameters.
- **`Scoring_Scheme` / `Default_Scoring`** — Match $+2$, Mismatch $-1$,
  Gap $-1$ (overridable).
- **`Pair_Score`** — single-character substitution score.
- **Fixed DP pool** — no per-call heap matrix; sized to `Max_Len`.
- **`Invalid_Argument`** when either length exceeds `Max_Len`.
- **Arbitrary `String` bounds** — works for any `A'First` / `B'First`.
- **Zero-warning build** — `gnatmake -gnatwa -gnat2022 -Pneedleman_wunsch.gpr`.

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

=== 1. Empty and singleton ===
  PASS: ...
...
Results:  NN PASS, 0 FAIL
```

(Exact `NN` is the current suite size; it is at least 50.)

## Testing

The test suite in `tests.adb` covers:

- Empty / singleton / identical strings
- All-mismatch and indel (length-difference) cases
- Classic textbook DNA examples with known scores (including Wikipedia
  Match $=+1$ scoring)
- Custom `Scoring_Scheme` values
- Gapped alignment string contents and equal lengths
- Non-1 `String'First` index bounds
- `Invalid_Argument` for oversized inputs
- Function / procedure `Align` agreement with `Best_Score`

## Building

- Prerequisites: GNAT compiler supporting Ada 2022 / Ada 2023 (e.g. GNAT FSF
  13+, GNAT 14+, or GNAT Pro).
- Standard: ISO/IEC 8652:2023.
- Build flag: `-gnatwa -gnat2022` with zero compiler warnings.

## API

```ada
package Needleman_Wunsch is
   Max_Len : constant Positive := 256;
   Match_Score    : constant Integer := 2;
   Mismatch_Score : constant Integer := -1;
   Gap_Penalty    : constant Integer := -1;
   type Scoring_Scheme is record
      Match, Mismatch, Gap : Integer;
   end record;
   Default_Scoring : constant Scoring_Scheme;
   Invalid_Argument : exception;
   type Alignment_Result is record
      Score     : Integer;
      A_Aligned : Unbounded_String;
      B_Aligned : Unbounded_String;
   end record;
   function Best_Score (A, B : String;
                        Scoring : Scoring_Scheme := Default_Scoring)
                       return Integer;
   function Align (A, B : String;
                   Scoring : Scoring_Scheme := Default_Scoring)
                  return Alignment_Result;
   procedure Align
     (A, B : String;
      Score : out Integer;
      A_Aligned, B_Aligned : out Unbounded_String;
      Scoring : Scoring_Scheme := Default_Scoring);
   function Pair_Score (Left, Right : Character;
                        Scoring : Scoring_Scheme := Default_Scoring)
                       return Integer;
end Needleman_Wunsch;
```

## License

Educational reference implementation. See repository `LICENSE` if present.
