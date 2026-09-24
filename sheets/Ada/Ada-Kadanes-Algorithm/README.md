# Kadane's algorithm (maximum subarray) — Ada 2023

Educational, self-contained Ada 2023 package for **Kadane's algorithm**: find a
contiguous subarray with the largest sum inside a one-dimensional array
$A[1..n]$. See

- [Wikipedia: Maximum subarray problem](https://en.wikipedia.org/wiki/Maximum_subarray_problem)
- [Wikipedia: Kadane's algorithm](https://en.wikipedia.org/wiki/Kadane%27s_algorithm)

This package implements the **nonempty** variant: empty subarrays are **not**
admitted. Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT
(`-gnat2022`).

Part of the **RobertBoettcherSF** Ada algorithm series.

## Problem

Find indices $i$ and $j$ with $1 \le i \le j \le n$ maximizing

$$
\sum_{x=i}^{j} A[x].
$$

**Example (Wikipedia).** For
$A = [-2,1,-3,4,-1,2,1,-5,4]$, the contiguous subarray $[4,-1,2,1]$ (indices
$4..7$) has sum $6$.

## All-negative policy

If every entry is negative, a maximum nonempty subarray is any length-$1$
window holding the **largest** (least negative) element. This package returns
that singleton (leftmost on ties). The empty-subarray convention (answer $0$)
is **not** used here; an empty input raises `Invalid_Argument`.

## Recurrence (Kadane)

Scan $A$ left to right. Let $\mathit{current}$ be the best sum of a subarray
**ending** at the current index $j$, and $\mathit{best}$ the best sum seen
anywhere in $A[1..j]$:

$$
\begin{aligned}
\mathit{current}(j)
  &= \max\bigl(A[j],\; \mathit{current}(j-1) + A[j]\bigr), \\
\mathit{best}(j)
  &= \max\bigl(\mathit{best}(j-1),\; \mathit{current}(j)\bigr),
\end{aligned}
$$

with $\mathit{current}(1)=\mathit{best}(1)=A[1]$. Restarting when
$A[j] > \mathit{current}(j-1)+A[j]$ begins a new candidate window at $j$.

**Complexity.** One pass: $O(n)$ time and $O(1)$ extra space (plus the input).

A $\Theta(n^{2})$ brute-force oracle (`Brute_Force` / `Brute_Force_Sum`) is
included for small-$n$ cross-checks in the test suite.

## API sketch

| Symbol | Role |
| --- | --- |
| `Element` / `Element_Array` | Integer entries; unconstrained array |
| `Result` | `Sum`, `First`, `Last` (1-based logical indices) |
| `Max_Subarray_Sum (A)` | Maximum contiguous sum ($O(n)$) |
| `Max_Subarray (A)` | Sum + witness window ($O(n)$) |
| `Brute_Force_Sum` / `Brute_Force` | $O(n^{2})$ educational oracles |
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
