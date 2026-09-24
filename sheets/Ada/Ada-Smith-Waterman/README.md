# Smith–Waterman Algorithm in Ada 2023

## Project Overview

The **Smith–Waterman algorithm** performs **local sequence alignment**: it
finds the most similar *regions* (substrings) between two strings of nucleic
acid or protein sequence, rather than forcing an end-to-end (global)
alignment. It is a **dynamic programming** method introduced by Temple F.
Smith and Michael S. Waterman (1981).

This package is an **Ada 2023 (ISO/IEC 8652:2023)** educational
implementation with a **linear gap penalty**, fixed DP matrix pool, simple
match / mismatch scoring, best-score query, and optional traceback to
recover one optimal local alignment (segment indices and gapped strings).

Primary source:
[Wikipedia — Smith–Waterman algorithm](https://en.wikipedia.org/wiki/Smith%E2%80%93Waterman_algorithm).

## Local vs global (Needleman–Wunsch)

| | **Smith–Waterman** (this package) | **Needleman–Wunsch** |
| --- | --- | --- |
| Goal | Best *local* similar region | Best *global* end-to-end alignment |
| Boundary | $H(i,0)=H(0,j)=0$ | Gap penalties along borders |
| Recurrence | $\max(0,\ldots)$ — scores never go negative | No zero floor; negatives allowed |
| Traceback | From the **maximum** cell | From the corner $H(m,n)$ |

Do **not** confuse the two: SW is for spotting shared motifs / domains;
NW is for aligning full sequences of similar length. This package does
not `with` any Needleman–Wunsch package.

## Algorithm

Given strings $A = a_1\ldots a_m$ and $B = b_1\ldots b_n$, a scoring
function $s(a_i,b_j)$ (match / mismatch), and linear gap penalty
$W_{\mathrm{gap}}$:

$$
\begin{aligned}
H(i,0) &= 0, \quad i = 0,\ldots,m \\
H(0,j) &= 0, \quad j = 0,\ldots,n \\
H(i,j) &= \max\begin{cases}
0 \\
H(i-1,j-1) + s(a_i,b_j) \\
H(i-1,j) + W_{\mathrm{gap}} \\
H(i,j-1) + W_{\mathrm{gap}}
\end{cases}
\end{aligned}
$$

The **best local score** is $\max_{i,j} H(i,j)$. Traceback starts at an
argmax cell and walks predecessors until a $0$ (or stop) cell, producing
gapped local aligned strings (gap character `-`).

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
&\quad H(i,j) \leftarrow \max\bigl(0,\ H(i-1,j-1)+s(a_i,b_j),\ H(i-1,j)+W_{\mathrm{gap}},\ H(i,j-1)+W_{\mathrm{gap}}\bigr) \\
&\mathit{best} \leftarrow \max_{i,j} H(i,j);\ \text{traceback from }\arg\max H
\end{align*}
$$

### Example

With Match $=+2$, Mismatch $=-1$, Gap $=-1$:

- $A = \texttt{ACGT}$, $B = \texttt{ACGT}$ → score $8$, full match.
- $A = \texttt{AAAA}$, $B = \texttt{TTTT}$ → score $0$ (no positive local
  similarity).
- $A = \texttt{GGTTGACTA}$, $B = \texttt{TGTTACGG}$ → score $9$, local
  segments aligning approximately $\texttt{GTTGAC}$ vs $\texttt{GTT{-}AC}$.

## Complexity

| Measure | Bound |
| ------- | ----- |
| Time | $O(mn)$ |
| Space | $O(mn)$ — fixed pool $({\mathrm{Max\_Len}}+1)^2$ |
| Capacity | Each string length $\le \mathrm{Max\_Len}$ (default $256$) |

Smith–Waterman is **optimal** for local alignment under the chosen scoring,
but the quadratic time / space cost limits it to modest educational lengths
(or to short refinement after a heuristic seed search such as BLAST).

## Features

- **`Best_Score (A, B)`** — maximum local alignment score.
- **`Align (A, B)`** — score plus 1-based start/end of one optimal local
  segment in each string.
- **`Align` (procedure)** — same path plus gapped `Unbounded_String`
  alignments (`-` for gaps).
- **`Scoring_Scheme` / `Default_Scoring`** — Match $+2$, Mismatch $-1$,
  Gap $-1$ (overridable).
- **`Pair_Score`** — single-character substitution score.
- **Fixed DP pool** — no per-call heap matrix; sized to `Max_Len`.
- **`Invalid_Argument`** when either length exceeds `Max_Len`.
- **Arbitrary `String` bounds** — works for any `A'First` / `B'First`.
- **Zero-warning build** — `gnatmake -gnatwa -gnat2022 -Psmith_waterman.gpr`.

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
- No similarity (expect score $0$)
- Classic textbook DNA / short-string examples with known scores
- Custom `Scoring_Scheme` values
- Gapped alignment string lengths and gap characters
- Non-1 `String'First` index bounds
- `Invalid_Argument` for oversized inputs
- Segment index consistency with gapped reconstruction

## Building

- Prerequisites: GNAT compiler supporting Ada 2022 / Ada 2023 (e.g. GNAT FSF
  13+, GNAT 14+, or GNAT Pro).
- Standard: ISO/IEC 8652:2023.
- Build flag: `-gnatwa -gnat2022` with zero compiler warnings.

## API

```ada
package Smith_Waterman is
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
      Score : Integer;
      A_Start, A_End, B_Start, B_End : Natural;
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
end Smith_Waterman;
```

## License

Educational reference implementation. See repository `LICENSE` if present.
