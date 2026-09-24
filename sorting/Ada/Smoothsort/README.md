# Smoothsort in Ada 2023

## Project Overview

**Smoothsort** is a comparison-based, in-place sorting algorithm invented by
Edsger W. Dijkstra in 1981. It is a variant of heapsort that reorganizes the
input into a string of *Leonardo heaps* (Dijkstra's "stretches") rather than a
single binary heap. Like heapsort it guarantees

$$
\mathcal{O}(n \log n)
$$

comparisons in the worst case and is **not stable**. Unlike classical heapsort,
smoothsort adapts to partially ordered inputs: an already-sorted array is a
valid Leonardo-heap forest, so the algorithm approaches

$$
\mathcal{O}(n)
$$

on sorted (and many nearly sorted) sequences.

This package is an **Ada 2023 (ISO/IEC 8652:2023)** educational implementation
of Dijkstra's construction: grow a forest of max-heaps whose sizes are
Leonardo numbers, keep stretch roots ordered via "stepson" links (`trinkle`),
then shrink the forest while extracting the global maximum (already at the end
of the unsorted prefix) with `semitrinkle`.

Primary source: [Wikipedia — Smoothsort](https://en.wikipedia.org/wiki/Smoothsort).
Dijkstra's note: [EWD796a](https://raboof.github.io/ewd/EWD796a.html).

## Leonardo heaps

The Leonardo numbers resemble the Fibonacci sequence:

$$
L(0) = L(1) = 1, \qquad L(k) = L(k-1) + L(k-2) + 1 \quad (k \ge 2).
$$

The first few terms are

$$
1, 1, 3, 5, 9, 15, 25, 41, 67, 109, \ldots
$$

Each stretch is a full binary tree of size $L(k)$: a root plus two children of
orders $k-1$ and $k-2$. Dijkstra combines the two rightmost stretches into a
parent of size $L(k+2)$ exactly when their sizes are the consecutive Leonardo
numbers $L(k+1)$ and $L(k)$. The resulting forest covers any prefix length $n$
with $O(\log n)$ stretches whose sizes are (almost) strictly decreasing.

Roots of adjacent stretches are linked by a *stepson* edge so that the whole
forest forms one global max-heap with the maximum at the rightmost root. When
that root is "extracted," it is already in its final sorted position—no swap
with a distant leaf is required (the key contrast with top-down binary
heapsort).

## Algorithm sketch

1. **Grow.** For each new index, either start a singleton stretch of size
   $L(1)$ / $L(0)$, or merge the last two stretches when they form consecutive
   Leonardo sizes. Restore the heap invariant with `sift` (intra-tree) or
   `trinkle` (tree + stepson).
2. **Shrink.** Detach the rightmost root. If it had children, expose two new
   stretch roots and restore stepson order with `semitrinkle` (then `trinkle`
   / `sift` as needed).
3. Repeat until one element remains. Empty and singleton inputs are no-ops.

Stretch presence is encoded in a bit string $P$ together with the current
Leonardo pair $(b, c)$, following Dijkstra's $O(1)$-word bookkeeping.

## Features

- In-place ascending `Sort` on `Element_Array` of `Integer`
- Leonardo-number accessor for teaching the stretch sizes
- Adaptive best-case behaviour on sorted input
- Contract-style capacity guard: `Invalid_Argument` when
  `A'Length > Max_Length`
- `Is_Sorted` predicate for postconditions and tests
- Zero `-gnatwa` warnings under `-gnat2022`

## API

```ada
package Smoothsort is
   Max_Length         : constant Positive := 100_000;
   Max_Leonardo_Order : constant Natural  := 40;

   type Element_Array is array (Natural range <>) of Integer;
   Invalid_Argument : exception;

   function Leonardo (K : Natural) return Natural;
   procedure Sort (A : in out Element_Array);
   function Is_Sorted (A : Element_Array) return Boolean;
end Smoothsort;
```

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
Smoothsort test suite (Ada 2023)
...
Results:  103 PASS, 0 FAIL
```

## Complexity

| Case | Time | Notes |
|------|------|--------|
| Best (sorted) | $\mathcal{O}(n)$ | Sorted input is already a valid heap forest |
| Average | $\mathcal{O}(n \log n)$ | Same asymptotic class as heapsort |
| Worst | $\mathcal{O}(n \log n)$ | Each sift/trinkle is $\mathcal{O}(\log n)$ |
| Extra space | $\mathcal{O}(1)$ | Bit-vector of stretch orders + a few scalars |

## Testing

The suite in `tests.adb` covers Leonardo recurrence checks, empty/singleton
arrays, already-sorted and reverse-sorted inputs, duplicates, random vectors,
arbitrary index bounds, extreme `Integer` values, nearly sorted patterns, and
the oversize `Invalid_Argument` guard.

## Building

- Prerequisites: GNAT supporting Ada 2022 / Ada 2023 (e.g. GNAT FSF 13+).
- Standard: ISO/IEC 8652:2023.
- Flags: `-gnatwa -gnat2022` with zero compiler warnings.

```bash
gnatmake -gnatwa -gnat2022 -Psmoothsort.gpr
```
