# Comb Sort in Ada 2023

## Project Overview

**Comb sort** is a relatively simple **comparison** sorting algorithm
originally designed by **Włodzimierz Dobosiewicz** and Artur Borowy in
1980, later rediscovered (and named *Combsort*) by **Stephen Lacey** and
**Richard Box** in 1991. It improves on **bubble sort** in the same way
that Shellsort improves on insertion sort: elements that start far from
their intended position may move **more than one** index per swap.

The basic idea is to eliminate **turtles** — small values near the end of
the list that slow bubble sort tremendously — by comparing elements
separated by a large **gap** that shrinks over successive passes. Large
values near the start (**rabbits**) are not a problem for bubble sort;
turtles are.

This package is an **Ada 2023 (ISO/IEC 8652:2023)** educational
implementation of classic **in-place** comb sort for `Integer` arrays,
using the empirically preferred shrink factor $k \approx 1.3$.

Primary source:
[Wikipedia — Comb sort](https://en.wikipedia.org/wiki/Comb_sort).

## Algorithm

Given an array $A$ of length $n$:

1. If $n \le 1$, return — already sorted.
2. Set $\mathit{gap} \leftarrow n$.
3. Repeat:
   - Shrink: $\mathit{gap} \leftarrow \max\bigl(1,\ \lfloor \mathit{gap}/k\rfloor\bigr)$
     with $k \approx 1.3$, implemented in integer arithmetic as
     $$
     \mathit{gap} \leftarrow \max\bigl(1,\ \lfloor \mathit{gap}\cdot 10 / 13\rfloor\bigr).
     $$
   - Comb pass: for each $i$ with $i+\mathit{gap}$ in range, if
     $A(i) > A(i+\mathit{gap})$ then swap and note that a swap occurred.
   - Stop when $\mathit{gap} = 1$ **and** the pass made **no** swaps
     (final bubble-sort pass on a nearly ordered array).
4. If $n > \mathrm{Max\_N}$, `Sort` raises `Invalid_Argument`.

Empty and singleton arrays are no-ops.

### Shrink factor

Lacey and Box suggest $k = 1.3$ after testing over $200\,000$ random
lists of length about $1000$. Dobosiewicz had suggested $4/3 \approx 1.333$.
A value too small causes too many comparisons; a value too large leaves
turtles for the final gap-$1$ stage. This package uses $1.3$ via
$\lfloor \mathit{gap}\cdot 10/13\rfloor$.

(The optional Wikipedia “rule of 11” — bumping gaps $9$ or $10$ up to
$11$ — is **not** applied here; the classic shrink-and-comb loop above is
sufficient for a correct sort.)

### Pseudocode

$$
\begin{align*}
&\mathbf{procedure}\ \mathrm{CombSort}(A): \\
&\quad \mathit{gap} \leftarrow |A| \\
&\quad \mathbf{loop}: \\
&\quad\quad \mathit{gap} \leftarrow \max\bigl(1,\ \lfloor \mathit{gap}\cdot 10/13\rfloor\bigr) \\
&\quad\quad \mathit{swapped} \leftarrow \mathbf{false} \\
&\quad\quad \mathbf{for}\ i \leftarrow A'\mathit{First}\ \mathbf{to}\ A'\mathit{Last}-\mathit{gap}: \\
&\quad\quad\quad \mathbf{if}\ A(i) > A(i+\mathit{gap}): \\
&\quad\quad\quad\quad \mathrm{swap}(A(i), A(i+\mathit{gap})) \\
&\quad\quad\quad\quad \mathit{swapped} \leftarrow \mathbf{true} \\
&\quad\quad \mathbf{exit\ when}\ \mathit{gap}=1\ \mathbf{and}\ \mathbf{not}\ \mathit{swapped}
\end{align*}
$$

### Example

Start with $\{8, 4, 1, 56, 3, -44, 23, 6, 28, 0\}$ ($n=10$):

1. First gap $\lfloor 10\cdot 10/13\rfloor = 7$: compare pairs distance $7$.
2. Gaps shrink ($5$, $3$, $2$, …) until $\mathit{gap}=1$.
3. Final gap-$1$ bubble passes until a clean pass — result
   $\{-44, 0, 1, 3, 4, 6, 8, 23, 28, 56\}$.

## Complexity

| Measure | Bound |
| ------- | ----- |
| Time (best) | Near-linear on already-sorted input (few gap stages, clean final pass) |
| Time (average) | Empirically much better than $O(n^2)$ bubble sort; often cited near $O(n\log n)$ in practice |
| Time (worst) | $O(n^2)$ — adversarial arrangements remain possible |
| Auxiliary space | $O(1)$ — in-place |
| Stability | **No** — gapped swaps can reorder equal keys |
| Relation | Bubble sort with diminishing gap; peer of Shellsort among diminishing-increment sorts |

Comb sort is a **comparison** sort. It is mainly of educational interest
as a clear improvement over bubble sort that still uses only adjacent-style
compare/swap with a variable gap.

## Features

- **`Sort (A)`** — ascending in-place classic comb sort on `Integer`
  arrays (shrink factor $\approx 1.3$).
- **`Is_Sorted`** — nondecreasing predicate (empty/singleton count as
  sorted).
- **In-place** — $O(1)$ auxiliary memory beyond a few locals.
- **Unstable** — equal-key order is not preserved in general.
- **Capacity guard** — `Invalid_Argument` when `A'Length > Max_N`
  (default $100\,000$).
- **Arbitrary bounds** — works for any `A'First`.
- **Negatives and duplicates** — full `Integer` domain.
- **Zero-warning build** — `gnatmake -gnatwa -gnat2022 -Pcomb_sort.gpr`.

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
- Duplicate keys (unsorted relative order for equals is allowed)
- Non-1 `A'First` index bounds
- Random arrays vs an insertion-sort reference
- Power-of-two and odd lengths; comb / turtle illustrations
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
package Comb_Sort is
   Max_N : constant Positive := 100_000;
   type Element_Array is array (Natural range <>) of Integer;
   Invalid_Argument : exception;
   procedure Sort (A : in out Element_Array);
   function Is_Sorted (A : Element_Array) return Boolean;
end Comb_Sort;
```

## License

Educational reference implementation. See repository `LICENSE` if present.
