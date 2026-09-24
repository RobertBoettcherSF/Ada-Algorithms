# Hirschberg's Algorithm in Ada 2023

## Project Overview

**Hirschberg's algorithm** computes an **optimal global sequence alignment**
with the **same score** as Needleman–Wunsch, but using only
**linear extra space** — $O(\min(m,n))$ working memory besides the output —
instead of the full $O(mn)$ DP matrix. Time remains $O(mn)$.

It is a **divide-and-conquer** method due to Dan Hirschberg (1975): forward
and reverse last-row Needleman–Wunsch scores locate an optimal midpoint split;
the two halves are solved recursively and the alignments concatenated.

This package is an **Ada 2023 (ISO/IEC 8652:2023)** educational
implementation with the same linear-gap educational scoring as the sibling
Needleman–Wunsch package (Match $+2$, Mismatch $-1$, Gap $-1$). It does
**not** `with` `Needleman_Wunsch` or `Smith_Waterman`; a two-row NW last-row
helper is reimplemented inline.

Primary source:
[Wikipedia — Hirschberg's algorithm](https://en.wikipedia.org/wiki/Hirschberg%27s_algorithm).

## Why linear space matters

| | **Needleman–Wunsch** | **Hirschberg** (this package) |
| --- | --- | --- |
| Optimal global score | Yes — $F(m,n)$ | Yes — **same** $F(m,n)$ |
| Alignment recovery | Traceback on full matrix | Divide-and-conquer + base NW |
| Time | $O(mn)$ | $O(mn)$ |
| Extra space | $O(mn)$ score / predecessor matrix | $O(\min(m,n))$ score rows (+ output) |

Score-only NW already admits a two-row formulation in $O(\min(m,n))$ space;
Hirschberg extends that idea so the **full alignment** is recovered without
storing the quadratic table.

## Algorithm

Given $A = a_1\ldots a_m$, $B = b_1\ldots b_n$, substitution scores
$s(a_i,b_j)$, and linear gap penalty $W_{\mathrm{gap}}$:

1. **Base cases.** If $m=0$, $n=0$, $m=1$, or $n=1$, produce the alignment
   with a trivial / small Needleman–Wunsch step.
2. **Split** $A$ at $\mathrm{mid}=\lfloor m/2\rfloor$.
3. **Forward.** Compute the last row $L[0..n]$ of NW scores for
   $A[1..\mathrm{mid}]$ vs $B$ (two-row DP).
4. **Reverse.** Compute the last row $R[0..n]$ for
   $\mathrm{reverse}(A[\mathrm{mid}+1..m])$ vs $\mathrm{reverse}(B)$.
5. **Choose** split index $j^\star$ maximizing $L[j]+R[n-j]$.
6. **Recurse** on $(A_{\mathrm{left}}, B[1..j^\star])$ and
   $(A_{\mathrm{right}}, B[j^\star+1..n])$; concatenate gapped strings.

$$
j^\star = \arg\max_{0 \le j \le n}\bigl(L[j] + R[n-j]\bigr)
$$

The optimal score equals the classical Needleman–Wunsch recurrence:

$$
\begin{aligned}
F(i,0) &= i \cdot W_{\mathrm{gap}}, \quad
F(0,j) = j \cdot W_{\mathrm{gap}} \\
F(i,j) &= \max\begin{cases}
F(i-1,j-1) + s(a_i,b_j) \\
F(i-1,j) + W_{\mathrm{gap}} \\
F(i,j-1) + W_{\mathrm{gap}}
\end{cases}
\end{aligned}
$$

### Default scoring

| Symbol | Value | Role |
| ------ | ----- | ---- |
| Match | $+2$ | Identical characters |
| Mismatch | $-1$ | Differing characters |
| Gap | $-1$ | Linear indel penalty |

Custom schemes use the `Scoring_Scheme` record (`Match`, `Mismatch`,
`Gap`). Affine gap penalties are **not** implemented here.

### Example

With Match $=+2$, Mismatch $=-1$, Gap $=-1$:

- $A = \texttt{ACGT}$, $B = \texttt{ACGT}$ → score $8$, full match.
- $A = \texttt{GCATGCG}$, $B = \texttt{GATTACA}$ → score $4$ (same as NW).
- $A = \texttt{AAAA}$, $B = \texttt{TTTT}$ → score $-4$.
- Same DNA pair with Match $=+1$, Mismatch $=-1$, Gap $=-1$ → score $0$.

## Complexity

| Measure | Bound |
| ------- | ----- |
| Time | $O(mn)$ |
| Extra working space | $O(\min(m,n))$ score rows (fixed pool sized to `Max_Len`) |
| Output | $O(m+n)$ gapped alignment strings |
| Capacity | Each string length $\le \mathrm{Max\_Len}$ (default $256$) |

## Features

- **`Best_Score (A, B)`** — optimal global score via two-row NW
  ($O(\min(m,n))$ space).
- **`Align (A, B)`** — Hirschberg alignment: score plus gapped
  `Unbounded_String` pair (`-` for gaps).
- **`Align` (procedure)** — same path with out-parameters.
- **`Scoring_Scheme` / `Default_Scoring`** — Match $+2$, Mismatch $-1$,
  Gap $-1$ (overridable).
- **`Pair_Score`** — single-character substitution score.
- **`Invalid_Argument`** when either length exceeds `Max_Len`.
- **Arbitrary `String` bounds** — works for any `A'First` / `B'First`.
- **No dependency** on Needleman–Wunsch / Smith–Waterman packages.
- **Zero-warning build** — `gnatmake -gnatwa -gnat2022 -Phirschbergs_algorithm.gpr`.

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
- Mismatches, indels, and classic DNA examples
- **Inline reference Needleman–Wunsch** score cross-checks (path score,
  degapped recovery, `Best_Score` / `Align.Score` agreement)
- Custom `Scoring_Scheme` values
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
package Hirschbergs_Algorithm is
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
end Hirschbergs_Algorithm;
```

## License

Educational reference implementation. See repository `LICENSE` if present.
