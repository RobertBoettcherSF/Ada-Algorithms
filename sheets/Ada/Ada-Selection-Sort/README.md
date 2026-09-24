# Selection Sort in Ada 2023

## Project Overview

**Selection sort** is a simple in-place comparison sorting algorithm. It
partitions the input into a growing sorted prefix and an unsorted suffix.
Each pass finds the minimum (or maximum) element of the unsorted suffix and
swaps it into the next prefix slot. The algorithm is easy to analyse: the
comparison count does not depend on the data, and the number of swaps is at
most $n-1$.

This package is an **Ada 2023 (ISO/IEC 8652:2023)** educational implementation
of classic ascending selection sort, plus an optional descending variant.

Primary source: [Wikipedia — Selection sort](https://en.wikipedia.org/wiki/Selection_sort).

## Algorithm

For an array $A$ of length $n$ (here indexed $A'\mathrm{First} \ldots A'\mathrm{Last}$):

1. For each index $i$ from the first element through the second-to-last:
2. Scan $A(i \ldots \mathrm{Last})$ to find the index of the minimum.
3. Swap that minimum with $A(i)$.

After pass $i$, the prefix $A(\mathrm{First} \ldots i)$ holds the $i-\mathrm{First}+1$
smallest elements in order. Empty and singleton arrays are no-ops.

**Worked Wikipedia example** ($64, 25, 12, 22, 11$):

| Pass | Array after selecting next minimum |
| ---- | ---------------------------------- |
| 1    | $11, 25, 12, 22, 64$               |
| 2    | $11, 12, 25, 22, 64$               |
| 3    | $11, 12, 22, 25, 64$               |
| 4    | $11, 12, 22, 25, 64$               |

## Complexity

Comparisons form the triangular sum

$$
(n-1)+(n-2)+\cdots+1 = \sum_{i=1}^{n-1} i = \frac{n(n-1)}{2} = \Theta(n^{2}).
$$

So selection sort uses $O(n^{2})$ comparisons in every case (best, average,
and worst). It performs at most $n-1$ swaps — often cited as ~$n$ swaps —
which is attractive when writes are expensive (e.g. EEPROM / flash). Among
quadratic sorts it usually beats bubble sort, but insertion sort typically
needs fewer comparisons on partially ordered data. Heapsort can be viewed as
selection sort with a heap, reducing selection cost to $\Theta(\log n)$ per
element and overall time to $\Theta(n\log n)$.

Selection sort is **not stable** under the classic swap formulation (equal
keys may change relative order). A stable variant inserts the minimum and
shifts intervening elements, at the cost of $\Theta(n^{2})$ writes unless
the structure supports cheap inserts.

## Features

- **`Sort (A)`** — in-place ascending selection sort on `Integer` arrays.
- **`Sort_Descending (A)`** — same structure selecting maxima each pass.
- **`Is_Sorted` / `Is_Sorted_Descending`** — order predicates (empty and
  singleton count as sorted).
- **Capacity guard** — `Invalid_Argument` when `A'Length > Max_Length`.
- **Arbitrary bounds** — works for any `A'First` (not only 1-based).
- **Zero-warning build** — `gnatmake -gnatwa -gnat2022 -Pselection_sort.gpr`.

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
- The Wikipedia worked example
- Negatives and `Integer'First` / `Integer'Last`
- Non-1-based index bounds
- Ascending and descending sorts matched against an insertion-sort reference
- Random arrays of several lengths
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
| `Max_Length` | Educational capacity bound (`10_000`) |
| `Invalid_Argument` | Raised on oversize length |
| `Sort` | Ascending in-place selection sort |
| `Sort_Descending` | Descending in-place selection sort |
| `Is_Sorted` | Nondecreasing predicate |
| `Is_Sorted_Descending` | Nonincreasing predicate |

## License

Educational reference package. Algorithm description follows the public
Wikipedia article on Selection sort.
