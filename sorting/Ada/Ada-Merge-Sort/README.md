# Merge Sort in Ada 2023

## Project Overview

**Merge sort** (also spelled *mergesort*) is an efficient, general-purpose,
comparison-based sorting algorithm. Most implementations are **stable**: the
relative order of equal elements is the same in the input and the output.
Merge sort is a classic **divide-and-conquer** algorithm invented by
**John von Neumann** in 1945. A detailed description and analysis of
bottom-up merge sort appeared in a report by Goldstine and von Neumann as
early as 1948.

Its running time satisfies the recurrence

$$
T(n) = 2\,T(n/2) + \Theta(n)
$$

which by the master theorem for divide-and-conquer recurrences closes to

$$
\Theta(n \log n)
$$

in the best, average, and worst cases. Auxiliary space for the usual array
implementation is $\Theta(n)$ for a temporary merge buffer (plus
$O(\log n)$ stack frames for the top-down recursion).

This package is an **Ada 2023 (ISO/IEC 8652:2023)** educational
implementation of the **classic top-down stable** form for `Integer`
arrays: recursively split at the midpoint, sort each half, then stably
merge into a temp buffer and copy back.

Primary source:
[Wikipedia — Merge sort](https://en.wikipedia.org/wiki/Merge_sort).

## Algorithm

Given an array $A$ of length $n$ (indices $\mathrm{Lo}..\mathrm{Hi}$):

1. If $\mathrm{Lo} \ge \mathrm{Hi}$ (length $\le 1$), return — already
   sorted.
2. Let $\mathrm{Mid} = \lfloor (\mathrm{Lo} + \mathrm{Hi}) / 2 \rfloor$.
3. Recursively sort $A[\mathrm{Lo}..\mathrm{Mid}]$ and
   $A[\mathrm{Mid}+1..\mathrm{Hi}]$.
4. **Stable merge** the two sorted halves into a temporary buffer (when
   $L \le R$, take from the left half so equal keys keep input order),
   then copy the merged run back into $A[\mathrm{Lo}..\mathrm{Hi}]$.

Empty and singleton arrays are no-ops. If $n > \mathrm{Max\_N}$, `Sort`
raises `Invalid_Argument`.

### Stability

Merge sort is stable when the merge prefers the **left** run on ties
($L \le R$). That preserves the relative order of equal keys — the same
guarantee needed when merge sort is used as a radix-sort subroutine or
when secondary keys must survive a primary-key sort.

### Top-down vs bottom-up

| Style | Approach |
| ----- | -------- |
| **Top-down** (this package) | Recursively split until runs of length $\le 1$, then merge on the way back up |
| **Bottom-up** | Start with $n$ unit runs; iteratively merge adjacent pairs until one run remains |
| **Natural merge** | Exploit already-sorted runs in the input (Timsort builds on this idea) |

## Complexity

| Measure | Bound |
| ------- | ----- |
| Time (best / average / worst) | $\Theta(n \log n)$ |
| Comparisons (worst, rough) | $\approx n\lceil\lg n\rceil - 2^{\lceil\lg n\rceil} + 1$ |
| Auxiliary space | $\Theta(n)$ temp buffer + $O(\log n)$ recursion stack |
| Stability | Yes (with left-preferring merge) |

Unlike Slowsort (multiply-and-surrender), merge sort is practical:
$\mathrm{Max\_N} = 100\,000$ is a comfortable educational bound.

## Features

- **`Sort (A)`** — ascending classic top-down stable merge sort on
  `Integer` arrays.
- **`Is_Sorted`** — nondecreasing predicate (empty/singleton count as
  sorted).
- **Stability** — equal keys keep left-to-right relative order.
- **Capacity guard** — `Invalid_Argument` when `A'Length > Max_N`
  (default $100\,000$).
- **Arbitrary bounds** — works for any `A'First`.
- **Negatives and duplicates** — full `Integer` domain.
- **Zero-warning build** — `gnatmake -gnatwa -gnat2022 -Pmerge_sort.gpr`.

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
- Already-sorted / reverse / almost-sorted / alternating patterns
- Negatives mixed with positives; large-magnitude integers
- Duplicate keys and **tagged stability** (encode arrival order in values)
- Non-1 `A'First` index bounds
- Random arrays vs a stable insertion-sort reference
- Power-of-two and odd lengths
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
package Merge_Sort is
   Max_N : constant Positive := 100_000;
   type Element_Array is array (Natural range <>) of Integer;
   Invalid_Argument : exception;
   procedure Sort (A : in out Element_Array);
   function Is_Sorted (A : Element_Array) return Boolean;
end Merge_Sort;
```

## License

Educational reference implementation. See repository `LICENSE` if present.
