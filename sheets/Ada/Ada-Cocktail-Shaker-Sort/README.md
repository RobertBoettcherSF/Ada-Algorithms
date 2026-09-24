# Cocktail Shaker Sort in Ada 2023

## Project Overview

**Cocktail shaker sort** (also known as **bidirectional bubble sort**,
**cocktail sort**, **shaker sort**, ripple sort, shuffle sort, or shuttle
sort) is a simple **comparison** sorting algorithm that extends **bubble
sort** by operating in **two directions**. A forward pass bubbles large
values toward the end of the list; a backward pass bubbles small values
toward the beginning. This helps move **turtles** (small keys near the end)
more quickly than unidirectional bubble sort, though the asymptotic cost
remains $O(n^2)$.

Like most bubble-sort variants, cocktail shaker sort is used primarily as
an **educational** tool. Production libraries prefer algorithms such as
quicksort, merge sort, or timsort.

This package is an **Ada 2023 (ISO/IEC 8652:2023)** educational
implementation of classic **in-place** cocktail shaker sort for `Integer`
arrays, with shrinking $\mathit{lo}..\mathit{hi}$ bounds and early exit on
a clean (swap-free) pass.

Primary source:
[Wikipedia — Cocktail shaker sort](https://en.wikipedia.org/wiki/Cocktail_shaker_sort).

## Algorithm

Given an array $A$ of length $n$:

1. If $n \le 1$, return — already sorted.
2. Set $\mathit{lo} \leftarrow A'\mathit{First}$, $\mathit{hi} \leftarrow A'\mathit{Last}$.
3. Repeat while $\mathit{lo} < \mathit{hi}$:
   - **Forward pass:** for each $i$ from $\mathit{lo}$ to $\mathit{hi}-1$, if
     $A(i) > A(i+1)$ then swap and note a swap. Then
     $\mathit{hi} \leftarrow \mathit{hi}-1$ (largest key is in place).
   - If the forward pass made **no** swaps, stop (already sorted).
   - **Backward pass:** for each $i$ from $\mathit{hi}-1$ down to $\mathit{lo}$,
     if $A(i) > A(i+1)$ then swap and note a swap. Then
     $\mathit{lo} \leftarrow \mathit{lo}+1$ (smallest key is in place).
   - If the backward pass made **no** swaps, stop.
4. If $n > \mathrm{Max\_N}$, `Sort` raises `Invalid_Argument`.

Empty and singleton arrays are no-ops.

### Differences from bubble sort

Bubble sort only passes bottom-to-top, so a single small value at the end
(**turtle**) moves left by one index per full pass. Cocktail shaker sort
alternates directions, so that turtle can travel leftward on the return
pass. Example: $(2,3,4,5,1)$ needs one cocktail round (forward + backward)
but four ascending bubble passes. Counting a cocktail round as two bubble
passes, cocktail sort is typically **less than twice** as fast as bubble
sort — a marginal practical gain, still $O(n^2)$.

### Pseudocode

$$
\begin{align*}
&\mathbf{procedure}\ \mathrm{CocktailShakerSort}(A): \\
&\quad \mathit{lo} \leftarrow A'\mathit{First};\ \mathit{hi} \leftarrow A'\mathit{Last} \\
&\quad \mathbf{while}\ \mathit{lo} < \mathit{hi}: \\
&\quad\quad \mathit{swapped} \leftarrow \mathbf{false} \\
&\quad\quad \mathbf{for}\ i \leftarrow \mathit{lo}\ \mathbf{to}\ \mathit{hi}-1: \\
&\quad\quad\quad \mathbf{if}\ A(i) > A(i+1):\ \mathrm{swap};\ \mathit{swapped} \leftarrow \mathbf{true} \\
&\quad\quad \mathbf{exit\ when}\ \mathbf{not}\ \mathit{swapped} \\
&\quad\quad \mathit{hi} \leftarrow \mathit{hi}-1 \\
&\quad\quad \mathit{swapped} \leftarrow \mathbf{false} \\
&\quad\quad \mathbf{for}\ i \leftarrow \mathit{hi}-1\ \mathbf{downto}\ \mathit{lo}: \\
&\quad\quad\quad \mathbf{if}\ A(i) > A(i+1):\ \mathrm{swap};\ \mathit{swapped} \leftarrow \mathbf{true} \\
&\quad\quad \mathbf{exit\ when}\ \mathbf{not}\ \mathit{swapped} \\
&\quad\quad \mathit{lo} \leftarrow \mathit{lo}+1
\end{align*}
$$

### Example

Start with $\{5, 1, 4, 2, 8, 0, 2\}$:

1. Forward: bubble $8$ to the end $\to$ $\{5, 1, 4, 2, 0, 2, 8\}$; shrink $\mathit{hi}$.
2. Backward: bubble $0$ to the front $\to$ $\{0, 5, 1, 4, 2, 2, 8\}$; raise $\mathit{lo}$.
3. Continue shrinking the window until a clean pass — result
   $\{0, 1, 2, 2, 4, 5, 8\}$.

Wikipedia turtle example $(2,3,4,5,1)$: one forward pass yields
$(2,3,4,1,5)$; one backward pass yields $(1,2,3,4,5)$.

## Complexity

| Measure | Bound |
| ------- | ----- |
| Time (best) | Near $O(n)$ on already/mostly sorted input (few passes, early exit) |
| Time (average) | $O(n^2)$ |
| Time (worst) | $O(n^2)$ — reverse sorted |
| Locally almost sorted | $O(kn)$ when every key is at most $k$ positions from its final place |
| Auxiliary space | $O(1)$ — in-place |
| Stability | **Yes** — only adjacent swaps of unequal keys; equals are not reordered |
| Relation | Bidirectional bubble sort; still a bubble-sort relative |

Cocktail shaker sort is a **comparison** sort and is **not** asymptotically
optimal. Knuth notes that bubble-sort refinements do not beat straight
insertion for large $N$; the algorithm remains educational.

## Features

- **`Sort (A)`** — ascending in-place cocktail shaker sort on `Integer`
  arrays (bidirectional bubble with $\mathit{lo}..\mathit{hi}$ bounds).
- **`Is_Sorted`** — nondecreasing predicate (empty/singleton count as
  sorted).
- **In-place** — $O(1)$ auxiliary memory beyond a few locals.
- **Stable** — adjacent unequal swaps only; equal-key order preserved.
- **Capacity guard** — `Invalid_Argument` when `A'Length > Max_N`
  (default $10\,000$).
- **Arbitrary bounds** — works for any `A'First`.
- **Negatives and duplicates** — full `Integer` domain.
- **Zero-warning build** — `gnatmake -gnatwa -gnat2022 -Pcocktail_shaker_sort.gpr`.

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
- Power-of-two and odd lengths; turtle / cocktail illustrations
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
package Cocktail_Shaker_Sort is
   Max_N : constant Positive := 10_000;
   type Element_Array is array (Natural range <>) of Integer;
   Invalid_Argument : exception;
   procedure Sort (A : in out Element_Array);
   function Is_Sorted (A : Element_Array) return Boolean;
end Cocktail_Shaker_Sort;
```

## License

Educational reference implementation. See repository `LICENSE` if present.
