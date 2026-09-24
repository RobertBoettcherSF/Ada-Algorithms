# Bubble Sort in Ada 2023

## Project Overview

**Bubble sort** (sometimes called **sinking sort**) is a simple **comparison**
sorting algorithm that repeatedly steps through a list, comparing adjacent
pairs and swapping them when they are out of order. Passes continue until a
full pass performs **no swaps**, which means the list is fully sorted. The
name comes from the way larger elements "**bubble**" toward the end of the
list (or smaller ones "sink" toward the front, depending on perspective).

Bubble sort performs poorly in real-world use and is used primarily as an
**educational** tool. Production libraries prefer algorithms such as
quicksort, merge sort, or timsort. Even among simple $O(n^2)$ algorithms,
**insertion sort** is usually considerably faster.

This package is an **Ada 2023 (ISO/IEC 8652:2023)** educational
implementation of classic **in-place** bubble sort for `Integer` arrays,
with a shrinking unsorted suffix (last-swap bound) and early exit on a
clean (swap-free) pass.

Primary source:
[Wikipedia — Bubble sort](https://en.wikipedia.org/wiki/Bubble_sort).

## Algorithm

Given an array $A$ of length $n$:

1. If $n \le 1$, return — already sorted.
2. Set $\mathit{Bound} \leftarrow A'\mathit{Last}$.
3. Repeat while $\mathit{Bound} > A'\mathit{First}$:
   - Set $\mathit{swapped} \leftarrow \mathbf{false}$,
     $\mathit{newBound} \leftarrow A'\mathit{First}$.
   - For each $i$ from $A'\mathit{First}$ to $\mathit{Bound}-1$, if
     $A(i) > A(i+1)$ then swap, set $\mathit{swapped} \leftarrow \mathbf{true}$,
     and record $\mathit{newBound} \leftarrow i$.
   - If the pass made **no** swaps, stop (already sorted).
   - Otherwise $\mathit{Bound} \leftarrow \mathit{newBound}$ (everything
     after the last swap is already in final place).
4. If $n > \mathrm{Max\_N}$, `Sort` raises `Invalid_Argument`.

Empty and singleton arrays are no-ops. Using strict $>$ (not $\ge$) keeps
the sort **stable**: equal keys are never reordered.

### Rabbits and turtles

An element that must move toward the **end** ("rabbit") can travel many
positions in one pass via successive swaps. An element that must move
toward the **beginning** ("turtle") moves only one index per pass. If the
smallest key starts at the end, it needs $n-1$ passes to reach the front.
Variants such as **cocktail shaker sort** (bidirectional) and **comb sort**
(shrinking gap) attack the turtle problem while keeping the adjacent-swap
idea.

### Pseudocode

$$
\begin{align*}
&\mathbf{procedure}\ \mathrm{BubbleSort}(A): \\
&\quad \mathit{bound} \leftarrow A'\mathit{Last} \\
&\quad \mathbf{while}\ \mathit{bound} > A'\mathit{First}: \\
&\quad\quad \mathit{swapped} \leftarrow \mathbf{false} \\
&\quad\quad \mathit{newBound} \leftarrow A'\mathit{First} \\
&\quad\quad \mathbf{for}\ i \leftarrow A'\mathit{First}\ \mathbf{to}\ \mathit{bound}-1: \\
&\quad\quad\quad \mathbf{if}\ A(i) > A(i+1):\ \mathrm{swap};\ \mathit{swapped} \leftarrow \mathbf{true};\ \mathit{newBound} \leftarrow i \\
&\quad\quad \mathbf{exit\ when}\ \mathbf{not}\ \mathit{swapped} \\
&\quad\quad \mathit{bound} \leftarrow \mathit{newBound}
\end{align*}
$$

### Example

Start with $\{5, 1, 4, 2, 8\}$ (Wikipedia step-by-step):

1. Pass 1: swaps yield $\{1, 4, 2, 5, 8\}$; $8$ is in place; shrink bound.
2. Pass 2: one swap of $4$ and $2$ yields $\{1, 2, 4, 5, 8\}$.
3. Pass 3: no swaps — early exit. Result $\{1, 2, 4, 5, 8\}$.

## Complexity

| Measure | Bound |
| ------- | ----- |
| Time (best) | $O(n)$ — already sorted; one clean pass then exit |
| Time (average) | $O(n^2)$ |
| Time (worst) | $O(n^2)$ — reverse sorted |
| Auxiliary space | $O(1)$ — in-place |
| Stability | **Yes** — only adjacent swaps of unequal keys ($>$ not $\ge$) |
| Adaptive | Yes — few inversions need few passes |

Bubble sort is a **comparison** sort and is **not** asymptotically optimal.
Knuth notes that bubble sort has little to recommend it beyond a catchy
name; it remains a standard educational introduction to sorting.

## Features

- **`Sort (A)`** — ascending in-place classic bubble sort on `Integer`
  arrays (adjacent swaps, last-swap bound, early exit).
- **`Is_Sorted`** — nondecreasing predicate (empty/singleton count as
  sorted).
- **In-place** — $O(1)$ auxiliary memory beyond a few locals.
- **Stable** — adjacent unequal swaps only; equal-key order preserved.
- **Capacity guard** — `Invalid_Argument` when `A'Length > Max_N`
  (default $10\,000$).
- **Arbitrary bounds** — works for any `A'First`.
- **Negatives and duplicates** — full `Integer` domain.
- **Zero-warning build** — `gnatmake -gnatwa -gnat2022 -Pbubble_sort.gpr`.

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
- Duplicate keys (stable relative order for equals)
- Non-1 `A'First` index bounds
- Random arrays vs an insertion-sort reference ($n \le \sim 500$)
- Power-of-two and odd lengths; Wikipedia demo patterns
- Idempotence (sorting twice)
- `Is_Sorted` true/false cases
- `Invalid_Argument` for oversized $n$

## Building

- Prerequisites: GNAT compiler supporting Ada 2022 / Ada 2023 (e.g. GNAT FSF
  13+, GNAT 14+, or GNAT Pro).
- Standard: ISO/IEC 8652:2023.
- Build flag: `-gnatwa -gnat2022` with zero compiler warnings.

## API

```ada
package Bubble_Sort is
   Max_N : constant Positive := 10_000;
   type Element_Array is array (Natural range <>) of Integer;
   Invalid_Argument : exception;
   procedure Sort (A : in out Element_Array);
   function Is_Sorted (A : Element_Array) return Boolean;
end Bubble_Sort;
```

## License

Educational reference implementation. See repository `LICENSE` if present.
