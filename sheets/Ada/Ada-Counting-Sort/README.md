# Counting Sort in Ada 2023

## Project Overview

**Counting sort** is an integer sorting algorithm that counts how many
objects share each distinct key, then applies a **prefix sum** on those
counts to determine each key's positions in the output. Its running time is

$$
O(n + k)
$$

where $n$ is the number of items and $k$ is the span of key values
($\mathrm{max} - \mathrm{min} + 1$, or $0..k$ for nonnegative keys). It is
suitable when the key variation is not significantly greater than $n$.

This package is an **Ada 2023 (ISO/IEC 8652:2023)** educational
implementation of the **classic stable** form for `Integer` arrays: count,
prefix-sum, then place elements into the output **from right to left**.

Primary source:
[Wikipedia — Counting sort](https://en.wikipedia.org/wiki/Counting_sort).

## Algorithm

Given an array $A$ of length $n$:

1. Find $\mathrm{min}$ and $\mathrm{max}$ among the elements (or use a known
   nonnegative bound $k$).
2. Let $k = \mathrm{max} - \mathrm{min} + 1$. Allocate a count table of size
   $k$, initialized to zeros.
3. For each item, increment $\mathrm{Count}[\mathrm{key} - \mathrm{min}]$
   (histogram of key occurrences).
4. Prefix-sum the count table so $\mathrm{Count}[j]$ is the number of
   elements with key $\le j$ (exclusive end offset for that key).
5. Scan $A$ **from right to left**: for each item, decrement its count entry
   and write the item into that output slot. The reverse scan preserves the
   relative order of equal keys (**stability**).
6. Copy the output buffer back into $A$.

Empty and singleton arrays are no-ops. If $n > \mathrm{Max\_Length}$ or
$k > \mathrm{Max\_Range}$, `Sort` raises `Invalid_Argument`.

## Stability via reverse scan

Counting sort must be stable for use as a radix-sort subroutine. After
prefix sums, each key's count is the exclusive end of its output range.
Placing items **right-to-left** fills that range from the end toward the
start, so earlier equals land at lower indices and keep input order.

## Contrast with pigeonhole sort

| Algorithm | Auxiliary structure | Item movement | Best when |
| --------- | ------------------- | ------------- | --------- |
| **Counting sort** | Count table of size $k$ | Counts → prefix sums → place each item once at its computed destination | Same $O(n+k)$ class; numeric table only |
| **Pigeonhole** | One hole (list / segment) per key | Moves items into holes, then concatenates | $k \approx n$; hole lists vs. counts |
| **Bucket sort** | $m \ll k$ buckets | Scatter into buckets, sort each, concatenate | $k \gg n$; keys map into few bins |

Wikipedia notes that counting sort stores a **single number per key**,
whereas bucket/pigeonhole styles hold sets of items. For pure `Integer`
keys both counting and pigeonhole reconstruct the same multiset; the
educational point is the **count table + prefix sums + reverse place**
design versus hole lists. Sibling package: `ada-pigeonhole-sort`
(contrast only — this package does **not** `with` it).

## Features

- **`Sort (A)`** — ascending classic counting sort on `Integer` arrays.
- **`Is_Sorted`** — nondecreasing predicate (empty/singleton count as sorted).
- **Stability** — equal keys keep left-to-right relative order (reverse scan).
- **Capacity guards** — `Invalid_Argument` when `A'Length > Max_Length` or
  key span $> \mathrm{Max\_Range}$ (both default $100\,000$).
- **Signed keys** — negatives and positives via $\mathrm{min}$ offset.
- **Arbitrary bounds** — works for any `A'First`.
- **Zero-warning build** — `gnatmake -gnatwa -gnat2022 -Pcounting_sort.gpr`.

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
- Duplicate keys and **tagged stability** (encode arrival order in values)
- Non-1 `A'First` index bounds
- Random arrays with compact ranges
- `Is_Sorted` true/false cases
- `Invalid_Argument` for oversized key range and oversized $n$
- Multiset equality vs. stable insertion-sort reference

## Building

- Prerequisites: GNAT compiler supporting Ada 2022 / Ada 2023 (e.g. GNAT FSF
  13+, GNAT 14+, or GNAT Pro).
- Standard: ISO/IEC 8652:2023.
- Build flag: `-gnatwa -gnat2022` with zero compiler warnings.

## API

```ada
package Counting_Sort is
   Max_Length : constant Positive := 100_000;
   Max_Range  : constant Positive := 100_000;
   type Element_Array is array (Natural range <>) of Integer;
   Invalid_Argument : exception;
   procedure Sort (A : in out Element_Array);
   function Is_Sorted (A : Element_Array) return Boolean;
end Counting_Sort;
```

## License

Educational reference implementation. See repository `LICENSE` if present.
