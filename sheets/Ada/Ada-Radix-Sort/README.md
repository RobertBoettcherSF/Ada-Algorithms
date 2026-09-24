# Radix Sort in Ada 2023

## Project Overview

**Radix sort** is a non-comparative sorting algorithm. Instead of comparing
keys pairwise, it distributes elements into buckets according to individual
**digits** (in some radix / base), repeating for every digit position until
the keys are fully ordered. For that reason it is also known as bucket sort
or digital sort. It applies to any data that can be ordered lexicographically
by digits—integers, fixed-width strings, punched cards historically, and so on.

This package is an **Ada 2023 (ISO/IEC 8652:2023)** educational implementation
of **LSD** (least-significant-digit) radix sort for **nonnegative** `Integer`
keys. Each digit pass is a stable **counting sort**. The default radix is
$10$ (decimal); `Sort_Base` accepts any base in $2 \ldots 256$.

Primary source: [Wikipedia — Radix sort](https://en.wikipedia.org/wiki/Radix_sort).

## LSD vs MSD

Radix sorts may start at either end of the key:

| Variant | Digit order | Typical use | Stability |
| ------- | ----------- | ----------- | --------- |
| **LSD** | Least → most significant | Integers; short-before-long then lexicographic | Naturally **stable** when each pass is stable |
| **MSD** | Most → least significant | Strings; fixed-width pads; recursive subdivision | Not necessarily stable |

For the integer sequence $[1, 2, \ldots, 9, 10, 11]$, LSD produces ordinary
numeric order. MSD with naive lexicographic digit order on variable-length
decimal strings would place $10$ before $2$. This package implements **LSD
only**.

## Algorithm (LSD + counting sort)

Given an array $A$ of $n$ nonnegative keys and radix $k$ (the base):

1. Let $M = \max A$ (or skip if $n \le 1$ or $M = 0$).
2. For digit significance $p = 0, 1, 2, \ldots$ while $\lfloor M / k^{p} \rfloor > 0$:
   - Let digit $d(x) = \lfloor x / k^{p} \rfloor \bmod k$.
   - **Counting-sort** $A$ stably by $d(x)$:
     - histogram of digits into a count array of length $k$;
     - prefix sums;
     - place elements from **right to left** into an auxiliary buffer so equal
       digits keep prior relative order;
     - copy back.

Empty and singleton arrays are no-ops. All-zero arrays finish after detecting
$M = 0$.

### Complexity

With $d$ digit passes and radix $k$:

$$
\Theta\bigl(d\,(n + k)\bigr)
$$

time and $\Theta(n + k)$ auxiliary memory for the output buffer and counts.
When $d$ is treated as constant (fixed-width keys) and $k = O(n)$, this is
linear in $n$. Equivalently Wikipedia often writes $O(d \cdot n)$ when the
$O(k)$ term is absorbed or $k$ is fixed (e.g. $k = 256$ for byte digits).

Stability follows because each counting-sort pass is stable and LSD composes
stable passes from low to high significance.

## Signed-integer policy

Digit extraction $(x / k^{p}) \bmod k$ is defined here for **nonnegative**
keys only ($0 \ldots \texttt{Integer'Last}$). Any negative element raises
`Invalid_Argument` before sorting.

An alternative (not implemented) is a **two's-complement key transform**:
XOR or flip the sign bit so signed values order correctly as unsigned bit
patterns, radix-sort the transformed keys, then restore. Use that when the
domain must include negatives; it is orthogonal to the LSD vs MSD choice.

## Features

- **`Sort (A)`** — stable ascending LSD radix sort, base $10$.
- **`Sort_Base (A, Base)`** — same algorithm with radix in $2 \ldots 256$.
- **`Is_Sorted`** — nondecreasing predicate (empty/singleton count as sorted).
- **Counting-sort digit passes** — histogram, prefix sums, right-to-left place.
- **Edge cases** — empty, singleton, all zeros, mixed digit lengths.
- **Guards** — `Invalid_Argument` on negatives or `A'Length > Max_Length`.
- **Arbitrary bounds** — works for any `A'First` (`Natural` index type).
- **Zero-warning build** — `gnatmake -gnatwa -gnat2022 -Pradix_sort.gpr`.

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
- Wikipedia LSD worked example $[170, 45, 75, 90, 2, 802, 2, 66]$
- Already sorted, fully reversed, duplicates, and zeros
- Single-digit keys and mixed / large digit lengths (up to `Integer'Last`)
- `Sort_Base` for radices $2$, $10$, $16$, and $256$
- Non-1-based index bounds
- Negatives and oversize arrays raising `Invalid_Argument`
- Idempotence; agreement of `Sort` with `Sort_Base (, 10)`
- Random nonnegative arrays matched against an insertion-sort reference

## Building

- Prerequisites: GNAT supporting Ada 2022 / Ada 2023 (e.g. GNAT FSF 13+).
- Standard: ISO/IEC 8652:2023.
- Flags: `-gnatwa -gnat2022` with zero compiler warnings.

## API Summary

| Entity | Role |
| ------ | ---- |
| `Element_Array` | Unconstrained `array (Natural range <>) of Integer` |
| `Base_Range` | Subtype `Positive range 2 .. 256` |
| `Max_Length` | Educational capacity bound (`100_000`) |
| `Max_Base` | Upper radix bound (`256`) |
| `Invalid_Argument` | Raised on oversize length or negative keys |
| `Sort` | Ascending LSD radix sort, base $10$ |
| `Sort_Base` | Ascending LSD radix sort, explicit base |
| `Is_Sorted` | Nondecreasing predicate |

## License

Educational reference package. Algorithm description follows the public
Wikipedia article on Radix sort.
