# Shellsort in Ada 2023

## Project Overview

**Shellsort** (also spelled *Shell sort* or *Shell's method*) is an
**in-place** comparison sort published by **Donald Shell** in 1959. It
generalizes insertion sort (and can also be viewed as a generalization of
bubble sort): instead of comparing only adjacent keys, it first sorts
pairs of elements far apart, then progressively reduces the gap until a
final ordinary insertion-sort pass with gap $1$.

The idea is to arrange the array so that, starting anywhere, taking every
$h$-th element produces a sorted list — the array is then said to be
**$h$-sorted**. Beginning with large $h$ moves distant out-of-order keys
quickly; smaller gaps finish the work on nearly ordered subsequences,
where insertion sort is efficient.

This package is an **Ada 2023 (ISO/IEC 8652:2023)** educational
implementation of classic Shellsort for `Integer` arrays. The gap
sequence is **Marcin Ciura's** empirically derived list, extended for
$n > 701$ by successive

$$
h_k = \lfloor 2.25\, h_{k-1}\rfloor
$$

(and consumed descending with $h := \lfloor h / 2.25\rfloor$), matching
the Wikipedia recommendation for continuing Ciura beyond the tabulated
values.

Primary source:
[Wikipedia — Shellsort](https://en.wikipedia.org/wiki/Shellsort).

## Algorithm

Given an array $A$ of length $n$:

1. If $n \le 1$, return — already sorted.
2. Choose a decreasing gap sequence that ends with $1$ (see below).
3. For each gap $h$ in that sequence with $h < n$:
   - **$h$-sort** $A$: run insertion sort independently on each of the
     $h$ interleaved subsequences
     $A(i),\ A(i+h),\ A(i+2h),\ \ldots$ for $i = A'\mathrm{First},
     \ldots$.
4. The final $h = 1$ pass is ordinary insertion sort and leaves $A$ fully
   sorted.

Empty and singleton arrays are no-ops. If $n > \mathrm{Max\_N}$, `Sort`
raises `Invalid_Argument`.

### Gap sequence (Ciura + $2.25$ extension)

| Role | Gaps |
| ---- | ---- |
| Published Ciura (descending) | $701,\ 301,\ 132,\ 57,\ 23,\ 10,\ 4,\ 1$ |
| Extension for $n > 701$ | Grow from $701$ with $h_k = \lfloor 2.25\, h_{k-1}\rfloor$ while $h_k < n$; apply descending with $h := \lfloor h / 2.25\rfloor$ until $701$, then the published list |

Any gap sequence that contains $1$ yields a correct sort; Ciura's sequence
has the best known average comparison count among common practical
choices. This package does **not** use Shell's original $n/2,\ n/4,\ \ldots$
sequence (which can hit $\Theta(n^2)$ on some adversarial inputs).

### Example (gaps $5$, $3$, $1$)

Wikipedia's short illustration: a $5$-sort insertion-sorts five
subsequences, a $3$-sort three subsequences, then a $1$-sort finishes.
Subarrays start short; later they are longer but nearly ordered — both
regimes favor insertion sort.

## Complexity

| Measure | Bound (typical / remarks) |
| ------- | ------------------------- |
| Time (best, adaptive) | Near-linear on already-sorted or nearly sorted input |
| Time (average, Ciura-class) | Empirically well below $O(n^2)$; exact average for Ciura is open |
| Time (worst) | Depends on the gap sequence; Ciura's proven worst case is unsettled; Pratt gaps give $O(n\log^2 n)$ |
| Auxiliary space | $O(1)$ — in-place |
| Stability | **No** — gapped insertions can reorder equal keys |
| Adaptivity | Yes — fewer moves when input is partially sorted |

Shellsort is a **comparison** sort. Unlike merge sort it needs no
$\Theta(n)$ buffer; unlike heapsort its practical speed depends strongly
on the chosen gaps.

## Features

- **`Sort (A)`** — ascending classic Shellsort on `Integer` arrays
  (Ciura gaps + $\lfloor 2.25\,h\rfloor$ extension).
- **`Is_Sorted`** — nondecreasing predicate (empty/singleton count as
  sorted).
- **In-place** — $O(1)$ auxiliary memory beyond a few locals.
- **Capacity guard** — `Invalid_Argument` when `A'Length > Max_N`
  (default $100\,000$).
- **Arbitrary bounds** — works for any `A'First`.
- **Negatives and duplicates** — full `Integer` domain (not stable).
- **Zero-warning build** — `gnatmake -gnatwa -gnat2022 -Pshell_sort.gpr`.

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
- Duplicate keys (value order vs insertion-sort reference)
- Non-1 `A'First` index bounds
- Random arrays vs an insertion-sort reference
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
package Shell_Sort is
   Max_N : constant Positive := 100_000;
   type Element_Array is array (Natural range <>) of Integer;
   Invalid_Argument : exception;
   procedure Sort (A : in out Element_Array);
   function Is_Sorted (A : Element_Array) return Boolean;
end Shell_Sort;
```

## License

Educational reference implementation. See repository `LICENSE` if present.
