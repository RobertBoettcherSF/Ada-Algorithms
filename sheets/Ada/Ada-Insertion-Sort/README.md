# Insertion Sort in Ada 2023

## Project Overview

**Insertion sort** is a simple **comparison** sorting algorithm that builds
the final sorted array one element at a time. It is much less efficient on
large lists than advanced algorithms such as quicksort, heapsort, or merge
sort, yet it remains valuable because it is:

- **Simple** to implement and reason about
- **Efficient for small** arrays (often used as a base case in hybrids)
- **Adaptive** — near-linear when the input is already substantially sorted
- **Stable** — equal keys keep their relative order
- **In-place** — only $O(1)$ extra memory
- **Online** — can sort as elements arrive

When people manually sort playing cards in a bridge hand, most use a method
similar to insertion sort.

This package is an **Ada 2023 (ISO/IEC 8652:2023)** educational
implementation of classic **stable in-place** insertion sort for `Integer`
arrays.

Primary source:
[Wikipedia — Insertion sort](https://en.wikipedia.org/wiki/Insertion_sort).

## Algorithm

Given an array $A$ of length $n$:

1. If $n \le 1$, return — already sorted.
2. For each index $i$ from the second element through the end:
   - Let $\mathit{Key} = A(i)$.
   - Shift every predecessor $A(j)$ with $A(j) > \mathit{Key}$ (equivalently
     $\mathit{Key} < A(j)$) one slot to the right. Use strict $<$ / $>$,
     **never** $\le$ / $\ge$, so equal keys are not moved past one another
     and the sort stays **stable**.
   - Insert $\mathit{Key}$ into the vacated slot.
3. After $k$ outer iterations the prefix of length $k+1$ is sorted.

Empty and singleton arrays are no-ops. If $n > \mathrm{Max\_N}$, `Sort`
raises `Invalid_Argument`.

### Example

Wikipedia's walk-through of $\{3, 7, 4, 9, 5, 2, 6, 1\}$ grows a sorted
prefix left-to-right; each new key is shifted left past strictly larger
neighbours until its place is found, ending at
$\{1, 2, 3, 4, 5, 6, 7, 9\}$.

## Complexity

| Measure | Bound |
| ------- | ----- |
| Time (best) | $O(n)$ — already sorted (one comparison per element) |
| Time (average) | $O(n^2)$ |
| Time (worst) | $O(n^2)$ — reverse sorted |
| Auxiliary space | $O(1)$ — in-place |
| Stability | **Yes** — strict $<$ when shifting |
| Adaptivity | Yes — $O(kn)$ when each element is at most $k$ places from its sorted position |
| Online | Yes — can insert each arriving element into a sorted prefix |

Insertion sort is a **comparison** sort. Good quicksort implementations
often fall back to it for tiny subarrays (commonly around ten elements).

## Features

- **`Sort (A)`** — ascending classic stable in-place insertion sort on
  `Integer` arrays.
- **`Is_Sorted`** — nondecreasing predicate (empty/singleton count as
  sorted).
- **In-place** — $O(1)$ auxiliary memory beyond a few locals.
- **Stable and online** — equal-key order preserved; adaptive on nearly
  sorted input.
- **Capacity guard** — `Invalid_Argument` when `A'Length > Max_N`
  (default $100\,000$).
- **Arbitrary bounds** — works for any `A'First`.
- **Negatives and duplicates** — full `Integer` domain.
- **Zero-warning build** — `gnatmake -gnatwa -gnat2022 -Pinsertion_sort.gpr`.

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
- Duplicate keys and **tagged stability** (key×1000 + arrival tag)
- Non-1 `A'First` index bounds
- Random arrays vs an insertion-sort reference (modest $n \le 500$)
- Power-of-two and odd lengths; Wikipedia-style small examples
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
package Insertion_Sort is
   Max_N : constant Positive := 100_000;
   type Element_Array is array (Natural range <>) of Integer;
   Invalid_Argument : exception;
   procedure Sort (A : in out Element_Array);
   function Is_Sorted (A : Element_Array) return Boolean;
end Insertion_Sort;
```

## License

Educational reference implementation. See repository `LICENSE` if present.
