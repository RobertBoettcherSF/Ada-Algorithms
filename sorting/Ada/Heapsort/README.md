# Heapsort in Ada 2023

## Project Overview

**Heapsort** is an efficient, comparison-based, in-place sorting algorithm.
It first reorganizes the input into a binary **max-heap**, then repeatedly
**extracts the maximum** (the root), placing it into a growing sorted
suffix—the same high-level idea as selection sort, but with heap-accelerated
selection. Invented by J. W. J. Williams (1964); the in-place bottom-up
`heapify` used here is due to Robert W. Floyd (1964).

Heapsort guarantees

$$
\mathcal{O}(n \log n)
$$

time in the best, average, and worst cases. It is **in-place** and **not
stable**. In practice a tuned quicksort is often faster on typical data, but
heapsort's hard $\mathcal{O}(n \log n)$ bound makes it a common fallback
inside introsort when quicksort degenerates.

This package is an **Ada 2023 (ISO/IEC 8652:2023)** educational implementation
of classic binary max-heap heapsort: Floyd bottom-up `Heapify` plus
extract-max with `Sift_Down`.

Primary source: [Wikipedia — Heapsort](https://en.wikipedia.org/wiki/Heapsort).

## Algorithm

Two phases on an array $A$ of length $n$:

1. **Build-heap (`Heapify`).** Treat $A$ as a complete binary tree. Every
   leaf is already a trivial heap. Starting at the parent of the last element
   and moving toward the root, call `Sift_Down` so each subtree becomes a
   max-heap. This costs $\mathcal{O}(n)$, not $\mathcal{O}(n \log n)$, because
   most subtrees are short:

$$
\sum_{h=0}^{\lfloor \log_2 n \rfloor} \frac{n}{2^{h+1}} \cdot O(h) = O(n).
$$

2. **Extract-max.** For $i = n-1$ down to $1$: swap the root (current
   maximum) with $A(i)$, shrink the heap by one, and `Sift_Down` the new
   root. Each sift costs $\mathcal{O}(\log n)$, so this phase is
   $\mathcal{O}(n \log n)$.

Overall:

$$
T(n) = O(n) + O(n \log n) = O(n \log n).
$$

Empty and singleton arrays are no-ops.

## Child-index formulas (0-based vs 1-based vs Ada)

Textbook presentations usually fix the index base:

| Base | Left child | Right child | Parent |
| ---- | ---------- | ----------- | ------ |
| 0-based | $2i+1$ | $2i+2$ | $\lfloor (i-1)/2 \rfloor$ |
| 1-based | $2i$ | $2i+1$ | $\lfloor i/2 \rfloor$ |

Ada unconstrained arrays may use **any** `A'First`. Applying a 1-based
formula to a 0-based slice (or the reverse) silently corrupts the tree.
This package therefore uses **logical 0-based offsets** relative to
`A'First`:

$$
\mathrm{Logical}(I) = I - A'\mathrm{First}
$$

$$
\mathrm{Left}(I) = A'\mathrm{First} + 2\cdot\mathrm{Logical}(I) + 1
$$

$$
\mathrm{Right}(I) = A'\mathrm{First} + 2\cdot\mathrm{Logical}(I) + 2
$$

$$
\mathrm{Parent}(I) = A'\mathrm{First} + \bigl\lfloor (\mathrm{Logical}(I)-1)/2 \bigr\rfloor
\quad (I > A'\mathrm{First})
$$

These match the Wikipedia 0-based identities after remapping indices onto
$0 \ldots n-1$.

## Contrast with smoothsort and selection sort

| Algorithm | Structure | Worst case | Adaptive? | Notes |
| --------- | --------- | ---------- | --------- | ----- |
| Selection sort | Linear scan for each next min/max | $\Theta(n^{2})$ | No | At most $n-1$ swaps; heapsort is “selection with a heap” |
| **Heapsort** | One binary max-heap | $\Theta(n \log n)$ | No | Simple; poor locality vs quicksort |
| Smoothsort | Forest of Leonardo heaps | $\Theta(n \log n)$ | Yes — $\sim O(n)$ on sorted input | Dijkstra (1981); more bookkeeping |

## Features

- **`Sift_Down`** — repair max-heap property at a damaged root.
- **`Heapify`** — Floyd bottom-up build-heap in $\mathcal{O}(n)$.
- **`Sort (A)`** — in-place ascending heapsort on `Integer` arrays.
- **`Is_Sorted`** — nondecreasing predicate (empty/singleton count as sorted).
- **Capacity guard** — `Invalid_Argument` when `A'Length > Max_Length`.
- **Arbitrary bounds** — First-relative child math works for any `A'First`.
- **Zero-warning build** — `gnatmake -gnatwa -gnat2022 -Pheapsort.gpr`.

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
...
Results:  NN PASS, 0 FAIL
```

(Exact `NN` is the current suite size; it is at least 40.)

## Testing

The suite in `tests.adb` covers:

- Empty, singleton, and two-element arrays
- Already sorted, fully reversed, and duplicate-heavy inputs
- A classic numeric worked example
- Negatives and `Integer'First` / `Integer'Last`
- Non-1-based index bounds (0-based, 5-based, 10-based)
- `Heapify` / `Sift_Down` max-heap invariants and one extract-max step
- Random arrays of several lengths matched against an insertion-sort reference
- Oversize arrays raising `Invalid_Argument`
- Idempotence of `Sort`

## Building

- Prerequisites: GNAT supporting Ada 2022 / Ada 2023 (e.g. GNAT FSF 13+).
- Standard: ISO/IEC 8652:2023.
- Flags: `-gnatwa -gnat2022` with zero compiler warnings.

## API Summary

| Entity | Role |
| ------ | ---- |
| `Element_Array` | Unconstrained `array (Natural range <>) of Integer` |
| `Max_Length` | Educational capacity bound (`100_000`) |
| `Invalid_Argument` | Raised on oversize length |
| `Sift_Down` | Restore max-heap at `Root` within `A'First .. Heap_Last` |
| `Heapify` | Bottom-up build of a binary max-heap |
| `Sort` | Ascending in-place heapsort (build-heap + extract-max) |
| `Is_Sorted` | Nondecreasing predicate |

## License

Educational reference package. Algorithm description follows the public
Wikipedia article on Heapsort.
