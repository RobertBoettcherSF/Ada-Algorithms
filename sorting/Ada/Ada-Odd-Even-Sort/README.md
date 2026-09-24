# Odd–Even Sort in Ada 2023

## Project Overview

**Odd–even sort** (also called **odd–even transposition sort**, **brick
sort**, or **parity sort**) is a simple **comparison** sorting algorithm
originally designed for **parallel processors** with only local
left–right neighbour connections. Sequentially it behaves like a two-phase
cousin of **bubble sort**: adjacent pairs of one parity are compared and
swapped, then pairs of the other parity, repeating until the list is
sorted.

This package is an **Ada 2023 (ISO/IEC 8652:2023)** educational
implementation of classic **in-place sequential** odd–even sort for
`Integer` arrays. It is **not** Batcher's odd–even mergesort (a different,
more efficient sorting network).

Primary source:
[Wikipedia — Odd–even sort](https://en.wikipedia.org/wiki/Odd%E2%80%93even_sort).

Habermann presented the parallel neighbour form in 1972 (*Parallel Neighbor
Sort*). With one key per processor the parallel depth is $O(n)$ compare–
exchange rounds.

## Algorithm

Given an array $A$ of length $n$:

1. If $n \le 1$, return — already sorted.
2. Repeat until a full cycle performs **no** swaps:
   1. **Odd phase.** Compare/swap every odd-indexed adjacent pair.
   2. **Even phase.** Compare/swap every even-indexed adjacent pair.
3. If $n > \mathrm{Max\_N}$, `Sort` raises `Invalid_Argument`.

Swap only when $A(i) > A(i+1)$ (strict $>$ / never $\ge$), so equal keys
are not exchanged and the sort is **stable**.

### Index convention

Wikipedia's sequential listing is **zero-based** and starts with
**odd-indexed** pairs, then **even-indexed** pairs. This package follows
that convention in **offset-from-`A'First`** space, so any `A'First` works:

| Phase | 0-based offsets | Ada indices |
| ----- | --------------- | ----------- |
| Odd (first) | $(1,2),\ (3,4),\ \ldots$ | `A(A'First+1)` vs `A(A'First+2)`, … |
| Even (second) | $(0,1),\ (2,3),\ \ldots$ | `A(A'First)` vs `A(A'First+1)`, … |

In 1-based textbook indexing the odd phase is pairs $(2,3),\ (4,5),\ \ldots$
and the even phase is $(1,2),\ (3,4),\ \ldots$. Either phase order sorts
correctly when repeated until no swaps; Wikipedia's order is the one used
in the $n$-pass 0–1 proof.

Sequential pseudocode (0-based, matching this package):

$$
\begin{align*}
&\mathbf{procedure}\ \mathrm{OddEvenSort}(A[0..n-1]): \\
&\quad \mathbf{repeat} \\
&\quad\quad \mathit{swapped} \leftarrow \mathbf{false} \\
&\quad\quad \mathbf{for}\ i \leftarrow 1,3,5,\ldots\ \mathbf{while}\ i < n-1: \\
&\quad\quad\quad \mathbf{if}\ A[i] > A[i+1]: \\
&\quad\quad\quad\quad \mathrm{swap}(A[i], A[i+1]);\ \mathit{swapped} \leftarrow \mathbf{true} \\
&\quad\quad \mathbf{for}\ i \leftarrow 0,2,4,\ldots\ \mathbf{while}\ i < n-1: \\
&\quad\quad\quad \mathbf{if}\ A[i] > A[i+1]: \\
&\quad\quad\quad\quad \mathrm{swap}(A[i], A[i+1]);\ \mathit{swapped} \leftarrow \mathbf{true} \\
&\quad \mathbf{until}\ \mathit{swapped} = \mathbf{false}
\end{align*}
$$

### Example

Start with $\{5, 3, 1, 4, 2\}$ (0-based):

1. Odd phase: $3\leftrightarrow 1$, $4\leftrightarrow 2$ $\to$ $\{5, 1, 3, 2, 4\}$.
2. Even phase: $5\leftrightarrow 1$, $3\leftrightarrow 2$ $\to$ $\{1, 5, 2, 3, 4\}$.
3. Odd: $5\leftrightarrow 2$ $\to$ $\{1, 2, 5, 3, 4\}$.
4. Even: $5\leftrightarrow 3$ $\to$ $\{1, 2, 3, 5, 4\}$.
5. Odd: $5\leftrightarrow 4$ $\to$ $\{1, 2, 3, 4, 5\}$.
6. Even then a clean cycle with no swaps — done.

Empty and singleton arrays are no-ops.

### Parallel processors

On a linear array of processors with one value each, every processor
concurrently compare–exchanges with its neighbour, alternating odd–even
and even–odd pairings. That is $O(n)$ parallel rounds of $O(1)$ work.
The Baudet–Stevenson **odd–even merge-splitting** extension lets each
processor hold a sublist: sort locally, then merge-split with the
alternating neighbour.

This sequential package simulates the single-processor algorithm (each
phase walks the array left to right).

## Complexity

| Measure | Sequential | $n$ processors (1 key each) |
| ------- | ---------- | --------------------------- |
| Time (best) | $O(n)$ — already sorted (one odd + even phase) | $O(n)$ rounds |
| Time (average) | $O(n^2)$ | $O(n)$ rounds |
| Time (worst) | $O(n^2)$ — reverse sorted, $\le n$ passes | $O(n)$ rounds |
| Auxiliary space | $O(1)$ — in-place | $O(1)$ per processor |
| Stability | **Yes** — strict $>$ when swapping | Yes (same comparators) |

A **pass** in the 0–1 proof is one odd–even or even–odd phase. The list
is sorted in at most $n$ such passes, so sequential work is $O(n^2)$.
Odd–even sort is a **comparison** sort and is **not** optimal.

Related: **Batcher's odd–even mergesort** uses a different
compare–exchange network ($O((\log n)^2)$ depth with long-range wires).
Do not confuse the two.

## Features

- **`Sort (A)`** — ascending in-place odd–even (brick) sort on `Integer`
  arrays.
- **`Is_Sorted`** — nondecreasing predicate (empty/singleton count as
  sorted).
- **In-place** — $O(1)$ auxiliary memory beyond a few locals.
- **Stable** — equal-key order preserved (adjacent swap only on $>$).
- **Capacity guard** — `Invalid_Argument` when `A'Length > Max_N`
  (default $10\,000$).
- **Arbitrary bounds** — works for any `A'First`.
- **Negatives and duplicates** — full `Integer` domain.
- **Zero-warning build** — `gnatmake -gnatwa -gnat2022 -Podd_even_sort.gpr`.

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

(Exact `NN` is the current suite size; it is at least 70.)

## Testing

The test suite in `tests.adb` covers:

- Empty / singleton edge cases
- Already-sorted / reverse / almost-sorted / alternating patterns
- Negatives mixed with positives; large-magnitude integers
- Duplicate keys and **tagged stability** (key$\times 1000$ + arrival tag)
- Non-1 `A'First` index bounds
- Random arrays vs an insertion-sort reference (modest $n \le 500$)
- Power-of-two and odd lengths
- Idempotence (sorting twice)
- `Is_Sorted` true/false cases
- `Invalid_Argument` for oversized $n$
- Reverse / random arrays kept $\le \sim 500$ because sequential
  odd–even sort is $O(n^2)$

## Building

- Prerequisites: GNAT compiler supporting Ada 2022 / Ada 2023 (e.g. GNAT FSF
  13+, GNAT 14+, or GNAT Pro).
- Standard: ISO/IEC 8652:2023.
- Build flag: `-gnatwa -gnat2022` with zero compiler warnings.

## API

```ada
package Odd_Even_Sort is
   Max_N : constant Positive := 10_000;
   type Element_Array is array (Natural range <>) of Integer;
   Invalid_Argument : exception;
   procedure Sort (A : in out Element_Array);
   function Is_Sorted (A : Element_Array) return Boolean;
end Odd_Even_Sort;
```

## License

Educational reference implementation. See repository `LICENSE` if present.
