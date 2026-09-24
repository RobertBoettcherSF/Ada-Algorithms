# Pigeonhole Sort in Ada 2023

## Project Overview

**Pigeonhole sort** is a sorting algorithm suited to lists where the number
of elements $n$ and the length $N$ of the range of possible key values are
approximately the same. It runs in

$$
O(n + N)
$$

time. The algorithm allocates one **pigeonhole** (bucket) for every key in
$[\mathrm{min}, \mathrm{max}]$, moves each item into the hole for its key,
then concatenates the holes in increasing key order.

This package is an **Ada 2023 (ISO/IEC 8652:2023)** educational
implementation for `Integer` arrays with a small key span. Placement into
holes is **stable** (left-to-right scatter into contiguous hole segments).

Primary source:
[Wikipedia — Pigeonhole sort](https://en.wikipedia.org/wiki/Pigeonhole_sort).

## Algorithm

Given an array $A$ of length $n$:

1. Find $\mathrm{min}$ and $\mathrm{max}$ among the elements.
2. Let $N = \mathrm{max} - \mathrm{min} + 1$. Allocate $N$ initially empty
   pigeonholes — one per key in the closed interval.
3. For each item in left-to-right order, place it into the hole indexed by
   $\mathrm{key} - \mathrm{min}$ (counts + stable scatter into a work
   buffer, equivalent to appending onto per-hole queues).
4. Iterate holes from low key to high key and write their contents back into
   $A$.

Empty and singleton arrays are no-ops. If $n > \mathrm{Max\_Length}$ or
$N > \mathrm{Max\_Range}$, `Sort` raises `Invalid_Argument`.

## When it is suitable

Pigeonhole sort shines when $N$ is $O(n)$ — for example sorting exam scores
in $0 \ldots 100$, small enums, or dense integer IDs. When $N \gg n$, the
hole array dominates both time and memory; **bucket sort** (fewer bins, each
sorted recursively) or a comparison sort is then preferable.

## Contrast with counting sort and bucket sort

| Algorithm | Auxiliary structure | Item movement | Best when |
| --------- | ------------------- | ------------- | --------- |
| **Pigeonhole** | One hole (list / segment) per key | Moves items into holes, then concatenates | $N \approx n$ |
| **Counting sort** | Count table of size $N$ | Builds counts, prefix sums, then places each item once at its computed destination | Same complexity class; count table only (no lists) |
| **Bucket sort** | $k \ll N$ buckets | Scatter into buckets, sort each, concatenate | $N \gg n$; keys map into few bins |

Wikipedia highlights the structural difference: pigeonhole sort
**moves items twice** — once into the hole array and again to the final
destination — whereas counting sort builds an auxiliary count array and uses
it to compute each item's final index. For pure `Integer` keys (value equals
key) both produce the same multiset; the educational point is the hole-list
vs. count-table design.

## Features

- **`Sort (A)`** — ascending pigeonhole sort on `Integer` arrays.
- **`Is_Sorted`** — nondecreasing predicate (empty/singleton count as sorted).
- **Stability** — equal keys keep left-to-right relative order.
- **Capacity guards** — `Invalid_Argument` when `A'Length > Max_Length` or
  key span $> \mathrm{Max\_Range}$ (both default $100\,000$).
- **Signed keys** — negatives and positives are handled via $\mathrm{min}$.
- **Arbitrary bounds** — works for any `A'First`.
- **Zero-warning build** — `gnatmake -gnatwa -gnat2022 -Ppigeonhole_sort.gpr`.

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
- Small dense ranges and already-sorted / reverse inputs
- Negatives mixed with positives, including near `Integer'First` / `Last`
- Duplicate keys (multiset vs. insertion-sort reference)
- Non-1 `A'First` index bounds
- Random arrays with compact ranges
- `Is_Sorted` true/false cases
- `Invalid_Argument` for oversized key range and oversized $n$

## Building

- Prerequisites: GNAT compiler supporting Ada 2022 / Ada 2023 (e.g. GNAT FSF
  13+, GNAT 14+, or GNAT Pro).
- Standard: ISO/IEC 8652:2023.
- Build flag: `-gnatwa -gnat2022` with zero compiler warnings.

## API

```ada
package Pigeonhole_Sort is
   Max_Length : constant Positive := 100_000;
   Max_Range  : constant Positive := 100_000;
   type Element_Array is array (Natural range <>) of Integer;
   Invalid_Argument : exception;
   procedure Sort (A : in out Element_Array);
   function Is_Sorted (A : Element_Array) return Boolean;
end Pigeonhole_Sort;
```

## License

Educational reference implementation. See repository `LICENSE` if present.
