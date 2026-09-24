# Slowsort in Ada 2023

## Project Overview

**Slowsort** is a humorous, deliberately *pessimal* sorting algorithm based on
the principle of **multiply and surrender** — a parody formed by taking the
opposites of *divide and conquer*. It was published in 1984 by Andrei Broder
and Jorge Stolfi in their paper *Pessimal Algorithms and Simplexity Analysis*
(a parody of optimal algorithms and complexity analysis).

Slowsort is a **reluctant** algorithm: it works hard to avoid finishing.
Recursively sorting both halves only to place a single maximum and then
re-sort almost the entire array again is intentionally wasteful. It is **not**
useful for practical applications.

The recurrence for the running time is

$$
T(n) = 2\,T\!\left(\frac{n}{2}\right) + T(n-1) + 1
$$

which yields a lower bound of

$$
\Omega\!\left(n^{\log_2(n)/(2+\epsilon)}\right)
$$

for any $\epsilon > 0$. Slowsort is therefore **not in polynomial time**.

This package is an **Ada 2023 (ISO/IEC 8652:2023)** educational implementation.
Because the asymptotics are so bad, `Max_N` is only $24$ (tests use much
smaller $n$, typically $\le 16$, with at most one $n=20$ case). Sorting even
moderate lengths will hang or time out — that is the point of the joke.

Primary source: [Wikipedia — Slowsort](https://en.wikipedia.org/wiki/Slowsort).

## Algorithm

Given an array $A$ with index range $[i .. j]$, Slowsort proceeds in place:

1. If $i \ge j$, return (trivial range).
2. Set $m := \lfloor (i+j)/2 \rfloor$.
3. **Multiply:** Slowsort $A[i .. m]$.
4. **Multiply:** Slowsort $A[m+1 .. j]$.
5. If $A[m] > A[j]$, swap them (the larger of the two half-maxima moves to $j$).
6. **Surrender:** Slowsort $A[i .. j-1]$ (re-sort everything except the new maximum).

Empty and singleton arrays are no-ops. If $n > \mathrm{Max\_N}$, `Sort`
raises `Invalid_Argument`.

### Example

For a tiny array $A = [3, 1, 2]$ ($i=1$, $j=3$):

| Step | Action | Array state (illustrative) |
| ---- | ------ | -------------------------- |
| 1 | $m=2$; sort left $[3,1]$ then right $[2]$ | after left: $[1,3,2]$ |
| 2 | Compare $A[2]=3$ and $A[3]=2$; swap | $[1,2,3]$ |
| 3 | Surrender-sort $[1,2]$ | already sorted $\rightarrow [1,2,3]$ |

(Real call trees for larger $n$ explode; do not try this by hand for $n \gg 8$.)

## Why `Max_N` is tiny

Unlike strand sort or mergesort, Slowsort **always** pays the full multiply-
and-surrender tree — data order does not help. The extra $T(n-1)$ call after
fixing one maximum makes the cost superpolynomial. Educational demos must
cap length (`Max_N = 24` here) so `make test` finishes quickly. Prefer
$n \le 16$ for thorough cases; a single $n=20$ run is already adventurous.

## Complexity

| Aspect | Bound | Notes |
| ------ | ----- | ----- |
| Recurrence | $T(n)=2T(n/2)+T(n-1)+\Theta(1)$ | From the three recursive calls |
| Lower bound | $\Omega\!\bigl(n^{\log_2 n/(2+\epsilon)}\bigr)$ | Not polynomial |
| Space | $O(\log n)$ stack | In-place aside from recursion |
| Stability | Unstable | Equal keys may change relative order |

## Features

- **`Sort (A)`** — ascending Slowsort on `Integer` arrays.
- **`Is_Sorted`** — nondecreasing predicate (empty/singleton count as sorted).
- **Capacity guard** — `Invalid_Argument` when `A'Length > Max_N` (default
  $24$).
- **Arbitrary bounds** — works for any `A'First`.
- **Negatives and duplicates** — full `Integer` domain.
- **Zero-warning build** — `gnatmake -gnatwa -gnat2022 -Pslowsort.gpr`.

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
- One cautious $n=20$ case
- `Is_Sorted` true/false cases
- `Invalid_Argument` for oversize $n = \mathrm{Max\_N}+1$
- Idempotence (sorting a sorted array again)

**Never** feed Slowsort random $n=100$ — it will not finish in reasonable time.

## Building

- Prerequisites: GNAT compiler supporting Ada 2022 / Ada 2023 (e.g. GNAT FSF
  13+, GNAT 14+, or GNAT Pro).
- Standard: ISO/IEC 8652:2023.
- Build flag: `-gnatwa -gnat2022` with zero compiler warnings.

## API

```ada
package Slowsort is
   Max_N : constant Positive := 24;
   type Element_Array is array (Natural range <>) of Integer;
   Invalid_Argument : exception;
   procedure Sort (A : in out Element_Array);
   function Is_Sorted (A : Element_Array) return Boolean;
end Slowsort;
```

## License

Educational reference implementation. See repository `LICENSE` if present.
