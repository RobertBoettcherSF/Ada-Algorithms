# Strand Sort in Ada 2023

## Project Overview

**Strand sort** is a recursive sorting algorithm that repeatedly pulls
*increasing strands* (nondecreasing subsequences) out of an unsorted list and
merges each strand into a growing sorted output. It was described in educational
and systems literature and is also used inside **J Sort** for small inputs
(fewer than about 40 elements).

Time complexity depends strongly on how ordered the input already is:

$$
\begin{align*}
\text{best} &\colon O(n) && \text{(already sorted — one strand)} \\
\text{average} &\colon \sim O(n \log n) && \text{(often cited)} \\
\text{worst} &\colon O(n^2) && \text{(reverse-sorted — many unit strands)}
\end{align*}
$$

Because each strand extraction and merge walks lists, linked-list
implementations make removals and insertions cheap. This package uses an
**array simulation** (work buffer for the remaining input plus a merge into
the output) that is easy to read in Ada and still matches the classic
algorithm.

This package is an **Ada 2023 (ISO/IEC 8652:2023)** educational implementation
with a modest length bound (`Max_N = 4096`). Elements are ordinary `Integer`
values (negatives and duplicates allowed).

Primary source: [Wikipedia — Strand sort](https://en.wikipedia.org/wiki/Strand_sort).

## Algorithm

Given an array $A$ of length $n$:

1. Copy $A$ into an unsorted **input** work buffer; start with an empty
   **output** list.
2. **Extract a strand:** take the first remaining input element, then scan
   left-to-right and greedily append every later element that is
   $\ge$ the last taken value (a nondecreasing subsequence). Remove those
   elements from the input.
3. **Merge** the strand into the sorted output with a standard two-way merge.
4. Repeat steps 2–3 until the input is empty; copy the output back into $A$.

Empty and singleton arrays are no-ops. If $n > \mathrm{Max\_N}$, `Sort`
raises `Invalid_Argument`.

### Example

For $A = \{5, 1, 4, 2, 0, 9, 6, 3, 8, 7\}$ (Wikipedia walk-through, adapted
to nondecreasing strands with $\ge$):

| Step | Strand extracted | Remaining input | Sorted output after merge |
| ---- | ---------------- | --------------- | ------------------------- |
| 1 | $\{5, 9\}$ | $\{1, 4, 2, 0, 6, 3, 8, 7\}$ | $\{5, 9\}$ |
| 2 | $\{1, 4, 6, 8\}$ | $\{2, 0, 3, 7\}$ | $\{1, 4, 5, 6, 8, 9\}$ |
| 3 | $\{2, 3, 7\}$ | $\{0\}$ | $\{1, 2, 3, 4, 5, 6, 7, 8, 9\}$ |
| 4 | $\{0\}$ | $\{\}$ | $\{0, 1, 2, 3, 4, 5, 6, 7, 8, 9\}$ |

(Wikipedia's prose uses a strict $>$ test; this package uses $\ge$ so equal
keys ride the same strand, which is natural for a nondecreasing sort.)

## Complexity

| Case | Time | When |
| ---- | ---- | ---- |
| Best | $O(n)$ | Input already sorted — a single strand, one merge |
| Average | $\sim O(n \log n)$ | Typical random order (roughly $\log n$ strands) |
| Worst | $O(n^2)$ | Reverse-sorted — $n$ unit strands, each merged |

Auxiliary space is $O(n)$ for the input / output / strand work buffers.

Strand sort is a **comparison** algorithm: it does not rely on integer key
ranges the way counting or bead sort do. It can exploit existing order in the
input (long strands) without being a pure adaptive insertion-style method.

## Features

- **`Sort (A)`** — ascending strand sort on `Integer` arrays.
- **`Is_Sorted`** — nondecreasing predicate (empty/singleton count as sorted).
- **Capacity guard** — `Invalid_Argument` when `A'Length > Max_N` (default
  $4096$).
- **Arbitrary bounds** — works for any `A'First`.
- **Negatives and duplicates** — full `Integer` domain.
- **Zero-warning build** — `gnatmake -gnatwa -gnat2022 -Pstrand_sort.gpr`.

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
- Already-sorted, reverse, and mixed small inputs
- Negatives, duplicates, and all-equal arrays
- Wikipedia-style example multiset
- Non-1 `A'First` index bounds
- Random arrays vs insertion-sort reference
- `Is_Sorted` true/false cases
- `Invalid_Argument` for oversize $n$
- Idempotence (sorting a sorted array again)

## Building

- Prerequisites: GNAT compiler supporting Ada 2022 / Ada 2023 (e.g. GNAT FSF
  13+, GNAT 14+, or GNAT Pro).
- Standard: ISO/IEC 8652:2023.
- Build flag: `-gnatwa -gnat2022` with zero compiler warnings.

## API

```ada
package Strand_Sort is
   Max_N : constant Positive := 4_096;
   type Element_Array is array (Natural range <>) of Integer;
   Invalid_Argument : exception;
   procedure Sort (A : in out Element_Array);
   function Is_Sorted (A : Element_Array) return Boolean;
end Strand_Sort;
```

## License

Educational reference implementation. See repository `LICENSE` if present.
