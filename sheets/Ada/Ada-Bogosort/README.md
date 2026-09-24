# Bogosort in Ada 2023

## Project Overview

**Bogosort** (also *permutation sort*, *stupid sort*) is a sorting algorithm based
on the **generate-and-test** paradigm: it successively generates permutations of
its input until it finds one that is sorted. The name is a portmanteau of
*bogus* and *sort*. It is **not** useful for practical sorting; the point is
pedagogical contrast with efficient algorithms.

Two flavours exist:

1. **Randomized** — shuffle repeatedly (Fisher–Yates) until sorted. Analogy:
   throw a deck of cards in the air, pick them up at random, repeat.
2. **Deterministic** — enumerate permutations in a fixed order until sorted.

This package implements the **deterministic** educational variant: advance the
array with **next-permutation** (lexicographic order, wrapping from last to
first) until `Is_Sorted` holds. That makes `Sort` reproducible and suitable for
unit tests. A random `Sort_Random` is intentionally omitted.

Because of factorial growth, `Max_N` is only $10$ (tests use $n \le 8$, with
reverse cases typically $\le 7$). Feeding bogosort $n=20$ will not finish in
reasonable time.

Primary source: [Wikipedia — Bogosort](https://en.wikipedia.org/wiki/Bogosort).

## Algorithm

### Randomized (classic, not used here)

```text
while A is not sorted:
    shuffle A randomly
```

If all keys are distinct, the expected number of comparisons is asymptotically
$(e-1)\,n!$, and the expected number of swaps is $(n-1)\,n!$. Overall expected
work is therefore on the order of

$$
O(n \cdot n!)
$$

Best case is already-sorted input ($n-1$ comparisons, no swaps). Worst case for
the random variant is unbounded.

### Deterministic (this package)

```text
while A is not sorted:
    A := next lexicographic permutation of A  (wrap last → first)
```

`next_permutation` finds the rightmost ascent, swaps in the rightmost
successor, and reverses the suffix (standard C++-style step). When the array is
already the last multiset permutation, it reverses fully to the first. For any
fixed multiset the sorted ascending arrangement is the first lexicographic
permutation, so the loop terminates in at most $n!$ steps.

Empty and singleton arrays are no-ops. If $n > \mathrm{Max\_N}$, `Sort` raises
`Invalid_Argument`.

### Example

For $A = [3, 1, 2]$:

| Step | State | Sorted? |
| ---- | ----- | ------- |
| start | $[3,1,2]$ | no |
| next | $[3,2,1]$ | no |
| next (wrap) | $[1,2,3]$ | yes → done |

(Real $n!$ tables grow fast; do not hand-simulate $n \gg 6$.)

## Why `Max_N` is tiny

Even the deterministic enumerator may walk nearly $n!$ permutations. With
$10! = 3\,628\,800$ already large for a classroom demo, `Max_N = 10` and tests
cap at $n \le 8$ ($8! = 40\,320$). Prefer reverse / already-sorted patterns for
larger tiny $n$; those finish in one check or one wrap.

## Complexity

| Aspect | Bound | Notes |
| ------ | ----- | ----- |
| Random expected | $O(n \cdot n!)$ | Classic shuffle-until-sorted |
| Deterministic worst | $O(n \cdot n!)$ | Up to $n!$ next-permutation steps |
| Best (sorted input) | $O(n)$ | Single `Is_Sorted` scan |
| Space | $O(1)$ extra | In-place aside from locals |
| Stability | N/A / unstable | Permutation rebuild; equals may reorder |
| Termination | Guaranteed (det.) | Random variant almost surely |

## Features

- **`Sort (A)`** — ascending deterministic bogosort on `Integer` arrays.
- **`Is_Sorted`** — nondecreasing predicate (empty/singleton count as sorted).
- **Capacity guard** — `Invalid_Argument` when `A'Length > Max_N` (default
  $10$).
- **Arbitrary bounds** — works for any `A'First`.
- **Negatives and duplicates** — full `Integer` domain; next-permutation
  respects multisets.
- **Zero-warning build** — `gnatmake -gnatwa -gnat2022 -Pbogosort.gpr`.

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
- Already-sorted, reverse ($\le 7$), and mixed inputs ($n \le 8$)
- Negatives, duplicates, and all-equal arrays
- Non-1 `A'First` index bounds
- Random arrays vs insertion-sort reference (tiny $n$ only)
- `Is_Sorted` true/false cases
- `Invalid_Argument` for oversize $n = \mathrm{Max\_N}+1$
- Idempotence (sorting a sorted array again)

**Never** feed bogosort random $n=12+$ — factorial cost will dominate.

## Building

- Prerequisites: GNAT compiler supporting Ada 2022 / Ada 2023 (e.g. GNAT FSF
  13+, GNAT 14+, or GNAT Pro).
- Standard: ISO/IEC 8652:2023.
- Build flag: `-gnatwa -gnat2022` with zero compiler warnings.

## API

```ada
package Bogosort is
   Max_N : constant Positive := 10;
   type Element_Array is array (Natural range <>) of Integer;
   Invalid_Argument : exception;
   procedure Sort (A : in out Element_Array);
   function Is_Sorted (A : Element_Array) return Boolean;
end Bogosort;
```

## License

Educational reference implementation. See repository `LICENSE` if present.
