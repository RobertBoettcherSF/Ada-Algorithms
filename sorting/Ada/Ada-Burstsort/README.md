# Burstsort in Ada 2023

## Project Overview

**Burstsort** is a family of cache-efficient string sorting algorithms: variants
of traditional **MSD radix sort** that organise input in a **burst trie**.
Shared prefixes live in trie nodes; unsorted suffixes sit in *buckets*. When a
bucket grows past a threshold it is **burst** into a child trie node, giving
the algorithm its name. Small buckets are finished with a simple
comparison sort (here: insertion sort).

Although the asymptotic cost remains

$$
O(w n)
$$

(with $w$ the maximum string length and $n$ the number of strings)—the same
class as classic radix sort—the trie layout keeps related radixes close in
memory, so large real-world string sets often sort about **twice as fast** as
a naïve radix sort. Burstsort has been billed as one of the fastest practical
algorithms for large sets of strings.

This package is an **Ada 2023 (ISO/IEC 8652:2023)** *educational*
implementation with modest bounds (`Max_N = 256`, `Max_String_Len = 64`) so the
entire trie fits easily in cache and in a fixed node pool.

Primary source: [Wikipedia — Burstsort](https://en.wikipedia.org/wiki/Burstsort).

## Burst tries and cache efficiency

A **burst trie** (Heinz, Zobel & Williams) mixes:

1. **Trie nodes** — an array of $|\Sigma|$ child slots (here $|\Sigma| = 256$
   for Latin-1 `Character`), indexed by the next character after a common
   prefix of length `Depth`.
2. **Buckets** — compact arrays of string indices (suffixes) that have not yet
   been expanded.
3. **Burst** — when a bucket’s size exceeds `Burst_Threshold`, replace it with
   a child trie node and redistribute strings by the next character. Strings
   that end exactly at the current depth go into an `Ended` list (they sort
   before any proper extension of the same prefix).

Classic MSD radix sort scatters accesses across large digit counters; the burst
trie **clusters** strings that share a prefix into small buckets that fit in
cache, then only expands hot buckets. Most production burstsorts finish buckets
with multikey quicksort; this educational package uses **insertion sort**, which
is clear and optimal for the tiny threshold we use (`Burst_Threshold = 8`).

## Algorithm (this package)

For an input array $A$ of bounded strings:

1. Copy $A$ into a 1-based work buffer and allocate a root trie node at
   depth $0$.
2. **Insert** each string index: walk existing trie edges by successive
   characters; append to a leaf bucket (or to `Ended` when the string is
   exhausted). If a bucket’s count exceeds `Burst_Threshold`, **burst** it.
3. **Emit** by an in-order walk: first the `Ended` bucket (insertion-sorted),
   then child slots for character codes $0 .. 255$ (bucket or recursive trie).
4. Write the emitted order back into $A$.

Empty and singleton inputs are no-ops. Lengths above `Max_N`, or `Make` on a
string longer than `Max_String_Len`, raise `Invalid_Argument`.

## Features

- **`Sort (A)`** — lexicographic ascending burstsort on `String_Array`.
- **`Is_Sorted`** — nondecreasing predicate under `"<="`.
- **`Make` / `To_String`** — construct and recover ordinary Ada `String`s.
- **`"<"` / `"<="`** — lexicographic order on `Bounded_String` (shorter prefix
  is smaller after a common stem, matching Ada `String` rules).
- **Capacity guards** — `Invalid_Argument` on oversize arrays or strings.
- **Zero-warning build** — `gnatmake -gnatwa -gnat2022 -Pburstsort.gpr`.

## Complexity

With maximum string length $w$ and $n$ strings, each character of each string
is examined a constant number of times during insert and emit, so the cost is
$O(w n)$ plus the insertion-sort work on buckets of size at most
`Burst_Threshold` (and equal-string `Ended` lists). The educational node pool
holds at most `Max_Nodes = 512` trie nodes.

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

=== 1. Empty / singleton / trivial ===
  PASS: ...
...
Results:  NN PASS, 0 FAIL
```

## Testing

The test suite in `tests.adb` covers:

- **Functional correctness** — burstsort output matches a reference insertion
  sort on the same `Bounded_String` ordering.
- **Edge cases** — empty / singleton arrays, already sorted, reverse order,
  duplicates, empty strings, nested prefixes, non-1-based index bounds.
- **Burst stress** — many strings with a long shared prefix (forces bursts).
- **Random strings** — several sizes up to $n = 100$.
- **Error handling** — `Invalid_Argument` for oversize arrays and `Make`.

## Building

- Prerequisites: GNAT compiler supporting Ada 2022 / Ada 2023 (e.g. GNAT FSF
  13+, GNAT 14+, or GNAT Pro).
- Standard: ISO/IEC 8652:2023.
- Build flag: `-gnatwa -gnat2022` with zero compiler warnings.

## References

- Sinha, Ranjan; Zobel, Justin (2003). *Efficient Trie-Based Sorting of Large
  Sets of Strings*.
- Heinz, Steffen; Zobel, Justin; Williams, Hugh E. (2002). *Burst Tries: A
  Fast, Efficient Data Structure for String Keys*.
- [Wikipedia — Burstsort](https://en.wikipedia.org/wiki/Burstsort)

## File layout

Seven root files (no `main.adb`; `tests.adb` is the program entry point):

| File | Role |
| ---- | ---- |
| `burstsort.ads` | Package specification |
| `burstsort.adb` | Burst-trie sort implementation |
| `burstsort.gpr` | GNAT project file |
| `Makefile` | `make` / `make test` / `make clean` |
| `tests.adb` | Standalone Pass/Fail test suite |
| `README.md` | This document |
| `.gitignore` | Ignores `obj/`, `bin/`, compiler debris |

## License

Educational reference implementation. See repository `LICENSE` if present.
