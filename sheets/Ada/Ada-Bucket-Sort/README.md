# Bucket Sort in Ada 2023

## Project Overview

**Bucket sort** (also called **bin sort**) is a distribution sorting algorithm
that scatters elements into a number of *buckets*, sorts each bucket
individually, then concatenates the buckets in order. It generalises
**pigeonhole sort** (multiple keys per bucket) and is a cousin of
most-significant-digit **radix sort**. With roughly uniform keys and
$k \approx n$ buckets it runs in **average linear time**.

This package is an **Ada 2023 (ISO/IEC 8652:2023)** *educational*
implementation for `Integer` arrays: $k = \min(n, \mathrm{Max\_Buckets})$
buckets, stable **insertion sort** inside each bucket, and a contiguous
scatter/gather layout (no linked lists).

Primary source: [Wikipedia — Bucket sort](https://en.wikipedia.org/wiki/Bucket_sort).

## Algorithm

Given an array $A$ of length $n$:

1. Find $\mathrm{min}$ and $\mathrm{max}$. If they are equal, stop (already sorted).
2. Choose $k = \min(n, \mathrm{Max\_Buckets})$ empty buckets.
3. **Scatter** each key $x$ into bucket
   $$
   \left\lfloor \frac{(k-1)\,(x - \mathrm{min})}{\mathrm{max} - \mathrm{min}} \right\rfloor
   $$
   so $\mathrm{min}$ maps to bucket $0$ and $\mathrm{max}$ to bucket $k-1$.
4. **Sort** each non-empty bucket with insertion sort (stable, excellent for
   small bins).
5. **Gather** buckets $0 .. k-1$ back into $A$.

Empty and singleton arrays are no-ops. Lengths above `Max_Length` raise
`Invalid_Argument`.

## Complexity

| Case | Cost |
| ---- | ---- |
| Average (uniform, $k \approx n$) | $O(n)$ |
| General average | $O\!\left(n + \dfrac{n^{2}}{k} + k\right)$ |
| Worst (all keys in one bucket) | $O(n^{2})$ with insertion sort |
| Extra space | $O(n + k)$ |

## Contrast with counting / pigeonhole sort

| Algorithm | Auxiliary structure | Best when |
| --------- | ------------------- | --------- |
| **Bucket sort** | $k$ buckets (often $k \approx n$) + per-bucket sort | Keys roughly uniform; range may be huge |
| **Counting sort** | Count table of size $\mathrm{max}-\mathrm{min}+1$ | Small key span; $O(n+k_{\mathrm{span}})$ worst case |
| **Pigeonhole** | One hole (list/segment) per key | Same small-span regime; moves items into holes |

Bucket sort with bucket size $1$ degenerates toward counting sort. Two buckets
behave like quicksort with a midpoint-of-range pivot. Sibling packages exist
for counting and pigeonhole sorts (contrast only — this package does **not**
`with` them).

## Features

- **`Sort (A)`** — ascending bucket sort on `Integer` arrays.
- **`Is_Sorted`** — nondecreasing predicate (empty/singleton count as sorted).
- **Stability** — equal keys keep left-to-right order (scatter + insertion sort).
- **Signed keys** — full `Integer` range via 64-bit bucket arithmetic.
- **Wide spans** — does **not** allocate one slot per key; only $k$ buckets.
- **Capacity guard** — `Invalid_Argument` when `A'Length > Max_Length`.
- **Zero-warning build** — `gnatmake -gnatwa -gnat2022 -Pbucket_sort.gpr`.

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

## Testing

The test suite in `tests.adb` covers:

- Empty / singleton edge cases
- Already-sorted / reverse / duplicates
- Negatives, positives, and `Integer'First` / `Integer'Last` extremes
- Tagged **stability** (encode arrival order in values)
- Non-1 `A'First` index bounds
- Random arrays, clustering, and **wide key spans**
- `Is_Sorted` true/false cases
- `Invalid_Argument` for oversized $n$
- Multiset equality vs. stable insertion-sort reference

## Building

- Prerequisites: GNAT compiler supporting Ada 2022 / Ada 2023 (e.g. GNAT FSF
  13+, GNAT 14+, or GNAT Pro).
- Standard: ISO/IEC 8652:2023.
- Build flag: `-gnatwa -gnat2022` with zero compiler warnings.

## File layout

Seven root files (no `main.adb`; `tests.adb` is the program entry point):

| File | Role |
| ---- | ---- |
| `bucket_sort.ads` | Package specification |
| `bucket_sort.adb` | Scatter / insertion-sort / gather |
| `bucket_sort.gpr` | GNAT project file |
| `Makefile` | `make` / `make test` / `make clean` |
| `tests.adb` | Standalone Pass/Fail test suite |
| `README.md` | This document |
| `.gitignore` | Ignores `obj/`, `bin/`, compiler debris |

## References

- Cormen, Leiserson, Rivest, Stein. *Introduction to Algorithms* — Bucket sort.
- [Wikipedia — Bucket sort](https://en.wikipedia.org/wiki/Bucket_sort)

## License

Educational reference implementation. See repository `LICENSE` if present.
