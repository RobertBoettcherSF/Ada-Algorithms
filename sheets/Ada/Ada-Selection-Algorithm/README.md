# Selection Algorithm in Ada 2023

## Project Overview

A **selection algorithm** finds the $k$-th smallest value in a collection of
orderable values — the **$k$-th order statistic**. Special cases include the
minimum ($k=1$), the maximum ($k=n$), and the median.

This package is an **Ada 2023 (ISO/IEC 8652:2023)** educational
implementation of **Quickselect-style** selection on unordered `Integer`
arrays: in-place partitioning with a **median-of-three** pivot and
**Lomuto** partition, average $O(n)$ time, worst-case $O(n^2)$, and $O(1)$
extra space for the mutating form.

Primary source:
[Wikipedia — Selection algorithm](https://en.wikipedia.org/wiki/Selection_algorithm).

Part of the **RobertBoettcherSF** Ada algorithm series.

## Contrast with selection siblings

| Package | Idea |
| --- | --- |
| **This package** (`Ada-Selection-Algorithm`) | Clear Select via Quickselect (median-of-three + Lomuto) |
| **Ada-Quickselect** (later sheet) | Focused Quickselect variants / analysis |
| **Ada-Introselect** (later sheet) | Hybrid Quickselect + median-of-medians fallback |

README links only — **no** package `with` of siblings.

## Survey of approaches

Wikipedia surveys several families of selection methods:

| Approach | Idea | Typical cost |
| --- | --- | --- |
| **Sorting** | Fully sort, then read index $k$ | $O(n\log n)$ |
| **Heaps** | Build a heap / heapselect | $O(n + k\log n)$ or similar |
| **Median of medians** | Deterministic good pivot (Blum et al.) | Worst-case $O(n)$ |
| **Quickselect** | Quicksort-style partition; recurse one side | Average $O(n)$, worst $O(n^2)$ |
| **Introselect** | Quickselect with median-of-medians fallback | Practical $O(n)$ with worst-case $O(n)$ |

This package implements a clear **Select** in the Quickselect family.
Dedicated **Quickselect** and **Introselect** packages are covered on later
sheets.

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
   - If $P = \mathit{target}$, return $A(P)$.
   - If $P > \mathit{target}$, set $R \leftarrow P-1$; else
     $L \leftarrow P+1$.
4. Return $A(L)$.

After `Select_Kth`, elements before the rank index are $\le$ the result and
elements after are $\ge$ it (partition property), but the two sides are not
fully sorted.

### Pseudocode

$$
\begin{align*}
&\mathbf{function}\ \mathrm{Select\_Kth}(A,k): \\
&\quad \mathit{target} \leftarrow A'\mathit{First}+(k-1);\ L \leftarrow A'\mathit{First};\ R \leftarrow A'\mathit{Last} \\
&\quad \mathbf{while}\ L < R: \\
&\quad\quad \mathrm{MedianOfThreeToHi}(A,L,R) \\
&\quad\quad P \leftarrow \mathrm{PartitionLomuto}(A,L,R) \\
&\quad\quad \mathbf{if}\ P = \mathit{target}:\ \mathbf{return}\ A(P) \\
&\quad\quad \mathbf{elsif}\ P > \mathit{target}:\ R \leftarrow P-1 \\
&\quad\quad \mathbf{else}:\ L \leftarrow P+1 \\
&\quad \mathbf{return}\ A(L)
\end{align*}
$$

### Median convention

- **Odd** $n$: rank $k = (n+1)/2$ (true middle).
- **Even** $n$: **lower middle** $k = n/2$ (document: upper middle would be
  $n/2+1$).

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
| Comparisons (expected) | $\sim cn$ for a small constant $c$ |

Median-of-three reduces (but does not eliminate) sorted-input pathologies
compared with a fixed end pivot. Guaranteed linear worst-case selection
needs median-of-medians or **Introselect** (sibling sheet).

## Features

- **`Select_Kth`** — in-place Quickselect; rearranges $A$.
- **`Select_Kth_Copy`** — non-mutating; copies then selects.
- **`Median`** — odd: middle; even: lower middle (documented).
- **Median-of-three + Lomuto** — deterministic, random-free pivot.
- **Capacity guard** — `Invalid_Argument` when empty, $n > \mathrm{Max\_N}$,
  or $k$ out of range (default $\mathrm{Max\_N}=100\,000$).
- **Arbitrary bounds** — works for any `Natural` `A'First`.
- **Negatives and duplicates** — full `Integer` domain.
- **Zero-warning build** — `gnatmake -gnatwa -gnat2022 -Pselection_algorithm.gpr`.

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

(Exact `NN` is the current suite size; it is at least 60.)

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
- `Invalid_Argument` for empty, $k > n$, and $n > \mathrm{Max\_N}$
- Random arrays vs a naive sort-based reference (tests only)
- Larger $n$ ($500$) at several ranks
- All ranks on a small permutation

## Building

- Prerequisites: GNAT compiler supporting Ada 2022 / Ada 2023 (e.g. GNAT FSF
  13+, GNAT 14+, or GNAT Pro).
- Standard: ISO/IEC 8652:2023.
- Build flag: `-gnatwa -gnat2022` with zero compiler warnings.

## API

```ada
package Selection_Algorithm is
   Max_N : constant Positive := 100_000;
   type Element_Array is array (Natural range <>) of Integer;
   Invalid_Argument : exception;
   function Select_Kth (A : in out Element_Array; K : Positive)
     return Integer;
   function Select_Kth_Copy (A : Element_Array; K : Positive)
     return Integer;
   function Median (A : in out Element_Array) return Integer;
end Selection_Algorithm;
```

`Select_Kth` and `Median` rearrange $A$ in place. `Select_Kth_Copy` leaves
the original unchanged. Raises `Invalid_Argument` if $A$ is empty,
$A'\mathit{Length} > \mathrm{Max\_N}$, or $K > A'\mathit{Length}$.

## License

Educational reference implementation. See repository `LICENSE` if present.
