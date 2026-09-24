# Quickselect in Ada 2023

## Project Overview

**Quickselect** (also **Hoare's selection algorithm**) finds the $k$-th
smallest element in an unordered list — the **$k$-th order statistic**. It
was developed by **Tony Hoare** alongside quicksort: choose a pivot,
partition, then recurse into **only one** side. That cuts the average cost
from $O(n\log n)$ (full sort) to $O(n)$, while the worst case remains
$O(n^2)$.

This package is an **Ada 2023 (ISO/IEC 8652:2023)** educational
implementation of classic **in-place Quickselect** on unordered `Integer`
arrays:

- **Median-of-three** pivot (first / middle / last) — deterministic and
  random-free; mitigates sorted / reverse pathologies of a fixed end pivot.
- **Lomuto partition** — after partitioning, the pivot sits at its final
  rank index $P$ (required by the classic Quickselect loop; Hoare partition
  does not guarantee that).
- Iterative one-sided shrink (no recursion stack).
- Average $O(n)$, worst $O(n^2)$, $O(1)$ extra space for `Select_Kth`.

Primary source:
[Wikipedia — Quickselect](https://en.wikipedia.org/wiki/Quickselect).

Part of the **RobertBoettcherSF** Ada algorithm series.

## Contrast with selection siblings

| Package | Idea |
| --- | --- |
| **This package** (`Ada-Quickselect`) | Focused Hoare Quickselect (median-of-three + Lomuto) |
| **Ada-Selection-Algorithm** | Broader selection-problem sheet (same family) |
| **Ada-Introselect** (later sheet) | Quickselect + median-of-medians fallback |
| **Ada-Quicksort** | Full sort: recurse into **both** sides |

README links only — **no** package `with` of siblings.

### Why not median-of-medians / Introselect here?

| Variant | Guarantee | Notes |
| --- | --- | --- |
| **Quickselect** (this package) | Average $O(n)$, worst $O(n^2)$ | Fast in practice; median-of-three helps common inputs |
| **Median of medians** | Worst-case $O(n)$ | High pivot overhead; rarely used alone |
| **Introselect** | Practical $O(n)$ with worst-case $O(n)$ | Hybrid: Quickselect + MoM fallback (Musser) |

This sheet stays focused on **Quickselect** as named on Wikipedia.

## Algorithm

Given an unordered array $A$ of length $n$ and a 1-based rank $k$
($1 \le k \le n$):

1. If $n = 0$, $n > \mathrm{Max\_N}$, or $k \notin [1,n]$, raise
   `Invalid_Argument`.
2. Set $\mathit{target} \leftarrow A'\mathit{First} + (k-1)$,
   $L \leftarrow A'\mathit{First}$, $R \leftarrow A'\mathit{Last}$.
3. While $L < R$:
   - Choose a **median-of-three** pivot among $A(L)$, $A(m)$, $A(R)$
     where $m = L + \lfloor(R-L)/2\rfloor$, and place it at $R$.
   - **Lomuto-partition** $A[L..R]$ around that pivot; let $P$ be the
     final pivot index.
   - If $P = \mathit{target}$, stop (the $k$-th element is at $P$).
   - If $P > \mathit{target}$, set $R \leftarrow P-1$; else
     $L \leftarrow P+1$.
4. After `Select_Kth`, $A(A'\mathit{First}+k-1)$ is the $k$-th smallest.

Elements before the rank index are $\le$ the result and elements after are
$\ge$ it (partition property); the two sides are **not** fully sorted.

### Pseudocode

$$
\begin{align*}
&\mathbf{procedure}\ \mathrm{Select\_Kth}(A,k): \\
&\quad \mathit{target} \leftarrow A'\mathit{First}+(k-1);\ L \leftarrow A'\mathit{First};\ R \leftarrow A'\mathit{Last} \\
&\quad \mathbf{while}\ L < R: \\
&\quad\quad \mathrm{MedianOfThreeToHi}(A,L,R) \\
&\quad\quad P \leftarrow \mathrm{PartitionLomuto}(A,L,R) \\
&\quad\quad \mathbf{if}\ P = \mathit{target}:\ \mathbf{return} \\
&\quad\quad \mathbf{elsif}\ P > \mathit{target}:\ R \leftarrow P-1 \\
&\quad\quad \mathbf{else}:\ L \leftarrow P+1
\end{align*}
$$

### Lomuto vs Hoare for selection

Wikipedia notes that the classic Quickselect loop assumes the partition
return value is the **pivot's final position**. That holds for **Lomuto**,
not for Hoare's original scheme (where the return index is the end of the
left region and the pivot may sit on either side). This package therefore
uses **Lomuto**.

### Median convention

- **Odd** $n$: rank $k = (n+1)/2$ (true middle).
- **Even** $n$: **lower middle** $k = n/2$.

### Example

Unordered $\{9,3,2,7,1,8,5\}$ ($n=7$):

- $k=1$ → $1$ (minimum)
- $k=3$ → $3$
- $k=4$ → $5$ (median)
- $k=7$ → $9$ (maximum)

## Complexity

| Measure | Bound |
| ------- | ----- |
| Time (average) | $O(n)$ |
| Time (worst) | $O(n^2)$ — adversarial pivot sequences |
| Auxiliary space (`Select_Kth`) | $O(1)$ — iterative |
| Auxiliary space (`Select_Kth_Copy`) | $O(n)$ — temporary copy |
| Expected comparisons (random pivots, median) | $\lesssim 3.4n + o(n)$ (Wikipedia) |

Median-of-three reduces (but does not eliminate) sorted-input pathologies.
A known **median-of-3 killer** sequence (Musser) still forces quadratic
behaviour — motivation for **Introselect** on a later sheet.

## Features

- **`Select_Kth`** — in-place procedure; after return,
  $A(A'\mathit{First}+K-1)$ is the $k$-th smallest.
- **`Select_Kth_Copy`** — non-mutating; copies then selects; returns the value.
- **`Median`** — odd: middle; even: lower middle (documented).
- **Median-of-three + Lomuto** — deterministic, random-free pivot.
- **Capacity guard** — `Invalid_Argument` when empty, $n > \mathrm{Max\_N}$,
  or $k$ out of range (default $\mathrm{Max\_N}=100\,000$).
- **Arbitrary bounds** — works for any `Natural` `A'First`.
- **Negatives and duplicates** — full `Integer` domain.
- **Zero-warning build** — `gnatmake -gnatwa -gnat2022 -Pquickselect.gpr`.

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

=== 1. Singleton and tiny ===
  PASS: ...
...
Results:  NN PASS, 0 FAIL
```

(Exact `NN` is the current suite size; it is at least 100.)

## Testing

The test suite in `tests.adb` covers:

- Singleton / two-element / three-element cases
- Min ($k=1$), max ($k=n$), and median
- Even-length lower-middle median convention
- Duplicates and all-equal arrays
- Already sorted, reverse, and nearly sorted inputs
- Negatives, zero, and mixed signed keys
- Non-1 `A'First` index bounds
- Post-select partition invariant
- `Invalid_Argument` for empty, $k > n$, and $n > \mathrm{Max\_N}`
- All 6 permutations of $\{1,2,3\}$ × all ranks
- All 24 permutations of $\{0,1,2,3\}$ × all ranks
- `Select_Kth_Copy` leaves the original unchanged
- Random arrays vs a naive sort-based reference (tests only)
- Larger $n$ ($500$) at several ranks

## Building

- Prerequisites: GNAT compiler supporting Ada 2022 / Ada 2023 (e.g. GNAT FSF
  13+, GNAT 14+, or GNAT Pro).
- Standard: ISO/IEC 8652:2023.
- Build flag: `-gnatwa -gnat2022` with zero compiler warnings.

## API

```ada
package Quickselect is
   Max_N : constant Positive := 100_000;
   type Element_Array is array (Natural range <>) of Integer;
   Invalid_Argument : exception;
   procedure Select_Kth (A : in out Element_Array; K : Positive);
   function Select_Kth_Copy (A : Element_Array; K : Positive)
     return Integer;
   function Median (A : in out Element_Array) return Integer;
end Quickselect;
```

`Select_Kth` and `Median` rearrange $A$ in place. `Select_Kth_Copy` leaves
the original unchanged. Raises `Invalid_Argument` if $A$ is empty,
$A'\mathit{Length} > \mathrm{Max\_N}$, or $K > A'\mathit{Length}$.

## License

Educational reference implementation. See repository `LICENSE` if present.
