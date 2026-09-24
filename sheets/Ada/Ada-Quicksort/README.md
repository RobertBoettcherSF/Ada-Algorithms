# Quicksort in Ada 2023

## Project Overview

**Quicksort** is an efficient, comparison-based, **divide-and-conquer** sorting
algorithm invented by **Tony Hoare** in 1959 and published in 1961. When
implemented well it is often two or three times faster than merge sort or
heapsort on typical data, thanks to excellent cache locality and a small
constant factor.

This package is an **Ada 2023 (ISO/IEC 8652:2023)** educational implementation
of **classic in-place quicksort** for `Integer` arrays:

- **Median-of-three** pivot (first / middle / last) to avoid the common
  $O(n^2)$ pathology on already-sorted or reverse-sorted inputs.
- **Hoare partition** (not Lomuto): two inward-scanning indices that swap
  inversions until they cross.
- Recurse on both sides of the split. No insertion-sort hybrid — see the
  companion **Introsort** package for depth-limited / small-partition hybrids.

The sort is **unstable** and **ascending**. Average time is $O(n \log n)$;
worst case remains $O(n^2)$ on carefully crafted adversarial inputs (median-
of-three mitigates but does not eliminate every killer sequence). Extra space
is $O(\log n)$ average recursion stack (worst $O(n)$).

Primary source: [Wikipedia — Quicksort](https://en.wikipedia.org/wiki/Quicksort).

## Algorithm

Given an array $A$ of length $n$:

1. If $n \le 1$, return (empty / singleton are no-ops).
2. Choose a **pivot** as the median of $A(\mathrm{Lo})$, $A(\mathrm{Mid})$,
   and $A(\mathrm{Hi})$, and move that median value to $\mathrm{Lo}$.
3. **Hoare-partition** so that every element in $A(\mathrm{Lo} .. P)$ is
   $\le$ every element in $A(P+1 .. \mathrm{Hi})$.
4. Recursively quicksort both sides.
5. If $n > \mathrm{Max\_N}$, `Sort` raises `Invalid_Argument`.

Pseudocode (1-based sketch; this Ada package uses inclusive Hoare indices):

$$
\begin{align*}
&\mathbf{procedure}\ \mathrm{sort}(A): \\
&\quad \mathbf{if}\ \mathrm{length}(A) \le 1:\ \mathbf{return} \\
&\quad p \leftarrow \mathrm{partition}(A) \\
&\quad \mathrm{sort}(A[1:p]) \\
&\quad \mathrm{sort}(A[p+1:n]) \\[0.5em]
&\mathbf{function}\ \mathrm{partition}(A):\ \text{(Hoare + median-of-three)} \\
&\quad \mathrm{pivot} \leftarrow \mathrm{median}(A_1, A_{\lfloor n/2 \rfloor}, A_n) \\
&\quad i \leftarrow 0;\ j \leftarrow n+1 \\
&\quad \mathbf{loop} \\
&\quad\quad \mathbf{repeat}\ i \leftarrow i+1\ \mathbf{until}\ A_i \ge \mathrm{pivot} \\
&\quad\quad \mathbf{repeat}\ j \leftarrow j-1\ \mathbf{until}\ A_j \le \mathrm{pivot} \\
&\quad\quad \mathbf{if}\ i \ge j:\ \mathbf{return}\ j \\
&\quad\quad \mathrm{swap}(A_i, A_j)
\end{align*}
$$

### Why median-of-three?

Naive “first element” or “last element” pivots make already-sorted and
reverse-sorted arrays degenerate to $\Theta(n^2)$. Median-of-three picks a
middle-ish key on those patterns and keeps splits reasonably balanced for
common classroom inputs. Random or dual-pivot schemes are alternatives;
introsort adds a heapsort depth cutoff for a hard $O(n \log n)$ worst case.

### Hoare vs Lomuto

| Scheme | Idea | Notes |
| ------ | ---- | ----- |
| **Hoare** (this package) | Two indices scan inward; swap inversions | Fewer swaps on average; pivot may land on either side |
| Lomuto | One scan; swap each $\le$ pivot toward the front | Simpler to teach; more swaps |

## Complexity

| Case | Time | Extra space |
| ---- | ---- | ----------- |
| Best | $O(n \log n)$ | $O(\log n)$ stack |
| Average | $O(n \log n)$ | $O(\log n)$ stack |
| Worst | $O(n^2)$ | $O(n)$ stack |

Unstable: equal keys may change relative order.

## Features

- **`Sort (A)`** — ascending in-place quicksort on `Integer` arrays.
- **`Is_Sorted`** — nondecreasing predicate (empty/singleton count as sorted).
- **Capacity guard** — `Invalid_Argument` when `A'Length > Max_N`.
- **Median-of-three + Hoare** — documented partition choice.
- **Arbitrary bounds** — works for any `A'First`.
- **Zero-warning build** — `gnatmake -gnatwa -gnat2022 -Pquicksort.gpr`.

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

(Exact `NN` is the current suite size; it is at least 80.)

## Testing

The suite in `tests.adb` covers:

- Empty, singleton, and two-element arrays
- Already sorted, fully reversed, and duplicate-heavy inputs
- All-equal and alternating patterns
- Negatives and `Integer'First` / `Integer'Last`
- Non-1-based index bounds (0-based, 5-based, 10-based)
- Random arrays of many lengths matched against an insertion-sort reference
- Adversarial patterns: sorted, reverse, sawtooth, organ-pipe
- Oversize arrays raising `Invalid_Argument`
- Idempotence of `Sort`
- `Is_Sorted` true/false predicates
- Larger reverse / random arrays ($n = 1024$, $2048$)

## Building

- Prerequisites: GNAT supporting Ada 2022 / Ada 2023 (e.g. GNAT FSF 13+).
- Standard: ISO/IEC 8652:2023.
- Flags: `-gnatwa -gnat2022` with zero compiler warnings.

## API Summary

| Entity | Role |
| ------ | ---- |
| `Element_Array` | Unconstrained `array (Natural range <>) of Integer` |
| `Max_N` | Educational capacity bound (`100_000`) |
| `Invalid_Argument` | Raised on oversize length |
| `Sort` | Ascending in-place quicksort (median-of-3 + Hoare) |
| `Is_Sorted` | Nondecreasing predicate |

## License

Educational reference package. Algorithm description follows the public
Wikipedia article on Quicksort.
