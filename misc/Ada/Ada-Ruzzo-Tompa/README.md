# Ruzzo–Tompa algorithm — Ada 2023

Educational, self-contained Ada 2023 package for the **Ruzzo–Tompa (RT)
algorithm**: find **all** non-overlapping contiguous **maximal scoring
subsequences** (positive-score segments) in a one-dimensional sequence of
scores $x_1,\ldots,x_n$ in linear time. See

- [Wikipedia: Ruzzo–Tompa algorithm](https://en.wikipedia.org/wiki/Ruzzo–Tompa_algorithm)
- Ruzzo & Tompa, ISMB 1999, *A Linear Time Algorithm for Finding All Maximal
  Scoring Subsequences*

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Part of the **RobertBoettcherSF** Ada algorithm series.

## Relation to the maximum subarray problem

The classical **maximum subarray** problem asks for a single contiguous
window maximizing

$$
S_{i,j} = \sum_{k=i}^{j} x_k.
$$

Ruzzo–Tompa returns the full list of **disjoint maximal** positive-score
segments. The segment with the largest score in that list is a solution to
maximum subarray whenever a positive-score window exists (so RT specializes
to Kadane’s answer for the global maximum). Recursively applying a linear
maximum-subarray finder left and right of the global maximum also enumerates
all maximal segments, but can take $O(n^{2})$ time in the worst case (Quicksort
style). RT builds the same set in $O(n)$ time and $O(n)$ space.

## All-nonpositive policy

Only **strictly positive** segment scores are admitted in
`Maximal_Segments`. If every entry is $\le 0$, the returned list is **empty**.

`Max_Segment` is the Kadane-equivalent check used by tests:

- if RT found at least one segment, return the one with largest `Score`
  (leftmost on ties);
- if the list is empty (all nonpositive), return the least-negative
  **singleton** (leftmost on ties) — the nonempty maximum-subarray
  convention.

Empty or oversize input raises `Invalid_Argument`.

## I-list formulation (educational)

Scan scores left to right while maintaining a running prefix sum and an
ordered list $I_1,\ldots,I_k$ of disjoint candidate segments. For each
$I_j$ store

$$
L_j =\text{prefix sum strictly before the start of }I_j,\qquad
R_j =\text{prefix sum through the end of }I_j.
$$

Nonpositive scores only advance the prefix sum. A positive score seeds a
length-one $I_k$ that is integrated by searching the list from right to left
for the largest $j$ with $L_j < L_k$:

1. If no such $j$, append $I_k$.
2. If $R_j \ge R_k$, append $I_k$.
3. Otherwise extend $I_k$ leftward to absorb $I_j,\ldots,I_{k-1}$, delete
   those entries, and reconsider the extended segment (stack / I-list style).

When the scan finishes, every remaining $I_j$ is maximal. This package
implements that educational I-list formulation (faithful to the Wikipedia /
Ruzzo–Tompa description).

**Example (Ruzzo & Tompa).** For
$x = [4,-5,3,-3,1,2,-2,2,-2,1,5]$ the maximal segments are $[4]$, $[3]$, and
$[1,2,-2,2,-2,1,5]$ (score $7$). The maximum subarray sum is $7$.

## Bioinformatics and other uses

High-scoring disjoint segments mark regions of unusual composition in DNA
or protein sequences (transmembrane domains, charged regions, homology
evaluation). Related uses include extracting high-value token spans in web
scraping and detecting information bursts in retrieval / microblog fusion.

## Complexity

One left-to-right pass with I-list merges: $O(n)$ time and $O(n)$ extra space
in the standard RT analysis (educational I-list form; $n \le$ `Max_Length`).

## API sketch

| Symbol | Role |
| --- | --- |
| `Element` / `Element_Array` | Integer scores; unconstrained array |
| `Segment` / `Segment_Array` | `First`, `Last`, `Score` (1-based logical) |
| `Maximal_Segments (A)` | All maximal positive-score segments ($O(n)$) |
| `Max_Segment (A)` | Best RT segment, or Kadane singleton if none |
| `Real_Array` / `Real_Segment` | `Long_Float` counterparts |
| `Max_Length` | Educational capacity ($10\,000$) |
| `Invalid_Argument` | Empty or oversize input |

`First` / `Last` are **1-based logical** positions into the sequence
($1$ = first element of $A$), independent of `A'First`.

## Build & test

```bash
make
make test
```

Requires GNAT with Ada 2022 support (`gnatmake -gnatwa -gnat2022`).

## License

Educational example code for the RobertBoettcherSF Ada algorithm series.
