# Introselect in Ada 2023

## Project Overview

**Introselect** (short for **introspective selection**) is a **hybrid**
selection algorithm invented by **David Musser** (1997), the selection
analogue of **introsort**. It starts with **Quickselect** (fast average
case, low overhead) and falls back to a **worst-case linear** pivot
strategy — the **Blum–Floyd–Pratt–Rivest–Tarjan median of medians** (BFPRT,
groups of 5) — when the Quickselect path does not progress rapidly enough.
The result is practical performance close to Quickselect with a
worst-case $O(n)$ guarantee intent.

This package is an **Ada 2023 (ISO/IEC 8652:2023)** educational
implementation of classic Musser introselect on unordered `Integer`
arrays:

- **Median-of-three** Quickselect steps with **Lomuto** partition
  (iterative one-sided shrink).
- Depth budget $2\lfloor\log_2 n\rfloor$ (classic Musser / introsort
  analogue).
- When the budget is exhausted, a **BFPRT median-of-medians** pivot is
  used; after that partition the depth budget is restored on the remaining
  subproblem.
- Average practical $\sim O(n)$; worst-case $O(n)$ intent via MoM pivots.

Primary source:
[Wikipedia — Introselect](https://en.wikipedia.org/wiki/Introselect).

Part of the **RobertBoettcherSF** Ada algorithm series.

## Contrast with selection / sort siblings

| Package | Idea |
| --- | --- |
| **Ada-Quickselect** | Pure Hoare Quickselect (median-of-three + Lomuto); worst $O(n^2)$ |
| **Ada-Selection-Algorithm** | Broader selection-problem sheet (same family) |
| **This package** (`Ada-Introselect`) | Quickselect + BFPRT MoM fallback (Musser) |
| **Ada-Introsort** | Sort analogue: quicksort + heapsort depth cutoff |
| **Ada-Quicksort** | Full sort: recurse into **both** sides |

README links only — **no** package `with` of siblings.

### Why the hybrid?

| Variant | Guarantee | Notes |
| --- | --- | --- |
| **Quickselect** | Average $O(n)$, worst $O(n^2)$ | Fast; median-of-three helps common inputs |
| **Median of medians alone** | Worst-case $O(n)$ | High pivot overhead |
| **Introselect** (this package) | Practical $\sim O(n)$ with worst-case $O(n)$ intent | Quickselect until depth limit, then MoM pivots |

Musser introduced introselect so generic library selection could tighten
performance requirements the way introsort did for sorting. (Many C++
library “introselect” variants instead fall back to heapselect and only
guarantee $O(n\log n)$ — this educational sheet follows the Wikipedia
MoM formulation.)

## Algorithm

Given an unordered array $A$ of length $n$ and a 1-based rank $k$
($1 \le k \le n$):

1. If $n = 0$, $n > \mathrm{Max\_N}$, or $k \notin [1,n]$, raise
   `Invalid_Argument`.
2. Set $\mathit{target} \leftarrow A'\mathit{First} + (k-1)$,
   $L \leftarrow A'\mathit{First}$, $R \leftarrow A'\mathit{Last}$, and

   $$
   \mathrm{depth} \leftarrow 2 \lfloor \log_2 n \rfloor.
   $$

3. While $L < R$:
   - If $\mathrm{depth} = 0$: compute a **BFPRT median-of-medians** pivot
     index on $A[L..R]$ (groups of 5), swap that element to $R$, and mark
     a fallback step.
   - Else: choose a **median-of-three** pivot among $A(L)$, $A(m)$, $A(R)$
     where $m = L + \lfloor(R-L)/2\rfloor$, place it at $R$, and set
     $\mathrm{depth} \leftarrow \mathrm{depth}-1$.
   - **Lomuto-partition** $A[L..R]$ around $A(R)$; let $P$ be the final
     pivot index.
   - If $P = \mathit{target}$, stop.
   - If $P > \mathit{target}$, set $R \leftarrow P-1$; else
     $L \leftarrow P+1$.
   - After a MoM fallback, restore
     $\mathrm{depth} \leftarrow 2\lfloor\log_2(R-L+1)\rfloor$ on the
     remaining subproblem.

4. After `Select_Kth`, $A(A'\mathit{First}+k-1)$ is the $k$-th smallest.

Elements before the rank index are $\le$ the result and elements after are
$\ge$ it (partition property); the two sides are **not** fully sorted.

### Pseudocode

$$
\begin{align*}
&\mathbf{procedure}\ \mathrm{Select\_Kth}(A,k): \\
&\quad \mathit{target} \leftarrow A'\mathit{First}+(k-1) \\
&\quad L \leftarrow A'\mathit{First};\ R \leftarrow A'\mathit{Last} \\
&\quad \mathrm{depth} \leftarrow 2\lfloor\log_2 n\rfloor \\
&\quad \mathbf{while}\ L < R: \\
&\quad\quad \mathbf{if}\ \mathrm{depth}=0: \\
&\quad\quad\quad \mathrm{Swap}(A,\ \mathrm{MoMIndex}(A,L,R),\ R) \\
&\quad\quad\quad \mathit{fallback} \leftarrow \mathbf{true} \\
&\quad\quad \mathbf{else}: \\
&\quad\quad\quad \mathrm{MedianOfThreeToHi}(A,L,R) \\
&\quad\quad\quad \mathrm{depth} \leftarrow \mathrm{depth}-1 \\
&\quad\quad\quad \mathit{fallback} \leftarrow \mathbf{false} \\
&\quad\quad P \leftarrow \mathrm{PartitionLomuto}(A,L,R) \\
&\quad\quad \mathbf{if}\ P = \mathit{target}:\ \mathbf{return} \\
&\quad\quad \mathbf{elsif}\ P > \mathit{target}:\ R \leftarrow P-1 \\
&\quad\quad \mathbf{else}:\ L \leftarrow P+1 \\
&\quad\quad \mathbf{if}\ \mathit{fallback}\ \mathbf{and}\ L < R: \\
&\quad\quad\quad \mathrm{depth} \leftarrow 2\lfloor\log_2(R-L+1)\rfloor
\end{align*}
$$

### Median-of-medians (BFPRT) sketch

Divide $A[L..R]$ into groups of five, sort each group, collect the group
medians, and recursively take the median of those medians. That value is a
pivot that discards a constant fraction of the input in the worst case —
the classic linear-time selection building block.

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
| Time (average / practical) | $\sim O(n)$ — Quickselect path |
| Time (worst, MoM pivots) | $O(n)$ intent — BFPRT fallback |
| Auxiliary space (`Select_Kth`) | $O(1)$ loop + $O(\log n)$ MoM recursion |
| Auxiliary space (`Select_Kth_Copy`) | $O(n)$ — temporary copy |

Switching strategy (depth limit $O(\log n)$, MoM when exhausted) follows
Musser’s introspective idea; see Wikipedia for the related partition-size
sum / halving checks.

## Features

- **`Select_Kth`** — in-place procedure; after return,
  $A(A'\mathit{First}+K-1)$ is the $k$-th smallest.
- **`Select_Kth_Copy`** — non-mutating; copies then selects; returns the value.
- **`Median`** — odd: middle; even: lower middle (documented).
- **Quickselect + MoM** — median-of-three until depth limit, then BFPRT.
- **Capacity guard** — `Invalid_Argument` when empty, $n > \mathrm{Max\_N}$,
  or $k$ out of range (default $\mathrm{Max\_N}=100\,000$).
- **Arbitrary bounds** — works for any `Natural` `A'First`.
- **Negatives and duplicates** — full `Integer` domain.
- **Zero-warning build** — `gnatmake -gnatwa -gnat2022 -Pintroselect.gpr`.

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
- Forced shallow depth / MoM path on adversarial-ish inputs

## Building

- Prerequisites: GNAT compiler supporting Ada 2022 / Ada 2023 (e.g. GNAT FSF
  13+, GNAT 14+, or GNAT Pro).
- Standard: ISO/IEC 8652:2023.
- Build flag: `-gnatwa -gnat2022` with zero compiler warnings.

## API

```ada
package Introselect is
   Max_N : constant Positive := 100_000;
   type Element_Array is array (Natural range <>) of Integer;
   Invalid_Argument : exception;
   procedure Select_Kth (A : in out Element_Array; K : Positive);
   function Select_Kth_Copy (A : Element_Array; K : Positive)
     return Integer;
   function Median (A : in out Element_Array) return Integer;
end Introselect;
```

`Select_Kth` and `Median` rearrange $A$ in place. `Select_Kth_Copy` leaves
the original unchanged. Raises `Invalid_Argument` if $A$ is empty,
$A'\mathit{Length} > \mathrm{Max\_N}$, or $K > A'\mathit{Length}$.

## License

Educational reference implementation. See repository `LICENSE` if present.
