# Stooge Sort in Ada 2023

## Project Overview

**Stooge sort** is a deliberately inefficient recursive sorting algorithm,
notable for its exceptionally poor time complexity of
$O(n^{\log 3 / \log 1.5}) \approx O(n^{2.709})$. It is slower than bubble
sort (a canonical inefficient sort) but still faster than Slowsort. The name
comes from [The Three Stooges](https://en.wikipedia.org/wiki/The_Three_Stooges).

The algorithm repeatedly sorts overlapping two-thirds of the array: first
the initial $\lceil 2n/3 \rceil$, then the final $\lceil 2n/3 \rceil$, then
the initial two-thirds again. It is a pedagogical curiosity — **not** useful
for practical applications.

This package is an **Ada 2023 (ISO/IEC 8652:2023)** educational
implementation. Because the asymptotics are so bad, `Max_N` is only $24$
(tests use much smaller $n$, typically $\le 16$). Sorting even moderate
lengths will hang or time out — that is intentional.

Primary source: [Wikipedia — Stooge sort](https://en.wikipedia.org/wiki/Stooge_sort).

## Algorithm

Given an array $A$ with index range $[i .. j]$, Stooge sort proceeds in place:

1. If $A[i] > A[j]$, swap them.
2. If the length $L := j - i + 1$ is greater than $2$:
   - Set $t := \lfloor L / 3 \rfloor$.
   - Stooge-sort $A[i .. j-t]$ (first $\lceil 2L/3 \rceil$).
   - Stooge-sort $A[i+t .. j]$ (last $\lceil 2L/3 \rceil$).
   - Stooge-sort $A[i .. j-t]$ again.

Using $t = \lfloor L/3 \rfloor$ makes the recursive span $L - t = \lceil 2L/3 \rceil$,
which is required for correctness (e.g. $L=5$ must recurse on length $4$, not
$3$). Empty and singleton arrays are no-ops. If $n > \mathrm{Max\_N}$, `Sort`
raises `Invalid_Argument`.

### Example

For a tiny array $A = [3, 1, 2]$ ($i=1$, $j=3$, $L=3$, $t=1$):

| Step | Action | Array state (illustrative) |
| ---- | ------ | -------------------------- |
| 1 | Compare $A[1]=3$ and $A[3]=2$; swap | $[2, 1, 3]$ |
| 2 | Sort first $2/3$: $[2,1]$ | $[1, 2, 3]$ |
| 3 | Sort last $2/3$: $[2,3]$ | already sorted |
| 4 | Sort first $2/3$ again: $[1,2]$ | $[1, 2, 3]$ |

(Real call trees for larger $n$ explode; do not try this by hand for $n \gg 8$.)

## Why `Max_N` is tiny

Unlike mergesort, Stooge sort **always** pays the full three-way recursion
tree — data order does not help much. The recurrence

$$
T(n) = 3\,T\!\left(\left\lceil\frac{2n}{3}\right\rceil\right) + \Theta(1)
$$

solves to $\Theta(n^{\log 3 / \log 1.5}) \approx \Theta(n^{2.709})$. Educational
demos must cap length (`Max_N = 24` here) so `make test` finishes quickly.
Prefer $n \le 16$ for thorough cases; never feed large reverse-sorted arrays.

## Complexity

| Aspect | Bound | Notes |
| ------ | ----- | ----- |
| Recurrence | $T(n)=3T(\lceil 2n/3 \rceil)+\Theta(1)$ | Three recursive calls on $2/3$ |
| Time | $O\!\bigl(n^{\log 3 / \log 1.5}\bigr) \approx O(n^{2.709})$ | Slower than bubble sort |
| Space | $O(\log n)$ stack | In-place aside from recursion |
| Stability | Unstable | Equal keys may change relative order |

## Features

- **`Sort (A)`** — ascending Stooge sort on `Integer` arrays.
- **`Is_Sorted`** — nondecreasing predicate (empty/singleton count as sorted).
- **Capacity guard** — `Invalid_Argument` when `A'Length > Max_N` (default
  $24$).
- **Arbitrary bounds** — works for any `A'First`.
- **Negatives and duplicates** — full `Integer` domain.
- **Zero-warning build** — `gnatmake -gnatwa -gnat2022 -Pstooge_sort.gpr`.

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
- Already-sorted, reverse, and mixed **small** inputs ($n \le 12$–$16$)
- Negatives, duplicates, and all-equal arrays
- Non-1 `A'First` index bounds
- Random arrays vs insertion-sort reference (tiny $n$ only)
- `Is_Sorted` true/false cases
- `Invalid_Argument` for oversize $n = \mathrm{Max\_N}+1$
- Idempotence (sorting a sorted array again)

**Never** feed Stooge sort random $n=100$ — it will not finish in reasonable
time.

## Building

- Prerequisites: GNAT compiler supporting Ada 2022 / Ada 2023 (e.g. GNAT FSF
  13+, GNAT 14+, or GNAT Pro).
- Standard: ISO/IEC 8652:2023.
- Build flag: `-gnatwa -gnat2022` with zero compiler warnings.

## API

```ada
package Stooge_Sort is
   Max_N : constant Positive := 24;
   type Element_Array is array (Natural range <>) of Integer;
   Invalid_Argument : exception;
   procedure Sort (A : in out Element_Array);
   function Is_Sorted (A : Element_Array) return Boolean;
end Stooge_Sort;
```

## License

Educational reference implementation. See repository `LICENSE` if present.
